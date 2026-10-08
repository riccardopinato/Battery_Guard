import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../models/battery_snapshot.dart';
import '../models/battery_health_report.dart';
import '../models/battery_intelligence.dart';
import '../models/battery_stress.dart';
import '../models/charge_test.dart';
import '../models/charging_session.dart';
import '../models/charging_setup_profile.dart';
import '../models/history_entry.dart';
import '../models/monitoring_config.dart';
import '../models/reliability_status.dart';
import 'battery_intelligence_engine.dart';
import 'feature_access.dart';
import 'native_battery_service.dart';
import 'premium_service.dart';

class AppController extends ChangeNotifier {
  AppController({NativeBatteryService? platform})
      : _platform = platform ?? NativeBatteryService.instance {
    premium = PremiumService(
      platform: _platform,
      onChanged: notifyListeners,
    );
  }

  final NativeBatteryService _platform;
  late final PremiumService premium;
  StreamSubscription<BatterySnapshot>? _subscription;
  Timer? _chargeDoctorTimer;

  BatterySnapshot snapshot = BatterySnapshot.empty();
  BatteryHealthReport batteryHealthReport = BatteryHealthReport.empty;
  IdleDrainReport idleDrainReport = IdleDrainReport.empty;
  MonitoringConfig config = MonitoringConfig.defaults();
  List<HistoryEntry> history = const [];
  List<ChargingSession> chargingSessions = const [];
  List<ChargeTest> chargeTests = const [];
  List<ChargingSetupProfile> chargingSetups = const [];
  ActiveChargeTest? activeChargeTest;
  ChargingSession? currentSession;
  ReliabilityStatus reliability = ReliabilityStatus.unknown;
  Locale? localeOverride;
  bool onboardingComplete = false;
  bool loading = true;
  bool notificationsGranted = false;
  String? lastError;

  bool get isWebPreview => kIsWeb;

  BatteryEtaEstimate get standardEta =>
      BatteryIntelligenceEngine.standardEta(
        snapshot: snapshot,
        currentSession: currentSession,
        targetLevel: config.targetLevel,
      );

  BatteryEtaEstimate get smartEta =>
      BatteryIntelligenceEngine.smartEta(
        snapshot: snapshot,
        currentSession: currentSession,
        history: chargingSessions,
        targetLevel: config.targetLevel,
      );

  BatteryEtaEstimate get effectiveEta =>
      premium.isPro && canUseFeature(BatteryGuardFeature.smartEta)
          ? smartEta
          : standardEta;

  bool canUseFeature(BatteryGuardFeature feature) =>
      FeatureCatalog.isEnabled(feature, isPro: premium.isPro);

  List<ChargingSetupProfile> get accessibleChargingSetups {
    if (premium.isPro ||
        canUseFeature(BatteryGuardFeature.multipleChargingSetups)) {
      return chargingSetups;
    }
    return chargingSetups.take(1).toList(growable: false);
  }

