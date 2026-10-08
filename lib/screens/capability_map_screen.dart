import 'package:flutter/material.dart';

import '../l10n/battery_labels.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/battery_signal.dart';
import '../services/app_controller.dart';

class CapabilityMapScreen extends StatelessWidget {
  const CapabilityMapScreen({
    required this.controller,
    super.key,
  });

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context);
        final snapshot = controller.snapshot;
        final items = <_CapabilityItem>[
          _CapabilityItem(
            keyName: 'level',
            label: l10n.capabilityLevel,
            value: '${snapshot.level}%',
          ),
          _CapabilityItem(
            keyName: 'temperature',
            label: l10n.temperature,
            value: snapshot.temperatureAvailable
                ? '${snapshot.temperatureC.toStringAsFixed(1)} °C'
                : l10n.dataUnavailable,
          ),
          _CapabilityItem(
            keyName: 'voltage',
            label: l10n.voltage,
            value: snapshot.voltageAvailable
                ? '${snapshot.voltageV.toStringAsFixed(3)} V'
                : l10n.dataUnavailable,
          ),
          _CapabilityItem(
            keyName: 'current',
            label: l10n.capabilityCurrent,
            value: snapshot.currentAvailable
                ? '${snapshot.currentMa.abs().toStringAsFixed(0)} mA'
                : l10n.dataUnavailable,
          ),
          _CapabilityItem(
            keyName: 'power',
            label: l10n.capabilityPower,
            value: snapshot.powerAvailable
                ? '${snapshot.powerW.abs().toStringAsFixed(1)} W'
                : l10n.dataUnavailable,
          ),
          _CapabilityItem(
            keyName: 'chargeCounter',
            label: l10n.capabilityChargeCounter,
            value: snapshot.chargeCounterAvailable
                ? '${snapshot.chargeCounterMah.toStringAsFixed(0)} mAh'
                : l10n.dataUnavailable,
          ),
          _CapabilityItem(
            keyName: 'cycleCount',
            label: l10n.cycleCount,
            value: snapshot.cycleCountAvailable
                ? snapshot.cycleCount.toString()
                : l10n.dataUnavailable,
          ),
          _CapabilityItem(
            keyName: 'status',
            label: l10n.capabilityStatus,
            value: localizedBatteryStatus(l10n, snapshot.status),
          ),
          _CapabilityItem(
            keyName: 'health',
            label: l10n.health,
            value: localizedBatteryHealth(l10n, snapshot.health),
          ),
          _CapabilityItem(
            keyName: 'technology',
            label: l10n.capabilityTechnology,
            value: snapshot.technology,
          ),
          _CapabilityItem(
            keyName: 'plugType',
            label: l10n.capabilityPlugType,
            value: localizedPlugType(l10n, snapshot.plugType),
          ),
        ];

        return Scaffold(
          appBar: AppBar(title: Text(l10n.capabilityMapTitle)),
          body: RefreshIndicator(
            onRefresh: controller.refreshSnapshot,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                Text(
                  l10n.capabilityMapSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 14),
                for (final item in items)
                  _CapabilityCard(
                    item: item,
                    meta: snapshot.signal(item.keyName),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CapabilityItem {
  const _CapabilityItem({
    required this.keyName,
    required this.label,
    required this.value,
  });

  final String keyName;
  final String label;
  final String value;
}

class _CapabilityCard extends StatelessWidget {
  const _CapabilityCard({
    required this.item,
    required this.meta,
  });

  final _CapabilityItem item;
  final BatterySignalMeta meta;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    String sourceLabel() => switch (meta.source) {
          BatteryDataSource.systemReported => l10n.sourceSystemReported,
          BatteryDataSource.oemReported => l10n.sourceOemReported,
          BatteryDataSource.measured => l10n.sourceMeasured,
          BatteryDataSource.calculated => l10n.sourceCalculated,
          BatteryDataSource.estimated => l10n.sourceEstimated,
          BatteryDataSource.unavailable => l10n.dataUnavailable,
        };

    String confidenceLabel() => switch (meta.confidence) {
          BatteryDataConfidence.high => l10n.confidenceHigh,
          BatteryDataConfidence.medium => l10n.confidenceMedium,
          BatteryDataConfidence.low => l10n.confidenceLow,
          BatteryDataConfidence.unknown => l10n.confidenceUnknown,
        };

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: meta.available
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
          foregroundColor: meta.available
              ? scheme.onPrimaryContainer
              : scheme.onSurfaceVariant,
          child: Icon(
            meta.available
                ? Icons.sensors_rounded
                : Icons.sensors_off_rounded,
          ),
        ),
        title: Text(
          item.label,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          meta.available
              ? '${sourceLabel()} • ${confidenceLabel()}'
              : l10n.dataNotExposed,
        ),
        trailing: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 118),
          child: Text(
            item.value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: meta.available
                  ? scheme.onSurface
                  : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
