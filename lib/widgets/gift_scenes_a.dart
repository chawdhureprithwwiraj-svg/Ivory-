import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';
import 'gift_gold.dart';

/// ============================================================
/// IVORY - POST GIFT SCENES, THE FIRST THREE
///
/// A Second Look · Again, Please · Goosebumps
///
/// Every one of these is DRAWN - circles, arcs and lines in the
/// house palette. Not one emoji. An emoji is somebody else's
/// artwork wearing somebody else's colours, and a member who has
/// just paid should never be shown a borrowed picture.
///
/// All three run for fifteen seconds and NONE of them snap back
/// to the first frame. They settle. The eye turns away, the ball
/// has already gone, and she stays wrapped in her own arms,
/// still bristling. A loop a member can count has stopped being
/// magic.
///
/// `t` is 0 to 1 across the fifteen seconds. Timing is written
/// with span() so each beat reads as "from here, for this long".
/// ============================================================

/// ------------------------------------------------------------
/// 1. A SECOND LOOK - "I scrolled past. I came back."
///
/// A woman's eye. It rolls in from above, drops, skids off the
/// left wall and bounces diagonally across the tile - then comes
/// straight at the member and fills the frame. The iris glances
/// aside and back. The lid lowers halfway and lingers there
/// before closing slowly into a full wink.
/// ------------------------------------------------------------
void paintSecondLook(Canvas canvas, Size size, double t) {
  final double u = size.shortestSide;
  final Offset mid = Offset(size.width / 2, size.height / 2);

  // The journey. Each leg is its own window, so the eye can
  // skid, bounce and settle rather than slide on one line.
  Offset at = mid;
  double scale = 0.62;
  double tilt = 0;
  double fade = 1;

  if (t < 0.07) {
    final double p = soft(span(t, 0, 0.07));
    at = mid + Offset(0, -u * 0.85 * (1 - p));
    scale = 0.45 + 0.17 * p;
    tilt = -1.4 * (1 - p);
    fade = p;
  } else if (t < 0.14) {
    at = mid + Offset(0, u * 0.22 * soft(span(t, 0.07, 0.14)));
  } else if (t < 0.20) {
    final double p = soft(span(t, 0.14, 0.20));
    at = mid + Offset(-u * 0.30 * p, u * 0.22 + u * 0.03 * p);
    tilt = -0.38 * p;
  } else if (t < 0.28) {
    final double p = soft(span(t, 0.20, 0.28));
    at = mid +
        Offset(-u * 0.30 + u * 0.56 * p, u * 0.25 - u * 0.50 * p);
    tilt = -0.38 + 0.66 * p;
  } else if (t < 0.35) {
    final double p = soft(span(t, 0.28, 0.35));
    at = mid + Offset(u * 0.26 - u * 0.50 * p, -u * 0.25 + u * 0.43 * p);
    tilt = 0.28 - 0.48 * p;
  } else if (t < 0.42) {
    final double p = soft(span(t, 0.35, 0.42));
    at = mid + Offset(-u * 0.24 + u * 0.42 * p, u * 0.18 - u * 0.06 * p);
    tilt = -0.20 + 0.32 * p;
  } else if (t < 0.50) {
    final double p = soft(span(t, 0.42, 0.50));
    at = mid + Offset(u * 0.18 * (1 - p), u * 0.12 * (1 - p));
    tilt = 0.12 * (1 - p);
    scale = 0.62 + 0.16 * p;
  } else if (t < 0.60) {
    scale = 0.78 + soft(span(t, 0.50, 0.60)) * 0.92;
  } else if (t < 0.92) {
    scale = 1.70;
  } else {
    final double p = soft(span(t, 0.92, 1.0));
    scale = 1.70 * (1 - p) + 0.15;
    tilt = 2.6 * p;
    fade = 1 - p;
  }

  // The whole eye is faded in ONE layer. Fading paint by paint
  // does not work: a Paint with a shader ignores its colour, so
  // the iris would have stayed solid while everything around it
  // faded away.
  canvas.saveLayer(
    Offset.zero & size,
    Paint()..color = Colors.white.withValues(alpha: fade.clamp(0.0, 1.0)),
  );
  canvas.translate(at.dx, at.dy);
  canvas.rotate(tilt);
  canvas.scale(scale);

  final double w = u * 0.42;
  final double h = u * 0.21;

  // The white of the eye, as an almond rather than an oval.
  final Path almond = Path()
    ..moveTo(-w, 0)
    ..quadraticBezierTo(0, -h * 1.5, w, 0)
    ..quadraticBezierTo(0, h * 1.15, -w, 0)
    ..close();
  canvas.drawPath(
    almond,
    Paint()..color = IvoryColors.surface,
  );

  // The iris glances aside, holds, comes back. A still iris is
  // what made the first attempt look flat.
  double gx = 0;
  if (t > 0.60 && t < 0.66) {
    gx = soft(span(t, 0.60, 0.66)) * w * 0.26;
  } else if (t >= 0.66 && t < 0.72) {
    gx = w * 0.26;
  } else if (t >= 0.72 && t < 0.80) {
    gx = w * 0.26 - soft(span(t, 0.72, 0.80)) * w * 0.44;
  } else if (t >= 0.80 && t < 0.88) {
    gx = -w * 0.18 + soft(span(t, 0.80, 0.88)) * w * 0.18;
  }

  canvas.save();
  canvas.clipPath(almond);
  final double ir = h * 0.82;
  final Offset ic = Offset(gx, -h * 0.10);
  canvas.drawCircle(
    ic,
    ir,
    Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.3, -0.35),
        colors: <Color>[
          Color(0xFFA8536A),
          Color(0xFF8B2E3F),
          IvoryColors.burgundy,
        ],
        stops: <double>[0, 0.38, 1],
      ).createShader(Rect.fromCircle(center: ic, radius: ir))
      ..color = IvoryColors.burgundy,
  );
  canvas.drawCircle(
    ic,
    ir * 0.44,
    Paint()..color = const Color(0xFF1A0409),
  );
  // The highlight. One small white dot is the whole difference
  // between an eye and a drawing of an eye.
  canvas.drawCircle(
    ic + Offset(-ir * 0.34, -ir * 0.36),
    ir * 0.22,
    Paint()..color = Colors.white.withValues(alpha: 0.92),
  );

  // The lid. Halfway and lingering first - the look - then the
  // slow close of the wink, and a fast opening.
  double lid = 0;
  if (t >= 0.56 && t < 0.62) {
    lid = soft(span(t, 0.56, 0.62)) * 0.42;
  } else if (t >= 0.62 && t < 0.74) {
    lid = 0.42;
  } else if (t >= 0.74 && t < 0.82) {
    lid = 0.42 + soft(span(t, 0.74, 0.82)) * 0.68;
  } else if (t >= 0.82 && t < 0.87) {
    lid = 1.10;
  } else if (t >= 0.87 && t < 0.90) {
    lid = 1.10 * (1 - span(t, 0.87, 0.90));
  }
  if (lid > 0) {
    canvas.drawRect(
      Rect.fromLTRB(-w * 1.1, -h * 1.8, w * 1.1, -h * 1.8 + h * 3.0 * lid),
      Paint()..color = const Color(0xFFF6C9A3),
    );
  }
  canvas.restore();

  // The lid line and the gold liner.
  canvas.drawPath(
    Path()
      ..moveTo(-w, 0)
      ..quadraticBezierTo(0, -h * 1.5, w, 0),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = u * 0.016
      ..strokeCap = StrokeCap.round
      ..color = IvoryColors.burgundy,
  );
  canvas.drawPath(
    Path()
      ..moveTo(-w, 0)
      ..quadraticBezierTo(0, h * 1.15, w, 0),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = u * 0.010
      ..strokeCap = StrokeCap.round
      ..color = IvoryColors.plum,
  );
  canvas.drawPath(
    Path()
      ..moveTo(-w * 1.04, h * 0.06)
      ..quadraticBezierTo(0, -h * 1.62, w * 1.04, h * 0.06),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = u * 0.006
      ..color = IvoryColors.gold.withValues(alpha: 0.75),
  );

  // Five lashes, different lengths and angles. Longest in the
  // middle, swept outward at the corners.
  const List<double> lx = <double>[-0.86, -0.46, 0.0, 0.46, 0.86];
  const List<double> ll = <double>[0.72, 0.95, 1.15, 0.95, 0.72];
  const List<double> la = <double>[-0.95, -0.50, -0.10, 0.42, 0.92];
  for (int i = 0; i < 5; i++) {
    final double x = w * lx[i];
    final double y = -h * 1.5 * (1 - lx[i].abs() * 0.62);
    canvas.drawLine(
      Offset(x, y),
      Offset(x + math.sin(la[i]) * h * ll[i],
          y - math.cos(la[i]) * h * ll[i]),
      Paint()
        ..strokeWidth = u * 0.013
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF2E0810),
    );
  }
  canvas.restore();
}

