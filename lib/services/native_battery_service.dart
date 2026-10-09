import 'dart:async';

import 'package:flutter/services.dart';

import '../models/battery_snapshot.dart';
import '../models/battery_health_report.dart';
import '../models/battery_intelligence.dart';
import '../models/charge_protection.dart';
import '../models/device_battery_profile.dart';
import '../models/charge_test.dart';
import '../models/charging_session.dart';
import '../models/charging_setup_profile.dart';
import '../models/history_entry.dart';
import '../models/monitoring_config.dart';
import '../models/reliability_status.dart';

class NativeBatteryService {
  NativeBatteryService._();
  static final NativeBatteryService instance = NativeBatteryService._();

  static const MethodChannel _control =
      MethodChannel('com.riccardopinato.batteryguard/control');
  static const EventChannel _events =
      EventChannel('com.riccardopinato.batteryguard/events');

  Stream<BatterySnapshot>? _cachedStream;

  Stream<BatterySnapshot> get snapshots {
    return _cachedStream ??= _events
        .receiveBroadcastStream()
        .where((event) => event is Map)
        .map((event) => BatterySnapshot.fromMap(event as Map<dynamic, dynamic>))
        .asBroadcastStream();
  }

  Future<DeviceIdentity> getDeviceIdentity() async {
    final raw =
        await _control.invokeMethod<Map<dynamic, dynamic>>('getDeviceIdentity');
    return DeviceIdentity.fromMap(raw ?? const {});
  }

  Future<ChargeProtectionCapability> getChargeProtectionCapability() async {
    final raw = await _control.invokeMethod<Map<dynamic, dynamic>>(
      'getChargeProtectionCapability',
    );
    return ChargeProtectionCapability.fromMap(raw ?? const {});
  }

  Future<ChargeProtectionState> getChargeProtectionState() async {
    final raw = await _control.invokeMethod<Map<dynamic, dynamic>>(
      'getChargeProtectionState',
    );
    return ChargeProtectionState.fromMap(raw ?? const {});
  }

  Future<ChargeProtectionState> verifyChargeProtection() async {
    final raw = await _control.invokeMethod<Map<dynamic, dynamic>>(
      'verifyChargeProtection',
    );
    return ChargeProtectionState.fromMap(raw ?? const {});
  }

  Future<bool> openChargeProtectionSettings() async =>
      await _control.invokeMethod<bool>('openChargeProtectionSettings') ??
      false;

  Future<BatterySnapshot> getSnapshot() async {
    final raw =
        await _control.invokeMethod<Map<dynamic, dynamic>>('getSnapshot');
    return BatterySnapshot.fromMap(raw ?? const {});
  }

  Future<MonitoringConfig> getConfig() async {
    final raw =
        await _control.invokeMethod<Map<dynamic, dynamic>>('getConfig');
    return MonitoringConfig.fromMap(raw ?? const {});
  }

  Future<void> setConfig(MonitoringConfig config) =>
      _control.invokeMethod<void>('setConfig', config.toMap());

  Future<List<HistoryEntry>> getHistory() async {
    final raw =
        await _control.invokeMethod<List<dynamic>>('getHistory') ?? const [];
    return raw
        .whereType<Map<dynamic, dynamic>>()
        .map(HistoryEntry.fromMap)
        .toList(growable: false);
  }

  Future<List<ChargingSession>> getChargingSessions() async {
    final raw =
        await _control.invokeMethod<List<dynamic>>('getChargingSessions') ??
            const [];
    return raw
        .whereType<Map<dynamic, dynamic>>()
        .map(ChargingSession.fromMap)
        .toList(growable: false);
  }

  Future<ChargingSession?> getCurrentChargingSession() async {
    final raw = await _control
        .invokeMethod<Map<dynamic, dynamic>>('getCurrentChargingSession');
    if (raw == null || raw.isEmpty) return null;
    return ChargingSession.fromMap(raw);
  }

