import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static bool _initialized = false;
  static bool _ready = false;

  static bool get ready => _ready;

  static String get bannerUnitId => const String.fromEnvironment(
        'ADMOB_BANNER_ID',
        defaultValue: 'ca-app-pub-3940256099942544/6300978111',
      );

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final completer = Completer<void>();
    void finish() {
      if (!completer.isCompleted) completer.complete();
    }

    Future<void> startAdsIfAllowed() async {
      try {
        final canRequest =
            await ConsentInformation.instance.canRequestAds();
        if (canRequest) {
          await MobileAds.instance.initialize();
          _ready = true;
        }
      } finally {
        finish();
      }
    }

    try {
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () {
          ConsentForm.loadAndShowConsentFormIfRequired(
            (formError) async {
              await startAdsIfAllowed();
            },
          );
        },
        (formError) async {
          await startAdsIfAllowed();
        },
      );
      await completer.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () {},
      );
    } catch (_) {
      _ready = false;
      finish();
    }
  }
}
