import 'dart:math' as math;
import 'dart:typed_data' show Float64List;

import 'package:flutter/material.dart';

import 'heart_paint.dart';

/// ============================================================
/// IVORY - TREASURE BADGES, DRAWN IN CODE
///
/// Eight shapes (medal, shield, crest, star, key, crown, heart,
/// laurel) in five metals (gold, rose, pearl, emerald, ruby): a
/// bevelled rim, a recessed plate, an emblem, a highlight and a sheen
/// that sweeps across. A locked treasure is a pale silhouette. No
/// pictures are uploaded, so every badge matches the rest of Ivory.
/// ============================================================
class BadgeMetal {
  const BadgeMetal(this.shine, this.light, this.mid, this.deep, this.rim);

  final Color shine;
  final Color light;
  final Color mid;
  final Color deep;
  final Color rim;

  static const BadgeMetal gold = BadgeMetal(
    Color(0xFFFFF7CF),
    Color(0xFFFFDB4D),
    Color(0xFFF5B800),
    Color(0xFFC98600),
    Color(0xFF8F5B00),
  );
  static const BadgeMetal rose = BadgeMetal(
    Color(0xFFFFEDE6),
    Color(0xFFF6BBAA),
    Color(0xFFE08E85),
    Color(0xFFB25A5E),
    Color(0xFF7A2F3A),
  );
  static const BadgeMetal pearl = BadgeMetal(
    Color(0xFFFFFFFF),
    Color(0xFFF3EDF3),
    Color(0xFFDACFDC),
    Color(0xFFA99BAE),
    Color(0xFF76607F),
  );
  static const BadgeMetal emerald = BadgeMetal(
    Color(0xFFD5F2E3),
    Color(0xFF6FCFA2),
    Color(0xFF218A5F),
    Color(0xFF0E5C41),
    Color(0xFF07402C),
  );
  static const BadgeMetal ruby = BadgeMetal(
    Color(0xFFFFD6DC),
    Color(0xFFF0788A),
    Color(0xFFC8283F),
    Color(0xFF8E1426),
    Color(0xFF4A0E17),
  );

  static BadgeMetal named(String n) {
    switch (n) {
      case 'rose':
        return rose;
      case 'pearl':
        return pearl;
      case 'emerald':
        return emerald;
      case 'ruby':
        return ruby;
      default:
        return gold;
    }
  }
}

Path _poly(Rect r, List<List<double>> pts) {
  final Path p = Path();
  for (int i = 0; i < pts.length; i++) {
    final double x = r.left + r.width * pts[i][0];
    final double y = r.top + r.height * pts[i][1];
    i == 0 ? p.moveTo(x, y) : p.lineTo(x, y);
  }
  return p..close();
}

Path _scaled(Path p, Rect r, double k) {
  final Offset c = r.center;
  return p.transform(
    Float64List.fromList(<double>[
      k, 0, 0, 0, //
      0, k, 0, 0, //
      0, 0, 1, 0, //
      c.dx * (1 - k), c.dy * (1 - k), 0, 1,
    ]),
  );
}

