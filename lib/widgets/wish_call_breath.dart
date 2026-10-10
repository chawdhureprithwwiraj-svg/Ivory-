import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';

/// A slow gold breath for the booking a member was sent to find.
///
/// Exactly three swells over 5.2 seconds, then it stops. The
/// changing key restarts it if another notice is tapped before
/// the first breath finishes. It never loops or keeps nagging.
class WishCallBreath extends StatefulWidget {
  const WishCallBreath({
    super.key,
    required this.child,
    required this.on,
    required this.pulseKey,
  });

  final Widget child;
  final bool on;
  final int pulseKey;

  @override
  State<WishCallBreath> createState() => _WishCallBreathState();
}

class _WishCallBreathState extends State<WishCallBreath>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5200),
  );

  @override
  void initState() {
    super.initState();
    if (widget.on) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant WishCallBreath oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.on &&
        (!oldWidget.on || widget.pulseKey != oldWidget.pulseKey)) {
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.on) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        // Three full swells in one forward pass: no timer and no loop.
        final double strength =
            (1 - math.cos(_controller.value * 6 * math.pi)) / 2;
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: IvoryColors.gold.withValues(alpha: 0.52 * strength),
                blurRadius: 8 + 20 * strength,
                spreadRadius: 1 + 3 * strength,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// END OF FILE - lib/widgets/wish_call_breath.dart
