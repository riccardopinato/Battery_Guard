import 'charging_curve_point.dart';

enum ChargingSessionQuality {
  active,
  completed,
  interrupted,
  uncertain;

  static ChargingSessionQuality parse(Object? value) {
    return ChargingSessionQuality.values.firstWhere(
      (item) => item.name == value?.toString(),
      orElse: () => ChargingSessionQuality.uncertain,
    );
  }
}

enum ChargingSessionValidity {
  active,
  valid,
  partial,
  interrupted,
  excluded,
  uncertain;

  static ChargingSessionValidity parse(
    Object? value, {
    required ChargingSessionQuality legacyQuality,
  }) {
    final parsed = ChargingSessionValidity.values.where(
      (item) => item.name == value?.toString(),
    );
    if (parsed.isNotEmpty) return parsed.first;

    return switch (legacyQuality) {
      ChargingSessionQuality.active => ChargingSessionValidity.active,
      ChargingSessionQuality.completed => ChargingSessionValidity.valid,
      ChargingSessionQuality.interrupted => ChargingSessionValidity.interrupted,
      ChargingSessionQuality.uncertain => ChargingSessionValidity.uncertain,
    };
  }
}

enum ChargingSessionReason {
  tooShort,
  insufficientSocDelta,
  powerDataMissing,
  currentDataMissing,
  temperatureDataMissing,
  userUnplugged,
  systemInterrupted,
  oemChargeLimit,
  monitoringGap,
  invalidTelemetry,
  unknown;

  static ChargingSessionReason parse(Object? value) {
    return switch (value?.toString()) {
      'TOO_SHORT' => ChargingSessionReason.tooShort,
      'INSUFFICIENT_SOC_DELTA' =>
        ChargingSessionReason.insufficientSocDelta,
      'POWER_DATA_MISSING' => ChargingSessionReason.powerDataMissing,
      'CURRENT_DATA_MISSING' => ChargingSessionReason.currentDataMissing,
      'TEMPERATURE_DATA_MISSING' =>
        ChargingSessionReason.temperatureDataMissing,
      'USER_UNPLUGGED' => ChargingSessionReason.userUnplugged,
      'SYSTEM_INTERRUPTED' => ChargingSessionReason.systemInterrupted,
      'OEM_CHARGE_LIMIT' => ChargingSessionReason.oemChargeLimit,
      'MONITORING_GAP' => ChargingSessionReason.monitoringGap,
      'INVALID_TELEMETRY' => ChargingSessionReason.invalidTelemetry,
      _ => ChargingSessionReason.unknown,
    };
  }
}

class ChargingSession {
  const ChargingSession({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.lastObservedAt,
    required this.startLevel,
    required this.currentLevel,
    required this.endLevel,
    required this.startTemperatureC,
    required this.currentTemperatureC,
    required this.maxTemperatureC,
    required this.temperatureAvailable,
    required this.averagePowerW,
    required this.averageCurrentMa,
    required this.percentPerHour,
    required this.estimatedMinutesToTarget,
    required this.plugType,
    required this.targetLevel,
    required this.completed,
    required this.quality,
    required this.validity,
    required this.reasonCodes,
    required this.oemChargeLimitDetected,
    required this.oemChargeLimitLevel,
    required this.curvePoints,
  });

