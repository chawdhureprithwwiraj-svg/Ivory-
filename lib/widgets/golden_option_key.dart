import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/ivory_theme.dart';
import 'gold_fx.dart';
import 'gold_sound.dart';

/// ============================================================
/// IVORY - THE ANSWER KEY
///
/// Each answer is a solid key that stands proud of the page. It
/// sinks when pressed, glows gold when chosen, turns to polished
/// gold with a glint when it is right, and to a warm red when it
/// is wrong. Plays a soft click on touch.
/// ============================================================

enum AnswerKeyState { idle, picked, right, wrong, dim }

class GoldenOptionKey extends StatefulWidget {
  const GoldenOptionKey({
    super.key,
    required this.letter,
    required this.text,
    required this.state,
    required this.onTap,
  });

  final String letter;
  final String text;
  final AnswerKeyState state;

  /// Null when the key cannot be pressed (an answer is in).
  final VoidCallback? onTap;

  @override
  State<GoldenOptionKey> createState() => _GoldenOptionKeyState();
}

class _KeyGlintPainter extends CustomPainter {
  _KeyGlintPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final double p = (t / 0.5).clamp(0.0, 1.0).toDouble();
    if (p >= 1) return;
    final double w = size.width * 0.3;
    final double x = -w + (size.width + w * 2) * p;
    final Rect band = Rect.fromLTWH(x, 0, w, size.height);
    canvas.drawRect(
      band,
      Paint()
        ..shader = LinearGradient(
          colors: <Color>[
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: 0.6),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(band),
    );
  }

  @override
  bool shouldRepaint(_KeyGlintPainter old) => old.t != t;
}

class _GoldenOptionKeyState extends State<GoldenOptionKey>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();
  bool _down = false;

  static const double _depth = 5;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AnswerKeyState st = widget.state;
    final bool right = st == AnswerKeyState.right;
    final bool wrong = st == AnswerKeyState.wrong;
    final bool picked = st == AnswerKeyState.picked;
    final Color ink = right ? IvoryColors.burgundy : IvoryColors.cream;
    final Color sideA = right
        ? GoldTones.deep
        : wrong
        ? const Color(0xFF6E1F2B)
        : const Color(0xFF3A0B13);
    final bool pressed = _down || picked;
    final Widget row = Row(
      children: <Widget>[
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: right
                ? null
                : const RadialGradient(
                    center: Alignment(-0.4, -0.5),
                    colors: <Color>[GoldTones.light, GoldTones.deep],
                  ),
            color: right ? IvoryColors.burgundy : null,
            border: Border.all(color: right ? GoldTones.shine : GoldTones.rim),
          ),
          child: Text(
            widget.letter,
            style: TextStyle(
              color: right ? GoldTones.shine : IvoryColors.burgundy,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            widget.text,
            style: TextStyle(
              color: ink,
              fontSize: 15.5,
              height: 1.3,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (right) const Icon(Icons.check_circle, color: IvoryColors.burgundy),
        if (wrong) const Icon(Icons.cancel, color: IvoryColors.cream),
      ],
    );
    final Decoration face = BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      gradient: right
          ? GoldTones.metal
          : wrong
          ? const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[Color(0xFFC4505B), IvoryColors.danger],
            )
          : const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[Color(0xFF7A1D30), IvoryColors.plum],
            ),
      border: Border.all(
        color: right
            ? GoldTones.shine
            : wrong
            ? IvoryColors.peach
            : picked
            ? GoldTones.light
            : IvoryColors.gold.withValues(alpha: 0.5),
        width: picked || right ? 2 : 1.2,
      ),
    );
    return AnimatedOpacity(
      opacity: st == AnswerKeyState.dim ? 0.42 : 1,
      duration: const Duration(milliseconds: 260),
      child: GestureDetector(
        onTapDown: widget.onTap == null
            ? null
            : (TapDownDetails _) {
                setState(() => _down = true);
                GoldSound.instance.quick('tap');
              },
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (TapUpDetails _) => setState(() => _down = false),
        onTap: widget.onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                widget.onTap!();
              },
        child: AnimatedBuilder(
          animation: _c,
          builder: (BuildContext context, Widget? _) {
            final double pulse = (math.sin(_c.value * math.pi * 2) + 1) / 2;
            final double glow = right
                ? 0.45 + 0.35 * pulse
                : picked
                ? 0.3 + 0.2 * pulse
                : 0;
            return SizedBox(
              height: 62 + _depth,
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Positioned(
                    left: 0,
                    right: 0,
                    top: _depth,
                    child: Container(
                      height: 62,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: sideA,
                        boxShadow: <BoxShadow>[
                          if (glow > 0)
                            BoxShadow(
                              color: IvoryColors.gold.withValues(alpha: glow),
                              blurRadius: 14 + 12 * pulse,
                              spreadRadius: 1 + 2 * pulse,
                            ),
                          BoxShadow(
                            color: IvoryColors.burgundy.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 80),
                    curve: Curves.easeOut,
                    left: 0,
                    right: 0,
                    top: pressed ? _depth - 1 : 0,
                    child: Container(
                      height: 62,
                      decoration: face,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(17),
                        child: Stack(
                          alignment: Alignment.centerLeft,
                          children: <Widget>[
                            Positioned(
                              left: 0,
                              right: 0,
                              top: 0,
                              height: 24,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: <Color>[
                                      Colors.white.withValues(
                                        alpha: right ? 0.5 : 0.13,
                                      ),
                                      Colors.white.withValues(alpha: 0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (right)
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _KeyGlintPainter(_c.value),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              child: row,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// END OF FILE - lib/widgets/golden_option_key.dart
