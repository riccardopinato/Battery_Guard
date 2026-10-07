class HistoryEntry {
  const HistoryEntry({
    required this.type,
    required this.title,
    required this.message,
    required this.level,
    required this.temperatureC,
    required this.temperatureAvailable,
    required this.timestamp,
    required this.isCharging,
  });

  factory HistoryEntry.fromMap(Map<dynamic, dynamic> map) {
    final timestamp = map['timestamp'];
    return HistoryEntry(
      type: map['type']?.toString() ?? 'sample',
      title: map['title']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
      level: (map['level'] as num?)?.round() ?? 0,
      temperatureC: (map['temperatureC'] as num?)?.toDouble() ?? 0,
      temperatureAvailable: map['temperatureAvailable'] == true,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        timestamp is num ? timestamp.round() : 0,
      ),
      isCharging: map['isCharging'] == true,
    );
  }

  final String type;
  final String title;
  final String message;
  final int level;
  final double temperatureC;
  final bool temperatureAvailable;
  final DateTime timestamp;
  final bool isCharging;

  bool get isAlert => type == 'alert';
  bool get isSample => type == 'sample';
}
