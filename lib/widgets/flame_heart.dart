import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'heart_cine.dart';

part 'flame_heart_fx.dart';

/// ============================================================
/// IVORY - THE FLAME HEART (inside the Golden Heart screen)
///
/// A living heart of molten gold, with veins of fire, flames licking
/// its edges and embers rising from it, beating its double beat.
/// It grows with the member's glow:
///   no glow yet - a cold, dark heart with faint glowing cracks
///   Ember - a few embers          Flame - flickering flames
///   Radiant - the veins burn      Brilliant - bright, a warm halo
///   Golden - fully molten gold    Sovereign - sparks rise off it
///   Eternal - a wide halo and a light streak
///   Crowned - everything, and the golden ring of dust circles it.
/// When today's heart is lit, it flares once. All painted; there is
/// no image in it. No black anywhere.
/// ============================================================
class FlameHeart extends StatefulWidget {
  const FlameHeart({
    super.key,
    required this.fill,
    required this.tier,
    this.lit = false,
    this.celebrate = 0,
    this.height = 310,
  });

  final double fill;
  final int tier;
  final bool lit;

  /// Goes up by one every time today's heart is lit: it flares.
  final int celebrate;
  final double height;

  static double heatOf(int tier, double fill, bool lit) {
    final double base = (tier < 0 ? 0 : (tier > 8 ? 8 : tier)) / 8.0;
    double h = 0.14 + 0.56 * base + 0.22 * Cine.clamp01(fill);
    if (lit) h += 0.08;
    return Cine.clamp01(h);
  }

  @override
  State<FlameHeart> createState() => _FlameHeartState();
}

class _FlameHeartState extends State<FlameHeart>
    with TickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 10),
  )..repeat();

  late final AnimationController _flare = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );

  @override
  void didUpdateWidget(FlameHeart old) {
    super.didUpdateWidget(old);
    if (widget.celebrate != old.celebrate && widget.celebrate > 0) {
      _flare.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    _flare.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double heat = FlameHeart.heatOf(
      widget.tier,
      widget.fill,
      widget.lit,
    );
    return RepaintBoundary(
      child: SizedBox(
        width: double.infinity,
        height: widget.height,
        child: AnimatedBuilder(
          animation: Listenable.merge(<Listenable>[_loop, _flare]),
          builder: (BuildContext _, Widget? __) => CustomPaint(
            painter: FlameHeartPainter(
              t: _loop.value,
              heat: heat,
              tier: widget.tier,
              lit: widget.lit,
              flare: _flare.value >= 1 ? 0.0 : _flare.value,
            ),
          ),
        ),
      ),
    );
  }
}

class FlameHeartPainter extends CustomPainter {
  FlameHeartPainter({
    required this.t,
    required this.heat,
    required this.tier,
    required this.lit,
    required this.flare,
  });

  final double t;
  final double heat;
  final int tier;
  final bool lit;
  final double flare;

  static List<List<Offset>>? _veins;
  static List<List<Offset>>? _fine;

  static List<List<Offset>> _walkers(
    int roots,
    int steps,
    double len,
    int seed,
    int maxDepth,
  ) {
    final List<List<Offset>> out = <List<Offset>>[];
    int n = seed;
    void walk(double x, double y, double ang, int count, double step, int depth) {
      final List<Offset> pts = <Offset>[Offset(x, y)];
      double cx = x;
      double cy = y;
      double a = ang;
      for (int i = 0; i < count; i++) {
        a += (Cine.hash(n++) - 0.5) * 0.95;
        cx += math.cos(a) * step;
        cy += math.sin(a) * step;
        pts.add(Offset(cx, cy));
        if (depth < maxDepth && i > 1 && Cine.hash(n++) < 0.3) {
          final double side = Cine.hash(n++) < 0.5 ? -1.0 : 1.0;
          walk(
            cx,
            cy,
            a + side * (0.6 + Cine.hash(n++) * 0.6),
            count - i - 1,
            step * 0.82,
            depth + 1,
          );
        }
      }
      out.add(pts);
    }

    for (int k = 0; k < roots; k++) {
      walk(
        0.2 + 0.6 * Cine.hash(seed + 1000 + k),
        0.24 + 0.22 * Cine.hash(seed + 2000 + k),
        1.1 + (Cine.hash(seed + 3000 + k) - 0.5) * 1.5,
        steps,
        len,
        0,
      );
    }
    return out;
  }

  static List<List<Offset>> get _bigVeins =>
      _veins ??= _walkers(15, 14, 0.048, 100, 2);
  static List<List<Offset>> get _fineVeins =>
      _fine ??= _walkers(44, 6, 0.026, 7000, 0);

