import 'dart:math' as math;

import 'package:flutter/material.dart';

/// ============================================================
/// IVORY - THE COLOUR CRACKERS (for the Golden Knock-off card)
///
/// The old firecracker animation, built to show on GOLD: rockets climb
/// on a spark trail and burst into balls, rings and crackling showers
/// of ruby, magenta, emerald, fire-orange and plum sparks, each with a
/// white-hot heart and a thin deep-burgundy edge, so every spark reads
/// clearly against the gold. A soft white flash marks each burst. No
/// blue anywhere. Everything is worked out from the clock: no stored
/// state, no images, no sound. Never takes a touch.
/// ============================================================
class ColorCrackers extends StatefulWidget {
  const ColorCrackers({
    super.key,
    this.rate = 1,
    this.reach = 1,
    this.seed = 4,
  });

  /// Shells per second, relative (1 = a new shell about every 1.5 s).
  final double rate;

  /// Size of each burst, relative.
  final double reach;
  final int seed;

  @override
  State<ColorCrackers> createState() => _ColorCrackersState();
}

class _ColorCrackersState extends State<ColorCrackers>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 100000),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _CrackerPainter(
            _c,
            widget.rate,
            widget.reach,
            widget.seed,
          ),
        ),
      ),
    );
  }
}

const List<List<Color>> _shellColors = <List<Color>>[
  <Color>[Color(0xFFE0143C), Color(0xFFFF6A1A)],
  <Color>[Color(0xFFD81B8A), Color(0xFFFF5C7A)],
  <Color>[Color(0xFF0E9F6A), Color(0xFF9BCB1B)],
  <Color>[Color(0xFFFF4D1A), Color(0xFFE0143C)],
  <Color>[Color(0xFF8E1E8E), Color(0xFFE0268F)],
  <Color>[Color(0xFFC2185B), Color(0xFFFF8A00)],
];

class _CrackerPainter extends CustomPainter {
  _CrackerPainter(this.clock, this.rate, this.reach, this.seed)
    : super(repaint: clock);

  final Animation<double> clock;
  final double rate;
  final double reach;
  final int seed;

  static double _h(int n) {
    final double s = math.sin(n * 12.9898 + 78.233) * 43758.5453;
    return s - s.floorToDouble();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    if (w <= 0 || h <= 0) return;
    final double t = clock.value * 100000;
    final double gap = 1.5 / (rate <= 0 ? 1 : rate);
    const double life = 2.7;
    final int last = (t / gap).floor();
    for (int n = last - 2; n <= last; n++) {
      final double age = t - n * gap;
      if (age < 0 || age > life) continue;
      _shell(canvas, w, h, n, age, life);
    }
  }

