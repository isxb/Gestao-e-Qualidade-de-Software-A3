import 'subscription_plan.dart';

/// Estado de uma assinatura no Asaas.
///
/// Mapeia as transições mais comuns que o gateway devolve. O `unknown`
/// existe apenas como fallback defensivo para versões futuras da API.
enum SubscriptionStatus {
  /// Sem assinatura paga ativa — usuário no plano free.
  none,

  /// Assinatura criada mas ainda não confirmada (aguardando 1º pagamento).
  pending,

  /// Pagamento em dia — usuário tem acesso premium.
  active,

  /// Pagamento atrasado, ainda dentro do grace period configurável.
  pastDue,

  /// Cancelada (pelo usuário ou por inadimplência).
  cancelled,

  /// Expirada (plano anual chegou ao fim sem renovação).
  expired,

  unknown,
}

extension SubscriptionStatusX on SubscriptionStatus {
  String get asString => name;

  /// Estados que ainda dão acesso ao premium.
  bool get grantsPremium {
    switch (this) {
      case SubscriptionStatus.active:
      case SubscriptionStatus.pastDue:
        return true;
      case SubscriptionStatus.none:
      case SubscriptionStatus.pending:
      case SubscriptionStatus.cancelled:
      case SubscriptionStatus.expired:
      case SubscriptionStatus.unknown:
        return false;
    }
  }

  String get label {
    switch (this) {
      case SubscriptionStatus.none:
        return 'Sem assinatura';
      case SubscriptionStatus.pending:
        return 'Aguardando pagamento';
      case SubscriptionStatus.active:
        return 'Ativa';
      case SubscriptionStatus.pastDue:
        return 'Pagamento atrasado';
      case SubscriptionStatus.cancelled:
        return 'Cancelada';
      case SubscriptionStatus.expired:
        return 'Expirada';
      case SubscriptionStatus.unknown:
        return 'Desconhecido';
    }
  }

  static SubscriptionStatus fromString(String? raw) {
    switch (raw) {
      case 'pending':
        return SubscriptionStatus.pending;
      case 'active':
        return SubscriptionStatus.active;
      case 'pastDue':
        return SubscriptionStatus.pastDue;
      case 'cancelled':
        return SubscriptionStatus.cancelled;
      case 'expired':
        return SubscriptionStatus.expired;
      case 'none':
        return SubscriptionStatus.none;
      default:
        return SubscriptionStatus.unknown;
    }
  }

  /// Mapeia status retornado pela API do Asaas para o nosso enum.
  /// A API usa: `ACTIVE`, `INACTIVE`, `EXPIRED`, etc.
  static SubscriptionStatus fromAsaas(String? raw) {
    switch (raw?.toUpperCase()) {
      case 'ACTIVE':
        return SubscriptionStatus.active;
      case 'INACTIVE':
        return SubscriptionStatus.cancelled;
      case 'EXPIRED':
        return SubscriptionStatus.expired;
      case 'OVERDUE':
        return SubscriptionStatus.pastDue;
      default:
        return SubscriptionStatus.unknown;
    }
  }
}

/// Snapshot da assinatura de um usuário, persistido localmente para
/// gating de UI sem precisar bater no Asaas a cada frame. Atualizado
/// quando o app sincroniza com o gateway (ou recebe webhook via backend).
class UserSubscription {
  UserSubscription({
    required this.userId,
    required this.planType,
    required this.status,
    this.asaasSubscriptionId,
    this.asaasCustomerId,
    this.checkoutUrl,
    this.startedAt,
    this.expiresAt,
    this.lastSyncAt,
  });

  /// ID do usuário dono da assinatura.
  final String userId;

  /// Plano correspondente (free, monthly, yearly).
  final PlanType planType;

  /// Estado atual segundo o último sync.
  final SubscriptionStatus status;

  /// ID da subscription no Asaas. `null` para o plano free.
  final String? asaasSubscriptionId;

  /// ID do cliente no Asaas (espelhado em [AppUser.asaasCustomerId]).
  final String? asaasCustomerId;

  /// Página de pagamento que pode ser reaberta enquanto a subscription
  /// está pendente (1º pagamento ainda não confirmado).
  final String? checkoutUrl;

  /// Quando a assinatura foi criada (após confirmação do pagamento).
  final DateTime? startedAt;

  /// Quando a assinatura expira (anual) ou data do próximo ciclo.
  final DateTime? expiresAt;

  /// Última vez que sincronizamos com o Asaas.
  final DateTime? lastSyncAt;

  bool get isActive => status.grantsPremium;

  bool get isPaidPlan =>
      planType == PlanType.monthly || planType == PlanType.yearly;

  /// Atalho — o usuário tem acesso premium agora?
  bool get isPremium => isPaidPlan && isActive;

  UserSubscription copyWith({
    PlanType? planType,
    SubscriptionStatus? status,
    String? asaasSubscriptionId,
    String? asaasCustomerId,
    String? checkoutUrl,
    DateTime? startedAt,
    DateTime? expiresAt,
    DateTime? lastSyncAt,
    bool clearCheckoutUrl = false,
    bool clearAsaasSubscription = false,
  }) {
    return UserSubscription(
      userId: userId,
      planType: planType ?? this.planType,
      status: status ?? this.status,
      asaasSubscriptionId: clearAsaasSubscription
          ? null
          : asaasSubscriptionId ?? this.asaasSubscriptionId,
      asaasCustomerId: asaasCustomerId ?? this.asaasCustomerId,
      checkoutUrl: clearCheckoutUrl ? null : checkoutUrl ?? this.checkoutUrl,
      startedAt: startedAt ?? this.startedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }

  /// Constrói o snapshot "free" padrão para um usuário recém-cadastrado.
  factory UserSubscription.free(String userId) => UserSubscription(
        userId: userId,
        planType: PlanType.free,
        status: SubscriptionStatus.none,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'userId': userId,
        'planType': planType.asString,
        'status': status.asString,
        'asaasSubscriptionId': asaasSubscriptionId,
        'asaasCustomerId': asaasCustomerId,
        'checkoutUrl': checkoutUrl,
        'startedAt': startedAt?.toIso8601String(),
        'expiresAt': expiresAt?.toIso8601String(),
        'lastSyncAt': lastSyncAt?.toIso8601String(),
      };

  static UserSubscription fromJson(Map<String, dynamic> j) {
    return UserSubscription(
      userId: j['userId'] as String,
      planType: PlanTypeX.fromString(j['planType'] as String?),
      status: SubscriptionStatusX.fromString(j['status'] as String?),
      asaasSubscriptionId: j['asaasSubscriptionId'] as String?,
      asaasCustomerId: j['asaasCustomerId'] as String?,
      checkoutUrl: j['checkoutUrl'] as String?,
      startedAt: j['startedAt'] == null
          ? null
          : DateTime.tryParse(j['startedAt'] as String),
      expiresAt: j['expiresAt'] == null
          ? null
          : DateTime.tryParse(j['expiresAt'] as String),
      lastSyncAt: j['lastSyncAt'] == null
          ? null
          : DateTime.tryParse(j['lastSyncAt'] as String),
    );
  }
}
