import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'ladder_glyphs.dart';

/// ============================================================
/// IVORY - THE IVORY LADDER: COLOURS AND PAINTERS
///
/// A deep teal page (never black), a glowing ladder whose lit rungs
/// run from teal to mint, rarity medallions with a travelling shine,
/// and a five-point star for every Full Day.
/// ============================================================
class LadderTones {
  static const Color teal = Color(0xFF063F46);
  static const Color tealMid = Color(0xFF0A5560);
  static const Color tealDeep = Color(0xFF052F3A);
  static const Color mint = Color(0xFF4DF0C8);
  static const Color aqua = Color(0xFF52D4FF);
  static const Color rose = Color(0xFFFF7FA8);
  static const Color sun = Color(0xFFFFC85A);
  static const Color violet = Color(0xFFB78BFF);
  static const Color pearl = Color(0xFFDDF4F2);
  static const Color mist = Color(0xFF8FC4C4);

  /// Colours of the five rarities: common to legendary.
  static const List<Color> rarity = <Color>[
    Color(0xFFCFE6EA),
    Color(0xFF4DF0A8),
    Color(0xFF52C7FF),
    Color(0xFFB78BFF),
    Color(0xFFFF9E6B),
  ];

  static const List<String> rarityName = <String>[
    'COMMON',
    'UNCOMMON',
    'RARE',
    'EPIC',
    'LEGENDARY',
  ];

  static Color mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;
}

/// The ladder: two rails, [rungs] rungs, the climbed part glowing and a
/// bright climber riding between the current rung and the next.
/// Row 0 is the TOP rung (the highest); [current] counts from the bottom.
class LadderPainter extends CustomPainter {
  LadderPainter({
    required this.rungs,
    required this.current,
    required this.climb,
    required this.t,
  }) : super(repaint: null);

  final int rungs;

  /// 0-based index (from the bottom) of the rung the member stands on.
  final int current;

  /// 0..1 progress towards the next rung.
  final double climb;

  /// 0..1 looping animation time.
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final double rowH = size.height / rungs;
    final double xl = size.width * 0.22;
    final double xr = size.width * 0.78;
    double yOf(double fromBottom) => size.height - rowH * (fromBottom + 0.5);
    final double yClimber = yOf(current + (current >= rungs - 1 ? 0 : climb));

