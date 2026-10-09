import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';

/// ============================================================
/// IVORY - THE GOLD LAYER
///
/// Shared by every gift scene, drawn OVER whichever scene is
/// playing. It is built once here and never repeated nine
/// times.
///
/// It speaks the same language as `GiftMoment` in the live
/// room - the same gold ring, the same sparks, the same four
/// colours - so a member who has gifted during a broadcast
/// recognises a post gift instantly as the same house, without
/// being able to say why.
///
/// TWO PARTS, AND THE RESTRAINT IS THE DESIGN.
///
/// 1. DUST. Fine gold motes lifting through the whole tile for
///    all fifteen seconds. Deliberately faint. A member should
///    notice it HAS BEEN there rather than notice it arrive.
///    That is the line between premium and decorated.
///
/// 2. ONE BURST. A gold ring and eight sparks, fired ONCE, on
///    the exact beat of that gift's own climax. Never a loop.
///    A firework that repeats is wallpaper, and nothing
///    cheapens a paid moment faster than watching it come
///    round again while you are still looking at it.
///
/// The ring throws wider as the price climbs, and the most
/// expensive gift in the house - and only that one - gets a
/// second ring a beat behind the first.
/// ============================================================

/// The four colours `GiftMoment` already uses in the live room.
const List<Color> kGiftGold = <Color>[
  IvoryColors.gold,
  IvoryColors.amber,
  IvoryColors.peach,
  IvoryColors.burgundy,
];

/// Where one gift's burst lands, and how wide it throws.
class GoldBeat {
  const GoldBeat(this.at, this.level, {this.second = false});

  /// Fraction of the fifteen seconds at which the burst fires.
  final double at;

  /// 1.0 at the cheapest gift, 1.7 at the dearest. Scales both
  /// the ring and how far the sparks are thrown.
  final double level;

  /// Only the top gift in the house sets this. Nothing else in
  /// Ivory gets a second ring, and it should stay that way.
  final bool second;
}

/// Each gift bursts on its own beat, not on a shared one.
const Map<String, GoldBeat> kGoldBeats = <String, GoldBeat>{
  'A Second Look': GoldBeat(0.80, 1.00),
  'Again, Please': GoldBeat(0.90, 1.08),
  'Goosebumps': GoldBeat(0.52, 1.16),
  'Carried All Day': GoldBeat(0.55, 1.24),
  'A Round of Applause': GoldBeat(0.46, 1.32),
  'Up All Night': GoldBeat(0.34, 1.40),
  'Front Row': GoldBeat(0.62, 1.48),
  'Crown of the Day': GoldBeat(0.54, 1.56),
  'One I Will Not Forget': GoldBeat(0.70, 1.70, second: true),
};

/// A number that rises 0 to 1 across a window and is 0 outside
/// it. The whole file is timed with this, so every beat can be
/// written as "from here, for this long".
double span(double t, double from, double to) {
  if (to <= from) return 0;
  final double v = (t - from) / (to - from);
  return v.clamp(0.0, 1.0);
}

/// Ease-out, so things arrive quickly and settle slowly. Used
/// everywhere in preference to a straight line, because a
/// straight line is the one thing that always reads as cheap.
double soft(double v) => 1 - math.pow(1 - v, 3).toDouble();

void paintGoldLayer(Canvas canvas, Size size, double t, GoldBeat beat) {
  final Offset c = Offset(size.width / 2, size.height / 2);
  final double unit = size.shortestSide;

  // ---- 1. THE DUST ----------------------------------------
  // Six motes, each on its own offset loop so the drift never
  // pulses and never marches in step.
  for (int i = 0; i < 6; i++) {
    final double phase = (t + i / 6.0) % 1.0;
    final double x = size.width * (0.10 + 0.16 * i) +
        math.sin(phase * math.pi * 2 + i) * unit * 0.05;
    final double y = size.height * (1.05 - phase * 1.15);
    final double fade =
        phase < 0.12 ? phase / 0.12 : (1 - (phase - 0.12) / 0.88);
    if (fade <= 0) continue;
    final double r = unit * (i.isEven ? 0.016 : 0.012);
    // A shader would override the colour, and with it the fade,
    // so the dust is drawn as two flat circles instead: a gold
    // body with a paler heart. Cheaper to draw and it holds the
    // fade, which is the part that matters.
    canvas.drawCircle(
      Offset(x, y),
      r,
      Paint()..color = IvoryColors.gold.withValues(alpha: 0.5 * fade),
    );
    canvas.drawCircle(
      Offset(x, y),
      r * 0.45,
      Paint()..color = IvoryColors.cream.withValues(alpha: 0.8 * fade),
    );
  }

  // ---- 2. THE BURST ---------------------------------------
  _burst(canvas, c, unit, t, beat.at, beat.level);
  if (beat.second) {
    // A beat behind the first, wider and thinner. The top of
    // the house, and nothing else in Ivory does this.
    _burst(canvas, c, unit, t, beat.at + 0.05, beat.level * 1.12,
        thin: true);
  }
}

void _burst(Canvas canvas, Offset c, double unit, double t, double at,
    double level,
    {bool thin = false}) {
  // The whole burst lasts about a second and a half, then is
  // gone for the rest of the loop. It does not come round
  // again inside the fifteen seconds.
  const double len = 0.10;
  if (t < at || t > at + len) return;
  final double p = (t - at) / len;

  // The ring.
  final double rr = unit * (0.08 + soft(p) * 0.58 * level);
  final double ringFade = (1 - p) * (1 - p);
  canvas.drawCircle(
    c,
    rr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (thin ? 1.0 : 2.0) * (1 - p * 0.6)
      ..color = IvoryColors.gold.withValues(alpha: 0.95 * ringFade),
  );
  canvas.drawCircle(
    c,
    rr * 0.86,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = IvoryColors.peach.withValues(alpha: 0.7 * ringFade),
  );
  if (thin) return;

  // Eight sparks, evenly spaced, each thrown further than the
  // ring so they appear to break out of it.
  for (int i = 0; i < 8; i++) {
    final double a = i * math.pi / 4;
    final double d = unit * (0.06 + soft(p) * 0.66 * level);
    final double len2 = unit * 0.10 * (1 - p * 0.7);
    final Offset from = c + Offset(math.cos(a) * d, math.sin(a) * d);
    final Offset to =
        c + Offset(math.cos(a) * (d + len2), math.sin(a) * (d + len2));
    canvas.drawLine(
      from,
      to,
      Paint()
        ..strokeWidth = unit * 0.022 * (1 - p * 0.5)
        ..strokeCap = StrokeCap.round
        ..color = kGiftGold[i % 3].withValues(alpha: 0.95 * (1 - p)),
    );
  }
}

// END OF FILE - lib/widgets/gift_gold.dart
