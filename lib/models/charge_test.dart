enum ChargeTestConfidence { low, medium, high }

class ChargeTest {
  const ChargeTest({
    required this.id,
    required this.profileId,
    required this.label,
    required this.chargerName,
    required this.cableName,
    required this.startedAt,
    required this.endedAt,
    required this.startLevel,
    required this.endLevel,
    required this.averagePowerW,
    required this.peakPowerW,
    required this.averageCurrentMa,
    required this.averageVoltageV,
    required this.startTemperatureC,
    required this.averageTemperatureC,
    required this.maxTemperatureC,
    required this.temperatureAvailable,
    required this.samples,
    required this.source,
    required this.confidence,
    required this.powerCoefficientOfVariation,
    required this.powerDropCount,
    required this.stressScore,
    required this.highSocMinutes,
    required this.hotMinutes,
    required this.veryHotMinutes,
    required this.highVoltageMinutes,
  });

  factory ChargeTest.fromMap(Map<dynamic, dynamic> map) {
    int i(String key, [int fallback = 0]) =>
        (map[key] as num?)?.round() ?? fallback;
    double d(String key, [double fallback = 0]) =>
        (map[key] as num?)?.toDouble() ?? fallback;
    String s(String key, [String fallback = '']) =>
        map[key]?.toString() ?? fallback;
    bool b(String key, [bool fallback = false]) =>
        map[key] is bool ? map[key] as bool : fallback;

    final startTemp = d('startTemperatureC');
    final maxTemp = d('maxTemperatureC');
    return ChargeTest(
      id: s('id'),
      profileId: s('profileId'),
      label: s('label', 'Charge Test'),
      chargerName: s('chargerName'),
      cableName: s('cableName'),
      startedAt: DateTime.fromMillisecondsSinceEpoch(i('startedAt')),
      endedAt: DateTime.fromMillisecondsSinceEpoch(i('endedAt')),
      startLevel: i('startLevel').clamp(0, 100).toInt(),
      endLevel: i('endLevel').clamp(0, 100).toInt(),
      averagePowerW: d('averagePowerW'),
      peakPowerW: d('peakPowerW', d('averagePowerW')),
      averageCurrentMa: d('averageCurrentMa'),
      averageVoltageV: d('averageVoltageV'),
      startTemperatureC: startTemp,
      averageTemperatureC: d(
        'averageTemperatureC',
        startTemp > 0 && maxTemp > 0 ? (startTemp + maxTemp) / 2 : 0,
      ),
      maxTemperatureC: maxTemp,
      temperatureAvailable:
          b('temperatureAvailable', startTemp > 0 || maxTemp > 0),
      samples: i('samples'),
      source: s('source', 'unknown'),
      confidence: ChargeTestConfidence.values.firstWhere(
        (value) => value.name == s('confidence'),
        orElse: () => ChargeTestConfidence.low,
      ),
      powerCoefficientOfVariation: d('powerCoefficientOfVariation'),
      powerDropCount: i('powerDropCount'),
      stressScore: d('stressScore'),
      highSocMinutes: d('highSocMinutes'),
      hotMinutes: d('hotMinutes'),
      veryHotMinutes: d('veryHotMinutes'),
      highVoltageMinutes: d('highVoltageMinutes'),
    );
  }

  Map<String, Object> toMap() => {
        'id': id,
        'profileId': profileId,
        'label': label,
        'chargerName': chargerName,
        'cableName': cableName,
        'startedAt': startedAt.millisecondsSinceEpoch,
        'endedAt': endedAt.millisecondsSinceEpoch,
        'startLevel': startLevel,
        'endLevel': endLevel,
        'averagePowerW': averagePowerW,
        'peakPowerW': peakPowerW,
        'averageCurrentMa': averageCurrentMa,
        'averageVoltageV': averageVoltageV,
        'startTemperatureC': startTemperatureC,
        'averageTemperatureC': averageTemperatureC,
        'maxTemperatureC': maxTemperatureC,
        'temperatureAvailable': temperatureAvailable,
        'samples': samples,
        'source': source,
        'confidence': confidence.name,
        'powerCoefficientOfVariation': powerCoefficientOfVariation,
        'powerDropCount': powerDropCount,
        'stressScore': stressScore,
        'highSocMinutes': highSocMinutes,
        'hotMinutes': hotMinutes,
        'veryHotMinutes': veryHotMinutes,
        'highVoltageMinutes': highVoltageMinutes,
      };

  final String id;
  final String profileId;
  final String label;
  final String chargerName;
  final String cableName;
  final DateTime startedAt;
  final DateTime endedAt;
  final int startLevel;
  final int endLevel;
  final double averagePowerW;
  final double peakPowerW;
  final double averageCurrentMa;
  final double averageVoltageV;
  final double startTemperatureC;
  final double averageTemperatureC;
  final double maxTemperatureC;
  final bool temperatureAvailable;
  final int samples;
  final String source;
  final ChargeTestConfidence confidence;
  final double powerCoefficientOfVariation;
  final int powerDropCount;
  final double stressScore;
  final double highSocMinutes;
  final double hotMinutes;
  final double veryHotMinutes;
  final double highVoltageMinutes;

  Duration get duration => endedAt.difference(startedAt);
  double get temperatureRiseC =>
      temperatureAvailable ? maxTemperatureC - startTemperatureC : 0;

  bool get reliable =>
      confidence == ChargeTestConfidence.medium ||
      confidence == ChargeTestConfidence.high;
}

class ChargeTestObservation {
  const ChargeTestObservation({
    required this.timestamp,
    required this.level,
    this.powerW,
    this.currentMa,
    this.voltageV,
    this.temperatureC,
  });

  final DateTime timestamp;
  final int level;
  final double? powerW;
  final double? currentMa;
  final double? voltageV;
  final double? temperatureC;
}

class ActiveChargeTest {
  ActiveChargeTest({
    required this.profileId,
    required this.label,
    required this.chargerName,
    required this.cableName,
    required this.startedAt,
    required this.startLevel,
    required this.startTemperatureC,
    required this.source,
  });

  final String profileId;
  final String label;
  final String chargerName;
  final String cableName;
  final DateTime startedAt;
  final int startLevel;
  final double startTemperatureC;
  final String source;
  final List<double> powers = [];
  final List<double> currents = [];
  final List<double> voltages = [];
  final List<double> temperatures = [];
  final List<ChargeTestObservation> observations = [];

  int get samples => observations.length;

  double average(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  double peak(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a > b ? a : b);
  }

  double coefficientOfVariation(List<double> values) {
    if (values.length < 2) return 0;
    final mean = average(values);
    if (mean <= 0) return 0;
    var squared = 0.0;
    for (final value in values) {
      final delta = value - mean;
      squared += delta * delta;
    }
    final variance = squared / values.length;
    return variance.sqrtApprox() / mean;
  }

  int powerDropCount() {
    if (powers.length < 2) return 0;
    var drops = 0;
    for (var index = 1; index < powers.length; index++) {
      final previous = powers[index - 1];
      final current = powers[index];
      if (previous >= 2 && current <= previous * 0.70) drops++;
    }
    return drops;
  }
}

extension _SqrtApprox on double {
  double sqrtApprox() {
    if (this <= 0) return 0;
    var estimate = this;
    for (var index = 0; index < 8; index++) {
      estimate = (estimate + this / estimate) / 2;
    }
    return estimate;
  }
}
