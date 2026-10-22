import 'dart:math' as math;

import 'package:flutter/material.dart';

/// ============================================================
/// IVORY - THE GOLDEN GATE (the first impression)
///
/// The native splash (cream, in android/) covers the engine waking.
/// The moment Flutter can draw, THIS plays once per app open: a sweep
/// of rich gold crosses the cream from left to right - brushed metal,
/// damask, twinkling grains, a bright specular edge - until the whole
/// screen is glittering gold with the heart and the wordmark upon it.
/// It holds a breath, sparkles once, then fades into the home screen.
/// A tap anywhere skips straight to the house.
///
/// Only cream and golds ever touch the screen. No dark, no black.
/// ============================================================
class GoldenGate extends StatefulWidget {
  const GoldenGate({super.key});

  static bool _played = false;

  @override
  State<GoldenGate> createState() => _GoldenGateState();
}

class _GoldenGateState extends State<GoldenGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  );
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );
  bool _gone = GoldenGate._played;

  static const Color _cream = Color(0xFFFAF5E9);
  static const Color _gold = Color(0xFFC9962C);
  static const Color _pale = Color(0xFFFFF3CF);

  @override
  void initState() {
    super.initState();
    if (_gone) return;
    _sweep.forward().then((_) => _burst.forward()).then((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 150));
      await _fade.forward();
      if (mounted) setState(() => _gone = true);
      GoldenGate._played = true;
    });
  }

  @override
  void dispose() {
    _sweep.dispose();
    _burst.dispose();
    _fade.dispose();
    super.dispose();
  }

  void _skip() {
    GoldenGate._played = true;
    if (mounted) setState(() => _gone = true);
  }

  double _mix(double sweep) {
    final double x = (sweep - 0.42) / 0.16;
    return x < 0 ? 0 : (x > 1 ? 1 : x);
  }

  @override
  Widget build(BuildContext context) {
    if (_gone) return const SizedBox.shrink();
    return GestureDetector(
      onTap: _skip,
      child: Opacity(
        opacity: 1 - _fade.value,
        child: AnimatedBuilder(
          animation: Listenable.merge(<Listenable>[_sweep, _burst]),
          builder: (BuildContext context, Widget? child) {
            final double m = _mix(_sweep.value);
            return CustomPaint(
              painter: _GatePainter(_sweep.value, _burst.value),
              child: SafeArea(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const SizedBox(height: 118),
                      Text(
                        'IVORY',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 10,
                          color: Color.lerp(_gold, _pale, m)!,
                          shadows: const <Shadow>[
                            Shadow(color: Color(0x33FFFFFF), blurRadius: 8),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Where every story leaves a mark',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 1.2,
                          color: Color.lerp(
                              const Color(0xFF7A4A12), _pale, m)!,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

double _seed(int i) {
  final double x = math.sin(i * 127.1) * 43758.5453;
  return x - x.floor();
}

class _GatePainter extends CustomPainter {
  const _GatePainter(this.sweep, this.burst);

  final double sweep;
  final double burst;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Rect r = Offset.zero & size;
    final double t = sweep * sweep * (3 - 2 * sweep); // smooth step
    final double bx = -140 + t * (w + 280); // the gold edge
    // Cream, always underneath.
    canvas.drawRect(r, Paint()..color = const Color(0xFFFAF5E9));
    // The gold that has already crossed.
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 0, bx, h));
    canvas.drawRect(
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFFF6DE9C), Color(0xFFE2B34C), Color(0xFFC9962C)],
          stops: <double>[0, 0.55, 1],
        ).createShader(r),
    );
    // Brushed hairlines.
    final Paint hair = Paint()
      ..strokeWidth = 1
      ..color = const Color(0x14FFFFFF);
    for (double y = 0; y < h; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(w, y), hair);
    }
    // Damask dots.
    final Paint dot = Paint()..color = const Color(0x14FFF6D6);
    for (double x = 6; x < w; x += 26) {
      for (double y = 8; y < h; y += 26) {
        canvas.drawCircle(Offset(x, y), 1.3, dot);
      }
    }
    // A sheen resting on top.
    canvas.drawRect(
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.6, -1.3),
          radius: 1.0,
          colors: <Color>[Color(0x55FFFFFF), Color(0x00FFFFFF)],
        ).createShader(r),
    );
    // Grains; they flare while the burst plays.
    final double flare = math.sin(burst * math.pi);
    for (int i = 0; i < 26; i++) {
      final double tw =
          0.5 + 0.5 * math.sin(2 * math.pi * (burst * 1.3 + _seed(i + 7)));
      final double a = 0.10 * tw + 0.30 * flare * tw;
      canvas.drawCircle(
        Offset(_seed(i) * w, _seed(i + 31) * h),
        0.7 + _seed(i + 13) * 1.1,
        Paint()..color = Color.fromRGBO(255, 255, 255, a),
      );
    }
    canvas.restore();
    // One soft turning shine during the burst.
    if (burst > 0 && burst < 1) {
      final double a = 0.10 * math.sin(burst * math.pi);
      canvas.drawRect(
        r,
        Paint()
          ..shader = SweepGradient(
            startAngle: burst * 2 * math.pi,
            endAngle: burst * 2 * math.pi + 2 * math.pi,
            colors: <Color>[
              Color.fromRGBO(255, 255, 255, a),
              const Color(0x00FFFFFF),
              Color.fromRGBO(255, 255, 255, a * 0.6),
              const Color(0x00FFFFFF),
            ],
            stops: const <double>[0, 0.25, 0.5, 0.75],
          ).createShader(r),
      );
    }
    // The feathered, shining edge of the sweep.
    final Rect band = Rect.fromLTWH(bx - 90, 0, 120, h);
    canvas.drawRect(
      band,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[
            const Color(0x00FAF5E9),
            const Color(0xAAFAF5E9),
            const Color(0x00FAF5E9),
          ],
        ).createShader(band),
    );
    final Rect line = Rect.fromLTWH(bx - 1.5, 0, 3, h);
    canvas.drawRect(line, Paint()..color = const Color(0xD9FFFBE8));
    final Rect glow = Rect.fromLTWH(bx - 14, 0, 28, h);
    canvas.drawRect(
      glow,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[
            const Color(0x00FFFBE8),
            const Color(0x66FFFBE8),
            const Color(0x00FFFBE8),
          ],
        ).createShader(glow),
    );
    // The heart of the house, centred; it turns pale as the gold arrives.
    final double cx = w / 2;
    final double cy = h / 2 - 60;
    final double m = _mixAt(bx, cx);
    final double s = 3.4;
    final Path heart = Path()
      ..moveTo(cx, cy + 10 * s / 2.6)
      ..cubicTo(cx - 3.4 * s / 2.6, cy + 7.1 * s / 2.6, cx - 5.6 * s / 2.6,
          cy + 4.7 * s / 2.6, cx - 5.6 * s / 2.6, cy + 2.3 * s / 2.6)
      ..cubicTo(cx - 5.6 * s / 2.6, cy + 0.5 * s / 2.6, cx - 4.3 * s / 2.6,
          cy - 0.6 * s / 2.6, cx - 2.7 * s / 2.6, cy - 0.6 * s / 2.6)
      ..cubicTo(cx - 1.6 * s / 2.6, cy - 0.6 * s / 2.6, cx - 0.6 * s / 2.6,
          cy - 0.1 * s / 2.6, cx, cy + 0.8 * s / 2.6)
      ..cubicTo(cx + 0.6 * s / 2.6, cy - 0.1 * s / 2.6, cx + 1.6 * s / 2.6,
          cy - 0.6 * s / 2.6, cx + 2.7 * s / 2.6, cy - 0.6 * s / 2.6)
      ..cubicTo(cx + 4.3 * s / 2.6, cy - 0.6 * s / 2.6, cx + 5.6 * s / 2.6,
          cy + 0.5 * s / 2.6, cx + 5.6 * s / 2.6, cy + 2.3 * s / 2.6)
      ..cubicTo(cx + 5.6 * s / 2.6, cy + 4.7 * s / 2.6, cx + 3.4 * s / 2.6,
          cy + 7.1 * s / 2.6, cx, cy + 10 * s / 2.6)
      ..close();
    canvas.drawPath(
      heart,
      Paint()
        ..color = Color.lerp(const Color(0xFFC9962C), const Color(0xFFFFF3CF), m)!,
    );
    canvas.drawPath(
      heart,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Color.lerp(const Color(0xFFE8C86A), const Color(0xFFC9962C), m)!,
    );
  }

  double _mixAt(double bx, double cx) {
    final double x = (bx - cx) / 120 + 0.5;
    return x < 0 ? 0 : (x > 1 ? 1 : x);
  }

  @override
  bool shouldRepaint(_GatePainter old) =>
      old.sweep != sweep || old.burst != burst;
}

// END OF FILE - lib/widgets/golden_gate.dart
