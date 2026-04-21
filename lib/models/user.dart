/// Cargos do sistema. Regra: `admin` enxerga e controla tudo;
/// `standard` usa o fluxo clínico.
enum UserRole { admin, standard }

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

  bool get isLocked =>
      lockedUntil != null && lockedUntil!.isAfter(DateTime.now());

  bool get isAdmin => role == UserRole.admin;

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
