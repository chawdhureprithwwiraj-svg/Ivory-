import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'gold_fx.dart';

/// ============================================================
/// IVORY - BURSTS OF LIGHT
///
/// The moments of light in The Golden Knock-off: a ring of light
/// racing outward (shockwave), a flash of gold over the whole
/// screen, and a rain of tumbling glitter. All painted in code.
/// ============================================================

class _WavePainter extends CustomPainter {
  _WavePainter(this.t, this.origin);
  final double t;
  final Alignment origin;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset o = Offset(
      size.width * (origin.x + 1) / 2,
      size.height * (origin.y + 1) / 2,
    );
    final double e = Curves.easeOutCubic.transform(t);
    for (int i = 0; i < 2; i++) {
      final double k = (e - i * 0.12).clamp(0.0, 1.0).toDouble();
      if (k <= 0) continue;
      canvas.drawCircle(
        o,
        size.longestSide * 0.75 * k,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7 * (1 - k) + 1
          ..color = GoldTones.shine.withValues(alpha: 0.7 * (1 - k))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.t != t;
}

/// A ring of light that races outward once. Give it a new key to fire again.
class GoldShockwave extends StatefulWidget {
  const GoldShockwave({super.key, this.origin = const Alignment(0, 0.2)});

  final Alignment origin;

  @override
  State<GoldShockwave> createState() => _GoldShockwaveState();
}

class _GoldShockwaveState extends State<GoldShockwave>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (BuildContext context, Widget? _) => CustomPaint(
          size: Size.infinite,
          painter: _WavePainter(_c.value, widget.origin),
        ),
      ),
    );
  }
}

/// A burst of golden light over the whole screen, once, then gone.
class GoldFlash extends StatefulWidget {
  const GoldFlash({super.key, this.strength = 0.4});

  final double strength;

  @override
  State<GoldFlash> createState() => _GoldFlashState();
}

class _GoldFlashState extends State<GoldFlash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (BuildContext context, Widget? _) {
          final double a =
              widget.strength * math.pow(1 - _c.value, 2).toDouble();
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.1),
                radius: 1.1,
                colors: <Color>[
                  GoldTones.shine.withValues(alpha: a),
                  GoldTones.mid.withValues(alpha: a * 0.3),
                  GoldTones.mid.withValues(alpha: 0),
                ],
              ),
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

class _GlitterPainter extends CustomPainter {
  _GlitterPainter(this.t, this.seeds);
  final double t;
  final List<List<double>> seeds;

  @override
  void paint(Canvas canvas, Size size) {
    const List<Color> hues = <Color>[
      GoldTones.shine,
      GoldTones.light,
      GoldTones.mid,
      GoldTones.deep,
    ];
    for (final List<double> s in seeds) {
      final double y = ((s[1] + t * s[2]) % 1.0) * (size.height + 40) - 20;
      final double x =
          s[0] * size.width + math.sin((t + s[3]) * math.pi * 4) * 14;
      final double flick = (math.sin((t * 3 + s[3]) * math.pi * 2) + 1) / 2;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * math.pi * 6 * s[2] + s[3] * 6);
      canvas.scale(0.35 + 0.65 * flick, 1);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: s[4], height: s[4] * 1.6),
        Paint()
          ..color = hues[(s[3] * 4).floor() % 4].withValues(
            alpha: 0.35 + 0.6 * flick,
          ),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_GlitterPainter old) => old.t != t;
}

/// Gold glitter falling and tumbling, over and over.
class GlitterRain extends StatefulWidget {
  const GlitterRain({super.key, this.count = 40});

  final int count;

  @override
  State<GlitterRain> createState() => _GlitterRainState();
}

class _GlitterRainState extends State<GlitterRain>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  )..repeat();
  late final List<List<double>> _seeds = () {
    final math.Random r = math.Random(21);
    return List<List<double>>.generate(
      widget.count,
      (int _) => <double>[
        r.nextDouble(),
        r.nextDouble(),
        0.5 + r.nextDouble() * 1.5,
        r.nextDouble(),
        3 + r.nextDouble() * 4,
      ],
    );
  }();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (BuildContext context, Widget? _) => CustomPaint(
          size: Size.infinite,
          painter: _GlitterPainter(_c.value, _seeds),
        ),
      ),
    );
  }
}

// END OF FILE - lib/widgets/gold_light.dart
