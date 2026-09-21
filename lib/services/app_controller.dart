import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/battery_snapshot.dart';
import '../models/charging_session.dart';
import '../models/history_entry.dart';
import '../models/monitoring_config.dart';
import '../models/reliability_status.dart';
import 'native_battery_service.dart';

class AppController extends ChangeNotifier {
  AppController({NativeBatteryService? platform})
      : _platform = platform ?? NativeBatteryService.instance;

  final NativeBatteryService _platform;
  StreamSubscription<BatterySnapshot>? _subscription;

  BatterySnapshot snapshot = BatterySnapshot.empty();
  MonitoringConfig config = MonitoringConfig.defaults();
  List<HistoryEntry> history = const [];
  List<ChargingSession> chargingSessions = const [];
  ChargingSession? currentSession;
  ReliabilityStatus reliability = ReliabilityStatus.unknown;
  bool onboardingComplete = false;
  bool loading = true;
  bool notificationsGranted = false;
  String? lastError;

  Future<void> initialize() async {
    loading = true;
    notifyListeners();
    try {
      final values = await Future.wait<Object?>([
        _platform.getSnapshot(),
        _platform.getConfig(),
        _platform.getHistory(),
        _platform.getChargingSessions(),
        _platform.getCurrentChargingSession(),
        _platform.hasNotificationPermission(),
        _platform.getReliabilityStatus(),
        _platform.isOnboardingComplete(),
      ]);
      snapshot = values[0] as BatterySnapshot;
      config = values[1] as MonitoringConfig;
      history = values[2] as List<HistoryEntry>;
      chargingSessions = values[3] as List<ChargingSession>;
      currentSession = values[4] as ChargingSession?;
      notificationsGranted = values[5] as bool;
      reliability = values[6] as ReliabilityStatus;
      onboardingComplete = values[7] as bool;
      lastError = null;

      await _subscription?.cancel();
      _subscription = _platform.snapshots.listen(
        (value) {
          snapshot = value;
          notifyListeners();
          unawaited(_refreshCurrentSessionSilently());
        },
        onError: (Object error) {
          lastError = error.toString();
          notifyListeners();
        },
      );
    } catch (error) {
      lastError = error.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _refreshCurrentSessionSilently() async {
    try {
      currentSession = await _platform.getCurrentChargingSession();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> refreshSnapshot() async {
    try {
      final values = await Future.wait<Object?>([
        _platform.getSnapshot(),
        _platform.getCurrentChargingSession(),
      ]);
      snapshot = values[0] as BatterySnapshot;
      currentSession = values[1] as ChargingSession?;
      notifyListeners();
    } catch (error) {
      lastError = error.toString();
      notifyListeners();
    }
  }

  Future<void> refreshReliability() async {
    try {
      reliability = await _platform.getReliabilityStatus();
      notificationsGranted = reliability.notificationsGranted;
      notifyListeners();
    } catch (error) {
      lastError = error.toString();
      notifyListeners();
    }
  }

  Future<void> repairMonitoring() async {
    await _platform.repairMonitoring();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await refreshReliability();
  }

  Future<void> completeOnboarding() async {
    onboardingComplete = true;
    notifyListeners();
    await _platform.setOnboardingComplete(true);
    await refreshReliability();
  }

  Future<void> updateConfig(MonitoringConfig next) async {
    final previous = config;
    config = next;
    notifyListeners();
    try {
      await _platform.setConfig(next);
      lastError = null;
      await refreshReliability();
    } catch (error) {
      config = previous;
      lastError = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> setEnabled(bool value) =>
      updateConfig(config.copyWith(enabled: value));

  Future<void> setTargetLevel(int value) =>
      updateConfig(config.copyWith(targetLevel: value));

  Future<void> setTemperatureThreshold(double value) =>
      updateConfig(config.copyWith(temperatureThresholdC: value));

  Future<void> refreshHistory() async {
    try {
      final values = await Future.wait<Object>([
        _platform.getHistory(),
        _platform.getChargingSessions(),
      ]);
      history = values[0] as List<HistoryEntry>;
      chargingSessions = values[1] as List<ChargingSession>;
      notifyListeners();
    } catch (error) {
      lastError = error.toString();
      notifyListeners();
    }
  }

  Future<void> clearHistory() async {
    await _platform.clearHistory();
    history = const [];
    chargingSessions = const [];
    notifyListeners();
  }

  Future<bool> requestNotificationPermission() async {
    notificationsGranted = await _platform.requestNotificationPermission();
    await refreshReliability();
    return notificationsGranted;
  }

  Future<void> openBatterySettings() => _platform.openBatterySettings();

  Future<void> openNotificationSettings() =>
      _platform.openNotificationSettings();

  Future<void> testAlert() => _platform.testAlert();

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
