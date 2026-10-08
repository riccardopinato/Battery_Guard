import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/charging_curve_point.dart';

class ChargingCurveChart extends StatelessWidget {
  const ChargingCurveChart({
    required this.points,
    required this.semanticsLabel,
    super.key,
  });

  final List<ChargingCurvePoint> points;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: semanticsLabel,
      image: true,
      child: SizedBox(
        height: 220,
        width: double.infinity,
        child: CustomPaint(
          painter: _ChargingCurvePainter(
            points: points,
            levelColor: scheme.primary,
            powerColor: scheme.secondary,
            temperatureColor: scheme.tertiary,
            currentColor: scheme.error,
            gridColor: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }
}

class _ChargingCurvePainter extends CustomPainter {
  const _ChargingCurvePainter({
    required this.points,
    required this.levelColor,
    required this.powerColor,
    required this.temperatureColor,
    required this.currentColor,
    required this.gridColor,
  });

  final List<ChargingCurvePoint> points;
  final Color levelColor;
  final Color powerColor;
  final Color temperatureColor;
  final Color currentColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2 || size.width <= 0 || size.height <= 0) return;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var index = 1; index < 4; index++) {
      final y = size.height * index / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final startMs = points.first.timestamp.millisecondsSinceEpoch;
    final endMs = points.last.timestamp.millisecondsSinceEpoch;
    final spanMs = math.max(1, endMs - startMs);

    final powers = points.map((point) => point.powerW).whereType<double>();
    final currents = points.map((point) => point.currentMa).whereType<double>();
    final temperatures =
        points.map((point) => point.temperatureC).whereType<double>();

    final maxPower = powers.isEmpty ? 1.0 : math.max(1.0, powers.reduce(math.max));
    final maxCurrent =
        currents.isEmpty ? 1.0 : math.max(1.0, currents.reduce(math.max));
    final tempList = temperatures.toList(growable: false);
    final minTemp = tempList.isEmpty ? 20.0 : tempList.reduce(math.min) - 1.0;
    final maxTemp = tempList.isEmpty
        ? 50.0
        : math.max(minTemp + 5.0, tempList.reduce(math.max) + 1.0);

    double xFor(ChargingCurvePoint point) {
      final elapsed = point.timestamp.millisecondsSinceEpoch - startMs;
      return (elapsed / spanMs).clamp(0.0, 1.0) * size.width;
    }

    Path buildPath(double? Function(ChargingCurvePoint point) valueFor) {
      final path = Path();
      var started = false;
      for (final point in points) {
        final value = valueFor(point);
        if (value == null) {
          started = false;
          continue;
        }
        final normalized = value.clamp(0.0, 1.0);
        final offset = Offset(
          xFor(point),
          size.height - normalized * size.height,
        );
        if (!started) {
          path.moveTo(offset.dx, offset.dy);
          started = true;
        } else {
          path.lineTo(offset.dx, offset.dy);
        }
      }
      return path;
    }

    void draw(Path path, Color color, [double width = 2.2]) {
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = width
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    draw(
      buildPath((point) => point.level / 100.0),
      levelColor,
      2.8,
    );
    draw(
      buildPath((point) => point.powerW == null ? null : point.powerW! / maxPower),
      powerColor,
    );
    draw(
      buildPath(
        (point) => point.temperatureC == null
            ? null
            : (point.temperatureC! - minTemp) / (maxTemp - minTemp),
      ),
      temperatureColor,
    );
    draw(
      buildPath(
        (point) => point.currentMa == null
            ? null
            : point.currentMa!.abs() / maxCurrent,
      ),
      currentColor,
    );
  }

  @override
  bool shouldRepaint(covariant _ChargingCurvePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.levelColor != levelColor ||
        oldDelegate.powerColor != powerColor ||
        oldDelegate.temperatureColor != temperatureColor ||
        oldDelegate.currentColor != currentColor ||
        oldDelegate.gridColor != gridColor;
  }
}
