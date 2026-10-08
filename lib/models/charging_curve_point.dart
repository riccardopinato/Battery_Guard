class ChargingCurvePoint {
  const ChargingCurvePoint({
    required this.timestamp,
    required this.level,
    required this.isCharging,
    required this.isPlugged,
    this.screenInteractive,
    this.temperatureC,
    this.voltageV,
    this.currentMa,
    this.powerW,
  });

  factory ChargingCurvePoint.fromMap(Map<dynamic, dynamic> map) {
    num? availableNumber(String key, String availabilityKey) {
      if (map[availabilityKey] != true) return null;
      final value = map[key];
      return value is num ? value : null;
    }

    final timestamp = map['timestamp'];
    final level = map['level'];

    return ChargingCurvePoint(
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        timestamp is num ? timestamp.round() : 0,
      ),
      level: level is num ? level.round().clamp(0, 100).toInt() : 0,
      isCharging: map['isCharging'] == true,
      isPlugged: map['isPlugged'] == true,
      screenInteractive: map['screenStateAvailable'] == true
          ? map['screenInteractive'] == true
          : null,
      temperatureC:
          availableNumber('temperatureC', 'temperatureAvailable')?.toDouble(),
      voltageV: availableNumber('voltageV', 'voltageAvailable')?.toDouble(),
      currentMa: availableNumber('currentMa', 'currentAvailable')?.toDouble(),
      powerW: availableNumber('powerW', 'powerAvailable')?.toDouble(),
    );
  }

  final DateTime timestamp;
  final int level;
  final bool isCharging;
  final bool isPlugged;
  final bool? screenInteractive;
  final double? temperatureC;
  final double? voltageV;
  final double? currentMa;
  final double? powerW;
}
