import 'dart:math' as math;

import 'package:flutter/material.dart';

/// ============================================================
/// CC.194 - THE MISSED-YOU GLASS
///
/// A warm golden pane breathing behind frost. One ripple crosses
/// it as it wakes; 'I missed you' is traced left to right by an
/// invisible fingertip, each letter left in dew - white with a
/// warm emboss shadow, crystal-clear on any phone; a heart is
/// traced from its bottom point around the words; 'welcome back'
/// settles beneath in plum; condensation drops slide; then the
/// golden sweep of the gate wipes the glass clean into the house.
/// Only golds, creams and warm plums. No dark, no black.
/// ============================================================
class _FrostPainter extends CustomPainter {
  _FrostPainter(this.t);

  final double t;

  static const List<List<double>> _bokeh = <List<double>>[
    <double>[0.18, 0.16, 0.11],
    <double>[0.80, 0.24, 0.14],
    <double>[0.26, 0.74, 0.13],
    <double>[0.84, 0.64, 0.10],
    <double>[0.55, 0.08, 0.08],
  ];
  static const List<List<double>> _drops = <List<double>>[
    <double>[0.20, 0.28, 0.55, 0.08],
    <double>[0.72, 0.22, 0.42, 0.14],
    <double>[0.44, 0.60, 0.30, 0.28],
    <double>[0.88, 0.46, 0.36, 0.42],
    <double>[0.10, 0.52, 0.40, 0.55],
  ];

  double _clamp(double x) => x < 0 ? 0 : (x > 1 ? 1 : x);

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Rect all = Offset.zero & size;
    // The warm golden glass.
    canvas.drawRect(
      all,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[const Color(0xFFEECE84), const Color(0xFFB07412)],
        ).createShader(all),
    );
    // A lamp glowing high behind the pane.
    canvas.drawRect(
      all,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.48),
          radius: 1.05,
          colors: <Color>[const Color(0x59FFF0C8), const Color(0x00FFF0C8)],
        ).createShader(all),
    );
    // Far bokeh lights.
    for (final List<double> b in _bokeh) {
      final Offset c = Offset(b[0] * w, b[1] * h);
      final double r = b[2] * w;
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: <Color>[const Color(0x14FFE9B0), const Color(0x00FFE9B0)],
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }
    // The frost veil and its soft clouds.
    canvas.drawRect(all, Paint()..color = const Color(0x1AFFFFFF));
    for (int i = 0; i < 6; i++) {
      final Offset c = Offset(w * (0.15 + 0.14 * i), h * (0.2 + 0.12 * ((i * 3) % 5)));
      canvas.drawCircle(
        c,
        w * 0.16,
        Paint()
          ..color = const Color(0x12FFFFFF)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
      );
    }
    // One ripple breathing across the glass as it wakes.
    if (t < 0.55) {
      final double a = (0.55 - t) * 0.5;
      for (int k = 0; k < 3; k++) {
        final double r = (t * 1.8 + k * 0.30) * w * 0.9;
        canvas.drawCircle(
          Offset(w * 0.5, h * 0.46),
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..color = const Color(0xFFFFFFFF).withValues(alpha: a * (1 - k * 0.28)),
        );
      }
    }
    // 'I missed you', traced by an invisible fingertip.
    final double fs = w * 0.132;
    final TextStyle st = TextStyle(
      fontFamily: 'serif',
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w700,
      fontSize: fs,
      color: const Color(0xFFFFFCF2),
    );
    const String words = 'I missed you';
    final TextPainter tp = TextPainter(
      text: TextSpan(text: words, style: st),
      textDirection: TextDirection.ltr,
    )..layout();
    final double x0 = (w - tp.width) / 2;
    final double ty = h * 0.435;
    final double p = _clamp((t - 0.10) / 0.48);
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, w * p, h));
    tp.paint(canvas, Offset(x0 + 1.2, ty + 1.6));
    canvas.restore();
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, w * p, h));
    tp.paint(canvas, Offset(x0, ty));
    canvas.restore();
    if (p > 0 && p < 1) {
      final Offset tip = Offset(x0 + tp.width * p, ty + fs * 0.5);
      for (final List<double> g in const <List<double>>[
        <double>[11, 70],
        <double>[7, 130],
        <double>[4, 225],
      ]) {
        canvas.drawCircle(
          tip,
          g[0] * w / 288,
          Paint()..color = const Color(0xFFFFFDF4).withValues(alpha: g[1] / 255),
        );
      }
    }
    // The heart, traced from its bottom point around the words.
    final double q = _clamp((t - 0.52) / 0.40);
    if (q > 0) {
      final double sc = w * 0.0181;
      final Path path = Path();
      final int n = (240 * q).toInt();
      for (int i = 0; i <= n; i++) {
        final double a = (i / 240 + 0.5) % 1.0 * 2 * 3.14159265;
        final double x = w * 0.5 + 16 * math.pow(math.sin(a), 3).toDouble() * sc;
        final double y = h * 0.470 -
            (13 * math.cos(a) - 5 * math.cos(2 * a) - 2 * math.cos(3 * a) -
                    math.cos(4 * a)) *
                sc;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6 * w / 288
          ..strokeCap = StrokeCap.round
          ..color = const Color(0x66683A10),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 * w / 288
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xF0FFFCF2),
      );
    }
    // 'welcome back', settling beneath.
    final double s2 = _clamp((t - 0.86) / 0.14);
    if (s2 > 0) {
      final TextPainter sp = TextPainter(
        text: TextSpan(
          text: 'welcome back',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: w * 0.066,
            color: const Color(0xFF4E220E).withValues(alpha: 0.9 * s2),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      sp.paint(canvas, Offset((w - sp.width) / 2, h * 0.635));
    }
    // Condensation drops sliding down the pane.
    for (final List<double> d in _drops) {
      final double tt = t - d[3];
      if (tt <= 0) continue;
      final double y = (d[1] + tt * d[2] * 0.9) * h;
      if (y > h * 0.94) continue;
      final double x = d[0] * w;
      canvas.drawLine(
        Offset(x, y - 20 * w / 288),
        Offset(x, y),
        Paint()
          ..strokeWidth = 2 * w / 288
          ..color = const Color(0x55FFFCE8),
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: 6 * w / 288, height: 8 * w / 288),
        Paint()..color = const Color(0xAFFFDFF4),
      );
      canvas.drawCircle(
        Offset(x - w / 288, y - 2 * w / 288),
        1.2 * w / 288,
        Paint()..color = const Color(0xEBFFFFFA),
      );
    }
    // A warm vignette, never dark.
    canvas.drawRect(
      all,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.05,
          colors: <Color>[
            const Color(0x00542C10),
            const Color(0x00542C10),
            const Color(0x8C542C10),
          ],
          stops: const <double>[0, 0.55, 1],
        ).createShader(all),
    );
  }

  @override
  bool shouldRepaint(_FrostPainter old) => old.t != t;
}

// END OF FILE - lib/widgets/missed_you_glass.dart
