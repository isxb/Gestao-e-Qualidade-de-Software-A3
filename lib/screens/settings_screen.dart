import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/subscription_plan.dart';
import '../providers/subscription_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/platform_check.dart';
import '../widgets/app_header.dart';
import '../widgets/section_card.dart';
import 'subscription/manage_subscription_screen.dart';
import 'subscription/plans_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SubscriptionProvider sub = context.watch<SubscriptionProvider>();
    final SubscriptionPlan currentPlan =
        PlanCatalog.byType(sub.subscription?.planType ?? PlanType.free);

    return Scaffold(
      appBar: AppHeader(
        showHomeButton: true,
        onHomeTap: () =>
            Navigator.of(context).popUntil((Route<dynamic> r) => r.isFirst),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: AppTheme.contentMaxWidth(context),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.horizontalPadding(context),
              vertical: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      tooltip: 'Voltar',
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Configurações',
                      style: theme.textTheme.displayMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Bloco de assinatura — em destaque, é o que o usuário
                // mais procura aqui depois do pivot online.
                SectionCard(
                  title: 'Assinatura',
                  subtitle: 'Plano atual e gerenciamento',
                  icon: Icons.workspace_premium_rounded,
                  children: <Widget>[
                    _PlanRow(
                      plan: currentPlan,
                      isPremium: sub.isPremium,
                    ),
                    const SizedBox(height: 14),
                    if (sub.isPremium)
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                const ManageSubscriptionScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.settings_rounded),
                        label: const Text('Gerenciar minha assinatura'),
                      )
                    else
                      FilledButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const PlansScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.workspace_premium_rounded),
                        label: const Text('Ver planos premium'),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Bloco "sobre" — agora descreve a arquitetura online sem
                // prometer "100% offline".
                SectionCard(
                  title: 'EvoluaPRO v2.0.0',
                  subtitle: 'Sobre o aplicativo',
                  icon: Icons.info_outline_rounded,
                  children: <Widget>[
                    Text(
                      'Aplicativo multiplataforma (Android, iOS e Windows) '
                      'para gerar evoluções de enfermagem estruturadas '
                      'automaticamente a partir de dados clínicos preenchidos '
                      'no formulário.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary
                            .withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.shield_rounded,
                              color: theme.colorScheme.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'As evoluções clínicas que você gera ficam '
                              'salvas neste dispositivo. Apenas e-mail e '
                              'dados de cobrança trafegam pela rede para '
                              'autenticação e processamento da assinatura.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Plataforma atual: ${PlatformCheck.name}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.plan, required this.isPremium});
  final SubscriptionPlan plan;
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accent = isPremium ? AppColors.teal : AppColors.amber;
    return Row(
      children: <Widget>[
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          alignment: Alignment.center,
          child: Icon(
            isPremium
                ? Icons.workspace_premium_rounded
                : Icons.local_offer_rounded,
            color: accent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(plan.title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(
                isPremium
                    ? 'Acesso premium liberado.'
                    : 'Plano gratuito — com anúncios em mobile.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