  void _shell(Canvas canvas, double w, double h, int n, double age, double life) {
    final int id = n * 7 + seed;
    final double bx = w * (0.14 + 0.72 * _h(id + 1));
    final double by = h * (0.1 + 0.34 * _h(id + 2));
    final List<Color> pal = _shellColors[(n.abs() + seed) % _shellColors.length];
    final int kind = (_h(id + 3) * 3).floor() % 3; // ball, ring, crackle
    const double rise = 0.55;
    final double R = math.min(w, h) * 0.3 * reach;

    final Paint edge = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final Paint ink = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final Paint fill = Paint();

    if (age < rise) {
      // The rocket and its spark trail.
      final double p = age / rise;
      final double e = 1 - math.pow(1 - p, 2).toDouble();
      final double y = h * 1.02 + (by - h * 1.02) * e;
      final double x = bx + math.sin(p * 9 + n) * 3;
      for (int i = 0; i < 9; i++) {
        final double q = i / 9;
        final double ty = y + q * h * 0.16;
        final double a = (1 - q) * 0.9;
        fill.color = Color.lerp(
          const Color(0xFFFF8A00),
          const Color(0xFFE0143C),
          q,
        )!.withValues(alpha: a);
        canvas.drawCircle(
          Offset(x + math.sin(q * 11 + n) * 2, ty),
          1.9 * (1 - q * 0.6),
          fill,
        );
      }
      fill.color = const Color(0xFFFFFFFF);
      canvas.drawCircle(Offset(x, y), 1.8, fill);
      return;
    }

    final double u = ((age - rise) / (life - rise)).clamp(0.0, 1.0).toDouble();
    // The flash at the moment of the burst.
    if (u < 0.18) {
      final double f = 1 - u / 0.18;
      canvas.drawCircle(
        Offset(bx, by),
        R * (0.35 + 0.5 * u / 0.18),
        Paint()
          ..shader = RadialGradient(
            colors: <Color>[
              const Color(0xFFFFFFFF).withValues(alpha: 0.75 * f),
              const Color(0x00FFFFFF),
            ],
          ).createShader(
            Rect.fromCircle(center: Offset(bx, by), radius: R * 0.9),
          ),
      );
    }

    final int count = kind == 1 ? 30 : 38;
    final double ease = 1 - math.pow(1 - u, 2.4).toDouble();
    final double fade = math.pow(1 - u, 1.15).toDouble();
    for (int i = 0; i < count; i++) {
      final int k = id * 53 + i;
      double ang = 6.2832 * i / count + _h(k + 1) * 0.2;
      double depth;
      double sp;
      if (kind == 1) {
        // A ring, tilted a little.
        depth = 0;
        sp = 1;
      } else {
        // A sphere: each spark has a place in 3D, flattened by depth.
        final double z = _h(k + 2) * 2 - 1;
        depth = z;
        sp = 0.5 + 0.5 * math.sqrt(1 - z * z) + 0.2 * _h(k + 3);
      }
      final double dist = R * ease * sp;
      double dx = math.cos(ang) * dist;
      double dy = math.sin(ang) * dist * (kind == 1 ? 0.45 : 1);
      // Gravity: the sparks droop as they die.
      dy += R * 0.55 * u * u;
      final Offset head = Offset(bx + dx, by + dy);
      final double ue = (u - 0.05).clamp(0.0, 1.0).toDouble();
      final double ease2 = 1 - math.pow(1 - ue, 2.4).toDouble();
      final double d2 = R * ease2 * sp;
      final Offset tail = Offset(
        bx + math.cos(ang) * d2,
        by + math.sin(ang) * d2 * (kind == 1 ? 0.45 : 1) + R * 0.55 * ue * ue,
      );
      double a = fade;
      if (kind == 2) {
        // Crackle: each spark flickers out on its own.
        a *= 0.5 + 0.5 * math.sin(age * (22 + 18 * _h(k + 4)) + i);
        a = a.clamp(0.0, 1.0).toDouble();
      }
      if (a < 0.03) continue;
      final Color col = pal[i % 2];
      final double near = 0.75 + 0.25 * (depth + 1) / 2;
      // A thin burgundy edge first, so the spark reads on gold.
      ink
        ..strokeWidth = 3.6 * near
        ..color = const Color(0xFF4A0E17).withValues(alpha: 0.5 * a);
      canvas.drawLine(tail, head, ink);
      edge
        ..strokeWidth = 2.0 * near
        ..color = col.withValues(alpha: a);
      canvas.drawLine(tail, head, edge);
      fill.color = const Color(0xFF4A0E17).withValues(alpha: 0.5 * a);
      canvas.drawCircle(head, 3.0 * near, fill);
      fill.color = col.withValues(alpha: a);
      canvas.drawCircle(head, 2.2 * near, fill);
      fill.color = const Color(0xFFFFFFFF).withValues(alpha: 0.95 * a);
      canvas.drawCircle(head, 0.9 * near, fill);
    }
  }

  @override
  bool shouldRepaint(_CrackerPainter old) => false;
}

// END OF FILE - lib/widgets/color_crackers.dart
