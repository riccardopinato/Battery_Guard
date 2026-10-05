import 'dart:async';
import 'dart:ui';

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
  Locale? localeOverride;
  bool onboardingComplete = false;
  bool loading = true;
  bool notificationsGranted = false;
  String? lastError;

  bool get isWebPreview => kIsWeb;

  Future<void> initialize() async {
    loading = true;
    notifyListeners();

    if (kIsWeb) {
      _initializeWebPreview();
      return;
    }

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
        _platform.getLocaleOverride(),
      ]);
      snapshot = values[0] as BatterySnapshot;
      config = values[1] as MonitoringConfig;
      history = values[2] as List<HistoryEntry>;
      chargingSessions = values[3] as List<ChargingSession>;
      currentSession = values[4] as ChargingSession?;
      notificationsGranted = values[5] as bool;
      reliability = values[6] as ReliabilityStatus;
      onboardingComplete = values[7] as bool;
      final language = values[8] as String?;
      localeOverride =
          language == null || language.isEmpty ? null : Locale(language);
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

  void _initializeWebPreview() {
    final now = DateTime.now();
    snapshot = BatterySnapshot.fromMap({
      'level': 76,
      'temperatureC': 34.2,
      'voltageMv': 4230,
      'currentMa': 2870.0,
      'powerW': 12.1,
      'temperatureAvailable': true,
      'voltageAvailable': true,
      'currentAvailable': true,
      'powerAvailable': true,
      'status': 'Charging',
      'health': 'Good',
      'technology': 'Li-ion',
      'isCharging': true,
      'isPlugged': true,
      'plugType': 'AC charger',
      'isPowerSaveMode': false,
      'timestamp': now.millisecondsSinceEpoch,
    });
    config = MonitoringConfig.defaults().copyWith(enabled: true);
    reliability = ReliabilityStatus.fromMap({
      'notificationsGranted': true,
      'notificationsGloballyEnabled': true,
      'monitorChannelEnabled': true,
      'alertChannelEnabled': true,
      'quietChannelEnabled': true,
      'batteryOptimizationIgnored': true,
      'monitoringRequested': true,
      'serviceHealthy': true,
      'manufacturer': 'Web Preview',
    });
    notificationsGranted = true;
    onboardingComplete = true;
    chargingSessions = List.generate(5, (index) {
      final start = now.subtract(Duration(days: index + 1, hours: 2));
      final end = start.add(Duration(minutes: 58 + index * 4));
      return ChargingSession(
        id: 'web-$index',
        startedAt: start,
        endedAt: end,
        lastObservedAt: end,
        startLevel: 28 + index * 3,
        currentLevel: 82 + index,
        endLevel: 82 + index,
        startTemperatureC: 29.5,
        currentTemperatureC: 34.0 + index * 0.4,
        maxTemperatureC: 35.0 + index * 0.5,
        averagePowerW: 15.0 + index,
        averageCurrentMa: 3500,
        percentPerHour: 45.0 - index * 2,
        estimatedMinutesToTarget: null,
        plugType: index.isEven ? 'AC charger' : 'USB',
        targetLevel: 80,
        completed: true,
        quality: ChargingSessionQuality.completed,
      );
    });
    history = const [];
    currentSession = null;
    loading = false;
    notifyListeners();
  }

  Future<void> _refreshCurrentSessionSilently() async {
    if (kIsWeb) return;
    try {
      currentSession = await _platform.getCurrentChargingSession();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> refreshSnapshot() async {
    if (kIsWeb) {
      notifyListeners();
      return;
    }
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
    if (kIsWeb) {
      notifyListeners();
      return;
    }
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
    if (kIsWeb) return;
    await _platform.repairMonitoring();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await refreshReliability();
  }

  Future<void> completeOnboarding() async {
    onboardingComplete = true;
    notifyListeners();
    if (!kIsWeb) {
      await _platform.setOnboardingComplete(true);
      await refreshReliability();
    }
  }

  Future<void> setLocaleOverride(String? languageCode) async {
    localeOverride =
        languageCode == null || languageCode.isEmpty
            ? null
            : Locale(languageCode);
    notifyListeners();
    if (!kIsWeb) {
      await _platform.setLocaleOverride(languageCode);
    }
  }

  Future<void> updateConfig(MonitoringConfig next) async {
    final previous = config;
    config = next;
    notifyListeners();
    if (kIsWeb) return;

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
    if (kIsWeb) {
      notifyListeners();
      return;
    }
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
    if (!kIsWeb) await _platform.clearHistory();
    history = const [];
    chargingSessions = const [];
    notifyListeners();
  }

  Future<bool> requestNotificationPermission() async {
    if (kIsWeb) return true;
    notificationsGranted = await _platform.requestNotificationPermission();
    await refreshReliability();
    return notificationsGranted;
  }

  Future<void> openBatterySettings() async {
    if (!kIsWeb) await _platform.openBatterySettings();
  }

  Future<void> openNotificationSettings() async {
    if (!kIsWeb) await _platform.openNotificationSettings();
  }

  Future<bool> testAlert() async {
    if (kIsWeb) return true;
    return _platform.testAlert();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
