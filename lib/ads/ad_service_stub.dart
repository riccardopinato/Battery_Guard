import 'package:flutter/foundation.dart';

class AdService {
  static final ValueNotifier<int> consentRevision = ValueNotifier<int>(0);

  static bool get ready => false;
  static bool get privacyOptionsRequired => false;
  static String get bannerUnitId => '';

  static Future<void> initialize() async {}
  static Future<void> showPrivacyOptions() async {}
}
