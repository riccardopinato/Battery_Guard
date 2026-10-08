import 'package:battery_guard/models/battery_snapshot.dart';
import 'package:battery_guard/models/battery_health_report.dart';
import 'package:battery_guard/models/charge_test.dart';
import 'package:battery_guard/models/charging_insights.dart';
import 'package:battery_guard/models/charging_session.dart';
import 'package:battery_guard/models/monitoring_config.dart';
import 'package:battery_guard/models/history_entry.dart';
import 'package:battery_guard/models/reliability_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BatterySnapshot distinguishes unavailable telemetry from zero', () {
    final snapshot = BatterySnapshot.fromMap({
      'level': 85,
      'temperatureC': 34.6,
      'voltageMv': 4321,
      'currentMa': -1200.0,
      'powerW': 5.18,
      'temperatureAvailable': true,
      'voltageAvailable': true,
      'currentAvailable': true,
      'powerAvailable': true,
      'chargeCounterAvailable': true,
      'chargeCounterMah': 3825.0,
      'cycleCount': 187,
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
    expect(snapshot.powerAvailable, isTrue);
    expect(snapshot.chargeCounterAvailable, isTrue);
    expect(snapshot.chargeCounterMah, closeTo(3825, 0.01));
    expect(snapshot.cycleCount, 187);

    final unsupported = BatterySnapshot.fromMap({'level': 50});
    expect(unsupported.powerAvailable, isFalse);
    expect(unsupported.currentAvailable, isFalse);
  });

  test('BatteryHealthReport parses estimated health evidence', () {
    final report = BatteryHealthReport.fromMap({
      'nominalCapacityMah': 5000,
      'estimatedFullCapacityMah': 4550.0,
      'estimatedHealthPercent': 91.0,
      'confidence': 'high',
      'sampleCount': 10,
      'cycleCount': 180,
      'trendPercent': -2.4,
      'averageTemperatureC': 32.0,
      'maxTemperatureC': 40.2,
    });

    expect(report.hasEstimate, isTrue);
    expect(report.hasCycleCount, isTrue);
    expect(report.estimatedHealthPercent, closeTo(91, 0.01));
  });

  test('ChargeTest parses controlled test evidence', () {
    final test = ChargeTest.fromMap({
      'id': 'doctor-1',
      'label': 'USB-C 65 W',
      'startedAt': 1000,
      'endedAt': 301000,
      'startLevel': 40,
      'endLevel': 46,
      'averagePowerW': 18.2,
      'averageCurrentMa': 4100.0,
      'averageVoltageV': 4.25,
      'startTemperatureC': 30.0,
      'maxTemperatureC': 34.0,
      'samples': 15,
      'source': 'AC charger',
      'confidence': 'high',
    });

    expect(test.reliable, isTrue);
    expect(test.averagePowerW, closeTo(18.2, 0.01));
    expect(test.temperatureRiseC, closeTo(4.0, 0.01));
  });

  test('MonitoringConfig defaults are battery-friendly', () {
    final config = MonitoringConfig.defaults();
    expect(config.lowLevel, 20);
    expect(config.targetLevel, 80);
    expect(config.notifyLow, isTrue);
    expect(config.temperatureThresholdC, 42);
    expect(config.notifyFull, isTrue);
    expect(config.notifyUnplugged, isTrue);
  });

  test('ChargingSession parses live smart-charging metrics', () {
    final session = ChargingSession.fromMap({
      'id': '1',
      'startedAt': 1000,
      'lastObservedAt': 2000,
      'endedAt': 0,
      'quality': 'active',
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
    expect(session.quality, ChargingSessionQuality.active);
  });

  test('ChargingInsights excludes interrupted sessions', () {
    final now = DateTime(2026, 9, 22, 12);

    ChargingSession buildSession({
      required String id,
      required int daysAgo,
      required int start,
      required int end,
      required double maxTemp,
      required double rate,
      required String source,
      ChargingSessionQuality quality = ChargingSessionQuality.completed,
    }) {
      final started = now.subtract(Duration(days: daysAgo, hours: 1));
      final ended = started.add(const Duration(hours: 1));
      return ChargingSession(
        id: id,
        startedAt: started,
        endedAt: ended,
        lastObservedAt: ended,
        startLevel: start,
        currentLevel: end,
        endLevel: end,
        startTemperatureC: 30,
        currentTemperatureC: maxTemp - 1,
        maxTemperatureC: maxTemp,
        temperatureAvailable: true,
        averagePowerW: 18,
        averageCurrentMa: 4000,
        percentPerHour: rate,
        estimatedMinutesToTarget: null,
        plugType: source,
        targetLevel: 80,
        completed: quality == ChargingSessionQuality.completed,
        quality: quality,
        validity: quality == ChargingSessionQuality.completed
            ? ChargingSessionValidity.valid
            : ChargingSessionValidity.interrupted,
        reasonCodes: const [],
        oemChargeLimitDetected: false,
        oemChargeLimitLevel: null,
        curvePoints: const [],
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
        buildSession(
          id: 'interrupted',
          daysAgo: 1,
          start: 20,
          end: 80,
          maxTemp: 50,
          rate: 5,
          source: 'Caricatore AC',
          quality: ChargingSessionQuality.interrupted,
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

  test('HistoryEntry does not reinterpret unavailable temperature as zero', () {
    final entry = HistoryEntry.fromMap({
      'type': 'sample',
      'level': 55,
      'temperatureC': 0.0,
      'temperatureAvailable': false,
      'timestamp': 1000,
    });

    expect(entry.temperatureAvailable, isFalse);
    expect(entry.temperatureC, 0.0);
  });

  test('ChargingSession preserves unavailable temperature state', () {
    final session = ChargingSession.fromMap({
      'id': 'no-temp',
      'startedAt': 1000,
      'lastObservedAt': 2000,
      'endedAt': 3000,
      'startLevel': 40,
      'currentLevel': 45,
      'endLevel': 45,
      'temperatureAvailable': false,
      'maxTemperatureC': 0.0,
      'quality': 'completed',
      'completed': true,
    });

    expect(session.temperatureAvailable, isFalse);
    expect(session.temperatureRiseC, isNull);
  });

  test('ReliabilityStatus exposes notification channel truth', () {
    final status = ReliabilityStatus.fromMap({
      'notificationsGranted': true,
      'notificationsGloballyEnabled': true,
      'monitorChannelEnabled': true,
      'alertChannelEnabled': false,
      'highChargeChannelEnabled': true,
      'lowBatteryChannelEnabled': true,
      'quietChannelEnabled': true,
      'batteryOptimizationIgnored': false,
      'monitoringRequested': true,
      'serviceHealthy': true,
      'manufacturer': 'Samsung',
    });

    expect(status.deliveryReady, isFalse);
    expect(status.needsAttention, isTrue);
    expect(status.deliveryLabel, contains('Canale'));
  });

  test('ReliabilityStatus detects quiet channel failure only in night mode', () {
    final status = ReliabilityStatus.fromMap({
      'notificationsGranted': true,
      'notificationsGloballyEnabled': true,
      'monitorChannelEnabled': true,
      'alertChannelEnabled': true,
      'highChargeChannelEnabled': true,
      'lowBatteryChannelEnabled': true,
      'quietChannelEnabled': false,
      'lowAlertEnabled': true,
      'nightModeEnabled': true,
      'monitoringRequested': true,
      'serviceHealthy': true,
      'manufacturer': 'Android',
    });

    expect(status.deliveryReady, isFalse);
    expect(status.needsAttention, isTrue);
  });

  test('ReliabilityStatus accepts disabled monitoring with ready alerts', () {
    final status = ReliabilityStatus.fromMap({
      'notificationsGranted': true,
      'notificationsGloballyEnabled': true,
      'monitorChannelEnabled': true,
      'alertChannelEnabled': true,
      'highChargeChannelEnabled': true,
      'lowBatteryChannelEnabled': true,
      'quietChannelEnabled': true,
      'batteryOptimizationIgnored': false,
      'monitoringRequested': false,
      'serviceHealthy': true,
      'manufacturer': 'Android',
    });

    expect(status.needsAttention, isFalse);
    expect(status.serviceLabel, 'Non richiesto');
    expect(status.deliveryReady, isTrue);
  });
}
