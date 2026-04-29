import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/subscription.dart';
import '../../models/subscription_plan.dart';
import '../../providers/subscription_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';
import 'plans_screen.dart';

/// Tela "Minha assinatura". Mostra o estado atual, link para reabrir o
/// checkout pendente e botão de cancelar / mudar de plano.
class ManageSubscriptionScreen extends StatefulWidget {
  const ManageSubscriptionScreen({super.key});

  @override
  State<ManageSubscriptionScreen> createState() =>
      _ManageSubscriptionScreenState();
}

class _ManageSubscriptionScreenState extends State<ManageSubscriptionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionProvider>().sync();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SubscriptionProvider sub = context.watch<SubscriptionProvider>();
    final UserSubscription? s = sub.subscription;

    return Scaffold(
      appBar: const AppHeader(showHomeButton: true),
      body: Center(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: AppTheme.contentMaxWidth(context)),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.horizontalPadding(context),
              vertical: 28,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 8),
                    Text('Minha assinatura',
                        style: theme.textTheme.displayMedium),
                  ],
                ),
                const SizedBox(height: 16),
                _StatusCard(subscription: s),
                const SizedBox(height: 22),
                if (s == null || !s.isPaidPlan)
                  _UpgradeCard()
                else
                  _ActionsCard(subscription: s),
                const SizedBox(height: 24),
                if (sub.lastError != null)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.dangerLight,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusSm),
                      border: Border.all(
                        color: AppColors.danger.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.error_outline_rounded,
                            color: AppColors.dangerDark),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            sub.lastError!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.dangerDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.subscription});
  final UserSubscription? subscription;

  Color _statusColor() {
    final SubscriptionStatus s =
        subscription?.status ?? SubscriptionStatus.none;
    switch (s) {
      case SubscriptionStatus.active:
        return AppColors.success;
      case SubscriptionStatus.pending:
      case SubscriptionStatus.pastDue:
        return AppColors.warning;
      case SubscriptionStatus.cancelled:
      case SubscriptionStatus.expired:
        return AppColors.danger;
      case SubscriptionStatus.none:
      case SubscriptionStatus.unknown:
        return AppColors.lightTextMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final UserSubscription? s = subscription;
    final SubscriptionPlan plan = PlanCatalog.byType(
      s?.planType ?? PlanType.free,
    );
    final Color statusColor = _statusColor();
    final SubscriptionStatus status = s?.status ?? SubscriptionStatus.none;
    final DateFormat fmt = DateFormat('dd/MM/yyyy');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(plan.title, style: theme.textTheme.titleLarge),
                    Text(
                      plan.type == PlanType.free
                          ? 'Plano gratuito'
                          : '${plan.priceLabel}${plan.cycle}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (s != null) ...<Widget>[
            if (s.startedAt != null)
              _InfoRow(
                label: 'Início',
                value: fmt.format(s.startedAt!),
              ),
            if (s.expiresAt != null)
              _InfoRow(
                label: status == SubscriptionStatus.active
                    ? 'Próximo ciclo'
                    : 'Validade',
                value: fmt.format(s.expiresAt!),
              ),
            if (s.lastSyncAt != null)
              _InfoRow(
                label: 'Última sincronização',
                value: DateFormat('dd/MM HH:mm').format(s.lastSyncAt!),
              ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: <Widget>[
          Text(label, style: theme.textTheme.bodySmall),
          const Spacer(),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _UpgradeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Atualizar para Premium',
              style: theme.textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Sem anúncios em mobile e acesso liberado no Windows.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const PlansScreen(),
              ),
            ),
            icon: const Icon(Icons.workspace_premium_rounded),
            label: const Text('Ver planos'),
          ),
        ],
      ),
    );
  }
}

class _ActionsCard extends StatelessWidget {
  const _ActionsCard({required this.subscription});
  final UserSubscription subscription;

  Future<void> _confirmAndCancel(BuildContext context) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Cancelar assinatura?'),
        content: const Text(
          'Você manterá o acesso premium até o fim do período já pago. '
          'Depois disso, voltará para o plano gratuito (com anúncios em '
          'mobile e sem acesso no Windows).',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Manter'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            child: const Text('Cancelar assinatura'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!context.mounted) return;
    final bool done =
        await context.read<SubscriptionProvider>().cancel();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          done
              ? 'Assinatura cancelada.'
              : 'Não foi possível cancelar agora. Tente novamente.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SubscriptionProvider sub = context.watch<SubscriptionProvider>();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (subscription.checkoutUrl != null &&
              !subscription.isActive) ...<Widget>[
            Text(
              'Pagamento pendente',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Reabra a página de pagamento para concluir.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () async {
                final Uri uri = Uri.parse(subscription.checkoutUrl!);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri,
                      mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.payment_rounded),
              label: const Text('Abrir página de pagamento'),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
          ],
          OutlinedButton.icon(
            onPressed: sub.isBusy ? null : sub.sync,
            icon: const Icon(Icons.sync_rounded),
            label: const Text('Atualizar status'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const PlansScreen(),
              ),
            ),
            icon: const Icon(Icons.swap_horiz_rounded),
            label: const Text('Mudar de plano'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: sub.isBusy
                ? null
                : () => _confirmAndCancel(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: BorderSide(
                color: AppColors.danger.withValues(alpha: 0.5),
              ),
            ),
            icon: const Icon(Icons.cancel_rounded),
            label: const Text('Cancelar assinatura'),
          ),
        ],
      ),
    );
  }
}
