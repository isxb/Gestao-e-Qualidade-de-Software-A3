/// Catálogo de planos do EvoluaPRO.
///
/// Os preços e IDs de plano no Asaas devem ser ajustados conforme a
/// conta real do operador (ver `.env.example`). Os valores aqui são
/// apenas placeholders sensatos para desenvolvimento.
enum PlanType { free, monthly, yearly }

extension PlanTypeX on PlanType {
  String get asString => name;

  static PlanType fromString(String? raw) {
    switch (raw) {
      case 'monthly':
        return PlanType.monthly;
      case 'yearly':
        return PlanType.yearly;
      case 'free':
      default:
        return PlanType.free;
    }
  }
}

/// Descreve um plano vendável (ou o plano gratuito padrão). Os planos
/// pagos espelham assinaturas configuradas no painel do Asaas — o
/// [asaasPlanId] é o `id` retornado pela API ao criar uma subscription.
class SubscriptionPlan {
  const SubscriptionPlan({
    required this.type,
    required this.title,
    required this.description,
    required this.priceCents,
    required this.cycle,
    required this.features,
    this.asaasBillingType = 'UNDEFINED',
    this.savingsLabel,
    this.highlighted = false,
  });

  /// Tipo do plano.
  final PlanType type;

  /// Nome curto do plano (mostrado nos cards).
  final String title;

  /// Descrição comercial em uma linha.
  final String description;

  /// Preço em centavos. Use 0 para o plano gratuito.
  final int priceCents;

  /// Texto do ciclo de cobrança (ex.: "/mês", "/ano").
  final String cycle;

  /// Lista de benefícios para destacar nos cards.
  final List<String> features;

  /// Forma de cobrança aceita pelo Asaas: `BOLETO`, `CREDIT_CARD`, `PIX`,
  /// `UNDEFINED` (deixa o cliente escolher na página do Asaas).
  final String asaasBillingType;

  /// Selo opcional ("Mais popular", "Economize 17%", etc.).
  final String? savingsLabel;

  /// Se este plano deve ganhar destaque visual na tela de planos.
  final bool highlighted;

  /// Preço formatado em BRL para exibição rápida na UI.
  String get priceLabel {
    if (priceCents == 0) return 'Grátis';
    final double reais = priceCents / 100;
    return 'R\$ ${reais.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  /// Equivalente mensal aproximado (útil para comparar plano anual com mensal).
  String get monthlyEquivalentLabel {
    if (type != PlanType.yearly || priceCents == 0) return priceLabel;
    final double monthly = (priceCents / 12) / 100;
    return 'R\$ ${monthly.toStringAsFixed(2).replaceAll('.', ',')}/mês';
  }
}

/// Catálogo público — referenciado pelas telas de paywall, planos e
/// gerenciamento. Ajuste preço/ID conforme a sua conta Asaas.
class PlanCatalog {
  PlanCatalog._();

  static const SubscriptionPlan free = SubscriptionPlan(
    type: PlanType.free,
    title: 'Grátis',
    description: 'Para experimentar o EvoluaPRO em mobile.',
    priceCents: 0,
    cycle: '',
    features: <String>[
      'Geração ilimitada de evoluções',
      'Histórico salvo no dispositivo',
      'Inclui anúncios discretos',
      'Disponível apenas em iOS e Android',
    ],
  );

  static const SubscriptionPlan monthly = SubscriptionPlan(
    type: PlanType.monthly,
    title: 'Mensal',
    description: 'Sem anúncios e disponível em todas as plataformas.',
    priceCents: 2990,
    cycle: '/mês',
    features: <String>[
      'Sem anúncios',
      'Acesso completo no Windows',
      'Suporte prioritário',
      'Cancele quando quiser',
    ],
    asaasBillingType: 'UNDEFINED',
  );

  static const SubscriptionPlan yearly = SubscriptionPlan(
    type: PlanType.yearly,
    title: 'Anual',
    description: 'Pague 12 meses de uma vez e economize.',
    priceCents: 29990,
    cycle: '/ano',
    features: <String>[
      'Tudo do plano Mensal',
      'Equivalente a ~R\$ 24,99/mês',
      'Renovação anual automática',
    ],
    asaasBillingType: 'UNDEFINED',
    savingsLabel: 'Economize 17%',
    highlighted: true,
  );

  /// Apenas os planos pagos, na ordem em que devem aparecer.
  static const List<SubscriptionPlan> paid = <SubscriptionPlan>[
    monthly,
    yearly,
  ];

  static SubscriptionPlan byType(PlanType type) {
    switch (type) {
      case PlanType.monthly:
        return monthly;
      case PlanType.yearly:
        return yearly;
      case PlanType.free:
        return free;
    }
  }
}