/// The outline of a badge inside [r].
Path badgeOutline(String shape, Rect r) {
  Offset o(double x, double y) =>
      Offset(r.left + r.width * x, r.top + r.height * y);
  switch (shape) {
    case 'shield':
      return Path()
        ..moveTo(o(0.5, 0.04).dx, o(0.5, 0.04).dy)
        ..cubicTo(
          o(0.66, 0.12).dx,
          o(0.66, 0.12).dy,
          o(0.80, 0.12).dx,
          o(0.80, 0.12).dy,
          o(0.90, 0.10).dx,
          o(0.90, 0.10).dy,
        )
        ..lineTo(o(0.90, 0.46).dx, o(0.90, 0.46).dy)
        ..cubicTo(
          o(0.90, 0.72).dx,
          o(0.90, 0.72).dy,
          o(0.70, 0.86).dx,
          o(0.70, 0.86).dy,
          o(0.5, 0.97).dx,
          o(0.5, 0.97).dy,
        )
        ..cubicTo(
          o(0.30, 0.86).dx,
          o(0.30, 0.86).dy,
          o(0.10, 0.72).dx,
          o(0.10, 0.72).dy,
          o(0.10, 0.46).dx,
          o(0.10, 0.46).dy,
        )
        ..lineTo(o(0.10, 0.10).dx, o(0.10, 0.10).dy)
        ..cubicTo(
          o(0.20, 0.12).dx,
          o(0.20, 0.12).dy,
          o(0.34, 0.12).dx,
          o(0.34, 0.12).dy,
          o(0.5, 0.04).dx,
          o(0.5, 0.04).dy,
        )
        ..close();
    case 'crest':
      return _poly(r, <List<double>>[
        <double>[0.5, 0.03],
        <double>[0.92, 0.26],
        <double>[0.92, 0.74],
        <double>[0.5, 0.97],
        <double>[0.08, 0.74],
        <double>[0.08, 0.26],
      ]);
    case 'star':
      final List<List<double>> pts = <List<double>>[];
      for (int i = 0; i < 10; i++) {
        final double a = -math.pi / 2 + i * math.pi / 5;
        final double k = i.isEven ? 0.5 : 0.23;
        pts.add(<double>[0.5 + k * math.cos(a), 0.54 + k * math.sin(a)]);
      }
      return _poly(r, pts);
    case 'key':
      Path p = Path()
        ..addOval(
          Rect.fromCircle(center: o(0.5, 0.27), radius: r.width * 0.23),
        );
      p = Path.combine(
        PathOperation.union,
        p,
        Path()..addRect(
          Rect.fromLTRB(
            o(0.455, 0).dx,
            o(0, 0.30).dy,
            o(0.545, 0).dx,
            o(0, 0.96).dy,
          ),
        ),
      );
      p = Path.combine(
        PathOperation.union,
        p,
        Path()..addRect(
          Rect.fromLTRB(
            o(0.5, 0).dx,
            o(0, 0.66).dy,
            o(0.72, 0).dx,
            o(0, 0.74).dy,
          ),
        ),
      );
      p = Path.combine(
        PathOperation.union,
        p,
        Path()..addRect(
          Rect.fromLTRB(
            o(0.5, 0).dx,
            o(0, 0.80).dy,
            o(0.66, 0).dx,
            o(0, 0.88).dy,
          ),
        ),
      );
      return Path.combine(
        PathOperation.difference,
        p,
        Path()..addOval(
          Rect.fromCircle(center: o(0.5, 0.27), radius: r.width * 0.09),
        ),
      );
    case 'crown':
      return _poly(r, <List<double>>[
        <double>[0.06, 0.94],
        <double>[0.06, 0.28],
        <double>[0.29, 0.54],
        <double>[0.5, 0.10],
        <double>[0.71, 0.54],
        <double>[0.94, 0.28],
        <double>[0.94, 0.94],
      ]);
    case 'heart':
      return heartPath(r.deflate(r.width * 0.03));
    case 'laurel':
    case 'medal':
    default:
      final double rad = r.width * (shape == 'medal' ? 0.34 : 0.46);
      return Path()..addOval(
        Rect.fromCircle(
          center: o(0.5, shape == 'medal' ? 0.40 : 0.5),
          radius: rad,
        ),
      );
  }
}

class BadgePainter extends CustomPainter {
  BadgePainter({
    required this.shape,
    required this.metal,
    required this.t,
    this.locked = false,
  });

  final String shape;
  final BadgeMetal metal;
  final double t;
  final bool locked;

  void _star(Canvas c, Offset o, double rad, Paint fill, Paint line) {
    final Path p = Path();
    for (int i = 0; i < 10; i++) {
      final double a = -math.pi / 2 + i * math.pi / 5;
      final double k = i.isEven ? rad : rad * 0.45;
      final double x = o.dx + k * math.cos(a);
      final double y = o.dy + k * math.sin(a);
      i == 0 ? p.moveTo(x, y) : p.lineTo(x, y);
    }
    p.close();
    c.drawPath(p, fill);
    c.drawPath(p, line);
  }

  @override
  void paint(Canvas c, Size s) {
    final double side = math.min(s.width, s.height);
    final Rect r = Rect.fromCenter(
      center: Offset(s.width / 2, s.height * (shape == 'medal' ? 0.46 : 0.5)),
      width: side * 0.86,
      height: side * 0.86,
    );
    final Path base = badgeOutline(shape, r);
    final BadgeMetal m = metal;

    if (locked) {
      c.drawPath(base, Paint()..color = const Color(0xFFEBDDE0));
      c.drawPath(
        base,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.2, side * 0.02)
          ..strokeJoin = StrokeJoin.round
          ..color = const Color(0xFFC9A7AE),
      );
      return;
    }