  /// The body of the heart inside [r] (unit coordinates, 0..1).
  Path _body(Rect r) {
    Offset q(double x, double y) =>
        Offset(r.left + r.width * x, r.top + r.height * y);
    final Path p = Path();
    p.moveTo(q(0.46, 0.95).dx, q(0.46, 0.95).dy);
    p.cubicTo(
      q(0.2, 0.88).dx, q(0.2, 0.88).dy,
      q(0.06, 0.64).dx, q(0.06, 0.64).dy,
      q(0.11, 0.45).dx, q(0.11, 0.45).dy,
    );
    p.cubicTo(
      q(0.15, 0.3).dx, q(0.15, 0.3).dy,
      q(0.27, 0.24).dx, q(0.27, 0.24).dy,
      q(0.4, 0.26).dx, q(0.4, 0.26).dy,
    );
    p.quadraticBezierTo(
      q(0.5, 0.21).dx, q(0.5, 0.21).dy,
      q(0.62, 0.25).dx, q(0.62, 0.25).dy,
    );
    p.cubicTo(
      q(0.8, 0.25).dx, q(0.8, 0.25).dy,
      q(0.93, 0.38).dx, q(0.93, 0.38).dy,
      q(0.9, 0.56).dx, q(0.9, 0.56).dy,
    );
    p.cubicTo(
      q(0.87, 0.76).dx, q(0.87, 0.76).dy,
      q(0.64, 0.88).dx, q(0.64, 0.88).dy,
      q(0.46, 0.95).dx, q(0.46, 0.95).dy,
    );
    p.close();
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double pulse = math.sin(math.pi * flare);
    final double hot = Cine.clamp01(heat + 0.5 * pulse);
    final double hh = h * 0.8;
    final double ww = hh * 0.86;
    final Rect r = Rect.fromLTWH((w - ww) / 2, h * 0.13, ww, hh);
    final Offset mid = Offset(r.left + r.width * 0.5, r.top + r.height * 0.55);
    final double beatU = lit ? Cine.fract(t * 8) : Cine.fract(t * 4);
    final double beat = Cine.beat(beatU) * (lit ? 1.0 : 0.6);
    final Path body = _body(r);

    // The glow of the whole fire on the air around it.
    final double gr = hh * (0.85 + 0.08 * beat + 0.25 * pulse);
    canvas.drawCircle(
      mid,
      gr,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            const Color(0xFFFF9A2A).withValues(alpha: 0.12 + 0.36 * hot),
            const Color(0xFFE0610F).withValues(alpha: 0.05 + 0.14 * hot),
            const Color(0xFFE0610F).withValues(alpha: 0),
          ],
          stops: const <double>[0, 0.5, 1],
        ).createShader(Rect.fromCircle(center: mid, radius: gr)),
    );

    final bool crowned = tier >= 8;
    final double rx = w * 0.47;
    final double ry = rx * 0.26;
    const double tilt = 0.17;
    if (crowned) {
      OrbitKit.cloud(
        canvas,
        center: Offset(w * 0.18, h * 0.8),
        rx: w * 0.14,
        ry: h * 0.12,
        t: t,
        n: 60,
        seed: 1500,
      );
      OrbitKit.ring(
        canvas,
        center: mid,
        rx: rx,
        ry: ry,
        tilt: tilt,
        t: t,
        n: 280,
        front: false,
      );
    }

    // Everything moves with the heart's beat.
    canvas.save();
    final double sc = 1 + 0.028 * beat + 0.03 * pulse;
    canvas.translate(mid.dx, mid.dy);
    canvas.scale(sc, sc);
    canvas.translate(-mid.dx, -mid.dy);

    this._vessels(canvas, r, hot);

    // The body: crust that gives way to molten gold as the heat rises.
    final Rect bb = body.getBounds();
    canvas.drawPath(
      body,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.2, -0.25),
          radius: 0.92,
          colors: <Color>[
            Cine.mix(const Color(0xFF9A3A12), const Color(0xFFFFF1B4), hot),
            Cine.mix(const Color(0xFF5E1A12), const Color(0xFFFFC43E), hot),
            Cine.mix(const Color(0xFF6A2230), const Color(0xFFE5800F), hot),
          ],
          stops: const <double>[0, 0.55, 1],
        ).createShader(bb),
    );

    canvas.save();
    canvas.clipPath(body);
    this._veinwork(canvas, r, hot);
    // A hot core that breathes with the beat.
    canvas.drawCircle(
      Offset(r.left + r.width * 0.42, r.top + r.height * 0.5),
      r.width * (0.4 + 0.05 * beat),
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            const Color(0xFFFFF4C2).withValues(alpha: 0.5 * hot * (0.8 + 0.2 * beat)),
            const Color(0xFFFFB02E).withValues(alpha: 0.18 * hot),
            const Color(0xFFFFB02E).withValues(alpha: 0),
          ],
          stops: const <double>[0, 0.5, 1],
        ).createShader(
          Rect.fromCircle(
            center: Offset(r.left + r.width * 0.42, r.top + r.height * 0.5),
            radius: r.width * 0.45,
          ),
        ),
    );
    canvas.restore();

    // The rim of light.
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r.width * 0.05
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r.width * 0.035)
        ..color = const Color(0xFFFFB02E).withValues(alpha: 0.2 + 0.5 * hot),
    );
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Cine.mix(
          const Color(0xFFFF8A1F),
          const Color(0xFFFFF0B0),
          hot,
        ).withValues(alpha: 0.35 + 0.5 * hot),
    );

    this._flames(canvas, r, body, hot);
    canvas.restore();

    this._embers(canvas, r, body, hot);
    this._streak(canvas, mid, w, hot, beat);

    if (crowned) {
      OrbitKit.ring(
        canvas,
        center: mid,
        rx: rx,
        ry: ry,
        tilt: tilt,
        t: t,
        n: 280,
        front: true,
      );
      OrbitKit.dust(
        canvas,
        center: mid,
        rx: rx,
        ry: ry,
        tilt: tilt,
        t: t,
        n: 90,
        fall: h * 0.3,
        wave: 0.22 +
            0.78 *
                Cine.smooth(0.08, 0.2, Cine.fract(t)) *
                (1 - Cine.smooth(0.5, 0.75, Cine.fract(t))),
      );
    }
    if (flare > 0) this._flareFx(canvas, mid, hh, ww);
  }

  @override
  bool shouldRepaint(FlameHeartPainter o) =>
      o.t != t ||
      o.heat != heat ||
      o.tier != tier ||
      o.lit != lit ||
      o.flare != flare;
}

class _Spot {
  const _Spot(this.p, this.n);

  final Offset p;
  final Offset n;
}

// END OF FILE - lib/widgets/flame_heart.dart
