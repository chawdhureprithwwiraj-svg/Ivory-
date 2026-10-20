part of 'flame_heart.dart';

/// ============================================================
/// IVORY - THE FLAME HEART, SECOND HALF
///
/// The painted parts of the flame heart (vessels, veins, flames,
/// embers, the light streak and the flare). It is a second file only
/// so that each file stays short enough to paste on a phone; it is
/// part of flame_heart.dart.
/// ============================================================
extension _FlameFx on FlameHeartPainter {
  /// The vessels that rise from the top of the heart, with the arch.
  void _vessels(Canvas canvas, Rect r, double hot) {
    Offset q(double x, double y) =>
        Offset(r.left + r.width * x, r.top + r.height * y);
    final Color base = Cine.mix(
      const Color(0xFF7A2A12),
      const Color(0xFFFFC43E),
      hot,
    );
    final Color lightC = Cine.mix(
      const Color(0xFFB8501A),
      const Color(0xFFFFF1B4),
      hot,
    );
    final List<Path> tubes = <Path>[
      Path()
        ..moveTo(q(0.42, 0.3).dx, q(0.42, 0.3).dy)
        ..cubicTo(
          q(0.41, 0.2).dx, q(0.41, 0.2).dy,
          q(0.4, 0.1).dx, q(0.4, 0.1).dy,
          q(0.41, 0.03).dx, q(0.41, 0.03).dy,
        ),
      Path()
        ..moveTo(q(0.52, 0.28).dx, q(0.52, 0.28).dy)
        ..cubicTo(
          q(0.52, 0.2).dx, q(0.52, 0.2).dy,
          q(0.53, 0.1).dx, q(0.53, 0.1).dy,
          q(0.52, 0.02).dx, q(0.52, 0.02).dy,
        ),
      Path()
        ..moveTo(q(0.6, 0.3).dx, q(0.6, 0.3).dy)
        ..cubicTo(
          q(0.6, 0.18).dx, q(0.6, 0.18).dy,
          q(0.7, 0.1).dx, q(0.7, 0.1).dy,
          q(0.86, 0.1).dx, q(0.86, 0.1).dy,
        ),
    ];
    final List<double> widths = <double>[0.075, 0.062, 0.05];
    for (int i = 0; i < tubes.length; i++) {
      canvas.drawPath(
        tubes[i],
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = r.width * widths[i]
          ..color = base,
      );
      canvas.drawPath(
        tubes[i],
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = r.width * widths[i] * 0.34
          ..color = lightC.withValues(alpha: 0.35 + 0.5 * hot),
      );
    }
  }

