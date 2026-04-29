import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_service.dart';
import '../utils/platform_check.dart';

/// Banner de anúncio adaptativo. Só renderiza algo em Android/iOS;
/// em qualquer outra plataforma vira `SizedBox.shrink()` para que a
/// mesma árvore de widgets funcione no Windows/web sem condicionais
/// no chamador.
class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _ad;
  bool _loaded = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    if (!PlatformCheck.supportsAds) return;
    final String unit = AdService.instance.bannerAdUnitId;
    if (unit.isEmpty) return;

    _ad = BannerAd(
      adUnitId: unit,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!mounted) return;
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _ad = null;
            _failed = true;
          });
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!PlatformCheck.supportsAds || _failed || !_loaded || _ad == null) {
      return const SizedBox.shrink();
    }
    return Center(
      child: SizedBox(
        width: _ad!.size.width.toDouble(),
        height: _ad!.size.height.toDouble(),
        child: AdWidget(ad: _ad!),
      ),
    );
  }
}
