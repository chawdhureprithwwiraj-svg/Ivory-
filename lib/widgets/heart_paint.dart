import 'dart:math' as math;
import 'dart:typed_data' show Float64List;

import 'package:flutter/material.dart';

import 'gold_fx.dart';
import 'heart_decor.dart';

/// ============================================================
/// IVORY - THE GOLDEN HEART, PAINTED
///
/// A glass heart of deep burgundy that fills with liquid gold as the
/// day's points arrive: a rolling surface, rising bubbles, a bevelled
/// rim, a bright highlight, a sheen that sweeps across it once it is
/// lit. Tier jewellery (embers, flame, rays, stars, crown, ring) is in
/// heart_decor.dart. Wrap it in GoldTilt for depth.
/// ============================================================

/// The heart outline inside [r].
Path heartPath(Rect r) {
  final double w = r.width;
  final double h = r.height;
  Offset p(double x, double y) => Offset(r.left + w * x, r.top + h * y);
  return Path()
    ..moveTo(p(0.5, 0.93).dx, p(0.5, 0.93).dy)
    ..cubicTo(
      p(0.30, 0.80).dx,
      p(0.30, 0.80).dy,
      p(0.02, 0.58).dx,
      p(0.02, 0.58).dy,
      p(0.02, 0.30).dx,
      p(0.02, 0.30).dy,
    )
    ..cubicTo(
      p(0.02, 0.10).dx,
      p(0.02, 0.10).dy,
      p(0.17, 0.04).dx,
      p(0.17, 0.04).dy,
      p(0.28, 0.04).dx,
      p(0.28, 0.04).dy,
    )
    ..cubicTo(
      p(0.40, 0.04).dx,
      p(0.40, 0.04).dy,
      p(0.47, 0.12).dx,
      p(0.47, 0.12).dy,
      p(0.5, 0.22).dx,
      p(0.5, 0.22).dy,
    )
    ..cubicTo(
      p(0.53, 0.12).dx,
      p(0.53, 0.12).dy,
      p(0.60, 0.04).dx,
      p(0.60, 0.04).dy,
      p(0.72, 0.04).dx,
      p(0.72, 0.04).dy,
    )
    ..cubicTo(
      p(0.83, 0.04).dx,
      p(0.83, 0.04).dy,
      p(0.98, 0.10).dx,
      p(0.98, 0.10).dy,
      p(0.98, 0.30).dx,
      p(0.98, 0.30).dy,
    )
    ..cubicTo(
      p(0.98, 0.58).dx,
      p(0.98, 0.58).dy,
      p(0.70, 0.80).dx,
      p(0.70, 0.80).dy,
      p(0.5, 0.93).dx,
      p(0.5, 0.93).dy,
    )
    ..close();
}

class HeartPainter extends CustomPainter {
  HeartPainter({
    required this.fill,
    required this.t,
    this.tier = 0,
    this.compact = false,
  });

  /// 0 (empty glass) to 1 (full gold).
  final double fill;

  /// 0 to 1, repeating: drives every movement.
  final double t;
  final int tier;

  /// Small icon: no jewellery, no bubbles, no sweep.
  final bool compact;

  @override
  void paint(Canvas c, Size s) {
    final double side = math.min(s.width, s.height) * (compact ? 0.92 : 0.70);
    final Rect h = Rect.fromCenter(
      center: Offset(s.width / 2, s.height * (compact ? 0.5 : 0.53)),
      width: side,
      height: side * 0.94,
    );
    final Path path = heartPath(h);
    if (!compact) HeartDecor.back(c, h, t, tier);

    c.drawPath(
      path.shift(Offset(0, h.height * 0.05)),
      Paint()
        ..color = const Color(0xFF4A0E17).withValues(alpha: 0.38)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, h.width * 0.05),
    );

