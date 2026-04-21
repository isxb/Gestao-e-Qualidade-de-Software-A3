import 'package:uuid/uuid.dart';

import '../models/activity_log.dart';
import '../models/user.dart';
import 'crypto_service.dart';
import 'log_service.dart';
import 'storage_service.dart';

class AuthException implements Exception {
  AuthException(this.code, this.message);
  final String code;
  final String message;
  @override
  String toString() => message;
}

/// Resultado de um login bem-sucedido.
class AuthResult {
  AuthResult(this.user, this.session);
  final AppUser user;
  final AppSession session;
}

/// Resultado de uma criação de usuário que gera senha temporária.
class CreatedUser {
  CreatedUser(this.user, this.temporaryPassword);
  final AppUser user;
  final String temporaryPassword;
}

/// Núcleo de autenticação local.
///
/// Responsável por:
/// - Bootstrap do admin padrão no primeiro uso
/// - Login / logout / validação de sessão
/// - CRUD de usuários (admin)
/// - Política de bloqueio após tentativas falhas
/// - Troca/reset de senha
///
/// Todas as operações disparam registros em [LogService] automaticamente.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final StorageService _storage = StorageService.instance;
  final LogService _logs = LogService.instance;
  final Uuid _uuid = const Uuid();

  static const int _maxFailedAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 15);
  static const Duration _sessionTtl = Duration(hours: 12);

  // ============================================================
  // Bootstrap
  // ============================================================

  /// Cria o admin padrão na primeira execução.
  /// Usuário: `admin` | Senha: `admin123` (marcada como "deve trocar").
  Future<void> ensureBootstrap() async {
    if (_storage.isBootstrapped) return;

    final List<AppUser> current = _storage.loadUsers();
    if (current.isEmpty) {
      final String salt = CryptoService.generateSalt();
      final String hash = CryptoService.hashPassword(
        password: 'admin123',
        saltBase64: salt,
      );
      final AppUser admin = AppUser(
        id: _uuid.v4(),
        username: 'admin',
        displayName: 'Administrador',
        email: 'admin@evoluapro.local',
        role: UserRole.admin,
        passwordHash: hash,
        salt: salt,
        iterations: CryptoService.defaultIterations,
        createdAt: DateTime.now(),
        mustChangePassword: true,
      );
      await _storage.saveUsers(<AppUser>[admin]);
      await _logs.record(
        userId: admin.id,
        userDisplayName: admin.displayName,
        type: ActivityType.userCreated,
        description: 'Usuário admin padrão criado automaticamente.',
        metadata: <String, dynamic>{'bootstrap': true},
      );
    }
    await _storage.markBootstrapped();
  }

  // ============================================================
  // Login / logout / sessão
  // ============================================================

  Future<AuthResult> login({
    required String username,
    required String password,
  }) async {
    final String normalized = username.trim().toLowerCase();
    if (normalized.isEmpty || password.isEmpty) {
      throw AuthException('empty', 'Informe usuário e senha.');
    }

    List<AppUser> users = _storage.loadUsers();
    final int idx = users.indexWhere(
      (AppUser u) => u.username.toLowerCase() == normalized,
    );

    if (idx < 0) {
      await _logs.record(
        userId: 'anonymous',
        userDisplayName: 'Desconhecido',
        type: ActivityType.loginFailed,
        description: 'Tentativa de login com usuário inexistente: "$normalized".',
      );
      throw AuthException('invalid', 'Usuário ou senha inválidos.');
    }

    AppUser user = users[idx];

    if (!user.active) {
      await _logs.record(
        userId: user.id,
        userDisplayName: user.displayName,
        type: ActivityType.loginFailed,
        description: 'Tentativa de login em conta desativada.',
      );
      throw AuthException(
        'inactive',
        'Sua conta foi desativada. Procure um administrador.',
      );
    }

    if (user.isLocked) {
      final int minutes = user.lockedUntil!.difference(DateTime.now()).inMinutes + 1;
      await _logs.record(
        userId: user.id,
        userDisplayName: user.displayName,
        type: ActivityType.loginFailed,
        description: 'Login bloqueado — conta temporariamente travada.',
      );
      throw AuthException(
        'locked',
        'Conta bloqueada. Tente novamente em $minutes min.',
      );
    }

    final bool ok = CryptoService.verifyPassword(
      password: password,
      expectedHashBase64: user.passwordHash,
      saltBase64: user.salt,
      iterations: user.iterations,
    );

    if (!ok) {
      final int attempts = user.failedLoginAttempts + 1;
      final bool shouldLock = attempts >= _maxFailedAttempts;
      final AppUser updated = user.copyWith(
        failedLoginAttempts: attempts,
        lockedUntil:
            shouldLock ? DateTime.now().add(_lockoutDuration) : user.lockedUntil,
      );
      users = List<AppUser>.from(users)..[idx] = updated;
      await _storage.saveUsers(users);

      await _logs.record(
        userId: user.id,
        userDisplayName: user.displayName,
        type: ActivityType.loginFailed,
        description: 'Senha incorreta. Tentativa $attempts/$_maxFailedAttempts.',
        metadata: <String, dynamic>{
          'attempts': attempts,
          'locked': shouldLock,
        },
      );

      if (shouldLock) {
        await _logs.record(
          userId: user.id,
          userDisplayName: user.displayName,
          type: ActivityType.accountLocked,
          description:
              'Conta bloqueada automaticamente após $_maxFailedAttempts falhas.',
        );
        throw AuthException(
          'locked',
          'Conta bloqueada por ${_lockoutDuration.inMinutes} min após tentativas falhas.',
        );
      }
      throw AuthException(
        'invalid',
        'Usuário ou senha inválidos. Tentativas restantes: ${_maxFailedAttempts - attempts}.',
      );
    }

    // Sucesso — limpa contador + atualiza last login
    user = user.copyWith(
      failedLoginAttempts: 0,
      clearLockedUntil: true,
      lastLoginAt: DateTime.now(),
    );
    users = List<AppUser>.from(users)..[idx] = user;
    await _storage.saveUsers(users);

    final AppSession session = AppSession(
      token: CryptoService.generateToken(),
      userId: user.id,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(_sessionTtl),
    );
    await _storage.saveSession(session);

    await _logs.record(
      userId: user.id,
      userDisplayName: user.displayName,
      type: ActivityType.loginSuccess,
      description: 'Login bem-sucedido.',
      metadata: <String, dynamic>{'role': user.role.asString},
    );

    if (user.mustChangePassword) {
      await _logs.record(
        userId: user.id,
        userDisplayName: user.displayName,
        type: ActivityType.mustChangePasswordPrompted,
        description: 'Usuário precisa trocar a senha no primeiro acesso.',
      );
    }

    return AuthResult(user, session);
  }

  Future<void> logout(AppUser user) async {
    await _storage.clearSession();
    await _logs.record(
      userId: user.id,
      userDisplayName: user.displayName,
      type: ActivityType.logout,
      description: 'Logout.',
    );
  }

  /// Tenta restaurar uma sessão salva. Retorna o usuário, ou null se a
  /// sessão tiver expirado ou o usuário não existir mais.
  Future<AppUser?> restoreSession() async {
    final AppSession? session = await _storage.loadSession();
    if (session == null) return null;
    if (!session.isValid) {
      final AppUser? owner = _getUserById(session.userId);
      await _storage.clearSession();
      if (owner != null) {
        await _logs.record(
          userId: owner.id,
          userDisplayName: owner.displayName,
          type: ActivityType.sessionExpired,
          description: 'Sessão expirada.',
        );
      }
      return null;
    }
    final AppUser? u = _getUserById(session.userId);
    if (u == null || !u.active) {
      await _storage.clearSession();
      return null;
    }
    return u;
  }

  AppUser? _getUserById(String id) {
    final List<AppUser> users = _storage.loadUsers();
    for (final AppUser u in users) {
      if (u.id == id) return u;
    }
    return null;
  }

  // ============================================================
  // Troca/reset de senha
  // ============================================================
  Future<AppUser> changeOwnPassword({
    required AppUser currentUser,
    required String oldPassword,
    required String newPassword,
  }) async {
    _validatePasswordPolicy(newPassword);

    final bool ok = CryptoService.verifyPassword(
      password: oldPassword,
      expectedHashBase64: currentUser.passwordHash,
      saltBase64: currentUser.salt,
      iterations: currentUser.iterations,
    );
    if (!ok) {
      throw AuthException('wrong-old-password', 'Senha atual incorreta.');
    }

    final String salt = CryptoService.generateSalt();
    final String hash = CryptoService.hashPassword(
      password: newPassword,
      saltBase64: salt,
    );

    final List<AppUser> users = _storage.loadUsers();
    final int idx = users.indexWhere((AppUser u) => u.id == currentUser.id);
    if (idx < 0) throw AuthException('not-found', 'Usuário não encontrado.');

    final AppUser updated = users[idx].copyWith(
      passwordHash: hash,
      salt: salt,
      iterations: CryptoService.defaultIterations,
      mustChangePassword: false,
      failedLoginAttempts: 0,
      clearLockedUntil: true,
    );
    users[idx] = updated;
    await _storage.saveUsers(users);

    await _logs.record(
      userId: updated.id,
      userDisplayName: updated.displayName,
      type: ActivityType.passwordChanged,
      description: 'Senha alterada pelo próprio usuário.',
    );

    return updated;
  }

  /// Reset de senha por admin. Gera senha temporária e marca "deve trocar".
  Future<String> resetPasswordByAdmin({
    required AppUser admin,
    required String targetUserId,
  }) async {
    _requireAdmin(admin);
    final List<AppUser> users = _storage.loadUsers();
    final int idx = users.indexWhere((AppUser u) => u.id == targetUserId);
    if (idx < 0) throw AuthException('not-found', 'Usuário não encontrado.');

    final String tempPassword = CryptoService.generateTempPassword();
    final String salt = CryptoService.generateSalt();
    final String hash = CryptoService.hashPassword(
      password: tempPassword,
      saltBase64: salt,
    );

    users[idx] = users[idx].copyWith(
      passwordHash: hash,
      salt: salt,
      iterations: CryptoService.defaultIterations,
      mustChangePassword: true,
      failedLoginAttempts: 0,
      clearLockedUntil: true,
    );
    await _storage.saveUsers(users);

    await _logs.record(
      userId: users[idx].id,
      userDisplayName: users[idx].displayName,
      type: ActivityType.passwordResetByAdmin,
      description: 'Senha redefinida por ${admin.displayName}.',
      metadata: <String, dynamic>{'adminId': admin.id},
    );

    return tempPassword;
  }

  // ============================================================
  // Usuários (admin CRUD)
  // ============================================================

  List<AppUser> listUsers() => _storage.loadUsers();

  Future<CreatedUser> createUser({
    required AppUser admin,
    required String username,
    required String displayName,
    required String email,
    required UserRole role,
    String? corenUF,
    String? corenNumero,
    String? password,
  }) async {
    _requireAdmin(admin);

    final String normalized = username.trim().toLowerCase();
    if (normalized.isEmpty) {
      throw AuthException('empty', 'Informe um nome de usuário.');
    }
    if (!RegExp(r'^[a-z0-9_.-]{3,32}$').hasMatch(normalized)) {
      throw AuthException(
        'invalid-username',
        'Usuário deve conter apenas letras minúsculas, números, "_" ou ".", e ter 3 a 32 caracteres.',
      );
    }
    if (displayName.trim().length < 2) {
      throw AuthException('invalid-name', 'Nome de exibição muito curto.');
    }

    final List<AppUser> users = _storage.loadUsers();
    if (users.any((AppUser u) => u.username.toLowerCase() == normalized)) {
      throw AuthException('duplicate', 'Já existe um usuário com esse nome.');
    }

    final String finalPassword =
        (password == null || password.isEmpty)
            ? CryptoService.generateTempPassword()
            : password;
    if (password != null && password.isNotEmpty) {
      _validatePasswordPolicy(password);
    }

    final String salt = CryptoService.generateSalt();
    final String hash = CryptoService.hashPassword(
      password: finalPassword,
      saltBase64: salt,
    );

    final AppUser user = AppUser(
      id: _uuid.v4(),
      username: normalized,
      displayName: displayName.trim(),
      email: email.trim(),
      role: role,
      passwordHash: hash,
      salt: salt,
      iterations: CryptoService.defaultIterations,
      createdAt: DateTime.now(),
      mustChangePassword: true,
      corenUF: corenUF,
      corenNumero: corenNumero,
    );

    final List<AppUser> updated = <AppUser>[...users, user];
    await _storage.saveUsers(updated);

    await _logs.record(
      userId: user.id,
      userDisplayName: user.displayName,
      type: ActivityType.userCreated,
      description: 'Criado por ${admin.displayName} (${role.label}).',
      metadata: <String, dynamic>{'adminId': admin.id},
    );

    return CreatedUser(user, finalPassword);
  }

  Future<AppUser> updateUser({
    required AppUser admin,
    required String targetUserId,
    String? displayName,
    String? email,
    UserRole? role,
    bool? active,
    String? corenUF,
    String? corenNumero,
  }) async {
    _requireAdmin(admin);
    final List<AppUser> users = _storage.loadUsers();
    final int idx = users.indexWhere((AppUser u) => u.id == targetUserId);
    if (idx < 0) throw AuthException('not-found', 'Usuário não encontrado.');
    final AppUser before = users[idx];

    final AppUser updated = before.copyWith(
      displayName: displayName?.trim(),
      email: email?.trim(),
      role: role,
      active: active,
      corenUF: corenUF,
      corenNumero: corenNumero,
    );
    users[idx] = updated;
    await _storage.saveUsers(users);

    if (role != null && role != before.role) {
      await _logs.record(
        userId: updated.id,
        userDisplayName: updated.displayName,
        type: ActivityType.userRoleChanged,
        description:
            'Cargo alterado de ${before.role.label} para ${role.label} por ${admin.displayName}.',
        metadata: <String, dynamic>{
          'from': before.role.asString,
          'to': role.asString,
          'adminId': admin.id,
        },
      );
    }

    if (active != null && active != before.active) {
      await _logs.record(
        userId: updated.id,
        userDisplayName: updated.displayName,
        type: active ? ActivityType.userActivated : ActivityType.userDeactivated,
        description:
            '${active ? "Ativado" : "Desativado"} por ${admin.displayName}.',
        metadata: <String, dynamic>{'adminId': admin.id},
      );
    }

    await _logs.record(
      userId: updated.id,
      userDisplayName: updated.displayName,
      type: ActivityType.userUpdated,
      description: 'Perfil atualizado por ${admin.displayName}.',
      metadata: <String, dynamic>{'adminId': admin.id},
    );

    return updated;
  }

  Future<void> deleteUser({
    required AppUser admin,
    required String targetUserId,
  }) async {
    _requireAdmin(admin);
    if (admin.id == targetUserId) {
      throw AuthException(
        'self-delete',
        'Você não pode excluir a si mesmo. Peça a outro admin.',
      );
    }
    final List<AppUser> users = _storage.loadUsers();
    final int idx = users.indexWhere((AppUser u) => u.id == targetUserId);
    if (idx < 0) throw AuthException('not-found', 'Usuário não encontrado.');
    final AppUser gone = users[idx];

    // Impede exclusão do último admin
    final int remainingAdmins = users
        .where(
          (AppUser u) => u.role == UserRole.admin && u.id != targetUserId && u.active,
        )
        .length;
    if (gone.role == UserRole.admin && remainingAdmins == 0) {
      throw AuthException(
        'last-admin',
        'Não é possível excluir o último administrador do sistema.',
      );
    }

    users.removeAt(idx);
    await _storage.saveUsers(users);

    await _logs.record(
      userId: gone.id,
      userDisplayName: gone.displayName,
      type: ActivityType.userDeleted,
      description: 'Excluído por ${admin.displayName}.',
      metadata: <String, dynamic>{'adminId': admin.id},
    );
  }

  Future<AppUser> unlockUser({
    required AppUser admin,
    required String targetUserId,
  }) async {
    _requireAdmin(admin);
    final List<AppUser> users = _storage.loadUsers();
    final int idx = users.indexWhere((AppUser u) => u.id == targetUserId);
    if (idx < 0) throw AuthException('not-found', 'Usuário não encontrado.');
    final AppUser updated = users[idx].copyWith(
      failedLoginAttempts: 0,
      clearLockedUntil: true,
    );
    users[idx] = updated;
    await _storage.saveUsers(users);
    await _logs.record(
      userId: updated.id,
      userDisplayName: updated.displayName,
      type: ActivityType.accountUnlocked,
      description: 'Desbloqueado por ${admin.displayName}.',
      metadata: <String, dynamic>{'adminId': admin.id},
    );
    return updated;
  }

  // ============================================================
  // Helpers
  // ============================================================
  void _requireAdmin(AppUser user) {
    if (!user.isAdmin) {
      throw AuthException('forbidden', 'Ação restrita a administradores.');
    }
  }

  void _validatePasswordPolicy(String password) {
    if (password.length < 8) {
      throw AuthException(
        'weak',
        'A senha deve ter pelo menos 8 caracteres.',
      );
    }
    if (CryptoService.passwordStrength(password) < 2) {
      throw AuthException(
        'weak',
        'Senha muito fraca. Combine letras, números e símbolos.',
      );
    }
  }
}
