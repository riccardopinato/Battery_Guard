enum ChargeTestConfidence { low, medium, high }

class ChargeTest {
  const ChargeTest({
    required this.id,
    required this.label,
    required this.startedAt,
    required this.endedAt,
    required this.startLevel,
    required this.endLevel,
    required this.averagePowerW,
    required this.averageCurrentMa,
    required this.averageVoltageV,
    required this.startTemperatureC,
    required this.maxTemperatureC,
    required this.samples,
    required this.source,
    required this.confidence,
  });

  factory ChargeTest.fromMap(Map<dynamic, dynamic> map) {
    int i(String key, [int fallback = 0]) =>
        (map[key] as num?)?.round() ?? fallback;
    double d(String key, [double fallback = 0]) =>
        (map[key] as num?)?.toDouble() ?? fallback;
    String s(String key, [String fallback = '']) =>
        map[key]?.toString() ?? fallback;

    return ChargeTest(
      id: s('id'),
      label: s('label', 'Charge Test'),
      startedAt: DateTime.fromMillisecondsSinceEpoch(i('startedAt')),
      endedAt: DateTime.fromMillisecondsSinceEpoch(i('endedAt')),
      startLevel: i('startLevel').clamp(0, 100),
      endLevel: i('endLevel').clamp(0, 100),
      averagePowerW: d('averagePowerW'),
      averageCurrentMa: d('averageCurrentMa'),
      averageVoltageV: d('averageVoltageV'),
      startTemperatureC: d('startTemperatureC'),
      maxTemperatureC: d('maxTemperatureC'),
      samples: i('samples'),
      source: s('source', 'unknown'),
      confidence: ChargeTestConfidence.values.firstWhere(
        (value) => value.name == s('confidence'),
        orElse: () => ChargeTestConfidence.low,
      ),
    );
  }

  Map<String, Object> toMap() => {
        'id': id,
        'label': label,
        'startedAt': startedAt.millisecondsSinceEpoch,
        'endedAt': endedAt.millisecondsSinceEpoch,
        'startLevel': startLevel,
        'endLevel': endLevel,
        'averagePowerW': averagePowerW,
        'averageCurrentMa': averageCurrentMa,
        'averageVoltageV': averageVoltageV,
        'startTemperatureC': startTemperatureC,
        'maxTemperatureC': maxTemperatureC,
        'samples': samples,
        'source': source,
        'confidence': confidence.name,
      };

  final String id;
  final String label;
  final DateTime startedAt;
  final DateTime endedAt;
  final int startLevel;
  final int endLevel;
  final double averagePowerW;
  final double averageCurrentMa;
  final double averageVoltageV;
  final double startTemperatureC;
  final double maxTemperatureC;
  final int samples;
  final String source;
  final ChargeTestConfidence confidence;

  Duration get duration => endedAt.difference(startedAt);
  double get temperatureRiseC => maxTemperatureC - startTemperatureC;

  bool get reliable =>
      confidence == ChargeTestConfidence.medium ||
      confidence == ChargeTestConfidence.high;
}

class ActiveChargeTest {
  ActiveChargeTest({
    required this.label,
    required this.startedAt,
    required this.startLevel,
    required this.startTemperatureC,
    required this.source,
  });

  final String label;
  final DateTime startedAt;
  final int startLevel;
  final double startTemperatureC;
  final String source;
  final List<double> powers = [];
  final List<double> currents = [];
  final List<double> voltages = [];
  final List<double> temperatures = [];

  int get samples => powers.length;

  double average(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }
}
