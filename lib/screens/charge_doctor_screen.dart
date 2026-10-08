import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/battery_labels.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/charge_test.dart';
import '../models/charging_setup_profile.dart';
import '../services/app_controller.dart';
import '../services/charging_intelligence_engine.dart';
import '../services/feature_access.dart';
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
  String? _selectedSetupId;
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
    super.dispose();
  }

  ChargingSetupProfile? _selectedSetup() {
    final setups = widget.controller.chargingSetups;
    if (setups.isEmpty) return null;
    final selected = _selectedSetupId;
    if (selected != null) {
      for (final setup in setups) {
        if (setup.id == selected) return setup;
      }
    }
    return setups.first;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final active = widget.controller.activeChargeTest;
    final tests = widget.controller.chargeTests;
    final setups = widget.controller.accessibleChargingSetups;
    final selectedSetup = _selectedSetup();
    final scheme = Theme.of(context).colorScheme;
    final detailedScores = widget.controller.canUseFeature(
      BatteryGuardFeature.detailedChargeScores,
    );
    final rankings = ChargingIntelligenceEngine.ranking(
      tests: tests,
      profiles: setups,
    );

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
          l10n.chargeDoctorSubtitleV2,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 18),
        _SetupSection(
          controller: widget.controller,
          setups: setups,
          selectedSetup: selectedSetup,
          onSelect: (id) => setState(() => _selectedSetupId = id),
          onCreate: () => _openSetupDialog(context),
          onEdit: (setup) => _openSetupDialog(context, setup: setup),
          onDelete: (setup) => _confirmDeleteSetup(context, setup),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: active == null
                ? _StartPanel(
                    controller: widget.controller,
                    setup: selectedSetup,
                    onStarted: () => setState(() {}),
                    onCreateSetup: () => _openSetupDialog(context),
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
                Expanded(child: Text(l10n.testGuidanceV2)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          l10n.chargerRanking,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 10),
        if (widget.controller.canUseFeature(BatteryGuardFeature.chargerRanking))
          _RankingPanel(entries: rankings)
        else
          _PremiumRankingPreview(controller: widget.controller),
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
              analysis: ChargingIntelligenceEngine.analyze(test, tests),
              detailedScores: detailedScores,
            ),
          ),
        if (!widget.controller.premium.isPro) ...[
          const SizedBox(height: 18),
          PremiumCard(controller: widget.controller),
        ],
      ],
    );
  }

  Future<void> _openSetupDialog(
    BuildContext context, {
    ChargingSetupProfile? setup,
  }) async {
    final l10n = AppLocalizations.of(context);
    final name = TextEditingController(text: setup?.name ?? '');
    final charger = TextEditingController(text: setup?.chargerName ?? '');
    final cable = TextEditingController(text: setup?.cableName ?? '');
    final notes = TextEditingController(text: setup?.notes ?? '');

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          setup == null ? l10n.newChargingSetup : l10n.editChargingSetup,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: InputDecoration(labelText: l10n.setupName),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: charger,
                decoration: InputDecoration(labelText: l10n.chargerName),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: cable,
                decoration: InputDecoration(labelText: l10n.cableName),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notes,
                maxLines: 2,
                decoration: InputDecoration(labelText: l10n.notesOptional),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (shouldSave != true || !mounted) {
      name.dispose();
      charger.dispose();
      cable.dispose();
      notes.dispose();
      return;
    }

    final result = await widget.controller.saveChargingSetup(
      id: setup?.id,
      name: name.text,
      chargerName: charger.text,
      cableName: cable.text,
      notes: notes.text,
    );
    name.dispose();
    charger.dispose();
    cable.dispose();
    notes.dispose();

    if (!mounted) return;
    if (result == 'premium_required') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.multipleSetupsPro)),
      );
      return;
    }
    if (result == 'invalid_setup') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.setupRequiresName)),
      );
      return;
    }
    if (result != null) {
      setState(() => _selectedSetupId = result);
    }
  }

  Future<void> _confirmDeleteSetup(
    BuildContext context,
    ChargingSetupProfile setup,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteSetupTitle),
        content: Text(l10n.deleteSetupBody(setup.displayName)),
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
      await widget.controller.deleteChargingSetup(setup.id);
      if (mounted) setState(() => _selectedSetupId = null);
    }
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

class _SetupSection extends StatelessWidget {
  const _SetupSection({
    required this.controller,
    required this.setups,
    required this.selectedSetup,
    required this.onSelect,
    required this.onCreate,
    required this.onEdit,
    required this.onDelete,
  });

