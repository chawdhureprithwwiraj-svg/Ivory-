import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'bell_paint.dart';

/// ============================================================
/// IVORY - RIBBONS OF LIGHT (instead of fireworks)
///
/// When a bell rings, braided ribbons of light flow from it into the
/// Golden Heart. When the day is full, four colours spiral out of the
/// heart in a bloom, a colour wash turns across the card and glowing
/// lanterns rise. All of it is light that adds together (it glows where
/// it overlaps), drawn by one painter on top of the card.
/// ============================================================
class BellsFxController {
  final Stopwatch _clock = Stopwatch()..start();
  final List<_Ribbon> _ribbons = <_Ribbon>[];
  final List<_Bloom> _blooms = <_Bloom>[];
  final List<_Lantern> _lanterns = <_Lantern>[];
  final List<_Wash> _washes = <_Wash>[];
  VoidCallback? _wake;

  double get now => _clock.elapsedMicroseconds / 1e6;

  bool get active =>
      _ribbons.isNotEmpty ||
      _blooms.isNotEmpty ||
      _lanterns.isNotEmpty ||
      _washes.isNotEmpty;

  /// A ribbon from a ringing bell into the heart.
  void ribbon(Offset from, Offset to, Color color) {
    _ribbons.add(_Ribbon(now, from, to, color));
    _wake?.call();
  }

  /// The Full Day: bloom, wash and lanterns around [center].
  void fullDay(Offset center, Size card) {
    _blooms.add(_Bloom(now, center));
    _washes.add(_Wash(now, center));
    final math.Random r = math.Random(now.hashCode);
    for (int i = 0; i < 16; i++) {
      _lanterns.add(
        _Lantern(
          start: now + 0.4 + i * 0.16,
          x: card.width * (0.08 + 0.84 * r.nextDouble()),
          y0: card.height + 20,
          speed: 55 + 45 * r.nextDouble(),
          phase: r.nextDouble() * 6.28,
          radius: 7 + 7 * r.nextDouble(),
          color: BellTones.of(i),
        ),
      );
    }
    _wake?.call();
  }

  void _prune() {
    final double t = now;
    _ribbons.removeWhere((_Ribbon e) => t - e.start > _Ribbon.life);
    _blooms.removeWhere((_Bloom e) => t - e.start > _Bloom.life);
    _washes.removeWhere((_Wash e) => t - e.start > _Wash.life);
    _lanterns.removeWhere((_Lantern e) => t - e.start > e.life);
  }
}

class _Ribbon {
  _Ribbon(this.start, this.from, this.to, this.color);
  static const double life = 1.7;
  final double start;
  final Offset from;
  final Offset to;
  final Color color;
}

class _Bloom {
  _Bloom(this.start, this.center);
  static const double life = 3.4;
  final double start;
  final Offset center;
}

class _Wash {
  _Wash(this.start, this.center);
  static const double life = 3.4;
  final double start;
  final Offset center;
}

class _Lantern {
  _Lantern({
    required this.start,
    required this.x,
    required this.y0,
    required this.speed,
    required this.phase,
    required this.radius,
    required this.color,
  });
  final double start;
  final double x;
  final double y0;
  final double speed;
  final double phase;
  final double radius;
  final Color color;
  double get life => (y0 + 40) / speed;
}

/// The layer that draws the controller's light. Put it over the card
/// inside an IgnorePointer.
class BellsFxLayer extends StatefulWidget {
  const BellsFxLayer({super.key, required this.controller});

  final BellsFxController controller;

  @override
  State<BellsFxLayer> createState() => _BellsFxLayerState();
}

class _BellsFxLayerState extends State<BellsFxLayer>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker((Duration _) {
    widget.controller._prune();
    _frame.value++;
    if (!widget.controller.active) {
      _ticker.stop();
      _frame.value++;
    }
  });
  final ValueNotifier<int> _frame = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    widget.controller._wake = () {
      if (!_ticker.isActive) _ticker.start();
    };
  }

  @override
  void dispose() {
    widget.controller._wake = null;
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _FxPainter(widget.controller, _frame),
        size: Size.infinite,
      ),
    );
  }
}

class _FxPainter extends CustomPainter {
  _FxPainter(this.c, Listenable repaint) : super(repaint: repaint);

  final BellsFxController c;

  static double _ease(double t) => 1 - math.pow(1 - t, 3).toDouble();

  @override
  void paint(Canvas canvas, Size size) {
    final double t = c.now;
    for (final _Wash w in List<_Wash>.of(c._washes)) {
      _wash(canvas, size, w, t);
    }
    for (final _Lantern l in List<_Lantern>.of(c._lanterns)) {
      _lantern(canvas, l, t);
    }
    for (final _Ribbon r in List<_Ribbon>.of(c._ribbons)) {
      _ribbon(canvas, r, t);
    }
    for (final _Bloom b in List<_Bloom>.of(c._blooms)) {
      _bloom(canvas, b, t);
    }
  }

