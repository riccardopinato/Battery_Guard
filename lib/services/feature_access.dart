enum BatteryGuardFeature {
  dataProvenance,
  capabilityMap,
  sessionReasons,
  oemChargeLimitDetection,
  chargingCurve,
  chargeDoctorBasic,
  multipleChargingSetups,
  detailedChargeScores,
  chargerRanking,
  batteryStressSummary,
  batteryStressDetails,
  healthSummary,
  healthLabAdvanced,
  standardEta,
  smartEta,
  idleDrain,
  deviceBatteryProfileLive,
  chargeProtection,
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
      BatteryGuardFeature.chargeDoctorBasic => FeatureTier.free,
      BatteryGuardFeature.multipleChargingSetups => FeatureTier.premium,
      BatteryGuardFeature.detailedChargeScores => FeatureTier.premium,
      BatteryGuardFeature.chargerRanking => FeatureTier.premium,
      BatteryGuardFeature.batteryStressSummary => FeatureTier.free,
      BatteryGuardFeature.batteryStressDetails => FeatureTier.premium,
      BatteryGuardFeature.healthSummary => FeatureTier.free,
      BatteryGuardFeature.healthLabAdvanced => FeatureTier.premium,
      BatteryGuardFeature.standardEta => FeatureTier.free,
      BatteryGuardFeature.smartEta => FeatureTier.premium,
      BatteryGuardFeature.idleDrain => FeatureTier.premium,
      BatteryGuardFeature.deviceBatteryProfileLive => FeatureTier.premium,
      BatteryGuardFeature.chargeProtection => FeatureTier.premium,
    };
  }

  static bool isEnabled(
    BatteryGuardFeature feature, {
    required bool isPro,
  }) {
    return tierFor(feature) == FeatureTier.free || isPro;
  }
}
