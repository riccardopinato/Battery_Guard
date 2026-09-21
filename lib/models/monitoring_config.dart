class MonitoringConfig {
  const MonitoringConfig({
    required this.enabled,
    required this.targetLevel,
    required this.temperatureThresholdC,
    required this.notifyFull,
    required this.notifyUnplugged,
    required this.nightMode,
    required this.nightStartMinutes,
    required this.nightEndMinutes,
  });

  factory MonitoringConfig.defaults() => const MonitoringConfig(
        enabled: false,
        targetLevel: 80,
        temperatureThresholdC: 42,
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
      targetLevel: (map['targetLevel'] as num?)?.round() ?? defaults.targetLevel,
      temperatureThresholdC:
          (map['temperatureThresholdC'] as num?)?.toDouble() ??
              defaults.temperatureThresholdC,
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
  final int targetLevel;
  final double temperatureThresholdC;
  final bool notifyFull;
  final bool notifyUnplugged;
  final bool nightMode;
  final int nightStartMinutes;
  final int nightEndMinutes;

  MonitoringConfig copyWith({
    bool? enabled,
    int? targetLevel,
    double? temperatureThresholdC,
    bool? notifyFull,
    bool? notifyUnplugged,
    bool? nightMode,
    int? nightStartMinutes,
    int? nightEndMinutes,
  }) {
    return MonitoringConfig(
      enabled: enabled ?? this.enabled,
      targetLevel: targetLevel ?? this.targetLevel,
      temperatureThresholdC:
          temperatureThresholdC ?? this.temperatureThresholdC,
      notifyFull: notifyFull ?? this.notifyFull,
      notifyUnplugged: notifyUnplugged ?? this.notifyUnplugged,
      nightMode: nightMode ?? this.nightMode,
      nightStartMinutes: nightStartMinutes ?? this.nightStartMinutes,
      nightEndMinutes: nightEndMinutes ?? this.nightEndMinutes,
    );
  }

  Map<String, dynamic> toMap() => {
        'enabled': enabled,
        'targetLevel': targetLevel,
        'temperatureThresholdC': temperatureThresholdC,
        'notifyFull': notifyFull,
        'notifyUnplugged': notifyUnplugged,
        'nightMode': nightMode,
        'nightStartMinutes': nightStartMinutes,
        'nightEndMinutes': nightEndMinutes,
      };
}
