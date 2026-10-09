class DeviceIdentity {
  const DeviceIdentity({
    required this.manufacturer,
    required this.brand,
    required this.model,
    required this.device,
    required this.product,
    required this.sdkInt,
    required this.androidRelease,
    this.sku = '',
    this.odmSku = '',
    this.hardware = '',
    this.board = '',
    this.socManufacturer = '',
    this.socModel = '',
  });

  factory DeviceIdentity.fromMap(Map<dynamic, dynamic> map) {
    String read(String key) => map[key]?.toString().trim() ?? '';
    return DeviceIdentity(
      manufacturer: read('manufacturer'),
      brand: read('brand'),
      model: read('model'),
      device: read('device'),
      product: read('product'),
      sdkInt: (map['sdkInt'] as num?)?.round() ?? 0,
      androidRelease: read('androidRelease'),
      sku: read('sku'),
      odmSku: read('odmSku'),
      hardware: read('hardware'),
      board: read('board'),
      socManufacturer: read('socManufacturer'),
      socModel: read('socModel'),
    );
  }

  static const empty = DeviceIdentity(
    manufacturer: '',
    brand: '',
    model: '',
    device: '',
    product: '',
    sdkInt: 0,
    androidRelease: '',
  );

  final String manufacturer;
  final String brand;
  final String model;
  final String device;
  final String product;
  final int sdkInt;
  final String androidRelease;
  final String sku;
  final String odmSku;
  final String hardware;
  final String board;
  final String socManufacturer;
  final String socModel;

  String get displayName {
    final values = <String>[
      if (manufacturer.isNotEmpty) manufacturer,
      if (model.isNotEmpty) model,
    ];
    return values.isEmpty ? 'Android device' : values.join(' ');
  }

  String get lookupQuery => [
        manufacturer,
        brand,
        model,
        product,
        sku,
        odmSku,
      ].where((value) => value.trim().isNotEmpty).join(' ').trim();
}

enum DeviceSpecLookupStatus {
  idle,
  found,
  notFound,
  unsupported,
  error,
}

class DeviceBatteryProfile {
  const DeviceBatteryProfile({
    required this.identity,
    required this.status,
    this.nominalCapacityMah,
    this.typicalCapacityMah,
    this.maxChargePowerW,
    this.sourceName = '',
    this.sourceUrl,
    this.sourceConfidence = 'unknown',
    this.exactMatch = false,
    this.matchedDeviceName,
    this.fetchedAt,
    this.errorCode,
  });

  final DeviceIdentity identity;
  final DeviceSpecLookupStatus status;
  final int? nominalCapacityMah;
  final int? typicalCapacityMah;
  final double? maxChargePowerW;
  final String sourceName;
  final String? sourceUrl;
  final String sourceConfidence;
  final bool exactMatch;
  final String? matchedDeviceName;
  final DateTime? fetchedAt;
  final String? errorCode;

  int? get preferredCapacityMah =>
      typicalCapacityMah ?? nominalCapacityMah;

  bool get hasCapacity => preferredCapacityMah != null;

  factory DeviceBatteryProfile.idle(DeviceIdentity identity) =>
      DeviceBatteryProfile(
        identity: identity,
        status: DeviceSpecLookupStatus.idle,
      );

  factory DeviceBatteryProfile.unsupported(DeviceIdentity identity) =>
      DeviceBatteryProfile(
        identity: identity,
        status: DeviceSpecLookupStatus.unsupported,
        errorCode: 'UNSUPPORTED_PLATFORM',
      );
}
