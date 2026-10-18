import 'dart:math' as math;

import 'package:flutter/material.dart';

/// ============================================================
/// IVORY - THE ARCH OF THE DOORBELL
///
/// A dome-topped card instead of a box: a rainbow rim that slowly
/// turns, a deep indigo sky with drifting magenta, teal and blue glows,
/// a band of light that sweeps across now and then, and little stars
/// that twinkle. Plus the title, set along an arc in pearl colours.
/// ============================================================
class ArchShell extends StatefulWidget {
  const ArchShell({super.key, required this.child});

  final Widget child;

  @override
  State<ArchShell> createState() => _ArchShellState();
}

class _ArchShellState extends State<ArchShell>
    with SingleTickerProviderStateMixin {
  static const double _rim = 3;
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        final double w = box.maxWidth;
        final BorderRadius outer = BorderRadius.only(
          topLeft: Radius.elliptical(w * 0.46, 170),
          topRight: Radius.elliptical(w * 0.46, 170),
          bottomLeft: const Radius.circular(42),
          bottomRight: const Radius.circular(42),
        );
        final BorderRadius inner = BorderRadius.only(
          topLeft: Radius.elliptical(w * 0.46 - _rim, 170 - _rim),
          topRight: Radius.elliptical(w * 0.46 - _rim, 170 - _rim),
          bottomLeft: const Radius.circular(42 - _rim),
          bottomRight: const Radius.circular(42 - _rim),
        );
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: outer,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xA6B07CFF),
                blurRadius: 28,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: const Color(0x59FF5ABE),
                blurRadius: 64,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: outer,
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _c,
                    builder: (BuildContext _, Widget? __) => CustomPaint(
                      painter: _RimPainter(_c.value),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(_rim),
                  child: ClipRRect(
                    borderRadius: inner,
                    child: Stack(
                      children: <Widget>[
                        Positioned.fill(
                          child: AnimatedBuilder(
                            animation: _c,
                            builder: (BuildContext _, Widget? __) =>
                                CustomPaint(painter: _SkyPainter(_c.value)),
                          ),
                        ),
                        widget.child,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RimPainter extends CustomPainter {
  _RimPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect r = Offset.zero & size;
    canvas.drawRect(
      r,
      Paint()
        ..shader = SweepGradient(
          transform: GradientRotation(t * 2 * math.pi),
          colors: const <Color>[
            Color(0xFFFF6B8B),
            Color(0xFFFFA42B),
            Color(0xFF4DF0A8),
            Color(0xFF52C7FF),
            Color(0xFFB07CFF),
            Color(0xFFFF6B8B),
          ],
        ).createShader(r),
    );
  }

  @override
  bool shouldRepaint(_RimPainter o) => o.t != t;
}

class _SkyPainter extends CustomPainter {
  _SkyPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect r = Offset.zero & size;
    final double w = size.width;
    final double h = size.height;
    canvas.drawRect(
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment(-0.3, -1),
          end: Alignment(0.3, 1),
          colors: <Color>[Color(0xFF2B0F94), Color(0xFF1B0A68), Color(0xFF3D0C76)],
          stops: <double>[0, 0.55, 1],
        ).createShader(r),
    );
    void glow(Offset c, double rad, Color col, double a) {
      canvas.drawCircle(
        c,
        rad,
        Paint()
          ..shader = RadialGradient(
            colors: <Color>[col.withValues(alpha: a), col.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: c, radius: rad)),
      );
    }

    final double a = t * 2 * math.pi;
    glow(
      Offset(w * (0.18 + 0.08 * math.sin(a)), h * (0.08 + 0.04 * math.cos(a))),
      w * 0.62,
      const Color(0xFF7B3DFF),
      0.75,
    );
    glow(
      Offset(w * (0.9 + 0.06 * math.cos(a)), h * (0.92 + 0.03 * math.sin(a))),
      w * 0.7,
      const Color(0xFFD8167F),
      0.7,
    );
    glow(
      Offset(w * (0.06 + 0.07 * math.sin(a + 1)), h * (0.7 + 0.05 * math.cos(a))),
      w * 0.55,
      const Color(0xFF00A8CC),
      0.62,
    );
    glow(
      Offset(w * (0.5 + 0.12 * math.cos(a + 2)), h * (1.0 - 0.03 * math.sin(a))),
      w * 0.5,
      const Color(0xFF5C7CFF),
      0.5,
    );

    // a band of light that sweeps across now and then
    final double ph = (t * 14 / 5.5) % 1;
    if (ph < 0.45) {
      final double k = ph / 0.45;
      final double x = -w * 0.5 + k * w * 1.8;
      final Path band = Path()
        ..moveTo(x, 0)
        ..lineTo(x + w * 0.3, 0)
        ..lineTo(x + w * 0.3 - h * 0.32, h)
        ..lineTo(x - h * 0.32, h)
        ..close();
      canvas.drawPath(
        band,
        Paint()
          ..shader = LinearGradient(
            colors: <Color>[
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: 0.2),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromLTWH(x - h * 0.2, 0, w * 0.3, 1)),
      );
    }

    // twinkling stars
    final math.Random rnd = math.Random(11);
    for (int i = 0; i < 16; i++) {
      final double sx = w * (0.06 + 0.88 * rnd.nextDouble());
      final double sy = h * (0.05 + 0.9 * rnd.nextDouble());
      final double off = rnd.nextDouble();
      final double per = 1.8 + 1.8 * rnd.nextDouble();
      final double tw = math.max(0, math.sin(2 * math.pi * ((t * 14) / per + off)));
      if (tw <= 0.02) continue;
      final double s = 1.5 + 4.5 * tw;
      final Path star = Path()
        ..moveTo(sx, sy - s)
        ..lineTo(sx + s * 0.22, sy - s * 0.22)
        ..lineTo(sx + s, sy)
        ..lineTo(sx + s * 0.22, sy + s * 0.22)
        ..lineTo(sx, sy + s)
        ..lineTo(sx - s * 0.22, sy + s * 0.22)
        ..lineTo(sx - s, sy)
        ..lineTo(sx - s * 0.22, sy - s * 0.22)
        ..close();
      canvas.drawPath(
        star,
        Paint()..color = Colors.white.withValues(alpha: 0.9 * tw),
      );
    }
  }

  @override
  bool shouldRepaint(_SkyPainter o) => o.t != t;
}

/// The title along an arc, each letter shaded from pink through white
/// to cyan and mint, with a soft glow.
class ArcTitle extends StatelessWidget {
  const ArcTitle({super.key, required this.text, this.fade = 1});

  final String text;
  final double fade;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 600),
      opacity: fade,
      child: CustomPaint(
        painter: _ArcTitlePainter(text),
        size: const Size(double.infinity, 108),
      ),
    );
  }
}

