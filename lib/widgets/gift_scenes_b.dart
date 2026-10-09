import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';
import 'gift_gold.dart';

/// ============================================================
/// IVORY - POST GIFT SCENES, BATCH TWO
///
/// Carried All Day · A Round of Applause · Up All Night
///
/// Drawn, like the first three. No emoji, no borrowed pictures.
/// Fifteen seconds each, and every one SETTLES rather than
/// snapping back to its first frame.
///
/// The three are deliberately unalike. One is a whole day
/// passing, one is a room full of other people, one is a night
/// that refuses to end. If two scenes in the set feel like the
/// same idea at different prices, the ladder stops meaning
/// anything.
/// ============================================================

/// ------------------------------------------------------------
/// 4. CARRIED ALL DAY - "I thought about it all day."
///
/// A sun crosses the whole sky, dawn to dusk, while she walks
/// the other way. Something small and gold rests against her
/// chest and never dims - not once in the whole crossing. The
/// light around her changes completely; the thing she is
/// carrying does not. That is the entire sentence.
/// ------------------------------------------------------------
void paintCarriedAllDay(Canvas canvas, Size size, double t) {
  final double u = size.shortestSide;
  final double gy = size.height * 0.84;

  // THE DAY ITSELF. The wash behind her moves from first light
  // through noon to a low evening, so the passing of time is
  // felt before it is noticed.
  final Color sky = Color.lerp(
    Color.lerp(const Color(0xFFFFE2C2), IvoryColors.cream, span(t, 0, 0.5))!,
    const Color(0xFFF3C9A8),
    span(t, 0.5, 1.0),
  )!;
  canvas.drawRect(Offset.zero & size, Paint()..color = sky);

  // The sun, on a true arc - low, high, low.
  final double sp = t.clamp(0.0, 1.0);
  final Offset sun = Offset(
    size.width * (0.08 + 0.84 * sp),
    gy - u * 0.18 - math.sin(sp * math.pi) * u * 0.62,
  );
  canvas.drawCircle(
    sun,
    u * 0.085,
    Paint()..color = IvoryColors.amber.withValues(alpha: 0.30),
  );
  canvas.drawCircle(
    sun,
    u * 0.055,
    Paint()..color = IvoryColors.gold,
  );

  canvas.drawLine(
    Offset(0, gy),
    Offset(size.width, gy),
    Paint()
      ..strokeWidth = u * 0.012
      ..color = IvoryColors.gold.withValues(alpha: 0.55),
  );

  // She walks the other way, right to left, unhurried.
  final double cx = size.width * (0.80 - 0.56 * sp);
  final double bob = math.sin(t * math.pi * 16) * u * 0.010;
  final double head = gy - u * 0.50 + bob;

  // Her shadow swings and stretches as the sun crosses - the
  // quiet detail that makes it read as one long day.
  final double shadow = (sp - 0.5) * 2;
  canvas.drawLine(
    Offset(cx, gy),
    Offset(cx - shadow * u * 0.34, gy + u * 0.02),
    Paint()
      ..strokeWidth = u * 0.03
      ..strokeCap = StrokeCap.round
      ..color = IvoryColors.plum.withValues(alpha: 0.16),
  );

  canvas.drawCircle(
      Offset(cx, head), u * 0.112, Paint()..color = const Color(0xFF2E0810));
  canvas.drawCircle(
      Offset(cx, head), u * 0.092, Paint()..color = const Color(0xFFF6C9A3));

  canvas.drawPath(
    Path()
      ..moveTo(cx - u * 0.10, gy)
      ..lineTo(cx - u * 0.072, gy - u * 0.37 + bob)
      ..quadraticBezierTo(
          cx, gy - u * 0.43 + bob, cx + u * 0.072, gy - u * 0.37 + bob)
      ..lineTo(cx + u * 0.10, gy)
      ..close(),
    Paint()..color = IvoryColors.plum,
  );

  // Both arms folded over it. She is not showing it to anyone.
  final Paint arm = Paint()
    ..strokeWidth = u * 0.032
    ..strokeCap = StrokeCap.round
    ..color = const Color(0xFFF6C9A3);
  canvas.drawLine(Offset(cx - u * 0.080, gy - u * 0.32 + bob),
      Offset(cx + u * 0.012, gy - u * 0.22 + bob), arm);
  canvas.drawLine(Offset(cx + u * 0.080, gy - u * 0.32 + bob),
      Offset(cx - u * 0.012, gy - u * 0.20 + bob), arm);

  // THE THING SHE IS CARRYING. A steady gold heart-light that
  // breathes very slightly and never fades, whatever the sky
  // is doing.
  final Offset keep = Offset(cx, gy - u * 0.24 + bob);
  final double breathe = 1 + math.sin(t * math.pi * 6) * 0.07;
  canvas.drawCircle(
    keep,
    u * 0.085 * breathe,
    Paint()..color = IvoryColors.gold.withValues(alpha: 0.22),
  );
  canvas.drawCircle(
    keep,
    u * 0.046 * breathe,
    Paint()..color = IvoryColors.gold,
  );
  canvas.drawCircle(
    keep + Offset(-u * 0.012, -u * 0.012),
    u * 0.016,
    Paint()..color = IvoryColors.cream,
  );

  sceneLabel(canvas, size, t, 0.66, 1.0, 'ALL DAY',
      colour: IvoryColors.plum);
}

