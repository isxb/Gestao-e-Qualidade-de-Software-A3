import 'package:google_sign_in/google_sign_in.dart';
import 'package:uuid/uuid.dart';

import '../models/activity_log.dart';
import '../models/user.dart';
import 'auth_service.dart';
import 'crypto_service.dart';
import 'log_service.dart';
import 'storage_service.dart';

/// Resultado de um sign-in/up via Google.
class GoogleAuthResult {
  GoogleAuthResult({required this.user, required this.created});
  final AppUser user;

  /// `true` quando este foi o primeiro login Google deste e-mail (ou
  /// seja, criamos a conta agora). Útil para a UI dar boas-vindas.
  final bool created;
}

/// Login federado com Google.
///
/// Em mobile (Android/iOS) e web o plugin oficial `google_sign_in`
/// abre o seletor de conta e devolve um [GoogleSignInAccount]. Em
/// Windows desktop o plugin não tem suporte; chamadas a [signIn]
/// devolvem [AuthException('google-unsupported', ...)] e a UI cai para
/// outra forma de login.
///
/// Configuração necessária antes de funcionar de verdade:
///   - Android: `google-services.json` com SHA-1 do keystore registrado
///     no Google Cloud Console.
///   - iOS: `GoogleService-Info.plist` + URL types no Info.plist.
///   - Web: `<meta name="google-signin-client_id" content="...">` no
///     `web/index.html` ou parâmetro `clientId:` no construtor abaixo.
class GoogleAuthService {
  GoogleAuthService._();
  static final GoogleAuthService instance = GoogleAuthService._();

  /// Inicializado lazy — em Windows desktop nem chegamos a instanciar.
  GoogleSignIn? _googleSignIn;

  GoogleSignIn _client() {
    return _googleSignIn ??= GoogleSignIn(
      scopes: <String>['email', 'profile'],
    );
  }

  final StorageService _storage = StorageService.instance;
  final LogService _logs = LogService.instance;
  final Uuid _uuid = const Uuid();

  Future<GoogleAuthResult> signIn() async {
    final GoogleSignInAccount? account;
    try {
      account = await _client().signIn();
    } catch (e) {
      throw AuthException('google-failed', 'Falha ao logar com Google: $e');
    }
    if (account == null) {
      // Usuário fechou o seletor.
      throw AuthException(
        'cancelled',
        'Login com Google cancelado.',
      );
    }

    return _findOrCreate(
      googleId: account.id,
      email: account.email,
      displayName: account.displayName ?? account.email.split('@').first,
      photoUrl: account.photoUrl,
    );
  }

  Future<void> signOut() async {
    try {
      await _client().signOut();
    } catch (_) {
      // Sem rede / sem suporte → ignorável.
    }
  }

  /// Localiza um usuário pelo `googleId` ou `email`. Se nada bater, cria
  /// uma conta `standard` ligada ao Google. A senha é uma string
  /// aleatória — usuários Google não fazem login local.
  Future<GoogleAuthResult> _findOrCreate({
    required String googleId,
    required String email,
    required String displayName,
    String? photoUrl,
  }) async {
    final List<AppUser> users = _storage.loadUsers();
    final String normalizedEmail = email.toLowerCase().trim();

    // 1. Já existe um usuário com este googleId? Ou com este email?
    AppUser? existing;
    int existingIdx = -1;
    for (int i = 0; i < users.length; i++) {
      final AppUser u = users[i];
      final bool sameGoogle = u.googleId != null && u.googleId == googleId;
      final bool sameEmail =
          u.email.toLowerCase().trim() == normalizedEmail;
      if (sameGoogle || sameEmail) {
        existing = u;
        existingIdx = i;
        break;
      }
    }

    if (existing != null && existingIdx >= 0) {
      // Garante que o googleId está vinculado e atualiza dados visíveis.
      final AppUser updated = existing.copyWith(
        googleId: googleId,
        photoUrl: photoUrl ?? existing.photoUrl,
        authProvider: AuthProviderKind.google,
        lastLoginAt: DateTime.now(),
        failedLoginAttempts: 0,
        clearLockedUntil: true,
      );
      users[existingIdx] = updated;
      await _storage.saveUsers(users);

      await _logs.record(
        userId: updated.id,
        userDisplayName: updated.displayName,
        type: ActivityType.loginSuccess,
        description: 'Login via Google.',
        metadata: <String, dynamic>{
          'provider': 'google',
          'firstTime': false,
        },
      );

      return GoogleAuthResult(user: updated, created: false);
    }

    // 2. Criação. Username derivado do e-mail, com fallback se conflitar.
    String username = _suggestUsername(normalizedEmail, users);

    // Senha aleatória — o usuário Google nunca a usa. Mantemos um hash
    // só para satisfazer o modelo atual, que exige passwordHash não nulo.
    final String randomPassword = CryptoService.generateToken(bytes: 24);
    final String salt = CryptoService.generateSalt();
    final String hash = CryptoService.hashPassword(
      password: randomPassword,
      saltBase64: salt,
    );

    final AppUser created = AppUser(
      id: _uuid.v4(),
      username: username,
      displayName: displayName,
      email: normalizedEmail,
      role: UserRole.standard,
      passwordHash: hash,
      salt: salt,
      iterations: CryptoService.defaultIterations,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      authProvider: AuthProviderKind.google,
      googleId: googleId,
      photoUrl: photoUrl,
      mustChangePassword: false,
    );
    await _storage.saveUsers(<AppUser>[...users, created]);

    await _logs.record(
      userId: created.id,
      userDisplayName: created.displayName,
      type: ActivityType.userCreated,
      description: 'Conta criada via Google Sign-In.',
      metadata: <String, dynamic>{
        'provider': 'google',
        'selfRegistered': true,
      },
    );

    return GoogleAuthResult(user: created, created: true);
  }

  String _suggestUsername(String email, List<AppUser> users) {
    final String base = email
        .split('@')
        .first
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_.-]'), '');
    final String safeBase = base.length >= 3 ? base : 'user_${base}_';
    String candidate = safeBase.length > 32 ? safeBase.substring(0, 32) : safeBase;
    int suffix = 1;
    while (users.any((AppUser u) => u.username == candidate)) {
      final String tail = (suffix++).toString();
      final int max = 32 - tail.length;
      candidate = '${safeBase.substring(0, safeBase.length > max ? max : safeBase.length)}$tail';
    }
    return candidate;
  }
}