  void _glowDot(Canvas canvas, Offset p, double r, Color col, double a) {
    if (a <= 0) return;
    canvas.drawCircle(
      p,
      r * 3.2,
      Paint()
        ..blendMode = BlendMode.plus
        ..color = col.withValues(alpha: 0.22 * a),
    );
    canvas.drawCircle(
      p,
      r,
      Paint()
        ..blendMode = BlendMode.plus
        ..color = Color.lerp(col, Colors.white, 0.6)!.withValues(alpha: a),
    );
  }

  void _ribbon(Canvas canvas, _Ribbon r, double t) {
    final double p = ((t - r.start) / (_Ribbon.life - 0.3)).clamp(0.0, 1.0);
    final double head = _ease(p);
    final Offset mid = Offset.lerp(r.from, r.to, 0.5)!;
    final Offset d = r.to - r.from;
    final double len = math.max(1, d.distance);
    final Offset n = Offset(-d.dy / len, d.dx / len);
    final double side = r.from.dx < r.to.dx ? 1 : -1;
    final Offset ctrl = mid + n * (len * 0.28 * side);
    for (int s = 0; s < 5; s++) {
      final double ph = s * 1.25;
      final double amp = 7 + s * 1.5;
      Offset? prev;
      for (int i = 0; i <= 22; i++) {
        final double u = head - 0.4 + 0.4 * i / 22;
        if (u < 0 || u > 1) {
          prev = null;
          continue;
        }
        final double a = 1 - u;
        final Offset b =
            r.from * (a * a) + ctrl * (2 * a * u) + r.to * (u * u);
        final double w =
            math.sin(u * 6 * math.pi + ph + (t - r.start) * 9) *
            amp *
            math.sin(math.pi * u);
        final Offset pt = b + n * w;
        final double age = i / 22;
        if (prev != null) {
          canvas.drawLine(
            prev,
            pt,
            Paint()
              ..blendMode = BlendMode.plus
              ..strokeCap = StrokeCap.round
              ..strokeWidth = 1.2 + 2.2 * age
              ..color = Color.lerp(
                r.color,
                Colors.white,
                s.isEven ? 0.15 : 0.55,
              )!.withValues(alpha: age * 0.95),
          );
        }
        prev = pt;
        if (i == 22) _glowDot(canvas, pt, 2.4, r.color, 0.9);
      }
    }
    if (p >= 1) {
      final double k = ((t - r.start) - (_Ribbon.life - 0.3)) / 0.3;
      _glowDot(canvas, r.to, 10 * (1 - k.clamp(0, 1)), r.color, 1 - k);
    }
  }

  void _bloom(Canvas canvas, _Bloom b, double t) {
    final double p = ((t - b.start) / _Bloom.life).clamp(0.0, 1.0);
    for (int k = 0; k < 4; k++) {
      final Color col = BellTones.of(k);
      final double base = k * math.pi / 2;
      for (int j = 0; j < 26; j++) {
        final double tj = p - j * 0.011;
        if (tj <= 0) continue;
        final double ang = base + tj * 4.2 * math.pi;
        final double rad = 14 + tj * 190;
        final Offset pt = b.center + Offset(math.cos(ang), math.sin(ang)) * rad;
        final double fade = (1 - tj) * (1 - j / 26);
        _glowDot(canvas, pt, 3.6 * (1 - j / 34), col, fade.clamp(0.0, 1.0));
      }
    }
  }

  void _wash(Canvas canvas, Size size, _Wash w, double t) {
    final double p = ((t - w.start) / _Wash.life).clamp(0.0, 1.0);
    final double a = math.pow(math.sin(math.pi * p), 1.3).toDouble() * 0.55;
    if (a <= 0) return;
    final Rect r = Offset.zero & size;
    canvas.save();
    canvas.clipRect(r);
    final List<Color> cs = <Color>[
      BellTones.dawn,
      BellTones.dusk,
      BellTones.noon,
      BellTones.night,
      BellTones.amethyst,
      BellTones.dawn,
    ];
    canvas.drawRect(
      r,
      Paint()
        ..blendMode = BlendMode.screen
        ..shader = SweepGradient(
          center: Alignment(
            (w.center.dx / size.width) * 2 - 1,
            (w.center.dy / size.height) * 2 - 1,
          ),
          transform: GradientRotation(p * math.pi * 1.1),
          colors: cs.map((Color c) => c.withValues(alpha: a)).toList(),
        ).createShader(r),
    );
    canvas.restore();
  }

  void _lantern(Canvas canvas, _Lantern l, double t) {
    final double age = t - l.start;
    if (age < 0) return;
    final double y = l.y0 - age * l.speed;
    final double x = l.x + math.sin(l.phase + age * 1.4) * 14;
    final double life = l.life;
    final double a = math.min(1.0, age / 0.8) * math.min(1.0, (life - age) / 1.2);
    if (a <= 0) return;
    final Offset p = Offset(x, y);
    _glowDot(canvas, p, l.radius * 0.55, l.color, a.clamp(0.0, 1.0));
    canvas.drawCircle(
      p,
      l.radius * 0.28,
      Paint()
        ..blendMode = BlendMode.plus
        ..color = const Color(0xFFFFF4C2).withValues(alpha: a.clamp(0.0, 1.0)),
    );
  }

  @override
  bool shouldRepaint(_FxPainter o) => false;
}

// END OF FILE - lib/widgets/bells_fx.dart