/// ------------------------------------------------------------
/// 2. AGAIN, PLEASE - "once was not enough."
///
/// Two sealed halves with a dead gap between them, so nothing
/// from one sport can ever appear during the other. Cricket
/// first: a bat swings and sends ONE red ball up and out of the
/// ground, then the same shot again in slow motion. Everything
/// clears. Then football: a boot strikes a penalty into the net,
/// and that is taken back too.
/// ------------------------------------------------------------
void paintAgainPlease(Canvas canvas, Size size, double t) {
  final double u = size.shortestSide;
  final double gy = size.height * 0.80;

  // The ground line, under both halves.
  canvas.drawLine(
    Offset(0, gy),
    Offset(size.width, gy),
    Paint()
      ..strokeWidth = u * 0.012
      ..color = IvoryColors.gold.withValues(alpha: 0.5),
  );

  // ---- CRICKET, 0 to 0.45 --------------------------------
  if (t < 0.45) {
    // Two swings: one at full speed, one for the replay.
    double sw = 0;
    if (t < 0.10) {
      sw = math.sin(span(t, 0.02, 0.10) * math.pi);
    } else if (t > 0.24 && t < 0.42) {
      sw = math.sin(span(t, 0.24, 0.42) * math.pi);
    }
    final Offset hands = Offset(size.width * 0.17, gy - u * 0.10);
    canvas.save();
    canvas.translate(hands.dx, hands.dy);
    canvas.rotate(-1.05 + sw * 1.75);
    canvas.drawLine(
      Offset.zero,
      Offset(0, -u * 0.30),
      Paint()
        ..strokeWidth = u * 0.055
        ..strokeCap = StrokeCap.round
        ..color = IvoryColors.amber,
    );
    canvas.drawLine(
      Offset.zero,
      Offset(0, -u * 0.12),
      Paint()
        ..strokeWidth = u * 0.026
        ..strokeCap = StrokeCap.round
        ..color = IvoryColors.plum,
    );
    canvas.restore();

    // ONE red ball. It leaves the ground entirely.
    double bp = -1;
    if (t > 0.05 && t < 0.18) bp = span(t, 0.05, 0.18);
    if (t > 0.27 && t < 0.44) bp = span(t, 0.27, 0.44);
    if (bp >= 0) {
      final Offset b = Offset(
        size.width * 0.22 + size.width * 0.86 * bp,
        gy - u * 0.14 - u * 1.05 * math.sin(bp * 1.5),
      );
      canvas.drawCircle(
        b,
        u * 0.045,
        Paint()..color = IvoryColors.danger,
      );
      canvas.drawArc(
        Rect.fromCircle(center: b, radius: u * 0.045),
        -0.6,
        2.2,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = u * 0.009
          ..color = IvoryColors.cream,
      );
    }
    _label(canvas, size, t, 0.18, 0.24, 'REPLAY');
  }

  // ---- FOOTBALL, 0.49 to 0.90 ----------------------------
  if (t > 0.49 && t < 0.92) {
    // The net.
    final Rect net = Rect.fromLTWH(size.width * 0.66, gy - u * 0.46,
        size.width * 0.30, u * 0.46);
    canvas.drawRect(
      net,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = u * 0.018
        ..color = IvoryColors.plum,
    );
    for (int i = 1; i < 4; i++) {
      final double x = net.left + net.width * i / 4;
      canvas.drawLine(Offset(x, net.top), Offset(x, net.bottom),
          Paint()..color = IvoryColors.gold.withValues(alpha: 0.45));
      final double y = net.top + net.height * i / 4;
      canvas.drawLine(Offset(net.left, y), Offset(net.right, y),
          Paint()..color = IvoryColors.gold.withValues(alpha: 0.45));
    }

    // The boot.
    double kick = 0;
    if (t < 0.60) {
      kick = math.sin(span(t, 0.51, 0.60) * math.pi);
    } else if (t > 0.70 && t < 0.88) {
      kick = math.sin(span(t, 0.70, 0.88) * math.pi);
    }
    canvas.save();
    canvas.translate(size.width * 0.14, gy - u * 0.02);
    canvas.rotate(-0.55 + kick * 0.95);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, -u * 0.05, u * 0.20, u * 0.09),
        Radius.circular(u * 0.04),
      ),
      Paint()..color = IvoryColors.burgundy,
    );
    canvas.restore();

    double fp = -1;
    if (t > 0.53 && t < 0.64) fp = span(t, 0.53, 0.64);
    if (t > 0.72 && t < 0.89) fp = span(t, 0.72, 0.89);
    if (fp >= 0) {
      final Offset b = Offset(
        size.width * 0.22 + size.width * 0.58 * fp,
        gy - u * 0.10 - u * 0.42 * math.sin(fp * math.pi * 0.9),
      );
      canvas.drawCircle(b, u * 0.055, Paint()..color = IvoryColors.cream);
      canvas.drawCircle(
        b,
        u * 0.055,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = u * 0.010
          ..color = IvoryColors.burgundy,
      );
      canvas.drawCircle(b, u * 0.020, Paint()..color = IvoryColors.burgundy);
    }
    _label(canvas, size, t, 0.64, 0.70, 'SLOW MOTION');
  }

  _label(canvas, size, t, 0.92, 1.0, 'WORTH A REPLAY');
}

