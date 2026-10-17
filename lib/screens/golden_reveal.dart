import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../widgets/gold_burst.dart';
import '../widgets/gold_fx.dart';
import '../widgets/gold_fx3d.dart';
import '../widgets/gold_light.dart';
import '../widgets/gold_seals.dart';
import '../widgets/gold_sound.dart';
import 'golden_quiz_parts.dart';

/// ============================================================
/// IVORY - THE UNSEALING
///
/// Ten seals circle a coin in space, light racing from seal to
/// seal, each one ringing a higher note. They slow, draw into the
/// coin, the room flashes, a ring of light races out, and the
/// member's secret topic rises in cast gold. About five seconds.
/// ============================================================
class GoldenReveal extends StatefulWidget {
  const GoldenReveal({
    super.key,
    required this.topic,
    required this.tagline,
    required this.onDone,
  });

  final String topic;
  final String tagline;
  final VoidCallback onDone;

  @override
  State<GoldenReveal> createState() => _GoldenRevealState();
}

class _GoldenRevealState extends State<GoldenReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4800),
  )..forward();
  int _step = -1;
  bool _boom = false;

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((AnimationStatus st) {
      if (st == AnimationStatus.completed && mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _sounds(double head, bool shown) {
    final int step = head.floor();
    if (!shown && step != _step) {
      _step = step;
      GoldSound.instance.quick('seal${(step * 10 / 25).floor().clamp(0, 9)}');
    }
    if (shown && !_boom) {
      _boom = true;
      GoldSound.instance.big('reveal');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (BuildContext context, Widget? _) {
        final double t = _c.value;
        final double chase = Curves.easeOutCubic.transform(
          (t / 0.52).clamp(0.0, 1.0).toDouble(),
        );
        final double head = chase * 25;
        final bool shown = t > 0.6;
        final double pull = Curves.easeInCubic.transform(
          ((t - 0.5) / 0.1).clamp(0.0, 1.0).toDouble(),
        );
        final double rise = Curves.easeOutBack.transform(
          ((t - 0.62) / 0.22).clamp(0.0, 1.0).toDouble(),
        );
        _sounds(head, shown);
        const double w = 320;
        const double h = 230;
        final List<Widget> back = <Widget>[];
        final List<Widget> front = <Widget>[];
        for (int i = 0; i < 10; i++) {
          final double a = math.pi / 2 + (i - head) * math.pi / 5;
          final double depth = (math.sin(a) + 1) / 2;
          double near = ((i - head) % 10).abs();
          if (near > 5) near = 10 - near;
          final double glow = shown
              ? 0
              : (1 - near / 2).clamp(0.0, 1.0).toDouble();
          final double r = 1 - pull;
          final double scale = (0.55 + 0.6 * depth) * (0.4 + 0.6 * r);
          final double sz = 40 * scale;
          final Widget seal = Positioned(
            left: w / 2 + math.cos(a) * 128 * r - sz / 2,
            top: h / 2 + math.sin(a) * 52 * r - sz / 2 + 8,
            child: Opacity(
              opacity: (0.35 + 0.65 * depth) * (1 - pull * 0.9),
              child: GoldSeal(size: sz, glow: glow, earned: false),
            ),
          );
          (math.sin(a) < 0 ? back : front).add(seal);
        }
        return Stack(
          children: <Widget>[
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    shown ? 'YOUR TOPIC' : 'UNSEALING YOUR TOPIC',
                    style: goldKick,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: w,
                    height: h,
                    child: Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        const OverflowBox(
                          maxWidth: 360,
                          maxHeight: 360,
                          child: GoldRays(size: 360, opacity: 0.3),
                        ),
                        ...back,
                        Transform.scale(
                          scale:
                              1 +
                              0.35 * pull +
                              (shown ? 0.1 * (1 - rise.clamp(0.0, 1.0)) : 0),
                          child: const GoldCoin(size: 84),
                        ),
                        ...front,
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Opacity(
                    opacity: rise.clamp(0.0, 1.0).toDouble(),
                    child: Transform.scale(
                      scale: 0.8 + 0.2 * rise,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 26),
                        child: Column(
                          children: <Widget>[
                            GoldShimmerText(
                              widget.topic.toUpperCase(),
                              textAlign: TextAlign.center,
                              extrude: 5,
                              style: goldSerif(31, w: FontWeight.w900),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              widget.tagline,
                              textAlign: TextAlign.center,
                              style: goldSerif(16, italic: true),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (shown) ...<Widget>[
              const Positioned.fill(
                child: GoldShockwave(key: ValueKey<String>('wave')),
              ),
              const Positioned.fill(
                child: GoldFlash(key: ValueKey<String>('flash'), strength: 0.6),
              ),
              const Positioned.fill(
                child: CoinBurst(big: true, origin: Alignment(0, -0.15)),
              ),
            ],
          ],
        );
      },
    );
  }
}

// END OF FILE - lib/screens/golden_reveal.dart
