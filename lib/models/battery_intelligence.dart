enum EtaKind { unavailable, standard, smart }

class BatteryEtaEstimate {
  const BatteryEtaEstimate({
    required this.kind,
    required this.minutes,
    required this.confidence,
    required this.historySamples,
    required this.screenContextUsed,
  });

  const BatteryEtaEstimate.unavailable()
      : kind = EtaKind.unavailable,
        minutes = -1,
        confidence = 'low',
        historySamples = 0,
        screenContextUsed = false;

  final EtaKind kind;
  final int minutes;
  final String confidence;
  final int historySamples;
  final bool screenContextUsed;

  bool get available => minutes >= 0;
}

class IdleDrainSegment {
  const IdleDrainSegment({
    required this.endedAt,
    required this.durationMinutes,
    required this.startLevel,
    required this.endLevel,
    required this.ratePercentPerHour,
    required this.powerSaveMode,
  });

  factory IdleDrainSegment.fromMap(Map<dynamic, dynamic> map) {
    num n(String key, [num fallback = 0]) =>
        map[key] is num ? map[key] as num : fallback;
    return IdleDrainSegment(
      endedAt: DateTime.fromMillisecondsSinceEpoch(n('endedAt').round()),
      durationMinutes: n('durationMinutes').round(),
      startLevel: n('startLevel').round().clamp(0, 100),
      endLevel: n('endLevel').round().clamp(0, 100),
      ratePercentPerHour: n('ratePercentPerHour').toDouble(),
      powerSaveMode: map['powerSaveMode'] == true,
    );
  }

  final DateTime endedAt;
  final int durationMinutes;
  final int startLevel;
  final int endLevel;
  final double ratePercentPerHour;
  final bool powerSaveMode;
}

class IdleDrainReport {
  const IdleDrainReport({
    required this.status,
    required this.confidence,
    required this.segmentCount,
    required this.baselineRatePercentPerHour,
    required this.recentRatePercentPerHour,
    required this.deltaPercent,
    required this.powerSaveMode,
    required this.recentSegments,
  });

  factory IdleDrainReport.fromMap(Map<dynamic, dynamic> map) {
    num n(String key, [num fallback = 0]) =>
        map[key] is num ? map[key] as num : fallback;
    final segments = <IdleDrainSegment>[];
    final raw = map['recentSegments'];
    if (raw is Iterable) {
      for (final item in raw) {
        if (item is Map) segments.add(IdleDrainSegment.fromMap(item));
      }
    }
    return IdleDrainReport(
      status: map['status']?.toString() ?? 'insufficient',
      confidence: map['confidence']?.toString() ?? 'low',
      segmentCount: n('segmentCount').round(),
      baselineRatePercentPerHour:
          n('baselineRatePercentPerHour').toDouble(),
      recentRatePercentPerHour: n('recentRatePercentPerHour').toDouble(),
      deltaPercent: n('deltaPercent').toDouble(),
      powerSaveMode: map['powerSaveMode'] == true,
      recentSegments: List.unmodifiable(segments),
    );
  }

  static const empty = IdleDrainReport(
    status: 'insufficient',
    confidence: 'low',
    segmentCount: 0,
    baselineRatePercentPerHour: 0,
    recentRatePercentPerHour: 0,
    deltaPercent: 0,
    powerSaveMode: false,
    recentSegments: [],
  );

  final String status;
  final String confidence;
  final int segmentCount;
  final double baselineRatePercentPerHour;
  final double recentRatePercentPerHour;
  final double deltaPercent;
  final bool powerSaveMode;
  final List<IdleDrainSegment> recentSegments;

  bool get hasBaseline =>
      segmentCount >= 4 && baselineRatePercentPerHour >= 0;
}
