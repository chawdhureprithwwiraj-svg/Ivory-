import 'dart:math' as math;

import 'package:flutter/material.dart';

/// ============================================================
/// IVORY - THE GOLDEN RUPEE COIN, TURNING
///
/// Recreates the owner's golden rupee (`golden_kick_off_animation.png`)
/// in paint, so it can really turn: a thick coin of polished gold with
/// a raised outer rim, a sunken face with a deep, embossed rupee sign
/// that glows amber where it is cut, and a burnished edge with bands of
/// light. It turns slowly about its upright axis, CLOCKWISE seen from
/// above (the face nearest you sweeps to the left), showing its edge
/// and then the same rupee on its other side. A band of light crosses
/// the face as it turns and a glint flashes on the rim. No images.
/// ============================================================
class RupeeCoin extends StatefulWidget {
  const RupeeCoin({super.key, this.size = 58});

  final double size;

  @override
  State<RupeeCoin> createState() => _RupeeCoinState();
}

class _RupeeCoinState extends State<RupeeCoin>
    with SingleTickerProviderStateMixin {
  // One full turn takes six seconds.
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
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
          builder: (BuildContext _, Widget? __) =>
              CustomPaint(painter: _CoinPainter(_c.value)),
        ),
      ),
    );
  }
}

class _CoinPainter extends CustomPainter {
  _CoinPainter(this.t);

  final double t;

  static final Map<int, TextPainter> _glyphs = <int, TextPainter>{};