  /// Veins of fire across the surface, flickering in four groups.
  void _veinwork(Canvas canvas, Rect r, double hot) {
    final List<Path> groups = <Path>[Path(), Path(), Path(), Path()];
    final Path dark = Path();
    void add(List<List<Offset>> list, int offset) {
      for (int i = 0; i < list.length; i++) {
        final List<Offset> pts = list[i];
        if (pts.length < 2) continue;
        final Path p = Path()
          ..moveTo(r.left + r.width * pts[0].dx, r.top + r.height * pts[0].dy);
        for (int k = 1; k < pts.length; k++) {
          p.lineTo(r.left + r.width * pts[k].dx, r.top + r.height * pts[k].dy);
        }
        groups[(i + offset) % 4].addPath(p, Offset.zero);
        dark.addPath(p, Offset.zero);
      }
    }

    add(FlameHeartPainter._bigVeins, 0);
    add(FlameHeartPainter._fineVeins, 1);

    canvas.drawPath(
      dark,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r.width * 0.012
        ..strokeJoin = StrokeJoin.round
        ..color = Cine.mix(
          const Color(0xFF5A1620),
          const Color(0xFFB5560E),
          hot,
        ).withValues(alpha: 0.5),
    );
    final Color glow = Cine.mix(
      const Color(0xFFFF6A14),
      const Color(0xFFFFF0B0),
      math.pow(hot, 1.3).toDouble(),
    );
    final Paint soft = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r.width * 0.016
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r.width * 0.01);
    final Paint crisp = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, r.width * 0.0042)
      ..strokeJoin = StrokeJoin.round;
    // One soft halo for all the veins (a blur is dear), then four crisp
    // groups that flicker on their own.
    final double avg = 0.7 + 0.3 * math.sin(Cine.tau * t * 11);
    soft.color = glow.withValues(
      alpha: Cine.clamp01((0.28 + 0.72 * hot) * avg * 0.5),
    );
    canvas.drawPath(dark, soft);
    for (int g = 0; g < 4; g++) {
      final double fl =
          0.62 + 0.38 * math.sin(Cine.tau * (t * (11 + g * 6) + g * 0.37));
      final double a = Cine.clamp01((0.28 + 0.72 * hot) * fl);
      crisp.color = glow.withValues(alpha: a);
      canvas.drawPath(groups[g], crisp);
    }
  }

  /// Tongues of flame along the edge and on the tips of the vessels.
  void _flames(Canvas canvas, Rect r, Path body, double hot) {
    if (hot < 0.2) return;
    final int count = (14 + 26 * hot).round();
    final List<_Spot> spots = _spots(body, count);
    final double base = r.height * (0.04 + 0.16 * hot);
    final Paint outer = Paint()..blendMode = BlendMode.plus;
    final Paint inner = Paint()..blendMode = BlendMode.plus;
    for (int i = 0; i < spots.length; i++) {
      final _Spot s = spots[i];
      final double up = -s.n.dy;
      final double wgt = 0.45 + 0.55 * (up > 0 ? up : 0.0);
      final double fl = 0.55 +
          0.3 * math.sin(Cine.tau * (t * (17 + (i % 4) * 6) + Cine.hash(i) * 6)) +
          0.15 * math.sin(Cine.tau * (t * 31 + Cine.hash(i + 50) * 6));
      final double hgt = base * wgt * fl * (0.7 + 0.6 * Cine.hash(i + 9));
      final Offset dirRaw = Offset(s.n.dx * 0.45, s.n.dy * 0.45 - 0.9);
      final double dl = dirRaw.distance;
      final Offset dir = Offset(dirRaw.dx / dl, dirRaw.dy / dl);
      final double sway = math.sin(Cine.tau * (t * 13 + Cine.hash(i + 20))) *
          r.width * 0.03 * hot;
      final double wd = r.width * (0.022 + 0.02 * Cine.hash(i + 33));
      _tongue(canvas, s.p, dir, hgt, wd, sway, outer,
          const Color(0xFFFF8A1F), 0.5 * hot + 0.1);
      _tongue(canvas, s.p, dir, hgt * 0.58, wd * 0.55, sway * 0.6, inner,
          const Color(0xFFFFE08A), 0.55 * hot + 0.1);
    }
    // The vessels burn at their tips, as in the reference.
    final List<Offset> tips = <Offset>[
      Offset(r.left + r.width * 0.41, r.top + r.height * 0.03),
      Offset(r.left + r.width * 0.52, r.top + r.height * 0.02),
      Offset(r.left + r.width * 0.86, r.top + r.height * 0.1),
    ];
    for (int i = 0; i < tips.length; i++) {
      final double fl = 0.6 + 0.4 * math.sin(Cine.tau * (t * (19 + i * 5) + i));
      final double sway = math.sin(Cine.tau * (t * 11 + i * 0.3)) * r.width * 0.025;
      _tongue(canvas, tips[i], const Offset(0, -1), base * 1.1 * fl,
          r.width * 0.03, sway, outer, const Color(0xFFFF8A1F), 0.6 * hot);
      _tongue(canvas, tips[i], const Offset(0, -1), base * 0.65 * fl,
          r.width * 0.018, sway * 0.6, inner, const Color(0xFFFFE08A), 0.6 * hot);
    }
  }

  void _tongue(
    Canvas c,
    Offset base,
    Offset dir,
    double len,
    double wd,
    double sway,
    Paint paint,
    Color col,
    double alpha,
  ) {
    if (len <= 1) return;
    final Offset perp = Offset(-dir.dy, dir.dx);
    final Offset tip = base + dir * len + perp * sway;
    final Offset bl = base - perp * wd;
    final Offset br = base + perp * wd;
    final Offset ctrlL = base - perp * wd * 1.1 + dir * (len * 0.55) + perp * (sway * 0.4);
    final Offset ctrlR = base + perp * wd * 1.1 + dir * (len * 0.55) + perp * (sway * 0.4);
    final Path p = Path()
      ..moveTo(bl.dx, bl.dy)
      ..quadraticBezierTo(ctrlL.dx, ctrlL.dy, tip.dx, tip.dy)
      ..quadraticBezierTo(ctrlR.dx, ctrlR.dy, br.dx, br.dy)
      ..close();
    paint.shader = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: <Color>[
        col.withValues(alpha: Cine.clamp01(alpha)),
        col.withValues(alpha: 0),
      ],
    ).createShader(Rect.fromPoints(base, tip).inflate(wd + 2));
    c.drawPath(p, paint);
  }

  /// Sample points around the edge with their outward direction.
  List<_Spot> _spots(Path body, int count) {
    final List<_Spot> out = <_Spot>[];
    for (final m in body.computeMetrics()) {
      final double len = m.length;
      for (int i = 0; i < count; i++) {
        final double d = len * i / count;
        final tg = m.getTangentForOffset(d);
        if (tg == null) continue;
        final Offset v = tg.vector;
        final double l = v.distance;
        if (l == 0) continue;
        final Offset u = Offset(v.dx / l, v.dy / l);
        out.add(_Spot(tg.position, Offset(u.dy, -u.dx)));
      }
      break;
    }
    return out;
  }

  /// Sparks that rise off the heart and fade.
  void _embers(Canvas canvas, Rect r, Path body, double hot) {
    final int count = (16 + 44 * hot).round();
    final List<_Spot> spots = _spots(body, 48);
    if (spots.isEmpty) return;
    final Paint core = Paint();
    final Paint glow = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2);
    const List<int> cycles = <int>[5, 6, 8];
    for (int i = 0; i < count; i++) {
      final int cyc = cycles[i % 3];
      final double u = (t * cyc + Cine.hash(i * 7)) % 1.0;
      final _Spot s = spots[(Cine.hash(i * 3 + 1) * spots.length).floor() % spots.length];
      final double rise = r.height * (0.25 + 0.5 * Cine.hash(i * 5 + 2)) * u;
      final double x = s.p.dx +
          math.sin(Cine.tau * (u * 1.4 + Cine.hash(i))) * r.width * 0.05 * u +
          r.width * 0.03 * u;
      final double y = s.p.dy - rise;
      final double a = math.pow(1 - u, 1.3).toDouble() * math.min(1.0, u * 9);
      final double rad = (0.7 + 1.7 * Cine.hash(i * 11)) * (1 - 0.55 * u);
      final Color col = Cine.mix(
        const Color(0xFFFFE9A0),
        const Color(0xFFFF7A14),
        u,
      );
      glow.color = col.withValues(alpha: a * 0.3 * hot);
      canvas.drawCircle(Offset(x, y), rad * 3, glow);
      core.color = col.withValues(alpha: Cine.clamp01(a * (0.5 + 0.5 * hot)));
      canvas.drawCircle(Offset(x, y), rad, core);
    }
    // A few drifting flakes, as in the reference.
    if (hot > 0.35) {
      final Paint fl = Paint();
      for (int i = 0; i < 7; i++) {
        final double u = (t * 3 + Cine.hash(i * 19 + 4)) % 1.0;
        final Offset p0 = spots[(i * 7) % spots.length].p;
        final double x = p0.dx + (Cine.hash(i + 70) - 0.5) * r.width * 0.3 * u;
        final double y = p0.dy - r.height * 0.5 * u;
        final double a = math.sin(math.pi * u) * 0.6 * hot;
        final double sz = 1.6 + 2.4 * Cine.hash(i + 90);
        final double rot = Cine.tau * (u + Cine.hash(i));
        fl.color = const Color(0xFFFFB44A).withValues(alpha: Cine.clamp01(a));
        final Path q = Path()
          ..moveTo(x + math.cos(rot) * sz, y + math.sin(rot) * sz)
          ..lineTo(x + math.cos(rot + 2.1) * sz * 0.7, y + math.sin(rot + 2.1) * sz * 0.7)
          ..lineTo(x + math.cos(rot + 4.0) * sz * 0.9, y + math.sin(rot + 4.0) * sz * 0.9)
          ..close();
        canvas.drawPath(q, fl);
      }
    }
  }

  /// A cinematic light streak across the heart at the highest levels.
  void _streak(Canvas canvas, Offset mid, double w, double hot, double beat) {
    if (hot < 0.6) return;
    final double k = Cine.clamp01((hot - 0.6) / 0.4);
    final Rect rr = Rect.fromCenter(
      center: Offset(mid.dx, mid.dy - 6),
      width: w * 0.95,
      height: 7,
    );
    canvas.drawRect(
      rr,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = LinearGradient(
          colors: <Color>[
            const Color(0xFFFFD27A).withValues(alpha: 0),
            const Color(0xFFFFF0B8).withValues(alpha: 0.4 * k * (0.8 + 0.2 * beat)),
            const Color(0xFFFFD27A).withValues(alpha: 0),
          ],
        ).createShader(rr),
    );
  }

  /// The one-time flare when today's heart is lit.
  void _flareFx(Canvas canvas, Offset mid, double hh, double ww) {
    final double f = flare;
    final double pulse = math.sin(math.pi * f);
    canvas.drawCircle(
      mid,
      ww,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            const Color(0xFFFFF4C8).withValues(alpha: 0.5 * pulse * pulse),
            const Color(0xFFFFB02E).withValues(alpha: 0.15 * pulse),
            const Color(0xFFFFB02E).withValues(alpha: 0),
          ],
          stops: const <double>[0, 0.4, 1],
        ).createShader(Rect.fromCircle(center: mid, radius: ww)),
    );
    for (int k = 0; k < 2; k++) {
      final double ff = Cine.clamp01(f - k * 0.14);
      if (ff <= 0) continue;
      canvas.drawCircle(
        mid,
        hh * (0.35 + 0.95 * ff),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 + 7 * (1 - ff)
          ..color = const Color(0xFFFFE9A0).withValues(
            alpha: math.pow(1 - ff, 1.5).toDouble() * 0.8,
          ),
      );
    }
    final Paint sp = Paint();
    for (int i = 0; i < 64; i++) {
      final double ang = Cine.tau * Cine.hash(i * 3 + 5);
      final double dist = math.pow(f, 0.6).toDouble() * hh * (0.55 + 0.7 * Cine.hash(i * 7 + 1));
      final double a = (1 - f) * (0.4 + 0.6 * Cine.hash(i));
      sp.color = Cine.mix(const Color(0xFFFFF0B0), const Color(0xFFFF9A2A), f)
          .withValues(alpha: Cine.clamp01(a));
      canvas.drawCircle(
        Offset(mid.dx + math.cos(ang) * dist, mid.dy + math.sin(ang) * dist),
        0.8 + 1.8 * Cine.hash(i * 11),
        sp,
      );
    }
  }
}

// END OF FILE - lib/widgets/flame_heart_fx.dart