  factory ChargingSession.fromMap(Map<dynamic, dynamic> map) {
    num number(String key, [num fallback = 0]) {
      final value = map[key];
      return value is num ? value : fallback;
    }

    String text(String key, [String fallback = '—']) {
      return map[key]?.toString() ?? fallback;
    }

    final endedAtMs = number('endedAt').round();
    final lastObservedAtMs = number(
      'lastObservedAt',
      endedAtMs > 0 ? endedAtMs : number('startedAt'),
    ).round();
    final estimate = number('estimatedMinutesToTarget', -1).round();
    final quality = ChargingSessionQuality.parse(
      map['quality'] ??
          ((map['completed'] as bool? ?? false) ? 'completed' : 'active'),
    );
    final maxTemperatureC = number('maxTemperatureC').toDouble();

    final rawReasons = map['reasonCodes'];
    final reasons = <ChargingSessionReason>[];
    if (rawReasons is Iterable) {
      for (final value in rawReasons) {
        final reason = ChargingSessionReason.parse(value);
        if (reason != ChargingSessionReason.unknown) reasons.add(reason);
      }
    }

    final rawCurve = map['curvePoints'];
    final curve = <ChargingCurvePoint>[];
    if (rawCurve is Iterable) {
      for (final value in rawCurve) {
        if (value is Map) {
          curve.add(ChargingCurvePoint.fromMap(value));
        }
      }
    }

    return ChargingSession(
      id: text('id', ''),
      startedAt: DateTime.fromMillisecondsSinceEpoch(
        number('startedAt', DateTime.now().millisecondsSinceEpoch).round(),
      ),
      endedAt: endedAtMs > 0
          ? DateTime.fromMillisecondsSinceEpoch(endedAtMs)
          : null,
      lastObservedAt: DateTime.fromMillisecondsSinceEpoch(lastObservedAtMs),
      startLevel: number('startLevel').round().clamp(0, 100),
      currentLevel: number('currentLevel').round().clamp(0, 100),
      endLevel: number('endLevel').round().clamp(0, 100),
      startTemperatureC: number('startTemperatureC').toDouble(),
      currentTemperatureC: number('currentTemperatureC').toDouble(),
      maxTemperatureC: maxTemperatureC,
      temperatureAvailable:
          map['temperatureAvailable'] as bool? ?? maxTemperatureC != 0,
      averagePowerW: number('averagePowerW').toDouble(),
      averageCurrentMa: number('averageCurrentMa').toDouble(),
      percentPerHour: number('percentPerHour').toDouble(),
      estimatedMinutesToTarget: estimate > 0 ? estimate : null,
      plugType: text('plugType', 'Sconosciuto'),
      targetLevel: number('targetLevel', 80).round().clamp(50, 100),
      completed: map['completed'] as bool? ??
          quality == ChargingSessionQuality.completed,
      quality: quality,
      validity: ChargingSessionValidity.parse(
        map['validity'],
        legacyQuality: quality,
      ),
      reasonCodes: List.unmodifiable(reasons),
      oemChargeLimitDetected: map['oemChargeLimitDetected'] == true,
      oemChargeLimitLevel: map['oemChargeLimitLevel'] is num
          ? (map['oemChargeLimitLevel'] as num).round().clamp(0, 100)
          : null,
      curvePoints: List.unmodifiable(curve),
    );
  }

  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final DateTime lastObservedAt;
  final int startLevel;
  final int currentLevel;
  final int endLevel;
  final double startTemperatureC;
  final double currentTemperatureC;
  final double maxTemperatureC;
  final bool temperatureAvailable;
  final double averagePowerW;
  final double averageCurrentMa;
  final double percentPerHour;
  final int? estimatedMinutesToTarget;
  final String plugType;
  final int targetLevel;
  final bool completed;
  final ChargingSessionQuality quality;
  final ChargingSessionValidity validity;
  final List<ChargingSessionReason> reasonCodes;
  final bool oemChargeLimitDetected;
  final int? oemChargeLimitLevel;
  final List<ChargingCurvePoint> curvePoints;

  bool get trustedForInsights =>
      completed && validity == ChargingSessionValidity.valid;

  bool get hasCurve => curvePoints.length >= 2;

  Duration get duration => (endedAt ?? DateTime.now()).difference(startedAt);

  int get gainedPercent =>
      ((endedAt != null ? endLevel : currentLevel) - startLevel)
          .clamp(-100, 100);

  double? get temperatureRiseC => temperatureAvailable
      ? currentTemperatureC - startTemperatureC
      : null;

  String get qualityLabel => switch (quality) {
        ChargingSessionQuality.active => 'In corso',
        ChargingSessionQuality.completed => 'Completa',
        ChargingSessionQuality.interrupted => 'Interrotta',
        ChargingSessionQuality.uncertain => 'Da verificare',
      };

  String get durationLabel {
    final minutes = duration.inMinutes;
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0 ? '$hours h' : '$hours h $rest min';
  }

  String get estimateLabel {
    final minutes = estimatedMinutesToTarget;
    if (minutes == null) return 'Calcolo…';
    if (minutes < 60) return '≈ $minutes min';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0 ? '≈ $hours h' : '≈ $hours h $rest min';
  }
}
