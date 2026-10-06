class MonitoringConfig {
  const MonitoringConfig({
    required this.enabled,
    required this.lowLevel,
    required this.targetLevel,
    required this.temperatureThresholdC,
    required this.notifyLow,
    required this.notifyFull,
    required this.notifyUnplugged,
    required this.nightMode,
    required this.nightStartMinutes,
    required this.nightEndMinutes,
  });

  factory MonitoringConfig.defaults() => const MonitoringConfig(
        enabled: false,
        lowLevel: 20,
        targetLevel: 80,
        temperatureThresholdC: 42,
        notifyLow: true,
        notifyFull: true,
        notifyUnplugged: true,
        nightMode: false,
        nightStartMinutes: 23 * 60,
        nightEndMinutes: 7 * 60,
      );

  factory MonitoringConfig.fromMap(Map<dynamic, dynamic> map) {
    final defaults = MonitoringConfig.defaults();
    return MonitoringConfig(
      enabled: map['enabled'] as bool? ?? defaults.enabled,
      lowLevel: ((map['lowLevel'] as num?)?.round() ?? defaults.lowLevel)
          .clamp(5, 45),
      targetLevel: ((map['targetLevel'] as num?)?.round() ??
              defaults.targetLevel)
          .clamp(50, 100),
      temperatureThresholdC:
          (map['temperatureThresholdC'] as num?)?.toDouble() ??
              defaults.temperatureThresholdC,
      notifyLow: map['notifyLow'] as bool? ?? defaults.notifyLow,
      notifyFull: map['notifyFull'] as bool? ?? defaults.notifyFull,
      notifyUnplugged:
          map['notifyUnplugged'] as bool? ?? defaults.notifyUnplugged,
      nightMode: map['nightMode'] as bool? ?? defaults.nightMode,
      nightStartMinutes:
          (map['nightStartMinutes'] as num?)?.round() ??
              defaults.nightStartMinutes,
      nightEndMinutes:
          (map['nightEndMinutes'] as num?)?.round() ?? defaults.nightEndMinutes,
    );
  }

  final bool enabled;
  final int lowLevel;
  final int targetLevel;
  final double temperatureThresholdC;
  final bool notifyLow;
  final bool notifyFull;
  final bool notifyUnplugged;
  final bool nightMode;
  final int nightStartMinutes;
  final int nightEndMinutes;

  MonitoringConfig copyWith({
    bool? enabled,
    int? lowLevel,
    int? targetLevel,
    double? temperatureThresholdC,
    bool? notifyLow,
    bool? notifyFull,
    bool? notifyUnplugged,
    bool? nightMode,
    int? nightStartMinutes,
    int? nightEndMinutes,
  }) {
    return MonitoringConfig(
      enabled: enabled ?? this.enabled,
      lowLevel: lowLevel ?? this.lowLevel,
      targetLevel: targetLevel ?? this.targetLevel,
      temperatureThresholdC:
          temperatureThresholdC ?? this.temperatureThresholdC,
      notifyLow: notifyLow ?? this.notifyLow,
      notifyFull: notifyFull ?? this.notifyFull,
      notifyUnplugged: notifyUnplugged ?? this.notifyUnplugged,
      nightMode: nightMode ?? this.nightMode,
      nightStartMinutes: nightStartMinutes ?? this.nightStartMinutes,
      nightEndMinutes: nightEndMinutes ?? this.nightEndMinutes,
    );
  }

  Map<String, dynamic> toMap() => {
        'enabled': enabled,
        'lowLevel': lowLevel,
        'targetLevel': targetLevel,
        'temperatureThresholdC': temperatureThresholdC,
        'notifyLow': notifyLow,
        'notifyFull': notifyFull,
        'notifyUnplugged': notifyUnplugged,
        'nightMode': nightMode,
        'nightStartMinutes': nightStartMinutes,
        'nightEndMinutes': nightEndMinutes,
      };
}
