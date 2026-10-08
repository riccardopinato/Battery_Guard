enum BatteryGuardFeature {
  dataProvenance,
  capabilityMap,
  sessionReasons,
  oemChargeLimitDetection,
  chargingCurve,
}

enum FeatureTier {
  free,
  premium,
}

class FeatureCatalog {
  const FeatureCatalog._();

  static FeatureTier tierFor(BatteryGuardFeature feature) {
    return switch (feature) {
      BatteryGuardFeature.dataProvenance => FeatureTier.free,
      BatteryGuardFeature.capabilityMap => FeatureTier.free,
      BatteryGuardFeature.sessionReasons => FeatureTier.free,
      BatteryGuardFeature.oemChargeLimitDetection => FeatureTier.free,
      BatteryGuardFeature.chargingCurve => FeatureTier.premium,
    };
  }

  static bool isEnabled(
    BatteryGuardFeature feature, {
    required bool isPro,
  }) {
    return tierFor(feature) == FeatureTier.free || isPro;
  }
}
