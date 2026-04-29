import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/subscription.dart';
import '../../models/subscription_plan.dart';
import '../../providers/subscription_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';

/// Galeria de planos pagos. Selecionar um plano abre um modal pedindo
/// CPF/CNPJ (exigência do Asaas) e dispara o checkout.
class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key, this.requireSubscription = false});

  /// Quando `true`, a tela é apresentada como gate obrigatório (sem
  /// botão de voltar). Usado em [PaywallScreen] para o Windows.
  final bool requireSubscription;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: requireSubscription ? null : const AppHeader(showHomeButton: true),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: AppTheme.contentMaxWidth(context),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.horizontalPadding(context),
              vertical: 32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (!requireSubscription)
                  Row(
                    children: <Widget>[
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const SizedBox(width: 8),
                      Text('Escolher plano',
                          style: theme.textTheme.displayMedium),
                    ],
                  ),
                if (!requireSubscription) const SizedBox(height: 16),
                _Header(requireSubscription: requireSubscription),
                const SizedBox(height: 24),
                _PlansGrid(),
                const SizedBox(height: 24),
                Text(
                  'Os pagamentos são processados com segurança pela Asaas. '
                  'Você pode cancelar a qualquer momento — em "Minha assinatura".',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
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

class _Header extends StatelessWidget {
  const _Header({required this.requireSubscription});
  final bool requireSubscription;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.workspace_premium_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(height: 14),
          Text(
            requireSubscription
                ? 'Ative o EvoluaPRO no seu computador'
                : 'EvoluaPRO Premium',
            style: theme.textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            requireSubscription
                ? 'A versão para Windows é exclusiva para assinantes. '
                    'Escolha um plano para liberar o acesso completo.'
                : 'Sem anúncios em mobile e acesso completo no Windows.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlansGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext c, BoxConstraints cts) {
        final bool wide = cts.maxWidth >= 720;
        final List<Widget> cards = PlanCatalog.paid
            .map((SubscriptionPlan p) => _PlanCard(plan: p))
            .toList();
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (int i = 0; i < cards.length; i++) ...<Widget>[
                Expanded(child: cards[i]),
                if (i < cards.length - 1) const SizedBox(width: 16),
              ],
            ],
          );
        }
        return Column(
          children: <Widget>[
            for (int i = 0; i < cards.length; i++) ...<Widget>[
              cards[i],
              if (i < cards.length - 1) const SizedBox(height: 16),
            ],
          ],
        );
      },
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan});
  final SubscriptionPlan plan;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SubscriptionProvider sub = context.watch<SubscriptionProvider>();
    final bool selected = sub.subscription?.planType == plan.type &&
        (sub.subscription?.isActive ?? false);
    final Color border = plan.highlighted
        ? AppColors.indigo
        : theme.dividerColor;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: border, width: plan.highlighted ? 1.6 : 1),
        boxShadow: plan.highlighted
            ? AppColors.softShadow(opacity: 0.08)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(plan.title, style: theme.textTheme.headlineSmall),
              if (plan.savingsLabel != null) ...<Widget>[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    plan.savingsLabel!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.teal,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(plan.description, style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                plan.priceLabel,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontSize: 30,
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  plan.cycle,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          if (plan.type == PlanType.yearly) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              'Equivale a ${plan.monthlyEquivalentLabel}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
          const SizedBox(height: 16),
          for (final String f in plan.features) ...<Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.check_rounded,
                        size: 18, color: AppColors.teal),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(f, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: sub.isBusy || selected
                  ? null
                  : () => _startCheckout(context, plan),
              style: FilledButton.styleFrom(
                backgroundColor:
                    plan.highlighted ? AppColors.indigo : null,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                selected
                    ? 'Plano atual'
                    : sub.isBusy
                        ? 'Processando...'
                        : 'Assinar',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startCheckout(
    BuildContext context,
    SubscriptionPlan plan,
  ) async {
    final String? cpf = await _askCpfCnpj(context);
    if (cpf == null || cpf.trim().isEmpty) return;

    if (!context.mounted) return;
    final SubscriptionProvider sub = context.read<SubscriptionProvider>();
    final UserSubscription? created = await sub.startCheckout(
      plan: plan,
      cpfCnpj: cpf.trim(),
    );

    if (!context.mounted) return;

    if (created == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            sub.lastError ?? 'Não foi possível iniciar o checkout.',
          ),
        ),
      );
      return;
    }

    final String? url = created.checkoutUrl;
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Assinatura criada. Acompanhe o pagamento em "Minha assinatura".',
          ),
        ),
      );
      return;
    }

    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<String?> _askCpfCnpj(BuildContext context) async {
    final TextEditingController ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Dados para a fatura'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              'Informe seu CPF ou CNPJ — exigência do gateway de '
              'pagamento. Apenas números.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: const InputDecoration(
                labelText: 'CPF / CNPJ',
                hintText: 'somente números',
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }
}

