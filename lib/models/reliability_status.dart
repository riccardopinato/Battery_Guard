class ReliabilityStatus {
  const ReliabilityStatus({
    required this.notificationsGranted,
    required this.batteryOptimizationIgnored,
    required this.monitoringRequested,
    required this.serviceHealthy,
    required this.lastHeartbeatAt,
    required this.lastStartFailureAt,
    required this.manufacturer,
  });

  factory ReliabilityStatus.fromMap(Map<dynamic, dynamic> map) {
    int number(String key) => (map[key] as num?)?.round() ?? 0;
    final heartbeat = number('lastHeartbeatAt');
    final failure = number('lastStartFailureAt');

    return ReliabilityStatus(
      notificationsGranted: map['notificationsGranted'] as bool? ?? false,
      batteryOptimizationIgnored:
          map['batteryOptimizationIgnored'] as bool? ?? false,
      monitoringRequested: map['monitoringRequested'] as bool? ?? false,
      serviceHealthy: map['serviceHealthy'] as bool? ?? false,
      lastHeartbeatAt: heartbeat > 0
          ? DateTime.fromMillisecondsSinceEpoch(heartbeat)
          : null,
      lastStartFailureAt: failure > 0
          ? DateTime.fromMillisecondsSinceEpoch(failure)
          : null,
      manufacturer: map['manufacturer']?.toString() ?? 'Android',
    );
  }

  static const unknown = ReliabilityStatus(
    notificationsGranted: false,
    batteryOptimizationIgnored: false,
    monitoringRequested: false,
    serviceHealthy: true,
    lastHeartbeatAt: null,
    lastStartFailureAt: null,
    manufacturer: 'Android',
  );

  final bool notificationsGranted;
  final bool batteryOptimizationIgnored;
  final bool monitoringRequested;
  final bool serviceHealthy;
  final DateTime? lastHeartbeatAt;
  final DateTime? lastStartFailureAt;
  final String manufacturer;

  bool get needsAttention =>
      !notificationsGranted || (monitoringRequested && !serviceHealthy);

  String get serviceLabel {
    if (!monitoringRequested) return 'Non richiesto';
    if (serviceHealthy) return 'Operativo';
    return 'Da verificare';
  }

  String get heartbeatLabel {
    final value = lastHeartbeatAt;
    if (value == null) return 'Nessun heartbeat registrato';

    final elapsed = DateTime.now().difference(value);
    if (elapsed.inMinutes < 1) return 'Aggiornato ora';
    if (elapsed.inMinutes < 60) {
      return 'Aggiornato ${elapsed.inMinutes} min fa';
    }
    return 'Aggiornato ${elapsed.inHours} h fa';
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
