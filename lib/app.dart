import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/subscription_provider.dart';
import 'screens/auth/change_password_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/subscription/paywall_screen.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'utils/platform_check.dart';

class EvoluaProApp extends StatelessWidget {
  const EvoluaProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EvoluaPRO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const _AuthGate(),
      builder: (BuildContext context, Widget? child) {
        final MediaQueryData mq = MediaQuery.of(context);
        final double clamped = mq.textScaler.scale(1).clamp(0.9, 1.2);
        return MediaQuery(
          data: mq.copyWith(textScaler: TextScaler.linear(clamped)),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

/// Portão que decide qual tela exibir com base no estado de autenticação
/// e — apenas no Windows — no estado da assinatura.
///
/// - [AuthStatus.initializing]  → splash com logo
/// - [AuthStatus.signedOut]     → tela de login
/// - [AuthStatus.signedIn] + mustChangePassword → troca obrigatória
/// - [AuthStatus.signedIn] + Windows sem premium → paywall OBRIGATÓRIO
/// - [AuthStatus.signedIn] + mobile/macOS/Linux/web → home (anúncios
///   controlados pelo StepOutput a cada evolução gerada)
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();
    final SubscriptionProvider sub = context.watch<SubscriptionProvider>();

    switch (auth.status) {
      case AuthStatus.initializing:
        return const _SplashView();

      case AuthStatus.signedOut:
        return const LoginScreen();

      case AuthStatus.signedIn:
        if (auth.mustChangePassword) {
          return const ChangePasswordScreen(forced: true);
        }
        // Paywall obrigatório somente no Windows.
        if (PlatformCheck.requiresPremium && !sub.isPremium) {
          return const PaywallScreen();
        }
        // Em todas as demais plataformas (mobile, macOS, Linux, web)
        // o usuário acessa o app diretamente. Em mobile sem premium,
        // 2 anúncios de 30s serão exibidos antes de cada evolução gerada.
        return const HomeScreen();
    }
  }
}

class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: AppColors.brandGradient),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
    );
  }
}