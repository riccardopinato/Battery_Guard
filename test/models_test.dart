import 'package:battery_guard/models/battery_snapshot.dart';
import 'package:battery_guard/models/monitoring_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BatterySnapshot parses Android payload', () {
    final snapshot = BatterySnapshot.fromMap({
      'level': 85,
      'temperatureC': 34.6,
      'voltageMv': 4321,
      'currentMa': -1200.0,
      'powerW': 5.18,
      'status': 'In carica',
      'health': 'Buona',
      'technology': 'Li-ion',
      'isCharging': true,
      'isPlugged': true,
      'plugType': 'USB',
      'isPowerSaveMode': false,
      'timestamp': 123456789,
    });

    expect(snapshot.level, 85);
    expect(snapshot.temperatureC, 34.6);
    expect(snapshot.voltageV, closeTo(4.321, 0.001));
    expect(snapshot.isCharging, isTrue);
  });

  test('MonitoringConfig defaults are battery-friendly', () {
    final config = MonitoringConfig.defaults();
    expect(config.targetLevel, 80);
    expect(config.temperatureThresholdC, 42);
    expect(config.notifyFull, isTrue);
    expect(config.notifyUnplugged, isTrue);
  });
}
