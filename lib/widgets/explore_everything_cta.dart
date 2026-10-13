import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';

const Duration _explorePulsePeriod = Duration(milliseconds: 1400);
const double _explorePulseScale = 0.055;
const double _explorePulseGoldMix = 0.50;

Color _explorePulseColor(double phase) =>
    Color.lerp(
      IvoryColors.burgundy,
      IvoryColors.gold,
      phase * _explorePulseGoldMix,
    )!;

/// A text-only, gently throbbing route into Explore.
/// The text remains a real accessible tap target, with no visible button chrome.
/// Animation stops when the user has requested reduced motion.
class ExploreEverythingCta extends StatefulWidget {
  const ExploreEverythingCta({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  State<ExploreEverythingCta> createState() => _ExploreEverythingCtaState();
}

class _ExploreEverythingCtaState extends State<ExploreEverythingCta>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: _explorePulsePeriod,
  );

  @override
  void initState() {
    super.initState();
    _pulse.repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant ExploreEverythingCta oldWidget) {
    super.didUpdateWidget(oldWidget);
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
    final bool reduceMotion = MediaQuery.of(context).disableAnimations;
    return Center(
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (BuildContext context, Widget? child) {
          final double breath = reduceMotion
              ? 0
              : Curves.easeInOut.transform(_pulse.value);
          final Color labelColor = _explorePulseColor(breath);
          return Transform.scale(
            scale: 1 + breath * _explorePulseScale,
            child: TextButton(
              onPressed: widget.onTap,
              style: TextButton.styleFrom(
                foregroundColor: labelColor,
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                overlayColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 8,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              child: Text(
                'EXPLORE EVERYTHING →',
                semanticsLabel: 'Explore everything',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: labelColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.65,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// END OF FILE - lib/widgets/explore_everything_cta.dart
