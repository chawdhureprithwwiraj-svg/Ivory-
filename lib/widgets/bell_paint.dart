import 'dart:math' as math;

import 'package:flutter/material.dart';

/// ============================================================
/// IVORY - THE FOUR JEWEL BELLS, PAINTED
///
/// Four bells that stand out from the deep indigo around them:
/// coral for Dawn, mint for Noon, tangerine for Dusk, sky blue for
/// Night. Each is a glossy jewel-coloured bell with a crown, a bright
/// highlight, a rim band, a clapper and a glow. No black anywhere.
/// ============================================================
class BellTones {
  BellTones._();

  static const Color dawn = Color(0xFFFF6B8B);
  static const Color noon = Color(0xFF4DF0A8);
  static const Color dusk = Color(0xFFFFA42B);
  static const Color night = Color(0xFF52C7FF);
  static const Color amethyst = Color(0xFF8F6CF0);
  static const Color pearl = Color(0xFFC7B2FF);
  static const Color deep = Color(0xFF2A1A7A);
  static const List<Color> all = <Color>[dawn, noon, dusk, night];

  static const List<String> keys = <String>['dawn', 'noon', 'dusk', 'night'];

  static Color of(int i) => all[i % 4];

  static Color mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;
}

/// The bell body, in a 64 x 78 box scaled to the size given.
Path bellBody(Size size) {
  final double s = size.width / 64;
  final Path p = Path();
  p.moveTo(32 * s, 15 * s);
  p.relativeCubicTo(-12 * s, 0, -18 * s, 10 * s, -18 * s, 23 * s);
  p.relativeCubicTo(0, 8 * s, -3 * s, 12 * s, -8 * s, 16 * s);
  p.relativeLineTo(0, 4 * s);
  p.relativeLineTo(52 * s, 0);
  p.relativeLineTo(0, -4 * s);
  p.relativeCubicTo(-5 * s, -4 * s, -8 * s, -8 * s, -8 * s, -16 * s);
  p.relativeCubicTo(0, -13 * s, -6 * s, -23 * s, -18 * s, -23 * s);
  p.close();
  return p;
}

class BellPainter extends CustomPainter {
  const BellPainter({
    required this.color,
    this.glow = 0.4,
    this.shine = -1,
  });

  final Color color;

  /// 0 to 1: how brightly the bell glows.
  final double glow;

  /// 0 to 1 sweeps a bright band over the bell; below 0 means none.
  final double shine;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width / 64;
    final Color light = BellTones.mix(color, Colors.white, 0.42);
    final Color dark = BellTones.mix(color, BellTones.deep, 0.38);
    final Path body = bellBody(size);
    final Rect bb = body.getBounds();

    if (glow > 0) {
      canvas.drawPath(
        body,
        Paint()
          ..color = color.withValues(alpha: 0.75 * glow)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12 * s),
      );
    }

    // crown
    final Path crown = Path()
      ..moveTo(32 * s, 4 * s)
      ..relativeLineTo(5 * s, 6 * s)
      ..relativeLineTo(-5 * s, 6 * s)
      ..relativeLineTo(-5 * s, -6 * s)
      ..close();
    canvas.drawPath(crown, Paint()..color = light);
    canvas.drawPath(
      crown,
      Paint()
        ..color = dark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8 * s,
    );

    // body
    canvas.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          colors: <Color>[dark, light, color, dark],
          stops: const <double>[0, 0.28, 0.6, 1],
        ).createShader(bb),
    );
    canvas.drawPath(
      body,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, 0.4),
          radius: 0.7,
          colors: <Color>[
            Colors.white.withValues(alpha: 0.32),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(bb),
    );
    canvas.drawPath(
      body,
      Paint()
        ..color = dark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 * s,
    );

    // a sweep of light over the metal
    if (shine >= 0 && shine <= 1) {
      canvas.save();
      canvas.clipPath(body);
      final double x = bb.left - bb.width * 0.6 + shine * bb.width * 2.2;
      final Path band = Path()
        ..moveTo(x, bb.top)
        ..lineTo(x + bb.width * 0.35, bb.top)
        ..lineTo(x + bb.width * 0.05, bb.bottom)
        ..lineTo(x - bb.width * 0.3, bb.bottom)
        ..close();
      canvas.drawPath(
        band,
        Paint()
          ..shader = LinearGradient(
            colors: <Color>[
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: 0.75),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromLTWH(x - bb.width * 0.3, 0, bb.width * 0.65, 1)),
      );
      canvas.restore();
    }

    // highlight
    final Path hi = Path()
      ..moveTo(20 * s, 28 * s)
      ..relativeCubicTo(2.5 * s, -6 * s, 7 * s, -9 * s, 11 * s, -9 * s);
    canvas.drawPath(
      hi,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6 * s
        ..strokeCap = StrokeCap.round,
    );

    // rim band
    final RRect band = RRect.fromRectAndRadius(
      Rect.fromLTWH(6 * s, 54 * s, 52 * s, 5 * s),
      Radius.circular(2.5 * s),
    );
    canvas.drawRRect(band, Paint()..color = light.withValues(alpha: 0.8));

    // clapper
    canvas.drawCircle(Offset(32 * s, 66 * s), 5.5 * s, Paint()..color = light);
    canvas.drawCircle(
      Offset(32 * s, 66 * s),
      5.5 * s,
      Paint()
        ..color = dark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1 * s,
    );
    canvas.drawCircle(
      Offset(30.2 * s, 64.2 * s),
      1.7 * s,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
  }

  @override
  bool shouldRepaint(BellPainter o) =>
      o.color != color || o.glow != glow || o.shine != shine;
}

/// A bell as a widget. [swing] is the angle in radians; it hangs from
/// its crown like a pendulum.
class BellShape extends StatelessWidget {
  const BellShape({
    super.key,
    required this.color,
    this.width = 60,
    this.glow = 0.4,
    this.swing = 0,
    this.shine = -1,
    this.dim = false,
  });

  final Color color;
  final double width;
  final double glow;
  final double swing;
  final double shine;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final double h = width * 78 / 64;
    Widget bell = CustomPaint(
      size: Size(width, h),
      painter: BellPainter(color: color, glow: glow, shine: shine),
    );
    if (dim) {
      bell = Opacity(opacity: 0.45, child: bell);
    }
    return Transform.rotate(
      angle: swing,
      alignment: const Alignment(0, -0.85),
      child: SizedBox(width: width, height: h, child: bell),
    );
  }
}

/// The swing of a struck bell: it throws wide and settles.
double bellSwingAt(double seconds) {
  if (seconds < 0) return 0;
  return 0.47 * math.exp(-2.4 * seconds) * math.cos(2 * math.pi * 1.7 * seconds);
}

// END OF FILE - lib/widgets/bell_paint.dart