  static TextPainter _glyph(Color c) {
    return _glyphs.putIfAbsent(c.toARGB32(), () {
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: '\u20B9',
          style: TextStyle(
            color: c,
            fontSize: 100,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      return tp;
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width;
    final double r = s * 0.42;
    final double th = r * 0.3;
    // Clockwise seen from above = a negative turn about the upright.
    final double a = -t * math.pi * 2;
    final double cs = math.cos(a);
    final double sn = math.sin(a);
    final double rx = math.max(r * 0.03, r * cs.abs());
    final Offset c = Offset(s / 2, s / 2);
    final double xf = c.dx + th / 2 * sn;
    final double xb = c.dx - th / 2 * sn;
    final double x0 = math.min(xf, xb) - rx;
    final double x1 = math.max(xf, xb) + rx;
    final Rect all = Rect.fromLTRB(x0, c.dy - r, x1, c.dy + r);

    // A warm glow behind the coin.
    canvas.drawCircle(
      c,
      s * 0.5,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            const Color(0xFFFFC21A).withValues(alpha: 0.32),
            const Color(0x00FFC21A),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: s * 0.5)),
    );

    // The edge: slices of the coin between its two faces.
    const int n = 14;
    final Paint wall = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: const <Color>[
          Color(0xFF8F5B00),
          Color(0xFFE59A10),
          Color(0xFFFFE27A),
          Color(0xFFD39000),
          Color(0xFFFFD34D),
          Color(0xFF9A6208),
        ],
        stops: const <double>[0, 0.16, 0.34, 0.55, 0.78, 1],
      ).createShader(all);
    final Paint wallShade = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          const Color(0xFFFFFFFF).withValues(alpha: 0.38),
          const Color(0x00FFFFFF),
          const Color(0xFFB8552F).withValues(alpha: 0.0),
          const Color(0xFF8F5B00).withValues(alpha: 0.4),
        ],
        stops: const <double>[0, 0.35, 0.6, 1],
      ).createShader(all);
    for (final Paint p in <Paint>[wall, wallShade]) {
      for (int i = 0; i <= n; i++) {
        final double x = xb + (xf - xb) * i / n;
        canvas.drawOval(Rect.fromCenter(center: Offset(x, c.dy), width: rx * 2, height: r * 2), p);
      }
    }

    // The visible face: the front one while cos > 0, else the back one.
    final double fx = cs >= 0 ? xf : xb;
    final Offset fc = Offset(fx, c.dy);
    final Rect face = Rect.fromCenter(center: fc, width: rx * 2, height: r * 2);
    final double lit = 0.82 + 0.18 * cs.abs();

    // The raised outer rim.
    canvas.drawOval(
      face,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFFFF3B0),
            Color(0xFFF5B800),
            Color(0xFFC98600),
            Color(0xFFFFD54A),
          ],
          stops: <double>[0, 0.35, 0.7, 1],
        ).createShader(face),
    );
    canvas.drawOval(
      face,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, r * 0.035)
        ..color = const Color(0xFFFFF7CF).withValues(alpha: 0.9),
    );

    // The sunken face inside the rim.
    final Rect inner = Rect.fromCenter(
      center: fc,
      width: rx * 2 * 0.8,
      height: r * 2 * 0.8,
    );
    canvas.drawOval(
      inner,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFC98600),
            Color(0xFFF2AC10),
            Color(0xFFFFD34D),
          ],
          stops: <double>[0, 0.5, 1],
        ).createShader(inner),
    );
    canvas.drawOval(
      inner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, r * 0.06)
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF8F5B00), Color(0xFFFFE27A)],
        ).createShader(inner),
    );

    // The rupee sign: cut deep, glowing amber where it is cut.
    final double gs = r * 1.02 / 100;
    final TextPainter body = _glyph(const Color(0xFFF3B21B));
    final TextPainter glow = _glyph(const Color(0xFFFF8A00));
    final TextPainter hi = _glyph(const Color(0xFFFFF0A0));
    final TextPainter dk = _glyph(const Color(0xFF9A5A00));
    void sign(TextPainter tp, double dx, double dy, {double alpha = 1}) {
      canvas.save();
      canvas.translate(fc.dx + dx * r * cs.abs(), fc.dy + dy * r);
      canvas.scale(gs * cs.abs().clamp(0.02, 1.0).toDouble(), gs);
      canvas.translate(-tp.width / 2, -tp.height / 2);
      if (alpha < 1) {
        canvas.saveLayer(
          Rect.fromLTWH(0, 0, tp.width, tp.height),
          Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: alpha),
        );
        tp.paint(canvas, Offset.zero);
        canvas.restore();
      } else {
        tp.paint(canvas, Offset.zero);
      }
      canvas.restore();
    }

    sign(glow, 0.07, 0.09, alpha: 0.8);
    sign(dk, 0.04, 0.05);
    sign(hi, -0.025, -0.03, alpha: 0.9);
    sign(body, 0, 0);

    // A band of light across the face, and a glint on the rim.
    canvas.save();
    canvas.clipPath(Path()..addOval(face));
    final double p = -0.3 + 1.6 * ((t * 2) % 1.0);
    double st(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);
    canvas.drawRect(
      face,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            const Color(0x00FFFFFF),
            const Color(0xFFFFFFFF).withValues(alpha: 0.5 * cs.abs()),
            const Color(0x00FFFFFF),
          ],
          stops: <double>[st(p - 0.12), st(p), st(p + 0.12)],
        ).createShader(face),
    );
    // The face darkens a little as it turns away.
    canvas.drawOval(
      face,
      Paint()..color = const Color(0xFF8F5B00).withValues(alpha: 1 - lit),
    );
    canvas.restore();

    final double gl = math.pow(
      math.max(0.0, math.sin(math.pi * 2 * (t * 2 + 0.1))),
      8,
    ).toDouble();
    if (gl > 0.05 && cs.abs() > 0.25) {
      final Offset g = Offset(fc.dx - rx * 0.62, fc.dy - r * 0.66);
      final Paint sp = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.95 * gl)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;
      final double len = s * (0.06 + 0.1 * gl);
      canvas.drawLine(g.translate(-len, 0), g.translate(len, 0), sp);
      canvas.drawLine(g.translate(0, -len), g.translate(0, len), sp);
    }
  }

  @override
  bool shouldRepaint(_CoinPainter o) => o.t != t;
}

// END OF FILE - lib/widgets/rupee_coin.dart
