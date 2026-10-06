import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../models/battery_snapshot.dart';
import '../models/charge_test.dart';
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
  Timer? _chargeDoctorTimer;

  BatterySnapshot snapshot = BatterySnapshot.empty();
  MonitoringConfig config = MonitoringConfig.defaults();
  List<HistoryEntry> history = const [];
  List<ChargingSession> chargingSessions = const [];
  List<ChargeTest> chargeTests = const [];
  ActiveChargeTest? activeChargeTest;
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
        _platform.getChargeTests(),
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
      chargeTests = values[9] as List<ChargeTest>;
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
    chargeTests = List.generate(3, (index) {
      final end = now.subtract(Duration(days: index + 1));
      final start = end.subtract(const Duration(minutes: 5));
      return ChargeTest(
        id: 'web-test-$index',
        label: index == 0 ? 'USB-C 65 W' : 'Charger ${index + 1}',
        startedAt: start,
        endedAt: end,
        startLevel: 35 + index * 5,
        endLevel: 39 + index * 5,
        averagePowerW: 17.8 - index * 2.1,
        averageCurrentMa: 4100 - index * 400,
        averageVoltageV: 4.28,
        startTemperatureC: 30.0,
        maxTemperatureC: 33.4 + index,
        samples: 15,
        source: index == 2 ? 'USB' : 'AC charger',
        confidence: ChargeTestConfidence.high,
      );
    });
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

  Future<String?> startChargeDoctorTest(String label) async {
    if (activeChargeTest != null) return null;

    final first = kIsWeb ? snapshot : await _platform.getSnapshot();
    if (!first.isPlugged) return 'not_plugged';
    if (!first.powerAvailable || !first.currentAvailable) {
      return 'power_unavailable';
    }

    activeChargeTest = ActiveChargeTest(
      label: label.trim().isEmpty ? 'Charge Test' : label.trim(),
      startedAt: DateTime.now(),
      startLevel: first.level,
      startTemperatureC:
          first.temperatureAvailable ? first.temperatureC : 0,
      source: first.plugType,
    );
    _addChargeDoctorSample(first);
    notifyListeners();

    _chargeDoctorTimer?.cancel();
    _chargeDoctorTimer = Timer.periodic(
      Duration(seconds: kIsWeb ? 5 : 20),
      (_) => unawaited(_sampleChargeDoctor()),
    );
    return null;
  }

  Future<void> _sampleChargeDoctor() async {
    final active = activeChargeTest;
    if (active == null) return;

    final value = kIsWeb ? snapshot : await _platform.getSnapshot();
    if (!value.isPlugged) {
      await stopChargeDoctorTest();
      return;
    }
    _addChargeDoctorSample(value);
    notifyListeners();
  }

  void _addChargeDoctorSample(BatterySnapshot value) {
    final active = activeChargeTest;
    if (active == null) return;
    if (value.powerAvailable) active.powers.add(value.powerW.abs());
    if (value.currentAvailable) active.currents.add(value.currentMa.abs());
    if (value.voltageAvailable) active.voltages.add(value.voltageV);
    if (value.temperatureAvailable) {
      active.temperatures.add(value.temperatureC);
    }
  }

  Future<ChargeTest?> stopChargeDoctorTest() async {
    final active = activeChargeTest;
    if (active == null) return null;
    _chargeDoctorTimer?.cancel();
    _chargeDoctorTimer = null;

    final finalSnapshot = kIsWeb ? snapshot : await _platform.getSnapshot();
    _addChargeDoctorSample(finalSnapshot);
    final endedAt = DateTime.now();
    final duration = endedAt.difference(active.startedAt);

    final confidence = duration.inMinutes >= 5 && active.samples >= 10
        ? ChargeTestConfidence.high
        : duration.inMinutes >= 2 && active.samples >= 4
            ? ChargeTestConfidence.medium
            : ChargeTestConfidence.low;

    final temperatures = active.temperatures;
    final test = ChargeTest(
      id: endedAt.microsecondsSinceEpoch.toString(),
      label: active.label,
      startedAt: active.startedAt,
      endedAt: endedAt,
      startLevel: active.startLevel,
      endLevel: finalSnapshot.level,
      averagePowerW: active.average(active.powers),
      averageCurrentMa: active.average(active.currents),
      averageVoltageV: active.average(active.voltages),
      startTemperatureC: active.startTemperatureC,
      maxTemperatureC: temperatures.isEmpty
          ? 0
          : temperatures.reduce((a, b) => a > b ? a : b),
      samples: active.samples,
      source: active.source,
      confidence: confidence,
    );

    activeChargeTest = null;
    chargeTests = [test, ...chargeTests].take(50).toList(growable: false);
    notifyListeners();

    if (!kIsWeb) await _platform.saveChargeTest(test);
    return test;
  }

  Future<void> clearChargeTests() async {
    _chargeDoctorTimer?.cancel();
    _chargeDoctorTimer = null;
    activeChargeTest = null;
    chargeTests = const [];
    notifyListeners();
    if (!kIsWeb) await _platform.clearChargeTests();
  }

  @override
  void dispose() {
    _chargeDoctorTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }
}
