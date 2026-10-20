import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'ticker_palettes.dart';

/// ============================================================
/// IVORY - THE CHEER BURST
///
/// When a member sends a cheer, the chosen symbol swells up in the
/// middle of the sheet and fades, with a ring of painted four-point
/// twinkles flying outward, all in the ribbon's own colours.
/// [t] runs 0 to 1 over about a second and a half.
/// ============================================================

/// The four styles: database word, label, symbol.
const List<List<Object>> kCheerStyles = <List<Object>>[
  <Object>['applause', 'APPLAUSE', Icons.celebration_rounded],
  <Object>['sparkle', 'SPARKLE', Icons.auto_awesome_rounded],
  <Object>['heart', 'HEART', Icons.favorite_rounded],
  <Object>['crown', 'CROWN', Icons.workspace_premium_rounded],
];

IconData cheerIcon(String style) {
  for (final List<Object> s in kCheerStyles) {
    if (s[0] == style) return s[2] as IconData;
  }
  return Icons.auto_awesome_rounded;
}

Path _twinkle(Offset c, double r) {
  final double k = r * 0.22;
  return Path()
    ..moveTo(c.dx, c.dy - r)
    ..quadraticBezierTo(c.dx + k, c.dy - k, c.dx + r, c.dy)
    ..quadraticBezierTo(c.dx + k, c.dy + k, c.dx, c.dy + r)
    ..quadraticBezierTo(c.dx - k, c.dy + k, c.dx - r, c.dy)
    ..quadraticBezierTo(c.dx - k, c.dy - k, c.dx, c.dy - r)
    ..close();
}

class CheerBurstPainter extends CustomPainter {
  CheerBurstPainter(this.t, this.style, this.pal) : super(repaint: t);

  final Animation<double> t;
  final String style;
  final TickerPalette pal;

  @override
  void paint(Canvas canvas, Size size) {
    final double v = t.value;
    if (v <= 0 || v >= 1) return;
    final Offset c = Offset(size.width / 2, size.height * 0.62);
    final double out = Curves.easeOutCubic.transform(v);
    final double fade = v < 0.55 ? 1.0 : (1 - (v - 0.55) / 0.45).clamp(0.0, 1.0);

    // A ring of twinkles flying outward.
    final math.Random r = math.Random(11);
    final List<Color> cols = <Color>[pal.trim, pal.light, kTickerCream];
    for (int i = 0; i < 18; i++) {
      final double a = (i / 18) * 2 * math.pi + r.nextDouble() * 0.3;
      final double reach = 54 + r.nextDouble() * 96;
      final Offset p = c + Offset(math.cos(a), math.sin(a)) * (reach * out);
      final double s = (3.0 + r.nextDouble() * 5.0) * (1 - 0.55 * out);
      final Paint glow = Paint()
        ..color = cols[i % 3].withValues(alpha: 0.35 * fade)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawPath(_twinkle(p, s * 1.6), glow);
      canvas.drawPath(
        _twinkle(p, s),
        Paint()..color = cols[i % 3].withValues(alpha: fade),
      );
    }

    // The symbol: swells, rises a little, then fades.
    final double scale = 0.55 + 1.05 * out;
    final double lift = -16 * out;
    final IconData ic = cheerIcon(style);
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(ic.codePoint),
        style: TextStyle(
          fontFamily: ic.fontFamily,
          package: ic.fontPackage,
          fontSize: 64 * scale,
          color: kTickerCream.withValues(alpha: fade),
          shadows: <Shadow>[
            Shadow(
              color: pal.deep.withValues(alpha: 0.75 * fade),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
            Shadow(
              color: pal.trim.withValues(alpha: 0.9 * fade),
              blurRadius: 22,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c + Offset(-tp.width / 2, -tp.height / 2 + lift));
  }

  @override
  bool shouldRepaint(covariant CheerBurstPainter old) =>
      old.style != style || old.pal != pal;
}

// END OF FILE - lib/widgets/ticker_cheer_burst.dart
