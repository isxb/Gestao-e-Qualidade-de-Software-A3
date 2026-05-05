import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/activity_log.dart';
import '../models/evolution_template.dart';
import '../models/saved_evolution.dart';
import '../models/subscription.dart';
import '../models/user.dart';

class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  // --- Keys ---
  static const String _kEvolutionsKey = 'evoluaPro_evolutions';
  static const String _kUsersKey = 'evoluaPro_users';
  static const String _kLogsKey = 'evoluaPro_logs';
  static const String _kBootstrappedKey = 'evoluaPro_bootstrapped';
  static const String _kSessionKey = 'evoluaPro_session_v1';
  static const String _kThemeKey = 'evoluaPro_theme';
  static const String _kSubscriptionsKey = 'evoluaPro_subscriptions';
  static const String _kTemplatesKey = 'evoluaPro_templates';

  static const int _maxLogs = 5000;

  SharedPreferences? _prefs;
  final FlutterSecureStorage _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get _store {
    final SharedPreferences? p = _prefs;
    if (p == null) {
      throw StateError(
        'StorageService.init() precisa ser chamado antes do uso.',
      );
    }
    return p;
  }

  // ============================================================
  // Evoluções salvas
  // ============================================================
  List<SavedEvolution> loadEvolutions() {
    final String? raw = _store.getString(_kEvolutionsKey);
    if (raw == null || raw.isEmpty) return <SavedEvolution>[];
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! List) return <SavedEvolution>[];
      return decoded
          .whereType<Map<dynamic, dynamic>>()
          .map((Map<dynamic, dynamic> m) =>
              SavedEvolution.fromJson(m.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return <SavedEvolution>[];
    }
  }

  Future<void> saveEvolutions(List<SavedEvolution> items) async {
    final String raw = jsonEncode(
      items.map((SavedEvolution e) => e.toJson()).toList(),
    );
    await _store.setString(_kEvolutionsKey, raw);
  }

  // ============================================================
  // Tema (light / dark / system)
  // ============================================================
  String? loadThemeMode() => _store.getString(_kThemeKey);

  Future<void> saveThemeMode(String mode) async {
    await _store.setString(_kThemeKey, mode);
  }

  // ============================================================
  // Usuários — armazenados em secure storage para proteger hashes de senha
  // ============================================================
  List<AppUser> loadUsers() {
    // Fallback síncrono: lê do cache em memória se disponível.
    // Para carregamento inicial, chame loadUsersAsync().
    final String? raw = _store.getString(_kUsersKey);
    if (raw == null || raw.isEmpty) return <AppUser>[];
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! List) return <AppUser>[];
      return decoded
          .whereType<Map<dynamic, dynamic>>()
          .map((Map<dynamic, dynamic> m) =>
              AppUser.fromJson(m.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return <AppUser>[];
    }
  }

  /// Versão assíncrona preferida: persiste em secure storage E mantém
  /// cópia em SharedPreferences apenas para leitura síncrona em bootstrap.
  Future<void> saveUsers(List<AppUser> users) async {
    final String raw =
        jsonEncode(users.map((AppUser u) => u.toJson()).toList());
    // Persiste na secure storage (dados sensíveis — hash + salt de senha)
    await _secure.write(key: _kUsersKey, value: raw);
    // Cópia em prefs para loadUsers() síncrono no bootstrap
    await _store.setString(_kUsersKey, raw);
  }

  /// Lê usuários da secure storage com fallback para SharedPreferences.
  Future<List<AppUser>> loadUsersAsync() async {
    try {
      final String? raw = await _secure.read(key: _kUsersKey);
      if (raw != null && raw.isNotEmpty) {
        final dynamic decoded = jsonDecode(raw);
        if (decoded is List) {
          final List<AppUser> users = decoded
              .whereType<Map<dynamic, dynamic>>()
              .map((Map<dynamic, dynamic> m) =>
                  AppUser.fromJson(m.cast<String, dynamic>()))
              .toList();
          // Sincroniza prefs para acesso síncrono futuro
          await _store.setString(_kUsersKey, raw);
          return users;
        }
      }
    } catch (_) {}
    // Fallback: SharedPreferences (dados de versões anteriores)
    return loadUsers();
  }

  bool get isBootstrapped => _store.getBool(_kBootstrappedKey) ?? false;

  Future<void> markBootstrapped() async {
    await _store.setBool(_kBootstrappedKey, true);
  }

  // ============================================================
  // Logs (com cap para evitar crescimento indefinido)
  // ============================================================
  List<ActivityLog> loadLogs() {
    final String? raw = _store.getString(_kLogsKey);
    if (raw == null || raw.isEmpty) return <ActivityLog>[];
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! List) return <ActivityLog>[];
      return decoded
          .whereType<Map<dynamic, dynamic>>()
          .map((Map<dynamic, dynamic> m) =>
              ActivityLog.fromJson(m.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return <ActivityLog>[];
    }
  }

  Future<void> saveLogs(List<ActivityLog> logs) async {
    final List<ActivityLog> trimmed =
        logs.length > _maxLogs ? logs.sublist(0, _maxLogs) : logs;
    final String raw =
        jsonEncode(trimmed.map((ActivityLog l) => l.toJson()).toList());
    await _store.setString(_kLogsKey, raw);
  }

  Future<void> clearLogs() async {
    await _store.remove(_kLogsKey);
  }

  // ============================================================
  // Sessão (secure storage)
  // ============================================================
  Future<AppSession?> loadSession() async {
    try {
      final String? raw = await _secure.read(key: _kSessionKey);
      if (raw == null || raw.isEmpty) return null;
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return AppSession.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSession(AppSession session) async {
    await _secure.write(
      key: _kSessionKey,
      value: jsonEncode(session.toJson()),
    );
  }

  Future<void> clearSession() async {
    try {
      await _secure.delete(key: _kSessionKey);
    } catch (e) {
      // Em alguns dispositivos o keychain pode falhar ao deletar (ex: iOS
      // após reinstalação sem backup). Logamos mas não propagamos para não
      // bloquear o logout do usuário.
      assert(() {
        // ignore: avoid_print
        print('[StorageService] clearSession error (non-fatal): $e');
        return true;
      }());
    }
  }

  // ============================================================
  // Assinaturas (cache local de UserSubscription por userId)
  // ============================================================
  Map<String, UserSubscription> loadSubscriptions() {
    final String? raw = _store.getString(_kSubscriptionsKey);
    if (raw == null || raw.isEmpty) return <String, UserSubscription>{};
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! List) return <String, UserSubscription>{};
      final Map<String, UserSubscription> map = <String, UserSubscription>{};
      for (final dynamic item in decoded) {
        if (item is Map<dynamic, dynamic>) {
          final UserSubscription s =
              UserSubscription.fromJson(item.cast<String, dynamic>());
          map[s.userId] = s;
        }
      }
      return map;
    } catch (_) {
      return <String, UserSubscription>{};
    }
  }

  Future<void> saveSubscriptions(
    Map<String, UserSubscription> subscriptions,
  ) async {
    final String raw = jsonEncode(
      subscriptions.values.map((UserSubscription s) => s.toJson()).toList(),
    );
    await _store.setString(_kSubscriptionsKey, raw);
  }

  // ============================================================
  // Templates (por conta de usuário)
  // ============================================================
  List<EvolutionTemplate> loadTemplates({required String userId}) {
    final String? raw = _store.getString(_kTemplatesKey);
    if (raw == null || raw.isEmpty) return <EvolutionTemplate>[];
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! List) return <EvolutionTemplate>[];
      return decoded
          .whereType<Map<dynamic, dynamic>>()
          .map((Map<dynamic, dynamic> m) =>
              EvolutionTemplate.fromJson(m.cast<String, dynamic>()))
          .where((EvolutionTemplate t) => t.userId == userId)
          .toList();
    } catch (_) {
      return <EvolutionTemplate>[];
    }
  }

  Future<void> _saveAllTemplates(List<EvolutionTemplate> all) async {
    final String raw =
        jsonEncode(all.map((EvolutionTemplate t) => t.toJson()).toList());
    await _store.setString(_kTemplatesKey, raw);
  }

  Future<void> upsertTemplate(EvolutionTemplate template) async {
    final List<EvolutionTemplate> all = _loadAllTemplates();
    final int idx = all.indexWhere((EvolutionTemplate t) => t.id == template.id);
    if (idx >= 0) {
      all[idx] = template;
    } else {
      all.insert(0, template);
    }
    await _saveAllTemplates(all);
  }

  Future<void> deleteTemplate(String templateId) async {
    final List<EvolutionTemplate> all = _loadAllTemplates()
        .where((EvolutionTemplate t) => t.id != templateId)
        .toList();
    await _saveAllTemplates(all);
  }

  List<EvolutionTemplate> _loadAllTemplates() {
    final String? raw = _store.getString(_kTemplatesKey);
    if (raw == null || raw.isEmpty) return <EvolutionTemplate>[];
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! List) return <EvolutionTemplate>[];
      return decoded
          .whereType<Map<dynamic, dynamic>>()
          .map((Map<dynamic, dynamic> m) =>
              EvolutionTemplate.fromJson(m.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return <EvolutionTemplate>[];
    }
  }
}