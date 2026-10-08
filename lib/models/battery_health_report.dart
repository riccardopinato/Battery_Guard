class BatteryHealthTrendPoint {
  const BatteryHealthTrendPoint({
    required this.at,
    required this.rawCapacityMah,
    required this.smoothedCapacityMah,
    required this.smoothedHealthPercent,
  });

  factory BatteryHealthTrendPoint.fromMap(Map<dynamic, dynamic> map) {
    num n(String key, [num fallback = 0]) =>
        map[key] is num ? map[key] as num : fallback;
    return BatteryHealthTrendPoint(
      at: DateTime.fromMillisecondsSinceEpoch(n('at').round()),
      rawCapacityMah: n('rawCapacityMah').toDouble(),
      smoothedCapacityMah: n('smoothedCapacityMah').toDouble(),
      smoothedHealthPercent: n('smoothedHealthPercent').toDouble(),
    );
  }

  final DateTime at;
  final double rawCapacityMah;
  final double smoothedCapacityMah;
  final double smoothedHealthPercent;
}

class BatteryHealthOutlier {
  const BatteryHealthOutlier({
    required this.at,
    required this.level,
    required this.estimateMah,
    required this.deviationPercent,
  });

  factory BatteryHealthOutlier.fromMap(Map<dynamic, dynamic> map) {
    num n(String key, [num fallback = 0]) =>
        map[key] is num ? map[key] as num : fallback;
    return BatteryHealthOutlier(
      at: DateTime.fromMillisecondsSinceEpoch(n('at').round()),
      level: n('level').round().clamp(0, 100),
      estimateMah: n('estimateMah').toDouble(),
      deviationPercent: n('deviationPercent').toDouble(),
    );
  }

  final DateTime at;
  final int level;
  final double estimateMah;
  final double deviationPercent;
}

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
    this.estimatorVersion = 'legacy',
    this.reportedHealthStatus = '',
    this.reportedHealthAvailable = false,
    this.reportedHealthObservedAt,
    this.confidenceScore = 0,
    this.totalSampleCount = 0,
    this.outlierCount = 0,
    this.socSpread = 0,
    this.dispersionPercent = 0,
    this.uncertaintyPercent = 0,
    this.trendDirection = 'insufficient',
    this.trendPoints = const [],
    this.outliers = const [],
  });

  factory BatteryHealthReport.fromMap(Map<dynamic, dynamic> map) {
    int i(String key, [int fallback = 0]) =>
        (map[key] as num?)?.round() ?? fallback;
    double d(String key, [double fallback = 0]) =>
        (map[key] as num?)?.toDouble() ?? fallback;
    String s(String key, [String fallback = 'low']) =>
        map[key]?.toString() ?? fallback;

    final rawTrend = map['trendPoints'];
    final trendPoints = <BatteryHealthTrendPoint>[];
    if (rawTrend is Iterable) {
      for (final value in rawTrend) {
        if (value is Map) {
          trendPoints.add(BatteryHealthTrendPoint.fromMap(value));
        }
      }
    }
    final rawOutliers = map['outliers'];
    final outliers = <BatteryHealthOutlier>[];
    if (rawOutliers is Iterable) {
      for (final value in rawOutliers) {
        if (value is Map) {
          outliers.add(BatteryHealthOutlier.fromMap(value));
        }
      }
    }
    final reportedAt = i('reportedHealthObservedAt');

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
      estimatorVersion: s('estimatorVersion', 'legacy'),
      reportedHealthStatus: s('reportedHealthStatus', ''),
      reportedHealthAvailable: map['reportedHealthAvailable'] == true,
      reportedHealthObservedAt: reportedAt > 0
          ? DateTime.fromMillisecondsSinceEpoch(reportedAt)
          : null,
      confidenceScore: d('confidenceScore'),
      totalSampleCount: i('totalSampleCount', i('sampleCount')),
      outlierCount: i('outlierCount'),
      socSpread: i('socSpread'),
      dispersionPercent: d('dispersionPercent'),
      uncertaintyPercent: d('uncertaintyPercent'),
      trendDirection: s('trendDirection', 'insufficient'),
      trendPoints: List.unmodifiable(trendPoints),
      outliers: List.unmodifiable(outliers),
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
  final String estimatorVersion;
  final String reportedHealthStatus;
  final bool reportedHealthAvailable;
  final DateTime? reportedHealthObservedAt;
  final double confidenceScore;
  final int totalSampleCount;
  final int outlierCount;
  final int socSpread;
  final double dispersionPercent;
  final double uncertaintyPercent;
  final String trendDirection;
  final List<BatteryHealthTrendPoint> trendPoints;
  final List<BatteryHealthOutlier> outliers;

  bool get hasEstimate =>
      nominalCapacityMah > 0 && estimatedFullCapacityMah > 0;
  bool get hasCycleCount => cycleCount >= 0;
  bool get hasThermalData => averageTemperatureC > 0;
  bool get hasTrend => trendPoints.length >= 8;

  BatteryHealthReport withNominalCapacity(int value) {
    final health = value > 0 && estimatedFullCapacityMah > 0
        ? (estimatedFullCapacityMah / value * 100).clamp(0, 100).toDouble()
        : 0.0;
    return BatteryHealthReport(
      nominalCapacityMah: value,
      estimatedFullCapacityMah: estimatedFullCapacityMah,
      estimatedHealthPercent: health,
      confidence: confidence,
      sampleCount: sampleCount,
      cycleCount: cycleCount,
      trendPercent: trendPercent,
      averageTemperatureC: averageTemperatureC,
      maxTemperatureC: maxTemperatureC,
      estimatorVersion: estimatorVersion,
      reportedHealthStatus: reportedHealthStatus,
      reportedHealthAvailable: reportedHealthAvailable,
      reportedHealthObservedAt: reportedHealthObservedAt,
      confidenceScore: confidenceScore,
      totalSampleCount: totalSampleCount,
      outlierCount: outlierCount,
      socSpread: socSpread,
      dispersionPercent: dispersionPercent,
      uncertaintyPercent: uncertaintyPercent,
      trendDirection: trendDirection,
      trendPoints: trendPoints,
      outliers: outliers,
    );
  }
}
