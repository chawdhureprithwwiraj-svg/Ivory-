import 'dart:math' as math;
import 'dart:ui';

/// ============================================================
/// IVORY - THE IVORY LADDER: THE LITTLE PICTURES ON THE MARKS
///
/// Each Mark carries one small picture, named by its `glyph` in the
/// database. Every picture is drawn as a filled shape inside a unit
/// circle (about -1 to 1) and then scaled to the medallion.
/// ============================================================
Path _ring(double r, double hole, {double cx = 0, double cy = 0}) {
  return Path()
    ..fillType = PathFillType.evenOdd
    ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r))
    ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: hole));
}

Path _poly(List<double> p) {
  final Path path = Path()..moveTo(p[0], p[1]);
  for (int i = 2; i < p.length; i += 2) {
    path.lineTo(p[i], p[i + 1]);
  }
  return path..close();
}

Path _starPath(int pts, double outer, double inner) {
  final Path p = Path();
  for (int i = 0; i < pts * 2; i++) {
    final double a = -math.pi / 2 + i * math.pi / pts;
    final double r = i.isEven ? outer : inner;
    final double x = r * math.cos(a);
    final double y = r * math.sin(a);
    if (i == 0) {
      p.moveTo(x, y);
    } else {
      p.lineTo(x, y);
    }
  }
  return p..close();
}

/// A five-point star path of radius [r], used by the star badge too.
Path ladderStarPath(double r) => _starPath(5, r, r * 0.46);

/// The picture for [glyph] inside a unit circle.
Path ladderGlyph(String glyph) {
  switch (glyph) {
    case 'flame':
      return Path()
        ..moveTo(0, -0.95)
        ..cubicTo(0.2, -0.5, 0.75, -0.2, 0.62, 0.4)
        ..cubicTo(0.55, 0.85, 0.15, 0.95, 0, 0.95)
        ..cubicTo(-0.15, 0.95, -0.55, 0.85, -0.62, 0.4)
        ..cubicTo(-0.68, 0.0, -0.4, -0.2, -0.3, -0.5)
        ..cubicTo(-0.15, -0.35, -0.05, -0.5, 0, -0.95)
        ..close();
    case 'crown':
      return _poly(<double>[
        -0.85, 0.6, -0.85, -0.45, -0.4, 0.05, 0, -0.7, 0.4, 0.05, 0.85, -0.45,
        0.85, 0.6,
      ]);
    case 'bell':
      return Path()
        ..moveTo(0, -0.85)
        ..cubicTo(0.55, -0.85, 0.65, -0.3, 0.7, 0.2)
        ..lineTo(0.9, 0.5)
        ..lineTo(-0.9, 0.5)
        ..lineTo(-0.7, 0.2)
        ..cubicTo(-0.65, -0.3, -0.55, -0.85, 0, -0.85)
        ..close()
        ..addOval(Rect.fromCircle(center: const Offset(0, 0.75), radius: 0.2));
    case 'star':
      return ladderStarPath(1.0);
    case 'chain':
      return _ring(0.5, 0.26, cx: -0.4)..addPath(_ring(0.5, 0.26, cx: 0.4), Offset.zero);
    case 'promise':
      return _ring(0.95, 0.68)
        ..addPath(
          _poly(<double>[-0.5, 0.0, -0.3, -0.2, -0.1, 0.1, 0.4, -0.45, 0.6, -0.25, -0.1, 0.5]),
          Offset.zero,
        );
    case 'gem':
      return _poly(<double>[-0.5, -0.8, 0.5, -0.8, 0.95, -0.15, 0, 0.95, -0.95, -0.15]);
    case 'circle':
      return _ring(0.95, 0.55)
        ..addPath(_poly(<double>[0.6, -0.95, 0.95, -0.35, 0.3, -0.45]), Offset.zero);
    case 'book':
      return _poly(<double>[-0.95, -0.6, -0.08, -0.45, -0.08, 0.75, -0.95, 0.6])
        ..addPath(_poly(<double>[0.95, -0.6, 0.08, -0.45, 0.08, 0.75, 0.95, 0.6]), Offset.zero);
    case 'vote':
      return Path()
        ..fillType = PathFillType.evenOdd
        ..addRRect(RRect.fromRectAndRadius(const Rect.fromLTRB(-0.85, -0.1, 0.85, 0.85), const Radius.circular(0.15)))
        ..addRect(const Rect.fromLTRB(-0.4, 0.15, 0.4, 0.3))
        ..addPath(_poly(<double>[-0.35, -0.85, 0.35, -0.85, 0.35, -0.2, -0.35, -0.2]), Offset.zero);
    case 'live':
      return _ring(0.3, 0.0)
        ..addPath(_ring(0.62, 0.45), Offset.zero)
        ..addPath(_ring(0.95, 0.78), Offset.zero);
    case 'wish':
      return Path()
        ..moveTo(0, 0.9)
        ..cubicTo(-1.1, 0.1, -0.8, -0.85, 0, -0.35)
        ..cubicTo(0.8, -0.85, 1.1, 0.1, 0, 0.9)
        ..close();
    case 'key':
      return _ring(0.45, 0.22, cx: -0.45)
        ..addRect(const Rect.fromLTRB(0.02, -0.1, 0.95, 0.1))
        ..addRect(const Rect.fromLTRB(0.5, 0.1, 0.7, 0.45))
        ..addRect(const Rect.fromLTRB(0.78, 0.1, 0.95, 0.35));
    case 'quiz':
      return _ring(0.95, 0.72)
        ..addPath(_ring(0.52, 0.3), Offset.zero)
        ..addOval(Rect.fromCircle(center: Offset.zero, radius: 0.12));
    case 'chest':
      return Path()
        ..moveTo(-0.9, -0.1)
        ..cubicTo(-0.9, -0.85, 0.9, -0.85, 0.9, -0.1)
        ..close()
        ..addRRect(RRect.fromRectAndRadius(const Rect.fromLTRB(-0.9, -0.05, 0.9, 0.8), const Radius.circular(0.1)));
    case 'spark':
    default:
      return Path()
        ..moveTo(0, -1)
        ..quadraticBezierTo(0.12, -0.12, 1, 0)
        ..quadraticBezierTo(0.12, 0.12, 0, 1)
        ..quadraticBezierTo(-0.12, 0.12, -1, 0)
        ..quadraticBezierTo(-0.12, -0.12, 0, -1)
        ..close();
  }
}

// END OF FILE - lib/widgets/ladder_glyphs.dart