    // Glass.
    c.drawPath(
      path,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.4),
          radius: 1.0,
          colors: <Color>[
            Color(0xFF8E2A42),
            Color(0xFF661528),
            Color(0xFF4A0E17),
          ],
        ).createShader(h),
    );

    c.save();
    c.clipPath(path);
    _gold(c, h);
    // Roundness: soft shade toward the edges.
    c.drawRect(
      h.inflate(2),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.25, -0.35),
          radius: 0.95,
          colors: <Color>[
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: 0.0),
            const Color(0xFF4A0E17).withValues(alpha: 0.40),
          ],
          stops: const <double>[0, 0.55, 1],
        ).createShader(h),
    );
    if (!compact) _sweep(c, h);
    c.restore();

    _highlight(c, h);
    _rim(c, h, path);
    if (!compact) HeartDecor.front(c, h, t, tier);
  }

  void _gold(Canvas c, Rect h) {
    if (fill <= 0.001) return;
    final double bottom = h.top + h.height * 0.96;
    final double top = h.top + h.height * 0.02;
    final double y = bottom - (bottom - top) * fill;
    final bool full = fill >= 0.999;
    final double amp = full ? 0 : h.height * 0.018;
    Path wave(double phase, double a) {
      final Path p = Path()..moveTo(h.left - 4, bottom + 4);
      p.lineTo(h.left - 4, y);
      for (double x = h.left - 4; x <= h.right + 4; x += 3) {
        final double k = (x - h.left) / h.width;
        p.lineTo(x, y + math.sin(k * math.pi * 3 + phase) * a);
      }
      p.lineTo(h.right + 4, bottom + 4);
      p.close();
      return p;
    }

    final double ph = t * math.pi * 2;
    c.drawPath(
      wave(ph + 1.7, amp * 1.2),
      Paint()..color = GoldTones.light.withValues(alpha: 0.55),
    );
    c.drawPath(
      wave(ph * 1.0, amp),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            GoldTones.shine,
            GoldTones.light,
            GoldTones.mid,
            GoldTones.deep,
            GoldTones.rim,
          ],
          stops: <double>[0, 0.22, 0.5, 0.82, 1],
        ).createShader(h),
    );
    if (!full) {
      final Path line = Path();
      for (double x = h.left; x <= h.right; x += 3) {
        final double k = (x - h.left) / h.width;
        final double yy = y + math.sin(k * math.pi * 3 + ph) * amp;
        x == h.left ? line.moveTo(x, yy) : line.lineTo(x, yy);
      }
      c.drawPath(
        line,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.2, h.width * 0.012)
          ..color = GoldTones.shine.withValues(alpha: 0.9),
      );
    }
    if (compact) return;
    for (int i = 0; i < 6; i++) {
      final double q = (t * (0.7 + 0.12 * i) + i / 6) % 1.0;
      final double bx =
          h.left +
          h.width * (0.2 + 0.12 * i) +
          math.sin(q * 8 + i) * h.width * 0.015;
      final double by = bottom - q * (bottom - y);
      if (by < y + 3) continue;
      c.drawCircle(
        Offset(bx, by),
        h.width * (0.008 + 0.004 * (i % 3)),
        Paint()..color = GoldTones.shine.withValues(alpha: 0.55 * (1 - q)),
      );
    }
  }

  void _sweep(Canvas c, Rect h) {
    if (fill < 0.999) return;
    final double q = (t * 1.5) % 1.5;
    if (q > 1) return;
    c.save();
    c.translate(h.center.dx, h.center.dy);
    c.rotate(-0.55);
    final double x = -h.width * 1.1 + q * h.width * 2.2;
    final Rect band = Rect.fromLTWH(x, -h.height, h.width * 0.26, h.height * 2);
    c.drawRect(
      band,
      Paint()
        ..shader = LinearGradient(
          colors: <Color>[
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: 0.5),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(band),
    );
    c.restore();
  }

  void _highlight(Canvas c, Rect h) {
    final double w = h.width;
    Offset p(double x, double y) =>
        Offset(h.left + w * x, h.top + h.height * y);
    final Path arc = Path()
      ..moveTo(p(0.10, 0.36).dx, p(0.10, 0.36).dy)
      ..cubicTo(
        p(0.07, 0.22).dx,
        p(0.07, 0.22).dy,
        p(0.15, 0.12).dx,
        p(0.15, 0.12).dy,
        p(0.29, 0.11).dx,
        p(0.29, 0.11).dy,
      );
    c.drawPath(
      arc,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = w * 0.035
        ..color = Colors.white.withValues(alpha: 0.78)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.008),
    );
    c.drawCircle(
      p(0.36, 0.11),
      w * 0.012,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
    // A faint reflected glint low on the right.
    final Path glint = Path()
      ..moveTo(p(0.90, 0.44).dx, p(0.90, 0.44).dy)
      ..cubicTo(
        p(0.88, 0.56).dx,
        p(0.88, 0.56).dy,
        p(0.80, 0.66).dx,
        p(0.80, 0.66).dy,
        p(0.70, 0.74).dx,
        p(0.70, 0.74).dy,
      );
    c.drawPath(
      glint,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = w * 0.014
        ..color = Colors.white.withValues(alpha: 0.28),
    );
  }

  void _rim(Canvas c, Rect h, Path path) {
    c.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.4, h.width * 0.034)
        ..strokeJoin = StrokeJoin.round
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            GoldTones.shine,
            GoldTones.mid,
            GoldTones.rim,
            GoldTones.mid,
            GoldTones.light,
          ],
        ).createShader(h),
    );
    const double k = 0.945;
    final Float64List m = Float64List.fromList(<double>[
      k, 0, 0, 0, //
      0, k, 0, 0, //
      0, 0, 1, 0, //
      h.center.dx * (1 - k), h.center.dy * (1 - k), 0, 1,
    ]);
    c.drawPath(
      path.transform(m),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.6, h.width * 0.008)
        ..color = GoldTones.shine.withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(HeartPainter o) =>
      o.fill != fill || o.t != t || o.tier != tier || o.compact != compact;
}

/// The heart as a widget: it breathes by itself.
class HeartPaint extends StatefulWidget {
  const HeartPaint({
    super.key,
    required this.fill,
    this.tier = 0,
    this.size = 200,
    this.compact = false,
    this.period = const Duration(milliseconds: 4200),
  });

  final double fill;
  final int tier;
  final double size;
  final bool compact;
  final Duration period;

  @override
  State<HeartPaint> createState() => _HeartPaintState();
}

class _HeartPaintState extends State<HeartPaint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.period,
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _c,
          builder: (BuildContext _, Widget? __) => CustomPaint(
            painter: HeartPainter(
              fill: widget.fill,
              t: _c.value,
              tier: widget.tier,
              compact: widget.compact,
            ),
          ),
        ),
      ),
    );
  }
}

// END OF FILE - lib/widgets/heart_paint.dart
