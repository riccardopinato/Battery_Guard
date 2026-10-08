import 'dart:math' as math;

import '../models/charge_test.dart';
import '../models/charging_setup_profile.dart';
import 'charge_test_group.dart';

enum ChargeScoreBand {
  excellent,
  good,
  fair,
  weak,
  unavailable,
}

enum ChargingAnomaly {
  unstablePower,
  repeatedPowerDrops,
  highTemperature,
  highTemperatureRise,
  slowerThanBaseline,
  insufficientBaseline,
  elevatedStress,
}

class ChargeTestAnalysis {
  const ChargeTestAnalysis({
    required this.speedScore,
    required this.stabilityScore,
    required this.thermalScore,
    required this.overallScore,
    required this.baselinePowerW,
    required this.powerDeltaPercent,
    required this.comparableTests,
    required this.anomalies,
  });

  final double? speedScore;
  final double? stabilityScore;
  final double? thermalScore;
  final double? overallScore;
  final double? baselinePowerW;
  final double? powerDeltaPercent;
  final int comparableTests;
  final List<ChargingAnomaly> anomalies;

  ChargeScoreBand bandFor(double? value) {
    if (value == null) return ChargeScoreBand.unavailable;
    if (value >= 90) return ChargeScoreBand.excellent;
    if (value >= 75) return ChargeScoreBand.good;
    if (value >= 55) return ChargeScoreBand.fair;
    return ChargeScoreBand.weak;
  }

  ChargeScoreBand get speedBand => bandFor(speedScore);
  ChargeScoreBand get stabilityBand => bandFor(stabilityScore);
  ChargeScoreBand get thermalBand => bandFor(thermalScore);
  ChargeScoreBand get overallBand => bandFor(overallScore);
}

class ChargingSetupRankingEntry {
  const ChargingSetupRankingEntry({
    required this.setupId,
    required this.name,
    required this.tests,
    required this.averagePowerW,
    required this.speedScore,
    required this.stabilityScore,
    required this.thermalScore,
    required this.overallScore,
    required this.averageStressScore,
    required this.overallTrendDelta,
    required this.stressTrendDelta,
  });

  final String setupId;
  final String name;
  final int tests;
  final double averagePowerW;
  final double? speedScore;
  final double? stabilityScore;
  final double? thermalScore;
  final double? overallScore;
  final double averageStressScore;
  final double? overallTrendDelta;
  final double? stressTrendDelta;
}

class ChargingIntelligenceEngine {
  const ChargingIntelligenceEngine._();

  static ChargeTestAnalysis analyze(
    ChargeTest current,
    List<ChargeTest> all,
  ) {
    final comparable = all
        .where(
          (test) =>
              test.id != current.id &&
              test.reliable &&
              _sameSetup(test, current),
        )
        .toList(growable: false);

    final baselinePower = comparable.length >= 2
        ? _median(
            comparable
                .map((test) => test.averagePowerW)
                .where((value) => value > 0)
                .toList(),
          )
        : null;

    final powerDelta = baselinePower != null && baselinePower > 0
        ? ((current.averagePowerW - baselinePower) / baselinePower) * 100
        : null;

    final speedScore = baselinePower != null && baselinePower > 0
        ? (80 + ((current.averagePowerW / baselinePower) - 1) * 80)
            .clamp(0, 100)
            .toDouble()
        : null;

    final stabilityScore = _stabilityScore(current);
    final thermalScore = _thermalScore(current);

    var weightedTotal = 0.0;
    var weightTotal = 0.0;
    if (speedScore != null) {
      weightedTotal += speedScore * 0.35;
      weightTotal += 0.35;
    }
    if (stabilityScore != null) {
      weightedTotal += stabilityScore * 0.35;
      weightTotal += 0.35;
    }
    if (thermalScore != null) {
      weightedTotal += thermalScore * 0.30;
      weightTotal += 0.30;
    }
    final overall = weightTotal <= 0 ? null : weightedTotal / weightTotal;

    final anomalies = <ChargingAnomaly>[];
    if (current.powerCoefficientOfVariation > 0.18) {
      anomalies.add(ChargingAnomaly.unstablePower);
    }
    if (current.powerDropCount >= 2) {
      anomalies.add(ChargingAnomaly.repeatedPowerDrops);
    }
    if (current.temperatureAvailable && current.maxTemperatureC >= 42) {
      anomalies.add(ChargingAnomaly.highTemperature);
    }
    if (current.temperatureAvailable && current.temperatureRiseC >= 8) {
      anomalies.add(ChargingAnomaly.highTemperatureRise);
    }
    if (powerDelta != null && powerDelta <= -15) {
      anomalies.add(ChargingAnomaly.slowerThanBaseline);
    }
    if (baselinePower == null) {
      anomalies.add(ChargingAnomaly.insufficientBaseline);
    }
    if (current.stressScore >= 50) {
      anomalies.add(ChargingAnomaly.elevatedStress);
    }

    return ChargeTestAnalysis(
      speedScore: speedScore,
      stabilityScore: stabilityScore,
      thermalScore: thermalScore,
      overallScore: overall,
      baselinePowerW: baselinePower,
      powerDeltaPercent: powerDelta,
      comparableTests: comparable.length,
      anomalies: List.unmodifiable(anomalies),
    );
  }

