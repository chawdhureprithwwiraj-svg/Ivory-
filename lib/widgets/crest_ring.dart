import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The ring: a faint track, the climb to the next rung in the four
/// colours of the worn bell set, and a small light running round.
class CrestRingPainter extends CustomPainter {
  CrestRingPainter({required this.colors, required this.fraction, required this.t});

  final List<Color> colors;
  final double fraction;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);
    final double r = math.min(size.width, size.height) / 2 - 7;
    final Rect rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..color = const Color(0x26FFFFFF),
    );
    final double sweep = 2 * math.pi * fraction.clamp(0.03, 1.0);
    final List<Color> g = <Color>[...colors, colors.first];
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: 0,
          endAngle: sweep,
          colors: g,
          transform: const GradientRotation(-math.pi / 2),
        ).createShader(rect),
    );
    final double a = -math.pi / 2 + 2 * math.pi * t;
    final Offset dot = c + Offset(math.cos(a), math.sin(a)) * r;
    canvas.drawCircle(
      dot,
      4.5,
      Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.85)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );
    canvas.drawCircle(dot, 2.2, Paint()..color = const Color(0xFFFFFFFF));
  }

  @override
  bool shouldRepaint(CrestRingPainter o) =>
      o.t != t || o.fraction != fraction || o.colors != colors;
}

// END OF FILE - lib/widgets/crest_ring.dart
