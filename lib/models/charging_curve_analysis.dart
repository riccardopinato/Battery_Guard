import 'charging_curve_point.dart';

enum ChargingPhase {
  rampUp,
  fast,
  steady,
  plateau,
  thermalThrottle,
  taper,
  chargeLimit,
  full,
}

class ChargingCurveSegment {
  const ChargingCurveSegment({
    required this.phase,
    required this.startedAt,
    required this.endedAt,
  });

  final ChargingPhase phase;
  final DateTime startedAt;
  final DateTime endedAt;
}

class ChargingCurveAnalysis {
  const ChargingCurveAnalysis({
    required this.segments,
    required this.peakPowerW,
    required this.averagePowerW,
    required this.temperatureRiseC,
  });

  factory ChargingCurveAnalysis.fromPoints(
    List<ChargingCurvePoint> points,
  ) {
    if (points.length < 2) {
      return const ChargingCurveAnalysis(
        segments: [],
        peakPowerW: null,
        averagePowerW: null,
        temperatureRiseC: null,
      );
    }

    final powers = points
        .map((point) => point.powerW)
        .whereType<double>()
        .where((value) => value >= 0)
        .toList(growable: false);
    final peak = powers.isEmpty
        ? null
        : powers.reduce((left, right) => left > right ? left : right);
    final average = powers.isEmpty
        ? null
        : powers.reduce((left, right) => left + right) / powers.length;

    final temperatures = points
        .map((point) => point.temperatureC)
        .whereType<double>()
        .toList(growable: false);
    final temperatureRise = temperatures.length < 2
        ? null
        : temperatures.last - temperatures.first;

    final raw = <ChargingCurveSegment>[];
    for (var index = 1; index < points.length; index++) {
      final previous = points[index - 1];
      final current = points[index];
      final phase = _phaseFor(
        previous: previous,
        current: current,
        peakPowerW: peak,
        sessionStart: points.first.timestamp,
      );

      if (raw.isNotEmpty && raw.last.phase == phase) {
        final last = raw.removeLast();
        raw.add(
          ChargingCurveSegment(
            phase: phase,
            startedAt: last.startedAt,
            endedAt: current.timestamp,
          ),
        );
      } else {
        raw.add(
          ChargingCurveSegment(
            phase: phase,
            startedAt: previous.timestamp,
            endedAt: current.timestamp,
          ),
        );
      }
    }

    return ChargingCurveAnalysis(
      segments: List.unmodifiable(raw),
      peakPowerW: peak,
      averagePowerW: average,
      temperatureRiseC: temperatureRise,
    );
  }

  final List<ChargingCurveSegment> segments;
  final double? peakPowerW;
  final double? averagePowerW;
  final double? temperatureRiseC;

  bool get detectedThermalThrottle =>
      segments.any((segment) => segment.phase == ChargingPhase.thermalThrottle);

  bool get detectedTaper =>
      segments.any((segment) => segment.phase == ChargingPhase.taper);

  bool get detectedChargeLimit =>
      segments.any((segment) => segment.phase == ChargingPhase.chargeLimit);

  static ChargingPhase _phaseFor({
    required ChargingCurvePoint previous,
    required ChargingCurvePoint current,
    required double? peakPowerW,
    required DateTime sessionStart,
  }) {
    if (!current.isCharging) {
      return current.level >= 99
          ? ChargingPhase.full
          : ChargingPhase.chargeLimit;
    }

    final power = current.powerW;
    final previousPower = previous.powerW;
    final peak = peakPowerW;

    if (power == null || previousPower == null || peak == null || peak <= 0) {
      return ChargingPhase.steady;
    }

    final elapsed = current.timestamp.difference(sessionStart);
    if (elapsed <= const Duration(minutes: 3) && power > previousPower * 1.12) {
      return ChargingPhase.rampUp;
    }

    final temperature = current.temperatureC;
    if (temperature != null &&
        temperature >= 40 &&
        power <= peak * 0.68 &&
        previousPower > power * 1.12) {
      return ChargingPhase.thermalThrottle;
    }

    if (current.level >= 80 && power <= peak * 0.65) {
      return ChargingPhase.taper;
    }

    if (power >= peak * 0.82) {
      return ChargingPhase.fast;
    }

    if ((power - previousPower).abs() <= peak * 0.08) {
      return ChargingPhase.plateau;
    }

    return ChargingPhase.steady;
  }
}