/// ------------------------------------------------------------
/// 5. A ROUND OF APPLAUSE - "that deserves a room."
///
/// A dark-plum audience in three rows. One figure stands. Then
/// another, then the row, then the whole room, until every one
/// of them is up - a standing ovation building front to back,
/// with claps sparking above them. They do NOT sit back down.
///
/// Drawn as silhouettes on purpose. Nine pairs of recognisable
/// hands at this size would be mud; nine shapes rising in
/// sequence reads instantly, even on a small tile.
/// ------------------------------------------------------------
void paintApplause(Canvas canvas, Size size, double t) {
  final double u = size.shortestSide;
  final double gy = size.height * 0.88;

  // Rows get darker towards the front, so the room has depth.
  const List<double> rowY = <double>[0.52, 0.68, 0.86];
  const List<int> rowN = <int>[5, 4, 3];
  const List<double> rowS = <double>[0.72, 0.88, 1.08];

  int seat = 0;
  for (int r = 2; r >= 0; r--) {
    final int n = rowN[r];
    final double sc = rowS[r];
    final double y = size.height * rowY[r];
    for (int i = 0; i < n; i++) {
      final double x = size.width * ((i + 0.5) / n);

      // Each seat stands at its own moment. The order runs
      // front row first, so the ovation travels backwards
      // through the room the way a real one does.
      final double at = 0.10 + seat * 0.055;
      final double up = soft(span(t, at, at + 0.10));
      seat++;

      final double lift = u * 0.085 * sc * up;
      final double hr = u * 0.052 * sc;
      final Color body = Color.lerp(IvoryColors.plum,
          IvoryColors.burgundy, r / 2)!;

      // Head.
      canvas.drawCircle(
        Offset(x, y - lift - u * 0.085 * sc),
        hr,
        Paint()..color = body,
      );
      // Shoulders.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x, y - lift + u * 0.020 * sc),
            width: u * 0.165 * sc,
            height: u * 0.145 * sc,
          ),
          Radius.circular(u * 0.055 * sc),
        ),
        Paint()..color = body,
      );

      // Hands, once they are up. Two small shapes closing and
      // opening - a clap read at a glance, not a hand drawn in
      // detail.
      if (up > 0.6) {
        final double gap =
            (0.5 + 0.5 * math.sin(t * math.pi * 22 + seat)) * u * 0.030 * sc;
        final double hy = y - lift - u * 0.155 * sc;
        for (int h = 0; h < 2; h++) {
          canvas.drawCircle(
            Offset(x + (h == 0 ? -gap : gap), hy),
            u * 0.028 * sc,
            Paint()..color = const Color(0xFFF6C9A3),
          );
        }
        // The spark of the clap itself.
        if (gap < u * 0.008 * sc) {
          canvas.drawCircle(
            Offset(x, hy),
            u * 0.045 * sc,
            Paint()..color = IvoryColors.gold.withValues(alpha: 0.35),
          );
        }
      }
    }
  }

  canvas.drawLine(
    Offset(0, gy),
    Offset(size.width, gy),
    Paint()
      ..strokeWidth = u * 0.010
      ..color = IvoryColors.gold.withValues(alpha: 0.4),
  );

  sceneLabel(canvas, size, t, 0.70, 1.0, 'ALL OF THEM, STANDING');
}

