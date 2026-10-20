import 'dart:math' as math;

import 'package:flutter/material.dart';

/// ============================================================
/// IVORY - THE CINEMA KIT FOR THE GOLDEN HEART
///
/// Small shared pieces for the two cinematic hearts: a steady
/// pseudo-random number (so every frame agrees with the last), the
/// double beat of a heart, and the Saturn-like ring of fine golden
/// dust that circles clockwise, passes behind the heart and then in
/// front of it, with a bright head, a long fading tail, dust that
/// drifts down from it, and glints. Everything is painted; nothing
/// is an image. No black anywhere.
/// ============================================================
class Cine {
  Cine._();

  static const double tau = math.pi * 2;

  /// A steady number between 0 and 1 for [n] (the same every time).
  static double hash(int n) {
    final double s = math.sin(n * 12.9898 + 78.233) * 43758.5453;
    return s - s.floorToDouble();
  }

  static double fract(double v) => v - v.floorToDouble();

  /// One heart beat, "lub-dub", as [u] runs from 0 to 1. Returns 0 to 1.
  static double beat(double u) {
    double g(double x, double c, double w) {
      final double d = (x - c) / w;
      return math.exp(-d * d);
    }

    final double v = g(u, 0.12, 0.05) + 0.7 * g(u, 0.34, 0.06);
    return v > 1.0 ? 1.0 : v;
  }

  static double clamp01(double v) => v < 0 ? 0.0 : (v > 1 ? 1.0 : v);

  static Color mix(Color a, Color b, double t) =>
      Color.lerp(a, b, clamp01(t))!;

  static double smooth(double a, double b, double x) {
    final double t = clamp01((x - a) / (b - a));
    return t * t * (3 - 2 * t);
  }
}

class OrbitKit {
  OrbitKit._();

  static const Color _gold = Color(0xFFFFC21A);
  static const Color _pale = Color(0xFFFFF3C4);
  static const Color _amber = Color(0xFFD98A0A);

  /// The golden river of dust. [front] picks the half that passes in
  /// FRONT of the heart (the lower half of the tilted ellipse); draw
  /// the other half before the heart. [t] runs 0..1 once per orbit.
  static void ring(
    Canvas c, {
    required Offset center,
    required double rx,
    required double ry,
    required double tilt,
    required double t,
    required int n,
    required bool front,
    double alpha = 1,
    double grain = 1,
    int seed = 11,
  }) {
    if (alpha <= 0.01) return;
    c.save();
    c.translate(center.dx, center.dy);
    c.rotate(tilt);
    final Rect r = Rect.fromCenter(
      center: Offset.zero,
      width: rx * 2,
      height: ry * 2,
    );
    // The faint glow of the path itself.
    final Paint glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ry * 0.5
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, ry * 0.35)
      ..color = _gold.withValues(alpha: 0.10 * alpha);
    c.drawArc(r, front ? 0 : math.pi, math.pi, false, glow);
    final Paint hair = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = _pale.withValues(alpha: 0.16 * alpha);
    c.drawArc(r, front ? 0 : math.pi, math.pi, false, hair);

