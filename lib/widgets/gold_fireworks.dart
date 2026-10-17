import 'dart:math' as math;

import 'package:flutter/material.dart';

/// ============================================================
/// IVORY - GOLDEN FIREWORKS
///
/// Real shells, in gold. A rocket climbs on a spark trail, the
/// shell bursts into a true sphere of light (each spark has a
/// place in 3D space, turns slowly and is drawn with perspective,
/// so the burst has depth), the sparks slow in the air, then
/// droop and fade under gravity, glittering at the end. Four kinds
/// of shell: peony (a crisp ball), willow (long drooping golden
/// rain), crackle (a ball that sparkles out) and ring.
///
/// Light is added to the picture (not painted over it), so the
/// fireworks glow on the dark burgundy like real light in a night
/// sky. Everything is worked out from the clock, with no stored
/// state, and nothing here is an image or a sound.
/// ============================================================
class GoldFireworks extends StatefulWidget {
  const GoldFireworks({
    super.key,
    this.rate = 1,
    this.strength = 1,
    this.seed = 5,
  });

  /// Shells per second, relative (1 = a new shell about every 1.3 s).
  final double rate;

  /// Brightness, 0 to 1.
  final double strength;

  final int seed;

  @override
  State<GoldFireworks> createState() => _GoldFireworksState();
}

class _GoldFireworksState extends State<GoldFireworks>
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
        child: AnimatedBuilder(
          animation: _c,
          builder: (BuildContext context, Widget? _) => CustomPaint(
            size: Size.infinite,
            painter: _FireworksPainter(
              _c.value * 100000,
              widget.rate,
              widget.strength,
              widget.seed,
            ),
          ),
        ),
      ),
    );
  }
}

const List<Color> _hues = <Color>[
  Color(0xFFFFD54A),
  Color(0xFFFFF1A8),
  Color(0xFFFFB300),
  Color(0xFFFFC9A3),
  Color(0xFFFFE680),
];

const Color _white = Color(0xFFFFF8E1);

class _FireworksPainter extends CustomPainter {
  _FireworksPainter(this.t, this.rate, this.strength, this.seed);

  final double t;
  final double rate;
  final double strength;
  final int seed;

