import 'charging_curve_point.dart';
import 'charging_session.dart';

enum BatteryStressLevel {
  low,
  moderate,
  high,
  veryHigh,
}

class BatteryStressSample {
  const BatteryStressSample({
    required this.timestamp,
    required this.level,
    this.temperatureC,
    this.voltageV,
    this.powerW,
  });

  final DateTime timestamp;
  final int level;
  final double? temperatureC;
  final double? voltageV;
  final double? powerW;
}

class BatteryStressAnalysis {
  const BatteryStressAnalysis({
    required this.score,
    required this.level,
    required this.highSocMinutes,
    required this.hotMinutes,
    required this.veryHotMinutes,
    required this.highVoltageMinutes,
    required this.highPowerHeatMinutes,
    required this.maxTemperatureC,
    required this.reasons,
    required this.dataSufficient,
  });

  factory BatteryStressAnalysis.unavailable() => const BatteryStressAnalysis(
        score: 0,
        level: BatteryStressLevel.low,
        highSocMinutes: 0,
        hotMinutes: 0,
        veryHotMinutes: 0,
        highVoltageMinutes: 0,
        highPowerHeatMinutes: 0,
        maxTemperatureC: null,
        reasons: [],
        dataSufficient: false,
      );

  factory BatteryStressAnalysis.fromSession(ChargingSession session) {
    if (session.curvePoints.length < 2) {
      return BatteryStressAnalysis.unavailable();
    }
    return BatteryStressAnalysis.fromCurve(session.curvePoints);
  }

  factory BatteryStressAnalysis.fromCurve(List<ChargingCurvePoint> points) {
    return BatteryStressAnalysis.fromSamples(
      [
        for (final point in points)
          BatteryStressSample(
            timestamp: point.timestamp,
            level: point.level,
            temperatureC: point.temperatureC,
            voltageV: point.voltageV,
            powerW: point.powerW,
          ),
      ],
    );
  }

  factory BatteryStressAnalysis.fromSamples(List<BatteryStressSample> samples) {
    if (samples.length < 2) return BatteryStressAnalysis.unavailable();

    final points = [...samples]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    var highSocSeconds = 0.0;
    var hotSeconds = 0.0;
    var veryHotSeconds = 0.0;
    var highVoltageSeconds = 0.0;
    var highPowerHeatSeconds = 0.0;
    double? maxTemperature;

    final availablePowers = points
        .map((point) => point.powerW)
        .whereType<double>()
        .where((value) => value > 0)
        .toList(growable: false);
    final peakPower = availablePowers.isEmpty
        ? null
        : availablePowers.reduce(
            (left, right) => left > right ? left : right,
          );

    for (var index = 1; index < points.length; index++) {
      final previous = points[index - 1];
      final current = points[index];
      final seconds = current.timestamp
              .difference(previous.timestamp)
              .inMilliseconds
              .clamp(0, const Duration(minutes: 10).inMilliseconds) /
          1000.0;

      final avgSoc = (previous.level + current.level) / 2.0;
      if (avgSoc >= 80) highSocSeconds += seconds;

      final temperatures = [
        previous.temperatureC,
        current.temperatureC,
      ].whereType<double>().toList(growable: false);
      double? intervalTemperature;
      if (temperatures.isNotEmpty) {
        final temp =
            temperatures.reduce((left, right) => left > right ? left : right);
        intervalTemperature = temp;
        maxTemperature =
            maxTemperature == null || temp > maxTemperature ? temp : maxTemperature;
        if (temp >= 38) hotSeconds += seconds;
        if (temp >= 42) veryHotSeconds += seconds;
      }

      if (peakPower != null && peakPower > 0 && intervalTemperature != null) {
        final powers = [
          previous.powerW,
          current.powerW,
        ].whereType<double>().where((value) => value >= 0).toList(growable: false);
        if (powers.isNotEmpty) {
          final intervalPower =
              powers.reduce((left, right) => left > right ? left : right);
          if (intervalPower >= peakPower * 0.80 && intervalTemperature >= 38) {
            highPowerHeatSeconds += seconds;
          }
        }
      }

      final voltages = [
        previous.voltageV,
        current.voltageV,
      ].whereType<double>().toList(growable: false);
      if (voltages.isNotEmpty) {
        final voltage =
            voltages.reduce((left, right) => left > right ? left : right);
        if (voltage >= 4.20) highVoltageSeconds += seconds;
      }
    }

    final highSocMinutes = highSocSeconds / 60.0;
    final hotMinutes = hotSeconds / 60.0;
    final veryHotMinutes = veryHotSeconds / 60.0;
    final highVoltageMinutes = highVoltageSeconds / 60.0;
    final highPowerHeatMinutes = highPowerHeatSeconds / 60.0;

    var score = 0.0;
    score += (highSocMinutes * 0.8).clamp(0, 28).toDouble();
    score += (hotMinutes * 1.8).clamp(0, 32).toDouble();
    score += (veryHotMinutes * 3.0).clamp(0, 24).toDouble();
    score += (highVoltageMinutes * 0.7).clamp(0, 14).toDouble();
    score += (highPowerHeatMinutes * 1.0).clamp(0, 12).toDouble();

    if (maxTemperature != null) {
      if (maxTemperature >= 45) {
        score += 18;
      } else if (maxTemperature >= 42) {
        score += 10;
      } else if (maxTemperature >= 40) {
        score += 5;
      }
    }

    final bounded = score.clamp(0, 100).toDouble();
    final reasons = <String>[];
    if (highSocMinutes >= 20) reasons.add('HIGH_SOC_EXPOSURE');
    if (hotMinutes >= 10) reasons.add('HEAT_EXPOSURE');
    if (veryHotMinutes >= 3) reasons.add('VERY_HIGH_TEMPERATURE');
    if (highVoltageMinutes >= 20) reasons.add('HIGH_VOLTAGE_EXPOSURE');
    if (highPowerHeatMinutes >= 5) {
      reasons.add('HIGH_POWER_HEAT_OVERLAP');
    }

    final level = switch (bounded) {
      < 25 => BatteryStressLevel.low,
      < 50 => BatteryStressLevel.moderate,
      < 75 => BatteryStressLevel.high,
      _ => BatteryStressLevel.veryHigh,
    };

    return BatteryStressAnalysis(
      score: bounded,
      level: level,
      highSocMinutes: highSocMinutes,
      hotMinutes: hotMinutes,
      veryHotMinutes: veryHotMinutes,
      highVoltageMinutes: highVoltageMinutes,
      highPowerHeatMinutes: highPowerHeatMinutes,
      maxTemperatureC: maxTemperature,
      reasons: List.unmodifiable(reasons),
      dataSufficient: true,
    );
  }

  final double score;
  final BatteryStressLevel level;
  final double highSocMinutes;
  final double hotMinutes;
  final double veryHotMinutes;
  final double highVoltageMinutes;
  final double highPowerHeatMinutes;
  final double? maxTemperatureC;
  final List<String> reasons;
  final bool dataSufficient;
}
