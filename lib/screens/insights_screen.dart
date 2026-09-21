import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/charging_insights.dart';
import '../services/app_controller.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({
    required this.controller,
    super.key,
  });

  final AppController controller;

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  int _days = 7;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.refreshHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final insights = ChargingInsights.fromSessions(
      widget.controller.chargingSessions,
      days: _days,
    );
    final scheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: widget.controller.refreshHistory,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Text(
            'Insights',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Statistiche basate solo sulle sessioni osservate sul dispositivo.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 7, label: Text('7 giorni')),
              ButtonSegment(value: 30, label: Text('30 giorni')),
            ],
            selected: {_days},
            showSelectedIcon: false,
            onSelectionChanged: (values) {
              setState(() => _days = values.first);
            },
          ),
          const SizedBox(height: 18),
          if (insights.sessionCount == 0)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.insights_rounded,
                      size: 40,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Non ci sono ancora sessioni concluse nel periodo selezionato.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else ...[
            GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 1.25,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _InsightMetric(
                  icon: Icons.battery_charging_full_rounded,
                  label: 'Sessioni',
                  value: '${insights.sessionCount}',
                  caption:
                      'Media ${_durationLabel(insights.averageDurationMinutes)}',
                ),
                _InsightMetric(
                  icon: Icons.speed_rounded,
                  label: 'Velocità media',
                  value:
                      '${insights.averageRatePercentPerHour.toStringAsFixed(1)} %/h',
                  caption: 'Sessioni con incremento misurabile',
                ),
                _InsightMetric(
                  icon: Icons.thermostat_rounded,
                  label: 'Temp. media max',
                  value:
                      '${insights.averageMaxTemperatureC.toStringAsFixed(1)} °C',
                  caption:
                      'Picco ${insights.maximumTemperatureC.toStringAsFixed(1)} °C',
                ),
                _InsightMetric(
                  icon: Icons.electric_bolt_rounded,
                  label: 'Potenza media',
                  value: '${insights.averagePowerW.toStringAsFixed(1)} W',
                  caption: 'Stima dai dati esposti da Android',
                ),
              ],
            ),
            const SizedBox(height: 18),
            const _SectionTitle(title: 'Frequenza ricariche'),
            const SizedBox(height: 10),
            Card(
              child: SizedBox(
                height: 180,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
                  child: CustomPaint(
                    painter: _DailyBarsPainter(
                      points: insights.daily,
                      barColor: scheme.primary,
                      gridColor: scheme.outlineVariant,
                      textColor: scheme.onSurfaceVariant,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const _SectionTitle(title: 'Temperatura massima media'),
            const SizedBox(height: 10),
            Card(
              child: SizedBox(
                height: 180,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
                  child: CustomPaint(
                    painter: _TemperatureLinePainter(
                      points: insights.daily,
                      lineColor: scheme.tertiary,
                      gridColor: scheme.outlineVariant,
                      textColor: scheme.onSurfaceVariant,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const _SectionTitle(title: 'Esposizione'),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _StatRow(
                      label: 'Sessioni ≥ 40 °C',
                      value: '${insights.over40Count}',
                    ),
                    _StatRow(
                      label: 'Sessioni ≥ 42 °C',
                      value: '${insights.over42Count}',
                    ),
                    _StatRow(
                      label: 'Finale ≥ 90%',
                      value: '${insights.over90Count}',
                    ),
                    _StatRow(
                      label: 'Finale 100%',
                      value: '${insights.fullCount}',
                    ),
                    _StatRow(
                      label: 'Tempo medio sopra 80%',
                      value:
                          '≈ ${_durationLabel(insights.estimatedAverageMinutesAbove80)}',
                      last: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const _SectionTitle(title: 'Sorgenti di ricarica'),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: insights.sourceCounts.entries
                      .map(
                        (entry) => Chip(
                          avatar: const Icon(
                            Icons.power_rounded,
                            size: 18,
                          ),
                          label: Text('${entry.key}: ${entry.value}'),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const _SectionTitle(title: 'Abitudini osservate'),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: insights.habitNotes
                      .map(
                        (note) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.circle,
                                size: 7,
                                color: scheme.primary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Text(note)),
                            ],
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _durationLabel(double minutesValue) {
    final minutes = minutesValue.round().clamp(0, 24 * 60);
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0 ? '$hours h' : '$hours h $rest min';
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _InsightMetric extends StatelessWidget {
  const _InsightMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
  });

  final IconData icon;
  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: scheme.primary),
            const Spacer(),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    this.last = false,
  });

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(
                bottom: BorderSide(color: scheme.outlineVariant),
              ),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _DailyBarsPainter extends CustomPainter {
  _DailyBarsPainter({
    required this.points,
    required this.barColor,
    required this.gridColor,
    required this.textColor,
  });

  final List<DailyChargingPoint> points;
  final Color barColor;
  final Color gridColor;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    const labelHeight = 22.0;
    final chartHeight = size.height - labelHeight;
    final maxSessions = math.max(
      1,
      points.fold<int>(
        0,
        (value, point) => math.max(value, point.sessionCount),
      ),
    );
    const gap = 4.0;
    final barWidth =
        math.max(2.0, (size.width - gap * (points.length - 1)) / points.length);

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, chartHeight),
      Offset(size.width, chartHeight),
      gridPaint,
    );

    final barPaint = Paint()..color = barColor;
    final labelPainter = TextPainter(textDirection: TextDirection.ltr);

    for (var index = 0; index < points.length; index++) {
      final point = points[index];
      final x = index * (barWidth + gap);
      final barHeight = chartHeight * (point.sessionCount / maxSessions);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          x,
          chartHeight - barHeight,
          barWidth,
          barHeight,
        ),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, barPaint);

      final showLabel = points.length <= 7 ||
          index == 0 ||
          index == points.length - 1 ||
          index % 5 == 0;
      if (showLabel) {
        labelPainter.text = TextSpan(
          text: '${point.day.day}',
          style: TextStyle(
            color: textColor,
            fontSize: 10,
          ),
        );
        labelPainter.layout();
        labelPainter.paint(
          canvas,
          Offset(
            x + (barWidth - labelPainter.width) / 2,
            chartHeight + 6,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DailyBarsPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.barColor != barColor ||
        oldDelegate.gridColor != gridColor;
  }
}

class _TemperatureLinePainter extends CustomPainter {
  _TemperatureLinePainter({
    required this.points,
    required this.lineColor,
    required this.gridColor,
    required this.textColor,
  });

  final List<DailyChargingPoint> points;
  final Color lineColor;
  final Color gridColor;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    const labelHeight = 22.0;
    final chartHeight = size.height - labelHeight;
    final valid = points
        .where((point) => point.averageMaxTemperatureC > 0)
        .toList(growable: false);

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, chartHeight),
      Offset(size.width, chartHeight),
      gridPaint,
    );

    if (valid.isEmpty) return;

    final maxTemp = math.max(
      45.0,
      valid
          .map((point) => point.averageMaxTemperatureC)
          .reduce(math.max)
          .ceilToDouble(),
    );
    const minTemp = 20.0;
    final path = Path();
    var started = false;

    for (var index = 0; index < points.length; index++) {
      final temp = points[index].averageMaxTemperatureC;
      if (temp <= 0) continue;
      final x = points.length <= 1
          ? size.width / 2
          : size.width * index / (points.length - 1);
      final normalized =
          ((temp - minTemp) / (maxTemp - minTemp)).clamp(0.0, 1.0);
      final y = chartHeight * (1 - normalized);
      if (!started) {
        path.moveTo(x, y);
        started = true;
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(
        Offset(x, y),
        3,
        Paint()..color = lineColor,
      );
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );

    final labelPainter = TextPainter(
      text: TextSpan(
        text: '${maxTemp.toStringAsFixed(0)}°',
        style: TextStyle(color: textColor, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    labelPainter.paint(canvas, const Offset(0, 0));
  }

  @override
  bool shouldRepaint(covariant _TemperatureLinePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor;
  }
}