  static const double _ascent = 0.6;
  static const double _life = 3.9;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final double gap = 1.3 / math.max(0.1, rate);
    final double sc = math.max(0.6, size.shortestSide / 330);
    final Paint p = Paint()
      ..blendMode = BlendMode.plus
      ..strokeCap = StrokeCap.round;
    final int from = ((t - _life) / gap).floor() - 1;
    final int to = (t / gap).floor();
    for (int k = math.max(0, from); k <= to; k++) {
      final math.Random r = math.Random(seed * 100003 + k * 7919);
      final double start = k * gap + r.nextDouble() * gap * 0.5;
      final double tau = t - start;
      if (tau < 0 || tau > _life) continue;
      final double x0 = 0.12 + r.nextDouble() * 0.76;
      final double ty = 0.1 + r.nextDouble() * 0.38;
      final int type = r.nextInt(4);
      final Color base = _hues[r.nextInt(_hues.length)];
      final double rot = r.nextDouble() * math.pi * 2;
      final double tilt = (r.nextDouble() - 0.5) * 1.3;
      final int n = 56 + r.nextInt(30);
      final double speed = (120 + r.nextDouble() * 70) * sc;
      final Offset target = Offset(x0 * size.width, ty * size.height);
      if (tau < _ascent) {
        _rocket(canvas, p, size, target, x0, tau, sc);
      } else {
        _burst(
          canvas,
          p,
          target,
          type,
          base,
          rot,
          tilt,
          n,
          speed,
          sc,
          k,
          tau - _ascent,
        );
      }
    }
  }

  void _rocket(
    Canvas canvas,
    Paint p,
    Size size,
    Offset target,
    double x0,
    double tau,
    double sc,
  ) {
    final double drift = (x0 - 0.5) * 40 * sc;
    Offset at(double u) {
      final double e = Curves.easeOutCubic.transform(
        u.clamp(0.0, 1.0).toDouble(),
      );
      return Offset(
        target.dx + drift * (1 - e),
        size.height + (target.dy - size.height) * e,
      );
    }

    final double u = tau / _ascent;
    for (int j = 0; j < 9; j++) {
      final double uj = u - j * 0.028;
      if (uj < 0) break;
      final double a = (1 - j / 9) * 0.85 * strength;
      p
        ..color = (j < 2 ? _white : _hues[0]).withValues(alpha: a)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(at(uj), (2.0 - j * 0.15) * sc, p);
    }
  }

  void _burst(
    Canvas canvas,
    Paint p,
    Offset c,
    int type,
    Color base,
    double rot,
    double tilt,
    int n,
    double speed,
    double sc,
    int k,
    double e,
  ) {
    if (e < 0.4) {
      final double f = 1 - e / 0.4;
      p
        ..style = PaintingStyle.fill
        ..color = const Color(
          0xFFFFE9A0,
        ).withValues(alpha: 0.4 * f * f * strength);
      canvas.drawCircle(c, (28 + 150 * (e / 0.4)) * sc, p);
    }
    final math.Random r = math.Random(k * 31 + 7);
    final bool willow = type == 1;
    final double drag = willow ? 1.7 : 2.4;
    final double grav = (willow ? 105 : 58) * sc;
    final double spin = rot + e * 0.55;
    final double cy = math.cos(spin);
    final double sy = math.sin(spin);
    final double cx = math.cos(tilt);
    final double sx = math.sin(tilt);
    final double dt = willow ? 0.1 : 0.07;
    for (int i = 0; i < n; i++) {
      double u = r.nextDouble() * 2 - 1;
      if (type == 3) u = (r.nextDouble() - 0.5) * 0.14;
      final double a = r.nextDouble() * math.pi * 2;
      final double s = math.sqrt(math.max(0, 1 - u * u));
      final double sv =
          (type == 0 ? 0.94 : 0.8) + r.nextDouble() * (type == 0 ? 0.12 : 0.4);
      final double pl = (1.7 + r.nextDouble() * 0.7) * (willow ? 1.4 : 1);
      final double phase = r.nextDouble() * 40;
      if (e > pl) continue;
      // Direction in 3D, turned about the up axis and then tipped.
      final double dx0 = s * math.cos(a);
      final double dz0 = s * math.sin(a);
      final double dx1 = dx0 * cy + dz0 * sy;
      final double dz1 = -dx0 * sy + dz0 * cy;
      final double dy1 = u * cx - dz1 * sx;
      final double dz2 = u * sx + dz1 * cx;
      Offset where(double tt) {
        if (tt < 0) tt = 0;
        final double rad = speed * sv * (1 - math.exp(-drag * tt)) / drag;
        final double z = dz2 * rad;
        final double pf = 1 / (1 - z / (520 * sc));
        return Offset(
          c.dx + dx1 * rad * pf,
          c.dy + dy1 * rad * pf + 0.5 * grav * tt * tt,
        );
      }

      final Offset head = where(e);
      final double fade = math.pow(1 - e / pl, 1.4).toDouble();
      double al = fade * strength;
      if (type == 2 || e > pl * 0.6) {
        al *= 0.3 + 0.7 * (0.5 + 0.5 * math.sin(e * 38 + phase));
      }
      if (al < 0.02) continue;
      final Color col = Color.lerp(
        _white,
        i % 4 == 0 ? _white : base,
        math.min(1, e / 0.8),
      )!;
      final double depth = 0.75 + 0.25 * dz2;
      p
        ..style = PaintingStyle.stroke
        ..strokeWidth = (1.7 + 0.8 * depth) * sc
        ..color = col.withValues(alpha: al * 0.55);
      final Offset t1 = where(e - dt);
      canvas.drawLine(head, t1, p);
      if (willow) {
        p
          ..strokeWidth = 1.3 * sc
          ..color = col.withValues(alpha: al * 0.28);
        canvas.drawLine(t1, where(e - dt * 2), p);
      }
      p.style = PaintingStyle.fill;
      if (i.isEven) {
        p.color = col.withValues(alpha: al * 0.16);
        canvas.drawCircle(head, 4.2 * sc * depth, p);
      }
      p.color = col.withValues(alpha: math.min(1, al * 1.1));
      canvas.drawCircle(head, (1.2 + 0.9 * depth) * sc, p);
    }
  }

  @override
  bool shouldRepaint(_FireworksPainter old) => old.t != t;
}

// END OF FILE - lib/widgets/gold_fireworks.dart
