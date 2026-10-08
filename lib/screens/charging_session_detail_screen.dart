import 'package:flutter/material.dart';

import '../l10n/battery_labels.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/battery_stress.dart';
import '../models/charging_curve_analysis.dart';
import '../models/charging_session.dart';
import '../services/app_controller.dart';
import '../services/feature_access.dart';
import '../widgets/charging_curve_chart.dart';

class ChargingSessionDetailScreen extends StatelessWidget {
  const ChargingSessionDetailScreen({
    required this.controller,
    required this.session,
    super.key,
  });

  final AppController controller;
  final ChargingSession session;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.sessionDetailTitle)),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final analysis =
              ChargingCurveAnalysis.fromPoints(session.curvePoints);
          final hasCurveAccess =
              controller.canUseFeature(BatteryGuardFeature.chargingCurve);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              _SummaryCard(session: session),
              _StressCard(
                analysis: BatteryStressAnalysis.fromSession(session),
                showDetails: controller.canUseFeature(
                  BatteryGuardFeature.batteryStressDetails,
                ),
              ),
              const SizedBox(height: 12),
              if (session.oemChargeLimitDetected) ...[
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.shield_outlined),
                    title: Text(l10n.oemChargeLimitDetected),
                    subtitle: Text(
                      l10n.oemChargeLimitBody(
                        session.oemChargeLimitLevel ?? session.endLevel,
                      ),
                    ),
                  ),
                ),
              ],
              if (session.reasonCodes.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  l10n.sessionEvidence,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      for (var index = 0;
                          index < session.reasonCodes.length;
                          index++) ...[
                        ListTile(
                          dense: true,
                          leading:
                              const Icon(Icons.info_outline_rounded, size: 20),
                          title: Text(
                            _reasonLabel(
                              l10n,
                              session.reasonCodes[index],
                            ),
                          ),
                        ),
                        if (index != session.reasonCodes.length - 1)
                          const Divider(height: 1),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Text(
                l10n.chargingCurveTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              if (!session.hasCurve)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Text(l10n.chargingCurveNotEnoughData),
                  ),
                )
              else if (!hasCurveAccess)
                _PremiumCurveLock(controller: controller)
              else ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
                    child: Column(
                      children: [
                        ChargingCurveChart(
                          points: session.curvePoints,
                          semanticsLabel: l10n.chargingCurveSemantics,
                        ),
                        const SizedBox(height: 14),
                        const _CurveLegend(),
                        const SizedBox(height: 10),
                        Text(
                          l10n.curveNormalizedHint,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _AnalysisCard(
                  analysis: analysis,
                  pointCount: session.curvePoints.length,
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  static String _reasonLabel(
    AppLocalizations l10n,
    ChargingSessionReason reason,
  ) {
    return switch (reason) {
      ChargingSessionReason.tooShort => l10n.reasonTooShort,
      ChargingSessionReason.insufficientSocDelta =>
        l10n.reasonInsufficientSocDelta,
      ChargingSessionReason.powerDataMissing => l10n.reasonPowerMissing,
      ChargingSessionReason.currentDataMissing => l10n.reasonCurrentMissing,
      ChargingSessionReason.temperatureDataMissing =>
        l10n.reasonTemperatureMissing,
      ChargingSessionReason.userUnplugged => l10n.reasonUserUnplugged,
      ChargingSessionReason.systemInterrupted => l10n.reasonSystemInterrupted,
      ChargingSessionReason.oemChargeLimit => l10n.reasonOemChargeLimit,
      ChargingSessionReason.monitoringGap => l10n.reasonMonitoringGap,
      ChargingSessionReason.invalidTelemetry => l10n.reasonInvalidTelemetry,
      ChargingSessionReason.unknown => l10n.qualityUncertain,
    };
  }
}

class _StressCard extends StatelessWidget {
  const _StressCard({
    required this.analysis,
    required this.showDetails,
  });

  final BatteryStressAnalysis analysis;
  final bool showDetails;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    String levelLabel() => switch (analysis.level) {
          BatteryStressLevel.low => l10n.stressLow,
          BatteryStressLevel.moderate => l10n.stressModerate,
          BatteryStressLevel.high => l10n.stressHigh,
          BatteryStressLevel.veryHigh => l10n.stressVeryHigh,
        };

    if (!analysis.dataSufficient) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.shield_outlined),
          title: Text(l10n.batteryStress),
          subtitle: Text(l10n.stressNotEnoughData),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  color: scheme.primary,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    l10n.batteryStress,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                Chip(label: Text(levelLabel())),
              ],
            ),
            const SizedBox(height: 8),
            Text(l10n.stressHeuristicNotice),
            if (showDetails) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _Metric(
                    label: l10n.stressScore,
                    value: '${analysis.score.toStringAsFixed(0)}/100',
                  ),
                  _Metric(
                    label: l10n.highSocExposure,
                    value:
                        '${analysis.highSocMinutes.toStringAsFixed(1)} min',
                  ),
                  _Metric(
                    label: l10n.heatExposure,
                    value: '${analysis.hotMinutes.toStringAsFixed(1)} min',
                  ),
                  _Metric(
                    label: l10n.highVoltageExposure,
                    value:
                        '${analysis.highVoltageMinutes.toStringAsFixed(1)} min',
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.lock_outline_rounded, size: 18),
                  const SizedBox(width: 7),
                  Expanded(child: Text(l10n.stressDetailsPro)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.session});

  final ChargingSession session;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final maxTemp = session.temperatureAvailable
        ? '${session.maxTemperatureC.toStringAsFixed(1)} °C'
        : l10n.dataUnavailable;

    String validityLabel() => switch (session.validity) {
          ChargingSessionValidity.active => l10n.validityActive,
          ChargingSessionValidity.valid => l10n.validityValid,
          ChargingSessionValidity.partial => l10n.validityPartial,
          ChargingSessionValidity.interrupted => l10n.validityInterrupted,
          ChargingSessionValidity.excluded => l10n.validityExcluded,
          ChargingSessionValidity.uncertain => l10n.validityUncertain,
        };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: session.trustedForInsights
                      ? scheme.primaryContainer
                      : scheme.tertiaryContainer,
                  child: Icon(
                    session.trustedForInsights
                        ? Icons.check_circle_outline_rounded
                        : Icons.rule_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${session.startLevel}% → ${session.endLevel}%',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                Text(
                  validityLabel(),
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _Metric(
                  label: l10n.resultDuration(session.durationLabel),
                  value: localizedPlugType(l10n, session.plugType),
                ),
                _Metric(
                  label: l10n.averagePower,
                  value: session.averagePowerW > 0
                      ? '${session.averagePowerW.toStringAsFixed(1)} W'
                      : l10n.dataUnavailable,
                ),
                _Metric(
                  label: l10n.speed,
                  value: session.percentPerHour > 0
                      ? '${session.percentPerHour.toStringAsFixed(1)} %/h'
                      : l10n.dataUnavailable,
                ),
                _Metric(
                  label: l10n.maxTemperature,
                  value: maxTemp,
                ),
              ],
            ),
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
      constraints: const BoxConstraints(minWidth: 135),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
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
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _PremiumCurveLock extends StatelessWidget {
  const _PremiumCurveLock({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const Icon(Icons.lock_outline_rounded, size: 34),
            const SizedBox(height: 10),
            Text(
              l10n.chargingCurvePremiumTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.chargingCurvePremiumBody,
              textAlign: TextAlign.center,
            ),
            if (controller.premium.canUnlock) ...[
              const SizedBox(height: 14),
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

class _CurveLegend extends StatelessWidget {
  const _CurveLegend();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 14,
      runSpacing: 8,
      children: [
        _Legend(label: l10n.capabilityLevel, color: scheme.primary),
        _Legend(label: l10n.capabilityPower, color: scheme.secondary),
        _Legend(label: l10n.temperature, color: scheme.tertiary),
        _Legend(label: l10n.capabilityCurrent, color: scheme.error),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard({
    required this.analysis,
    required this.pointCount,
  });

  final ChargingCurveAnalysis analysis;
  final int pointCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final phases = <ChargingPhase>[];
    for (final segment in analysis.segments) {
      if (!phases.contains(segment.phase)) phases.add(segment.phase);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.curveAnalysis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(l10n.curveDataPoints(pointCount)),
            if (analysis.peakPowerW != null)
              Text(
                l10n.curvePeakPower(
                  analysis.peakPowerW!.toStringAsFixed(1),
                ),
              ),
            if (analysis.temperatureRiseC != null)
              Text(
                l10n.curveTemperatureRise(
                  analysis.temperatureRiseC!.toStringAsFixed(1),
                ),
              ),
            if (phases.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  for (final phase in phases)
                    Chip(label: Text(_phaseLabel(l10n, phase))),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _phaseLabel(AppLocalizations l10n, ChargingPhase phase) {
    return switch (phase) {
      ChargingPhase.rampUp => l10n.phaseRampUp,
      ChargingPhase.fast => l10n.phaseFast,
      ChargingPhase.steady => l10n.phaseSteady,
      ChargingPhase.plateau => l10n.phasePlateau,
      ChargingPhase.thermalThrottle => l10n.phaseThermalThrottle,
      ChargingPhase.taper => l10n.phaseTaper,
      ChargingPhase.chargeLimit => l10n.phaseChargeLimit,
      ChargingPhase.full => l10n.phaseFull,
    };
  }
}
