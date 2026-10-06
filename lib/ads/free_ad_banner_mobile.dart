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
  AdSize? _slotSize;
  int? _requestedWidth;
  bool _loaded = false;
  bool _preparing = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    AdService.consentRevision.addListener(_handleConsentChanged);
  }

  void _handleConsentChanged() {
    final width = _requestedWidth;
    _generation++;
    _disposeBanner();
    _requestedWidth = null;

    if (mounted) {
      setState(() => _slotSize = null);
    }

    if (width != null && width > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _prepareForWidth(width);
        }
      });
    }
  }

  void _disposeBanner() {
    _banner?.dispose();
    _banner = null;
    _loaded = false;
  }

  Future<void> _prepareForWidth(int width) async {
    if (width <= 0) return;
    if (_preparing && _requestedWidth == width) return;
    if (_requestedWidth == width && (_loaded || _banner != null)) return;

    _requestedWidth = width;
    final generation = ++_generation;
    _preparing = true;

    _disposeBanner();

    try {
      await AdService.initialize();
      if (!mounted || generation != _generation) return;

      if (!AdService.ready) {
        setState(() => _slotSize = null);
        return;
      }

      final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
      if (!mounted || generation != _generation) return;

      if (size == null) {
        setState(() => _slotSize = null);
        return;
      }

      setState(() => _slotSize = size);

      final banner = BannerAd(
        size: size,
        adUnitId: AdService.bannerUnitId,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (!mounted || generation != _generation) {
              ad.dispose();
              return;
            }
            setState(() {
              _banner = ad as BannerAd;
              _loaded = true;
            });
            debugPrint(
              'AdMob banner loaded: placement=main_top '
              'size=${size.width}x${size.height} '
              'live=${AdService.usingLiveAds}',
            );
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            if (!mounted || generation != _generation) return;
            setState(() {
              _banner = null;
              _slotSize = null;
              _loaded = false;
            });
            debugPrint(
              'AdMob banner failed: placement=main_top error=$error',
            );
          },
          onAdImpression: (ad) {
            debugPrint('AdMob impression: placement=main_top');
          },
          onAdClicked: (ad) {
            debugPrint('AdMob click: placement=main_top');
          },
        ),
      );

      _banner = banner;
      await banner.load();
    } finally {
      if (generation == _generation) {
        _preparing = false;
      }
    }
  }

  @override
  void dispose() {
    AdService.consentRevision.removeListener(_handleConsentChanged);
    _generation++;
    _disposeBanner();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.floor();

          if (width > 0 && width != _requestedWidth) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _prepareForWidth(width);
              }
            });
          }

          final size = _slotSize;
          if (size == null) {
            return const SizedBox.shrink();
          }

          final scheme = Theme.of(context).colorScheme;
          final banner = _banner;

          return DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: scheme.outlineVariant,
                  width: 0.5,
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: size.height.toDouble(),
              child: _loaded && banner != null
                  ? Center(
                      child: SizedBox(
                        width: size.width.toDouble(),
                        height: size.height.toDouble(),
                        child: AdWidget(ad: banner),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          );
        },
      ),
    );
  }
}
