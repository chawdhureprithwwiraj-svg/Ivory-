import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';
import 'gift_gold.dart';

/// ============================================================
/// IVORY - POST GIFT SCENES, BATCH THREE
///
/// Front Row · Crown of the Day · One I Will Not Forget
///
/// The top of the ladder, and the three that have to feel
/// worth their price. The rule I held to: THE DEAREST SCENES
/// ARE NOT THE BUSIEST ONES. Expensive reads as slow, certain
/// and uncrowded - a curtain opening, a crown settling, a seal
/// pressed once. Cheap reads as fast and cluttered.
///
/// So these three have FEWER moving parts than batch two, not
/// more, and they take their time arriving.
/// ============================================================

/// ------------------------------------------------------------
/// 7. FRONT ROW - "I want to be where I can see you."
///
/// Curtains draw back. A spotlight swings down out of the dark
/// and settles - not on the stage, but on one empty seat in
/// the front row, which turns gold and stays lit after
/// everything else has gone quiet. The seat is kept.
/// ------------------------------------------------------------
void paintFrontRow(Canvas canvas, Size size, double t) {
  final double u = size.shortestSide;

  canvas.drawRect(
    Offset.zero & size,
    Paint()..color = const Color(0xFF6B4A66),
  );

  // The stage behind, revealed as the curtains part.
  canvas.drawRect(
    Rect.fromLTWH(0, size.height * 0.08, size.width, size.height * 0.46),
    Paint()..color = IvoryColors.plum.withValues(alpha: 0.55),
  );

  // THE SPOTLIGHT. It swings in from the left and settles -
  // overshooting slightly and easing back, because something
  // that arrives exactly on its mark looks mechanical.
  final double swing = soft(span(t, 0.18, 0.52));
  final double settle = math.sin(span(t, 0.52, 0.66) * math.pi) * 0.04;
  final double lx = size.width * (0.18 + 0.32 * swing - settle);
  final double ly = size.height * 0.74;
  if (t > 0.18) {
    final double on = span(t, 0.18, 0.30);
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.5, -u * 0.1)
        ..lineTo(lx - u * 0.26, ly + u * 0.06)
        ..lineTo(lx + u * 0.26, ly + u * 0.06)
        ..close(),
      Paint()..color = IvoryColors.cream.withValues(alpha: 0.17 * on),
    );
  }

  // THE CURTAINS. They part slowly and stay open.
  final double part = soft(span(t, 0.04, 0.42));
  for (int side = 0; side < 2; side++) {
    final double w = size.width * (0.52 - 0.40 * part);
    final Rect r = side == 0
        ? Rect.fromLTWH(0, 0, w, size.height * 0.62)
        : Rect.fromLTWH(size.width - w, 0, w, size.height * 0.62);
    canvas.drawRect(r, Paint()..color = IvoryColors.burgundy);
    // Folds, so it reads as cloth and not a block.
    for (int i = 1; i < 4; i++) {
      final double x = r.left + r.width * i / 4;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, r.bottom),
        Paint()
          ..strokeWidth = u * 0.010
          ..color = IvoryColors.plum.withValues(alpha: 0.75),
      );
    }
  }

  // THE ROW OF SEATS. Three, and the lit one is the middle.
  for (int i = 0; i < 3; i++) {
    final double x = size.width * (0.26 + i * 0.24);
    final bool mine = i == 1;
    final double lit = mine ? soft(span(t, 0.58, 0.74)) : 0;
    final Color seat =
        Color.lerp(IvoryColors.plum, IvoryColors.gold, lit)!;

    // Back.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - u * 0.085, ly - u * 0.16, u * 0.17, u * 0.17),
        Radius.circular(u * 0.045),
      ),
      Paint()..color = seat,
    );
    // Cushion.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - u * 0.095, ly, u * 0.19, u * 0.055),
        Radius.circular(u * 0.022),
      ),
      Paint()..color = seat,
    );
    if (mine && lit > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
              x - u * 0.105, ly - u * 0.17, u * 0.21, u * 0.245),
          Radius.circular(u * 0.05),
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = u * 0.012
          ..color = IvoryColors.cream.withValues(alpha: 0.85 * lit),
      );
    }
  }

  sceneLabel(canvas, size, t, 0.76, 1.0, 'KEPT FOR YOU',
      colour: IvoryColors.cream);
}

