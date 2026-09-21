import 'charging_session.dart';

class DailyChargingPoint {
  const DailyChargingPoint({
    required this.day,
    required this.sessionCount,
    required this.averageMaxTemperatureC,
    required this.averageRatePercentPerHour,
  });

  final DateTime day;
  final int sessionCount;
  final double averageMaxTemperatureC;
  final double averageRatePercentPerHour;
}

class ChargingInsights {
  const ChargingInsights({
    required this.days,
    required this.sessionCount,
    required this.averageDurationMinutes,
    required this.averageMaxTemperatureC,
    required this.maximumTemperatureC,
    required this.averageRatePercentPerHour,
    required this.averagePowerW,
    required this.averageEndLevel,
    required this.over40Count,
    required this.over42Count,
    required this.over90Count,
    required this.fullCount,
    required this.estimatedAverageMinutesAbove80,
    required this.sourceCounts,
    required this.daily,
  });

  factory ChargingInsights.fromSessions(
    List<ChargingSession> sessions, {
    required int days,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final today = DateTime(reference.year, reference.month, reference.day);
    final cutoff = today.subtract(Duration(days: days - 1));

    final filtered = sessions
        .where((session) => session.completed)
        .where((session) {
          final local = session.startedAt.toLocal();
          final date = DateTime(local.year, local.month, local.day);
          return !date.isBefore(cutoff) && !date.isAfter(today);
        })
        .toList(growable: false);

    if (filtered.isEmpty) {
      return ChargingInsights(
        days: days,
        sessionCount: 0,
        averageDurationMinutes: 0,
        averageMaxTemperatureC: 0,
        maximumTemperatureC: 0,
        averageRatePercentPerHour: 0,
        averagePowerW: 0,
        averageEndLevel: 0,
        over40Count: 0,
        over42Count: 0,
        over90Count: 0,
        fullCount: 0,
        estimatedAverageMinutesAbove80: 0,
        sourceCounts: const {},
        daily: List.generate(
          days,
          (index) => DailyChargingPoint(
            day: cutoff.add(Duration(days: index)),
            sessionCount: 0,
            averageMaxTemperatureC: 0,
            averageRatePercentPerHour: 0,
          ),
        ),
      );
    }

    double average(Iterable<double> values) {
      final list = values.toList(growable: false);
      if (list.isEmpty) return 0;
      return list.reduce((a, b) => a + b) / list.length;
    }

    final sources = <String, int>{};
    for (final session in filtered) {
      sources.update(
        session.plugType,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    double estimatedMinutesAbove80(ChargingSession session) {
      final end = session.endLevel;
      final start = session.startLevel;
      final duration = session.duration.inMinutes.clamp(0, 24 * 60);
      if (end <= 80 || duration == 0) return 0;
      if (start >= 80) return duration.toDouble();

      final gained = end - start;
      if (gained <= 0) return 0;
      final above = end - 80;
      return duration * (above / gained).clamp(0.0, 1.0);
    }

    final daily = List.generate(days, (index) {
      final day = cutoff.add(Duration(days: index));
      final daySessions = filtered.where((session) {
        final local = session.startedAt.toLocal();
        return local.year == day.year &&
            local.month == day.month &&
            local.day == day.day;
      }).toList(growable: false);

      return DailyChargingPoint(
        day: day,
        sessionCount: daySessions.length,
        averageMaxTemperatureC: average(
          daySessions.map((session) => session.maxTemperatureC),
        ),
        averageRatePercentPerHour: average(
          daySessions
              .where((session) => session.percentPerHour > 0)
              .map((session) => session.percentPerHour),
        ),
      );
    });

    return ChargingInsights(
      days: days,
      sessionCount: filtered.length,
      averageDurationMinutes: average(
        filtered.map(
          (session) =>
              session.duration.inMinutes.clamp(0, 24 * 60).toDouble(),
        ),
      ),
      averageMaxTemperatureC: average(
        filtered.map((session) => session.maxTemperatureC),
      ),
      maximumTemperatureC: filtered
          .map((session) => session.maxTemperatureC)
          .reduce((a, b) => a > b ? a : b),
      averageRatePercentPerHour: average(
        filtered
            .where((session) => session.percentPerHour > 0)
            .map((session) => session.percentPerHour),
      ),
      averagePowerW: average(
        filtered
            .where((session) => session.averagePowerW > 0)
            .map((session) => session.averagePowerW),
      ),
      averageEndLevel: average(
        filtered.map((session) => session.endLevel.toDouble()),
      ),
      over40Count:
          filtered.where((session) => session.maxTemperatureC >= 40).length,
      over42Count:
          filtered.where((session) => session.maxTemperatureC >= 42).length,
      over90Count: filtered.where((session) => session.endLevel >= 90).length,
      fullCount: filtered.where((session) => session.endLevel >= 100).length,
      estimatedAverageMinutesAbove80: average(
        filtered.map(estimatedMinutesAbove80),
      ),
      sourceCounts: Map.unmodifiable(sources),
      daily: List.unmodifiable(daily),
    );
  }

  final int days;
  final int sessionCount;
  final double averageDurationMinutes;
  final double averageMaxTemperatureC;
  final double maximumTemperatureC;
  final double averageRatePercentPerHour;
  final double averagePowerW;
  final double averageEndLevel;
  final int over40Count;
  final int over42Count;
  final int over90Count;
  final int fullCount;
  final double estimatedAverageMinutesAbove80;
  final Map<String, int> sourceCounts;
  final List<DailyChargingPoint> daily;

  String get dominantSource {
    if (sourceCounts.isEmpty) return '—';
    return sourceCounts.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  List<String> get habitNotes {
    if (sessionCount == 0) {
      return const ['Nessuna sessione disponibile nel periodo selezionato.'];
    }

    final notes = <String>[];
    if (sessionCount < 3) {
      notes.add(
        'Servono almeno 3 sessioni per confronti personali più affidabili.',
      );
    }

    notes.add(
      'Livello medio a fine ricarica: ${averageEndLevel.toStringAsFixed(0)}%.',
    );

    if (fullCount > 0) {
      notes.add(
        '$fullCount sessioni su $sessionCount sono arrivate al 100%.',
      );
    }
    if (over42Count > 0) {
      notes.add(
        '$over42Count sessioni hanno raggiunto almeno 42 °C.',
      );
    } else {
      notes.add('Nessuna sessione ha raggiunto 42 °C nel periodo.');
    }

    if (dominantSource != '—') {
      notes.add('Sorgente più utilizzata: $dominantSource.');
    }

    return notes;
  }
}
