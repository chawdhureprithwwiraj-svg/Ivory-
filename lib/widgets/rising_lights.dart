import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'light_shapes.dart';

/// ============================================================
/// IVORY - THE TEN-DAY VAULT: THE RISING LIGHTS
///
/// Replaces the firecracker in the Ten-Day Vault (the Golden
/// Knock-off keeps its own). Everything climbs from the bottom to
/// the top, in full colour and never in blue:
///
///  * Sky lanterns: paper lanterns in ruby, emerald, amber,
///    magenta, coral and lime. Each is shaded like a real round
///    lantern (dark at the edges, glowing in the middle), with
///    ribs, brass caps, a flickering flame, a tassel and a halo.
///  * Jewels: cut gems (ruby, emerald, citrine, rose, peridot,
///    fire opal) that turn as they climb, show their facets, and
///    flash.
///  * Embers: bright coloured sparks drifting upward.
///  * Every nine seconds a SURGE: a row of jewel-headed comets
///    shoots up from the bottom.
///
/// Near things are bigger, brighter and faster; far things are
/// smaller and softer, so the sky has depth. Everything is
/// worked out from the clock: no stored state, no images, no
/// sound. [RisingLights] is the lights on a clear background; the
/// sunrise they climb through is in vault_sky.dart.
/// ============================================================


const List<Color> _lanternColors = <Color>[
  Color(0xFFE6203F),
  Color(0xFF16A864),
  Color(0xFFFFA000),
  Color(0xFFE0268F),
  Color(0xFFFF6A3D),
  Color(0xFF9BCB1B),
  Color(0xFFFF8A00),
  Color(0xFFFF4D8D),
];

const List<Color> _gemColors = <Color>[
  Color(0xFFE0143C),
  Color(0xFF12B76A),
  Color(0xFFFFC21A),
  Color(0xFFFF5CA8),
  Color(0xFFA5D414),
  Color(0xFFFF7A1A),
];

const List<Color> _emberColors = <Color>[
  Color(0xFFFFE27A),
  Color(0xFFFFB347),
  Color(0xFFFF7AA2),
  Color(0xFFFFFFFF),
  Color(0xFFB6E84A),
  Color(0xFFFF8A5C),
];


class _Item {
  const _Item({
    required this.lantern,
    required this.x,
    required this.size,
    required this.period,
    required this.phase,
    required this.z,
    required this.sway,
    required this.swayRate,
    required this.spinRate,
    required this.color,
  });

  final bool lantern;
  final double x;
  final double size;
  final double period;
  final double phase;
  final double z;
  final double sway;
  final double swayRate;
  final double spinRate;
  final Color color;
}

/// Just the rising lights, on a clear background.
class RisingLights extends StatefulWidget {
  const RisingLights({
    super.key,
    this.scale = 1,
    this.lanterns = 9,
    this.gems = 12,
    this.embers = 40,
    this.surge = true,
    this.onDark = false,
    this.seed = 7,
  });

  /// Size of everything, relative (1 = full size).
  final double scale;
  final int lanterns;
  final int gems;
  final int embers;

  /// Whether a row of comets shoots up every nine seconds.
  final bool surge;

  /// On a dark background the lights are added to it (glowing); on a
  /// light one they are painted normally.
  final bool onDark;
  final int seed;

  @override
  State<RisingLights> createState() => _RisingLightsState();
}

