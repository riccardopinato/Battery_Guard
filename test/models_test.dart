import 'package:battery_guard/models/battery_snapshot.dart';
import 'package:battery_guard/models/charging_insights.dart';
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

  test('ChargingInsights aggregates observed sessions', () {
    final now = DateTime(2026, 9, 22, 12);

    ChargingSession buildSession({
      required String id,
      required int daysAgo,
      required int start,
      required int end,
      required double maxTemp,
      required double rate,
      required String source,
    }) {
      final started = now.subtract(Duration(days: daysAgo, hours: 1));
      return ChargingSession(
        id: id,
        startedAt: started,
        endedAt: started.add(const Duration(hours: 1)),
        startLevel: start,
        currentLevel: end,
        endLevel: end,
        startTemperatureC: 30,
        currentTemperatureC: maxTemp - 1,
        maxTemperatureC: maxTemp,
        averagePowerW: 18,
        averageCurrentMa: 4000,
        percentPerHour: rate,
        estimatedMinutesToTarget: null,
        plugType: source,
        targetLevel: 80,
        completed: true,
      );
    }

    final insights = ChargingInsights.fromSessions(
      [
        buildSession(
          id: 'a',
          daysAgo: 0,
          start: 30,
          end: 100,
          maxTemp: 43,
          rate: 35,
          source: 'Caricatore AC',
        ),
        buildSession(
          id: 'b',
          daysAgo: 2,
          start: 40,
          end: 85,
          maxTemp: 38,
          rate: 30,
          source: 'Caricatore AC',
        ),
      ],
      days: 7,
      now: now,
    );

    expect(insights.sessionCount, 2);
    expect(insights.fullCount, 1);
    expect(insights.over42Count, 1);
    expect(insights.dominantSource, 'Caricatore AC');
    expect(insights.averageRatePercentPerHour, closeTo(32.5, 0.01));
  });
}
