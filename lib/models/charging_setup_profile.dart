class ChargingSetupProfile {
  const ChargingSetupProfile({
    required this.id,
    required this.name,
    required this.chargerName,
    required this.cableName,
    required this.source,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChargingSetupProfile.fromMap(Map<dynamic, dynamic> map) {
    int i(String key, [int fallback = 0]) =>
        (map[key] as num?)?.round() ?? fallback;
    String s(String key, [String fallback = '']) =>
        map[key]?.toString() ?? fallback;

    final now = DateTime.now().millisecondsSinceEpoch;
    return ChargingSetupProfile(
      id: s('id'),
      name: s('name', 'Charging setup'),
      chargerName: s('chargerName'),
      cableName: s('cableName'),
      source: s('source', 'unknown'),
      notes: s('notes'),
      createdAt: DateTime.fromMillisecondsSinceEpoch(i('createdAt', now)),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(i('updatedAt', now)),
    );
  }

  final String id;
  final String name;
  final String chargerName;
  final String cableName;
  final String source;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get displayName => name.trim().isNotEmpty
      ? name.trim()
      : [
          chargerName.trim(),
          cableName.trim(),
        ].where((value) => value.isNotEmpty).join(' + ');

  Map<String, Object> toMap() => {
        'id': id,
        'name': name,
        'chargerName': chargerName,
        'cableName': cableName,
        'source': source,
        'notes': notes,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
      };

  ChargingSetupProfile copyWith({
    String? id,
    String? name,
    String? chargerName,
    String? cableName,
    String? source,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChargingSetupProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      chargerName: chargerName ?? this.chargerName,
      cableName: cableName ?? this.cableName,
      source: source ?? this.source,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
