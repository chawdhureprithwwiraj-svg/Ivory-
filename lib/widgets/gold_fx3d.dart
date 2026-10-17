import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';
import 'gold_fx.dart';

/// ============================================================
/// IVORY - GOLD IN THREE DIMENSIONS
///
/// Depth for The Golden Knock-off: a panel that sways in space and
/// leans toward a finger with a glint sliding across it, rays of
/// light turning slowly behind a coin, a shake, a pulsing dot, and a
/// gentle rise-in for lists. (Bursts of light: gold_light.dart.)
/// ============================================================

/// A panel in perspective. Idle, it sways a few degrees. Touched, it
/// leans toward the finger (without stealing the scroll) and a glint
/// follows. Let go and it settles back.
class GoldTilt extends StatefulWidget {
  const GoldTilt({
    super.key,
    required this.child,
    this.radius = 26,
    this.lean = 0.16,
    this.sway = 1,
  });

  final Widget child;
  final double radius;
  final double lean;

  /// How much it drifts when untouched (1 = full, 0 = still).
  final double sway;

  @override
  State<GoldTilt> createState() => _GoldTiltState();
}

class _GoldTiltState extends State<GoldTilt> with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  )..repeat();
  late final AnimationController _back = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
    value: 0,
  );
  Offset _p = Offset.zero;
  bool _touch = false;

  @override
  void dispose() {
    _idle.dispose();
    _back.dispose();
    super.dispose();
  }

  void _move(PointerEvent e) {
    final Size? s = context.size;
    if (s == null || s.isEmpty) return;
    _touch = true;
    _back.value = 1;
    setState(
      () => _p = Offset(
        ((e.localPosition.dx / s.width) * 2 - 1).clamp(-1.0, 1.0).toDouble(),
        ((e.localPosition.dy / s.height) * 2 - 1).clamp(-1.0, 1.0).toDouble(),
      ),
    );
  }

  void _up(PointerEvent e) {
    _touch = false;
    _back.animateTo(0, curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _move,
      onPointerMove: _move,
      onPointerUp: _up,
      onPointerCancel: _up,
      child: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[_idle, _back]),
        builder: (BuildContext context, Widget? child) {
          final double a = _idle.value * math.pi * 2;
          final double k = _touch ? 1 : _back.value;
          final double ry =
              math.sin(a) * 0.04 * widget.sway * (1 - k) +
              _p.dx * widget.lean * k;
          final double rx =
              math.cos(a) * 0.028 * widget.sway * (1 - k) -
              _p.dy * widget.lean * k;
          final Alignment glint = Alignment(
            (math.sin(a) * 0.9) * (1 - k) + _p.dx * k,
            (math.cos(a * 0.7) * 0.6) * (1 - k) + _p.dy * k,
          );
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0011)
              ..rotateX(rx)
              ..rotateY(ry),
            child: Stack(
              children: <Widget>[
                child!,
                Positioned.fill(
                  child: IgnorePointer(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(widget.radius),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: glint,
                            radius: 0.75,
                            colors: <Color>[
                              GoldTones.shine.withValues(alpha: 0.2),
                              GoldTones.shine.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}

class _RaysPainter extends CustomPainter {
  _RaysPainter(this.turn, this.color);
  final double turn;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);
    final double r = size.shortestSide / 2;
    const int n = 14;
    final Shader sh = RadialGradient(
      colors: <Color>[
        color.withValues(alpha: 0.55),
        color.withValues(alpha: 0),
      ],
    ).createShader(Rect.fromCircle(center: c, radius: r));
    final Paint p = Paint()..shader = sh;
    for (int i = 0; i < n; i++) {
      final double a0 = turn * math.pi * 2 + i * math.pi * 2 / n;
      final double a1 = a0 + math.pi / n * 0.8;
      final Path w = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + math.cos(a0) * r, c.dy + math.sin(a0) * r)
        ..lineTo(c.dx + math.cos(a1) * r, c.dy + math.sin(a1) * r)
        ..close();
      canvas.drawPath(w, p);
    }
  }

  @override
  bool shouldRepaint(_RaysPainter old) => old.turn != turn;
}

/// Rays of light turning slowly, like light from a jewel.
class GoldRays extends StatefulWidget {
  const GoldRays({
    super.key,
    this.size = 220,
    this.opacity = 0.2,
    this.color = GoldTones.light,
  });

  final double size;
  final double opacity;
  final Color color;

  @override
  State<GoldRays> createState() => _GoldRaysState();
}

class _GoldRaysState extends State<GoldRays>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 46),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: widget.opacity,
        child: AnimatedBuilder(
          animation: _c,
          builder: (BuildContext context, Widget? _) => CustomPaint(
            size: Size.square(widget.size),
            painter: _RaysPainter(_c.value, widget.color),
          ),
        ),
      ),
    );
  }
}

/// Shakes its child sideways each time [trigger] changes (a wrong answer).
class GoldShake extends StatefulWidget {
  const GoldShake({super.key, required this.trigger, required this.child});

  final int trigger;
  final Widget child;

  @override
  State<GoldShake> createState() => _GoldShakeState();
}

class _GoldShakeState extends State<GoldShake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  @override
  void didUpdateWidget(GoldShake old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (BuildContext context, Widget? child) => Transform.translate(
        offset: Offset(
          math.sin(_c.value * math.pi * 7) * 11 * (1 - _c.value),
          0,
        ),
        child: child,
      ),
    );
  }
}

/// A small pulsing dot with a halo: "this is live".
class GoldPulseDot extends StatefulWidget {
  const GoldPulseDot({super.key, this.size = 9});

  final double size;

  @override
  State<GoldPulseDot> createState() => _GoldPulseDotState();
}

class _GoldPulseDotState extends State<GoldPulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double s = widget.size;
    return SizedBox(
      width: s * 3,
      height: s * 3,
      child: AnimatedBuilder(
        animation: _c,
        builder: (BuildContext context, Widget? _) => Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Container(
              width: s * (1 + 2 * _c.value),
              height: s * (1 + 2 * _c.value),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: GoldTones.mid.withValues(alpha: 0.5 * (1 - _c.value)),
              ),
            ),
            Container(
              width: s,
              height: s,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: GoldTones.shine,
                boxShadow: <BoxShadow>[
                  BoxShadow(color: IvoryColors.gold, blurRadius: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fades and lifts its child into place after [delayMs]. For lists.
class GoldRise extends StatelessWidget {
  const GoldRise({super.key, required this.child, this.delayMs = 0});

  final Widget child;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 650 + delayMs),
      curve: Interval(delayMs / (650 + delayMs), 1, curve: Curves.easeOutCubic),
      builder: (BuildContext context, double v, Widget? c) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 26 * (1 - v)), child: c),
      ),
      child: child,
    );
  }
}

// END OF FILE - lib/widgets/gold_fx3d.dart
