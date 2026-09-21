import 'package:battery_guard/models/battery_snapshot.dart';
import 'package:battery_guard/models/charging_session.dart';
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

  test('ChargingSession parses live smart-charging metrics', () {
    final session = ChargingSession.fromMap({
      'id': '1',
      'startedAt': 1000,
      'endedAt': 0,
      'startLevel': 40,
      'currentLevel': 55,
      'endLevel': 55,
      'startTemperatureC': 30.0,
      'currentTemperatureC': 34.0,
      'maxTemperatureC': 35.0,
      'averagePowerW': 18.4,
      'averageCurrentMa': 4200.0,
      'percentPerHour': 30.0,
      'estimatedMinutesToTarget': 50,
      'plugType': 'Caricatore AC',
      'targetLevel': 80,
      'completed': false,
    });

    expect(session.gainedPercent, 15);
    expect(session.percentPerHour, 30.0);
    expect(session.estimatedMinutesToTarget, 50);
    expect(session.completed, isFalse);
  });
}