  static List<ChargingSetupRankingEntry> ranking({
    required List<ChargeTest> tests,
    required List<ChargingSetupProfile> profiles,
  }) {
    final reliable = tests.where((test) => test.reliable).toList();
    final keys = <String>{
      for (final test in reliable) _setupKey(test),
    };
    final profileById = {
      for (final profile in profiles) profile.id: profile,
    };

    final entries = <ChargingSetupRankingEntry>[];
    for (final key in keys) {
      final group = reliable.where((test) => _setupKey(test) == key).toList();
      if (group.isEmpty) continue;

      final analyses = [
        for (final test in group) analyze(test, reliable),
      ];
      final representative = group.first;
      final profile = profileById[representative.profileId];
      final name = profile != null && profile.displayName.isNotEmpty
          ? profile.displayName
          : representative.label;

      double avg(Iterable<double> values) {
        final list = values.toList(growable: false);
        if (list.isEmpty) return 0;
        return list.reduce((a, b) => a + b) / list.length;
      }

      double? avgNullable(Iterable<double?> values) {
        final list = values.whereType<double>().toList(growable: false);
        return list.isEmpty ? null : avg(list);
      }

      final chronological = [...group]
        ..sort((a, b) => a.endedAt.compareTo(b.endedAt));
      double? overallTrend;
      double? stressTrend;
      if (chronological.length >= 4) {
        final previous = chronological
            .take(chronological.length - 2)
            .toList(growable: false);
        final latest = chronological
            .skip(chronological.length - 2)
            .toList(growable: false);

        final previousOverall = avgNullable(
          previous.map((test) => analyze(test, reliable).overallScore),
        );
        final latestOverall = avgNullable(
          latest.map((test) => analyze(test, reliable).overallScore),
        );
        if (previousOverall != null && latestOverall != null) {
          overallTrend = latestOverall - previousOverall;
        }

        final previousStress = previous
            .where((test) => test.stressAvailable)
            .map((test) => test.stressScore)
            .toList(growable: false);
        final latestStress = latest
            .where((test) => test.stressAvailable)
            .map((test) => test.stressScore)
            .toList(growable: false);
        if (previousStress.isNotEmpty && latestStress.isNotEmpty) {
          stressTrend = avg(latestStress) - avg(previousStress);
        }
      }

      entries.add(
        ChargingSetupRankingEntry(
          setupId: key,
          name: name,
          tests: group.length,
          averagePowerW: avg(group.map((test) => test.averagePowerW)),
          speedScore: avgNullable(analyses.map((item) => item.speedScore)),
          stabilityScore:
              avgNullable(analyses.map((item) => item.stabilityScore)),
          thermalScore: avgNullable(analyses.map((item) => item.thermalScore)),
          overallScore: avgNullable(analyses.map((item) => item.overallScore)),
          averageStressScore: avg(
            group.where((test) => test.stressAvailable).map(
                  (test) => test.stressScore,
                ),
          ),
          overallTrendDelta: overallTrend,
          stressTrendDelta: stressTrend,
        ),
      );
    }

    entries.sort((a, b) {
      final left = a.overallScore ?? -1;
      final right = b.overallScore ?? -1;
      return right.compareTo(left);
    });
    return List.unmodifiable(entries);
  }

  static String setupKeyFor(ChargeTest test) => _setupKey(test);

  static bool _sameSetup(ChargeTest a, ChargeTest b) =>
      _setupKey(a) == _setupKey(b);

  static String _setupKey(ChargeTest test) {
    final profileId = test.profileId.trim();
    if (profileId.isNotEmpty) return 'profile:$profileId';
    return 'legacy:${chargeTestGroupKey(label: test.label, source: test.source)}';
  }

  static double? _stabilityScore(ChargeTest test) {
    if (test.samples < 4 || test.averagePowerW <= 0) return null;
    final cvPenalty =
        (test.powerCoefficientOfVariation.clamp(0, 0.50) / 0.50) * 65;
    final dropPenalty = math.min(30.0, test.powerDropCount * 8.0);
    return (100 - cvPenalty - dropPenalty).clamp(0, 100).toDouble();
  }

  static double? _thermalScore(ChargeTest test) {
    if (!test.temperatureAvailable || test.maxTemperatureC <= 0) return null;

    var score = 100.0;
    final maxTemp = test.maxTemperatureC;
    if (maxTemp > 35) score -= (maxTemp - 35) * 4.0;
    if (maxTemp > 42) score -= (maxTemp - 42) * 5.0;

    final rise = test.temperatureRiseC;
    if (rise > 5) score -= (rise - 5) * 3.5;
    if (rise > 10) score -= (rise - 10) * 3.0;

    return score.clamp(0, 100).toDouble();
  }

  static double? _median(List<double> values) {
    final filtered = values.where((value) => value > 0).toList()..sort();
    if (filtered.isEmpty) return null;
    final mid = filtered.length ~/ 2;
    if (filtered.length.isOdd) return filtered[mid];
    return (filtered[mid - 1] + filtered[mid]) / 2;
  }
}
