import 'package:flutter/foundation.dart';

import '../models/subscription.dart';
import '../models/subscription_plan.dart';
import '../models/user.dart';
import '../services/subscription_service.dart';
import '../utils/platform_check.dart';

/// Estado de assinatura observável pelas telas. Espelha o snapshot do
/// [SubscriptionService] e despacha as ações de checkout/sync/cancel.
class SubscriptionProvider extends ChangeNotifier {
  SubscriptionProvider({SubscriptionService? service})
      : _service = service ?? SubscriptionService.instance;

  final SubscriptionService _service;

  AppUser? _user;
  UserSubscription? _subscription;
  bool _busy = false;
  String? _lastError;

  UserSubscription? get subscription => _subscription;
  bool get isBusy => _busy;
  String? get lastError => _lastError;

  /// ===========================================================
  /// FEATURE FLAG — LIBERAÇÃO PARA AVALIAÇÃO ACADÊMICA
  /// ===========================================================
  /// Quando `true`, a trava de assinatura fica DESATIVADA: o paywall
  /// obrigatório (desktop/Windows) e os anúncios (mobile) são ignorados,
  /// permitindo que o sistema seja usado e avaliado livremente sem uma
  /// assinatura ativa.
  ///
  /// Toda a lógica de assinatura (checkout, Asaas, planos, paywall)
  /// permanece INTACTA no código. Para reativar a trava em produção,
  /// basta alterar este valor para `false`.
  static const bool kBypassSubscriptionLock = true;

  /// Acesso premium ativo agora.
  /// Com [kBypassSubscriptionLock] ligado, sempre retorna `true` para
  /// destravar o app, sem remover a lógica real de assinatura abaixo.
  bool get isPremium =>
      kBypassSubscriptionLock || (_subscription?.isPremium ?? false);

  /// Show ads? Só em mobile e enquanto não há premium.
  bool get shouldShowAds {
    if (_user == null) return false;
    return _service.shouldShowAds(_user!);
  }

  /// Pode usar o app neste device com este usuário?
  /// Em desktop, exige premium; em mobile, sempre verdadeiro.
  bool get canUseApp {
    if (_user == null) return false;
    return _service.canUseApp(_user!);
  }

  /// Indica se o gate de Windows/desktop deve aparecer (paywall obrigatório).
  bool get blockedByPlatform =>
      PlatformCheck.requiresPremium && !isPremium;

  /// Atualiza o usuário "vinculado" — chamado pelo ProxyProvider sempre
  /// que a sessão muda. Recarrega o snapshot da assinatura.
  void bindUser(AppUser? user) {
    _user = user;
    if (user == null) {
      _subscription = null;
    } else {
      _subscription = _service.forUser(user.id);
    }
    notifyListeners();
  }

  // ============================================================
  // Ações
  // ============================================================

  /// Inicia o checkout de um plano. Em sucesso o snapshot fica `pending`
  /// com o `checkoutUrl` que a UI deve abrir num browser.
  Future<UserSubscription?> startCheckout({
    required SubscriptionPlan plan,
    required String cpfCnpj,
  }) async {
    final AppUser? user = _user;
    if (user == null) return null;
    _busy = true;
    _lastError = null;
    notifyListeners();
    try {
      final UserSubscription created = await _service.startCheckout(
        user: user,
        plan: plan,
        cpfCnpj: cpfCnpj,
      );
      _subscription = created;
      return created;
    } catch (e) {
      _lastError = _humanize(e);
      return null;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> sync() async {
    final AppUser? user = _user;
    if (user == null) return;
    _busy = true;
    notifyListeners();
    try {
      _subscription = await _service.sync(user);
    } catch (e) {
      _lastError = _humanize(e);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> cancel() async {
    final AppUser? user = _user;
    if (user == null) return false;
    _busy = true;
    _lastError = null;
    notifyListeners();
    try {
      _subscription = await _service.cancel(user);
      return true;
    } catch (e) {
      _lastError = _humanize(e);
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Atalho de DEV para liberar premium sem passar por Asaas.
  /// **Não usar em telas de produção.**
  Future<void> grantPremiumForDev(PlanType plan) async {
    final AppUser? user = _user;
    if (user == null) return;
    await _service.grantPremiumForDev(user, plan);
    _subscription = _service.forUser(user.id);
    notifyListeners();
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  String _humanize(Object e) {
    final String s = e.toString();
    return s.startsWith('Exception: ') ? s.substring(11) : s;
  }
}
