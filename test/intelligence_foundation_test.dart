import 'package:battery_guard/models/battery_snapshot.dart';
import 'package:battery_guard/models/battery_signal.dart';
import 'package:battery_guard/models/charging_curve_analysis.dart';
import 'package:battery_guard/models/charging_curve_point.dart';
import 'package:battery_guard/models/charging_session.dart';
import 'package:battery_guard/services/feature_access.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BatterySnapshot preserves provenance and confidence metadata', () {
    final snapshot = BatterySnapshot.fromMap({
      'level': 80,
      'temperatureC': 33.5,
      'temperatureAvailable': true,
      'timestamp': 1000,
      'signals': {
        'temperature': {
          'available': true,
          'source': 'system_reported',
          'confidence': 'high',
          'observedAt': 1000,
        },
        'power': {
          'available': true,
          'source': 'calculated',
          'confidence': 'medium',
          'observedAt': 1000,
        },
      },
    });

    expect(snapshot.signal('temperature').available, isTrue);
    expect(
      snapshot.signal('temperature').source,
      BatteryDataSource.systemReported,
    );
    expect(
      snapshot.signal('temperature').confidence,
      BatteryDataConfidence.high,
    );
    expect(snapshot.signal('power').source, BatteryDataSource.calculated);
    expect(snapshot.signal('cycleCount').available, isFalse);
  });

  test('FeatureCatalog keeps truth/protection free and curves premium', () {
    expect(
      FeatureCatalog.tierFor(BatteryGuardFeature.dataProvenance),
      FeatureTier.free,
    );
    expect(
      FeatureCatalog.tierFor(BatteryGuardFeature.capabilityMap),
      FeatureTier.free,
    );
    expect(
      FeatureCatalog.tierFor(BatteryGuardFeature.sessionReasons),
      FeatureTier.free,
    );
    expect(
      FeatureCatalog.tierFor(BatteryGuardFeature.oemChargeLimitDetection),
      FeatureTier.free,
    );
    expect(
      FeatureCatalog.tierFor(BatteryGuardFeature.chargingCurve),
      FeatureTier.premium,
    );
    expect(
      FeatureCatalog.isEnabled(
        BatteryGuardFeature.chargingCurve,
        isPro: false,
      ),
      isFalse,
    );
    expect(
      FeatureCatalog.isEnabled(
        BatteryGuardFeature.chargingCurve,
        isPro: true,
      ),
      isTrue,
    );
  });

  test('ChargingSession parses reason codes OEM limit and bounded curve data', () {
    final session = ChargingSession.fromMap({
      'id': 'session-a',
      'startedAt': 1000,
      'endedAt': 601000,
      'lastObservedAt': 601000,
      'startLevel': 30,
      'currentLevel': 80,
      'endLevel': 80,
      'quality': 'completed',
      'validity': 'valid',
      'completed': true,
      'reasonCodes': ['OEM_CHARGE_LIMIT', 'USER_UNPLUGGED'],
      'oemChargeLimitDetected': true,
      'oemChargeLimitLevel': 80,
      'curvePoints': [
        {
          'timestamp': 1000,
          'level': 30,
          'isCharging': true,
          'powerAvailable': true,
          'powerW': 20.0,
        },
        {
          'timestamp': 601000,
          'level': 80,
          'isCharging': false,
          'powerAvailable': true,
          'powerW': 0.0,
        },
      ],
    });

    expect(session.validity, ChargingSessionValidity.valid);
    expect(session.trustedForInsights, isTrue);
    expect(
      session.reasonCodes,
      contains(ChargingSessionReason.oemChargeLimit),
    );
    expect(session.oemChargeLimitDetected, isTrue);
    expect(session.oemChargeLimitLevel, 80);
    expect(session.curvePoints, hasLength(2));
  });

  test('Legacy completed sessions remain readable without invented curve data', () {
    final session = ChargingSession.fromMap({
      'id': 'legacy',
      'startedAt': 1000,
      'endedAt': 301000,
      'lastObservedAt': 301000,
      'startLevel': 40,
      'currentLevel': 60,
      'endLevel': 60,
      'quality': 'completed',
      'completed': true,
    });

    expect(session.validity, ChargingSessionValidity.valid);
    expect(session.reasonCodes, isEmpty);
    expect(session.curvePoints, isEmpty);
    expect(session.oemChargeLimitDetected, isFalse);
  });

  test('Charging curve analyzer detects taper and device charge pause', () {
    final start = DateTime(2026, 10, 8, 12);
    final points = <ChargingCurvePoint>[
      ChargingCurvePoint(
        timestamp: start,
        level: 20,
        isCharging: true,
        powerW: 10,
      ),
      ChargingCurvePoint(
        timestamp: start.add(const Duration(minutes: 1)),
        level: 25,
        isCharging: true,
        powerW: 18,
      ),
      ChargingCurvePoint(
        timestamp: start.add(const Duration(minutes: 2)),
        level: 30,
        isCharging: true,
        powerW: 24,
      ),
      ChargingCurvePoint(
        timestamp: start.add(const Duration(minutes: 10)),
        level: 65,
        isCharging: true,
        powerW: 23,
      ),
      ChargingCurvePoint(
        timestamp: start.add(const Duration(minutes: 20)),
        level: 82,
        isCharging: true,
        powerW: 12,
      ),
      ChargingCurvePoint(
        timestamp: start.add(const Duration(minutes: 30)),
        level: 82,
        isCharging: false,
        powerW: 0,
      ),
    ];

    final analysis = ChargingCurveAnalysis.fromPoints(points);

    expect(analysis.peakPowerW, 24);
    expect(analysis.detectedTaper, isTrue);
    expect(analysis.detectedChargeLimit, isTrue);
  });
}
