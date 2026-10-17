import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'gold_fx.dart';

/// ============================================================
/// IVORY - THE GOLDEN HEART: THE JEWELLERY THAT GLOW EARNS
///
/// Tier 1 Ember: a few rising embers.      Tier 2 Flame: a flame.
/// Tier 3 Radiant: turning rays of light.  Tier 4 Brilliant: stars
/// that orbit. Tier 5 Golden: a stronger halo. Tier 6 Sovereign: a
/// crown. Tier 7 Eternal: a ring of gold around the heart. Tier 8
/// Crowned: a larger crown and a brighter ring. A tier the house adds
/// later simply keeps the richest look.
/// ============================================================
class HeartDecor {
  HeartDecor._();

  static const List<double> _halo = <double>[
    0.0,
    0.16,
    0.22,
    0.28,
    0.32,
    0.38,
    0.44,
    0.48,
    0.54,
  ];

  static double _pulse(double t) => 0.5 + 0.5 * math.sin(t * math.pi * 2);

  /// Everything that sits BEHIND the heart.
  static void back(Canvas c, Rect h, double t, int tier) {
    if (tier <= 0) return;
    final int ti = tier.clamp(0, 8);
    final Offset mid = h.center;
    final double halo = _halo[ti] * (0.78 + 0.22 * _pulse(t));
    final double r = h.width * (0.78 + 0.05 * ti / 8);
    c.drawCircle(
      mid,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            GoldTones.light.withValues(alpha: halo),
            GoldTones.mid.withValues(alpha: halo * 0.4),
            GoldTones.mid.withValues(alpha: 0),
          ],
          stops: const <double>[0.35, 0.7, 1],
        ).createShader(Rect.fromCircle(center: mid, radius: r)),
    );
    if (ti >= 3) _rays(c, mid, h.width, t, ti >= 5 ? 16 : 10, ti);
    if (ti >= 7) _ring(c, h, t, ti, back: true);
    if (ti == 1) _embers(c, h, t);
  }

  /// Everything that sits IN FRONT of the heart.
  static void front(Canvas c, Rect h, double t, int tier) {
    if (tier <= 0) return;
    final int ti = tier.clamp(0, 8);
    if (ti == 2) _flame(c, h, t);
    if (ti >= 7) _ring(c, h, t, ti, back: false);
    if (ti >= 6) _crown(c, h, t, ti >= 8);
    if (ti >= 4) _orbit(c, h, t, ti >= 7 ? 8 : 5);
  }

  static void _rays(Canvas c, Offset mid, double w, double t, int n, int ti) {
    final double R = w * 1.0;
    final Paint p = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          GoldTones.shine.withValues(alpha: 0.30 + 0.02 * ti),
          GoldTones.light.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: mid, radius: R));
    final double spin = t * math.pi * 2 * 0.5;
    for (int i = 0; i < n; i++) {
      final double a = spin + i * math.pi * 2 / n;
      final double wd = math.pi / n * 0.42;
      final Path ray = Path()
        ..moveTo(mid.dx, mid.dy)
        ..lineTo(mid.dx + R * math.cos(a - wd), mid.dy + R * math.sin(a - wd))
        ..lineTo(mid.dx + R * math.cos(a + wd), mid.dy + R * math.sin(a + wd))
        ..close();
      c.drawPath(ray, p);
    }
  }

  static void _embers(Canvas c, Rect h, double t) {
    for (int i = 0; i < 4; i++) {
      final double ph = (t * 1.5 + i * 0.27) % 1.0;
      final double x =
          h.left +
          h.width * (0.30 + 0.13 * i) +
          math.sin(ph * 6 + i) * h.width * 0.02;
      final double y = h.top + h.height * 0.10 - ph * h.height * 0.16;
      final double a = (1 - ph).clamp(0.0, 1.0);
      c.drawCircle(
        Offset(x, y),
        h.width * 0.016 + h.width * 0.006 * (1 - ph),
        Paint()
          ..color = GoldTones.light.withValues(alpha: 0.9 * a)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6),
      );
    }
  }

  static void _flame(Canvas c, Rect h, double t) {
    final double fl = 0.9 + 0.1 * math.sin(t * math.pi * 14);
    final double fw = h.width * 0.13 * fl;
    final double fh =
        h.height * 0.2 * (0.92 + 0.08 * math.sin(t * math.pi * 10));
    final Offset base = Offset(h.center.dx, h.top + h.height * 0.24);
    final Path f = Path()
      ..moveTo(base.dx, base.dy)
      ..cubicTo(
        base.dx - fw * 1.3,
        base.dy - fh * 0.2,
        base.dx - fw * 0.5,
        base.dy - fh * 0.7,
        base.dx + math.sin(t * 9) * fw * 0.2,
        base.dy - fh,
      )
      ..cubicTo(
        base.dx + fw * 0.6,
        base.dy - fh * 0.65,
        base.dx + fw * 1.3,
        base.dy - fh * 0.2,
        base.dx,
        base.dy,
      )
      ..close();
    c.drawPath(
      f,
      Paint()
        ..color = GoldTones.light.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    c.drawPath(
      f,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: const <Color>[GoldTones.deep, GoldTones.mid, GoldTones.shine],
        ).createShader(f.getBounds()),
    );
  }

  static void _star(Canvas c, Offset o, double r, Color col) {
    final Path s = Path()
      ..moveTo(o.dx, o.dy - r)
      ..quadraticBezierTo(o.dx, o.dy, o.dx + r, o.dy)
      ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy + r)
      ..quadraticBezierTo(o.dx, o.dy, o.dx - r, o.dy)
      ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy - r)
      ..close();
    c.drawPath(s, Paint()..color = col);
  }

  static void _orbit(Canvas c, Rect h, double t, int n) {
    final Offset mid = h.center;
    for (int i = 0; i < n; i++) {
      final double a = t * math.pi * 2 * 0.35 + i * math.pi * 2 / n;
      final double rx = h.width * (0.62 + 0.04 * (i % 2));
      final double ry = h.height * (0.52 + 0.05 * (i % 3));
      final double tw = 0.5 + 0.5 * math.sin(t * math.pi * 6 + i * 1.7);
      _star(
        c,
        Offset(mid.dx + rx * math.cos(a), mid.dy + ry * math.sin(a)),
        h.width * (0.025 + 0.03 * tw),
        GoldTones.shine.withValues(alpha: 0.45 + 0.5 * tw),
      );
    }
  }

  static void _ring(Canvas c, Rect h, double t, int ti, {required bool back}) {
    final Rect e = Rect.fromCenter(
      center: Offset(h.center.dx, h.top + h.height * 0.52),
      width: h.width * 1.32,
      height: h.width * 0.34,
    );
    c.save();
    c.translate(e.center.dx, e.center.dy);
    c.rotate(-0.2);
    c.translate(-e.center.dx, -e.center.dy);
    final Paint p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = h.width * (ti >= 8 ? 0.032 : 0.02)
      ..shader = const LinearGradient(
        colors: <Color>[
          GoldTones.deep,
          GoldTones.shine,
          GoldTones.mid,
          GoldTones.shine,
          GoldTones.deep,
        ],
      ).createShader(e);
    if (back) {
      c.drawArc(
        e,
        math.pi,
        math.pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = p.strokeWidth
          ..color = GoldTones.mid.withValues(alpha: 0.5),
      );
    } else {
      c.drawArc(e, 0, math.pi, false, p);
      final double a = t * math.pi * 2;
      final Offset d = Offset(
        e.center.dx + e.width / 2 * math.cos(a),
        e.center.dy + e.height / 2 * math.sin(a),
      );
      if (math.sin(a) > 0) {
        _star(c, d, h.width * 0.05, GoldTones.shine);
      }
    }
    c.restore();
  }

  static void _crown(Canvas c, Rect h, double t, bool big) {
    final double cw = h.width * (big ? 0.40 : 0.30);
    final double ch = cw * 0.78;
    final double bx = h.center.dx - cw / 2;
    final double by = h.top + h.height * 0.215;
    final Path p = Path()
      ..moveTo(bx, by)
      ..lineTo(bx - cw * 0.02, by - ch * 0.62)
      ..lineTo(bx + cw * 0.25, by - ch * 0.34)
      ..lineTo(bx + cw * 0.5, by - ch)
      ..lineTo(bx + cw * 0.75, by - ch * 0.34)
      ..lineTo(bx + cw * 1.02, by - ch * 0.62)
      ..lineTo(bx + cw, by)
      ..close();
    c.drawPath(
      p.shift(Offset(0, h.width * 0.012)),
      Paint()
        ..color = const Color(0xFF4A0E17).withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    c.drawPath(
      p,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            GoldTones.shine,
            GoldTones.light,
            GoldTones.mid,
            GoldTones.deep,
          ],
        ).createShader(p.getBounds()),
    );
    c.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = h.width * 0.012
        ..strokeJoin = StrokeJoin.round
        ..color = GoldTones.rim,
    );
    const Color gem = Color(0xFFE8506A);
    final double tw = 0.6 + 0.4 * _pulse(t);
    for (final Offset g in <Offset>[
      Offset(bx - cw * 0.02, by - ch * 0.62),
      Offset(bx + cw * 0.5, by - ch),
      Offset(bx + cw * 1.02, by - ch * 0.62),
    ]) {
      c.drawCircle(g, cw * 0.06, Paint()..color = gem);
      c.drawCircle(
        g.translate(-cw * 0.015, -cw * 0.015),
        cw * 0.02,
        Paint()..color = Colors.white.withValues(alpha: 0.85 * tw),
      );
    }
  }
}

// END OF FILE - lib/widgets/heart_decor.dart
