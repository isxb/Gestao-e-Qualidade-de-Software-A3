import 'package:uuid/uuid.dart';

import '../models/activity_log.dart';
import 'storage_service.dart';

/// Registra e consulta eventos (auditoria local).
///
/// Eventos são armazenados em `shared_preferences` via [StorageService],
/// com cap automático para evitar crescimento indefinido. As APIs de
/// consulta permitem filtro combinado por usuário, tipo e janela temporal.
class LogService {
  LogService._();

  static final LogService instance = LogService._();

  final Uuid _uuid = const Uuid();
  final StorageService _storage = StorageService.instance;

  List<ActivityLog> _cache = <ActivityLog>[];
  bool _hydrated = false;

  /// Deve ser chamado uma vez no startup, após [StorageService.init].
  void hydrate() {
    _cache = _storage.loadLogs()
      ..sort((ActivityLog a, ActivityLog b) =>
          b.timestamp.compareTo(a.timestamp));
    _hydrated = true;
  }

  void _ensureHydrated() {
    if (!_hydrated) hydrate();
  }

  /// Registra um novo evento. Retorna o [ActivityLog] gravado (para uso
  /// imediato sem precisar re-consultar o storage).
  Future<ActivityLog> record({
    required String userId,
    required String userDisplayName,
    required ActivityType type,
    required String description,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) async {
    _ensureHydrated();
    final ActivityLog log = ActivityLog(
      id: _uuid.v4(),
      userId: userId,
      userDisplayName: userDisplayName,
      type: type,
      description: description,
      timestamp: DateTime.now(),
      metadata: metadata,
    );
    _cache = <ActivityLog>[log, ..._cache];
    await _storage.saveLogs(_cache);
    return log;
  }

  /// Retorna todos os logs (já em ordem decrescente).
  List<ActivityLog> all() {
    _ensureHydrated();
    return List<ActivityLog>.unmodifiable(_cache);
  }

  /// Filtro combinado. Qualquer parâmetro nulo é ignorado.
  List<ActivityLog> query({
    String? userId,
    Set<ActivityType>? types,
    Set<LogCategory>? categories,
    DateTime? from,
    DateTime? to,
    int? limit,
  }) {
    _ensureHydrated();
    Iterable<ActivityLog> it = _cache;
    if (userId != null) it = it.where((ActivityLog l) => l.userId == userId);
    if (types != null) it = it.where((ActivityLog l) => types.contains(l.type));
    if (categories != null) {
      it = it.where((ActivityLog l) => categories.contains(l.type.category));
    }
    if (from != null) it = it.where((ActivityLog l) => !l.timestamp.isBefore(from));
    if (to != null) it = it.where((ActivityLog l) => !l.timestamp.isAfter(to));
    final List<ActivityLog> out = it.toList();
    if (limit != null && out.length > limit) {
      return out.sublist(0, limit);
    }
    return out;
  }

  /// Conta eventos de um usuário para cada categoria (para cards de
  /// estatística no painel admin).
  Map<LogCategory, int> countByCategoryForUser(String userId) {
    _ensureHydrated();
    final Map<LogCategory, int> counts = <LogCategory, int>{
      for (final LogCategory c in LogCategory.values) c: 0,
    };
    for (final ActivityLog l in _cache) {
      if (l.userId == userId) counts[l.type.category] = counts[l.type.category]! + 1;
    }
    return counts;
  }

  /// Número de logins no intervalo (últimos N dias).
  int loginsInLastDays(int days, {String? userId}) {
    _ensureHydrated();
    final DateTime cutoff = DateTime.now().subtract(Duration(days: days));
    return _cache
        .where((ActivityLog l) =>
            l.type == ActivityType.loginSuccess &&
            l.timestamp.isAfter(cutoff) &&
            (userId == null || l.userId == userId))
        .length;
  }

  /// Limpa todos os eventos (apenas admin).
  Future<void> clearAll() async {
    _cache = <ActivityLog>[];
    await _storage.clearLogs();
  }
}
