import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../services/auth_service.dart';

enum AuthStatus {
  /// Ainda verificando sessão ao abrir o app.
  initializing,

  /// Sem usuário autenticado.
  signedOut,

  /// Logado.
  signedIn,
}

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? service}) : _service = service ?? AuthService.instance;

  final AuthService _service;

  AppUser? _user;
  AuthStatus _status = AuthStatus.initializing;
  String? _lastError;

  AppUser? get currentUser => _user;
  AuthStatus get status => _status;
  String? get lastError => _lastError;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get mustChangePassword => _user?.mustChangePassword ?? false;

  /// Chamado em main.dart após `ensureBootstrap()`.
  Future<void> hydrate() async {
    _status = AuthStatus.initializing;
    notifyListeners();
    final AppUser? restored = await _service.restoreSession();
    _user = restored;
    _status = restored == null ? AuthStatus.signedOut : AuthStatus.signedIn;
    notifyListeners();
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    _lastError = null;
    try {
      final AuthResult result = await _service.login(
        username: username,
        password: password,
      );
      _user = result.user;
      _status = AuthStatus.signedIn;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _lastError = e.message;
      notifyListeners();
      return false;
    }
  }

  /// Auto-cadastro de usuário comum. Em sucesso, já cria sessão e
  /// sinaliza [AuthStatus.signedIn] — não há necessidade de o usuário
  /// fazer login manual logo após o registro.
  Future<bool> register({
    required String username,
    required String displayName,
    required String email,
    required String password,
  }) async {
    _lastError = null;
    try {
      await _service.registerSelf(
        username: username,
        displayName: displayName,
        email: email,
        password: password,
      );
      final AuthResult result = await _service.login(
        username: username,
        password: password,
      );
      _user = result.user;
      _status = AuthStatus.signedIn;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _lastError = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    final AppUser? u = _user;
    if (u != null) await _service.logout(u);
    _user = null;
    _status = AuthStatus.signedOut;
    notifyListeners();
  }

  Future<bool> changeOwnPassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final AppUser? u = _user;
    if (u == null) return false;
    _lastError = null;
    try {
      final AppUser updated = await _service.changeOwnPassword(
        currentUser: u,
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      _user = updated;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _lastError = e.message;
      notifyListeners();
      return false;
    }
  }

  /// Atualiza o usuário local após uma mudança feita pelo admin no próprio
  /// perfil. Evita re-login.
  void refreshCurrentUser() {
    final AppUser? u = _user;
    if (u == null) return;
    final List<AppUser> users = _service.listUsers();
    final AppUser? updated = users.cast<AppUser?>().firstWhere(
          (AppUser? x) => x?.id == u.id,
          orElse: () => null,
        );
    if (updated != null) {
      _user = updated;
      notifyListeners();
    }
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
  }
}