/// ------------------------------------------------------------
/// 8. CROWN OF THE DAY - "nothing else today came close."
///
/// A crown descends out of the light, turning as it falls,
/// slows, touches down and SETTLES - one small bounce, then
/// still. Laurel opens either side of it. It does not spin,
/// pulse or lift off again. It has been awarded, and awarded
/// things stay put.
/// ------------------------------------------------------------
void paintCrownOfTheDay(Canvas canvas, Size size, double t) {
  final double u = size.shortestSide;
  final Offset rest = Offset(size.width * 0.5, size.height * 0.50);

  // The descent: fast at first, then slower and slower.
  final double drop = soft(span(t, 0.06, 0.46));
  // One small settle, and then nothing.
  final double bounce =
      math.sin(span(t, 0.46, 0.58) * math.pi) * u * 0.035;
  final double y = rest.dy - u * 0.70 * (1 - drop) + bounce;
  final double spin = (1 - drop) * 1.9;

  // Laurel, opening outward once the crown is down. Drawn
  // first so the crown sits in front of it.
  final double leaf = soft(span(t, 0.52, 0.74));
  if (leaf > 0) {
    for (int side = 0; side < 2; side++) {
      final double dir = side == 0 ? -1 : 1;
      for (int i = 0; i < 5; i++) {
        final double p = i / 4.0;
        final Offset at = rest +
            Offset(dir * u * (0.17 + p * 0.20) * leaf,
                u * 0.10 - p * u * 0.21 * leaf);
        canvas.save();
        canvas.translate(at.dx, at.dy);
        // Each leaf tilts a little further than the last, so
        // the sprig opens like a fan rather than a row.
        canvas.rotate(dir * (0.9 - p * 0.7));
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset.zero, width: u * 0.085, height: u * 0.036),
          Paint()
            ..color = IvoryColors.success.withValues(alpha: 0.80 * leaf),
        );
        canvas.restore();
      }
    }
  }

  canvas.save();
  canvas.translate(rest.dx, y);
  canvas.rotate(spin);

  final double w = u * 0.46;
  final double h = u * 0.34;
  final Path crown = Path()
    ..moveTo(-w / 2, h * 0.34)
    ..lineTo(-w / 2, -h * 0.20)
    ..lineTo(-w * 0.21, h * 0.06)
    ..lineTo(0, -h * 0.46)
    ..lineTo(w * 0.21, h * 0.06)
    ..lineTo(w / 2, -h * 0.20)
    ..lineTo(w / 2, h * 0.34)
    ..close();

  canvas.drawPath(
    crown,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[IvoryColors.cream, IvoryColors.amber,
          IvoryColors.gold],
        stops: <double>[0, 0.42, 1],
      ).createShader(
          Rect.fromCenter(center: Offset.zero, width: w, height: h)),
  );
  canvas.drawPath(
    crown,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = u * 0.018
      ..color = IvoryColors.burgundy.withValues(alpha: 0.65),
  );
  // The band and three stones.
  canvas.drawRect(
    Rect.fromLTWH(-w / 2, h * 0.34, w, h * 0.17),
    Paint()..color = IvoryColors.burgundy.withValues(alpha: 0.80),
  );
  for (int i = 0; i < 3; i++) {
    canvas.drawCircle(
      Offset(-w * 0.26 + i * w * 0.26, h * 0.425),
      u * 0.024,
      Paint()..color = IvoryColors.cream,
    );
  }
  canvas.restore();

  // A soft halo where it lands, fading as it settles.
  if (t > 0.42) {
    final double halo = 1 - span(t, 0.42, 0.72);
    canvas.drawCircle(
      Offset(rest.dx, rest.dy + u * 0.04),
      u * (0.26 + 0.18 * (1 - halo)),
      Paint()..color = IvoryColors.gold.withValues(alpha: 0.18 * halo),
    );
  }

  sceneLabel(canvas, size, t, 0.74, 1.0, 'BEST OF THE DAY',
      colour: IvoryColors.plum);
}

