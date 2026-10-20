import 'dart:math' as math;

import 'package:flutter/material.dart';


/// ============================================================
/// IVORY - THE GOLD PLATE
///
/// A slab of very rich, high-gloss metallic gold for the Golden
/// Knock-off card on Home: a banded gold metal, a bright polished
/// rim, a raised edge (light on top, shadow below), a glassy gloss
/// over the upper half, a streak of light that sweeps across now
/// and then, and a few sparkles spread evenly (never crowded).
///
/// Writing on the plate is deep burgundy. Parts that are made of
/// gold themselves (the button, the seals, the ring) sit inside a
/// burgundy well so they never vanish into the gold.
///
/// Pure painting. No images, no sound, nothing stored.
/// ============================================================
class GoldPlate extends StatefulWidget {
  const GoldPlate({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(18, 18, 18, 18),
    this.radius = 26,
    this.calm = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;

  /// A quiet version: no sweep, no sparkles.
  final bool calm;

  @override
  State<GoldPlate> createState() => _GoldPlateState();
}

class _GoldPlateState extends State<GoldPlate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 6000),
  );

  @override
  void initState() {
    super.initState();
    if (!widget.calm) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double r = widget.radius;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF96640A).withValues(alpha: 0.5),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: const Color(0xFFFFD34D).withValues(alpha: 0.35),
            blurRadius: 18,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r),
        child: Stack(
          children: <Widget>[
            // The metal: bands of light and dark gold, like polished leaf.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(r),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      Color(0xFFFFF3B0),
                      Color(0xFFF7CF45),
                      Color(0xFFD9A011),
                      Color(0xFFFFE98A),
                      Color(0xFFC48A08),
                      Color(0xFFF6CB3C),
                      Color(0xFFB97F06),
                    ],
                    stops: <double>[0, 0.14, 0.3, 0.46, 0.62, 0.78, 1],
                  ),
                  border: Border.all(color: const Color(0xFFFFF0A0), width: 2),
                ),
              ),
            ),
            // The raised edge, the gloss and the sweep of light.
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (BuildContext context, Widget? _) => CustomPaint(
                    painter: _PlatePainter(
                      t: widget.calm ? 0.9 : _c.value,
                      radius: r,
                      calm: widget.calm,
                    ),
                  ),
                ),
              ),
            ),
            Padding(padding: widget.padding, child: widget.child),
          ],
        ),
      ),
    );
  }
}

class _PlatePainter extends CustomPainter {
  _PlatePainter({required this.t, required this.radius, required this.calm});

  final double t;
  final double radius;
  final bool calm;

  static double _h(int n) {
    final double s = math.sin(n * 12.9898 + 78.233) * 43758.5453;
    return s - s.floorToDouble();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Rect all = Offset.zero & size;
    final RRect body = RRect.fromRectAndRadius(all, Radius.circular(radius));

    // Gloss: a glassy light over the upper half.
    canvas.save();
    canvas.clipRRect(body);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h * 0.5),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            const Color(0xFFFFFFFF).withValues(alpha: 0.5),
            const Color(0xFFFFFFFF).withValues(alpha: 0.08),
            const Color(0xFFFFFFFF).withValues(alpha: 0),
          ],
          stops: const <double>[0, 0.6, 1],
        ).createShader(Rect.fromLTWH(0, 0, w, h * 0.5)),
    );

    // The raised edge: a bright line on top, a warm shadow rising from
    // the bottom, so the plate looks thick.
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.82, w, h * 0.18),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            const Color(0xFF784600).withValues(alpha: 0),
            const Color(0xFF784600).withValues(alpha: 0.38),
          ],
        ).createShader(Rect.fromLTWH(0, h * 0.82, w, h * 0.18)),
    );
    canvas.drawLine(
      Offset(radius * 0.7, 2.6),
      Offset(w - radius * 0.7, 2.6),
      Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.85)
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );

    if (!calm) {
      // The streak of light: crosses the plate once per cycle.
      final double p = (t / 0.55).clamp(0.0, 1.0).toDouble();
      if (p < 1) {
        final double bw = w * 0.3;
        final double x = -bw + (w + bw * 2) * p;
        final Rect band = Rect.fromLTWH(x, -h, bw, h * 3);
        canvas.save();
        canvas.translate(w / 2, h / 2);
        canvas.rotate(0.36);
        canvas.translate(-w / 2, -h / 2);
        canvas.drawRect(
          band,
          Paint()
            ..shader = LinearGradient(
              colors: <Color>[
                const Color(0xFFFFFFFF).withValues(alpha: 0),
                const Color(0xFFFFFFFF).withValues(alpha: 0.7),
                const Color(0xFFFFFFFF).withValues(alpha: 0),
              ],
            ).createShader(band),
        );
        canvas.restore();
      }

      // A few sparkles, one in each cell of a loose grid so they are
      // spread evenly and never crowd.
      const int cols = 4;
      const int rows = 3;
      final Paint dot = Paint();
      final Paint line = Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.1;
      for (int i = 0; i < cols * rows; i++) {
        final int cx = i % cols;
        final int cy = i ~/ cols;
        final double x = w * (cx + 0.2 + 0.6 * _h(i + 1)) / cols;
        final double y = h * (cy + 0.2 + 0.6 * _h(i + 40)) / rows;
        final double ph = (t * (1 + i % 2) + _h(i + 90)) % 1.0;
        final double tw = math.pow(
          math.max(0.0, math.sin(math.pi * ph)),
          5,
        ).toDouble();
        if (tw < 0.08) continue;
        final double len = 2.5 + 5 * tw;
        line.color = const Color(0xFFFFFFFF).withValues(alpha: 0.9 * tw);
        canvas.drawLine(Offset(x - len, y), Offset(x + len, y), line);
        canvas.drawLine(Offset(x, y - len), Offset(x, y + len), line);
        dot.color = const Color(0xFFFFFFFF).withValues(alpha: tw);
        canvas.drawCircle(Offset(x, y), 0.9 + 0.9 * tw, dot);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PlatePainter o) => o.t != t || o.calm != calm;
}

/// A small burgundy well for gold-made parts that sit on the gold plate.
class GoldWell extends StatelessWidget {
  const GoldWell({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(5),
    this.radius = 18,
    this.circle = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF7A1F33), Color(0xFF4A0E17)],
        ),
        border: Border.all(color: const Color(0xFFFFE27A), width: 1.4),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF4A0E17).withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

// END OF FILE - lib/widgets/gold_plate.dart
