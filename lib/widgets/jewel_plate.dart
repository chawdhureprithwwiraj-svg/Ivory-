import 'dart:math' as math;

import 'package:flutter/material.dart';

/// ============================================================
/// IVORY - THE JEWEL PLATE
///
/// A card cut like a gem, for the Early Door and the Private Line on
/// Home: a body of banded, deep or bright colour whose bands drift
/// slowly (or, for a foil, travel all the way round); a glassy gloss
/// over the upper half; a bevelled edge (light above, shade below); a
/// rim of light that circles the card; a streak of light that sweeps
/// across now and then; and a few sparkles spread evenly. All of it is
/// gentle and slow. Pure painting. No images, no sound.
/// ============================================================
class JewelPlate extends StatefulWidget {
  const JewelPlate({
    super.key,
    required this.child,
    required this.colors,
    required this.rim,
    required this.spark,
    required this.shade,
    this.stops,
    this.padding = const EdgeInsets.fromLTRB(14, 14, 16, 14),
    this.radius = 22,
    this.foil = false,
  });

  final Widget child;

  /// The bands of the body. For a [foil] the last colour equals the first.
  final List<Color> colors;
  final List<double>? stops;

  /// The colour of the lit rim, of the sparkles, and of the shade/shadow.
  final Color rim;
  final Color spark;
  final Color shade;
  final EdgeInsets padding;
  final double radius;

  /// A foil: the bands travel right round the card (a holographic look).
  final bool foil;

  @override
  State<JewelPlate> createState() => _JewelPlateState();
}

class _JewelPlateState extends State<JewelPlate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat();

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
            color: widget.shade.withValues(alpha: 0.42),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: widget.rim.withValues(alpha: 0.22),
            blurRadius: 16,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r),
        child: AnimatedBuilder(
          animation: _c,
          builder: (BuildContext context, Widget? kid) {
            final double t = _c.value;
            final double ang = widget.foil
                ? t * math.pi * 2
                : math.sin(t * math.pi * 2) * 0.2;
            return Stack(
              children: <Widget>[
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: widget.colors,
                        stops: widget.stops,
                        transform: GradientRotation(ang),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _JewelPainter(
                        t: t,
                        radius: r,
                        rim: widget.rim,
                        spark: widget.spark,
                        shade: widget.shade,
                      ),
                    ),
                  ),
                ),
                kid!,
              ],
            );
          },
          child: Padding(padding: widget.padding, child: widget.child),
        ),
      ),
    );
  }
}

class _JewelPainter extends CustomPainter {
  _JewelPainter({
    required this.t,
    required this.radius,
    required this.rim,
    required this.spark,
    required this.shade,
  });

  final double t;
  final double radius;
  final Color rim;
  final Color spark;
  final Color shade;

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
    canvas.save();
    canvas.clipRRect(body);

    // The glassy gloss over the upper half.
    final Rect up = Rect.fromLTWH(0, 0, w, h * 0.5);
    canvas.drawRect(
      up,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            const Color(0xFFFFFFFF).withValues(alpha: 0.34),
            const Color(0xFFFFFFFF).withValues(alpha: 0.06),
            const Color(0x00FFFFFF),
          ],
          stops: const <double>[0, 0.62, 1],
        ).createShader(up),
    );
    // The shade rising from the bottom edge, and the bright top line.
    final Rect lo = Rect.fromLTWH(0, h * 0.8, w, h * 0.2);
    canvas.drawRect(
      lo,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            shade.withValues(alpha: 0),
            shade.withValues(alpha: 0.4),
          ],
        ).createShader(lo),
    );
    canvas.drawLine(
      Offset(radius * 0.7, 2.4),
      Offset(w - radius * 0.7, 2.4),
      Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.8)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );

    // The streak of light, once per cycle.
    final double p = (t / 0.4).clamp(0.0, 1.0).toDouble();
    if (p < 1) {
      final double bw = w * 0.28;
      final double x = -bw + (w + bw * 2) * p;
      final Rect band = Rect.fromLTWH(x, -h, bw, h * 3);
      canvas.save();
      canvas.translate(w / 2, h / 2);
      canvas.rotate(0.38);
      canvas.translate(-w / 2, -h / 2);
      canvas.drawRect(
        band,
        Paint()
          ..shader = LinearGradient(
            colors: <Color>[
              const Color(0x00FFFFFF),
              const Color(0xFFFFFFFF).withValues(alpha: 0.5),
              const Color(0x00FFFFFF),
            ],
          ).createShader(band),
      );
      canvas.restore();
    }

    // Sparkles: one in each cell of a loose 4 x 2 grid.
    final Paint dot = Paint();
    final Paint line = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.0;
    for (int i = 0; i < 8; i++) {
      final int cx = i % 4;
      final int cy = i ~/ 4;
      final double x = w * (cx + 0.2 + 0.6 * _h(i + 3)) / 4;
      final double y = h * (cy + 0.2 + 0.6 * _h(i + 31)) / 2;
      final double ph = (t * (2 + i % 3) + _h(i + 77)) % 1.0;
      final double tw = math.pow(
        math.max(0.0, math.sin(math.pi * ph)),
        6,
      ).toDouble();
      if (tw < 0.1) continue;
      final double len = 2.2 + 4.5 * tw;
      line.color = spark.withValues(alpha: 0.9 * tw);
      canvas.drawLine(Offset(x - len, y), Offset(x + len, y), line);
      canvas.drawLine(Offset(x, y - len), Offset(x, y + len), line);
      dot.color = const Color(0xFFFFFFFF).withValues(alpha: tw);
      canvas.drawCircle(Offset(x, y), 0.8 + 0.8 * tw, dot);
    }
    canvas.restore();

    // The rim: a thin line of light with a bright bead that circles it.
    canvas.drawRRect(
      body.deflate(0.9),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..shader = SweepGradient(
          colors: <Color>[
            rim.withValues(alpha: 0.5),
            const Color(0xFFFFFFFF).withValues(alpha: 0.95),
            rim.withValues(alpha: 0.5),
            rim.withValues(alpha: 0.28),
            rim.withValues(alpha: 0.5),
          ],
          stops: const <double>[0, 0.12, 0.26, 0.6, 1],
          transform: GradientRotation(t * math.pi * 2),
        ).createShader(all),
    );
  }

  @override
  bool shouldRepaint(_JewelPainter o) => o.t != t;
}

// END OF FILE - lib/widgets/jewel_plate.dart
