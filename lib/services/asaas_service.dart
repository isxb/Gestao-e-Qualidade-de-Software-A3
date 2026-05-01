import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/subscription_plan.dart';

/// Snapshot tipado de uma subscription no Asaas — apenas o que o app
/// precisa. A API devolve mais campos, mas mantemos o mínimo para evitar
/// acoplamento desnecessário ao formato do gateway.
class AsaasSubscription {
  AsaasSubscription({
    required this.id,
    required this.status,
    this.paymentLink,
    this.startedAt,
    this.nextDueDate,
  });

  final String id;
  final String status;
  final String? paymentLink;
  final DateTime? startedAt;
  final DateTime? nextDueDate;
}

/// Erro lançado por chamadas ao Asaas. Inclui o `code` HTTP e a mensagem
/// que pode ser exibida ao usuário (já em português, quando possível).
class AsaasException implements Exception {
  AsaasException(this.code, this.message, {this.payload});
  final int code;
  final String message;
  final dynamic payload;
  @override
  String toString() => 'AsaasException($code): $message';
}

/// Cliente do gateway de pagamento Asaas.
///
/// ⚠️ **AVISO DE SEGURANÇA**
/// A API key do Asaas **não deve ficar no app em produção** — qualquer
/// pessoa que abrir o APK pode extrair a string e cobrar/cancelar em
/// nome do operador. O caminho seguro:
///
///   1. Subir um backend próprio (Cloud Functions, Supabase Edge,
///      Lambda, etc.) que guarde a API key em variáveis de ambiente.
///   2. Apontar [_baseUrl] para esse backend (ex.:
///      `https://api.suaempresa.com.br/payments`).
///   3. O backend repassa as chamadas autenticadas para `api.asaas.com`.
///
/// Para acelerar o desenvolvimento, esta classe permite chamar o Asaas
/// **diretamente** quando `ASAAS_PROXY_BASE_URL` está vazio. Isso só é
/// aceitável em ambiente sandbox — nunca em produção.
class AsaasService {
  AsaasService._();
  static final AsaasService instance = AsaasService._();

  /// URL do proxy próprio (recomendado em produção). Quando definida,
  /// todas as chamadas vão para lá em vez do Asaas direto.
  String get _proxyBaseUrl =>
      (_envOrEmpty('ASAAS_PROXY_BASE_URL')).trim();

  /// URL base do Asaas. Sandbox por padrão; troque para produção via .env
  /// quando habilitar o ambiente real.
  String get _asaasBaseUrl {
    final String fromEnv = _envOrEmpty('ASAAS_BASE_URL');
    return fromEnv.isNotEmpty ? fromEnv : 'https://sandbox.asaas.com/api/v3';
  }

  String get _baseUrl =>
      _proxyBaseUrl.isNotEmpty ? _proxyBaseUrl : _asaasBaseUrl;

  String get _apiKey => _envOrEmpty('ASAAS_API_KEY');

  /// Lê uma chave do `.env` de forma defensiva: se o arquivo nem foi
  /// carregado, devolve string vazia em vez de explodir.
  String _envOrEmpty(String key) {
    try {
      return (dotenv.env[key] ?? '').trim();
    } catch (_) {
      return '';
    }
  }

  bool get _isProxied => _proxyBaseUrl.isNotEmpty;

  /// Cabeçalhos comuns. Quando estamos batendo direto no Asaas, mandamos
  /// `access_token`. Quando estamos no proxy, espera-se que o backend
  /// próprio cuide dessa parte e exija um token de sessão (ex.: Bearer
  /// JWT) — isso fica como TODO para quando o backend existir.
  Map<String, String> get _headers => <String, String>{
        'Content-Type': 'application/json',
        if (!_isProxied && _apiKey.isNotEmpty) 'access_token': _apiKey,
      };

  void _ensureConfigured() {
    if (_isProxied) return;
    if (_apiKey.isEmpty) {
      throw AsaasException(
        0,
        'Asaas não configurado. Defina ASAAS_API_KEY no .env ou aponte '
        'ASAAS_PROXY_BASE_URL para o seu backend.',
      );
    }
  }

  Uri _uri(String path) {
    final String cleanBase =
        _baseUrl.endsWith('/') ? _baseUrl.substring(0, _baseUrl.length - 1) : _baseUrl;
    final String cleanPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$cleanBase$cleanPath');
  }

