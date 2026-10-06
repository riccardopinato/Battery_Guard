class ReliabilityStatus {
  const ReliabilityStatus({
    required this.notificationsGranted,
    required this.notificationsGloballyEnabled,
    required this.monitorChannelEnabled,
    required this.alertChannelEnabled,
    required this.highChargeChannelEnabled,
    required this.lowBatteryChannelEnabled,
    required this.quietChannelEnabled,
    required this.batteryOptimizationIgnored,
    required this.monitoringRequested,
    required this.serviceHealthy,
    required this.lastServiceStartAt,
    required this.lastServiceStopAt,
    required this.lastBatteryEventAt,
    required this.lastStartFailureAt,
    required this.manufacturer,
  });

  factory ReliabilityStatus.fromMap(Map<dynamic, dynamic> map) {
    DateTime? time(String key) {
      final value = (map[key] as num?)?.round() ?? 0;
      return value > 0 ? DateTime.fromMillisecondsSinceEpoch(value) : null;
    }

    bool flag(String key, [bool fallback = false]) =>
        map[key] as bool? ?? fallback;

    return ReliabilityStatus(
      notificationsGranted: flag('notificationsGranted'),
      notificationsGloballyEnabled: flag('notificationsGloballyEnabled'),
      monitorChannelEnabled: flag('monitorChannelEnabled'),
      alertChannelEnabled: flag('alertChannelEnabled'),
      highChargeChannelEnabled: flag('highChargeChannelEnabled'),
      lowBatteryChannelEnabled: flag('lowBatteryChannelEnabled'),
      quietChannelEnabled: flag('quietChannelEnabled'),
      batteryOptimizationIgnored: flag('batteryOptimizationIgnored'),
      monitoringRequested: flag('monitoringRequested'),
      serviceHealthy: flag('serviceHealthy'),
      lastServiceStartAt: time('lastServiceStartAt'),
      lastServiceStopAt: time('lastServiceStopAt'),
      lastBatteryEventAt: time('lastBatteryEventAt'),
      lastStartFailureAt: time('lastStartFailureAt'),
      manufacturer: map['manufacturer']?.toString() ?? 'Android',
    );
  }

  static const unknown = ReliabilityStatus(
    notificationsGranted: false,
    notificationsGloballyEnabled: false,
    monitorChannelEnabled: false,
    alertChannelEnabled: false,
    highChargeChannelEnabled: false,
    lowBatteryChannelEnabled: false,
    quietChannelEnabled: false,
    batteryOptimizationIgnored: false,
    monitoringRequested: false,
    serviceHealthy: true,
    lastServiceStartAt: null,
    lastServiceStopAt: null,
    lastBatteryEventAt: null,
    lastStartFailureAt: null,
    manufacturer: 'Android',
  );

  final bool notificationsGranted;
  final bool notificationsGloballyEnabled;
  final bool monitorChannelEnabled;
  final bool alertChannelEnabled;
  final bool highChargeChannelEnabled;
  final bool lowBatteryChannelEnabled;
  final bool quietChannelEnabled;
  final bool batteryOptimizationIgnored;
  final bool monitoringRequested;
  final bool serviceHealthy;
  final DateTime? lastServiceStartAt;
  final DateTime? lastServiceStopAt;
  final DateTime? lastBatteryEventAt;
  final DateTime? lastStartFailureAt;
  final String manufacturer;

  bool get deliveryReady =>
      notificationsGranted &&
      notificationsGloballyEnabled &&
      alertChannelEnabled &&
      highChargeChannelEnabled &&
      lowBatteryChannelEnabled;

  bool get monitorDeliveryReady =>
      notificationsGranted &&
      notificationsGloballyEnabled &&
      monitorChannelEnabled;

  bool get needsAttention =>
      !deliveryReady ||
      (monitoringRequested && (!serviceHealthy || !monitorDeliveryReady));

  String get serviceLabel {
    if (!monitoringRequested) return 'Non richiesto';
    if (serviceHealthy) return 'Operativo';
    return 'Da verificare';
  }

  String get deliveryLabel {
    if (!notificationsGranted) return 'Permesso notifiche mancante';
    if (!notificationsGloballyEnabled) return 'Notifiche app disattivate';
    if (!highChargeChannelEnabled) {
      return 'Canale limite superiore disattivato';
    }
    if (!lowBatteryChannelEnabled) {
      return 'Canale limite inferiore disattivato';
    }
    if (!alertChannelEnabled) return 'Canale avvisi disattivato';
    return 'Avvisi pronti';
  }

  String get batteryEventLabel {
    final value = lastBatteryEventAt;
    if (value == null) return 'Nessun evento batteria registrato';
    final elapsed = DateTime.now().difference(value);
    if (elapsed.inMinutes < 1) return 'Ultimo evento ora';
    if (elapsed.inMinutes < 60) {
      return 'Ultimo evento ${elapsed.inMinutes} min fa';
    }
    return 'Ultimo evento ${elapsed.inHours} h fa';
  }

  String get oemHint {
    final name = manufacturer.toLowerCase();
    if (name.contains('xiaomi') ||
        name.contains('redmi') ||
        name.contains('poco')) {
      return 'Su Xiaomi/Redmi/Poco verifica anche Avvio automatico e batteria senza restrizioni.';
    }
    if (name.contains('samsung')) {
      return 'Su Samsung evita che Battery Guard venga inserita tra le app in sospensione profonda.';
    }
    if (name.contains('oneplus') ||
        name.contains('oppo') ||
        name.contains('realme')) {
      return 'Su OnePlus/Oppo/Realme consenti attività in background e avvio automatico.';
    }
    if (name.contains('vivo')) {
      return 'Su Vivo consenti avvio automatico e attività in background.';
    }
    return 'Se il monitoraggio viene interrotto, imposta Battery Guard come app senza restrizioni nelle impostazioni batteria.';
  }
}
