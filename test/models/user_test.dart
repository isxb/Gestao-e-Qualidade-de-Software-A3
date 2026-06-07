// Testes unitários (caixa branca) — modelo AppUser, UserRole, AppSession
// Tipo: Teste Unitário | Abordagem: Caixa Branca
import 'package:evolua_pro/models/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // =========================================================
  // UserRole
  // =========================================================
  group('UserRole', () {
    test('fromString retorna admin para "admin"', () {
      expect(UserRoleX.fromString('admin'), UserRole.admin);
    });

    test('fromString retorna standard para "standard"', () {
      expect(UserRoleX.fromString('standard'), UserRole.standard);
    });

    test('fromString retorna standard para valor nulo', () {
      expect(UserRoleX.fromString(null), UserRole.standard);
    });

    test('fromString retorna standard para valor desconhecido', () {
      expect(UserRoleX.fromString('desconhecido'), UserRole.standard);
    });

    test('label retorna texto legível correto', () {
      expect(UserRole.admin.label, 'Administrador');
      expect(UserRole.standard.label, 'Usuário');
    });

    test('shortLabel retorna abreviação correta', () {
      expect(UserRole.admin.shortLabel, 'Admin');
      expect(UserRole.standard.shortLabel, 'Padrão');
    });

    test('asString retorna o nome do enum', () {
      expect(UserRole.admin.asString, 'admin');
      expect(UserRole.standard.asString, 'standard');
    });
  });

  // =========================================================
  // AuthProviderKind
  // =========================================================
  group('AuthProviderKind', () {
    test('fromString retorna google para "google"', () {
      expect(AuthProviderKindX.fromString('google'), AuthProviderKind.google);
    });

    test('fromString retorna local para "local"', () {
      expect(AuthProviderKindX.fromString('local'), AuthProviderKind.local);
    });

    test('fromString retorna local para valor nulo', () {
      expect(AuthProviderKindX.fromString(null), AuthProviderKind.local);
    });

    test('fromString retorna local para valor desconhecido', () {
      expect(AuthProviderKindX.fromString('facebook'), AuthProviderKind.local);
    });
  });

  // =========================================================
  // AppUser
  // =========================================================
  group('AppUser', () {
    AppUser buildUser({
      UserRole role = UserRole.standard,
      bool active = true,
      DateTime? lockedUntil,
      AuthProviderKind authProvider = AuthProviderKind.local,
    }) {
      return AppUser(
        id: 'u1',
        username: 'testuser',
        displayName: 'Test User',
        email: 'test@example.com',
        role: role,
        passwordHash: 'hash123',
        salt: 'salt123',
        iterations: 1000,
        createdAt: DateTime(2024, 1, 1),
        active: active,
        lockedUntil: lockedUntil,
        authProvider: authProvider,
      );
    }

    test('isAdmin retorna true apenas para role admin', () {
      expect(buildUser(role: UserRole.admin).isAdmin, isTrue);
      expect(buildUser(role: UserRole.standard).isAdmin, isFalse);
    });

    test('isGoogleAccount retorna true apenas para authProvider google', () {
      expect(
        buildUser(authProvider: AuthProviderKind.google).isGoogleAccount,
        isTrue,
      );
      expect(
        buildUser(authProvider: AuthProviderKind.local).isGoogleAccount,
        isFalse,
      );
    });

    test('isLocked retorna false quando lockedUntil é null', () {
      expect(buildUser().isLocked, isFalse);
    });

    test('isLocked retorna true quando lockedUntil está no futuro', () {
      final DateTime futuro = DateTime.now().add(const Duration(hours: 1));
      expect(buildUser(lockedUntil: futuro).isLocked, isTrue);
    });

    test('isLocked retorna false quando lockedUntil está no passado', () {
      final DateTime passado =
          DateTime.now().subtract(const Duration(hours: 1));
      expect(buildUser(lockedUntil: passado).isLocked, isFalse);
    });

    test('copyWith substitui apenas o campo informado', () {
      final AppUser original = buildUser(role: UserRole.admin);
      final AppUser copia = original.copyWith(displayName: 'Novo Nome');
      expect(copia.displayName, 'Novo Nome');
      expect(copia.role, UserRole.admin);
      expect(copia.username, original.username);
    });

    test('copyWith com clearLockedUntil remove o bloqueio', () {
      final DateTime futuro = DateTime.now().add(const Duration(hours: 2));
      final AppUser bloqueado = buildUser(lockedUntil: futuro);
      final AppUser desbloqueado = bloqueado.copyWith(clearLockedUntil: true);
      expect(desbloqueado.lockedUntil, isNull);
    });

    test('toJson / fromJson é um round-trip fiel', () {
      final AppUser original = buildUser(role: UserRole.admin);
      final Map<String, dynamic> json = original.toJson();
      final AppUser restaurado = AppUser.fromJson(json);

      expect(restaurado.id, original.id);
      expect(restaurado.username, original.username);
      expect(restaurado.email, original.email);
      expect(restaurado.role, original.role);
      expect(restaurado.active, original.active);
    });
  });

  // =========================================================
  // AppSession
  // =========================================================
  group('AppSession', () {
    test('isValid retorna true antes da expiração', () {
      final AppSession sessao = AppSession(
        token: 'tok',
        userId: 'u1',
        createdAt: DateTime.now().subtract(const Duration(minutes: 1)),
        expiresAt: DateTime.now().add(const Duration(hours: 8)),
      );
      expect(sessao.isValid, isTrue);
    });

    test('isValid retorna false após a expiração', () {
      final AppSession sessao = AppSession(
        token: 'tok',
        userId: 'u1',
        createdAt: DateTime.now().subtract(const Duration(hours: 10)),
        expiresAt: DateTime.now().subtract(const Duration(hours: 2)),
      );
      expect(sessao.isValid, isFalse);
    });

    test('remaining retorna duração positiva para sessão válida', () {
      final AppSession sessao = AppSession(
        token: 'tok',
        userId: 'u1',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      expect(sessao.remaining.isNegative, isFalse);
    });

    test('toJson / fromJson é round-trip fiel', () {
      final AppSession original = AppSession(
        token: 'tok-abc-123',
        userId: 'u42',
        createdAt: DateTime(2025, 1, 1, 8),
        expiresAt: DateTime(2025, 1, 1, 16),
      );
      final AppSession restaurado = AppSession.fromJson(original.toJson());
      expect(restaurado.token, original.token);
      expect(restaurado.userId, original.userId);
      expect(restaurado.expiresAt, original.expiresAt);
    });
  });
}
