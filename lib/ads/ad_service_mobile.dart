import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static bool _ready = false;
  static bool _privacyOptionsRequired = false;
  static Future<void>? _initializing;

  static final ValueNotifier<int> consentRevision = ValueNotifier<int>(0);

  static bool get ready => _ready;
  static bool get privacyOptionsRequired => _privacyOptionsRequired;

  static String get bannerUnitId => const String.fromEnvironment(
        'ADMOB_BANNER_ID',
        defaultValue: 'ca-app-pub-3940256099942544/6300978111',
      );

  static Future<void> initialize() async {
    final running = _initializing;
    if (running != null) {
      await running;
      return;
    }

    final completer = Completer<void>();
    _initializing = completer.future;

    void finish() {
      if (!completer.isCompleted) completer.complete();
    }

    Future<void> refreshPrivacyRequirement() async {
      try {
        _privacyOptionsRequired =
            await ConsentInformation.instance
                    .getPrivacyOptionsRequirementStatus() ==
                PrivacyOptionsRequirementStatus.required;
      } catch (_) {
        _privacyOptionsRequired = false;
      }
    }

    Future<void> updateAdReadiness() async {
      try {
        final canRequest =
            await ConsentInformation.instance.canRequestAds();
        if (canRequest) {
          await MobileAds.instance.initialize();
          _ready = true;
        } else {
          _ready = false;
        }
      } catch (_) {
        _ready = false;
      }
    }

    try {
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () async {
          await refreshPrivacyRequirement();
          ConsentForm.loadAndShowConsentFormIfRequired(
            (formError) async {
              await refreshPrivacyRequirement();
              await updateAdReadiness();
              consentRevision.value++;
              finish();
            },
          );
        },
        (formError) async {
          await refreshPrivacyRequirement();
          _ready = false;
          finish();
        },
      );

      await completer.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          _ready = false;
        },
      );
    } finally {
      _initializing = null;
    }
  }

  static Future<void> showPrivacyOptions() async {
    if (!_privacyOptionsRequired) return;

    final completer = Completer<void>();
    ConsentForm.showPrivacyOptionsForm(
      (formError) async {
        try {
          _privacyOptionsRequired =
              await ConsentInformation.instance
                      .getPrivacyOptionsRequirementStatus() ==
                  PrivacyOptionsRequirementStatus.required;
          final canRequest =
              await ConsentInformation.instance.canRequestAds();
          _ready = canRequest;
          if (canRequest) {
            await MobileAds.instance.initialize();
          }
        } finally {
          consentRevision.value++;
          if (!completer.isCompleted) completer.complete();
        }
      },
    );
    await completer.future;
  }
}
