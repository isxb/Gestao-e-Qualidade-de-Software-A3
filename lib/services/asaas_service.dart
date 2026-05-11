import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/subscription_plan.dart';

/// Snapshot tipado de uma subscription.
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

/// Erro lançado por chamadas à sua API de pagamentos.
class AsaasException implements Exception {
  AsaasException(this.code, this.message, {this.payload});
  final int code;
  final String message;
  final dynamic payload;
  @override
  String toString() => 'AsaasException($code): $message';
}

/// Cliente de requisições de pagamento.
/// Agora configurado de forma segura: ele fala APENAS com o seu backend (Proxy)
/// e NUNCA carrega a chave de API do Asaas no lado do cliente.
class AsaasService {
  AsaasService._();
  static final AsaasService instance = AsaasService._();

  /// URL do seu próprio backend (Proxy).
  /// Exemplo no .env: PAYMENTS_API_URL=https://api.suaempresa.com.br/payments
  String get _baseUrl {
    try {
      final String url = (dotenv.env['PAYMENTS_API_URL'] ?? '').trim();
      // Se não houver URL no .env, aponta para um backend local (ambiente de dev)
      return url.isNotEmpty ? url : 'http://localhost:3000/payments'; 
    } catch (_) {
      return 'http://localhost:3000/payments';
    }
  }

  /// Cabeçalhos para comunicar com o SEU backend.
  /// Futuramente, você deve enviar o token de autenticação (JWT, Firebase Auth, etc)
  /// para que seu backend saiba qual usuário está solicitando o pagamento.
  Map<String, String> get _headers => <String, String>{
        'Content-Type': 'application/json',
        // TODO: Adicionar o token de autenticação da sessão do usuário aqui
        // 'Authorization': 'Bearer token_do_usuario',
      };

  Uri _uri(String path) {
    final String cleanBase =
        _baseUrl.endsWith('/') ? _baseUrl.substring(0, _baseUrl.length - 1) : _baseUrl;
    final String cleanPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$cleanBase$cleanPath');
  }

  static const Duration _httpTimeout = Duration(seconds: 20);

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
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
    final http.Response res =
        await http.get(_uri(path), headers: _headers).timeout(_httpTimeout);
    return _decode(res);
  }

  Future<dynamic> _delete(String path) async {
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
    
    // Tenta extrair a mensagem de erro que vem do seu backend/asaas
    final String msg = decoded is Map<String, dynamic>
        ? (decoded['errors'] is List && (decoded['errors'] as List).isNotEmpty
            ? (decoded['errors'] as List)
                .map((dynamic e) =>
                    e is Map ? (e['description'] ?? e.toString()) : e)
                .join('; ')
            : (decoded['message'] ?? res.reasonPhrase ?? 'Erro no Servidor de Pagamentos'))
        : (res.reasonPhrase ?? 'Erro no Servidor de Pagamentos');
        
    throw AsaasException(res.statusCode, msg.toString(), payload: decoded);
  }

  // ============================================================
  // Customers
  // ============================================================

  /// Solicita ao seu backend a criação de um cliente.
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
    throw AsaasException(0, 'Resposta inesperada ao criar cliente no servidor.', payload: res);
  }

  // ============================================================
  // Subscriptions
  // ============================================================

  /// Solicita ao seu backend a criação de uma assinatura.
  Future<AsaasSubscription> createSubscription({
    required String customerId,
    required SubscriptionPlan plan,
  }) async {
    final String cycle = plan.type == PlanType.yearly ? 'YEARLY' : 'MONTHLY';
    final double valueReais = plan.priceCents / 100;
    
    // Define a data de vencimento para o dia seguinte
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
      throw AsaasException(0, 'Resposta inesperada do servidor ao criar assinatura.',
          payload: res);
    }

    final String id = (res['id'] ?? '') as String;
    if (id.isEmpty) {
      throw AsaasException(0, 'O servidor não retornou o ID da assinatura.', payload: res);
    }

    final String? paymentLink = (res['paymentLink'] as String?) ??
        (res['invoiceUrl'] as String?);

    return AsaasSubscription(
      id: id,
      status: (res['status'] as String?) ?? 'PENDING',
      paymentLink: paymentLink,
      nextDueDate: DateTime.tryParse((res['nextDueDate'] as String?) ?? ''),
    );
  }

  /// Solicita ao seu backend o status atualizado de uma assinatura.
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
      if (e.code == 404) return null; // Não encontrado no servidor
      rethrow;
    }
  }

  /// Solicita ao seu backend o cancelamento de uma assinatura.
  Future<void> cancelSubscription(String id) async {
    await _delete('/subscriptions/$id');
  }
}