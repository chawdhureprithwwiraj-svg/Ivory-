import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';

/// A realistic emerald-and-gold crown, rotating slowly clockwise on the
/// post-gifter wall. The empty-state version stays softly faded.
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

  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 22),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncRotation();
  }

  @override
  void didUpdateWidget(covariant RotatingGiftCrown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animated != widget.animated) _syncRotation();
  }

  void _syncRotation() {
    if (!widget.animated || MediaQuery.of(context).disableAnimations) {
      _turn.stop();
      _turn.value = 0;
    } else if (!_turn.isAnimating) {
      _turn.repeat();
    }
  }

  @override
  void dispose() {
    _turn.dispose();
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
            animation: _turn,
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
            builder: (BuildContext context, Widget? child) => Transform.rotate(
              // Positive angles are clockwise in Flutter's screen coordinates.
              angle: _turn.value * math.pi * 2,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

// END OF FILE - lib/widgets/rotating_gift_crown.dart
