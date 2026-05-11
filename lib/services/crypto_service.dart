import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// Implementação de PBKDF2-HMAC-SHA256 para hashing de senhas.
/// Mantém o fluxo de autenticação totalmente local, sem dependência
/// de backend, preservando segurança em nível de prática recomendada.
class CryptoService {
  CryptoService._();

  /// Padrão atual (OWASP 2024 recomenda ≥ 600.000 para PBKDF2-SHA256).
  /// Mantemos 150.000 para equilíbrio entre segurança e UX em dispositivos
  /// modestos (principalmente mobile). O valor fica armazenado por usuário
  /// em [AppUser.iterations] para upgrade transparente no futuro.
  static const int defaultIterations = 150000;
  static const int saltBytes = 16;
  static const int keyBytes = 32;

  /// Gera um salt aleatório seguro em base64.
  static String generateSalt() {
    final Random rnd = Random.secure();
    final List<int> bytes = List<int>.generate(saltBytes, (_) => rnd.nextInt(256));
    return base64Encode(bytes);
  }

  /// Gera um token criptograficamente seguro (para sessões, resets, etc).
  static String generateToken({int bytes = 32}) {
    final Random rnd = Random.secure();
    final List<int> raw = List<int>.generate(bytes, (_) => rnd.nextInt(256));
    return base64UrlEncode(raw).replaceAll('=', '');
  }

  /// Gera uma senha temporária legível (para admin reset/criação).
  /// Formato: `EV-XXXX-XXXX` (8 chars alfanuméricos).
  static String generateTempPassword() {
    const String alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final Random rnd = Random.secure();
    String chunk(int n) =>
        List<int>.generate(n, (_) => rnd.nextInt(alphabet.length))
            .map((int i) => alphabet[i])
            .join();
    return 'EV-${chunk(4)}-${chunk(4)}';
  }

  /// Produz um hash PBKDF2-HMAC-SHA256 da senha usando o salt fornecido.
  /// Retorna o hash em base64. [iterations] permite upgrade controlado.
  static String hashPassword({
    required String password,
    required String saltBase64,
    int iterations = defaultIterations,
  }) {
    final Uint8List salt = base64Decode(saltBase64);
    final List<int> derived =
        _pbkdf2(utf8.encode(password), salt, iterations, keyBytes);
    return base64Encode(derived);
  }

  /// Verifica uma senha em tempo constante contra o hash.
  static bool verifyPassword({
    required String password,
    required String expectedHashBase64,
    required String saltBase64,
    required int iterations,
  }) {
    final String computed = hashPassword(
      password: password,
      saltBase64: saltBase64,
      iterations: iterations,
    );
    return _constantTimeEquals(computed, expectedHashBase64);
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    int diff = 0;
    for (int i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }

  // ============================================================
  // PBKDF2-HMAC-SHA256 — RFC 2898
  // ============================================================
  static List<int> _pbkdf2(
    List<int> password,
    List<int> salt,
    int iterations,
    int keyLength,
  ) {
    final Hmac hmac = Hmac(sha256, password);
    const int hLen = 32; // SHA-256 output size
    final int blockCount = (keyLength / hLen).ceil();
    final List<int> result = <int>[];

    for (int blockIndex = 1; blockIndex <= blockCount; blockIndex++) {
      final List<int> saltWithIndex = <int>[...salt, ..._intToBytes(blockIndex)];
      List<int> u = hmac.convert(saltWithIndex).bytes;
      final List<int> block = List<int>.from(u);

      for (int iter = 1; iter < iterations; iter++) {
        u = hmac.convert(u).bytes;
        for (int b = 0; b < block.length; b++) {
          block[b] ^= u[b];
        }
      }
      result.addAll(block);
    }

    return result.sublist(0, keyLength);
  }

  static List<int> _intToBytes(int value) {
    return <int>[
      (value >> 24) & 0xff,
      (value >> 16) & 0xff,
      (value >> 8) & 0xff,
      value & 0xff,
    ];
  }

  /// Avaliação simples da força da senha (0–4).
  static int passwordStrength(String password) {
    int score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password)) {
      score++;
    }
    if (RegExp(r'\d').hasMatch(password)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score++;
    return score.clamp(0, 4);
  }

  // ============================================================
  // Versões assíncronas — rodam o PBKDF2 num Isolate via compute()
  // para não travar a UI thread (150k iterações ≈ 200–400ms no mobile).
  // ============================================================

  /// Versão async de [hashPassword]. Prefira este método em código de UI.
  static Future<String> hashPasswordAsync({
    required String password,
    required String saltBase64,
    int iterations = defaultIterations,
  }) {
    return compute(
      (List<String> args) => hashPassword(
        password: args[0],
        saltBase64: args[1],
        iterations: int.parse(args[2]),
      ),
      <String>[password, saltBase64, iterations.toString()],
    );
  }

  /// Versão async de [verifyPassword]. Prefira este método em código de UI.
  static Future<bool> verifyPasswordAsync({
    required String password,
    required String expectedHashBase64,
    required String saltBase64,
    required int iterations,
  }) {
    return compute(
      (List<String> args) => verifyPassword(
        password: args[0],
        expectedHashBase64: args[1],
        saltBase64: args[2],
        iterations: int.parse(args[3]),
      ),
      <String>[password, expectedHashBase64, saltBase64, iterations.toString()],
    );
  }

  static String passwordStrengthLabel(int score) {
    switch (score) {
      case 0:
      case 1:
        return 'Fraca';
      case 2:
        return 'Regular';
      case 3:
        return 'Boa';
      case 4:
      default:
        return 'Excelente';
    }
  }
}