/// ------------------------------------------------------------
/// 6. UP ALL NIGHT - "I could not put it down."
///
/// A window. The moon crosses it and goes. A clock on the wall
/// spins through the small hours. The sky behind lightens into
/// first morning - and the lamp inside is STILL ON. Nobody
/// turns it off, and nothing in the room has moved.
/// ------------------------------------------------------------
void paintUpAllNight(Canvas canvas, Size size, double t) {
  final double u = size.shortestSide;

  // Night turning to dawn, but only at the very end, so the
  // last two seconds carry the whole point.
  final Color night = Color.lerp(
    const Color(0xFF6B4A66),
    const Color(0xFFF3C9A8),
    soft(span(t, 0.74, 1.0)),
  )!;

  final Rect win = Rect.fromLTWH(size.width * 0.14, size.height * 0.10,
      size.width * 0.72, size.height * 0.60);
  canvas.drawRRect(
    RRect.fromRectAndRadius(win, Radius.circular(u * 0.05)),
    Paint()..color = night,
  );

  // Stars, fading out as morning arrives.
  final double starFade = 1 - span(t, 0.66, 0.92);
  for (int i = 0; i < 7; i++) {
    final double x = win.left + win.width * ((i * 0.37) % 1.0);
    final double y = win.top + win.height * ((i * 0.53) % 0.7);
    final double tw =
        0.45 + 0.55 * (0.5 + 0.5 * math.sin(t * math.pi * 7 + i * 1.7));
    canvas.drawCircle(
      Offset(x, y),
      u * 0.012,
      Paint()
        ..color = IvoryColors.cream.withValues(alpha: tw * starFade),
    );
  }

  // The moon crosses the window and leaves before dawn.
  final double mp = span(t, 0.04, 0.76);
  if (mp > 0 && mp < 1) {
    final Offset m = Offset(
      win.left + win.width * (0.1 + 0.8 * mp),
      win.top + win.height * (0.52 - math.sin(mp * math.pi) * 0.34),
    );
    canvas.drawCircle(
      m,
      u * 0.075,
      Paint()..color = IvoryColors.cream.withValues(alpha: 0.22),
    );
    canvas.drawCircle(m, u * 0.048, Paint()..color = IvoryColors.cream);
    // Bitten away on one side, so it is a moon and not a lamp.
    canvas.drawCircle(m + Offset(u * 0.022, -u * 0.014), u * 0.040,
        Paint()..color = night);
  }

  // The frame, drawn after the sky so it sits in front.
  canvas.drawRRect(
    RRect.fromRectAndRadius(win, Radius.circular(u * 0.05)),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = u * 0.030
      ..color = IvoryColors.burgundy,
  );
  canvas.drawLine(Offset(win.center.dx, win.top),
      Offset(win.center.dx, win.bottom),
      Paint()
        ..strokeWidth = u * 0.018
        ..color = IvoryColors.burgundy);
  canvas.drawLine(Offset(win.left, win.center.dy),
      Offset(win.right, win.center.dy),
      Paint()
        ..strokeWidth = u * 0.018
        ..color = IvoryColors.burgundy);

  // THE CLOCK. Hands going round far too fast, which is what
  // the small hours actually feel like.
  final Offset c = Offset(size.width * 0.20, size.height * 0.80);
  final double cr = u * 0.085;
  canvas.drawCircle(c, cr, Paint()..color = IvoryColors.surface);
  canvas.drawCircle(
    c,
    cr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = u * 0.014
      ..color = IvoryColors.gold,
  );
  for (final List<double> h in <List<double>>[
    <double>[t * math.pi * 2 * 6, 0.62, 0.016],
    <double>[t * math.pi * 2 * 0.5, 0.44, 0.022],
  ]) {
    final double a = h[0] - math.pi / 2;
    canvas.drawLine(
      c,
      c + Offset(math.cos(a) * cr * h[1], math.sin(a) * cr * h[1]),
      Paint()
        ..strokeWidth = u * h[2]
        ..strokeCap = StrokeCap.round
        ..color = IvoryColors.burgundy,
    );
  }

  // THE LAMP, STILL ON. It never goes out, and its glow only
  // grows as the room gets light around it.
  final Offset lamp = Offset(size.width * 0.80, size.height * 0.80);
  final double glow = 1 + soft(span(t, 0.74, 1.0)) * 0.25;
  canvas.drawCircle(
    lamp,
    u * 0.13 * glow,
    Paint()..color = IvoryColors.gold.withValues(alpha: 0.20),
  );
  canvas.drawPath(
    Path()
      ..moveTo(lamp.dx - u * 0.075, lamp.dy)
      ..lineTo(lamp.dx - u * 0.042, lamp.dy - u * 0.085)
      ..lineTo(lamp.dx + u * 0.042, lamp.dy - u * 0.085)
      ..lineTo(lamp.dx + u * 0.075, lamp.dy)
      ..close(),
    Paint()..color = IvoryColors.amber,
  );
  canvas.drawLine(
    Offset(lamp.dx, lamp.dy),
    Offset(lamp.dx, lamp.dy + u * 0.085),
    Paint()
      ..strokeWidth = u * 0.020
      ..color = IvoryColors.burgundy,
  );

  sceneLabel(canvas, size, t, 0.80, 1.0, 'AND IT IS MORNING',
      colour: IvoryColors.plum);
}

// END OF FILE - lib/widgets/gift_scenes_b.dart
