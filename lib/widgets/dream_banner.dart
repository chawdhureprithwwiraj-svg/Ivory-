import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'dream_house.dart';

/// ============================================================
/// IVORY - THE DREAM HOUSE BANNER (CC.195)
///
/// The royal ribbon: a burgundy velvet plaque with pointed
/// heraldic ends inside a CAST-GOLD BEVEL that catches light
/// top-left and shades bottom-right like real metal; an embossed
/// crown medallion with its own highlight and root-shadow; a
/// metallic cartouche seal reading YOUR DREAM HOUSE; two gold
/// rivets at the points; a whisper of damask in the velvet; a
/// slow shimmer walking the metal; and the whole banner floating
/// on a deep shadow above the room. The dreamed name rides in
/// cream serif italic with its deed in pale gold.
///
/// Nothing dark ever touches it but the velvet's own root, and
/// even that root is burgundy, never black.
/// ============================================================
class DreamBanner extends StatefulWidget {
  const DreamBanner({super.key, required this.show, required this.t});

  final DreamShow show;
  final Animation<double> t;

  @override
  State<DreamBanner> createState() => _DreamBannerState();
}

class _DreamBannerState extends State<DreamBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _life = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat();

  @override
  void dispose() {
    _life.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _life,
      builder: (BuildContext context, Widget? child) => CustomPaint(
        size: const Size(340, 58),
        painter: _BannerPainter(widget.show, _life.value),
      ),
    );
  }
}

class _BannerPainter extends CustomPainter {
  _BannerPainter(this.show, this.life);

  final DreamShow show;
  final double life;

  static const double H = 58;

  Path _plaque(double w, double inset) {
    final double p = 12 - inset * 0.6;
    return Path()
      ..moveTo(inset, H / 2)
      ..lineTo(inset + p, inset)
      ..lineTo(w - inset - p, inset)
      ..lineTo(w - inset, H / 2)
      ..lineTo(w - inset - p, H - inset)
      ..lineTo(inset + p, H - inset)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final Rect all = Offset.zero & size;

    // The float: a deep soft shadow under the whole banner.
    canvas.saveLayer(all, Paint());
    canvas.drawPath(
      _plaque(w, 2),
      Paint()
        ..color = const Color(0x55280812)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );

    // The cast-gold bevel frame.
    canvas.drawPath(
      _plaque(w, 2),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            const Color(0xFFFFF6D8),
            const Color(0xFFE2B34C),
            const Color(0xFF8A5A10),
            const Color(0xFFF6DE9C),
            const Color(0xFFA9781C),
            const Color(0xFFFFF0BE),
          ],
          stops: const <double>[0, 0.22, 0.46, 0.62, 0.82, 1],
        ).createShader(all),
    );

    // The velvet field inside the frame.
    canvas.drawPath(
      _plaque(w, 4.5),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            const Color(0xFF8A2A3B),
            const Color(0xFF5C1220),
            const Color(0xFF3A0B12),
          ],
          stops: const <double>[0, 0.45, 1],
        ).createShader(all),
    );
    // A whisper of damask in the velvet.
    canvas.save();
    canvas.clipPath(_plaque(w, 4.5));
    for (double x = 0; x < w; x += 14) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + H, H),
        Paint()..color = const Color(0x0DF6DE9C)..strokeWidth = 3,
      );
    }
    // Inner top light and bottom shade: the velvet has a body.
    canvas.drawRect(
      Rect.fromLTRB(0, 4, w, 12),
      Paint()..color = const Color(0x26FFECBE),
    );
    canvas.drawRect(
      Rect.fromLTRB(0, H - 12, w, H - 4),
      Paint()..color = const Color(0x33140206),
    );
    canvas.restore();

    // The inner hairline.
    canvas.drawPath(
      _plaque(w, 6.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xB3F6DE9C),
    );

    // Rivets at the heraldic points.
    for (final double rx in <double>[13, w - 13]) {
      canvas.drawCircle(
        Offset(rx, H / 2),
        2.6,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.35, -0.4),
            colors: <Color>[const Color(0xFFFFF6D8), const Color(0xFFA9781C)],
          ).createShader(Rect.fromCircle(center: Offset(rx, H / 2), radius: 2.6)),
      );
    }

    // The crown medallion, embossed.
    const double cx = 30;
    const double cy = H / 2;
    canvas.drawCircle(
      Offset(cx, cy + 1.2),
      15,
      Paint()..color = const Color(0x66200409),
    );
    canvas.drawCircle(
      Offset(cx, cy),
      15,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.36, -0.42),
          colors: <Color>[
            const Color(0xFFFFFBEA),
            const Color(0xFFF6DE9C),
            const Color(0xFFE2B34C),
            const Color(0xFF8A5A10),
            const Color(0xFF5C3A08),
          ],
          stops: const <double>[0, 0.3, 0.55, 0.82, 1],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 15)),
    );
    // The crown itself: three points, two pearls.
    final Path crown = Path()
      ..moveTo(cx - 8, cy + 5)
      ..lineTo(cx - 8, cy - 1)
      ..lineTo(cx - 4, cy + 1.5)
      ..lineTo(cx, cy - 5)
      ..lineTo(cx + 4, cy + 1.5)
      ..lineTo(cx + 8, cy - 1)
      ..lineTo(cx + 8, cy + 5)
      ..close();
    canvas.drawPath(crown, Paint()..color = const Color(0xFF5C1220));
    canvas.drawCircle(Offset(cx, cy - 6.4), 1.5, Paint()..color = const Color(0xFFFFF6D8));
    canvas.drawCircle(Offset(cx - 8, cy - 2.4), 1.2, Paint()..color = const Color(0xFFFFF6D8));
    canvas.drawCircle(Offset(cx + 8, cy - 2.4), 1.2, Paint()..color = const Color(0xFFFFF6D8));

    // The metallic cartouche seal.
    const double sx = 52;
    final Rect seal = Rect.fromLTWH(sx, cy - 8, 96, 16);
    canvas.drawRRect(
      RRect.fromRectAndRadius(seal, const Radius.circular(4)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            const Color(0xFFFFF6D8),
            const Color(0xFFE2B34C),
            const Color(0xFFA9781C),
            const Color(0xFFF6DE9C),
          ],
          stops: const <double>[0, 0.45, 0.7, 1],
        ).createShader(seal),
    );
    _text(
      canvas,
      'YOUR DREAM HOUSE',
      Offset(sx + 7, cy - 5),
      TextStyle(
        fontSize: 8.5,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.6,
        color: const Color(0xFF3A2405),
      ),
    );

    // The dreamed name and deed.
    _text(
      canvas,
      show.name,
      Offset(sx + 104, cy - 15),
      const TextStyle(
        fontFamily: 'serif',
        fontStyle: FontStyle.italic,
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: Color(0xFFFFF3CF),
      ),
      shadow: const Shadow(color: Color(0x993C0A12), offset: Offset(0, 1)),
    );
    _text(
      canvas,
      show.deed,
      Offset(sx + 104, cy + 4),
      const TextStyle(
        fontFamily: 'serif',
        fontStyle: FontStyle.italic,
        fontSize: 11.5,
        color: Color(0xD9F6DE9C),
      ),
    );

    // The shimmer walking the metal.
    canvas.save();
    canvas.clipPath(_plaque(w, 2));
    final double gx = -w * 0.35 + ((life * 1.35) % 1.0) * w * 1.45;
    final Rect band = Rect.fromLTWH(gx, 0, w * 0.22, H);
    canvas.drawRect(
      band,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[
            const Color(0x00FFF6DC),
            const Color(0x66FFF6DC),
            const Color(0x00FFF6DC),
          ],
        ).createShader(band),
    );
    canvas.restore();
    canvas.restore();
  }

  void _text(Canvas canvas, String s, Offset at, TextStyle st, {Shadow? shadow}) {
    final TextPainter tp = TextPainter(
      text: TextSpan(text: s, style: shadow == null ? st : st.copyWith(shadows: <Shadow>[shadow])),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at);
  }

  @override
  bool shouldRepaint(_BannerPainter old) =>
      old.life != life || old.show != show;
}

