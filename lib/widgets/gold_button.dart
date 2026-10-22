import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/ivory_theme.dart';
import 'gold_fx.dart';
import 'gold_sound.dart';

/// ============================================================
/// IVORY - THE GOLD BUTTON, CAST
///
/// The call-to-action of the house, recast as a single piece of gold:
/// a bright bevel along the top, its weight and shadow UNDERNEATH where
/// gravity wants them (no dark slab peeling off the card), a hairline
/// bronze rim, a slow shimmer crossing every few seconds and a gentle
/// breathing glow while it waits for a hand. Press it and it settles a
/// hair, like a real key being turned, with a soft click.
/// Split from gold_fx.dart to keep both files inside the paste ceiling.
/// ============================================================

class _BtnSheenPainter extends CustomPainter {
  _BtnSheenPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    // The shimmer crosses in the first stretch of every cycle.
    final double p = (t / 0.45).clamp(0, 1).toDouble();
    if (p >= 1) return;
    final double w = size.width * 0.30;
    final double x = -w + (size.width + w * 2) * p;
    final Rect band = Rect.fromLTWH(x, 0, w, size.height);
    canvas.drawRect(
      band,
      Paint()
        ..shader = LinearGradient(
          colors: <Color>[
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: 0.55),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(band),
    );
  }

  @override
  bool shouldRepaint(_BtnSheenPainter old) => old.t != t;
}

/// The call-to-action: cast gold, a glint that keeps passing,
/// a press that settles a little and a firm tap you can feel.
class GoldButton extends StatefulWidget {
  const GoldButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.busy = false,
    this.ghost = false,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool busy;

  /// Outline only, for a quieter second action.
  final bool ghost;

  @override
  State<GoldButton> createState() => _GoldButtonState();
}

class _GoldButtonState extends State<GoldButton>
    with SingleTickerProviderStateMixin {
  // One breath and one shimmer crossing, every four seconds.
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4000),
  )..repeat();
  bool _down = false;

  static const double _h = 56;
  static const double _room = 6;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool on = widget.onTap != null && !widget.busy;
    final Color ink = widget.ghost ? GoldTones.light : IvoryColors.burgundy;
    final Widget label = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (widget.busy)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: ink),
          )
        else if (widget.icon != null)
          Icon(widget.icon, size: 20, color: ink),
        if (widget.busy || widget.icon != null) const SizedBox(width: 10),
        Flexible(
          child: Text(
            widget.label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: ink,
              fontSize: 15.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              shadows: widget.ghost
                  ? null
                  : <Shadow>[
                      Shadow(
                        color: GoldTones.shine.withValues(alpha: 0.9),
                        offset: const Offset(0, 1),
                      ),
                    ],
            ),
          ),
        ),
      ],
    );
    return Opacity(
      opacity: on || widget.busy ? 1 : 0.5,
      child: GestureDetector(
        onTapDown: on
            ? (TapDownDetails _) => setState(() => _down = true)
            : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (TapUpDetails _) => setState(() => _down = false),
        onTap: on
            ? () {
                HapticFeedback.mediumImpact();
                GoldSound.instance.quick('tap');
                widget.onTap!();
              }
            : null,
        child: AnimatedBuilder(
          animation: _c,
          builder: (BuildContext context, Widget? _) {
            final double pulse = (math.sin(_c.value * math.pi * 2) + 1) / 2;
            return SizedBox(
              height: _h + _room,
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 90),
                    curve: Curves.easeOut,
                    left: 0,
                    right: 0,
                    top: _down ? 2 : 0,
                    child: Container(
                      height: _h,
                      decoration: BoxDecoration(
                        gradient: widget.ghost ? null : const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                            Color(0xFFFFFBE8),
                            Color(0xFFFBE9AE),
                            Color(0xFFE9BE55),
                            Color(0xFFC9962C),
                          ],
                          stops: <double>[0, 0.30, 0.68, 1],
                        ),
                        borderRadius: BorderRadius.circular(_h / 2),
                        border: Border.all(
                          color: widget.ghost
                              ? GoldTones.light
                              : const Color(0xA67A4A12),
                          width: widget.ghost ? 1.6 : 1.6,
                        ),
                        boxShadow: widget.ghost
                            ? null
                            : <BoxShadow>[
                                // Its weight, underneath, where gravity wants it.
                                BoxShadow(
                                  color: IvoryColors.burgundy.withValues(
                                    alpha: _down ? 0.22 : 0.30,
                                  ),
                                  blurRadius: _down ? 8 : 12,
                                  offset: Offset(0, _down ? 4 : 7),
                                ),
                                // The breathing glow while a hand is owed.
                                BoxShadow(
                                  color: IvoryColors.gold.withValues(
                                    alpha: on ? 0.18 + 0.16 * pulse : 0.10,
                                  ),
                                  blurRadius: 14 + 8 * pulse,
                                  spreadRadius: 0.5 + 1 * pulse,
                                ),
                              ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(_h / 2 - 1),
                        child: Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            if (!widget.ghost)
                              Positioned(
                                left: 0,
                                right: 0,
                                top: 0,
                                height: _h * 0.42,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: <Color>[
                                        Colors.white.withValues(alpha: 0.6),
                                        Colors.white.withValues(alpha: 0.02),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            if (!widget.ghost)
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                height: _h * 0.34,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: <Color>[
                                        const Color(0x61926014),
                                        const Color(0x00926014),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            if (on && !widget.ghost)
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _BtnSheenPainter(_c.value),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: label,
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

// END OF FILE - lib/widgets/gold_button.dart