  final AppController controller;
  final List<ChargingSetupProfile> setups;
  final ChargingSetupProfile? selectedSetup;
  final ValueChanged<String> onSelect;
  final VoidCallback onCreate;
  final ValueChanged<ChargingSetupProfile> onEdit;
  final ValueChanged<ChargingSetupProfile> onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final canAddMultiple =
        controller.canUseFeature(BatteryGuardFeature.multipleChargingSetups);
    final canAdd = setups.isEmpty || canAddMultiple;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.power_rounded),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    l10n.chargingSetups,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                IconButton(
                  tooltip: canAdd ? l10n.newChargingSetup : l10n.multipleSetupsPro,
                  onPressed: canAdd
                      ? onCreate
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.multipleSetupsPro)),
                          );
                        },
                  icon: Icon(
                    canAdd ? Icons.add_rounded : Icons.lock_outline_rounded,
                  ),
                ),
              ],
            ),
            if (setups.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(l10n.noChargingSetups),
              )
            else ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final setup in setups)
                    ChoiceChip(
                      label: Text(setup.displayName),
                      selected: selectedSetup?.id == setup.id,
                      onSelected: (_) => onSelect(setup.id),
                    ),
                ],
              ),
              if (selectedSetup != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          [
                            if (selectedSetup!.chargerName.isNotEmpty)
                              selectedSetup!.chargerName,
                            if (selectedSetup!.cableName.isNotEmpty)
                              selectedSetup!.cableName,
                            localizedPlugType(l10n, selectedSetup!.source),
                          ].join(' • '),
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.edit,
                        onPressed: () => onEdit(selectedSetup!),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: l10n.delete,
                        onPressed: controller.activeChargeTest?.profileId ==
                                selectedSetup!.id
                            ? null
                            : () => onDelete(selectedSetup!),
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _StartPanel extends StatelessWidget {
  const _StartPanel({
    required this.controller,
    required this.setup,
    required this.onStarted,
    required this.onCreateSetup,
  });

  final AppController controller;
  final ChargingSetupProfile? setup;
  final VoidCallback onStarted;
  final VoidCallback onCreateSetup;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (setup == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.setupBeforeTest,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(l10n.setupBeforeTestBody),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onCreateSetup,
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.newChargingSetup),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          setup!.displayName,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 6),
        Text(l10n.chargeDoctorSetupReady),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: () async {
            final error = await controller.startChargeDoctorTest(setup!);
            if (!context.mounted) return;
            if (error == null) {
              onStarted();
              return;
            }
            final message = switch (error) {
              'not_plugged' => l10n.testRequiresPlug,
              'not_charging' => l10n.testRequiresCharging,
              'power_unavailable' => l10n.testPowerUnavailable,
              'premium_required' => l10n.multipleSetupsPro,
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

class _RankingPanel extends StatelessWidget {
  const _RankingPanel({required this.entries});

  final List<ChargingSetupRankingEntry> entries;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (entries.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(l10n.rankingNeedsTests),
        ),
      );
    }

    return Column(
      children: [
        for (var index = 0; index < entries.length; index++)
          Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Text('#${index + 1}'),
              ),
              title: Text(
                entries[index].name,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                l10n.rankingTestsAndPower(
                  entries[index].tests,
                  entries[index].averagePowerW.toStringAsFixed(1),
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _score(entries[index].overallScore),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  Text(
                    _trendText(l10n, entries[index].overallTrendDelta),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _score(double? value) => value == null ? '—' : value.toStringAsFixed(0);

  String _trendText(AppLocalizations l10n, double? delta) {
    if (delta == null) return l10n.trendNotEnoughData;
    if (delta.abs() < 2) return l10n.trendStable;
    return delta > 0
        ? l10n.trendImproving(delta.toStringAsFixed(0))
        : l10n.trendWorsening(delta.abs().toStringAsFixed(0));
  }
}

class _PremiumRankingPreview extends StatelessWidget {
  const _PremiumRankingPreview({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const Icon(Icons.emoji_events_outlined, size: 34),
            const SizedBox(height: 10),
            Text(
              l10n.rankingProTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.rankingProBody,
              textAlign: TextAlign.center,
            ),
            if (controller.premium.canUnlock) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => controller.premium.buy(),
                icon: const Icon(Icons.workspace_premium_outlined),
                label: Text(l10n.unlockPro),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TestCard extends StatelessWidget {
  const _TestCard({
    required this.test,
    required this.analysis,
    required this.detailedScores,
  });

  final ChargeTest test;
  final ChargeTestAnalysis analysis;
  final bool detailedScores;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    String confidenceLabel() => switch (test.confidence) {
          ChargeTestConfidence.low => l10n.confidenceLow,
          ChargeTestConfidence.medium => l10n.confidenceMedium,
          ChargeTestConfidence.high => l10n.confidenceHigh,
        };

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
            if (test.chargerName.isNotEmpty || test.cableName.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                [
                  if (test.chargerName.isNotEmpty) test.chargerName,
                  if (test.cableName.isNotEmpty) test.cableName,
                ].join(' • '),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
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
                  label: l10n.peakPower,
                  value: test.peakPowerW > 0
                      ? '${test.peakPowerW.toStringAsFixed(1)} W'
                      : l10n.measurementUnavailable,
                ),
                _Metric(
                  label: l10n.temperatureRise,
                  value: test.temperatureAvailable
                      ? '+${test.temperatureRiseC.toStringAsFixed(1)} °C'
                      : l10n.measurementUnavailable,
                ),
                _Metric(
                  label: l10n.batteryStress,
                  value: _stressBand(l10n, test),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${l10n.sourceLabel(localizedPlugType(l10n, test.source))} • ${l10n.resultDuration(duration)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const Divider(height: 24),
            Text(
              l10n.chargeQualitySummary,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _BandChip(
                  label: l10n.speed,
                  band: analysis.speedBand,
                ),
                _BandChip(
                  label: l10n.stability,
                  band: analysis.stabilityBand,
                ),
                _BandChip(
                  label: l10n.thermalBehavior,
                  band: analysis.thermalBand,
                ),
                _BandChip(
                  label: l10n.overall,
                  band: analysis.overallBand,
                ),
              ],
            ),
            const SizedBox(height: 10),
            _Anomalies(analysis: analysis),
            if (detailedScores) ...[
              const Divider(height: 24),
              _DetailedScores(test: test, analysis: analysis),
            ] else ...[
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(Icons.lock_outline_rounded, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(l10n.detailedScoresPro)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _stressBand(AppLocalizations l10n, ChargeTest test) {
    if (!test.stressAvailable) return l10n.measurementUnavailable;
    final value = test.stressScore;
    if (value < 25) return l10n.stressLow;
    if (value < 50) return l10n.stressModerate;
    if (value < 75) return l10n.stressHigh;
    return l10n.stressVeryHigh;
  }
}

class _DetailedScores extends StatelessWidget {
  const _DetailedScores({
    required this.test,
    required this.analysis,
  });

  final ChargeTest test;
  final ChargeTestAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.proScoreBreakdown,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _ScoreMetric(label: l10n.speed, value: analysis.speedScore),
            _ScoreMetric(label: l10n.stability, value: analysis.stabilityScore),
            _ScoreMetric(
              label: l10n.thermalBehavior,
              value: analysis.thermalScore,
            ),
            _ScoreMetric(label: l10n.overall, value: analysis.overallScore),
          ],
        ),
        const SizedBox(height: 12),
        if (analysis.baselinePowerW != null &&
            analysis.powerDeltaPercent != null)
          Text(
            l10n.personalBaselineDetail(
              analysis.baselinePowerW!.toStringAsFixed(1),
              analysis.powerDeltaPercent!.toStringAsFixed(0),
              analysis.comparableTests,
            ),
          )
        else
          Text(l10n.baselineNeedsTests),
        if (test.stressAvailable) ...[
          const SizedBox(height: 8),
          Text(
            l10n.stressDetail(
              test.stressScore.toStringAsFixed(0),
              test.highSocMinutes.toStringAsFixed(1),
              test.hotMinutes.toStringAsFixed(1),
            ),
          ),
        ],
      ],
    );
  }
}

class _Anomalies extends StatelessWidget {
  const _Anomalies({required this.analysis});

  final ChargeTestAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final visible = analysis.anomalies
        .where((item) => item != ChargingAnomaly.insufficientBaseline)
        .toList(growable: false);

    if (visible.isEmpty) {
      return Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 18),
          const SizedBox(width: 7),
          Expanded(child: Text(l10n.noChargeAnomalies)),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final anomaly in visible)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 18),
                const SizedBox(width: 7),
                Expanded(child: Text(_label(l10n, anomaly))),
              ],
            ),
          ),
      ],
    );
  }

  String _label(AppLocalizations l10n, ChargingAnomaly anomaly) {
    return switch (anomaly) {
      ChargingAnomaly.unstablePower => l10n.anomalyUnstablePower,
      ChargingAnomaly.repeatedPowerDrops => l10n.anomalyPowerDrops,
      ChargingAnomaly.highTemperature => l10n.anomalyHighTemperature,
      ChargingAnomaly.highTemperatureRise => l10n.anomalyTemperatureRise,
      ChargingAnomaly.slowerThanBaseline => l10n.anomalySlowBaseline,
      ChargingAnomaly.insufficientBaseline => l10n.baselineNeedsTests,
      ChargingAnomaly.elevatedStress => l10n.anomalyElevatedStress,
    };
  }
}

class _BandChip extends StatelessWidget {
  const _BandChip({
    required this.label,
    required this.band,
  });

  final String label;
  final ChargeScoreBand band;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final value = switch (band) {
      ChargeScoreBand.excellent => l10n.scoreExcellent,
      ChargeScoreBand.good => l10n.scoreGood,
      ChargeScoreBand.fair => l10n.scoreFair,
      ChargeScoreBand.weak => l10n.scoreWeak,
      ChargeScoreBand.unavailable => l10n.measurementUnavailable,
    };
    return Chip(label: Text('$label: $value'));
  }
}

class _ScoreMetric extends StatelessWidget {
  const _ScoreMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final double? value;

  @override
  Widget build(BuildContext context) {
    return _Metric(
      label: label,
      value: value == null ? '—' : '${value!.toStringAsFixed(0)}/100',
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
