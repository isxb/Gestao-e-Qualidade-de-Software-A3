import 'package:flutter/foundation.dart';

import '../models/activity_log.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/log_service.dart';

/// Estado reativo para as telas administrativas (lista de usuários,
/// logs, ações em usuários). Todas as operações admin passam por aqui
/// para garantir refresh automático das telas observadoras.
class AdminProvider extends ChangeNotifier {
  AdminProvider({
    AuthService? auth,
    LogService? logs,
  })  : _auth = auth ?? AuthService.instance,
        _logs = logs ?? LogService.instance;

  final AuthService _auth;
  final LogService _logs;

  List<AppUser> _users = <AppUser>[];

  List<AppUser> get users => List<AppUser>.unmodifiable(_users);

  int get totalUsers => _users.length;
  int get totalAdmins => _users.where((AppUser u) => u.role == UserRole.admin).length;
  int get activeUsers => _users.where((AppUser u) => u.active).length;

  void hydrate() {
    _users = _auth.listUsers();
    notifyListeners();
  }

  // ----- Ações em usuários -----
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
    final CreatedUser created = await _auth.createUser(
      admin: admin,
      username: username,
      displayName: displayName,
      email: email,
      role: role,
      corenUF: corenUF,
      corenNumero: corenNumero,
      password: password,
    );
    hydrate();
    return created;
  }

  Future<void> updateUser({
    required AppUser admin,
    required String targetUserId,
    String? displayName,
    String? email,
    UserRole? role,
    bool? active,
    String? corenUF,
    String? corenNumero,
  }) async {
    await _auth.updateUser(
      admin: admin,
      targetUserId: targetUserId,
      displayName: displayName,
      email: email,
      role: role,
      active: active,
      corenUF: corenUF,
      corenNumero: corenNumero,
    );
    hydrate();
  }

  Future<void> deleteUser({
    required AppUser admin,
    required String targetUserId,
  }) async {
    await _auth.deleteUser(admin: admin, targetUserId: targetUserId);
    hydrate();
  }

  Future<String> resetPassword({
    required AppUser admin,
    required String targetUserId,
  }) async {
    final String temp = await _auth.resetPasswordByAdmin(
      admin: admin,
      targetUserId: targetUserId,
    );
    hydrate();
    return temp;
  }

  Future<void> unlockUser({
    required AppUser admin,
    required String targetUserId,
  }) async {
    await _auth.unlockUser(admin: admin, targetUserId: targetUserId);
    hydrate();
  }

  // ----- Logs -----
  List<ActivityLog> allLogs() => _logs.all();

  List<ActivityLog> logsForUser(String userId, {int? limit}) =>
      _logs.query(userId: userId, limit: limit);

  List<ActivityLog> queryLogs({
    String? userId,
    Set<ActivityType>? types,
    Set<LogCategory>? categories,
    DateTime? from,
    DateTime? to,
    int? limit,
  }) =>
      _logs.query(
        userId: userId,
        types: types,
        categories: categories,
        from: from,
        to: to,
        limit: limit,
      );

  Future<void> clearAllLogs() async {
    await _logs.clearAll();
    notifyListeners();
  }

  Map<LogCategory, int> categoryCountsForUser(String userId) =>
      _logs.countByCategoryForUser(userId);

  int loginsInLastDays(int days, {String? userId}) =>
      _logs.loginsInLastDays(days, userId: userId);
}
