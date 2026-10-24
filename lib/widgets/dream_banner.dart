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
        size: const Size(292, 46),
        painter: _BannerPainter(widget.show, _life.value),
      ),
    );
  }
}

class _BannerPainter extends CustomPainter {
  _BannerPainter(this.show, this.life);

  final DreamShow show;
  final double life;

  static const double H = 46;

  Path _plaque(double w, double inset) {
    final double p = 10 - inset * 0.5;
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
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
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
    for (double x = 0; x < w; x += 12) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + H, H),
        Paint()..color = const Color(0x0DF6DE9C)..strokeWidth = 2.5,
      );
    }
    // Inner top light and bottom shade: the velvet has a body.
    canvas.drawRect(
      Rect.fromLTRB(0, 3, w, 9),
      Paint()..color = const Color(0x26FFECBE),
    );
    canvas.drawRect(
      Rect.fromLTRB(0, H - 9, w, H - 3),
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
    for (final double rx in <double>[11, w - 11]) {
      canvas.drawCircle(
        Offset(rx, H / 2),
        2.2,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.35, -0.4),
            colors: <Color>[const Color(0xFFFFF6D8), const Color(0xFFA9781C)],
          ).createShader(Rect.fromCircle(center: Offset(rx, H / 2), radius: 2.2)),
      );
    }

    // The crown medallion, embossed.
    const double cx = 25;
    const double cy = H / 2;
    canvas.drawCircle(
      Offset(cx, cy + 1),
      12,
      Paint()..color = const Color(0x66200409),
    );
    canvas.drawCircle(
      Offset(cx, cy),
      12,
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
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 12)),
    );
    // The crown itself: three points, two pearls.
    final Path crown = Path()
      ..moveTo(cx - 6.5, cy + 4)
      ..lineTo(cx - 6.5, cy - 0.8)
      ..lineTo(cx - 3.2, cy + 1.2)
      ..lineTo(cx, cy - 4)
      ..lineTo(cx + 3.2, cy + 1.2)
      ..lineTo(cx + 6.5, cy - 0.8)
      ..lineTo(cx + 6.5, cy + 4)
      ..close();
    canvas.drawPath(crown, Paint()..color = const Color(0xFF5C1220));
    canvas.drawCircle(Offset(cx, cy - 5.2), 1.2, Paint()..color = const Color(0xFFFFF6D8));
    canvas.drawCircle(Offset(cx - 6.5, cy - 2), 1, Paint()..color = const Color(0xFFFFF6D8));
    canvas.drawCircle(Offset(cx + 6.5, cy - 2), 1, Paint()..color = const Color(0xFFFFF6D8));

    // The metallic cartouche seal.
    const double sx = 43;
    final Rect seal = Rect.fromLTWH(sx, cy - 6.5, 88, 13);
    canvas.drawRRect(
      RRect.fromRectAndRadius(seal, const Radius.circular(3)),
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
      Offset(sx + 5, cy - 4.2),
      TextStyle(
        fontSize: 6.5,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.9,
        color: const Color(0xFF3A2405),
      ),
      maxW: 78,
    );

    // The dreamed name and deed.
    final double maxW = w - sx - 95 - 8;
    _text(
      canvas,
      show.name,
      Offset(sx + 95, cy - 12),
      const TextStyle(
        fontFamily: 'serif',
        fontStyle: FontStyle.italic,
        fontSize: 12.5,
        fontWeight: FontWeight.w800,
        color: Color(0xFFFFF3CF),
      ),
      shadow: const Shadow(color: Color(0x993C0A12), offset: Offset(0, 1)),
      maxW: maxW,
    );
    _text(
      canvas,
      show.deed,
      Offset(sx + 95, cy + 3),
      const TextStyle(
        fontFamily: 'serif',
        fontStyle: FontStyle.italic,
        fontSize: 9.5,
        color: Color(0xD9F6DE9C),
      ),
      maxW: maxW,
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

  void _text(Canvas canvas, String s, Offset at, TextStyle st,
      {Shadow? shadow, double? maxW}) {
    final TextPainter tp = TextPainter(
      text: TextSpan(text: s, style: shadow == null ? st : st.copyWith(shadows: <Shadow>[shadow])),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '\u2026',
    )..layout(maxWidth: maxW ?? double.infinity);
    tp.paint(canvas, at);
  }

  @override
  bool shouldRepaint(_BannerPainter old) =>
      old.life != life || old.show != show;
}

/// Petals from a cheered dream: nine twinkles walking outward and
/// fading, in cream and gold. A dream's cheer leaves no ledger.
class DreamPetalPainter extends CustomPainter {
  DreamPetalPainter(this.t, this.at) : super(repaint: t);

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
  bool shouldRepaint(DreamPetalPainter old) => old.t != t || old.at != at;
}


/// The burgundy honesty card, shown once, before the first dream.
class DreamHonestyCard extends StatelessWidget {
const DreamHonestyCard({super.key, required this.onClose});

final VoidCallback onClose;

@override
Widget build(BuildContext context) {
  return Positioned(
    left: 16,
    right: 16,
    bottom: MediaQuery.of(context).padding.bottom + 24,
    child: Material(
      color: const Color(0xFF4A0E17),
      borderRadius: BorderRadius.circular(18),
      elevation: 10,
      shadowColor: const Color(0x66280812),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2B34C), width: 2),
        ),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Sometimes the house dreams aloud',
              style: TextStyle(
                fontFamily: 'serif',
                fontStyle: FontStyle.italic,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFFFFF3CF),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'A ribbon sealed YOUR DREAM HOUSE imagines a member yet '
              'to come - a quiet fiction, always labelled, never '
              'counted anywhere. Every other ribbon is a real voice '
              'from a real room.',
              style: TextStyle(fontSize: 13, height: 1.45,
                  color: Color(0xE6F6DE9C)),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onClose,
                child: const Text(
                  'Let the house dream',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFFFE9A8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}


// END OF FILE - lib/widgets/dream_banner.dart
