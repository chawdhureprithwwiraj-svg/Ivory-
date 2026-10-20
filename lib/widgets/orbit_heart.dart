import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'heart_cine.dart';

/// ============================================================
/// IVORY - THE CRYSTAL HEART AND ITS GOLDEN ORBIT (Home)
///
/// A faceted heart of gold crystal. Light slides across its facets,
/// its corners glint, a cluster of crystals rises from its shoulder,
/// and a ring of fine golden dust circles it like the rings of
/// Saturn: clockwise, behind the heart and then in front, with a
/// bright head and a long glittering tail, and now and then a soft
/// fall of golden dust. The more the member glows, the more crystal,
/// the brighter the gold and the richer the ring. All painted; there
/// is no image in it.
/// ============================================================
class OrbitHeart extends StatefulWidget {
  const OrbitHeart({
    super.key,
    required this.fill,
    required this.tier,
    this.lit = false,
    this.height = 236,
  });

  /// Today's progress, 0 to 1.
  final double fill;

  /// The glow tier, 0 to 8.
  final int tier;
  final bool lit;
  final double height;

  /// How hot the heart is, 0 to 1, from its tier and today's progress.
  static double heatOf(int tier, double fill, bool lit) {
    final double base = (tier < 0 ? 0 : (tier > 8 ? 8 : tier)) / 8.0;
    double h = 0.16 + 0.54 * base + 0.2 * Cine.clamp01(fill);
    if (lit) h += 0.1;
    return Cine.clamp01(h);
  }

  @override
  State<OrbitHeart> createState() => _OrbitHeartState();
}

class _OrbitHeartState extends State<OrbitHeart>
    with SingleTickerProviderStateMixin {
  // One full orbit takes ten seconds: calm, never rushed, never sleepy.
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 10),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double heat = OrbitHeart.heatOf(widget.tier, widget.fill, widget.lit);
    return RepaintBoundary(
      child: SizedBox(
        width: double.infinity,
        height: widget.height,
        child: AnimatedBuilder(
          animation: _c,
          builder: (BuildContext _, Widget? __) => CustomPaint(
            painter: CrystalHeartPainter(
              t: _c.value,
              heat: heat,
              tier: widget.tier,
            ),
          ),
        ),
      ),
    );
  }
}

class _Geo {
  _Geo(this.outer, this.mid, this.center);

  final List<Offset> outer;
  final List<Offset> mid;
  final Offset center;
}

class CrystalHeartPainter extends CustomPainter {
  CrystalHeartPainter({
    required this.t,
    required this.heat,
    required this.tier,
  });

  final double t;
  final double heat;
  final int tier;

  static const int _n = 22;
  static _Geo? _cache;

  static const List<Color> _ramp = <Color>[
    Color(0xFF6A3806),
    Color(0xFF9A5A08),
    Color(0xFFD98E0C),
    Color(0xFFFFBE24),
    Color(0xFFFFE27A),
    Color(0xFFFFF6D6),
  ];

  /// The heart of unit size: x from -1 to 1, y from about -0.8 to 1.
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

  static _Geo _geo() {
    final _Geo? g = _cache;
    if (g != null) return g;
    final List<Offset> o = <Offset>[];
    final List<Offset> m = <Offset>[];
    for (int i = 0; i < _n; i++) {
      final Offset p = _pt(Cine.tau * i / _n);
      o.add(p);
      m.add(
        Offset(
          p.dx * 0.58 + (Cine.hash(40 + i) - 0.5) * 0.08,
          p.dy * 0.58 + 0.02 + (Cine.hash(90 + i) - 0.5) * 0.08,
        ),
      );
    }
    final _Geo made = _Geo(o, m, const Offset(0.0, -0.04));
    _cache = made;
    return made;
  }

  Color _color(double b) {
    final double x = Cine.clamp01(b) * (_ramp.length - 1);
    int i = x.floor();
    if (i > _ramp.length - 2) i = _ramp.length - 2;
    return Color.lerp(_ramp[i], _ramp[i + 1], x - i)!;
  }

