import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/bell_models.dart';
import '../models/heart_models.dart';
import 'bell_paint.dart';
import 'bells_arch.dart';
import 'bells_fx.dart';
import 'bells_orb.dart';
import 'heart_paint.dart';

/// ============================================================
/// IVORY - THE STAGE OF THE DOORBELL
///
/// The arch card: the title, four jewel bells hanging from a rainbow
/// rope, the Golden Heart in its medallion, and a round button under
/// each bell. The screen tells it which bells to ring and when; it
/// swings them, sounds them and sends ribbons of light into the heart.
/// ============================================================
class BellsStage extends StatefulWidget {
  const BellsStage({
    super.key,
    required this.state,
    required this.heart,
    required this.shown,
    required this.fullShown,
    required this.onOrb,
  });

  final BellsState? state;
  final HeartState? heart;

  /// Keys of the bells whose ringing has been shown.
  final Set<String> shown;
  final bool fullShown;
  final ValueChanged<String> onOrb;

  @override
  State<BellsStage> createState() => BellsStageState();
}

class BellsStageState extends State<BellsStage> with TickerProviderStateMixin {
  static const double _swingSeconds = 3.4;
  final BellsFxController _fx = BellsFxController();
  late final List<AnimationController> _swing =
      List<AnimationController>.generate(
        4,
        (int _) => AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 3400),
        ),
      );
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();
  final GlobalKey _cardKey = GlobalKey();
  final GlobalKey _heartKey = GlobalKey();
  final List<GlobalKey> _bellKeys = List<GlobalKey>.generate(
    4,
    (int _) => GlobalKey(),
  );
  bool _fullIn = false;

  @override
  void initState() {
    super.initState();
    _fullIn = widget.fullShown;
  }

  @override
  void didUpdateWidget(BellsStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fullShown) _fullIn = true;
  }

  @override
  void dispose() {
    for (final AnimationController c in _swing) {
      c.dispose();
    }
    _pulse.dispose();
    _spin.dispose();
    super.dispose();
  }

  Offset? _centre(GlobalKey k) {
    final RenderObject? o = k.currentContext?.findRenderObject();
    final RenderObject? card = _cardKey.currentContext?.findRenderObject();
    if (o is! RenderBox || card is! RenderBox || !o.hasSize || !card.hasSize) {
      return null;
    }
    return card.globalToLocal(o.localToGlobal(o.size.center(Offset.zero)));
  }

  /// Swings a bell, sounds it and sends its ribbons into the heart.
  void ringBell(String key) {
    final int i = BellTones.keys.indexOf(key);
    if (i < 0) return;
    _swing[i].forward(from: 0);
    final Offset? from = _centre(_bellKeys[i]);
    final Offset? to = _centre(_heartKey);
    if (from != null && to != null) {
      _fx.ribbon(from, to, BellTones.of(i));
    }
    Future<void>.delayed(const Duration(milliseconds: 950), () {
      if (mounted) _pulse.forward(from: 0);
    });
  }

  /// The Full Day: bloom, wash, lanterns, the iridescent bell and star.
  void playFull() {
    final Offset? to = _centre(_heartKey);
    final RenderObject? card = _cardKey.currentContext?.findRenderObject();
    if (to != null && card is RenderBox && card.hasSize) {
      _fx.fullDay(to, card.size);
    }
    setState(() => _fullIn = true);
    _pulse.forward(from: 0);
  }

  double _ropeY(double u) => 56 - 136 * u + 136 * u * u;

  @override
  Widget build(BuildContext context) {
    final BellsState? st = widget.state;
    final List<BellItem> items = st?.bells ?? const <BellItem>[];
    final List<String> keys = items.isEmpty
        ? BellTones.keys
        : items.map((BellItem b) => b.key).toList();
    final List<double> us = keys.length >= 4
        ? <double>[0.12, 0.38, 0.62, 0.88]
        : <double>[0.16, 0.5, 0.84];
    BellItem? item(String k) => st?.byKey(k);

    return ArchShell(
      child: Stack(
        key: _cardKey,
        children: <Widget>[
          Column(
            children: <Widget>[
              const SizedBox(height: 26),
              ArcTitle(text: 'RING MY DOORBELL', fade: _fullIn ? 0.12 : 1),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 600),
                opacity: _fullIn ? 0.1 : 1,
                child: const Text(
                  'YOUR DAILY CHECK-IN  \u00B7  FOUR BELLS',
                  style: TextStyle(
                    color: Color(0xFFCFF6FF),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.4,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 262,
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints box) =>
                      _stage(box.maxWidth, keys, us, item),
                ),
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 600),
                opacity: _fullIn ? 1 : 0,
                child: const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'A FULL DAY',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                      color: Color(0xFFD6FBFF),
                      shadows: <Shadow>[
                        Shadow(color: Color(0xAAFFFFFF), blurRadius: 10),
                      ],
                    ),
                  ),
                ),
              ),
              _pointsLine(),
              const SizedBox(height: 14),
              _orbs(keys, item),
              const SizedBox(height: 20),
            ],
          ),
          // the Full-Day bell, descending in changing pearl colours
          AnimatedPositioned(
            duration: const Duration(milliseconds: 1300),
            curve: Curves.easeOutBack,
            left: 0,
            right: 0,
            top: _fullIn ? 46 : -260,
            child: IgnorePointer(
              child: Center(
                child: AnimatedBuilder(
                  animation: _spin,
                  builder: (BuildContext _, Widget? __) => BellShape(
                    color: HSVColor.fromAHSV(
                      1,
                      (_spin.value * 360) % 360,
                      0.38,
                      1,
                    ).toColor(),
                    width: 112,
                    glow: 0.9,
                    swing: 0.05 * math.sin(_spin.value * 2 * math.pi * 2),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(child: BellsFxLayer(controller: _fx)),
          ),
        ],
      ),
    );
  }

  Widget _pointsLine() {
    final HeartState? h = widget.heart;
    if (h == null) return const SizedBox(height: 18);
    const TextStyle base = TextStyle(color: Color(0xFFE4DBFF), fontSize: 13);
    if (h.lit) {
      return const Text("Today's heart is lit", style: base);
    }
    return Text.rich(
      TextSpan(
        style: base,
        children: <InlineSpan>[
          TextSpan(
            text: '${h.points}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(text: " of ${h.litPoints} to light today's heart"),
        ],
      ),
    );
  }

  Widget _stage(
    double w,
    List<String> keys,
    List<double> us,
    BellItem? Function(String) item,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned.fill(child: CustomPaint(painter: BellRopePainter())),
        for (int n = 0; n < keys.length; n++)
          _bellSlot(w, keys[n], us[n], item(keys[n])),
        Positioned(left: w / 2 - 44, top: 176, child: _medallion()),
      ],
    );
  }

  Widget _bellSlot(double w, String key, double u, BellItem? it) {
    final int i = BellTones.keys.indexOf(key);
    final Color c = BellTones.of(i);
    final bool rung = widget.shown.contains(key);
    final bool locked = it != null && !it.isOpen && !rung;
    final bool waiting = it != null && it.isOpen && !rung;
    final String time = it?.timeLabel ?? '';
    final String sub = rung ? 'rung' : (locked ? 'opens $time' : time);
    return Positioned(
      left: w * u - 40,
      top: _ropeY(u) * 1.0,
      width: 80,
      child: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[_swing[i], _spin]),
        builder: (BuildContext _, Widget? __) {
          final double secs = _swing[i].value * _swingSeconds;
          final double hit = _swing[i].isAnimating ? 1 : 0;
          double angle = bellSwingAt(secs) * hit;
          if (hit == 0 && waiting) {
            angle = 0.05 * math.sin(_spin.value * 2 * math.pi * 3 + i);
          }
          final double shine = _swing[i].isAnimating
              ? (_swing[i].value * 3).clamp(0.0, 1.0)
              : -1;
          final double ripple = _swing[i].isAnimating
              ? (secs / 1.3).clamp(0.0, 1.0)
              : 1;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 2,
                height: 14,
                color: Colors.white.withValues(alpha: 0.55),
              ),
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: <Widget>[
                  if (ripple < 1)
                    Positioned(
                      top: 46,
                      child: Container(
                        width: 8 + ripple * 84,
                        height: 8 + ripple * 84,
                        transform: Matrix4.translationValues(
                          0,
                          -(4 + ripple * 42),
                          0,
                        ),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(
                              alpha: 0.9 * (1 - ripple),
                            ),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  KeyedSubtree(
                    key: _bellKeys[i],
                    child: BellShape(
                      color: c,
                      width: 60,
                      glow: rung ? 0.95 : (locked ? 0.12 : 0.5),
                      swing: angle,
                      shine: shine,
                      dim: locked,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                (it?.label ?? key).toUpperCase(),
                style: TextStyle(
                  color: BellTones.mix(c, Colors.white, 0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              Text(
                sub,
                style: const TextStyle(color: Color(0xFFD9CCFF), fontSize: 10),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _medallion() {
    final HeartState? h = widget.heart;
    final bool lit = h?.lit ?? false;
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[_spin, _pulse]),
      builder: (BuildContext _, Widget? __) {
        final double s = 1 + 0.2 * math.sin(math.pi * _pulse.value);
        return Transform.scale(
          scale: s,
          child: SizedBox(
            key: _heartKey,
            width: 88,
            height: 88,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: <Widget>[
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      transform: GradientRotation(_spin.value * 2 * math.pi),
                      colors: const <Color>[
                        Color(0xFFFF6B8B),
                        Color(0xFFFFA42B),
                        Color(0xFF4DF0A8),
                        Color(0xFF52C7FF),
                        Color(0xFFB07CFF),
                        Color(0xFFFF6B8B),
                      ],
                    ),
                    boxShadow: lit
                        ? const <BoxShadow>[
                            BoxShadow(color: Color(0xAAFFC93C), blurRadius: 24),
                          ]
                        : null,
                  ),
                ),
                Container(
                  width: 82,
                  height: 82,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: Alignment(-0.2, -0.4),
                      colors: <Color>[Color(0xFF5A2FC4), Color(0xFF2F1A86)],
                    ),
                  ),
                ),
                HeartPaint(size: 66, fill: h?.fill ?? 0, tier: h?.tierIdx ?? 0),
                Positioned(
                  top: -22,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.elasticOut,
                    scale: _fullIn ? 1 : 0,
                    child: const Text(
                      '\u2726',
                      style: TextStyle(
                        fontSize: 26,
                        color: Color(0xFFFFE3F2),
                        shadows: <Shadow>[
                          Shadow(color: Color(0xFFFF8FC0), blurRadius: 12),
                        ],
                      ),
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

  Widget _orbs(List<String> keys, BellItem? Function(String) item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        for (final String key in keys)
          BellOrb(
            bellKey: key,
            item: item(key),
            isRung: widget.shown.contains(key),
            onTap: () => widget.onOrb(key),
          ),
      ],
    );
  }
}

// END OF FILE - lib/widgets/bells_stage.dart