/// ------------------------------------------------------------
/// 9. ONE I WILL NOT FORGET - "this one stays."
///
/// A blank card. A line of gold writes itself across it, left
/// to right, in its own time. Then a wax seal comes down ONCE,
/// presses, and lifts - leaving the mark behind. The card does
/// not close, fade or reset. It has been written and sealed,
/// and that is permanent.
///
/// The dearest gift in the house, so it is also the quietest:
/// one line, one press. The gold layer gives this one alone a
/// second ring, and nothing in the scene competes with it.
/// ------------------------------------------------------------
void paintNotForget(Canvas canvas, Size size, double t) {
  final double u = size.shortestSide;

  final Rect card = Rect.fromCenter(
    center: Offset(size.width * 0.5, size.height * 0.46),
    width: size.width * 0.72,
    height: size.height * 0.52,
  );

  // The card arrives, settling rather than landing flat.
  final double inp = soft(span(t, 0, 0.14));
  canvas.save();
  canvas.translate(card.center.dx, card.center.dy);
  canvas.rotate((1 - inp) * -0.16);
  canvas.scale(0.84 + 0.16 * inp);
  canvas.translate(-card.center.dx, -card.center.dy);

  canvas.drawRRect(
    RRect.fromRectAndRadius(
        card.shift(Offset(0, u * 0.014)), Radius.circular(u * 0.04)),
    Paint()..color = IvoryColors.plum.withValues(alpha: 0.18),
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(card, Radius.circular(u * 0.04)),
    Paint()..color = IvoryColors.surface,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(card.deflate(u * 0.028),
        Radius.circular(u * 0.028)),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = u * 0.008
      ..color = IvoryColors.gold.withValues(alpha: 0.7),
  );

  // THE WRITING. Three strokes of gold, each finishing before
  // the next begins, so it reads as a hand moving and not a
  // bar filling up.
  const List<double> at = <double>[0.20, 0.34, 0.48];
  for (int i = 0; i < 3; i++) {
    final double p = soft(span(t, at[i], at[i] + 0.13));
    if (p <= 0) continue;
    final double y = card.top + card.height * (0.30 + i * 0.17);
    final double x0 = card.left + card.width * 0.14;
    final double full = card.width * (i == 2 ? 0.44 : 0.72);
    final Path line = Path()..moveTo(x0, y);
    final int segs = 14;
    for (int sgi = 1; sgi <= segs; sgi++) {
      final double f = sgi / segs;
      if (f > p) break;
      line.lineTo(
        x0 + full * f,
        y + math.sin(f * math.pi * 4 + i) * u * 0.012,
      );
    }
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = u * 0.016
        ..strokeCap = StrokeCap.round
        ..color = IvoryColors.gold,
    );
  }
  canvas.restore();

  // THE SEAL. Down, press, lift. Once.
  final Offset sc =
      Offset(card.right - u * 0.14, card.bottom - u * 0.10);
  final double down = soft(span(t, 0.62, 0.72));
  final double lift = soft(span(t, 0.78, 0.88));
  final double sy = sc.dy - u * 0.55 * (1 - down) + u * 0.10 * lift;
  final double press = span(t, 0.72, 0.78);

  // The mark it leaves, which stays for the rest of the scene.
  if (t > 0.72) {
    canvas.drawCircle(
      sc,
      u * 0.085,
      Paint()..color = IvoryColors.danger.withValues(alpha: 0.92),
    );
    canvas.drawCircle(
      sc,
      u * 0.085,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = u * 0.008
        ..color = IvoryColors.gold,
    );
    for (int i = 0; i < 8; i++) {
      final double a = i * math.pi / 4;
      canvas.drawLine(
        sc + Offset(math.cos(a) * u * 0.052, math.sin(a) * u * 0.052),
        sc + Offset(math.cos(a) * u * 0.078, math.sin(a) * u * 0.078),
        Paint()
          ..strokeWidth = u * 0.009
          ..color = IvoryColors.gold.withValues(alpha: 0.85),
      );
    }
  }

  // The stamp itself, gone once it has lifted away.
  if (t > 0.62 && t < 0.94) {
    final double gone = 1 - span(t, 0.86, 0.94);
    canvas.drawCircle(
      Offset(sc.dx, sy),
      u * 0.088 * (1 + press * 0.08),
      Paint()..color = IvoryColors.burgundy.withValues(alpha: gone),
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(sc.dx, sy - u * 0.13),
        width: u * 0.046,
        height: u * 0.10,
      ),
      Paint()..color = IvoryColors.plum.withValues(alpha: gone),
    );
  }

  sceneLabel(canvas, size, t, 0.88, 1.0, 'SEALED',
      colour: IvoryColors.plum);
}

// END OF FILE - lib/widgets/gift_scenes_c.dart
