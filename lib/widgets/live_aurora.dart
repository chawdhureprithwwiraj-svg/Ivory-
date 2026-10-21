import 'dart:math' as math;

import 'package:flutter/material.dart';

/// ============================================================
/// IVORY - THE LIVE AURORA
///
/// The slow, colourful light that lives behind the "Every time I have
/// been LIVE" card. It sits on deep emerald and never changes its
/// green: four soft ribbons of light (mint, lime, gold, rose, orchid,
/// tangerine) drift and fold like a northern light; faint broadcast
/// rings widen from the top-right corner, like a signal going out; and
/// a few fireflies float upward and twinkle. Everything is a whole
/// number of turns per loop, so it never jumps. Pure painting, no
/// images, no sound; it never takes a touch.
/// ============================================================
class LiveAurora extends StatefulWidget {
  const LiveAurora({super.key});

  @override
  State<LiveAurora> createState() => _LiveAuroraState();
}

class _LiveAuroraState extends State<LiveAurora>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 22),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (BuildContext context, Widget? _) => CustomPaint(
            painter: _AuroraPainter(_c.value),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _Ribbon {
  const _Ribbon(this.y, this.amp, this.turns, this.phase, this.colors);

  final double y; // share of the height
  final double amp; // share of the height
  final int turns; // whole turns per loop (negative = the other way)
  final double phase;
  final List<Color> colors;
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter(this.t);

  final double t;

  static const List<_Ribbon> _ribbons = <_Ribbon>[
    _Ribbon(0.22, 0.16, 1, 0.00, <Color>[
      Color(0xFF5DF5B8),
      Color(0xFFC6F26B),
      Color(0xFFFFD66B),
    ]),
    _Ribbon(0.46, 0.18, -1, 0.31, <Color>[
      Color(0xFFFF8FA8),
      Color(0xFFFFD66B),
      Color(0xFFB6F27A),
    ]),
    _Ribbon(0.70, 0.15, 2, 0.57, <Color>[
      Color(0xFFE7A6FF),
      Color(0xFF5DF5B8),
      Color(0xFFFF8FA8),
    ]),
    _Ribbon(0.90, 0.12, -2, 0.83, <Color>[
      Color(0xFFFFA45C),
      Color(0xFFFFD66B),
      Color(0xFF5DF5B8),
    ]),
  ];

  static const List<Color> _glow = <Color>[
    Color(0xFFFFE9A8),
    Color(0xFF9BFFD6),
    Color(0xFFFFB3C6),
    Color(0xFFE2FF9B),
    Color(0xFFF1C4FF),
  ];

  static double _h(int n) {
    final double s = math.sin(n * 12.9898 + 78.233) * 43758.5453;
    return s - s.floorToDouble();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    if (w <= 0 || h <= 0) return;
    final Rect all = Offset.zero & size;
    canvas.save();
    canvas.clipRect(all);
    const double tau = math.pi * 2;

    // Ribbons: three strokes of falling width give a soft glow without
    // any costly blur.
    for (final _Ribbon r in _ribbons) {
      final Path p = Path();
      for (double x = -16; x <= w + 16; x += 14) {
        final double u = x / w;
        final double y = h * r.y +
            h * r.amp * math.sin(tau * (u * 1.15 + t * r.turns + r.phase)) +
            h * r.amp * 0.45 * math.sin(tau * (u * 2.3 - t * r.turns.sign + r.phase * 2));
        if (x <= -16) {
          p.moveTo(x, y);
        } else {
          p.lineTo(x, y);
        }
      }
      const List<double> widths = <double>[34, 20, 9];
      const List<double> alphas = <double>[0.10, 0.14, 0.24];
      for (int k = 0; k < 3; k++) {
        canvas.drawPath(
          p,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..strokeWidth = widths[k]
            ..shader = LinearGradient(
              colors: <Color>[
                for (final Color c in r.colors) c.withValues(alpha: alphas[k]),
              ],
            ).createShader(all)
            ..blendMode = BlendMode.plus,
        );
      }
    }

    // Broadcast rings from the top-right corner.
    final Offset src = Offset(w * 0.93, h * 0.16);
    final double reach = math.max(w, h) * 0.78;
    for (int i = 0; i < 3; i++) {
      final double p = (t * 2 + i / 3) % 1.0;
      final double a = math.pow(1 - p, 1.7).toDouble() * 0.30;
      canvas.drawCircle(
        src,
        6 + reach * p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = const Color(0xFFB6FFE0).withValues(alpha: a)
          ..blendMode = BlendMode.plus,
      );
    }

    // Fireflies.
    for (int i = 0; i < 16; i++) {
      final double bx = _h(i + 5);
      final int rise = 1 + i % 2;
      final double yy = ((_h(i + 40) - t * rise) % 1.0 + 1.0) % 1.0;
      final double x = w * bx + 9 * math.sin(tau * (t * (1 + i % 3) + _h(i + 9)));
      final double y = h * yy;
      final double tw = 0.5 + 0.5 * math.sin(tau * (t * (3 + i % 4) + _h(i + 70)));
      final double edge = math.min(yy, 1 - yy) * 5;
      final double a = (tw * math.min(1.0, edge)).clamp(0.0, 1.0).toDouble();
      if (a < 0.05) continue;
      final Color c = _glow[i % _glow.length];
      canvas.drawCircle(
        Offset(x, y),
        4.5 + 2 * tw,
        Paint()
          ..color = c.withValues(alpha: 0.16 * a)
          ..blendMode = BlendMode.plus,
      );
      canvas.drawCircle(
        Offset(x, y),
        1.1 + 0.9 * tw,
        Paint()
          ..color = c.withValues(alpha: 0.85 * a)
          ..blendMode = BlendMode.plus,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AuroraPainter o) => o.t != t;
}

// END OF FILE - lib/widgets/live_aurora.dart
