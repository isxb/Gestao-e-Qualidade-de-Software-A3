import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../utils/platform_check.dart';

/// Inicialização e configuração do AdMob.
///
/// **IDs de teste do Google são usados por padrão** — você não corre
/// risco de ser banido em desenvolvimento. Antes do release, sobrescreva
/// via `.env` (`ADMOB_BANNER_ID_ANDROID`, `ADMOB_BANNER_ID_IOS`,
/// `ADMOB_INTERSTITIAL_ID_ANDROID`, `ADMOB_INTERSTITIAL_ID_IOS`) e
/// registre os ad units no console do AdMob.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  // ============================================================
  // IDs de teste oficiais do Google (sempre seguros para usar em dev)
  // Documentação: https://developers.google.com/admob/android/test-ads
  // ============================================================
  static const String _testBannerAndroid =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testBannerIOS =
      'ca-app-pub-3940256099942544/2934735716';
  static const String _testInterstitialAndroid =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testInterstitialIOS =
      'ca-app-pub-3940256099942544/4411468910';

  bool _initialized = false;

  /// Chamado uma vez no `main.dart`. Em plataformas que não suportam
  /// ads (desktop/web) é um no-op rápido.
  Future<void> initialize() async {
    if (_initialized) return;
    if (!PlatformCheck.supportsAds) {
      _initialized = true;
      return;
    }
    try {
      await MobileAds.instance.initialize();
    } catch (e) {
      // Falha de inicialização não pode quebrar o app — só perdemos os
      // anúncios. Em release, vale registrar no Crashlytics aqui.
      debugPrint('AdMob init falhou: $e');
    }
    _initialized = true;
  }

  String _envOrEmpty(String key) {
    try {
      return (dotenv.env[key] ?? '').trim();
    } catch (_) {
      return '';
    }
  }

  String get bannerAdUnitId {
    if (!PlatformCheck.supportsAds) return '';
    if (PlatformCheck.isAndroid) {
      final String custom = _envOrEmpty('ADMOB_BANNER_ID_ANDROID');
      return custom.isNotEmpty ? custom : _testBannerAndroid;
    }
    if (PlatformCheck.isIOS) {
      final String custom = _envOrEmpty('ADMOB_BANNER_ID_IOS');
      return custom.isNotEmpty ? custom : _testBannerIOS;
    }
    return '';
  }

  String get interstitialAdUnitId {
    if (!PlatformCheck.supportsAds) return '';
    if (PlatformCheck.isAndroid) {
      final String custom = _envOrEmpty('ADMOB_INTERSTITIAL_ID_ANDROID');
      return custom.isNotEmpty ? custom : _testInterstitialAndroid;
    }
    if (PlatformCheck.isIOS) {
      final String custom = _envOrEmpty('ADMOB_INTERSTITIAL_ID_IOS');
      return custom.isNotEmpty ? custom : _testInterstitialIOS;
    }
    return '';
  }
}
