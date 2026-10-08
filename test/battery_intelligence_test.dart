import 'package:battery_guard/models/battery_snapshot.dart';
import 'package:battery_guard/models/charging_session.dart';
import 'package:battery_guard/services/battery_intelligence_engine.dart';
import 'package:flutter_test/flutter_test.dart';

BatterySnapshot snapshot({
  int level = 50,
  bool charging = true,
  bool plugged = true,
  bool screenInteractive = false,
}) {
  return BatterySnapshot.fromMap({
    'level': level,
    'isCharging': charging,
    'isPlugged': plugged,
    'plugType': 'AC charger',
    'screenInteractive': screenInteractive,
    'screenStateAvailable': true,
    'timestamp': DateTime(2026, 10, 8, 12).millisecondsSinceEpoch,
  });
}

ChargingSession session({
  required String id,
  int startLevel = 40,
  int endLevel = 80,
  int minutes = 60,
  bool valid = true,
}) {
  final start = DateTime(2026, 10, 7, 12);
  return ChargingSession.fromMap({
    'id': id,
    'startedAt': start.millisecondsSinceEpoch,
    'endedAt': start.add(Duration(minutes: minutes)).millisecondsSinceEpoch,
    'lastObservedAt': start.add(Duration(minutes: minutes)).millisecondsSinceEpoch,
    'startLevel': startLevel,
    'currentLevel': endLevel,
    'endLevel': endLevel,
    'percentPerHour': (endLevel - startLevel) / (minutes / 60),
    'estimatedMinutesToTarget': -1,
    'plugType': 'AC charger',
    'targetLevel': 80,
    'completed': true,
    'quality': 'completed',
    'validity': valid ? 'valid' : 'partial',
    'reasonCodes': const [],
    'curvePoints': [
      for (var i = 0; i <= 8; i++)
        {
          'timestamp': start
              .add(Duration(minutes: (minutes * i / 8).round()))
              .millisecondsSinceEpoch,
          'level': startLevel + ((endLevel - startLevel) * i / 8).round(),
          'isCharging': true,
          'isPlugged': true,
          'screenStateAvailable': true,
          'screenInteractive': false,
        },
    ],
  });
}

void main() {
  test('standard ETA uses current session rate', () {
    final current = session(id: 'current', minutes: 60);
    final eta = BatteryIntelligenceEngine.standardEta(
      snapshot: snapshot(level: 60),
      currentSession: current,
      targetLevel: 80,
    );
    expect(eta.available, isTrue);
    expect(eta.minutes, inInclusiveRange(25, 35));
  });

  test('smart ETA learns only from valid same-source sessions', () {
    final eta = BatteryIntelligenceEngine.smartEta(
      snapshot: snapshot(level: 60),
      currentSession: null,
      history: [
        session(id: 'a', minutes: 60),
        session(id: 'b', minutes: 64),
        session(id: 'ignored', minutes: 20, valid: false),
      ],
      targetLevel: 80,
    );
    expect(eta.available, isTrue);
    expect(eta.historySamples, 2);
    expect(eta.kind.name, 'smart');
    expect(eta.minutes, inInclusiveRange(25, 40));
  });

  test('ETA is unavailable when device is not actively charging', () {
    final eta = BatteryIntelligenceEngine.smartEta(
      snapshot: snapshot(charging: false, plugged: false),
      currentSession: null,
      history: [session(id: 'a')],
      targetLevel: 80,
    );
    expect(eta.available, isFalse);
  });
}