    final Paint dim = Paint()
      ..color = LadderTones.mist.withValues(alpha: 0.32)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(xl, 0), Offset(xl, size.height), dim);
    canvas.drawLine(Offset(xr, 0), Offset(xr, size.height), dim);

    // The lit part of the rails, from the bottom up to the climber.
    final Rect lit = Rect.fromLTRB(0, yClimber, size.width, size.height);
    final Shader litShader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[LadderTones.mint, LadderTones.aqua],
    ).createShader(lit);
    final Paint glow = Paint()
      ..shader = litShader
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    final Paint rail = Paint()
      ..shader = litShader
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    for (final double x in <double>[xl, xr]) {
      canvas.drawLine(Offset(x, yClimber), Offset(x, size.height), glow);
      canvas.drawLine(Offset(x, yClimber), Offset(x, size.height), rail);
    }

    for (int i = 0; i < rungs; i++) {
      final double y = yOf(i.toDouble());
      final bool reached = i <= current;
      final bool isNow = i == current;
      if (reached) {
        final Color c = LadderTones.mix(
          LadderTones.aqua,
          LadderTones.mint,
          i / math.max(1, rungs - 1),
        );
        canvas.drawLine(
          Offset(xl, y),
          Offset(xr, y),
          Paint()
            ..color = c.withValues(alpha: isNow ? 0.8 : 0.45)
            ..strokeWidth = isNow ? 15 : 10
            ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
        canvas.drawLine(
          Offset(xl, y),
          Offset(xr, y),
          Paint()
            ..color = c
            ..strokeWidth = isNow ? 7 : 5
            ..strokeCap = StrokeCap.round,
        );
        // A slow shine running along the rung.
        final double sx = xl + (xr - xl) * ((t + i * 0.13) % 1.0);
        canvas.drawCircle(
          Offset(sx, y),
          isNow ? 3.4 : 2.4,
          Paint()..color = Colors.white.withValues(alpha: 0.9),
        );
      } else {
        canvas.drawLine(
          Offset(xl, y),
          Offset(xr, y),
          Paint()
            ..color = LadderTones.mist.withValues(alpha: 0.4)
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    // Sparks drifting up the lit rails.
    for (int k = 0; k < 8; k++) {
      final double p = (t * 1.3 + k * 0.125) % 1.0;
      final double x = (k.isEven ? xl : xr) + math.sin((t + k) * 6.28) * 4;
      final double y = size.height - (size.height - yClimber) * p;
      canvas.drawCircle(
        Offset(x, y),
        1.8,
        Paint()..color = Colors.white.withValues(alpha: (1 - p) * 0.8),
      );
    }

    // The climber: a pulsing orb of light.
    final double pulse = 0.5 + 0.5 * math.sin(t * math.pi * 2 * 2);
    final Offset c = Offset(size.width / 2, yClimber);
    canvas.drawCircle(
      c,
      20 + pulse * 6,
      Paint()
        ..color = LadderTones.mint.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawCircle(
      c,
      9,
      Paint()
        ..shader = const RadialGradient(
          colors: <Color>[Colors.white, LadderTones.mint],
        ).createShader(Rect.fromCircle(center: c, radius: 9)),
    );
  }

  @override
  bool shouldRepaint(LadderPainter o) =>
      o.t != t || o.current != current || o.climb != climb || o.rungs != rungs;
}

/// A medallion for one Mark. Earned: a metallic rarity ring, a bright
/// disc, the picture and a shine that sweeps across. Locked: a quiet
/// teal disc with a progress ring.
class MarkMedallionPainter extends CustomPainter {
  MarkMedallionPainter({
    required this.glyph,
    required this.rarity,
    required this.earned,
    required this.fraction,
    required this.shine,
  }) : super(repaint: shine);

  final String glyph;
  final int rarity;
  final bool earned;
  final double fraction;
  final Animation<double> shine;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);
    final double r = math.min(size.width, size.height) / 2 - 3;
    final Color tone = LadderTones.rarity[rarity.clamp(0, 4)];
    if (!earned) {
      canvas.drawCircle(
        c,
        r,
        Paint()..color = LadderTones.tealDeep.withValues(alpha: 0.85),
      );
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = LadderTones.mist.withValues(alpha: 0.28),
      );
      if (fraction > 0) {
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: r),
          -math.pi / 2,
          math.pi * 2 * fraction,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.5
            ..strokeCap = StrokeCap.round
            ..color = tone.withValues(alpha: 0.85),
        );
      }
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.scale(r * 0.46);
      canvas.drawPath(
        ladderGlyph(glyph),
        Paint()..color = LadderTones.mist.withValues(alpha: 0.32),
      );
      canvas.restore();
      return;
    }
    canvas.drawCircle(
      c,
      r + 2,
      Paint()
        ..color = tone.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    final Rect box = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = SweepGradient(
          colors: <Color>[
            tone,
            Colors.white,
            tone,
            LadderTones.mix(tone, LadderTones.teal, 0.35),
            tone,
          ],
        ).createShader(box),
    );
    canvas.drawCircle(
      c,
      r * 0.8,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.4),
          colors: <Color>[
            LadderTones.mix(tone, Colors.white, 0.55),
            LadderTones.mix(tone, LadderTones.tealMid, 0.45),
          ],
        ).createShader(box),
    );
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(r * 0.46);
    final Path g = ladderGlyph(glyph);
    canvas.drawPath(
      g.shift(const Offset(0.05, 0.07)),
      Paint()..color = LadderTones.teal.withValues(alpha: 0.35),
    );
    canvas.drawPath(g, Paint()..color = Colors.white);
    canvas.restore();
    // The shine: a soft diagonal band sweeping across the disc.
    final double p = shine.value;
    if (p < 0.5) {
      final double x = c.dx - r + (r * 2) * (p / 0.5);
      canvas.save();
      canvas.clipPath(Path()..addOval(box));
      canvas.drawLine(
        Offset(x - 6, c.dy + r),
        Offset(x + 6, c.dy - r),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.5)
          ..strokeWidth = 9
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(MarkMedallionPainter o) =>
      o.glyph != glyph ||
      o.rarity != rarity ||
      o.earned != earned ||
      o.fraction != fraction;
}

/// A medallion widget; [shine] is one animation shared by a whole page.
class MarkMedallion extends StatelessWidget {
  const MarkMedallion({
    super.key,
    required this.glyph,
    required this.rarity,
    required this.earned,
    required this.fraction,
    required this.shine,
    this.size = 64,
  });

  final String glyph;
  final int rarity;
  final bool earned;
  final double fraction;
  final Animation<double> shine;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: MarkMedallionPainter(
        glyph: glyph,
        rarity: rarity,
        earned: earned,
        fraction: fraction,
        shine: shine,
      ),
    );
  }
}

/// A five-point star for a Full Day, with a shine that passes over it.
class StarBadgePainter extends CustomPainter {
  StarBadgePainter({required this.shine, this.lit = true})
    : super(repaint: shine);

  final Animation<double> shine;
  final bool lit;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);
    final double r = math.min(size.width, size.height) / 2 - 2;
    final Path star = ladderStarPath(r).shift(c);
    if (!lit) {
      canvas.drawPath(
        star,
        Paint()..color = LadderTones.mist.withValues(alpha: 0.25),
      );
      return;
    }
    canvas.drawPath(
      star,
      Paint()
        ..color = LadderTones.sun.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawPath(
      star,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Colors.white, LadderTones.sun, LadderTones.rose],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    final double p = shine.value;
    final double x = c.dx - r + r * 2 * p;
    canvas.save();
    canvas.clipPath(star);
    canvas.drawLine(
      Offset(x - 5, c.dy + r),
      Offset(x + 5, c.dy - r),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.75)
        ..strokeWidth = 8
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(StarBadgePainter o) => o.lit != lit;
}

// END OF FILE - lib/widgets/ladder_paint.dart
