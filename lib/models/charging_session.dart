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
    required this.averagePowerW,
    required this.averageCurrentMa,
    required this.percentPerHour,
    required this.estimatedMinutesToTarget,
    required this.plugType,
    required this.targetLevel,
    required this.completed,
    required this.quality,
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
      map['quality'] ?? ((map['completed'] as bool? ?? false) ? 'completed' : 'active'),
    );

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
      maxTemperatureC: number('maxTemperatureC').toDouble(),
      averagePowerW: number('averagePowerW').toDouble(),
      averageCurrentMa: number('averageCurrentMa').toDouble(),
      percentPerHour: number('percentPerHour').toDouble(),
      estimatedMinutesToTarget: estimate > 0 ? estimate : null,
      plugType: text('plugType', 'Sconosciuto'),
      targetLevel: number('targetLevel', 80).round().clamp(50, 100),
      completed: map['completed'] as bool? ??
          quality == ChargingSessionQuality.completed,
      quality: quality,
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
  final double averagePowerW;
  final double averageCurrentMa;
  final double percentPerHour;
  final int? estimatedMinutesToTarget;
  final String plugType;
  final int targetLevel;
  final bool completed;
  final ChargingSessionQuality quality;

  bool get trustedForInsights =>
      quality == ChargingSessionQuality.completed && completed;

  Duration get duration => (endedAt ?? DateTime.now()).difference(startedAt);

  int get gainedPercent =>
      ((endedAt != null ? endLevel : currentLevel) - startLevel).clamp(-100, 100);

  double get temperatureRiseC => currentTemperatureC - startTemperatureC;

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
