import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_header.dart';

/// Tela de "acesso restrito" exibida quando um usuário NÃO administrador
/// tenta abrir qualquer tela do painel administrativo.
///
/// Funciona como defesa em profundidade: mesmo que algum ponto de
/// navegação deixe de esconder o botão de admin, a própria tela protegida
/// verifica a permissão e bloqueia o acesso a dados/ações sensíveis.
///
/// Uso (no início do `build` de cada tela admin):
/// ```dart
/// final AuthProvider auth = context.watch<AuthProvider>();
/// if (!auth.isAdmin) return const AdminAccessDenied();
/// ```
class AdminAccessDenied extends StatelessWidget {
  const AdminAccessDenied({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: const AppHeader(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.lock_outline_rounded,
                size: 64,
                color: AppColors.danger,
              ),
              const SizedBox(height: 16),
              Text(
                'Acesso restrito',
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Esta área é exclusiva para administradores. '
                'Sua conta não possui permissão para acessá-la.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () =>
                    Navigator.of(context).popUntil((Route<dynamic> r) => r.isFirst),
                icon: const Icon(Icons.home_rounded),
                label: const Text('Voltar ao início'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
