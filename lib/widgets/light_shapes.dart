import 'dart:math' as math;

import 'package:flutter/material.dart';

/// ============================================================
/// IVORY - THE SHAPES OF THE RISING LIGHTS
///
/// Two painted objects for the Ten-Day Vault (see rising_lights.dart):
/// a round paper lantern, shaded like a real one, and a cut jewel
/// that turns and flashes. Pure painting.
/// ============================================================

Color lightShade(Color c, double a) =>
    Color.lerp(c, const Color(0xFFFFFFFF), a)!;
Color deepShade(Color c, double a) =>
    Color.lerp(c, const Color(0xFF4A0E17), a)!;

void paintLantern(
  Canvas c,
  double x,
  double y,
  double s,
  Color base,
  double phase,
  double t,
  bool onDark,
) {
  final double flick = 0.84 + 0.16 * math.sin(t * 9 + phase * 20);
  final double hh = s * 1.0;
  final double wTop = s * 0.64;
  final double wBot = s * 0.5;

  // The halo.
  final Rect halo = Rect.fromCircle(center: Offset(x, y), radius: s * 1.9);
  c.drawCircle(
    Offset(x, y),
    s * 1.9,
    Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          lightShade(base, 0.35).withValues(alpha: (onDark ? 0.5 : 0.42) * flick),
          base.withValues(alpha: 0),
        ],
      ).createShader(halo)
      ..blendMode = onDark ? BlendMode.plus : BlendMode.srcOver,
  );

  // The body, shaded like a round lantern.
  final Path body = Path()
    ..moveTo(x - wTop / 2, y - hh / 2)
    ..quadraticBezierTo(x - s * 0.5, y, x - wBot / 2, y + hh / 2)
    ..lineTo(x + wBot / 2, y + hh / 2)
    ..quadraticBezierTo(x + s * 0.5, y, x + wTop / 2, y - hh / 2)
    ..close();
  final Rect bb = Rect.fromLTWH(x - s * 0.5, y - hh / 2, s, hh);
  c.drawPath(
    body,
    Paint()
      ..shader = LinearGradient(
        colors: <Color>[
          deepShade(base, 0.5),
          base,
          lightShade(base, 0.5),
          base,
          deepShade(base, 0.45),
        ],
        stops: const <double>[0, 0.24, 0.5, 0.78, 1],
      ).createShader(bb),
  );
  c.save();
  c.clipPath(body);
  // The flame inside lights the paper from within.
  c.drawRect(
    bb,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, 0.25),
        radius: 0.75,
        colors: <Color>[
          const Color(0xFFFFF6C8).withValues(alpha: 0.9 * flick),
          const Color(0xFFFFD36A).withValues(alpha: 0.35 * flick),
          const Color(0xFFFFD36A).withValues(alpha: 0),
        ],
        stops: const <double>[0, 0.4, 1],
      ).createShader(bb),
  );
  // Ribs.
  final Paint rib = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(0.8, s * 0.018)
    ..color = deepShade(base, 0.6).withValues(alpha: 0.35);
  for (int i = -2; i <= 2; i++) {
    final double f = i * 0.2;
    final Path r = Path()
      ..moveTo(x + wTop * f, y - hh / 2)
      ..quadraticBezierTo(x + s * f * 1.15, y, x + wBot * f, y + hh / 2);
    c.drawPath(r, rib);
  }
  // A soft highlight down the left.
  c.drawRect(
    Rect.fromLTWH(x - s * 0.34, y - hh / 2, s * 0.12, hh),
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          const Color(0xFFFFFFFF).withValues(alpha: 0.45),
          const Color(0xFFFFFFFF).withValues(alpha: 0.05),
        ],
      ).createShader(Rect.fromLTWH(x - s * 0.34, y - hh / 2, s * 0.12, hh)),
  );
  c.restore();

  // Brass caps and the tassel.
  final Paint cap = Paint()
    ..shader = const LinearGradient(
      colors: <Color>[
        Color(0xFF9A6200),
        Color(0xFFFFE27A),
        Color(0xFFC98A06),
      ],
    ).createShader(bb);
  c.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(x, y - hh / 2),
        width: wTop + s * 0.08,
        height: s * 0.1,
      ),
      Radius.circular(s * 0.05),
    ),
    cap,
  );
  c.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(x, y + hh / 2),
        width: wBot + s * 0.08,
        height: s * 0.1,
      ),
      Radius.circular(s * 0.05),
    ),
    cap,
  );
  final double sw = math.sin(t * 1.6 + phase * 9) * s * 0.04;
  c.drawLine(
    Offset(x, y + hh / 2 + s * 0.05),
    Offset(x + sw, y + hh / 2 + s * 0.3),
    Paint()
      ..color = const Color(0xFFFFD34D)
      ..strokeWidth = math.max(1, s * 0.03)
      ..strokeCap = StrokeCap.round,
  );
  c.drawCircle(
    Offset(x + sw, y + hh / 2 + s * 0.33),
    s * 0.05,
    Paint()..color = const Color(0xFFFFD34D),
  );
  // A loop to hang it by.
  c.drawArc(
    Rect.fromCenter(
      center: Offset(x, y - hh / 2 - s * 0.08),
      width: s * 0.2,
      height: s * 0.16,
    ),
    math.pi,
    math.pi,
    false,
    Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFFC98A06)
      ..strokeWidth = math.max(1, s * 0.03),
  );
}

