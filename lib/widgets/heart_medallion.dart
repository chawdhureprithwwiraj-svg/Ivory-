import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'dust_ring.dart';
import 'heart_cine.dart';

/// ============================================================
/// IVORY - THE GOLDEN HEART MEDALLION (top bar)
///
/// A small round medallion of deep burgundy holding a crystal heart of
/// gold, with a thick cloud of golden dust circling it clockwise like
/// the rings of Saturn. The higher the member's glow, the richer and
/// denser it becomes. No sound. All painted. No black anywhere.
/// ============================================================
class HeartMedallion extends StatefulWidget {
  const HeartMedallion({
    super.key,
    required this.fill,
    required this.tier,
    this.lit = false,
    this.size = 44,
  });

  final double fill;
  final int tier;
  final bool lit;
  final double size;

  static double heatOf(int tier, double fill, bool lit) {
    final int tt = tier < 0 ? 0 : (tier > 8 ? 8 : tier);
    double h = 0.3 + 0.45 * tt / 8.0 + 0.15 * Cine.clamp01(fill);
    if (lit) h += 0.1;
    return Cine.clamp01(h);
  }

  @override
  State<HeartMedallion> createState() => _HeartMedallionState();
}

class _HeartMedallionState extends State<HeartMedallion>
    with SingleTickerProviderStateMixin {
  // One turn of the dust takes eight seconds.
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double heat = HeartMedallion.heatOf(
      widget.tier,
      widget.fill,
      widget.lit,
    );
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _c,
          builder: (BuildContext _, Widget? __) => CustomPaint(
            painter: _MedallionPainter(t: _c.value, heat: heat),
          ),
        ),
      ),
    );
  }
}

class _MedallionPainter extends CustomPainter {
  _MedallionPainter({required this.t, required this.heat});

  final double t;
  final double heat;

  static const List<Color> _ramp = <Color>[
    Color(0xFF8A5008),
    Color(0xFFB8740A),
    Color(0xFFE59A10),
    Color(0xFFFFC21A),
    Color(0xFFFFDF70),
    Color(0xFFFFF3C4),
  ];

  static Color _tone(double b) {
    final double x = Cine.clamp01(b) * (_ramp.length - 1);
    int i = x.floor();
    if (i > _ramp.length - 2) i = _ramp.length - 2;
    return Color.lerp(_ramp[i], _ramp[i + 1], x - i)!;
  }

