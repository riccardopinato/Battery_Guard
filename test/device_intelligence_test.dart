import 'package:battery_guard/models/charge_protection.dart';
import 'package:battery_guard/models/device_battery_profile.dart';
import 'package:battery_guard/models/monitoring_config.dart';
import 'package:battery_guard/services/feature_access.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('charge protection target is persisted and clamped to 70-100', () {
    final low = MonitoringConfig.fromMap({
      'targetLevel': 45,
      'chargeProtectionEnabled': true,
    });
    final high = MonitoringConfig.fromMap({
      'targetLevel': 140,
      'chargeProtectionEnabled': false,
    });

    expect(low.targetLevel, 70);
    expect(low.chargeProtectionEnabled, isTrue);
    expect(low.toMap()['chargeProtectionEnabled'], isTrue);
    expect(high.targetLevel, 100);
  });

  test('DeviceIdentity builds a non-sensitive lookup query', () {
    final identity = DeviceIdentity.fromMap({
      'manufacturer': 'Samsung',
      'brand': 'Samsung',
      'model': 'SM-S928B',
      'product': 'e3qxeea',
      'sku': 'SM-S928BZKDEUE',
      'sdkInt': 36,
      'androidRelease': '16',
    });

    expect(identity.displayName, 'Samsung SM-S928B');
    expect(identity.lookupQuery, contains('SM-S928B'));
    expect(identity.lookupQuery, isNot(contains('serial')));
  });

  test('OEM system setting is distinct from direct charging control', () {
    final capability = ChargeProtectionCapability.fromMap({
      'adapterId': 'samsung_battery_protection',
      'mode': 'system_setting',
      'supportsDirectControl': false,
      'systemLimitAvailable': true,
      'supportedTargets': [80, 85, 90, 95],
      'confidence': 'medium',
      'guideCode': 'samsung_battery_protection',
      'manufacturer': 'Samsung',
      'model': 'SM-S928B',
    });

    expect(capability.mode, ChargeProtectionMode.systemSetting);
    expect(capability.supportsDirectControl, isFalse);
    expect(capability.systemLimitAvailable, isTrue);
    expect(capability.supportedTargets, [80, 85, 90, 95]);
  });

  test('charge stop is only verified from explicit native readback state', () {
    final stillCharging = ChargeProtectionState.fromMap({
      'enabled': true,
      'targetLevel': 80,
      'verification': 'still_charging',
      'observedLevel': 80,
      'observedIsCharging': true,
      'observedIsPlugged': true,
      'commandSent': true,
    });
    final stopped = ChargeProtectionState.fromMap({
      'enabled': true,
      'targetLevel': 80,
      'verification': 'verified_stopped',
      'observedLevel': 80,
      'observedIsCharging': false,
      'observedIsPlugged': true,
      'commandSent': false,
    });

    expect(stillCharging.isVerifiedStopped, isFalse);
    expect(stopped.isVerifiedStopped, isTrue);
  });

  test('Device Intelligence and Charge Protection are Pro features', () {
    expect(
      FeatureCatalog.tierFor(BatteryGuardFeature.deviceBatteryProfileLive),
      FeatureTier.premium,
    );
    expect(
      FeatureCatalog.tierFor(BatteryGuardFeature.chargeProtection),
      FeatureTier.premium,
    );
  });
}
