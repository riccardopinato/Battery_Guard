enum BatteryDataSource {
  systemReported,
  oemReported,
  measured,
  calculated,
  estimated,
  unavailable;

  static BatteryDataSource parse(Object? value) {
    return switch (value?.toString()) {
      'system_reported' => BatteryDataSource.systemReported,
      'oem_reported' => BatteryDataSource.oemReported,
      'measured' => BatteryDataSource.measured,
      'calculated' => BatteryDataSource.calculated,
      'estimated' => BatteryDataSource.estimated,
      _ => BatteryDataSource.unavailable,
    };
  }
}

enum BatteryDataConfidence {
  high,
  medium,
  low,
  unknown;

  static BatteryDataConfidence parse(Object? value) {
    return switch (value?.toString()) {
      'high' => BatteryDataConfidence.high,
      'medium' => BatteryDataConfidence.medium,
      'low' => BatteryDataConfidence.low,
      _ => BatteryDataConfidence.unknown,
    };
  }
}

class BatterySignalMeta {
  const BatterySignalMeta({
    required this.key,
    required this.available,
    required this.source,
    required this.confidence,
    required this.observedAt,
  });

  factory BatterySignalMeta.fromMap(
    String key,
    Map<dynamic, dynamic> map,
  ) {
    final timestamp = map['observedAt'];
    return BatterySignalMeta(
      key: key,
      available: map['available'] == true,
      source: BatteryDataSource.parse(map['source']),
      confidence: BatteryDataConfidence.parse(map['confidence']),
      observedAt: DateTime.fromMillisecondsSinceEpoch(
        timestamp is num ? timestamp.round() : 0,
      ),
    );
  }

  factory BatterySignalMeta.unavailable(String key) => BatterySignalMeta(
        key: key,
        available: false,
        source: BatteryDataSource.unavailable,
        confidence: BatteryDataConfidence.unknown,
        observedAt: DateTime.fromMillisecondsSinceEpoch(0),
      );

  final String key;
  final bool available;
  final BatteryDataSource source;
  final BatteryDataConfidence confidence;
  final DateTime observedAt;
}
