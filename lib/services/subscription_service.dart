import '../models/activity_log.dart';
import '../models/subscription.dart';
import '../models/subscription_plan.dart';
import '../models/user.dart';
import '../utils/platform_check.dart';
import 'asaas_service.dart';
import 'log_service.dart';
import 'storage_service.dart';

/// Camada que reúne persistência local + Asaas para o ciclo de vida da
/// assinatura. As telas falam apenas com `SubscriptionProvider`, que
/// por sua vez chama este service. Toda regra de "tem ou não acesso
/// premium" vive aqui.
class SubscriptionService {
  SubscriptionService._();
  static final SubscriptionService instance = SubscriptionService._();

  final StorageService _storage = StorageService.instance;
  final AsaasService _asaas = AsaasService.instance;
  final LogService _logs = LogService.instance;

  /// Cache em memória para evitar I/O em cada chamada de `isPremium`.
  Map<String, UserSubscription>? _cache;

  Map<String, UserSubscription> get _subscriptions {
    return _cache ??= _storage.loadSubscriptions();
  }

  /// Recupera a assinatura local de um usuário. Devolve uma "free"
  /// implícita se nada estiver salvo (fluxo do recém-cadastrado).
  UserSubscription forUser(String userId) {
    return _subscriptions[userId] ?? UserSubscription.free(userId);
  }

  /// Atualiza o cache + storage com o snapshot fornecido.
  Future<void> _persist(UserSubscription sub) async {
    final Map<String, UserSubscription> map =
        Map<String, UserSubscription>.from(_subscriptions);
    map[sub.userId] = sub;
    _cache = map;
    await _storage.saveSubscriptions(map);
  }

  // ============================================================
  // Decisões de gating
  // ============================================================

  /// Concentra a regra final: o usuário pode usar o app neste momento?
  ///
  /// - Em mobile: sempre pode (free com ads ou premium sem ads).
  /// - Em desktop (Windows/macOS/Linux): só com assinatura ativa.
  bool canUseApp(AppUser user) {
    if (PlatformCheck.requiresPremium) {
      return forUser(user.id).isPremium;
    }
    return true;
  }

  /// Mostra anúncios? Apenas em mobile e quando o usuário não tem premium.
  bool shouldShowAds(AppUser user) {
    if (!PlatformCheck.supportsAds) return false;
    return !forUser(user.id).isPremium;
  }

  // ============================================================
  // Checkout
  // ============================================================

  /// Inicia o checkout de um plano pago. Cria customer no Asaas (se
  /// ainda não existir), abre uma subscription e devolve o snapshot
  /// pendente, com a URL de pagamento que a UI pode abrir num browser
  /// externo.
  ///
  /// Em produção, este método deve ser chamado contra um proxy próprio
  /// (ver `AsaasService` para a explicação de segurança da API key).
  Future<UserSubscription> startCheckout({
    required AppUser user,
    required SubscriptionPlan plan,
    required String cpfCnpj,
  }) async {
    if (plan.type == PlanType.free) {
      throw StateError('Plano gratuito não passa por checkout.');
    }

    final UserSubscription current = forUser(user.id);

    // 1. Garante customer no Asaas.
    final String customerId = current.asaasCustomerId ??
        user.asaasCustomerId ??
        await _asaas.createCustomer(
          name: user.displayName,
          email: user.email,
          cpfCnpj: cpfCnpj,
          externalRef: user.id,
        );

    // 2. Cria a subscription.
    final AsaasSubscription created = await _asaas.createSubscription(
      customerId: customerId,
      plan: plan,
    );

    final UserSubscription pending = current.copyWith(
      planType: plan.type,
      status: SubscriptionStatus.pending,
      asaasSubscriptionId: created.id,
      asaasCustomerId: customerId,
      checkoutUrl: created.paymentLink,
      lastSyncAt: DateTime.now(),
    );

    await _persist(pending);

    await _logs.record(
      userId: user.id,
      userDisplayName: user.displayName,
      type: ActivityType.custom,
      description:
          'Checkout iniciado no plano ${plan.title} (${plan.priceLabel}${plan.cycle}).',
      metadata: <String, dynamic>{
        'plan': plan.type.asString,
        'asaasSubscriptionId': created.id,
      },
    );

    return pending;
  }

  /// Sincroniza o status da assinatura com o Asaas. Chamado quando o
  /// usuário volta da página de pagamento ou ao abrir a tela de
  /// gerenciamento.
  Future<UserSubscription> sync(AppUser user) async {
    final UserSubscription current = forUser(user.id);
    if (current.asaasSubscriptionId == null) return current;
    final AsaasSubscription? remote =
        await _asaas.getSubscription(current.asaasSubscriptionId!);
    if (remote == null) return current;

    final UserSubscription updated = current.copyWith(
      status: SubscriptionStatusX.fromAsaas(remote.status),
      startedAt: remote.startedAt ?? current.startedAt,
      expiresAt: remote.nextDueDate ?? current.expiresAt,
      lastSyncAt: DateTime.now(),
    );
    await _persist(updated);
    return updated;
  }

  /// Cancela a assinatura no Asaas e atualiza o snapshot local.
  Future<UserSubscription> cancel(AppUser user) async {
    final UserSubscription current = forUser(user.id);
    if (current.asaasSubscriptionId == null) return current;

    await _asaas.cancelSubscription(current.asaasSubscriptionId!);

    final UserSubscription cancelled = current.copyWith(
      status: SubscriptionStatus.cancelled,
      lastSyncAt: DateTime.now(),
    );
    await _persist(cancelled);

    await _logs.record(
      userId: user.id,
      userDisplayName: user.displayName,
      type: ActivityType.custom,
      description: 'Assinatura cancelada pelo usuário.',
      metadata: <String, dynamic>{
        'asaasSubscriptionId': current.asaasSubscriptionId,
      },
    );

    return cancelled;
  }

  // ============================================================
  // Bypass para desenvolvimento
  // ============================================================

  /// Apenas para testes locais — concede premium sem passar pelo Asaas.
  /// Não chamar de UI de produção.
  Future<void> grantPremiumForDev(AppUser user, PlanType plan) async {
    final UserSubscription updated = forUser(user.id).copyWith(
      planType: plan,
      status: SubscriptionStatus.active,
      lastSyncAt: DateTime.now(),
    );
    await _persist(updated);
  }
}