class _RisingLightsState extends State<RisingLights>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 100000),
  )..repeat();

  late final List<_Item> _items = _make();

  List<_Item> _make() {
    final math.Random r = math.Random(widget.seed);
    final List<_Item> out = <_Item>[];
    for (int i = 0; i < widget.lanterns; i++) {
      out.add(
        _Item(
          lantern: true,
          x: 0.06 + 0.88 * ((i + 0.2 + 0.6 * r.nextDouble()) / widget.lanterns),
          size: 34 + 18 * r.nextDouble(),
          period: 20 + 12 * r.nextDouble(),
          phase: r.nextDouble(),
          z: r.nextDouble(),
          sway: 0.012 + 0.02 * r.nextDouble(),
          swayRate: 0.5 + 0.7 * r.nextDouble(),
          spinRate: 0,
          color: _lanternColors[(i + r.nextInt(3)) % _lanternColors.length],
        ),
      );
    }
    for (int i = 0; i < widget.gems; i++) {
      out.add(
        _Item(
          lantern: false,
          x: 0.05 + 0.9 * ((i + 0.2 + 0.6 * r.nextDouble()) / widget.gems),
          size: 11 + 8 * r.nextDouble(),
          period: 11 + 8 * r.nextDouble(),
          phase: r.nextDouble(),
          z: r.nextDouble(),
          sway: 0.01 + 0.025 * r.nextDouble(),
          swayRate: 0.8 + 1.2 * r.nextDouble(),
          spinRate: 1.2 + 2.2 * r.nextDouble(),
          color: _gemColors[(i + r.nextInt(2)) % _gemColors.length],
        ),
      );
    }
    out.sort((_Item a, _Item b) => a.z.compareTo(b.z));
    return out;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _LightsPainter(
            clock: _c,
            items: _items,
            scale: widget.scale,
            embers: widget.embers,
            surge: widget.surge,
            onDark: widget.onDark,
          ),
        ),
      ),
    );
  }
}

class _LightsPainter extends CustomPainter {
  _LightsPainter({
    required this.clock,
    required this.items,
    required this.scale,
    required this.embers,
    required this.surge,
    required this.onDark,
  }) : super(repaint: clock);

  final Animation<double> clock;
  final List<_Item> items;
  final double scale;
  final int embers;
  final bool surge;
  final bool onDark;

  static double _h(int n) {
    final double s = math.sin(n * 12.9898 + 78.233) * 43758.5453;
    return s - s.floorToDouble();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double t = clock.value * 100000;
    final double w = size.width;
    final double h = size.height;
    if (w <= 0 || h <= 0) return;
    final double k = (w / 360).clamp(0.8, 1.3).toDouble() * scale;

    _embers(canvas, w, h, t, k);

    for (final _Item it in items) {
      final double sp = 0.75 + 0.55 * it.z;
      final double u = (t / it.period * sp + it.phase) % 1.0;
      final double s = it.size * k * (0.58 + 0.72 * it.z);
      final double y = h + s * 1.6 - u * (h + s * 3.4);
      final double x =
          w * it.x +
          math.sin(t * it.swayRate + it.phase * 6.2832) * it.sway * w;
      final double fade = math
          .min(u / 0.07, (1 - u) / 0.1)
          .clamp(0.0, 1.0)
          .toDouble();
      final double a = fade * (0.62 + 0.38 * it.z);
      if (a <= 0.01) continue;
      final Rect box = Rect.fromCenter(
        center: Offset(x, y),
        width: s * 4,
        height: s * 4,
      );
      canvas.saveLayer(
        box,
        Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: a),
      );
      if (it.lantern) {
        paintLantern(canvas, x, y, s, it.color, it.phase, t, onDark);
      } else {
        paintGem(canvas, x, y, s, it.color, it.phase, it.spinRate, t, onDark);
      }
      canvas.restore();
    }

