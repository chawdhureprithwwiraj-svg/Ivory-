import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';
import 'gold_fx.dart';

/// ============================================================
/// IVORY - GOLD IN MOTION (coin, burst, ring, counting number)
///
/// The moving pieces of The Golden Knock-off. Pure painting, no
/// images, no sound files: a coin that turns, coins that burst
/// when an answer is right, a gold ring that drains with the
/// clock, and a number that counts up to what you won.
/// ============================================================

/// A solid gold coin that turns on its edge: a real thickness made of
/// layered discs, a face on each side, light moving across it.
class GoldCoin extends StatefulWidget {
  const GoldCoin({super.key, this.size = 54});

  final double size;

  @override
  State<GoldCoin> createState() => _GoldCoinState();
}

class _GoldCoinState extends State<GoldCoin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _face(double s, double glint) {
    return Container(
      width: s,
      height: s,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: Alignment(-0.5 + glint * 1.0, -0.5 + glint * 0.4),
          colors: const <Color>[
            GoldTones.shine,
            GoldTones.light,
            GoldTones.mid,
            GoldTones.deep,
          ],
          stops: const <double>[0, 0.3, 0.7, 1],
        ),
        border: Border.all(color: GoldTones.rim, width: s * 0.045),
      ),
      child: Container(
        width: s * 0.72,
        height: s * 0.72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: GoldTones.rim.withValues(alpha: 0.7),
            width: 1.2,
          ),
        ),
        child: Text(
          '\u20B9',
          style: TextStyle(
            fontFamily: IvoryTheme.displayFont,
            fontWeight: FontWeight.w900,
            fontSize: s * 0.42,
            color: IvoryColors.burgundy,
            shadows: <Shadow>[
              Shadow(
                color: GoldTones.shine.withValues(alpha: 0.9),
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double s = widget.size;
    final double d = s * 0.055;
    return SizedBox(
      width: s,
      height: s,
      child: AnimatedBuilder(
        animation: _c,
        builder: (BuildContext context, Widget? _) {
          final double a = _c.value * math.pi * 2;
          final bool frontUp = math.cos(a) >= 0;
          final double glint = (math.sin(a * 2) + 1) / 2;
          final List<Widget> edge = <Widget>[
            for (int k = -4; k <= 4; k++)
              Transform(
                alignment: Alignment.center,
                transform: Matrix4.translationValues(0, 0, d * k / 4),
                child: Container(
                  width: s,
                  height: s,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.lerp(
                      GoldTones.rim,
                      GoldTones.deep,
                      (k + 4) / 8,
                    ),
                  ),
                ),
              ),
          ];
          final Widget front = Transform(
            alignment: Alignment.center,
            transform: Matrix4.translationValues(0, 0, d),
            child: _face(s, glint),
          );
          final Widget back = Transform(
            alignment: Alignment.center,
            transform: Matrix4.translationValues(0, 0, -d)..rotateY(math.pi),
            child: _face(s, 1 - glint),
          );
          return OverflowBox(
            maxWidth: s * 2,
            maxHeight: s * 2,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..rotateX(-0.18)
                ..rotateY(a),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: IvoryColors.gold.withValues(alpha: 0.5),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: SizedBox(
                  width: s,
                  height: s,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: frontUp
                        ? <Widget>[back, ...edge, front]
                        : <Widget>[front, ...edge, back],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Bit {
  _Bit(math.Random r, bool big)
    : angle =
          -math.pi / 2 + (r.nextDouble() - 0.5) * math.pi * (big ? 1.9 : 1.3),
      speed = (big ? 360 : 260) + r.nextDouble() * (big ? 360 : 240),
      size = 5 + r.nextDouble() * (big ? 8 : 6),
      spin = r.nextDouble() * 6,
      late_ = r.nextDouble() * 0.18;
  final double angle;
  final double speed;
  final double size;
  final double spin;
  final double late_;
}

class _BurstPainter extends CustomPainter {
  _BurstPainter(this.bits, this.t, this.origin) : super(repaint: null);
  final List<_Bit> bits;
  final double t;
  final Alignment origin;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset o = Offset(
      size.width * (origin.x + 1) / 2,
      size.height * (origin.y + 1) / 2,
    );
    for (final _Bit b in bits) {
      final double k = ((t - b.late_) / (1 - b.late_))
          .clamp(0.0, 1.0)
          .toDouble();
      if (k <= 0) continue;
      final double secs = k * 1.5;
      final Offset p =
          o +
          Offset(
            math.cos(b.angle) * b.speed * secs,
            math.sin(b.angle) * b.speed * secs + 520 * secs * secs,
          );
      final double fade = k < 0.6 ? 1 : (1 - (k - 0.6) / 0.4);
      final double squash =
          (math.cos(b.spin * k * math.pi * 2)).abs() * 0.8 + 0.2;
      final Rect r = Rect.fromCenter(
        center: p,
        width: b.size * 2 * squash,
        height: b.size * 2,
      );
      canvas.drawOval(
        r,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.3, -0.4),
            colors: <Color>[
              GoldTones.shine.withValues(alpha: fade),
              GoldTones.mid.withValues(alpha: fade),
              GoldTones.deep.withValues(alpha: fade),
            ],
          ).createShader(r),
      );
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.t != t;
}

/// Coins thrown up and falling, once. Give it a new key to throw again.
class CoinBurst extends StatefulWidget {
  const CoinBurst({
    super.key,
    this.big = false,
    this.origin = const Alignment(0, 0.2),
  });

  final bool big;
  final Alignment origin;

  @override
  State<CoinBurst> createState() => _CoinBurstState();
}

class _CoinBurstState extends State<CoinBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.big ? 2200 : 1500),
  )..forward();
  late final List<_Bit> _bits = () {
    final math.Random r = math.Random();
    return List<_Bit>.generate(
      widget.big ? 46 : 22,
      (int _) => _Bit(r, widget.big),
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
          painter: _BurstPainter(_bits, _c.value, widget.origin),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress, this.warn);
  final double progress;
  final bool warn;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.shortestSide * 0.085;
    final Rect rect = Offset.zero & size;
    final Rect arcR = rect.deflate(w / 2 + 2);
    canvas.drawArc(
      arcR,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..color = GoldTones.mid.withValues(alpha: 0.22),
    );
    final double sweep = math.pi * 2 * progress.clamp(0.0, 1.0);
    if (sweep <= 0.001) return;
    final Color hot = warn ? IvoryColors.peach : GoldTones.shine;
    final Shader sh = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: -math.pi / 2 + sweep,
      colors: <Color>[GoldTones.deep, GoldTones.mid, hot],
    ).createShader(arcR);
    canvas.drawArc(
      arcR,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 1.9
        ..strokeCap = StrokeCap.round
        ..shader = sh
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7)
        ..color = Colors.white.withValues(alpha: 0.5),
    );
    canvas.drawArc(
      arcR,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round
        ..shader = sh,
    );
    final double endA = -math.pi / 2 + sweep;
    final Offset tip =
        arcR.center +
        Offset(
          math.cos(endA) * arcR.width / 2,
          math.sin(endA) * arcR.height / 2,
        );
    canvas.drawCircle(tip, w * 0.62, Paint()..color = hot);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.warn != warn;
}

/// A glowing gold ring that drains. [progress] 1 = full, 0 = empty.
class GoldRing extends StatelessWidget {
  const GoldRing({
    super.key,
    required this.progress,
    this.size = 64,
    this.warn = false,
    this.child,
  });

  final double progress;
  final double size;
  final bool warn;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(progress, warn),
        child: Center(child: child),
      ),
    );
  }
}

/// A rupee amount that counts up to its value.
class CountUpText extends StatelessWidget {
  const CountUpText(
    this.value, {
    super.key,
    required this.style,
    this.prefix = '\u20B9',
    this.duration = const Duration(milliseconds: 1400),
  });

  final int value;
  final TextStyle style;
  final String prefix;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double v, Widget? _) =>
          Text('$prefix${v.round()}', style: style),
    );
  }
}

/// "5h 42m", "12 min 05 s", "3 days 4h": for countdowns on the card.
String goldCountdown(Duration d, {bool seconds = false}) {
  if (d.isNegative) return '0m';
  final int days = d.inDays;
  final int h = d.inHours % 24;
  final int m = d.inMinutes % 60;
  final int s = d.inSeconds % 60;
  if (days > 0) return '$days day${days == 1 ? '' : 's'} ${h}h';
  if (d.inHours > 0) {
    return seconds
        ? '${d.inHours}h ${m.toString().padLeft(2, '0')}m ${s.toString().padLeft(2, '0')}s'
        : '${d.inHours}h ${m}m';
  }
  return '${m}m ${s.toString().padLeft(2, '0')}s';
}

// END OF FILE - lib/widgets/gold_burst.dart