  static Offset _pt(double th) {
    final double s = math.sin(th);
    final double x = s * s * s;
    final double y =
        (13 * math.cos(th) -
            5 * math.cos(2 * th) -
            2 * math.cos(3 * th) -
            math.cos(4 * th)) /
        16;
    return Offset(x, -y - 0.095);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width;
    final Offset c = Offset(s / 2, s / 2);
    final double rad = s / 2 - 1.5;
    final Rect disc = Rect.fromCircle(center: c, radius: rad);

    // The burgundy medallion.
    canvas.drawCircle(
      c,
      rad,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.4),
          radius: 1.0,
          colors: <Color>[
            Color(0xFF8E2C44),
            Color(0xFF5C1222),
            Color(0xFF4A0E17),
          ],
          stops: <double>[0, 0.62, 1],
        ).createShader(disc),
    );
    canvas.save();
    canvas.clipPath(Path()..addOval(disc));

    // A warm glow behind the heart.
    canvas.drawCircle(
      c,
      rad * 0.95,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            const Color(0xFFFFC21A).withValues(alpha: 0.18 + 0.3 * heat),
            const Color(0xFFFFC21A).withValues(alpha: 0),
          ],
        ).createShader(disc),
    );

    final double beat = Cine.beat(Cine.fract(t * 6));
    final int n = (170 + 150 * heat).round();
    final double rx = rad * 0.97;
    final double ry = rad * 0.34;
    const double tilt = 0.2;

    DustRing.paint(
      canvas,
      center: c,
      rx: rx,
      ry: ry,
      tilt: tilt,
      t: t,
      n: n,
      front: false,
      alpha: 0.8,
      grain: 0.9,
      thick: 0.26,
      haze: 1,
    );

    // The crystal heart.
    final double hw = rad * (0.5 + 0.03 * beat);
    final Offset hc = Offset(c.dx, c.dy - rad * 0.02);
    Offset at(Offset u) => Offset(hc.dx + u.dx * hw, hc.dy + u.dy * hw);
    const int k = 16;
    final List<Offset> outer = <Offset>[];
    final List<Offset> mid = <Offset>[];
    for (int i = 0; i < k; i++) {
      final Offset q = _pt(Cine.tau * i / k);
      outer.add(at(q));
      mid.add(
        at(
          Offset(
            q.dx * 0.55 + (Cine.hash(i + 40) - 0.5) * 0.1,
            q.dy * 0.55 + 0.02 + (Cine.hash(i + 90) - 0.5) * 0.1,
          ),
        ),
      );
    }
    final Offset mc = at(const Offset(0, -0.04));
    final Path body = Path();
    for (int i = 0; i <= 64; i++) {
      final Offset q = at(_pt(Cine.tau * i / 64));
      if (i == 0) {
        body.moveTo(q.dx, q.dy);
      } else {
        body.lineTo(q.dx, q.dy);
      }
    }
    body.close();
    canvas.drawPath(body, Paint()..color = _tone(0.25 + 0.2 * heat));
    final double sweep = Cine.fract(t * 2) * 3.4 - 1.7;
    final Paint fp = Paint();
    int id = 0;
    void facet(Offset a, Offset b, Offset d, Offset u) {
      final double lam = (-u.dx * 0.5 - u.dy * 0.6) * 0.5 + 0.62;
      double br = lam * (0.5 + 0.32 * heat) + 0.06 * heat;
      br += (Cine.hash(id * 7 + 3) - 0.5) * 0.34;
      final double dd = (u.dx * 0.8 + u.dy * 0.6) - sweep;
      br += 0.55 * math.exp(-dd * dd / 0.05) * (0.5 + 0.5 * heat);
      id++;
      fp.color = _tone(br);
      canvas.drawPath(
        Path()
          ..moveTo(a.dx, a.dy)
          ..lineTo(b.dx, b.dy)
          ..lineTo(d.dx, d.dy)
          ..close(),
        fp,
      );
    }

    for (int i = 0; i < k; i++) {
      final int j = (i + 1) % k;
      final Offset ua = _pt(Cine.tau * (i + 0.5) / k);
      facet(outer[i], outer[j], mid[i], ua);
      facet(mid[i], mid[j], outer[j], ua);
      facet(mid[i], mid[j], mc, Offset(ua.dx * 0.5, ua.dy * 0.5));
    }
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, hw * 0.07)
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFFFFEDB0).withValues(alpha: 0.9),
    );

    // A glint that wakes and sleeps on the heart's shoulder.
    final double gl = math.pow(
      math.max(0.0, math.sin(Cine.tau * (t * 2 + 0.25))),
      6,
    ).toDouble();
    if (gl > 0.05) {
      final Offset gp = at(const Offset(-0.5, -0.55));
      final Paint sp = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.9 * gl)
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round;
      final double len = hw * (0.35 + 0.35 * gl);
      canvas.drawLine(gp.translate(-len, 0), gp.translate(len, 0), sp);
      canvas.drawLine(gp.translate(0, -len), gp.translate(0, len), sp);
    }

    DustRing.paint(
      canvas,
      center: c,
      rx: rx,
      ry: ry,
      tilt: tilt,
      t: t,
      n: n,
      front: true,
      alpha: 1,
      grain: 0.95,
      thick: 0.26,
      haze: 1,
    );
    canvas.restore();

    // The gold rim.
    canvas.drawCircle(
      c,
      rad,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..shader = SweepGradient(
          transform: GradientRotation(Cine.tau * t),
          colors: const <Color>[
            Color(0xFFFFF3C4),
            Color(0xFFE59A10),
            Color(0xFFFFC21A),
            Color(0xFF8A5008),
            Color(0xFFFFF3C4),
          ],
        ).createShader(disc),
    );
  }

  @override
  bool shouldRepaint(_MedallionPainter o) => o.t != t || o.heat != heat;
}

// END OF FILE - lib/widgets/heart_medallion.dart
