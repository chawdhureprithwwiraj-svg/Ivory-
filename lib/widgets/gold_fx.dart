import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';
import 'gold_fireworks.dart';

/// ============================================================
/// IVORY - THE GOLD TOOLKIT (shimmer, sheen, sparkle, button)
///
/// Everything that makes The Golden Knock-off glitter lives here
/// and nowhere else, so every screen of the quiz shines the same
/// way. No images, no packages: pure Flutter painting, so it costs
/// the APK nothing. No black anywhere - shadows are burgundy.
/// ============================================================

class GoldTones {
  GoldTones._();

  // Vivid, high-contrast gold: a bright highlight, a saturated body and a
  // deep warm shadow, like polished 24-carat leaf rather than flat paint.
  static const Color shine = Color(0xFFFFF7CF);
  static const Color light = Color(0xFFFFDB4D);
  static const Color mid = Color(0xFFF5B800);
  static const Color deep = Color(0xFFC98600);
  static const Color rim = Color(0xFF8F5B00);

  /// Gold foil for lettering: a bright top, a rich body, a dark horizon
  /// band across the middle (the mark of real polished metal), then a
  /// warm bounce of light underneath.
  static const LinearGradient foil = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      Color(0xFFFFFBE3),
      Color(0xFFFFE15A),
      Color(0xFFFFC21A),
      Color(0xFFB87400),
      Color(0xFFFFD23F),
      Color(0xFFFFF0A8),
      Color(0xFFE9A400),
    ],
    stops: <double>[0, 0.2, 0.42, 0.54, 0.64, 0.84, 1],
  );

  /// Polished gold: bright edge, soft body, a warm shadow, a glint.
  static const LinearGradient metal = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[shine, light, mid, deep, light],
    stops: <double>[0, 0.25, 0.55, 0.82, 1],
  );

  /// Same, laid flat for buttons.
  static const LinearGradient flat = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[shine, light, mid],
    stops: <double>[0, 0.35, 1],
  );
}

class _Slide extends GradientTransform {
  const _Slide(this.t);
  final double t;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * (t * 2 - 1), 0, 0);
}

/// Text that looks like gold leaf with a light gliding across it.
class GoldShimmerText extends StatefulWidget {
  const GoldShimmerText(
    this.text, {
    super.key,
    required this.style,
    this.textAlign = TextAlign.start,
    this.period = const Duration(milliseconds: 3200),
    this.extrude = 0,
  });

  final String text;
  final TextStyle style;
  final TextAlign textAlign;
  final Duration period;

  /// Depth in layers (0 = flat). Gives the letters a solid 3D edge of
  /// deeper gold and a soft golden glow, like cast metal lettering.
  final int extrude;

  @override
  State<GoldShimmerText> createState() => _GoldShimmerTextState();
}

class _GoldShimmerTextState extends State<GoldShimmerText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.period,
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (BuildContext context, Widget? _) {
        final double t = Curves.easeInOut.transform(
          (_c.value / 0.62).clamp(0.0, 1.0).toDouble(),
        );
        Widget leaf(ShaderCallback cb) => ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: cb,
          child: Text(
            widget.text,
            textAlign: widget.textAlign,
            style: widget.style.copyWith(color: Colors.white),
          ),
        );
        final Widget top = Stack(
          children: <Widget>[
            leaf((Rect r) => GoldTones.foil.createShader(r)),
            leaf(
              (Rect r) => LinearGradient(
                colors: <Color>[
                  Colors.white.withValues(alpha: 0),
                  Colors.white.withValues(alpha: 0.95),
                  Colors.white.withValues(alpha: 0),
                ],
                stops: const <double>[0.4, 0.5, 0.6],
                transform: _Slide(t),
              ).createShader(r),
            ),
          ],
        );
        if (widget.extrude <= 0) return top;
        final int n = widget.extrude;
        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Text(
              widget.text,
              textAlign: widget.textAlign,
              style: widget.style.copyWith(
                color: Colors.transparent,
                shadows: <Shadow>[
                  Shadow(
                    color: GoldTones.light.withValues(alpha: 0.6),
                    blurRadius: 20 + 8 * (1 - _c.value),
                    offset: Offset(0, n * 1.2),
                  ),
                ],
              ),
            ),
            for (int i = n; i >= 1; i--)
              Transform.translate(
                offset: Offset(0, i * 0.9),
                child: Text(
                  widget.text,
                  textAlign: widget.textAlign,
                  style: widget.style.copyWith(
                    color: Color.lerp(GoldTones.rim, GoldTones.deep, 1 - i / n),
                  ),
                ),
              ),
            top,
            const Positioned.fill(child: SparkleField(count: 7, seed: 3)),
          ],
        );
      },
    );
  }
}

class _Spark {
  _Spark(math.Random r)
    : x = r.nextDouble(),
      y = r.nextDouble(),
      size = 3 + r.nextDouble() * 6,
      phase = r.nextDouble(),
      speed = 0.6 + r.nextDouble() * 0.9;
  final double x;
  final double y;
  final double size;
  final double phase;
  final double speed;
}

