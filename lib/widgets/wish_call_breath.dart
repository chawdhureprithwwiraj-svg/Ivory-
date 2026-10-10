import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';

/// A continuous, slow gold breath on the one call named by a notice.
/// It stays visible while the member still needs to choose a time;
/// WishCallBanner turns it off when requestedFor is no longer null.
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
    duration: const Duration(milliseconds: 2600),
  );

  void _breathe() => _controller.repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    if (widget.on) _breathe();
  }

  @override
  void didUpdateWidget(covariant WishCallBreath oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.on &&
        (!oldWidget.on || widget.pulseKey != oldWidget.pulseKey)) {
      _controller.reset();
      _breathe();
    } else if (!widget.on && oldWidget.on) {
      _controller.stop();
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
        final double strength =
            Curves.easeInOutCubic.transform(_controller.value);
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: IvoryColors.gold
                    .withValues(alpha: 0.18 + 0.24 * strength),
                blurRadius: 10 + 12 * strength,
                spreadRadius: 1 + 2 * strength,
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
