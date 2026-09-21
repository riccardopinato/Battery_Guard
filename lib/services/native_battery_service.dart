import 'dart:async';

import 'package:flutter/services.dart';

import '../models/battery_snapshot.dart';
import '../models/charging_session.dart';
import '../models/history_entry.dart';
import '../models/monitoring_config.dart';

class NativeBatteryService {
  NativeBatteryService._();

  static final NativeBatteryService instance = NativeBatteryService._();

  static const MethodChannel _control = MethodChannel(
    'com.riccardopinato.batteryguard/control',
  );
  static const EventChannel _events = EventChannel(
    'com.riccardopinato.batteryguard/events',
  );

  Stream<BatterySnapshot>? _cachedStream;

  Stream<BatterySnapshot> get snapshots {
    return _cachedStream ??= _events
        .receiveBroadcastStream()
        .where((event) => event is Map)
        .map((event) => BatterySnapshot.fromMap(event as Map<dynamic, dynamic>))
        .asBroadcastStream();
  }

  Future<BatterySnapshot> getSnapshot() async {
    final raw = await _control.invokeMethod<Map<dynamic, dynamic>>('getSnapshot');
    return BatterySnapshot.fromMap(raw ?? const {});
  }

  Future<MonitoringConfig> getConfig() async {
    final raw = await _control.invokeMethod<Map<dynamic, dynamic>>('getConfig');
    return MonitoringConfig.fromMap(raw ?? const {});
  }

  Future<void> setConfig(MonitoringConfig config) {
    return _control.invokeMethod<void>('setConfig', config.toMap());
  }

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

  Future<bool> requestNotificationPermission() async {
    return await _control.invokeMethod<bool>('requestNotificationPermission') ??
        false;
  }

  Future<bool> hasNotificationPermission() async {
    return await _control.invokeMethod<bool>('hasNotificationPermission') ??
        false;
  }

  Future<void> openBatterySettings() {
    return _control.invokeMethod<void>('openBatterySettings');
  }

  Future<void> testAlert() {
    return _control.invokeMethod<void>('testAlert');
  }
}
