import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../theme/ivory_theme.dart';

/// A gentle, continuous vertical bounce for the confirmed top gifter.
/// The empty-wall crown can remain static through the existing flag.
class RotatingGiftCrown extends StatefulWidget {
  const RotatingGiftCrown({
    super.key,
    required this.size,
    this.faded = false,
    this.animated = true,
  });

  final double size;
  final bool faded;
  final bool animated;

  @override
  State<RotatingGiftCrown> createState() => _RotatingGiftCrownState();
}

class _RotatingGiftCrownState extends State<RotatingGiftCrown>
    with SingleTickerProviderStateMixin {
  static const String _asset = 'assets/premium/ivory_gift_crown.png';

  late final AnimationController _bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant RotatingGiftCrown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animated != widget.animated) _syncMotion();
  }

  void _syncMotion() {
    if (!widget.animated || MediaQuery.of(context).disableAnimations) {
      if (_bounce.isAnimating) _bounce.stop();
      _bounce.value = 0;
    } else if (!_bounce.isAnimating) {
      _bounce.repeat();
    }
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double size = widget.size;
    return Semantics(
      label: widget.faded ? 'Gift crown' : 'Top gifter crown',
      child: SizedBox(
        width: size,
        height: size,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _bounce,
            child: Opacity(
              opacity: widget.faded ? 0.42 : 1,
              child: Image.asset(
                _asset,
                width: size,
                height: size,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.workspace_premium_rounded,
                  size: size * 0.84,
                  color: IvoryColors.gold,
                ),
              ),
            ),
            builder: (BuildContext context, Widget? child) {
              // One full cycle descends to the landing point, then rises smoothly.
              final double phase = _bounce.value * math.pi * 2;
              final double descent = (1 - math.cos(phase)) * 0.5;
              final double squash = descent * 0.035;
              return Transform.translate(
                offset: Offset(0, size * 0.12 * descent),
                child: Transform.scale(
                  scaleX: 1 + squash,
                  scaleY: 1 - squash,
                  alignment: Alignment.center,
                  child: child,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// END OF FILE - lib/widgets/rotating_gift_crown.dart