    c.drawPath(
      base.shift(Offset(0, side * 0.035)),
      Paint()
        ..color = const Color(0xFF4A0E17).withValues(alpha: 0.30)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, side * 0.03),
    );
    if (shape == 'medal') {
      for (final double dir in <double>[-1, 1]) {
        final Path rb = Path()
          ..moveTo(r.center.dx + dir * r.width * 0.05, r.top + r.height * 0.55)
          ..lineTo(r.center.dx + dir * r.width * 0.30, r.top + r.height * 1.06)
          ..lineTo(r.center.dx + dir * r.width * 0.17, r.top + r.height * 0.99)
          ..lineTo(r.center.dx + dir * r.width * 0.06, r.top + r.height * 1.06)
          ..close();
        c.drawPath(
          rb,
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[Color(0xFFC8283F), Color(0xFF7A1F33)],
            ).createShader(r),
        );
      }
    }
    final Paint metalPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[m.shine, m.light, m.mid, m.deep, m.rim],
        stops: const <double>[0, 0.22, 0.5, 0.8, 1],
      ).createShader(r);
    c.drawPath(base, metalPaint);

    final bool thin = shape == 'key' || shape == 'crown';
    if (!thin) {
      final Path inset = _scaled(base, r, shape == 'star' ? 0.56 : 0.78);
      c.drawPath(
        inset,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[m.deep, m.mid, m.light],
          ).createShader(r),
      );
      c.drawPath(
        inset,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(0.8, side * 0.012)
          ..strokeJoin = StrokeJoin.round
          ..color = m.shine.withValues(alpha: 0.7),
      );
    }

    final Paint emFill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[m.shine, m.light, m.mid],
      ).createShader(r);
    final Paint emLine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, side * 0.012)
      ..strokeJoin = StrokeJoin.round
      ..color = m.rim;
    final Offset mid = Offset(
      r.center.dx,
      shape == 'medal' ? r.top + r.height * 0.40 : r.center.dy,
    );
    if (shape == 'crown') {
      for (final List<double> g in <List<double>>[
        <double>[0.06, 0.28],
        <double>[0.5, 0.10],
        <double>[0.94, 0.28],
      ]) {
        c.drawCircle(
          Offset(r.left + r.width * g[0], r.top + r.height * g[1]),
          side * 0.045,
          Paint()..color = const Color(0xFFE8506A),
        );
      }
    } else if (shape != 'key' && shape != 'star') {
      _star(c, mid, side * 0.17, emFill, emLine);
    }
    if (shape == 'laurel') {
      for (int i = 0; i < 7; i++) {
        final double a = math.pi * (0.62 + i * 0.13);
        for (final double dir in <double>[-1, 1]) {
          final double ang = dir < 0 ? a : math.pi - a;
          final Offset lp = Offset(
            mid.dx + math.cos(ang) * r.width * 0.33,
            mid.dy + math.sin(ang) * r.width * 0.33,
          );
          c.save();
          c.translate(lp.dx, lp.dy);
          c.rotate(ang + math.pi / 2 + dir * 0.5);
          c.drawOval(
            Rect.fromCenter(
              center: Offset.zero,
              width: side * 0.05,
              height: side * 0.12,
            ),
            emFill,
          );
          c.restore();
        }
      }
    }

    c.save();
    c.clipPath(base);
    c.drawRect(
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.45, -0.55),
          radius: 0.8,
          colors: <Color>[
            Colors.white.withValues(alpha: 0.5),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(r),
    );
    final double q = (t * 1.6) % 1.6;
    if (q < 1) {
      c.translate(r.center.dx, r.center.dy);
      c.rotate(-0.55);
      final Rect band = Rect.fromLTWH(
        -r.width * 1.1 + q * r.width * 2.2,
        -r.height,
        r.width * 0.22,
        r.height * 2,
      );
      c.drawRect(
        band,
        Paint()
          ..shader = LinearGradient(
            colors: <Color>[
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: 0.55),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(band),
      );
    }
    c.restore();

    c.drawPath(
      base,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, side * 0.03)
        ..strokeJoin = StrokeJoin.round
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[m.shine, m.mid, m.rim, m.mid, m.light],
        ).createShader(r),
    );
  }

  @override
  bool shouldRepaint(BadgePainter o) =>
      o.t != t || o.shape != shape || o.metal != metal || o.locked != locked;
}

/// A badge as a widget. It shines by itself unless [animate] is false.
class RewardBadge extends StatefulWidget {
  const RewardBadge({
    super.key,
    required this.shape,
    required this.metal,
    this.size = 88,
    this.locked = false,
    this.animate = true,
  });

  final String shape;
  final String metal;
  final double size;
  final bool locked;
  final bool animate;

  @override
  State<RewardBadge> createState() => _RewardBadgeState();
}

class _RewardBadgeState extends State<RewardBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4800),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate && !widget.locked) _c.repeat();
  }

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
          builder: (BuildContext _, Widget? __) => CustomPaint(
            painter: BadgePainter(
              shape: widget.shape,
              metal: BadgeMetal.named(widget.metal),
              t: _c.value,
              locked: widget.locked,
            ),
          ),
        ),
      ),
    );
  }
}

// END OF FILE - lib/widgets/reward_badge.dart