  static const Duration _httpTimeout = Duration(seconds: 20);

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    _ensureConfigured();
    final http.Response res = await http
        .post(
          _uri(path),
          headers: _headers,
          body: jsonEncode(body),
        )
        .timeout(_httpTimeout);
    return _decode(res);
  }

  Future<dynamic> _get(String path) async {
    _ensureConfigured();
    final http.Response res =
        await http.get(_uri(path), headers: _headers).timeout(_httpTimeout);
    return _decode(res);
  }

  Future<dynamic> _delete(String path) async {
    _ensureConfigured();
    final http.Response res = await http
        .delete(_uri(path), headers: _headers)
        .timeout(_httpTimeout);
    return _decode(res);
  }

  dynamic _decode(http.Response res) {
    final dynamic decoded =
        res.body.isEmpty ? null : jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return decoded;
    }
    final String msg = decoded is Map<String, dynamic>
        ? (decoded['errors'] is List && (decoded['errors'] as List).isNotEmpty
            ? (decoded['errors'] as List)
                .map((dynamic e) =>
                    e is Map ? (e['description'] ?? e.toString()) : e)
                .join('; ')
            : (decoded['message'] ?? res.reasonPhrase ?? 'Erro Asaas'))
        : (res.reasonPhrase ?? 'Erro Asaas');
    throw AsaasException(res.statusCode, msg.toString(), payload: decoded);
  }

  // ============================================================
  // Customers
  // ============================================================

  /// Cria um cliente no Asaas. CPF/CNPJ é exigência do gateway no Brasil.
  /// Retorna o `id` do customer recém-criado.
  Future<String> createCustomer({
    required String name,
    required String email,
    required String cpfCnpj,
    String? externalRef,
  }) async {
    final dynamic res = await _post('/customers', <String, dynamic>{
      'name': name,
      'email': email,
      'cpfCnpj': cpfCnpj.replaceAll(RegExp(r'\D'), ''),
      if (externalRef != null) 'externalReference': externalRef,
    });
    if (res is Map<String, dynamic> && res['id'] is String) {
      return res['id'] as String;
    }
    throw AsaasException(0, 'Resposta inesperada ao criar cliente.', payload: res);
  }

  // ============================================================
  // Subscriptions
  // ============================================================

  /// Cria uma assinatura recorrente no Asaas para o `customerId` indicado.
  ///
  /// Mapeamos nosso [SubscriptionPlan.type] para o `cycle` do Asaas:
  /// - `monthly` → `MONTHLY`
  /// - `yearly`  → `YEARLY`
  Future<AsaasSubscription> createSubscription({
    required String customerId,
    required SubscriptionPlan plan,
  }) async {
    final String cycle =
        plan.type == PlanType.yearly ? 'YEARLY' : 'MONTHLY';
    final double valueReais = plan.priceCents / 100;
    final String nextDueDate =
        DateTime.now().add(const Duration(days: 1)).toIso8601String().split('T').first;

    final dynamic res = await _post('/subscriptions', <String, dynamic>{
      'customer': customerId,
      'billingType': plan.asaasBillingType,
      'value': valueReais,
      'nextDueDate': nextDueDate,
      'cycle': cycle,
      'description': '${plan.title} • EvoluaPRO',
    });

    if (res is! Map<String, dynamic>) {
      throw AsaasException(0, 'Resposta inesperada ao criar assinatura.',
          payload: res);
    }

    final String id = (res['id'] ?? '') as String;
    if (id.isEmpty) {
      throw AsaasException(
        0,
        'Asaas não retornou ID da assinatura.',
        payload: res,
      );
    }

    // O Asaas devolve um link de fatura/checkout para o primeiro
    // pagamento dentro de `invoiceUrl` ou `paymentLink`. Usamos o
    // primeiro disponível.
    final String? paymentLink = (res['paymentLink'] as String?) ??
        (res['invoiceUrl'] as String?);

    return AsaasSubscription(
      id: id,
      status: (res['status'] as String?) ?? 'PENDING',
      paymentLink: paymentLink,
      nextDueDate: DateTime.tryParse((res['nextDueDate'] as String?) ?? ''),
    );
  }

  Future<AsaasSubscription?> getSubscription(String id) async {
    try {
      final dynamic res = await _get('/subscriptions/$id');
      if (res is! Map<String, dynamic>) return null;
      return AsaasSubscription(
        id: (res['id'] ?? id) as String,
        status: (res['status'] as String?) ?? 'UNKNOWN',
        paymentLink: (res['paymentLink'] as String?) ??
            (res['invoiceUrl'] as String?),
        startedAt: DateTime.tryParse((res['dateCreated'] as String?) ?? ''),
        nextDueDate: DateTime.tryParse((res['nextDueDate'] as String?) ?? ''),
      );
    } on AsaasException catch (e) {
      if (e.code == 404) return null;
      rethrow;
    }
  }

  Future<void> cancelSubscription(String id) async {
    await _delete('/subscriptions/$id');
  }
}
