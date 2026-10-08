import 'dart:math' as math;

import '../models/battery_intelligence.dart';
import '../models/battery_snapshot.dart';
import '../models/charging_curve_point.dart';
import '../models/charging_session.dart';

class BatteryIntelligenceEngine {
  const BatteryIntelligenceEngine._();

  static BatteryEtaEstimate standardEta({
    required BatterySnapshot snapshot,
    required ChargingSession? currentSession,
    required int targetLevel,
  }) {
    if (!snapshot.isPlugged || !snapshot.isCharging) {
      return const BatteryEtaEstimate.unavailable();
    }
    final remaining = targetLevel - snapshot.level;
    if (remaining <= 0) {
      return const BatteryEtaEstimate(
        kind: EtaKind.standard,
        minutes: 0,
        confidence: 'high',
        historySamples: 0,
        screenContextUsed: false,
      );
    }

    final nativeMinutes = currentSession?.estimatedMinutesToTarget;
    if (nativeMinutes != null && nativeMinutes > 0) {
      final gained = currentSession?.gainedPercent ?? 0;
      return BatteryEtaEstimate(
        kind: EtaKind.standard,
        minutes: nativeMinutes.clamp(1, 24 * 60),
        confidence: gained >= 5 ? 'medium' : 'low',
        historySamples: 0,
        screenContextUsed: false,
      );
    }

    final rate = currentSession?.percentPerHour ?? 0;
    if (rate <= 0 || rate > 300) {
      return const BatteryEtaEstimate.unavailable();
    }
    return BatteryEtaEstimate(
      kind: EtaKind.standard,
      minutes: ((remaining / rate) * 60).round().clamp(1, 24 * 60),
      confidence: (currentSession?.gainedPercent ?? 0) >= 3 ? 'medium' : 'low',
      historySamples: 0,
      screenContextUsed: false,
    );
  }

  static BatteryEtaEstimate smartEta({
    required BatterySnapshot snapshot,
    required ChargingSession? currentSession,
    required List<ChargingSession> history,
    required int targetLevel,
  }) {
    final standard = standardEta(
      snapshot: snapshot,
      currentSession: currentSession,
      targetLevel: targetLevel,
    );
    if (!snapshot.isPlugged || !snapshot.isCharging || targetLevel <= snapshot.level) {
      return standard.available
          ? BatteryEtaEstimate(
              kind: EtaKind.smart,
              minutes: standard.minutes,
              confidence: standard.confidence,
              historySamples: 0,
              screenContextUsed: false,
            )
          : const BatteryEtaEstimate.unavailable();
    }

    final estimates = <double>[];
    var historicalSamples = 0;
    final sameSource = history.where(
      (session) =>
          session.trustedForInsights &&
          session.hasCurve &&
          session.plugType == snapshot.plugType,
    );

    for (final session in sameSource.take(20)) {
      final minutes = _historicalMinutes(
        session.curvePoints,
        fromLevel: snapshot.level,
        targetLevel: targetLevel,
      );
      if (minutes != null) {
        estimates.add(minutes.toDouble());
        historicalSamples++;
      }
    }

    var usedScreenContext = false;
    if (snapshot.screenStateAvailable) {
      final screenRate = _screenContextRate(
        sameSource.expand((session) => session.curvePoints),
        screenInteractive: snapshot.screenInteractive,
      );
      if (screenRate != null && screenRate > 0) {
        estimates.add(((targetLevel - snapshot.level) / screenRate) * 60);
        usedScreenContext = true;
      }
    }

    if (standard.available) {
      // Current-session behavior is useful but intentionally counts as a
      // single observation so history/taper cannot be overwhelmed by it.
      estimates.add(standard.minutes.toDouble());
    }

    final sane = estimates
        .where((value) => value.isFinite && value >= 1 && value <= 24 * 60)
        .toList(growable: false)
      ..sort();
    if (sane.isEmpty) return standard;

    final median = _median(sane);
    final evidenceCount = historicalSamples + (usedScreenContext ? 1 : 0);
    final confidence = evidenceCount >= 4
        ? 'high'
        : evidenceCount >= 2
            ? 'medium'
            : 'low';

    return BatteryEtaEstimate(
      kind: EtaKind.smart,
      minutes: median.round().clamp(1, 24 * 60),
      confidence: confidence,
      historySamples: historicalSamples,
      screenContextUsed: usedScreenContext,
    );
  }

  static int? _historicalMinutes(
    List<ChargingCurvePoint> points, {
    required int fromLevel,
    required int targetLevel,
  }) {
    final eligible = points
        .where((point) => point.isPlugged && point.isCharging)
        .toList(growable: false);
    if (eligible.length < 2) return null;

    ChargingCurvePoint? start;
    ChargingCurvePoint? end;
    for (final point in eligible) {
      if (start == null && point.level >= fromLevel) {
        start = point;
      }
      if (start != null && point.level >= targetLevel) {
        end = point;
        break;
      }
    }
    if (start == null || end == null || !end.timestamp.isAfter(start.timestamp)) {
      return null;
    }
    final minutes = end.timestamp.difference(start.timestamp).inMinutes;
    return minutes >= 1 && minutes <= 24 * 60 ? minutes : null;
  }

  static double? _screenContextRate(
    Iterable<ChargingCurvePoint> points, {
    required bool screenInteractive,
  }) {
    final sorted = points.toList(growable: false)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    var elapsedHours = 0.0;
    var gained = 0.0;

    for (var i = 1; i < sorted.length; i++) {
      final previous = sorted[i - 1];
      final current = sorted[i];
      if (previous.screenInteractive != screenInteractive ||
          current.screenInteractive != screenInteractive ||
          !previous.isCharging ||
          !current.isCharging ||
          !previous.isPlugged ||
          !current.isPlugged) {
        continue;
      }
      final seconds = current.timestamp.difference(previous.timestamp).inSeconds;
      if (seconds < 30 || seconds > 10 * 60) continue;
      final delta = current.level - previous.level;
      if (delta < 0 || delta > 3) continue;
      elapsedHours += seconds / 3600.0;
      gained += delta;
    }

    if (elapsedHours < 0.15 || gained < 1) return null;
    final rate = gained / elapsedHours;
    return rate > 0 && rate <= 300 ? rate : null;
  }

  static double _median(List<double> sortedValues) {
    if (sortedValues.isEmpty) return 0;
    final middle = sortedValues.length ~/ 2;
    if (sortedValues.length.isOdd) return sortedValues[middle];
    return (sortedValues[middle - 1] + sortedValues[middle]) / 2;
  }

  static double robustMedian(Iterable<double> values) {
    final sorted = values.where((value) => value.isFinite).toList()..sort();
    return _median(sorted);
  }

  static double clampFinite(double value, double min, double max) {
    if (!value.isFinite) return min;
    return math.max(min, math.min(max, value));
  }
}
