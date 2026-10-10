import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';

/// A clear, animated gift action for the live audience.
///
/// The icon and the word GIFT make the action understandable at a glance.
/// Its slow gold pulse draws attention without flashing; reduced-motion
/// settings leave the button still, labelled and fully usable.
class LiveGiftButton extends StatefulWidget {
  const LiveGiftButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<LiveGiftButton> createState() => _LiveGiftButtonState();
}

class _LiveGiftButtonState extends State<LiveGiftButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  void _syncMotion() {
    if (MediaQuery.of(context).disableAnimations) {
      _pulse.stop();
      _pulse.value = 0;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool motionOff = MediaQuery.of(context).disableAnimations;
    return Tooltip(
      message: 'Send a gift',
      child: Semantics(
        button: true,
        label: 'Send a gift to Ivory',
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (BuildContext context, Widget? child) {
            final double breath = motionOff
                ? 0
                : Curves.easeInOutCubic.transform(_pulse.value);
            return Transform.scale(
              scale: 1 + 0.06 * breath,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: IvoryColors.gold.withValues(
                        alpha: motionOff ? 0.20 : 0.20 + 0.24 * breath,
                      ),
                      blurRadius: motionOff ? 10 : 10 + 10 * breath,
                      spreadRadius: motionOff ? 0 : 2.5 * breath,
                    ),
                  ],
                ),
                child: child,
              ),
            );
          },
          child: Material(
            color: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(
                gradient: IvoryColors.goldGradient,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: IvoryColors.cream.withValues(alpha: 0.78),
                  width: 0.8,
                ),
              ),
              child: InkWell(
                onTap: widget.onPressed,
                borderRadius: BorderRadius.circular(22),
                // The label stays tappable even when reduced motion
                // stops the pulse entirely.
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 72,
                    minHeight: 48,
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(
                          Icons.card_giftcard_rounded,
                          color: IvoryColors.burgundy,
                          size: 18,
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'GIFT',
                          style: TextStyle(
                            color: IvoryColors.burgundy,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// END OF FILE - lib/widgets/live_gift_button.dart