  Future<void> clearHistory() => _control.invokeMethod<void>('clearHistory');

  Future<List<ChargeTest>> getChargeTests() async {
    final raw =
        await _control.invokeMethod<List<dynamic>>('getChargeTests') ?? const [];
    return raw
        .whereType<Map<dynamic, dynamic>>()
        .map(ChargeTest.fromMap)
        .toList(growable: false);
  }

  Future<void> saveChargeTest(ChargeTest test) =>
      _control.invokeMethod<void>('saveChargeTest', test.toMap());

  Future<void> clearChargeTests() =>
      _control.invokeMethod<void>('clearChargeTests');

  Future<List<ChargingSetupProfile>> getChargingSetups() async {
    final raw =
        await _control.invokeMethod<List<dynamic>>('getChargingSetups') ??
            const [];
    return raw
        .whereType<Map<dynamic, dynamic>>()
        .map(ChargingSetupProfile.fromMap)
        .toList(growable: false);
  }

  Future<void> saveChargingSetup(ChargingSetupProfile profile) =>
      _control.invokeMethod<void>('saveChargingSetup', profile.toMap());

  Future<void> deleteChargingSetup(String id) =>
      _control.invokeMethod<void>('deleteChargingSetup', id);

  Future<BatteryHealthReport> getBatteryHealthReport() async {
    final raw = await _control
        .invokeMethod<Map<dynamic, dynamic>>('getBatteryHealthReport');
    return BatteryHealthReport.fromMap(raw ?? const {});
  }

  Future<BatteryHealthReport> setNominalCapacityMah(int value) async {
    final raw = await _control.invokeMethod<Map<dynamic, dynamic>>(
      'setNominalCapacityMah',
      value,
    );
    return BatteryHealthReport.fromMap(raw ?? const {});
  }

  Future<IdleDrainReport> getIdleDrainReport() async {
    final raw =
        await _control.invokeMethod<Map<dynamic, dynamic>>('getIdleDrainReport');
    return IdleDrainReport.fromMap(raw ?? const {});
  }

  Future<bool> requestNotificationPermission() async =>
      await _control.invokeMethod<bool>('requestNotificationPermission') ??
      false;

  Future<bool> hasNotificationPermission() async =>
      await _control.invokeMethod<bool>('hasNotificationPermission') ?? false;

  Future<ReliabilityStatus> getReliabilityStatus() async {
    final raw = await _control
        .invokeMethod<Map<dynamic, dynamic>>('getReliabilityStatus');
    return ReliabilityStatus.fromMap(raw ?? const {});
  }

  Future<bool> isOnboardingComplete() async =>
      await _control.invokeMethod<bool>('isOnboardingComplete') ?? false;

  Future<String?> getLocaleOverride() =>
      _control.invokeMethod<String>('getLocaleOverride');

  Future<void> setLocaleOverride(String? languageCode) =>
      _control.invokeMethod<void>('setLocaleOverride', languageCode);

  Future<bool> getProEntitlement() async =>
      await _control.invokeMethod<bool>('getProEntitlement') ?? false;

  Future<void> setProEntitlement(bool value) =>
      _control.invokeMethod<void>('setProEntitlement', value);

  Future<void> setOnboardingComplete(bool value) =>
      _control.invokeMethod<void>('setOnboardingComplete', value);

  Future<void> repairMonitoring() =>
      _control.invokeMethod<void>('repairMonitoring');

  Future<void> openBatterySettings() =>
      _control.invokeMethod<void>('openBatterySettings');

  Future<void> openNotificationSettings() =>
      _control.invokeMethod<void>('openNotificationSettings');

  Future<bool> testAlert() async =>
      await _control.invokeMethod<bool>('testAlert') ?? false;

  Future<bool> testHighAlert() async =>
      await _control.invokeMethod<bool>('testHighAlert') ?? false;

  Future<bool> testLowAlert() async =>
      await _control.invokeMethod<bool>('testLowAlert') ?? false;
}