/// Petals from a cheered dream: nine twinkles walking outward and
/// fading, in cream and gold. A dream's cheer leaves no ledger.
class DreamPetalPainter extends CustomPainter {
  _PetalPainter(this.t, this.at) : super(repaint: t);

  final Animation<double> t;
  final Offset at;

  @override
  void paint(Canvas canvas, Size size) {
    final double v = t.value;
    if (v <= 0 || v >= 1) return;
    final List<Color> cols = <Color>[
      const Color(0xFFFFF3CF),
      const Color(0xFFE2B34C),
      const Color(0xFF8A2A3B),
    ];
    for (int i = 0; i < 9; i++) {
      final double a = i * 2 * 3.14159 / 9 + v * 0.6;
      final double r = 12 + v * 46;
      final Offset c = at + Offset(math.cos(a) * r, math.sin(a) * r * 0.7);
      final double k = (1 - v) * 4.5;
      final Path p = Path()
        ..moveTo(c.dx, c.dy - k)
        ..quadraticBezierTo(c.dx + k * 0.3, c.dy - k * 0.3, c.dx + k, c.dy)
        ..quadraticBezierTo(c.dx + k * 0.3, c.dy + k * 0.3, c.dx, c.dy + k)
        ..quadraticBezierTo(c.dx - k * 0.3, c.dy + k * 0.3, c.dx - k, c.dy)
        ..quadraticBezierTo(c.dx - k * 0.3, c.dy - k * 0.3, c.dx, c.dy - k)
        ..close();
      canvas.drawPath(p, Paint()..color = cols[i % 3].withOpacity((1 - v) * 0.9));
    }
  }

  @override
  bool shouldRepaint(_PetalPainter old) => old.t != t || old.at != at;
}


// END OF FILE - lib/widgets/dream_banner.dart
