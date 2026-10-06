class BatteryHealthReport {
  const BatteryHealthReport({
    required this.nominalCapacityMah,
    required this.estimatedFullCapacityMah,
    required this.estimatedHealthPercent,
    required this.confidence,
    required this.sampleCount,
    required this.cycleCount,
    required this.trendPercent,
    required this.averageTemperatureC,
    required this.maxTemperatureC,
  });

  factory BatteryHealthReport.fromMap(Map<dynamic, dynamic> map) {
    int i(String key, [int fallback = 0]) =>
        (map[key] as num?)?.round() ?? fallback;
    double d(String key, [double fallback = 0]) =>
        (map[key] as num?)?.toDouble() ?? fallback;
    String s(String key, [String fallback = 'low']) =>
        map[key]?.toString() ?? fallback;

    return BatteryHealthReport(
      nominalCapacityMah: i('nominalCapacityMah'),
      estimatedFullCapacityMah: d('estimatedFullCapacityMah'),
      estimatedHealthPercent: d('estimatedHealthPercent'),
      confidence: s('confidence'),
      sampleCount: i('sampleCount'),
      cycleCount: i('cycleCount', -1),
      trendPercent: d('trendPercent'),
      averageTemperatureC: d('averageTemperatureC'),
      maxTemperatureC: d('maxTemperatureC'),
    );
  }

  static const empty = BatteryHealthReport(
    nominalCapacityMah: 0,
    estimatedFullCapacityMah: 0,
    estimatedHealthPercent: 0,
    confidence: 'low',
    sampleCount: 0,
    cycleCount: -1,
    trendPercent: 0,
    averageTemperatureC: 0,
    maxTemperatureC: 0,
  );

  final int nominalCapacityMah;
  final double estimatedFullCapacityMah;
  final double estimatedHealthPercent;
  final String confidence;
  final int sampleCount;
  final int cycleCount;
  final double trendPercent;
  final double averageTemperatureC;
  final double maxTemperatureC;

  bool get hasEstimate =>
      nominalCapacityMah > 0 && estimatedFullCapacityMah > 0;
  bool get hasCycleCount => cycleCount >= 0;
  bool get hasThermalData => averageTemperatureC > 0;
}
