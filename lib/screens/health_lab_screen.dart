import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/app_controller.dart';
import '../widgets/premium_card.dart';

class HealthLabScreen extends StatelessWidget {
  const HealthLabScreen({
    required this.controller,
    super.key,
  });

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    if (!controller.premium.isPro) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.healthLab)),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              l10n.healthLabSubtitle,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 18),
            PremiumCard(controller: controller),
          ],
        ),
      );
    }

    final report = controller.batteryHealthReport;
    final health = report.estimatedHealthPercent.clamp(0, 120);
    final normalized = (health / 100).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.healthLab),
        actions: [
          IconButton(
            tooltip: l10n.recheckReliability,
            onPressed: controller.refreshBatteryHealth,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.refreshBatteryHealth,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Text(
              l10n.healthLabSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    SizedBox(
                      width: 154,
                      height: 154,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox.expand(
                            child: CircularProgressIndicator(
                              value: report.hasEstimate ? normalized : null,
                              strokeWidth: 12,
                              backgroundColor: scheme.surfaceContainerHighest,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                report.hasEstimate
                                    ? '${health.toStringAsFixed(0)}%'
                                    : '—',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineLarge
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              Text(
                                l10n.estimatedHealth,
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      report.hasEstimate
                          ? '${report.estimatedFullCapacityMah.toStringAsFixed(0)} mAh / ${report.nominalCapacityMah} mAh'
                          : report.nominalCapacityMah <= 0
                              ? l10n.healthNeedNominal
                              : l10n.healthDataUnavailable,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      onPressed: () => _setNominalCapacity(context),
                      icon: const Icon(Icons.edit_rounded),
                      label: Text(l10n.setNominalCapacity),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: MediaQuery.sizeOf(context).width < 520 ? 2 : 4,
              childAspectRatio: 1.2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                _HealthMetric(
                  icon: Icons.battery_6_bar_rounded,
                  label: l10n.estimatedCapacity,
                  value: report.estimatedFullCapacityMah > 0
                      ? '${report.estimatedFullCapacityMah.toStringAsFixed(0)} mAh'
                      : l10n.dataUnavailable,
                ),
                _HealthMetric(
                  icon: Icons.repeat_rounded,
                  label: l10n.cycleCount,
                  value: report.hasCycleCount
                      ? '${report.cycleCount}'
                      : l10n.cycleUnavailable,
                ),
                _HealthMetric(
                  icon: Icons.verified_outlined,
                  label: l10n.confidence,
                  value: _confidenceLabel(l10n, report.confidence),
                ),
                _HealthMetric(
                  icon: Icons.trending_down_rounded,
                  label: l10n.trend,
                  value: report.sampleCount >= 6
                      ? '${report.trendPercent >= 0 ? '+' : ''}${report.trendPercent.toStringAsFixed(1)}%'
                      : l10n.dataUnavailable,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.thermalProfile,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _RowMetric(
                      label: l10n.averageTemperature,
                      value: report.hasThermalData
                          ? '${report.averageTemperatureC.toStringAsFixed(1)} °C'
                          : l10n.dataUnavailable,
                    ),
                    _RowMetric(
                      label: l10n.maximumTemperature,
                      value: report.maxTemperatureC > 0
                          ? '${report.maxTemperatureC.toStringAsFixed(1)} °C'
                          : l10n.dataUnavailable,
                    ),
                    _RowMetric(
                      label: l10n.confidence,
                      value: l10n.samplesUsed(report.sampleCount),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded),
                    const SizedBox(width: 10),
                    Expanded(child: Text(l10n.healthDisclaimer)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _confidenceLabel(AppLocalizations l10n, String value) {
    return switch (value) {
      'high' => l10n.confidenceHigh,
      'medium' => l10n.confidenceMedium,
      _ => l10n.confidenceLow,
    };
  }

  Future<void> _setNominalCapacity(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final report = controller.batteryHealthReport;
    final textController = TextEditingController(
      text: report.nominalCapacityMah > 0
          ? report.nominalCapacityMah.toString()
          : '',
    );

    final value = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.setNominalCapacity),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.nominalCapacityHint),
            const SizedBox(height: 14),
            TextField(
              controller: textController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: l10n.nominalCapacity,
                suffixText: 'mAh',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final parsed = int.tryParse(textController.text);
              if (parsed == null || parsed < 300 || parsed > 20000) return;
              Navigator.pop(dialogContext, parsed);
            },
            child: Text(l10n.continueLabel),
          ),
        ],
      ),
    );
    textController.dispose();
    if (value != null) {
      await controller.setNominalCapacityMah(value);
    }
  }
}

class _HealthMetric extends StatelessWidget {
  const _HealthMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: scheme.primary),
            const Spacer(),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RowMetric extends StatelessWidget {
  const _RowMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 12),
          Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
