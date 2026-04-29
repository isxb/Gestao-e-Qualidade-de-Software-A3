import 'package:flutter/material.dart';

import 'plans_screen.dart';

/// Gate obrigatório de assinatura — exibido em desktop quando o usuário
/// está autenticado mas ainda não tem premium ativo.
///
/// Toda a UI vive em [PlansScreen] no modo `requireSubscription: true`.
/// Este wrapper existe apenas para que o roteamento em `_AuthGate` fique
/// declarativo (`return const PaywallScreen()`) e para que, no futuro,
/// possamos plugar lógica adicional (analytics de conversão, A/B test
/// de mensagens) sem mexer no `PlansScreen`.
class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlansScreen(requireSubscription: true);
  }
}