    if (surge) _surge(canvas, w, h, t, k);
  }

  void _embers(Canvas canvas, double w, double h, double t, double k) {
    final Paint p = Paint();
    final Paint line = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.0;
    for (int i = 0; i < embers; i++) {
      final double per = 7 + 9 * _h(i + 1);
      final double u = (t / per + _h(i + 2)) % 1.0;
      final double x =
          w * _h(i + 3) + math.sin(t * (0.6 + _h(i + 4)) + i) * 10 * k;
      final double y = h * (1.04 - 1.1 * u);
      final double tw = 0.55 + 0.45 * math.sin(t * (3 + 4 * _h(i + 5)) + i);
      final double fade = math
          .min(u / 0.1, (1 - u) / 0.2)
          .clamp(0.0, 1.0)
          .toDouble();
      final Color c = _emberColors[i % _emberColors.length];
      final double r = (0.9 + 1.5 * _h(i + 6)) * k;
      final double al = (fade * tw).clamp(0.0, 1.0).toDouble();
      p.color = c.withValues(alpha: 0.85 * al);
      if (onDark) p.blendMode = BlendMode.plus;
      canvas.drawCircle(Offset(x, y), r, p);
      p.blendMode = BlendMode.srcOver;
      if (tw > 0.85 && fade > 0.4) {
        final double len = 3.5 * k * tw;
        line.color = (onDark ? c : deepShade(c, 0.2)).withValues(alpha: 0.8 * al);
        canvas.drawLine(Offset(x - len, y), Offset(x + len, y), line);
        canvas.drawLine(Offset(x, y - len), Offset(x, y + len), line);
      }
    }
  }

  /// A row of jewel-headed comets that shoots up from the bottom.
  void _surge(Canvas canvas, double w, double h, double t, double k) {
    const double cycle = 9;
    const double span = 2.8;
    final double tin = t % cycle;
    if (tin > span + 0.6) return;
    const int n = 14;
    final int cyc = (t / cycle).floor();
    final Paint tail = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < n; i++) {
      final double delay = 0.05 * ((i * 7) % n) / n * 3;
      final double p = ((tin - delay) / span).clamp(0.0, 1.0).toDouble();
      if (p <= 0 || p >= 1) continue;
      final double e = 1 - math.pow(1 - p, 2.2).toDouble();
      final double x =
          w * (i + 0.5 + 0.35 * (_h(i + cyc * 31) - 0.5)) / n +
          math.sin(p * 6 + i) * 6 * k;
      final double y = h * 1.04 - e * h * 1.1;
      final Color c = _gemColors[(i + cyc) % _gemColors.length];
      final double fade = (1 - p).clamp(0.0, 1.0).toDouble();
      final double len = (50 + 50 * _h(i + 9)) * k * (1 - p * 0.5);
      tail
        ..strokeWidth = 3.0 * k * fade + 0.8
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: <Color>[c.withValues(alpha: 0), c.withValues(alpha: 0.9 * fade)],
        ).createShader(Rect.fromLTWH(x - 2, y, 4, len));
      canvas.drawLine(Offset(x, y + len), Offset(x, y), tail);
      tail.shader = null;
      // The jewel at the head of the comet.
      final double r = 5.5 * k * (0.7 + 0.5 * fade);
      canvas.drawCircle(
        Offset(x, y),
        r * 1.9,
        Paint()
          ..shader = RadialGradient(
            colors: <Color>[
              lightShade(c, 0.3).withValues(alpha: 0.6 * fade),
              c.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: Offset(x, y), radius: r * 1.9))
          ..blendMode = onDark ? BlendMode.plus : BlendMode.srcOver,
      );
      final Path dia = Path()
        ..moveTo(x, y - r)
        ..lineTo(x + r * 0.75, y)
        ..lineTo(x, y + r * 1.15)
        ..lineTo(x - r * 0.75, y)
        ..close();
      canvas.drawPath(dia, Paint()..color = lightShade(c, 0.1));
      canvas.drawPath(
        Path()
          ..moveTo(x, y - r)
          ..lineTo(x + r * 0.75, y)
          ..lineTo(x, y)
          ..close(),
        Paint()..color = lightShade(c, 0.6),
      );
      canvas.drawPath(
        dia,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.7 * fade),
      );
    }
  }

  @override
  bool shouldRepaint(_LightsPainter old) => false;
}

// END OF FILE - lib/widgets/rising_lights.dart