class _ArcTitlePainter extends CustomPainter {
  _ArcTitlePainter(this.text);

  final String text;

  static const List<Color> _stops = <Color>[
    Color(0xFFFFB3D6),
    Color(0xFFFFFFFF),
    Color(0xFFC9F7FF),
    Color(0xFFB6FFD2),
  ];

  Color _at(double u) {
    final double x = u.clamp(0.0, 1.0) * (_stops.length - 1);
    final int i = math.min(x.floor(), _stops.length - 2);
    return Color.lerp(_stops[i], _stops[i + 1], x - i)!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double fs = math.min(27, size.width / 13.5);
    final List<TextPainter> gl = <TextPainter>[];
    double total = 0;
    for (int i = 0; i < text.length; i++) {
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: text[i],
          style: TextStyle(
            fontFamily: 'serif',
            fontWeight: FontWeight.w900,
            fontSize: fs,
            color: _at(i / math.max(1, text.length - 1)),
            shadows: const <Shadow>[
              Shadow(color: Color(0xAAFFFFFF), blurRadius: 9),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      gl.add(tp);
      total += tp.width + 3;
    }
    final double rad = size.width * 0.62;
    // The outer letters sink lower than the middle ones; keep them all
    // above the bottom edge so the line beneath is never touched.
    final double drop = rad * (1 - math.cos(math.min(1.2, total / (2 * rad))));
    final Offset c = Offset(size.width / 2, size.height + rad - 14 - drop);
    double ang = -total / (2 * rad);
    for (final TextPainter tp in gl) {
      final double wA = (tp.width + 3) / rad;
      final double th = ang + wA / 2;
      canvas.save();
      canvas.translate(c.dx + rad * math.sin(th), c.dy - rad * math.cos(th));
      canvas.rotate(th);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height));
      canvas.restore();
      ang += wA;
    }
  }

  @override
  bool shouldRepaint(_ArcTitlePainter o) => o.text != text;
}

// END OF FILE - lib/widgets/bells_arch.dart
