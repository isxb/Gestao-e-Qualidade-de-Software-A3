import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../utils/platform_check.dart';

/// Inicialização e gerenciamento de anúncios AdMob.
///
/// **IDs de teste do Google são usados por padrão** — você não corre
/// risco de ser banido em desenvolvimento. Antes do release, sobrescreva
/// via `.env`:
///   ADMOB_BANNER_ID_ANDROID
///   ADMOB_BANNER_ID_IOS
///   ADMOB_REWARDED_INTERSTITIAL_ID_ANDROID
///   ADMOB_REWARDED_INTERSTITIAL_ID_IOS
///
/// O fluxo de monetização em mobile free é:
///   - 2 anúncios recompensados (rewarded interstitial) de ~30s por evolução
///   - O usuário NÃO pode pular — é o formato correto do AdMob para isso
///   - Após assistir os 2, o conteúdo da evolução é liberado
///   - Premium remove completamente os anúncios
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

  // Rewarded Interstitial — não permite pular, ~30s
  static const String _testRewardedInterstitialAndroid =
      'ca-app-pub-3940256099942544/5354046379';
  static const String _testRewardedInterstitialIOS =
      'ca-app-pub-3940256099942544/6978759866';

  bool _initialized = false;

  /// Anúncio pré-carregado em memória para exibição imediata.
  /// Após cada exibição, _preloadNext() já carrega o próximo.
  RewardedInterstitialAd? _preloadedAd;
  bool _isLoadingPreload = false;

  // ============================================================
  // Inicialização
  // ============================================================

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
      // Pré-carrega o primeiro rewarded interstitial logo no boot,
      // para que esteja pronto quando o usuário gerar a primeira evolução.
      _preloadNext();
    } catch (e) {
      // Falha de inicialização não pode quebrar o app — só perdemos os
      // anúncios. Em release, vale registrar no Crashlytics aqui.
      debugPrint('AdMob init falhou: $e');
    }
    _initialized = true;
  }

  // ============================================================
  // Helpers de ambiente
  // ============================================================

  String _envOrEmpty(String key) {
    try {
      return (dotenv.env[key] ?? '').trim();
    } catch (_) {
      return '';
    }
  }

  // ============================================================
  // IDs dos ad units (com fallback para teste)
  // ============================================================

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

  String get rewardedInterstitialAdUnitId {
    if (!PlatformCheck.supportsAds) return '';
    if (PlatformCheck.isAndroid) {
      final String custom =
          _envOrEmpty('ADMOB_REWARDED_INTERSTITIAL_ID_ANDROID');
      return custom.isNotEmpty ? custom : _testRewardedInterstitialAndroid;
    }
    if (PlatformCheck.isIOS) {
      final String custom =
          _envOrEmpty('ADMOB_REWARDED_INTERSTITIAL_ID_IOS');
      return custom.isNotEmpty ? custom : _testRewardedInterstitialIOS;
    }
    return '';
  }

  // ============================================================
  // Pré-carregamento
  // ============================================================

  /// Carrega silenciosamente o próximo rewarded interstitial em background.
  /// Chamado após cada exibição para que o seguinte já esteja pronto.
  void _preloadNext() {
    if (!PlatformCheck.supportsAds) return;
    if (_isLoadingPreload || _preloadedAd != null) return;

    final String unit = rewardedInterstitialAdUnitId;
    if (unit.isEmpty) return;

    _isLoadingPreload = true;

    RewardedInterstitialAd.load(
      adUnitId: unit,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (RewardedInterstitialAd ad) {
          _preloadedAd = ad;
          _isLoadingPreload = false;
          debugPrint('AdService: rewarded interstitial pré-carregado.');
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('AdService: falha no pré-carregamento — $error');
          _isLoadingPreload = false;
        },
      ),
    );
  }

  // ============================================================
  // Exibição
  // ============================================================

  /// Exibe um anúncio intersticial recompensado de ~30s.
  ///
  /// [onComplete] é chamado quando o usuário assiste o anúncio até o fim
  /// (evento `onUserEarnedReward`). Em plataformas sem suporte a ads
  /// (macOS, Linux, Windows, web) `onComplete` é chamado imediatamente
  /// para não bloquear o fluxo.
  ///
  /// [onSkipped] é chamado se o anúncio for fechado antes da recompensa.
  /// Com rewarded interstitial o usuário tecnicamente não pode pular, mas
  /// mantemos o callback como fallback defensivo (ex.: falha na exibição).
  ///
  /// Retorna `true` se o anúncio chegou a ser exibido na tela;
  /// `false` se não havia suporte ou se houve falha de carregamento
  /// (nesses casos [onComplete] ainda é chamado para não bloquear).
  Future<bool> showRewardedInterstitial({
    required VoidCallback onComplete,
    VoidCallback? onSkipped,
  }) async {
    // Plataformas sem suporte: libera imediatamente.
    if (!PlatformCheck.supportsAds) {
      onComplete();
      return true;
    }

    // Usa o anúncio pré-carregado se disponível; caso contrário carrega agora.
    RewardedInterstitialAd? ad = _preloadedAd;
    _preloadedAd = null; // Libera a referência para pré-carregar o próximo.

    if (ad == null) {
      final String unit = rewardedInterstitialAdUnitId;
      if (unit.isEmpty) {
        // Sem ID configurado — não bloqueia.
        onComplete();
        return false;
      }
      debugPrint('AdService: anúncio não pré-carregado, carregando agora...');
      ad = await _loadNow(unit);
      if (ad == null) {
        // Falha de rede ou timeout — não bloqueia o usuário.
        debugPrint('AdService: falha ao carregar sob demanda, liberando.');
        onComplete();
        return false;
      }
    }

    bool rewarded = false;

    ad.fullScreenContentCallback = FullScreenContentCallback<RewardedInterstitialAd>(
      onAdDismissedFullScreenContent: (RewardedInterstitialAd a) {
        a.dispose();
        _preloadNext(); // Já prepara o próximo anúncio.
        if (!rewarded) {
          // Fechou antes de completar (não deveria acontecer com rewarded
          // interstitial, mas cobre o caso de falha silenciosa do SDK).
          onSkipped?.call();
        }
      },
      onAdFailedToShowFullScreenContent: (
        RewardedInterstitialAd a,
        AdError error,
      ) {
        a.dispose();
        _preloadNext();
        debugPrint('AdService: falha ao exibir anúncio — $error');
        // Falha na exibição não deve bloquear o usuário.
        onComplete();
      },
    );

    await ad.show(
      onUserEarnedReward: (AdWithoutView _, RewardItem __) {
        rewarded = true;
        onComplete();
      },
    );

    return true;
  }

  /// Carrega um rewarded interstitial sob demanda com timeout de 8 segundos.
  Future<RewardedInterstitialAd?> _loadNow(String unit) async {
    RewardedInterstitialAd? result;
    bool done = false;

    RewardedInterstitialAd.load(
      adUnitId: unit,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (RewardedInterstitialAd ad) {
          result = ad;
          done = true;
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('AdService._loadNow falhou: $error');
          done = true;
        },
      ),
    );

    // Polling com timeout de 8s para não travar indefinidamente.
    const int maxWaitMs = 8000;
    const int stepMs = 100;
    int waited = 0;
    while (!done && waited < maxWaitMs) {
      await Future<void>.delayed(const Duration(milliseconds: stepMs));
      waited += stepMs;
    }

    return result;
  }
}