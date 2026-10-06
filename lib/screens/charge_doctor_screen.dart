import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/charge_test.dart';
import '../services/app_controller.dart';
import '../widgets/premium_card.dart';

class ChargeDoctorScreen extends StatefulWidget {
  const ChargeDoctorScreen({
    required this.controller,
    super.key,
  });

  final AppController controller;

  @override
  State<ChargeDoctorScreen> createState() => _ChargeDoctorScreenState();
}

class _ChargeDoctorScreenState extends State<ChargeDoctorScreen> {
  final TextEditingController _labelController = TextEditingController();
  Timer? _uiTimer;

  @override
  void initState() {
    super.initState();
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && widget.controller.activeChargeTest != null) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final active = widget.controller.activeChargeTest;
    final tests = widget.controller.chargeTests;
    final scheme = Theme.of(context).colorScheme;

    if (!widget.controller.premium.isPro) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Text(
            l10n.chargeDoctorTitle,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.chargeDoctorSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 18),
          PremiumCard(controller: widget.controller),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.chargeDoctorTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            if (tests.isNotEmpty)
              IconButton(
                tooltip: l10n.clearTests,
                onPressed: () => _confirmClear(context),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          l10n.chargeDoctorSubtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: active == null
                ? _StartPanel(
                    controller: widget.controller,
                    labelController: _labelController,
                    onStarted: () => setState(() {}),
                  )
                : _ActivePanel(
                    controller: widget.controller,
                    active: active,
                    onStopped: () => setState(() {}),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.science_outlined),
                const SizedBox(width: 10),
                Expanded(child: Text(l10n.testGuidance)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          l10n.savedTests,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 10),
        if (tests.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.electric_bolt_outlined,
                    size: 38,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.noChargeTests,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ...tests.map(
            (test) => _TestCard(
              test: test,
              comparison: _comparisonFor(test, tests),
            ),
          ),
      ],
    );
  }

  _Comparison _comparisonFor(
    ChargeTest current,
    List<ChargeTest> all,
  ) {
    if (!current.reliable || current.averagePowerW <= 0) {
      return const _Comparison.insufficient();
    }

    final comparable = all
        .where(
          (test) =>
              test.id != current.id &&
              test.reliable &&
              test.source == current.source &&
              test.averagePowerW > 0,
        )
        .toList(growable: false);

    if (comparable.length < 2) {
      return const _Comparison.insufficient();
    }

    final baseline =
        comparable.map((test) => test.averagePowerW).reduce((a, b) => a + b) /
            comparable.length;
    if (baseline <= 0) return const _Comparison.insufficient();

    final delta = ((current.averagePowerW - baseline) / baseline) * 100;
    return _Comparison(deltaPercent: delta, baselineW: baseline);
  }

  Future<void> _confirmClear(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.clearTestsTitle),
        content: Text(l10n.clearTestsBody),
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
      await widget.controller.clearChargeTests();
      if (mounted) setState(() {});
    }
  }
}

class _StartPanel extends StatelessWidget {
  const _StartPanel({
    required this.controller,
    required this.labelController,
    required this.onStarted,
  });

  final AppController controller;
  final TextEditingController labelController;
  final VoidCallback onStarted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: labelController,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: l10n.testName,
            hintText: l10n.testNameHint,
            prefixIcon: const Icon(Icons.cable_rounded),
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: () async {
            final error =
                await controller.startChargeDoctorTest(labelController.text);
            if (!context.mounted) return;
            if (error == null) {
              onStarted();
              return;
            }
            final message = switch (error) {
              'not_plugged' => l10n.testRequiresPlug,
              'power_unavailable' => l10n.testPowerUnavailable,
              _ => l10n.testPowerUnavailable,
            };
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          },
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(l10n.startTest),
        ),
      ],
    );
  }
}

class _ActivePanel extends StatelessWidget {
  const _ActivePanel({
    required this.controller,
    required this.active,
    required this.onStopped,
  });

  final AppController controller;
  final ActiveChargeTest active;
  final VoidCallback onStopped;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final elapsed = DateTime.now().difference(active.startedAt);
    final power = active.average(active.powers);
    final current = active.average(active.currents);
    final voltage = active.average(active.voltages);
    final temperature = active.temperatures.isEmpty
        ? null
        : active.temperatures.reduce((a, b) => a > b ? a : b);

