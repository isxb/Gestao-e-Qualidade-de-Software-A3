import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Centraliza decisões dependentes de plataforma. Toda regra de negócio
/// que muda entre Android/iOS/Windows/Web fica aqui — assim os widgets
/// não precisam importar `dart:io` espalhado pelo código.
class PlatformCheck {
  PlatformCheck._();

  static bool get isWeb => kIsWeb;

  static bool get isAndroid => !kIsWeb && Platform.isAndroid;
  static bool get isIOS => !kIsWeb && Platform.isIOS;
  static bool get isWindows => !kIsWeb && Platform.isWindows;
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;
  static bool get isLinux => !kIsWeb && Platform.isLinux;

  static bool get isMobile => isAndroid || isIOS;
  static bool get isDesktop => isWindows || isMacOS || isLinux;

  // ============================================================
  // Regras de negócio do EvoluaPRO
  // ============================================================

  /// Plataformas onde o uso é gratuito mas com anúncios:
  /// **apenas Android e iOS** — nem desktop, nem web.
  static bool get supportsFreeWithAds => isMobile;

  /// Plataformas onde a assinatura é obrigatória para usar o app:
  /// **Windows** (e demais desktops por extensão).
  ///
  /// O Windows é o caso citado explicitamente; por consistência
  /// estendemos para macOS/Linux. Ajustar aqui caso a regra mude.
  static bool get requiresPremium => isDesktop;

  /// Plataformas onde o Google Sign-In nativo (`google_sign_in`) tem
  /// suporte oficial. Em desktops o plugin não roda — usamos um fallback
  /// (mensagem de "indisponível" ou OAuth via browser externo).
  static bool get supportsGoogleSignIn => isMobile || isWeb;

  /// Plataformas onde o `google_mobile_ads` consegue carregar anúncios.
  static bool get supportsAds => isMobile;

  /// Nome legível da plataforma corrente. Útil em logs e crash reports.
  static String get name {
    if (isWeb) return 'Web';
    if (isAndroid) return 'Android';
    if (isIOS) return 'iOS';
    if (isWindows) return 'Windows';
    if (isMacOS) return 'macOS';
    if (isLinux) return 'Linux';
    return 'Desconhecida';
  }
}
