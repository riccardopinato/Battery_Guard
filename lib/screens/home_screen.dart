import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/charging_session.dart';
import '../services/app_controller.dart';
import '../widgets/battery_ring.dart';
import '../widgets/metric_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final snapshot = controller.snapshot;
    final config = controller.config;
    final session = controller.currentSession;
    final scheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: controller.refreshSnapshot,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Battery Guard',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                          ),
                    ),
                    Text(
                      config.enabled
                          ? l10n.protectionActive
                          : l10n.protectionInactive,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: config.enabled
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: config.enabled,
                onChanged: controller.setEnabled,
              ),
            ],
          ),
          if (controller.isWebPreview) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.language_rounded),
                    const SizedBox(width: 10),
                    Expanded(child: Text(l10n.webPreviewNotice)),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          Center(
            child: BatteryRing(
              level: snapshot.level,
              temperatureC: snapshot.temperatureC,
              isCharging: snapshot.isCharging,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        snapshot.isPlugged
                            ? Icons.power_rounded
                            : Icons.power_off_rounded,
                        color: snapshot.isPlugged
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              snapshot.isPlugged
                                  ? snapshot.plugType
                                  : l10n.notConnected,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              '${snapshot.status} • ${l10n.healthInline(snapshot.health.toLowerCase())}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      if (snapshot.isPowerSaveMode)
                        const Tooltip(
                          message: l10n.batterySaverActive,
                          child: Icon(Icons.energy_savings_leaf_outlined),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.notifyAt,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<int>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: 80, label: Text('80%')),
                        ButtonSegment(value: 85, label: Text('85%')),
                        ButtonSegment(value: 90, label: Text('90%')),
                        ButtonSegment(value: 100, label: Text('100%')),
                      ],
                      selected: {config.targetLevel},
                      onSelectionChanged: (values) {
                        HapticFeedback.selectionClick();
                        controller.setTargetLevel(values.first);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (session != null && snapshot.isPlugged) ...[
            const SizedBox(height: 14),
            _ChargingSessionCard(session: session),
          ],
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 1.25,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              MetricCard(
                icon: Icons.thermostat_rounded,
                label: l10n.temperature,
                value: snapshot.temperatureAvailable
                    ? '${snapshot.temperatureC.toStringAsFixed(1)} °C'
                    : 'Non disponibile',
                caption: snapshot.temperatureAvailable
                    ? (snapshot.temperatureC >= config.temperatureThresholdC
                        ? l10n.aboveThreshold
                        : l10n.thresholdValue(config.temperatureThresholdC.toStringAsFixed(0)))
                    : l10n.dataNotExposed,
              ),
              MetricCard(
                icon: Icons.electric_bolt_rounded,
                label: l10n.estimatedPower,
                value: snapshot.powerAvailable
                    ? '${snapshot.powerW.abs().toStringAsFixed(1)} W'
                    : 'Non disponibile',
                caption: snapshot.currentAvailable
                    ? '${snapshot.currentMa.abs().toStringAsFixed(0)} mA'
                    : l10n.currentNotExposed,
              ),
              MetricCard(
                icon: Icons.speed_rounded,
                label: l10n.voltage,
                value: snapshot.voltageAvailable
                    ? '${snapshot.voltageV.toStringAsFixed(2)} V'
                    : 'Non disponibile',
                caption: snapshot.technology,
              ),
              MetricCard(
                icon: Icons.favorite_outline_rounded,
                label: l10n.health,
                value: snapshot.health,
                caption: snapshot.status,
              ),
            ],
          ),
          if (!controller.reliability.deliveryReady) ...[
            const SizedBox(height: 14),
            Card(
              color: scheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_off_outlined,
                      color: scheme.onErrorContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.allowNotificationsToAlert,
                        style: TextStyle(color: scheme.onErrorContainer),
                      ),
                    ),
                    TextButton(
                      onPressed: controller.requestNotificationPermission,
                      child: Text(l10n.allow),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (controller.lastError case final error?) ...[
            const SizedBox(height: 14),
            Text(error, style: TextStyle(color: scheme.error)),
          ],
        ],
      ),
    );
  }
}

class _ChargingSessionCard extends StatelessWidget {
  const _ChargingSessionCard({required this.session});

  final ChargingSession session;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final speed = session.percentPerHour > 0
        ? '${session.percentPerHour.toStringAsFixed(1)} %/h'
        : l10n.calculating;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: scheme.primaryContainer,
                  foregroundColor: scheme.onPrimaryContainer,
                  child: const Icon(Icons.battery_charging_full_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.currentSession,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      Text(
                        '${session.plugType} • ${session.durationLabel}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${session.startLevel}% → ${session.currentLevel}%',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _SessionMetric(label: l10n.speed, value: speed),
                _SessionMetric(
                  label: l10n.averagePower,
                  value: '${session.averagePowerW.toStringAsFixed(1)} W',
                ),
                _SessionMetric(
                  label: l10n.atTarget(session.targetLevel),
                  value: session.estimateLabel,
                ),
                _SessionMetric(
                  label: l10n.temperature,
                  value:
                      '${session.currentTemperatureC.toStringAsFixed(1)} °C • max ${session.maxTemperatureC.toStringAsFixed(1)} °C',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionMetric extends StatelessWidget {
  const _SessionMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 128),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