    final double head = t * Cine.tau;
    final Paint p = Paint();
    final Paint halo = Paint();
    for (int i = 0; i < n; i++) {
      final double u = i / n;
      // Dense near the head, thin far behind it.
      final double ang =
          -Cine.tau * math.pow(u, 1.7).toDouble() +
          (Cine.hash(seed + i * 3) - 0.5) * 0.05;
      final double th = ang + head;
      final double s = math.sin(th);
      if ((s > 0) != front) continue;
      final double jr = (Cine.hash(seed + i * 3 + 1) - 0.5) * 0.16 * grain;
      final double jy = (Cine.hash(seed + i * 3 + 2) - 0.5) * ry * 0.34;
      final double x = rx * (1 + jr) * math.cos(th);
      final double y = ry * (1 + jr) * s + jy;
      final double d = (-ang) % Cine.tau;
      final double tail = math.exp(-d * 0.85);
      final double b = 0.18 + 0.82 * tail;
      final double depth = 0.62 + 0.38 * s;
      final double tw =
          0.6 +
          0.4 *
              math.sin(
                Cine.tau * (t * 17 + Cine.hash(seed + i * 5)),
              );
      final double a = Cine.clamp01(b * depth * tw * alpha);
      final double rad = (0.45 + 1.35 * b) * depth * grain;
      p.color = Cine.mix(_amber, _pale, tail).withValues(alpha: a);
      c.drawCircle(Offset(x, y), rad, p);
      if (tail > 0.55) {
        halo.color = _gold.withValues(alpha: a * 0.16);
        c.drawCircle(Offset(x, y), rad * 3.2, halo);
      }
    }
    // The bright head, with a glint.
    final double hs = math.sin(head - 0.02);
    if ((hs > 0) == front) {
      final Offset hp = Offset(rx * math.cos(head - 0.02), ry * hs);
      final Paint hh = Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            _pale.withValues(alpha: 0.85 * alpha),
            _gold.withValues(alpha: 0.28 * alpha),
            _gold.withValues(alpha: 0),
          ],
          stops: const <double>[0, 0.35, 1],
        ).createShader(Rect.fromCircle(center: hp, radius: ry * 0.9));
      c.drawCircle(hp, ry * 0.9, hh);
      glint(c, hp, ry * 0.9, 0.9 * alpha);
    }
    c.restore();
  }

  /// Fine golden dust that lets go of the ring and drifts down.
  /// [wave] 0..1 is how heavily it falls just now.
  static void dust(
    Canvas c, {
    required Offset center,
    required double rx,
    required double ry,
    required double tilt,
    required double t,
    required int n,
    required double fall,
    required double wave,
    int seed = 301,
  }) {
    if (wave <= 0.01) return;
    final Paint p = Paint();
    final double cs = math.cos(tilt);
    final double sn = math.sin(tilt);
    for (int i = 0; i < n; i++) {
      const int cyc = 3;
      final double u = (t * cyc + Cine.hash(seed + i)) % 1.0;
      final double spawn = t - u / cyc;
      final double th = Cine.tau * Cine.hash(seed + i * 2 + 1) +
          Cine.tau * spawn;
      final double x0 = rx * math.cos(th);
      final double y0 = ry * math.sin(th);
      double x = center.dx + x0 * cs - y0 * sn;
      double y = center.dy + x0 * sn + y0 * cs;
      final double ph = Cine.hash(seed + i * 7) * Cine.tau;
      y += fall * (0.3 * u + 0.7 * u * u);
      x += math.sin(u * 5 + ph) * fall * 0.035;
      final double a =
          math.pow(math.sin(math.pi * u), 1.2).toDouble() *
          wave *
          (0.55 +
              0.45 * math.sin(Cine.tau * (t * 13 + Cine.hash(seed + i * 9))));
      if (a <= 0.01) continue;
      final double rad = 0.4 + 0.9 * Cine.hash(seed + i * 11);
      p.color = Cine.mix(_gold, _pale, 0.6).withValues(alpha: Cine.clamp01(a));
      c.drawCircle(Offset(x, y), rad, p);
    }
  }

  /// A soft cloud of golden specks that twinkle.
  static void cloud(
    Canvas c, {
    required Offset center,
    required double rx,
    required double ry,
    required double t,
    required int n,
    required int seed,
    double alpha = 1,
  }) {
    final Paint p = Paint();
    for (int i = 0; i < n; i++) {
      final double gx =
          (Cine.hash(seed + i * 2) +
              Cine.hash(seed + i * 2 + 1) +
              Cine.hash(seed + i * 5) -
              1.5) /
          1.5;
      final double gy =
          (Cine.hash(seed + i * 3 + 7) +
              Cine.hash(seed + i * 3 + 8) +
              Cine.hash(seed + i * 4 + 3) -
              1.5) /
          1.5;
      final double tw =
          0.25 +
          0.75 *
              (0.5 +
                  0.5 *
                      math.sin(
                        Cine.tau * (t * 5 + Cine.hash(seed + i * 13)),
                      ));
      p.color = _gold.withValues(alpha: Cine.clamp01(0.55 * tw * alpha));
      c.drawCircle(
        Offset(center.dx + gx * rx, center.dy + gy * ry),
        0.4 + 0.8 * Cine.hash(seed + i * 17),
        p,
      );
    }
  }

  /// A four-pointed glint.
  static void glint(Canvas c, Offset p, double r, double a) {
    final double al = Cine.clamp01(a);
    if (al <= 0.01) return;
    final double w = r * 0.12;
    final Paint pt = Paint()..color = _pale.withValues(alpha: al);
    final Path v = Path()
      ..moveTo(p.dx, p.dy - r)
      ..lineTo(p.dx + w, p.dy)
      ..lineTo(p.dx, p.dy + r)
      ..lineTo(p.dx - w, p.dy)
      ..close();
    final Path h = Path()
      ..moveTo(p.dx - r * 0.8, p.dy)
      ..lineTo(p.dx, p.dy - w)
      ..lineTo(p.dx + r * 0.8, p.dy)
      ..lineTo(p.dx, p.dy + w)
      ..close();
    c.drawPath(v, pt);
    c.drawPath(h, pt);
    c.drawCircle(
      p,
      r * 0.22,
      Paint()..color = Colors.white.withValues(alpha: al * 0.8),
    );
  }
}

// END OF FILE - lib/widgets/heart_cine.dart
