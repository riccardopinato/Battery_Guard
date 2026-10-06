import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_service.dart';

class FreeAdBanner extends StatefulWidget {
  const FreeAdBanner({super.key});

  @override
  State<FreeAdBanner> createState() => _FreeAdBannerState();
}

class _FreeAdBannerState extends State<FreeAdBanner> {
  BannerAd? _banner;
  bool _loaded = false;
  bool _preparing = false;

  @override
  void initState() {
    super.initState();
    AdService.consentRevision.addListener(_handleConsentChanged);
    _prepare();
  }

  void _handleConsentChanged() {
    _disposeBanner();
    _prepare();
  }

  void _disposeBanner() {
    _banner?.dispose();
    _banner = null;
    _loaded = false;
  }

  Future<void> _prepare() async {
    if (_preparing) return;
    _preparing = true;
    try {
      await AdService.initialize();
      if (!mounted || !AdService.ready) return;

      final banner = BannerAd(
        size: AdSize.banner,
        adUnitId: AdService.bannerUnitId,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (!mounted) {
              ad.dispose();
              return;
            }
            setState(() => _loaded = true);
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            if (mounted) {
              setState(() {
                _banner = null;
                _loaded = false;
              });
            }
          },
        ),
      );
      _banner = banner;
      await banner.load();
    } finally {
      _preparing = false;
    }
  }

  @override
  void dispose() {
    AdService.consentRevision.removeListener(_handleConsentChanged);
    _disposeBanner();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banner = _banner;
    if (!_loaded || banner == null) {
      return const SizedBox.shrink();
    }
    return SafeArea(
      top: false,
      child: SizedBox(
        width: banner.size.width.toDouble(),
        height: banner.size.height.toDouble(),
        child: AdWidget(ad: banner),
      ),
    );
  }
}
