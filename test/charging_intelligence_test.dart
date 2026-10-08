import 'package:battery_guard/models/battery_stress.dart';
import 'package:battery_guard/models/charge_test.dart';
import 'package:battery_guard/models/charging_setup_profile.dart';
import 'package:battery_guard/services/charging_intelligence_engine.dart';
import 'package:battery_guard/services/feature_access.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ChargingSetupProfile profile(
    String id,
    String name, {
    String charger = 'Charger',
    String cable = 'Cable',
  }) {
    final now = DateTime(2026, 10, 8, 12);
    return ChargingSetupProfile(
      id: id,
      name: name,
      chargerName: charger,
      cableName: cable,
      source: 'AC charger',
      notes: '',
      createdAt: now,
      updatedAt: now,
    );
  }

  ChargeTest buildTest({
    required String id,
    required String profileId,
    required String label,
    required DateTime endedAt,
    double power = 20,
    double peakPower = 24,
    double cv = 0.08,
    int drops = 0,
    double startTemp = 30,
    double averageTemp = 33,
    double maxTemp = 35,
    bool temperatureAvailable = true,
    double stress = 20,
    bool stressAvailable = true,
    ChargeTestConfidence confidence = ChargeTestConfidence.high,
  }) {
    return ChargeTest(
      id: id,
      profileId: profileId,
      label: label,
      chargerName: 'Charger',
      cableName: 'Cable',
      startedAt: endedAt.subtract(const Duration(minutes: 5)),
      endedAt: endedAt,
      startLevel: 35,
      endLevel: 42,
      averagePowerW: power,
      peakPowerW: peakPower,
      averageCurrentMa: 4000,
      averageVoltageV: 4.2,
      startTemperatureC: startTemp,
      averageTemperatureC: averageTemp,
      maxTemperatureC: maxTemp,
      temperatureAvailable: temperatureAvailable,
      samples: 15,
      source: 'AC charger',
      confidence: confidence,
      powerCoefficientOfVariation: cv,
      powerDropCount: drops,
      stressAvailable: stressAvailable,
      stressScore: stress,
      highSocMinutes: 0,
      hotMinutes: 0,
      veryHotMinutes: 0,
      highVoltageMinutes: 0,
    );
  }

  test('Charging setup profile round-trips persisted fields', () {
    final parsed = ChargingSetupProfile.fromMap({
      'id': 'setup-a',
      'name': 'Samsung 25 W + original cable',
      'chargerName': 'Samsung 25 W',
      'cableName': 'Original cable',
      'source': 'AC charger',
      'notes': 'Desk',
      'createdAt': 1000,
      'updatedAt': 2000,
    });

    expect(parsed.id, 'setup-a');
    expect(parsed.displayName, 'Samsung 25 W + original cable');
    expect(parsed.toMap()['cableName'], 'Original cable');
  });

  test('personal speed baseline only compares the same setup profile', () {
    final now = DateTime(2026, 10, 8, 12);
    final current = buildTest(
      id: 'current',
      profileId: 'setup-a',
      label: 'Setup A',
      endedAt: now,
      power: 22,
    );
    final history = [
      current,
      buildTest(
        id: 'a1',
        profileId: 'setup-a',
        label: 'Setup A',
        endedAt: now.subtract(const Duration(days: 1)),
        power: 20,
      ),
      buildTest(
        id: 'a2',
        profileId: 'setup-a',
        label: 'Setup A',
        endedAt: now.subtract(const Duration(days: 2)),
        power: 20,
      ),
      buildTest(
        id: 'other',
        profileId: 'setup-b',
        label: 'Setup B',
        endedAt: now.subtract(const Duration(days: 3)),
        power: 40,
      ),
    ];

    final analysis = ChargingIntelligenceEngine.analyze(current, history);

    expect(analysis.baselinePowerW, closeTo(20, 0.001));
    expect(analysis.comparableTests, 2);
    expect(analysis.powerDeltaPercent, closeTo(10, 0.001));
    expect(analysis.speedScore, closeTo(88, 0.001));
  });

  test('stability score penalizes coefficient of variation and repeated drops', () {
    final now = DateTime(2026, 10, 8, 12);
    final stable = buildTest(
      id: 'stable',
      profileId: 'a',
      label: 'Stable',
      endedAt: now,
      cv: 0.05,
      drops: 0,
    );
    final unstable = buildTest(
      id: 'unstable',
      profileId: 'b',
      label: 'Unstable',
      endedAt: now,
      cv: 0.35,
      drops: 4,
    );

    final stableAnalysis =
        ChargingIntelligenceEngine.analyze(stable, [stable]);
    final unstableAnalysis =
        ChargingIntelligenceEngine.analyze(unstable, [unstable]);

    expect(stableAnalysis.stabilityScore, greaterThan(90));
    expect(unstableAnalysis.stabilityScore, lessThan(40));
    expect(
      unstableAnalysis.anomalies,
      contains(ChargingAnomaly.unstablePower),
    );
    expect(
      unstableAnalysis.anomalies,
      contains(ChargingAnomaly.repeatedPowerDrops),
    );
  });

  test('thermal score penalizes high maximum temperature and large rise', () {
    final now = DateTime(2026, 10, 8, 12);
    final cool = buildTest(
      id: 'cool',
      profileId: 'a',
      label: 'Cool',
      endedAt: now,
      startTemp: 29,
      maxTemp: 34,
    );
    final hot = buildTest(
      id: 'hot',
      profileId: 'b',
      label: 'Hot',
      endedAt: now,
      startTemp: 30,
      maxTemp: 44,
    );

    final coolScore =
        ChargingIntelligenceEngine.analyze(cool, [cool]).thermalScore;
    final hotAnalysis = ChargingIntelligenceEngine.analyze(hot, [hot]);

    expect(coolScore, greaterThan(90));
    expect(hotAnalysis.thermalScore, lessThan(coolScore!));
    expect(
      hotAnalysis.anomalies,
      contains(ChargingAnomaly.highTemperature),
    );
  });

  test('ranking keeps charger/cable profiles separate and orders by score', () {
    final now = DateTime(2026, 10, 8, 12);
    final profiles = [
      profile('fast', 'Fast setup'),
      profile('slow', 'Slow setup'),
    ];
    final tests = <ChargeTest>[
      for (var index = 0; index < 4; index++)
        buildTest(
          id: 'fast-$index',
          profileId: 'fast',
          label: 'Fast setup',
          endedAt: now.subtract(Duration(days: index)),
          power: 22 - index * 0.2,
          cv: 0.05,
          maxTemp: 35,
          stress: 15,
        ),
      for (var index = 0; index < 4; index++)
        buildTest(
          id: 'slow-$index',
          profileId: 'slow',
          label: 'Slow setup',
          endedAt: now.subtract(Duration(days: index + 5)),
          power: 15 - index * 0.2,
          cv: 0.25,
          drops: 3,
          maxTemp: 42,
          stress: 55,
        ),
    ];

    final ranking = ChargingIntelligenceEngine.ranking(
      tests: tests,
      profiles: profiles,
    );

    expect(ranking, hasLength(2));
    expect(ranking.first.name, 'Fast setup');
    expect(ranking.first.overallScore, greaterThan(ranking.last.overallScore!));
    expect(ranking.first.overallTrendDelta, isNotNull);
  });

  test('Battery Stress rises with high SoC heat and voltage exposure', () {
    final start = DateTime(2026, 10, 8, 12);
    final low = BatteryStressAnalysis.fromSamples([
      BatteryStressSample(
        timestamp: start,
        level: 30,
        temperatureC: 30,
        voltageV: 3.9,
      ),
      BatteryStressSample(
        timestamp: start.add(const Duration(minutes: 20)),
        level: 60,
        temperatureC: 33,
        voltageV: 4.05,
      ),
    ]);
    final high = BatteryStressAnalysis.fromSamples([
      BatteryStressSample(
        timestamp: start,
        level: 85,
        temperatureC: 40,
        voltageV: 4.22,
      ),
      BatteryStressSample(
        timestamp: start.add(const Duration(minutes: 20)),
        level: 92,
        temperatureC: 43,
        voltageV: 4.28,
      ),
      BatteryStressSample(
        timestamp: start.add(const Duration(minutes: 40)),
        level: 96,
        temperatureC: 44,
        voltageV: 4.30,
      ),
    ]);

    expect(low.dataSufficient, isTrue);
    expect(high.score, greaterThan(low.score));
    expect(high.level.index, greaterThan(low.level.index));
    expect(high.reasons, contains('HEAT_EXPOSURE'));
  });

  test('Free keeps qualitative protection while Pro owns deep analytics', () {
    expect(
      FeatureCatalog.tierFor(BatteryGuardFeature.chargeDoctorBasic),
      FeatureTier.free,
    );
    expect(
      FeatureCatalog.tierFor(BatteryGuardFeature.batteryStressSummary),
      FeatureTier.free,
    );
    expect(
      FeatureCatalog.tierFor(BatteryGuardFeature.multipleChargingSetups),
      FeatureTier.premium,
    );
    expect(
      FeatureCatalog.tierFor(BatteryGuardFeature.detailedChargeScores),
      FeatureTier.premium,
    );
    expect(
      FeatureCatalog.tierFor(BatteryGuardFeature.chargerRanking),
      FeatureTier.premium,
    );
    expect(
      FeatureCatalog.tierFor(BatteryGuardFeature.batteryStressDetails),
      FeatureTier.premium,
    );
  });

  test('legacy ChargeTest maps remain readable without invented Pro evidence', () {
    final legacy = ChargeTest.fromMap({
      'id': 'legacy',
      'label': 'USB-C 65 W',
      'startedAt': 1000,
      'endedAt': 301000,
      'averagePowerW': 18.2,
      'samples': 15,
      'source': 'AC charger',
      'confidence': 'high',
    });

    expect(legacy.profileId, isEmpty);
    expect(legacy.peakPowerW, closeTo(18.2, 0.001));
    expect(legacy.powerCoefficientOfVariation, 0);
    expect(legacy.stressAvailable, isFalse);
  });
}