  Path _outline(Offset c, double hw) {
    final Path p = Path();
    const int k = 96;
    for (int i = 0; i <= k; i++) {
      final Offset q = _pt(Cine.tau * i / k);
      final Offset s = Offset(c.dx + q.dx * hw, c.dy + q.dy * hw);
      if (i == 0) {
        p.moveTo(s.dx, s.dy);
      } else {
        p.lineTo(s.dx, s.dy);
      }
    }
    p.close();
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double hw = h * 0.3;
    final Offset c = Offset(w * 0.5, h * 0.47);
    final _Geo g = _geo();
    Offset at(Offset u) => Offset(c.dx + u.dx * hw, c.dy + u.dy * hw);
    final double rx = w * 0.46;
    final double ry = rx * 0.27;
    const double tilt = 0.17;
    final int ringN = (150 + 170 * heat).round();
    final double beat = Cine.beat(Cine.fract(t * 8));
    final double wave = 0.22 + 0.78 * Cine.smooth(0.08, 0.2, Cine.fract(t)) *
        (1 - Cine.smooth(0.5, 0.75, Cine.fract(t)));

    // Drifting clouds of fine dust, as in the night sky.
    OrbitKit.cloud(
      canvas,
      center: Offset(w * 0.2, h * 0.78),
      rx: w * 0.16,
      ry: h * 0.14,
      t: t,
      n: 70,
      seed: 500,
      alpha: 0.5 + 0.5 * heat,
    );
    OrbitKit.cloud(
      canvas,
      center: Offset(w * 0.84, h * 0.24),
      rx: w * 0.12,
      ry: h * 0.12,
      t: t,
      n: 56,
      seed: 800,
      alpha: 0.5 + 0.5 * heat,
    );

    // The halo behind the heart.
    final double halo = hw * (2.1 + 0.12 * beat);
    canvas.drawCircle(
      c,
      halo,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            const Color(0xFFFFC21A).withValues(alpha: 0.2 + 0.3 * heat),
            const Color(0xFFD98A0A).withValues(alpha: 0.1 + 0.1 * heat),
            const Color(0xFFD98A0A).withValues(alpha: 0),
          ],
          stops: const <double>[0, 0.45, 1],
        ).createShader(Rect.fromCircle(center: c, radius: halo)),
    );

    // The half of the ring that passes behind the heart.
    OrbitKit.ring(
      canvas,
      center: c,
      rx: rx,
      ry: ry,
      tilt: tilt,
      t: t,
      n: ringN,
      front: false,
    );

    // The heart itself: a deep amber body, then the facets.
    final Path body = _outline(c, hw);
    canvas.drawPath(
      body,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.25, -0.35),
          radius: 0.95,
          colors: <Color>[
            Cine.mix(const Color(0xFFB36A08), const Color(0xFFFFD25A), heat),
            Cine.mix(const Color(0xFF6A3806), const Color(0xFFD98E0C), heat),
            const Color(0xFF5A3008),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: hw * 1.1)),
    );

    canvas.save();
    canvas.clipPath(body);
    final double sweep = Cine.fract(t * 2) * 3.4 - 1.7;
    final Paint fp = Paint();
    final Paint edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, hw * 0.012)
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFFFFE9A6).withValues(alpha: 0.78);
    final Path edges = Path();
    void facet(Offset a, Offset b, Offset d, int id) {
      final Offset cen = Offset((a.dx + b.dx + d.dx) / 3, (a.dy + b.dy + d.dy) / 3);
      // A dome-like normal, lit from the upper left.
      final double nz = math.sqrt(math.max(0.08, 1 - 0.5 * (cen.dx * cen.dx + cen.dy * cen.dy)));
      final double lam = math.max(
        0.0,
        (-cen.dx * 0.5 - cen.dy * 0.6) * 0.55 + nz * 0.62,
      );
      double bright = lam * (0.5 + 0.32 * heat) + 0.06 * heat;
      bright += (Cine.hash(id * 7 + 3) - 0.5) * 0.34;
      final double proj = cen.dx * 0.8 + cen.dy * 0.6;
      final double dd = proj - sweep;
      bright += 0.55 * math.exp(-dd * dd / 0.05) * (0.5 + 0.5 * heat);
      fp.color = _color(bright).withValues(alpha: 0.9);
      final Path tri = Path()
        ..moveTo(at(a).dx, at(a).dy)
        ..lineTo(at(b).dx, at(b).dy)
        ..lineTo(at(d).dx, at(d).dy)
        ..close();
      canvas.drawPath(tri, fp);
      edges.addPath(tri, Offset.zero);
    }

    int id = 0;
    for (int i = 0; i < _n; i++) {
      final int j = (i + 1) % _n;
      facet(g.outer[i], g.outer[j], g.mid[i], id++);
      facet(g.mid[i], g.mid[j], g.outer[j], id++);
      facet(g.mid[i], g.mid[j], g.center, id++);
    }
    // The golden river seen through the glass.
    OrbitKit.ring(
      canvas,
      center: c,
      rx: rx,
      ry: ry,
      tilt: tilt,
      t: t,
      n: ringN,
      front: false,
      alpha: 0.4,
    );
    canvas.drawPath(edges, edge);
    canvas.restore();

    // The bright rim, with a soft glow.
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hw * 0.07
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, hw * 0.06)
        ..color = const Color(0xFFFFC21A).withValues(alpha: 0.35 + 0.3 * heat),
    );
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, hw * 0.022)
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFFFFEDB0).withValues(alpha: 0.9),
    );

    // A cluster of crystals rising from the left shoulder: one more for
    // every few tiers of glow.
    final int spikes = 3 + (tier >= 3 ? 1 : 0) + (tier >= 5 ? 1 : 0) + (tier >= 7 ? 1 : 0);
    const List<int> bases = <int>[18, 19, 20, 17, 16, 21];
    for (int k = 0; k < spikes; k++) {
      final Offset v = g.outer[bases[k]];
      final Offset a0 = at(v);
      double dx = v.dx * 1.0;
      double dy = v.dy - 0.35;
      final double dl = math.sqrt(dx * dx + dy * dy);
      dx /= dl;
      dy /= dl;
      final double len = hw * (0.34 + 0.2 * Cine.hash(60 + k)) * (0.8 + 0.2 * heat);
      final double wd = hw * (0.085 + 0.02 * Cine.hash(70 + k));
      _spike(canvas, a0, Offset(dx, dy), len, wd, k);
    }

    // Glowing corners that twinkle.
    for (int i = 0; i < _n; i += 1) {
      final Offset p = at(g.outer[i]);
      canvas.drawCircle(
        p,
        math.max(1.1, hw * 0.017),
        Paint()..color = const Color(0xFFFFF3C0).withValues(alpha: 0.95),
      );
      if (i % 4 == 1) {
        final double tw = 0.5 +
            0.5 * math.sin(Cine.tau * (t * 6 + Cine.hash(200 + i)));
        OrbitKit.glint(canvas, p, hw * 0.16 * (0.5 + 0.8 * tw), 0.35 + 0.65 * tw);
      }
    }
    for (int i = 0; i < _n; i += 2) {
      canvas.drawCircle(
        at(g.mid[i]),
        math.max(0.9, hw * 0.012),
        Paint()..color = const Color(0xFFFFE9A6).withValues(alpha: 0.85),
      );
    }

    // The half of the ring that sweeps in front of the heart.
    OrbitKit.ring(
      canvas,
      center: c,
      rx: rx,
      ry: ry,
      tilt: tilt,
      t: t,
      n: ringN,
      front: true,
    );
    OrbitKit.dust(
      canvas,
      center: c,
      rx: rx,
      ry: ry,
      tilt: tilt,
      t: t,
      n: (50 + 60 * heat).round(),
      fall: h * 0.34,
      wave: wave,
    );
  }

  void _spike(Canvas canvas, Offset base, Offset dir, double len, double wd, int k) {
    final Offset perp = Offset(-dir.dy, dir.dx);
    final Offset bl = base - perp * wd;
    final Offset br = base + perp * wd;
    final Offset sl = base - perp * wd * 0.95 + dir * (len * 0.72);
    final Offset sr = base + perp * wd * 0.95 + dir * (len * 0.72);
    final Offset tip = base + dir * len;
    final Offset mid = base + dir * (len * 0.72);
    final Paint dark = Paint()
      ..color = _color(0.34 + 0.2 * heat + 0.1 * Cine.hash(k + 5));
    final Paint light = Paint()
      ..color = _color(0.72 + 0.25 * heat + 0.1 * Cine.hash(k + 9));
    final Path left = Path()
      ..moveTo(bl.dx, bl.dy)
      ..lineTo(sl.dx, sl.dy)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(mid.dx, mid.dy)
      ..lineTo(base.dx, base.dy)
      ..close();
    final Path right = Path()
      ..moveTo(br.dx, br.dy)
      ..lineTo(sr.dx, sr.dy)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(mid.dx, mid.dy)
      ..lineTo(base.dx, base.dy)
      ..close();
    canvas.drawPath(left, dark);
    canvas.drawPath(right, light);
    final Paint line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFFFFEDB0).withValues(alpha: 0.9);
    canvas.drawPath(left, line);
    canvas.drawPath(right, line);
    final double tw = 0.5 + 0.5 * math.sin(Cine.tau * (t * 4 + Cine.hash(k + 30)));
    OrbitKit.glint(canvas, tip, wd * 2.4 * (0.5 + 0.6 * tw), 0.4 + 0.6 * tw);
  }

  @override
  bool shouldRepaint(CrystalHeartPainter o) =>
      o.t != t || o.heat != heat || o.tier != tier;
}

// END OF FILE - lib/widgets/orbit_heart.dart