/// ------------------------------------------------------------
/// 3. GOOSEBUMPS - "whatever you did there, it worked."
///
/// A woman walks in, unhurried. A cool wave crosses the tile and
/// reaches her. She stops, shivers, and every hair stands up at
/// once. Then she wraps her arms around herself and stays that
/// way, still bristling. She does not relax at the end, because
/// the feeling did not.
/// ------------------------------------------------------------
void paintGoosebumps(Canvas canvas, Size size, double t) {
  final double u = size.shortestSide;
  final double gy = size.height * 0.84;

  // The cold, crossing the whole tile before it reaches her.
  if (t > 0.28 && t < 0.50) {
    final double p = span(t, 0.28, 0.50);
    final double x = -size.width * 0.3 + size.width * 1.5 * p;
    canvas.drawRect(
      Rect.fromLTWH(x, 0, size.width * 0.34, size.height),
      Paint()
        ..shader = LinearGradient(
          colors: <Color>[
            IvoryColors.cream.withValues(alpha: 0),
            const Color(0xFFB3D6FF).withValues(alpha: 0.55),
            IvoryColors.cream.withValues(alpha: 0),
          ],
        ).createShader(
            Rect.fromLTWH(x, 0, size.width * 0.34, size.height)),
    );
  }

  // She walks to the middle, then stops.
  final double walk = soft(span(t, 0, 0.34));
  double shiver = 0;
  if (t > 0.44 && t < 0.58) {
    shiver = math.sin(span(t, 0.44, 0.58) * math.pi * 9) *
        (1 - span(t, 0.44, 0.58)) *
        u *
        0.022;
  }
  final double cx = size.width * (0.14 + 0.36 * walk) + shiver;
  final double bob = t < 0.34 ? math.sin(t * math.pi * 14) * u * 0.012 : 0;

  final Paint skin = Paint()..color = const Color(0xFFF6C9A3);
  final Paint cloth = Paint()..color = IvoryColors.plum;

  // Hair, drawn before her so it sits behind the shoulders.
  canvas.drawCircle(
      Offset(cx, gy - u * 0.50 + bob), u * 0.115, Paint()..color = const Color(0xFF2E0810));
  // Head.
  canvas.drawCircle(Offset(cx, gy - u * 0.50 + bob), u * 0.095, skin);
  // Body.
  final Path body = Path()
    ..moveTo(cx - u * 0.10, gy)
    ..lineTo(cx - u * 0.075, gy - u * 0.38 + bob)
    ..quadraticBezierTo(cx, gy - u * 0.44 + bob, cx + u * 0.075,
        gy - u * 0.38 + bob)
    ..lineTo(cx + u * 0.10, gy)
    ..close();
  canvas.drawPath(body, cloth);

  // Her arms. Loose while she walks; wrapped around herself the
  // moment the cold lands, and they stay there.
  final bool wrapped = t > 0.56;
  final Paint arm = Paint()
    ..strokeWidth = u * 0.034
    ..strokeCap = StrokeCap.round
    ..color = const Color(0xFFF6C9A3);
  if (wrapped) {
    canvas.drawLine(Offset(cx - u * 0.085, gy - u * 0.33 + bob),
        Offset(cx + u * 0.055, gy - u * 0.21 + bob), arm);
    canvas.drawLine(Offset(cx + u * 0.085, gy - u * 0.33 + bob),
        Offset(cx - u * 0.055, gy - u * 0.18 + bob), arm);
  } else {
    final double sw = math.sin(t * math.pi * 14) * u * 0.03;
    canvas.drawLine(Offset(cx - u * 0.075, gy - u * 0.34 + bob),
        Offset(cx - u * 0.10 + sw, gy - u * 0.14 + bob), arm);
    canvas.drawLine(Offset(cx + u * 0.075, gy - u * 0.34 + bob),
        Offset(cx + u * 0.10 - sw, gy - u * 0.14 + bob), arm);
  }

  // Every hair up at once, then quivering, and never settling.
  if (t > 0.46) {
    final double rise = soft(span(t, 0.46, 0.54));
    final double quiver =
        1 + math.sin(t * math.pi * 26) * 0.10 * (1 - span(t, 0.54, 0.72));
    for (int i = 0; i < 6; i++) {
      final double a = -math.pi / 2 + (i - 2.5) * 0.30;
      final Offset from = Offset(cx, gy - u * 0.50 + bob) +
          Offset(math.cos(a) * u * 0.115, math.sin(a) * u * 0.115);
      final double len = u * 0.095 * rise * quiver;
      canvas.drawLine(
        from,
        from + Offset(math.cos(a) * len, math.sin(a) * len),
        Paint()
          ..strokeWidth = u * 0.015
          ..strokeCap = StrokeCap.round
          ..color = IvoryColors.plum,
      );
    }
  }

  _label(canvas, size, t, 0.72, 1.0, 'GOOSEBUMPS');
}

/// A small caption that fades in and stays. Shared by the three.
void _label(Canvas canvas, Size size, double t, double from, double to,
    String text) {
  if (t < from) return;
  final double a = span(t, from, from + (to - from) * 0.4);
  final TextPainter tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: IvoryColors.danger.withValues(alpha: a),
        fontSize: size.shortestSide * 0.085,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: size.width);
  tp.paint(canvas,
      Offset((size.width - tp.width) / 2, size.height - tp.height - 2));
}

// END OF FILE - lib/widgets/gift_scenes_a.dart
