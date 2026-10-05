import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/charging_session.dart';
import '../models/history_entry.dart';
import '../services/app_controller.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    required this.controller,
    super.key,
  });

  final AppController controller;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.refreshHistory();
    });
  }

  String _dateLabel(BuildContext context, DateTime date) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final local = date.toLocal();
    final sameDay = now.year == local.year &&
        now.month == local.month &&
        now.day == local.day;
    final time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    if (sameDay) return '${l10n.historyTitle == "History" ? "Today" : l10n.historyTitle == "Historial" ? "Hoy" : l10n.historyTitle == "Historique" ? "Aujourd’hui" : l10n.historyTitle == "Verlauf" ? "Heute" : l10n.historyTitle == "Histórico" ? "Hoje" : "Oggi"} - $time';
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')} - $time';
  }

  IconData _iconFor(HistoryEntry entry) {
    final title = entry.title.toLowerCase();
    if (title.contains('temperatura')) return Icons.thermostat_rounded;
    if (title.contains('scollegato')) return Icons.power_off_rounded;
    if (title.contains('lenta')) return Icons.speed_rounded;
    if (title.contains('carica')) return Icons.battery_charging_full_rounded;
    return Icons.notifications_active_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final history = widget.controller.history;
    final sessions = widget.controller.chargingSessions.take(20).toList();
    final samples = history.where((entry) => entry.isSample).take(24).toList();
    final alerts = history.where((entry) => entry.isAlert).take(30).toList();
    final hasAnything =
        history.isNotEmpty || widget.controller.chargingSessions.isNotEmpty;

    return RefreshIndicator(
      onRefresh: widget.controller.refreshHistory,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.historyTitle,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              if (hasAnything)
                IconButton(
                  tooltip: l10n.deleteHistory,
                  onPressed: () => _confirmClear(context),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.historySubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          if (sessions.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              l10n.chargingSessions,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            ...sessions.map(
              (session) => _SessionCard(
                session: session,
                dateLabel: _dateLabel(context, session.startedAt),
              ),
            ),
          ],
          if (samples.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              l10n.recentSamples,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    for (final entry in samples.take(8))
                      _SampleRow(
                        entry: entry,
                        dateLabel: _dateLabel(context, entry.timestamp),
                      ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          Text(
            l10n.recentAlerts,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          if (alerts.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.notifications_none_rounded,
                      size: 36,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 10),
                    Text(l10n.noAlerts),
                  ],
                ),
              ),
            )
          else
            ...alerts.map(
              (entry) => Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(child: Icon(_iconFor(entry))),
                  title: Text(
                    entry.title.isEmpty ? l10n.batteryAlert : entry.title,
                  ),
                  subtitle: Text(
                    '${entry.message}\\n${_dateLabel(context, entry.timestamp)}',
                  ),
                  isThreeLine: true,
                  trailing: Text('${entry.level}%'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.clearHistoryTitle),
        content: Text(l10n.clearHistoryBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.controller.clearHistory();
    }
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.dateLabel,
  });

  final ChargingSession session;
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final speed = session.percentPerHour > 0
        ? '${session.percentPerHour.toStringAsFixed(1)} %/h'
        : '—';

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: const CircleAvatar(
          child: Icon(Icons.battery_charging_full_rounded),
        ),
        title: Text(
          '${session.startLevel}% → ${session.endLevel}%  (+${session.gainedPercent}%)',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '$dateLabel • ${session.durationLabel} • ${session.plugType}\\n'
          '$speed • media ${session.averagePowerW.toStringAsFixed(1)} W • max ${session.maxTemperatureC.toStringAsFixed(1)} °C • ${session.qualityLabel}',
        ),
        isThreeLine: true,
        trailing: Tooltip(
          message: session.qualityLabel,
          child: Icon(
            session.trustedForInsights
                ? Icons.check_circle_outline_rounded
                : Icons.warning_amber_rounded,
            color: session.trustedForInsights ? scheme.primary : scheme.tertiary,
          ),
        ),
      ),
    );
  }
}

class _SampleRow extends StatelessWidget {
  const _SampleRow({
    required this.entry,
    required this.dateLabel,
  });

  final HistoryEntry entry;
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final level = entry.level.clamp(0, 100);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              '${entry.level}%',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: level / 100,
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 58,
            child: Text(
              '${entry.temperatureC.toStringAsFixed(1)} °C',
              textAlign: TextAlign.end,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 86,
            child: Text(
              dateLabel,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
