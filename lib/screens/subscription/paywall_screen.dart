import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_logo.dart';
import 'plans_screen.dart';

/// Gate obrigatório de assinatura — exibido no Windows quando o usuário
/// está autenticado mas ainda não tem premium ativo. Em mobile o app
/// nunca chama esta tela: o paywall ali é apenas opcional (a partir de
/// um botão "remover anúncios").
class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SubscriptionProvider sub = context.watch<SubscriptionProvider>();
    final bool isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Color(0xFF0B1422),
                    Color(0xFF152133),
                    Color(0xFF1D2C42),
                  ],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Color(0xFFF6F9FC),
                    Color(0xFFEDF3F8),
                    Color(0xFFD4F0EC),
                  ],
                ),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Row(
                  children: <Widget>[
                    AppLogoLockup(
                      logoSize: 36,
                      compact: true,
                      color: theme.colorScheme.onSurface,
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () =>
                          context.read<AuthProvider>().logout(),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Sair'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: const PlansScreen(requireSubscription: true),
                  ),
                ),
              ),
              if (sub.subscription?.checkoutUrl != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.amberLight,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      border: Border.all(
                        color: AppColors.amber.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.hourglass_top_rounded,
                            color: AppColors.warningDark),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Sua assinatura está aguardando confirmação do '
                            'primeiro pagamento. Após confirmar, recarregue '
                            'esta tela para liberar o acesso.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        TextButton(
                          onPressed: sub.isBusy ? null : sub.sync,
                          child: const Text('Atualizar status'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