    String durationLabel(Duration value) {
      if (value.inMinutes > 0) return l10n.minutesShort(value.inMinutes);
      return l10n.secondsShort(value.inSeconds);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.science_rounded),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.activeTest,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            Text(durationLabel(elapsed)),
          ],
        ),
        const SizedBox(height: 6),
        Text(active.label),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _Metric(
              label: l10n.observedPower,
              value: power > 0
                  ? '${power.toStringAsFixed(1)} W'
                  : l10n.measurementUnavailable,
            ),
            _Metric(
              label: l10n.observedCurrent,
              value: current > 0
                  ? '${current.toStringAsFixed(0)} mA'
                  : l10n.measurementUnavailable,
            ),
            _Metric(
              label: l10n.observedVoltage,
              value: voltage > 0
                  ? '${voltage.toStringAsFixed(2)} V'
                  : l10n.measurementUnavailable,
            ),
            _Metric(
              label: l10n.temperature,
              value: temperature == null
                  ? l10n.measurementUnavailable
                  : '${temperature.toStringAsFixed(1)} °C',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(l10n.samplesCount(active.samples)),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: () async {
            await controller.stopChargeDoctorTest();
            onStopped();
          },
          icon: const Icon(Icons.stop_rounded),
          label: Text(l10n.stopTest),
        ),
      ],
    );
  }
}

class _TestCard extends StatelessWidget {
  const _TestCard({
    required this.test,
    required this.comparison,
  });

  final ChargeTest test;
  final _Comparison comparison;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    String confidenceLabel() => switch (test.confidence) {
          ChargeTestConfidence.low => l10n.confidenceLow,
          ChargeTestConfidence.medium => l10n.confidenceMedium,
          ChargeTestConfidence.high => l10n.confidenceHigh,
        };

    final comparisonText = comparison.insufficient
        ? l10n.baselineNeedsTests
        : comparison.deltaPercent! > 10
            ? l10n.aboveBaseline(
                comparison.deltaPercent!.abs().toStringAsFixed(0),
              )
            : comparison.deltaPercent! < -10
                ? l10n.belowBaseline(
                    comparison.deltaPercent!.abs().toStringAsFixed(0),
                  )
                : l10n.similarBaseline;

    final duration = test.duration.inMinutes > 0
        ? l10n.minutesShort(test.duration.inMinutes)
        : l10n.secondsShort(test.duration.inSeconds);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: scheme.primaryContainer,
                  foregroundColor: scheme.onPrimaryContainer,
                  child: const Icon(Icons.electric_bolt_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    test.label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                Chip(label: Text(confidenceLabel())),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _Metric(
                  label: l10n.observedPower,
                  value: test.averagePowerW > 0
                      ? '${test.averagePowerW.toStringAsFixed(1)} W'
                      : l10n.measurementUnavailable,
                ),
                _Metric(
                  label: l10n.observedCurrent,
                  value: test.averageCurrentMa > 0
                      ? '${test.averageCurrentMa.toStringAsFixed(0)} mA'
                      : l10n.measurementUnavailable,
                ),
                _Metric(
                  label: l10n.observedVoltage,
                  value: test.averageVoltageV > 0
                      ? '${test.averageVoltageV.toStringAsFixed(2)} V'
                      : l10n.measurementUnavailable,
                ),
                _Metric(
                  label: l10n.temperatureRise,
                  value: test.maxTemperatureC > 0 &&
                          test.startTemperatureC > 0
                      ? '+${test.temperatureRiseC.toStringAsFixed(1)} °C'
                      : l10n.measurementUnavailable,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${l10n.sourceLabel(test.source)} • ${l10n.resultDuration(duration)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const Divider(height: 24),
            Text(
              l10n.baselineComparison,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(comparisonText),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 130),
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
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _Comparison {
  const _Comparison({
    required this.deltaPercent,
    required this.baselineW,
  }) : insufficient = false;

  const _Comparison.insufficient()
      : deltaPercent = null,
        baselineW = null,
        insufficient = true;

  final double? deltaPercent;
  final double? baselineW;
  final bool insufficient;
}
