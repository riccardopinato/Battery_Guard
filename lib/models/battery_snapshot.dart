import 'battery_signal.dart';

class BatterySnapshot {
  const BatterySnapshot({
    required this.level,
    required this.temperatureC,
    required this.voltageMv,
    required this.currentMa,
    required this.powerW,
    required this.temperatureAvailable,
    required this.voltageAvailable,
    required this.currentAvailable,
    required this.powerAvailable,
    required this.chargeCounterAvailable,
    required this.chargeCounterMah,
    required this.cycleCount,
    required this.status,
    required this.health,
    required this.technology,
    required this.isCharging,
    required this.isPlugged,
    required this.plugType,
    required this.isPowerSaveMode,
    this.screenInteractive = false,
    this.screenStateAvailable = false,
    required this.timestamp,
    required this.signals,
  });

  factory BatterySnapshot.empty() => BatterySnapshot(
        level: 0,
        temperatureC: 0,
        voltageMv: 0,
        currentMa: 0,
        powerW: 0,
        temperatureAvailable: false,
        voltageAvailable: false,
        currentAvailable: false,
        powerAvailable: false,
        chargeCounterAvailable: false,
        chargeCounterMah: 0,
        cycleCount: -1,
        status: 'Unknown',
        health: 'Unknown',
        technology: '—',
        isCharging: false,
        isPlugged: false,
        plugType: 'None',
        isPowerSaveMode: false,
        screenInteractive: false,
        screenStateAvailable: false,
        timestamp: DateTime.now(),
        signals: const {},
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

    final timestamp = DateTime.fromMillisecondsSinceEpoch(
      number('timestamp', DateTime.now().millisecondsSinceEpoch).round(),
    );
    final rawSignals = map['signals'];
    final signals = <String, BatterySignalMeta>{};
    if (rawSignals is Map) {
      for (final entry in rawSignals.entries) {
        final value = entry.value;
        if (value is Map) {
          final key = entry.key.toString();
          signals[key] = BatterySignalMeta.fromMap(
            key,
            value,
          );
        }
      }
    }

    return BatterySnapshot(
      level: number('level').round().clamp(0, 100).toInt(),
      temperatureC: number('temperatureC').toDouble(),
      voltageMv: number('voltageMv').round(),
      currentMa: number('currentMa').toDouble(),
      powerW: number('powerW').toDouble(),
      temperatureAvailable: boolean('temperatureAvailable'),
      voltageAvailable: boolean('voltageAvailable'),
      currentAvailable: boolean('currentAvailable'),
      powerAvailable: boolean('powerAvailable'),
      chargeCounterAvailable: boolean('chargeCounterAvailable'),
      chargeCounterMah: number('chargeCounterMah').toDouble(),
      cycleCount: number('cycleCount', -1).round(),
      status: text('status', 'Unknown'),
      health: text('health', 'Unknown'),
      technology: text('technology'),
      isCharging: boolean('isCharging'),
      isPlugged: boolean('isPlugged'),
      plugType: text('plugType', 'None'),
      isPowerSaveMode: boolean('isPowerSaveMode'),
      screenInteractive: boolean('screenInteractive'),
      screenStateAvailable: boolean('screenStateAvailable'),
      timestamp: timestamp,
      signals: Map.unmodifiable(signals),
    );
  }

  final int level;
  final double temperatureC;
  final int voltageMv;
  final double currentMa;
  final double powerW;
  final bool temperatureAvailable;
  final bool voltageAvailable;
  final bool currentAvailable;
  final bool powerAvailable;
  final bool chargeCounterAvailable;
  final double chargeCounterMah;
  final int cycleCount;
  final String status;
  final String health;
  final String technology;
  final bool isCharging;
  final bool isPlugged;
  final String plugType;
  final bool isPowerSaveMode;
  final bool screenInteractive;
  final bool screenStateAvailable;
  final DateTime timestamp;
  final Map<String, BatterySignalMeta> signals;

  double get voltageV => voltageMv / 1000;
  bool get cycleCountAvailable => cycleCount >= 0;

  BatterySignalMeta signal(String key) =>
      signals[key] ?? BatterySignalMeta.unavailable(key);
}