class _SparklePainter extends CustomPainter {
  _SparklePainter(this.sparks, this.t, this.color) : super(repaint: null);
  final List<_Spark> sparks;
  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    for (final _Spark s in sparks) {
      final double a =
          (math.sin((t * s.speed + s.phase) * math.pi * 2) + 1) / 2;
      final double k = a * a * a;
      if (k < 0.03) continue;
      final Offset c = Offset(s.x * size.width, s.y * size.height);
      final double r = s.size * (0.5 + k);
      final Path p = Path();
      for (int i = 0; i < 8; i++) {
        final double ang = -math.pi / 2 + i * math.pi / 4;
        final double rad = i.isEven ? r : r * 0.26;
        final Offset o = c + Offset(math.cos(ang) * rad, math.sin(ang) * rad);
        if (i == 0) {
          p.moveTo(o.dx, o.dy);
        } else {
          p.lineTo(o.dx, o.dy);
        }
      }
      p.close();
      canvas.drawCircle(
        c,
        r * 1.7,
        Paint()
          ..color = color.withValues(alpha: 0.16 * k)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawPath(p, Paint()..color = color.withValues(alpha: 0.95 * k));
    }
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.t != t;
}

/// Twinkling four-point stars. Drop it into any Stack.
class SparkleField extends StatefulWidget {
  const SparkleField({
    super.key,
    this.count = 14,
    this.seed = 7,
    this.color = GoldTones.shine,
  });

  final int count;
  final int seed;
  final Color color;

  @override
  State<SparkleField> createState() => _SparkleFieldState();
}

class _SparkleFieldState extends State<SparkleField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();
  late final List<_Spark> _sparks = () {
    final math.Random r = math.Random(widget.seed);
    return List<_Spark>.generate(widget.count, (int _) => _Spark(r));
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
          painter: _SparklePainter(_sparks, _c.value, widget.color),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _SheenPainter extends CustomPainter {
  _SheenPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final double p = (t / 0.4).clamp(0, 1).toDouble();
    if (p >= 1) return;
    final double w = size.width * 0.55;
    final double x = -w + (size.width + w * 2) * p;
    final Rect band = Rect.fromLTWH(x, -size.height, w, size.height * 3);
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(0.38);
    canvas.translate(-size.width / 2, -size.height / 2);
    canvas.drawRect(
      band,
      Paint()
        ..shader = LinearGradient(
          colors: <Color>[
            GoldTones.shine.withValues(alpha: 0),
            GoldTones.shine.withValues(alpha: 0.22),
            GoldTones.shine.withValues(alpha: 0),
          ],
        ).createShader(band),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SheenPainter old) => old.t != t;
}

/// The Golden Knock-off's panel: deep burgundy, a polished gold rim,
/// a glow, a slow sheen and golden fireworks. Reads the theme palette.
class GoldenFrame extends StatefulWidget {
  const GoldenFrame({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(18, 18, 18, 18),
    this.radius = 26,
    this.sparkles = true,
    this.calm = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final bool sparkles;

  /// A quiet version: no sheen, no stars, thinner rim.
  final bool calm;

  @override
  State<GoldenFrame> createState() => _GoldenFrameState();
}

class _GoldenFrameState extends State<GoldenFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5600),
  );

  @override
  void initState() {
    super.initState();
    if (!widget.calm) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double rim = widget.calm ? 1.2 : 2.2;
    final double inner = widget.radius - rim;
    return Container(
      padding: EdgeInsets.all(rim),
      decoration: BoxDecoration(
        gradient: GoldTones.metal,
        borderRadius: BorderRadius.circular(widget.radius),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: IvoryColors.gold.withValues(
              alpha: widget.calm ? 0.12 : 0.38,
            ),
            blurRadius: widget.calm ? 12 : 28,
            spreadRadius: widget.calm ? 0 : 1,
          ),
          BoxShadow(
            color: IvoryColors.burgundy.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(inner),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const RadialGradient(
                    center: Alignment(0.7, -0.9),
                    radius: 1.5,
                    colors: <Color>[
                      Color(0xFF8A1D33),
                      IvoryColors.plum,
                      IvoryColors.burgundy,
                    ],
                    stops: <double>[0, 0.5, 1],
                  ),
                ),
              ),
            ),
            if (!widget.calm)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _c,
                    builder: (BuildContext context, Widget? _) =>
                        CustomPaint(painter: _SheenPainter(_c.value)),
                  ),
                ),
              ),
            if (widget.sparkles && !widget.calm)
              const Positioned.fill(
                child: GoldFireworks(rate: 0.9, strength: 0.9),
              ),
            Padding(padding: widget.padding, child: widget.child),
          ],
        ),
      ),
    );
  }
}

// END OF FILE - lib/widgets/gold_fx.dart