  Future<void> initialize() async {
    loading = true;
    notifyListeners();

    if (kIsWeb) {
      _initializeWebPreview();
      unawaited(premium.initialize(webPreview: true));
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
        _platform.getChargingSetups(),
        _platform.getBatteryHealthReport(),
        _platform.getIdleDrainReport(),
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
      chargingSetups = values[10] as List<ChargingSetupProfile>;
      batteryHealthReport = values[11] as BatteryHealthReport;
      idleDrainReport = values[12] as IdleDrainReport;
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
      unawaited(premium.initialize(webPreview: false));
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
      'chargeCounterAvailable': true,
      'chargeCounterMah': 3820.0,
      'cycleCount': 187,
      'status': 'Charging',
      'health': 'Good',
      'technology': 'Li-ion',
      'isCharging': true,
      'isPlugged': true,
      'plugType': 'AC charger',
      'isPowerSaveMode': false,
      'screenInteractive': false,
      'screenStateAvailable': true,
      'timestamp': now.millisecondsSinceEpoch,
      'signals': {
        'level': {
          'available': true,
          'source': 'system_reported',
          'confidence': 'high',
          'observedAt': now.millisecondsSinceEpoch,
        },
        'temperature': {
          'available': true,
          'source': 'system_reported',
          'confidence': 'high',
          'observedAt': now.millisecondsSinceEpoch,
        },
        'voltage': {
          'available': true,
          'source': 'system_reported',
          'confidence': 'high',
          'observedAt': now.millisecondsSinceEpoch,
        },
        'current': {
          'available': true,
          'source': 'system_reported',
          'confidence': 'medium',
          'observedAt': now.millisecondsSinceEpoch,
        },
        'power': {
          'available': true,
          'source': 'calculated',
          'confidence': 'medium',
          'observedAt': now.millisecondsSinceEpoch,
        },
        'chargeCounter': {
          'available': true,
          'source': 'system_reported',
          'confidence': 'medium',
          'observedAt': now.millisecondsSinceEpoch,
        },
        'cycleCount': {
          'available': true,
          'source': 'system_reported',
          'confidence': 'high',
          'observedAt': now.millisecondsSinceEpoch,
        },
        'status': {
          'available': true,
          'source': 'system_reported',
          'confidence': 'high',
          'observedAt': now.millisecondsSinceEpoch,
        },
        'health': {
          'available': true,
          'source': 'system_reported',
          'confidence': 'medium',
          'observedAt': now.millisecondsSinceEpoch,
        },
        'technology': {
          'available': true,
          'source': 'system_reported',
          'confidence': 'medium',
          'observedAt': now.millisecondsSinceEpoch,
        },
        'plugType': {
          'available': true,
          'source': 'system_reported',
          'confidence': 'high',
          'observedAt': now.millisecondsSinceEpoch,
        },
      },
    });
    config = MonitoringConfig.defaults().copyWith(
      enabled: true,
      lowLevel: 20,
      targetLevel: 80,
    );
    batteryHealthReport = const BatteryHealthReport(
      nominalCapacityMah: 5000,
      estimatedFullCapacityMah: 4560,
      estimatedHealthPercent: 91.2,
      confidence: 'high',
      sampleCount: 12,
      cycleCount: 187,
      trendPercent: -2.8,
      averageTemperatureC: 32.4,
      maxTemperatureC: 41.1,
      estimatorVersion: 'health_lab_2',
      reportedHealthStatus: 'Good',
      reportedHealthAvailable: true,
      confidenceScore: 88,
      totalSampleCount: 15,
      outlierCount: 3,
      socSpread: 52,
      dispersionPercent: 5.2,
      uncertaintyPercent: 1.8,
      trendDirection: 'down',
    );
    idleDrainReport = const IdleDrainReport(
      status: 'normal',
      confidence: 'high',
      segmentCount: 11,
      baselineRatePercentPerHour: 0.42,
      recentRatePercentPerHour: 0.48,
      deltaPercent: 14.3,
      powerSaveMode: false,
      recentSegments: [],
    );
    reliability = ReliabilityStatus.fromMap({
      'notificationsGranted': true,
      'notificationsGloballyEnabled': true,
      'monitorChannelEnabled': true,
      'alertChannelEnabled': true,
      'highChargeChannelEnabled': true,
      'lowBatteryChannelEnabled': true,
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
      final points = List.generate(9, (pointIndex) {
        final fraction = pointIndex / 8;
        final timestamp = start.add(
          Duration(
            milliseconds:
                (end.difference(start).inMilliseconds * fraction).round(),
          ),
        );
        final level = (28 + index * 3 + (54 * fraction)).round().clamp(0, 100);
        final power = pointIndex < 5
            ? 18.0 + index + pointIndex * 0.8
            : 21.0 + index - (pointIndex - 4) * 3.0;
        return {
          'timestamp': timestamp.millisecondsSinceEpoch,
          'level': level,
          'isCharging': true,
          'isPlugged': true,
          'temperatureAvailable': true,
          'temperatureC': 29.5 + pointIndex * 0.6,
          'voltageAvailable': true,
          'voltageV': 4.0 + fraction * 0.25,
          'currentAvailable': true,
          'currentMa': 3500.0 - pointIndex * 120,
          'powerAvailable': true,
          'powerW': power.clamp(3.0, 30.0),
        };
      });

      return ChargingSession.fromMap({
        'id': 'web-$index',
        'startedAt': start.millisecondsSinceEpoch,
        'endedAt': end.millisecondsSinceEpoch,
        'lastObservedAt': end.millisecondsSinceEpoch,
        'startLevel': 28 + index * 3,
        'currentLevel': 82 + index,
        'endLevel': 82 + index,
        'startTemperatureC': 29.5,
        'currentTemperatureC': 34.0 + index * 0.4,
        'maxTemperatureC': 35.0 + index * 0.5,
        'temperatureAvailable': true,
        'averagePowerW': 15.0 + index,
        'averageCurrentMa': 3500,
        'percentPerHour': 45.0 - index * 2,
        'estimatedMinutesToTarget': -1,
        'plugType': index.isEven ? 'AC charger' : 'USB',
        'targetLevel': 80,
        'completed': true,
        'quality': 'completed',
        'validity': index == 4 ? 'partial' : 'valid',
        'reasonCodes': index == 4
            ? ['POWER_DATA_MISSING', 'USER_UNPLUGGED']
            : ['USER_UNPLUGGED'],
        'oemChargeLimitDetected': index == 0,
        'oemChargeLimitLevel': index == 0 ? 80 : -1,
        'curvePoints': points,
      });
    });
    history = const [];
    currentSession = ChargingSession.fromMap({
      'id': 'web-current',
      'startedAt': now.subtract(const Duration(minutes: 30)).millisecondsSinceEpoch,
      'lastObservedAt': now.millisecondsSinceEpoch,
      'startLevel': 60,
      'currentLevel': 76,
      'endLevel': 76,
      'startTemperatureC': 30.0,
      'currentTemperatureC': 34.2,
      'maxTemperatureC': 34.7,
      'temperatureAvailable': true,
      'averagePowerW': 16.8,
      'averageCurrentMa': 3700,
      'percentPerHour': 32.0,
      'estimatedMinutesToTarget': 8,
      'plugType': 'AC charger',
      'targetLevel': 80,
      'completed': false,
      'quality': 'active',
      'validity': 'active',
      'reasonCodes': const [],
      'curvePoints': [
        {
          'timestamp': now.subtract(const Duration(minutes: 30)).millisecondsSinceEpoch,
          'level': 60,
          'isCharging': true,
          'isPlugged': true,
          'screenStateAvailable': true,
          'screenInteractive': false,
        },
        {
          'timestamp': now.millisecondsSinceEpoch,
          'level': 76,
          'isCharging': true,
          'isPlugged': true,
          'screenStateAvailable': true,
          'screenInteractive': false,
        },
      ],
    });
    chargingSetups = [
      ChargingSetupProfile(
        id: 'web-samsung-25w',
        name: 'Samsung 25 W + cavo originale',
        chargerName: 'Samsung 25 W',
        cableName: 'Cavo originale',
        source: 'AC charger',
        notes: '',
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now,
      ),
      ChargingSetupProfile(
        id: 'web-travel-20w',
        name: 'Travel 20 W + USB-C',
        chargerName: 'Travel 20 W',
        cableName: 'USB-C',
        source: 'AC charger',
        notes: '',
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
    ];
    chargeTests = List.generate(6, (index) {
      final end = now.subtract(Duration(days: index + 1));
      final start = end.subtract(const Duration(minutes: 5));
      final primary = index < 4;
      final profile = primary ? chargingSetups[0] : chargingSetups[1];
      final power = primary ? 20.8 - index * 0.35 : 15.1 - (index - 4) * 0.4;
      return ChargeTest(
        id: 'web-test-$index',
        profileId: profile.id,
        label: profile.displayName,
        chargerName: profile.chargerName,
        cableName: profile.cableName,
        startedAt: start,
        endedAt: end,
        startLevel: 35 + index * 3,
        endLevel: 40 + index * 3,
        averagePowerW: power,
        peakPowerW: power + 2.8,
        averageCurrentMa: primary ? 4200 : 3200,
        averageVoltageV: 4.25,
        startTemperatureC: 30.0,
        averageTemperatureC: primary ? 33.0 : 32.0,
        maxTemperatureC: primary ? 35.0 + index * 0.3 : 34.0,
        temperatureAvailable: true,
        samples: 15,
        source: profile.source,
        confidence: ChargeTestConfidence.high,
        powerCoefficientOfVariation: primary ? 0.07 + index * 0.01 : 0.14,
        powerDropCount: primary ? (index == 3 ? 1 : 0) : 2,
        stressAvailable: true,
        stressScore: primary ? 18.0 + index * 2 : 28.0,
        highSocMinutes: 0,
        hotMinutes: primary ? 0 : 1.5,
        veryHotMinutes: 0,
        highVoltageMinutes: 0,
        highPowerHeatMinutes: 0,
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
        _platform.getBatteryHealthReport(),
        _platform.getIdleDrainReport(),
      ]);
      snapshot = values[0] as BatterySnapshot;
      currentSession = values[1] as ChargingSession?;
      batteryHealthReport = values[2] as BatteryHealthReport;
      idleDrainReport = values[3] as IdleDrainReport;
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

  Future<void> setLowLevel(int value) =>
      updateConfig(config.copyWith(lowLevel: value));

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

  Future<bool> testHighAlert() async {
    if (kIsWeb) return true;
    return _platform.testHighAlert();
  }

  Future<bool> testLowAlert() async {
    if (kIsWeb) return true;
    return _platform.testLowAlert();
  }

  Future<void> refreshBatteryHealth() async {
    await refreshBatteryIntelligence();
  }

  Future<void> refreshBatteryIntelligence() async {
    if (kIsWeb) {
      notifyListeners();
      return;
    }
    try {
      final values = await Future.wait<Object>([
        _platform.getBatteryHealthReport(),
        _platform.getIdleDrainReport(),
      ]);
      batteryHealthReport = values[0] as BatteryHealthReport;
      idleDrainReport = values[1] as IdleDrainReport;
      notifyListeners();
    } catch (error) {
      lastError = error.toString();
      notifyListeners();
    }
  }

  Future<void> setNominalCapacityMah(int value) async {
    if (kIsWeb) {
      batteryHealthReport =
          batteryHealthReport.withNominalCapacity(value);
      notifyListeners();
      return;
    }
    batteryHealthReport = await _platform.setNominalCapacityMah(value);
    notifyListeners();
  }

  Future<String?> startChargeDoctorTest(
    ChargingSetupProfile setup,
  ) async {
    if (activeChargeTest != null) return null;
    if (!premium.isPro &&
        chargingSetups.isNotEmpty &&
        accessibleChargingSetups.every((item) => item.id != setup.id)) {
      return 'premium_required';
    }

    final first = kIsWeb ? snapshot : await _platform.getSnapshot();
    if (!first.isPlugged) return 'not_plugged';
    if (!first.isCharging) return 'not_charging';
    if (!first.powerAvailable || !first.currentAvailable) {
      return 'power_unavailable';
    }

    activeChargeTest = ActiveChargeTest(
      profileId: setup.id,
      label: setup.displayName,
      chargerName: setup.chargerName,
      cableName: setup.cableName,
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
    if (!value.isPlugged || !value.isCharging) {
      await stopChargeDoctorTest();
      return;
    }
    _addChargeDoctorSample(value);
    notifyListeners();
  }

  void _addChargeDoctorSample(BatterySnapshot value) {
    final active = activeChargeTest;
    if (active == null) return;

    final power = value.powerAvailable ? value.powerW.abs() : null;
    final current = value.currentAvailable ? value.currentMa.abs() : null;
    final voltage = value.voltageAvailable ? value.voltageV : null;
    final temperature =
        value.temperatureAvailable ? value.temperatureC : null;

    if (power != null) active.powers.add(power);
    if (current != null) active.currents.add(current);
    if (voltage != null) active.voltages.add(voltage);
    if (temperature != null) active.temperatures.add(temperature);

    active.observations.add(
      ChargeTestObservation(
        timestamp: value.timestamp,
        level: value.level,
        powerW: power,
        currentMa: current,
        voltageV: voltage,
        temperatureC: temperature,
      ),
    );
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
    final stress = BatteryStressAnalysis.fromSamples(
      [
        for (final sample in active.observations)
          BatteryStressSample(
            timestamp: sample.timestamp,
            level: sample.level,
            temperatureC: sample.temperatureC,
            voltageV: sample.voltageV,
            powerW: sample.powerW,
          ),
      ],
    );
    final test = ChargeTest(
      id: endedAt.microsecondsSinceEpoch.toString(),
      profileId: active.profileId,
      label: active.label,
      chargerName: active.chargerName,
      cableName: active.cableName,
      startedAt: active.startedAt,
      endedAt: endedAt,
      startLevel: active.startLevel,
      endLevel: finalSnapshot.level,
      averagePowerW: active.average(active.powers),
      peakPowerW: active.peak(active.powers),
      averageCurrentMa: active.average(active.currents),
      averageVoltageV: active.average(active.voltages),
      startTemperatureC: active.startTemperatureC,
      averageTemperatureC: active.average(temperatures),
      maxTemperatureC: temperatures.isEmpty
          ? 0
          : temperatures.reduce((a, b) => a > b ? a : b),
      temperatureAvailable: temperatures.isNotEmpty,
      samples: active.samples,
      source: active.source,
      confidence: confidence,
      powerCoefficientOfVariation:
          active.coefficientOfVariation(active.powers),
      powerDropCount: active.powerDropCount(),
      stressAvailable: stress.dataSufficient,
      stressScore: stress.dataSufficient ? stress.score : 0,
      highSocMinutes: stress.highSocMinutes,
      hotMinutes: stress.hotMinutes,
      veryHotMinutes: stress.veryHotMinutes,
      highVoltageMinutes: stress.highVoltageMinutes,
      highPowerHeatMinutes: stress.highPowerHeatMinutes,
    );

    activeChargeTest = null;
    chargeTests = [test, ...chargeTests].take(50).toList(growable: false);
    notifyListeners();

    if (!kIsWeb) await _platform.saveChargeTest(test);
    return test;
  }

  Future<String?> saveChargingSetup({
    String? id,
    required String name,
    required String chargerName,
    required String cableName,
    String notes = '',
  }) async {
    final normalizedName = name.trim();
    final normalizedCharger = chargerName.trim();
    final normalizedCable = cableName.trim();
    if (normalizedName.isEmpty &&
        normalizedCharger.isEmpty &&
        normalizedCable.isEmpty) {
      return 'invalid_setup';
    }

    final existingId = id?.trim() ?? '';
    final creating = existingId.isEmpty;
    if (creating &&
        !premium.isPro &&
        chargingSetups.isNotEmpty &&
        !canUseFeature(BatteryGuardFeature.multipleChargingSetups)) {
      return 'premium_required';
    }

    final now = DateTime.now();
    ChargingSetupProfile? existing;
    if (existingId.isNotEmpty) {
      for (final item in chargingSetups) {
        if (item.id == existingId) {
          existing = item;
          break;
        }
      }
    }
    final profile = ChargingSetupProfile(
      id: existing?.id ?? now.microsecondsSinceEpoch.toString(),
      name: normalizedName.isNotEmpty
          ? normalizedName
          : [normalizedCharger, normalizedCable]
              .where((value) => value.isNotEmpty)
              .join(' + '),
      chargerName: normalizedCharger,
      cableName: normalizedCable,
      source: snapshot.plugType,
      notes: notes.trim(),
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    chargingSetups = [
      profile,
      ...chargingSetups.where((item) => item.id != profile.id),
    ];
    notifyListeners();
    if (!kIsWeb) await _platform.saveChargingSetup(profile);
    return profile.id;
  }

  Future<void> deleteChargingSetup(String id) async {
    if (activeChargeTest?.profileId == id) return;
    chargingSetups =
        chargingSetups.where((item) => item.id != id).toList(growable: false);
    notifyListeners();
    if (!kIsWeb) await _platform.deleteChargingSetup(id);
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
    premium.dispose();
    super.dispose();
  }
}