void paintGem(
  Canvas c,
  double x,
  double y,
  double r,
  Color base,
  double phase,
  double spinRate,
  double t,
  bool onDark,
) {
  final double spin = t * spinRate + phase * 6.2832;
  // The glow behind the stone.
  final Rect g = Rect.fromCircle(center: Offset(x, y), radius: r * 2.1);
  c.drawCircle(
    Offset(x, y),
    r * 2.1,
    Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          lightShade(base, 0.2).withValues(alpha: onDark ? 0.5 : 0.42),
          base.withValues(alpha: 0),
        ],
      ).createShader(g)
      ..blendMode = onDark ? BlendMode.plus : BlendMode.srcOver,
  );

  c.save();
  c.translate(x, y);
  c.rotate(math.sin(spin * 0.5) * 0.18);
  // Turning on its axis: the stone narrows and widens.
  final double sx = 0.3 + 0.7 * math.cos(spin).abs();
  c.scale(sx, 1);
  Offset o(double a, double b) => Offset(a * r, b * r);
  final Offset a = o(-0.5, -0.62);
  final Offset b = o(0.5, -0.62);
  final Offset g1 = o(0.3, -0.12);
  final Offset h1 = o(-0.3, -0.12);
  final Offset d = o(-1, -0.12);
  final Offset cc = o(1, -0.12);
  final Offset e = o(0, 1.05);
  final double face = math.cos(spin) >= 0 ? 1.0 : -1.0;
  // Pavilion (the underside), then the crown on top.
  _facet(c, <Offset>[d, h1, e], deepShade(base, face > 0 ? 0.05 : 0.3));
  _facet(c, <Offset>[h1, g1, e], lightShade(base, 0.05));
  _facet(c, <Offset>[g1, cc, e], deepShade(base, face > 0 ? 0.3 : 0.05));
  _facet(c, <Offset>[a, h1, d], lightShade(base, 0.28));
  _facet(c, <Offset>[b, cc, g1], deepShade(base, 0.12));
  _facet(c, <Offset>[a, b, g1, h1], lightShade(base, 0.55));
  // The flash: a four-point star on the table now and then.
  final double fl = math
      .pow(math.max(0.0, math.sin(t * 2.4 + phase * 30)), 14)
      .toDouble();
  if (fl > 0.06) {
    final Paint sp = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: fl)
      ..strokeWidth = math.max(1.0, r * 0.1)
      ..strokeCap = StrokeCap.round;
    final Offset q = o(-0.2, -0.45);
    final double len = r * (0.5 + 1.1 * fl);
    c.drawLine(q.translate(-len, 0), q.translate(len, 0), sp);
    c.drawLine(q.translate(0, -len), q.translate(0, len), sp);
    c.drawCircle(q, r * 0.16 * fl, Paint()..color = const Color(0xFFFFFFFF));
  }
  c.restore();
}

void _facet(Canvas c, List<Offset> pts, Color col) {
  final Path p = Path()..moveTo(pts[0].dx, pts[0].dy);
  for (int i = 1; i < pts.length; i++) {
    p.lineTo(pts[i].dx, pts[i].dy);
  }
  p.close();
  c.drawPath(p, Paint()..color = col);
  c.drawPath(
    p,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.55),
  );
}

// END OF FILE - lib/widgets/light_shapes.dart
