import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/activity_log.dart';
import '../models/saved_evolution.dart';
import '../models/user.dart';

/// Camada de persistência cross-platform.
///
/// - Evoluções, usuários e logs → `shared_preferences` (JSON).
/// - Sessão ativa → `flutter_secure_storage` (Keychain/KeyStore/DPAPI).
/// - API key → `shared_preferences` (override local).
///
/// Tudo local ao dispositivo. A implementação foi desenhada para que
/// no futuro apenas este arquivo precise mudar para rotear para um
/// backend remoto, sem tocar no resto do app.
class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  // --- Keys ---
  static const String _kEvolutionsKey = 'evoluaPro_evolutions';
  static const String _kApiKeyKey = 'evoluaPro_api_key';
  static const String _kUsersKey = 'evoluaPro_users';
  static const String _kLogsKey = 'evoluaPro_logs';
  static const String _kBootstrappedKey = 'evoluaPro_bootstrapped';
  static const String _kSessionKey = 'evoluaPro_session_v1';
  static const String _kThemeKey = 'evoluaPro_theme';

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
  // API Key
  // ============================================================
  String? loadApiKey() => _store.getString(_kApiKeyKey);
  Future<void> saveApiKey(String key) async {
    await _store.setString(_kApiKeyKey, key.trim());
  }

  Future<void> clearApiKey() async {
    await _store.remove(_kApiKeyKey);
  }

  // ============================================================
  // Tema (light / dark / system)
  // ============================================================
  String? loadThemeMode() => _store.getString(_kThemeKey);

  Future<void> saveThemeMode(String mode) async {
    await _store.setString(_kThemeKey, mode);
  }

  // ============================================================
  // Usuários
  // ============================================================
  List<AppUser> loadUsers() {
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

  Future<void> saveUsers(List<AppUser> users) async {
    final String raw =
        jsonEncode(users.map((AppUser u) => u.toJson()).toList());
    await _store.setString(_kUsersKey, raw);
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
    // Mantém os mais recentes (ordem decrescente esperada).
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
    } catch (_) {
      // ignora falhas silenciosamente — ambiente de teste ou web.
    }
  }
}
