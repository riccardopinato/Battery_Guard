enum ChargeProtectionMode {
  directControl,
  systemSetting,
  alertOnly,
}

enum ChargeProtectionVerification {
  disabled,
  belowTarget,
  pending,
  verifiedStopped,
  stillCharging,
  unplugged,
  unsupported,
  failed,
  notApplicable,
}

ChargeProtectionMode _modeFrom(String raw) {
  return switch (raw) {
    'direct_control' => ChargeProtectionMode.directControl,
    'system_setting' => ChargeProtectionMode.systemSetting,
    _ => ChargeProtectionMode.alertOnly,
  };
}

ChargeProtectionVerification _verificationFrom(String raw) {
  return switch (raw) {
    'disabled' => ChargeProtectionVerification.disabled,
    'below_target' => ChargeProtectionVerification.belowTarget,
    'pending' => ChargeProtectionVerification.pending,
    'verified_stopped' => ChargeProtectionVerification.verifiedStopped,
    'still_charging' => ChargeProtectionVerification.stillCharging,
    'unplugged' => ChargeProtectionVerification.unplugged,
    'unsupported' => ChargeProtectionVerification.unsupported,
    'failed' => ChargeProtectionVerification.failed,
    'not_applicable' => ChargeProtectionVerification.notApplicable,
    _ => ChargeProtectionVerification.pending,
  };
}

class ChargeProtectionCapability {
  const ChargeProtectionCapability({
    required this.adapterId,
    required this.mode,
    required this.supportsDirectControl,
    required this.systemLimitAvailable,
    required this.supportedTargets,
    required this.confidence,
    required this.guideCode,
    required this.manufacturer,
    required this.model,
  });

  factory ChargeProtectionCapability.fromMap(Map<dynamic, dynamic> map) {
    return ChargeProtectionCapability(
      adapterId: map['adapterId']?.toString() ?? 'generic',
      mode: _modeFrom(map['mode']?.toString() ?? ''),
      supportsDirectControl: map['supportsDirectControl'] as bool? ?? false,
      systemLimitAvailable: map['systemLimitAvailable'] as bool? ?? false,
      supportedTargets: (map['supportedTargets'] as List<dynamic>? ?? const [])
          .whereType<num>()
          .map((value) => value.round())
          .where((value) => value >= 70 && value <= 100)
          .toList(growable: false),
      confidence: map['confidence']?.toString() ?? 'unknown',
      guideCode: map['guideCode']?.toString() ?? 'generic',
      manufacturer: map['manufacturer']?.toString() ?? '',
      model: map['model']?.toString() ?? '',
    );
  }

  static const unknown = ChargeProtectionCapability(
    adapterId: 'generic',
    mode: ChargeProtectionMode.alertOnly,
    supportsDirectControl: false,
    systemLimitAvailable: false,
    supportedTargets: <int>[],
    confidence: 'unknown',
    guideCode: 'generic',
    manufacturer: '',
    model: '',
  );

  final String adapterId;
  final ChargeProtectionMode mode;
  final bool supportsDirectControl;
  final bool systemLimitAvailable;
  final List<int> supportedTargets;
  final String confidence;
  final String guideCode;
  final String manufacturer;
  final String model;

  bool supportsTarget(int targetLevel) =>
      supportsDirectControl || supportedTargets.contains(targetLevel);
}

class ChargeProtectionState {
  const ChargeProtectionState({
    required this.enabled,
    required this.targetLevel,
    required this.verification,
    required this.observedLevel,
    required this.observedIsCharging,
    required this.observedIsPlugged,
    this.verifiedAt,
    this.commandSent = false,
    this.requiresUserAction = false,
    this.verificationMode = 'alert_only',
    this.observedAt,
    this.commandSentAt,
  });

  factory ChargeProtectionState.fromMap(Map<dynamic, dynamic> map) {
    final verifiedAtRaw = (map['verifiedAt'] as num?)?.toInt() ?? 0;
    return ChargeProtectionState(
      enabled: map['enabled'] as bool? ?? false,
      targetLevel: ((map['targetLevel'] as num?)?.round() ?? 80)
          .clamp(70, 100),
      verification:
          _verificationFrom(map['verification']?.toString() ?? 'pending'),
      observedLevel: ((map['observedLevel'] as num?)?.round() ?? -1),
      observedIsCharging: map['observedIsCharging'] as bool? ?? false,
      observedIsPlugged: map['observedIsPlugged'] as bool? ?? false,
      verifiedAt: verifiedAtRaw > 0
          ? DateTime.fromMillisecondsSinceEpoch(verifiedAtRaw)
          : null,
      commandSent: map['commandSent'] as bool? ?? false,
      requiresUserAction: map['requiresUserAction'] as bool? ?? false,
      verificationMode:
          map['verificationMode']?.toString() ?? 'alert_only',
      observedAt: ((map['observedAt'] as num?)?.toInt() ?? 0) > 0
          ? DateTime.fromMillisecondsSinceEpoch(
              (map['observedAt'] as num).toInt(),
            )
          : null,
      commandSentAt: ((map['commandSentAt'] as num?)?.toInt() ?? 0) > 0
          ? DateTime.fromMillisecondsSinceEpoch(
              (map['commandSentAt'] as num).toInt(),
            )
          : null,
    );
  }

  static const disabled = ChargeProtectionState(
    enabled: false,
    targetLevel: 80,
    verification: ChargeProtectionVerification.disabled,
    observedLevel: -1,
    observedIsCharging: false,
    observedIsPlugged: false,
  );

  final bool enabled;
  final int targetLevel;
  final ChargeProtectionVerification verification;
  final int observedLevel;
  final bool observedIsCharging;
  final bool observedIsPlugged;
  final DateTime? verifiedAt;
  final bool commandSent;
  final bool requiresUserAction;
  final String verificationMode;
  final DateTime? observedAt;
  final DateTime? commandSentAt;

  bool get isVerifiedStopped =>
      verification == ChargeProtectionVerification.verifiedStopped;
}
