/// Cargos do sistema. Regra: `admin` enxerga e controla tudo;
/// `standard` usa o fluxo clínico.
enum UserRole { admin, standard }

/// Como a conta foi autenticada. `local` = usuário/senha tradicional;
/// `google` = federada via Google Sign-In (sem senha local).
enum AuthProviderKind { local, google }

extension AuthProviderKindX on AuthProviderKind {
  String get asString => name;

  static AuthProviderKind fromString(String? raw) {
    switch (raw) {
      case 'google':
        return AuthProviderKind.google;
      case 'local':
      default:
        return AuthProviderKind.local;
    }
  }
}

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.standard:
        return 'Usuário';
    }
  }

  String get shortLabel {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.standard:
        return 'Padrão';
    }
  }

  static UserRole fromString(String? raw) {
    switch (raw) {
      case 'admin':
        return UserRole.admin;
      case 'standard':
      default:
        return UserRole.standard;
    }
  }

  String get asString => name;
}

/// Representa um usuário persistido localmente.
/// A senha nunca é armazenada em texto plano — guardamos hash PBKDF2 + salt.
class AppUser {
  AppUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.email,
    required this.role,
    required this.passwordHash,
    required this.salt,
    required this.iterations,
    required this.createdAt,
    this.lastLoginAt,
    this.active = true,
    this.failedLoginAttempts = 0,
    this.lockedUntil,
    this.mustChangePassword = false,
    this.corenUF,
    this.corenNumero,
    this.authProvider = AuthProviderKind.local,
    this.googleId,
    this.photoUrl,
    this.asaasCustomerId,
  });

  final String id;
  final String username;
  final String displayName;
  final String email;
  final UserRole role;
  final String passwordHash;
  final String salt;
  final int iterations;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool active;
  final int failedLoginAttempts;
  final DateTime? lockedUntil;
  final bool mustChangePassword;
  final String? corenUF;
  final String? corenNumero;

  /// Origem da autenticação. Define se há senha local válida.
  final AuthProviderKind authProvider;

  /// `sub` (subject) retornado pelo Google. Pode ser usado como chave
  /// idempotente para vincular contas locais ao login federado.
  final String? googleId;

  /// URL do avatar retornado pelo Google (opcional).
  final String? photoUrl;

  /// ID do cliente correspondente no Asaas, criado no primeiro checkout.
  /// Persiste mesmo entre cancelamentos/reativações de assinatura.
  final String? asaasCustomerId;

  bool get isLocked =>
      lockedUntil != null && lockedUntil!.isAfter(DateTime.now());

  bool get isAdmin => role == UserRole.admin;

  bool get isGoogleAccount => authProvider == AuthProviderKind.google;

  AppUser copyWith({
    String? id,
    String? username,
    String? displayName,
    String? email,
    UserRole? role,
    String? passwordHash,
    String? salt,
    int? iterations,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? clearLastLogin,
    bool? active,
    int? failedLoginAttempts,
    DateTime? lockedUntil,
    bool? clearLockedUntil,
    bool? mustChangePassword,
    String? corenUF,
    String? corenNumero,
    AuthProviderKind? authProvider,
    String? googleId,
    String? photoUrl,
    String? asaasCustomerId,
  }) {
    return AppUser(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      role: role ?? this.role,
      passwordHash: passwordHash ?? this.passwordHash,
      salt: salt ?? this.salt,
      iterations: iterations ?? this.iterations,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: (clearLastLogin ?? false) ? null : lastLoginAt ?? this.lastLoginAt,
      active: active ?? this.active,
      failedLoginAttempts: failedLoginAttempts ?? this.failedLoginAttempts,
      lockedUntil:
          (clearLockedUntil ?? false) ? null : lockedUntil ?? this.lockedUntil,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      corenUF: corenUF ?? this.corenUF,
      corenNumero: corenNumero ?? this.corenNumero,
      authProvider: authProvider ?? this.authProvider,
      googleId: googleId ?? this.googleId,
      photoUrl: photoUrl ?? this.photoUrl,
      asaasCustomerId: asaasCustomerId ?? this.asaasCustomerId,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'username': username,
        'displayName': displayName,
        'email': email,
        'role': role.asString,
        'passwordHash': passwordHash,
        'salt': salt,
        'iterations': iterations,
        'createdAt': createdAt.toIso8601String(),
        'lastLoginAt': lastLoginAt?.toIso8601String(),
        'active': active,
        'failedLoginAttempts': failedLoginAttempts,
        'lockedUntil': lockedUntil?.toIso8601String(),
        'mustChangePassword': mustChangePassword,
        'corenUF': corenUF,
        'corenNumero': corenNumero,
        'authProvider': authProvider.asString,
        'googleId': googleId,
        'photoUrl': photoUrl,
        'asaasCustomerId': asaasCustomerId,
      };

  static AppUser fromJson(Map<String, dynamic> j) {
    return AppUser(
      id: j['id'] as String,
      username: j['username'] as String,
      displayName: j['displayName'] as String,
      email: (j['email'] as String?) ?? '',
      role: UserRoleX.fromString(j['role'] as String?),
      passwordHash: j['passwordHash'] as String,
      salt: j['salt'] as String,
      iterations: (j['iterations'] as num?)?.toInt() ?? 150000,
      createdAt: DateTime.parse(j['createdAt'] as String),
      lastLoginAt: j['lastLoginAt'] == null
          ? null
          : DateTime.parse(j['lastLoginAt'] as String),
      active: (j['active'] as bool?) ?? true,
      failedLoginAttempts: (j['failedLoginAttempts'] as num?)?.toInt() ?? 0,
      lockedUntil: j['lockedUntil'] == null
          ? null
          : DateTime.parse(j['lockedUntil'] as String),
      mustChangePassword: (j['mustChangePassword'] as bool?) ?? false,
      corenUF: j['corenUF'] as String?,
      corenNumero: j['corenNumero'] as String?,
      authProvider: AuthProviderKindX.fromString(j['authProvider'] as String?),
      googleId: j['googleId'] as String?,
      photoUrl: j['photoUrl'] as String?,
      asaasCustomerId: j['asaasCustomerId'] as String?,
    );
  }
}

/// Sessão ativa de um usuário. Armazenada em secure storage.
class AppSession {
  AppSession({
    required this.token,
    required this.userId,
    required this.createdAt,
    required this.expiresAt,
  });

  final String token;
  final String userId;
  final DateTime createdAt;
  final DateTime expiresAt;

  bool get isValid => expiresAt.isAfter(DateTime.now());

  Duration get remaining => expiresAt.difference(DateTime.now());

  Map<String, dynamic> toJson() => <String, dynamic>{
        'token': token,
        'userId': userId,
        'createdAt': createdAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
      };

  static AppSession fromJson(Map<String, dynamic> j) => AppSession(
        token: j['token'] as String,
        userId: j['userId'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        expiresAt: DateTime.parse(j['expiresAt'] as String),
      );
}
