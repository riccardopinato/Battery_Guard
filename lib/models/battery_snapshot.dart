class BatterySnapshot {
  const BatterySnapshot({
    required this.level,
    required this.temperatureC,
    required this.voltageMv,
    required this.currentMa,
    required this.powerW,
    required this.status,
    required this.health,
    required this.technology,
    required this.isCharging,
    required this.isPlugged,
    required this.plugType,
    required this.isPowerSaveMode,
    required this.timestamp,
  });

  factory BatterySnapshot.empty() => BatterySnapshot(
        level: 0,
        temperatureC: 0,
        voltageMv: 0,
        currentMa: 0,
        powerW: 0,
        status: 'Sconosciuto',
        health: 'Sconosciuta',
        technology: '—',
        isCharging: false,
        isPlugged: false,
        plugType: 'Nessuno',
        isPowerSaveMode: false,
        timestamp: DateTime.now(),
      );

  factory BatterySnapshot.fromMap(Map<dynamic, dynamic> map) {
    num number(String key, [num fallback = 0]) {
      final value = map[key];
      return value is num ? value : fallback;
    }

    bool boolean(String key, [bool fallback = false]) {
      final value = map[key];
      return value is bool ? value : fallback;
    }

    String text(String key, [String fallback = '—']) {
      final value = map[key];
      return value?.toString() ?? fallback;
    }

    return BatterySnapshot(
      level: number('level').round().clamp(0, 100).toInt(),
      temperatureC: number('temperatureC').toDouble(),
      voltageMv: number('voltageMv').round(),
      currentMa: number('currentMa').toDouble(),
      powerW: number('powerW').toDouble(),
      status: text('status', 'Sconosciuto'),
      health: text('health', 'Sconosciuta'),
      technology: text('technology'),
      isCharging: boolean('isCharging'),
      isPlugged: boolean('isPlugged'),
      plugType: text('plugType', 'Nessuno'),
      isPowerSaveMode: boolean('isPowerSaveMode'),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        number('timestamp', DateTime.now().millisecondsSinceEpoch).round(),
      ),
    );
  }

  final int level;
  final double temperatureC;
  final int voltageMv;
  final double currentMa;
  final double powerW;
  final String status;
  final String health;
  final String technology;
  final bool isCharging;
  final bool isPlugged;
  final String plugType;
  final bool isPowerSaveMode;
  final DateTime timestamp;

  double get voltageV => voltageMv / 1000;
}
