import 'package:flutter/material.dart';

/// One painted segment of the Wheel of Fans.
class WheelSeg {
  const WheelSeg(this.label, this.color, this.kind);
  final String label;
  final Color color;
  final String kind;
}

/// The wheel itself, painted in three dimensions without a single
/// package: radial dome gradients per segment, a cast-gold bevel rim with
/// twenty-four notches, engraved separators, a travelling specular shine
/// and a cream coin hub. Nothing flat, nothing cheap.
class WheelPainter extends CustomPainter {
  WheelPainter({
    required this.segs,
    required this.angle,
    this.shine = 0.0,
    this.dim = false,
  });

  final List<WheelSeg> segs;
  final double angle; // radians, whole-wheel rotation
  final double shine; // 0..1 travelling highlight position
  final bool dim;

  static Color shade(Color c, double t) {
    if (t >= 0) {
      return Color.fromRGBO(
          (c.red + (255 - c.red) * t).round(),
          (c.green + (255 - c.green) * t).round(),
          (c.blue + (255 - c.blue) * t).round(),
          1);
    }
    final double k = 1 + t;
    return Color.fromRGBO((c.red * k).round().clamp(0, 255),
        (c.green * k).round().clamp(0, 255),
        (c.blue * k).round().clamp(0, 255), 1);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double r = size.shortestSide / 2;
    final Offset c = Offset(size.width / 2, size.height / 2);
    final int n = segs.isEmpty ? 12 : segs.length;
    final double arc = 6.283185307 / n;

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(angle);

    // under-shadow of the whole wheel: the velvet catches it
    final Paint sh = Paint()
      ..color = const Color(0x66200A10).withOpacity(dim ? 0.25 : 0.4);
    canvas.drawCircle(Offset(0, r * 0.03), r, sh);

    // segments: domed radial gradients, bright heart to deep edge
    for (int i = 0; i < n; i++) {
      final WheelSeg s = segs[i % segs.length];
      final double a0 = i * arc - 1.5707963;
      final Path p = Path()
        ..moveTo(0, 0)
        ..arcTo(Rect.fromCircle(center: Offset.zero, radius: r * 0.94),
            a0, arc, false)
        ..close();
      final Color base = s.color;
      p.addRect(Rect.zero);
      final Paint fill = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.15, -0.25),
          radius: 1.25,
          colors: <Color>[
            shade(base, 0.42),
            base,
            shade(base, -0.34),
          ],
          stops: const <double>[0.12, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));
      canvas.drawPath(
          Path()
            ..moveTo(0, 0)
            ..arcTo(Rect.fromCircle(center: Offset.zero, radius: r * 0.94),
                a0, arc, false)
            ..close(),
          fill);

      // engraved separator between segments
      final Paint sep = Paint()
        ..color = const Color(0x59FFF6E5)
        ..strokeWidth = 1.4;
      canvas.drawLine(Offset.zero,
          Offset.fromDirection(a0, r * 0.93), sep);

      // label, rotated to stand upright on its segment
      canvas.save();
      canvas.rotate(a0 + arc / 2);
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: segs[i % segs.length].label.replaceFirst(' · the crown', ''),
          style: TextStyle(
            color: segs[i % segs.length].kind == 'rest'
                ? const Color(0xFF6B5F4C)
                : const Color(0xFFFFF6E5),
            fontSize: r * (segs[i % segs.length].label.length > 9 ? 0.052 : 0.085),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            shadows: <Shadow>[
              Shadow(color: const Color(0x80200A10), blurRadius: 3)
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas,
          Offset(r * 0.60 - tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    // travelling specular shine: a soft white sweep across the dome
    if (shine > 0 && shine < 1) {
      final double sa = shine * 6.283185307;
      final Paint gl = Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            const Color(0x59FFFFFF),
            const Color(0x00FFFFFF),
          ],
        ).createShader(Rect.fromCircle(
            center: Offset.fromDirection(sa, r * 0.45), radius: r * 0.75));
      canvas.drawCircle(Offset.zero, r * 0.94, gl);
    }

    // cast-gold bevel rim with twenty-four notches
    final Paint rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.085
      ..shader = SweepGradient(
        colors: const <Color>[
          Color(0xFFF6D98A),
          Color(0xFFB9822B),
          Color(0xFFF6D98A),
          Color(0xFF8A5E1C),
          Color(0xFFF6D98A),
        ],
        stops: const <double>[0, 0.25, 0.5, 0.75, 1],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));
    canvas.drawCircle(Offset.zero, r * 0.965, rim);
    final Paint notch = Paint()
      ..color = const Color(0xFF7A5216)
      ..strokeWidth = r * 0.016;
    for (int k = 0; k < 24; k++) {
      final double a = k * 6.283185307 / 24;
      canvas.drawLine(Offset.fromDirection(a, r * 0.925),
          Offset.fromDirection(a, r * 1.0), notch);
    }

    // cream coin hub, embossed
    final Paint hub = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.35),
        colors: const <Color>[
          Color(0xFFFFFDF6),
          Color(0xFFF3E4C2),
          Color(0xFFD9BE8A),
        ],
        stops: const <double>[0.1, 0.65, 1],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: r * 0.20));
    canvas.drawCircle(Offset.zero, r * 0.20, hub);
    final Paint hubRing = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.018
      ..color = const Color(0xFFB9822B);
    canvas.drawCircle(Offset.zero, r * 0.20, hubRing);
    final TextPainter mark = TextPainter(
      text: const TextSpan(
        text: '✦',
        style: TextStyle(
            color: Color(0xFF4A0E17),
            fontSize: 34,
            fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    mark.paint(canvas, Offset(-mark.width / 2, -mark.height / 2));

    canvas.restore();
  }

  @override
  bool shouldRepaint(WheelPainter old) =>
      old.angle != angle || old.shine != shine || old.dim != dim;
}

// END OF FILE - lib/widgets/wheel_painter.dart
