import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4;

import '../theme/ivory_theme.dart';

/// A slow, continuous left-to-right turn around the crown's vertical axis.
/// This is a perspective yaw, not a clockwise screen-plane roll.
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
            builder: (BuildContext context, Widget? child) {
              // Positive Y rotation follows the left-pointing direction shown.
              // Perspective narrows it toward an edge-on view.
              final double angle = _turn.value * math.pi * 2;
              final Matrix4 transform = Matrix4.identity()
                ..setEntry(3, 2, 0.0015)
                ..rotateY(angle);
              return Transform(
                alignment: Alignment.center,
                transform: transform,
                child: child,
              );
            },
          ),
        ),
      ),
    );
  }
}

// END OF FILE - lib/widgets/rotating_gift_crown.dart
