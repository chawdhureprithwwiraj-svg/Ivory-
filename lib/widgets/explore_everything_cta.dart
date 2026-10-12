import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';

/// A clearly tappable, gently pulsing secondary route into Explore.
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
    duration: const Duration(milliseconds: 1400),
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
          final Color edge = Color.lerp(
            IvoryColors.gold,
            IvoryColors.amber,
            breath,
          )!;
          return Transform.scale(
            scale: 1 + breath * 0.018,
            child: Semantics(
              button: true,
              label: 'Explore everything',
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: IvoryColors.gold.withValues(
                        alpha: 0.10 + breath * 0.12,
                      ),
                      blurRadius: 8 + breath * 8,
                      spreadRadius: breath * 1.2,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Material(
                  color: IvoryColors.surface,
                  borderRadius: BorderRadius.circular(30),
                  child: InkWell(
                    onTap: widget.onTap,
                    borderRadius: BorderRadius.circular(30),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 19,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: edge, width: 1.5),
                        gradient: LinearGradient(
                          colors: <Color>[
                            IvoryColors.surface,
                            Color.lerp(
                              IvoryColors.surfaceWarm,
                              IvoryColors.amber.withValues(alpha: 0.22),
                              breath * 0.35,
                            )!,
                          ],
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            Icons.explore_outlined,
                            size: 18,
                            color: IvoryColors.burgundy,
                          ),
                          const SizedBox(width: 9),
                          Text(
                            'EXPLORE EVERYTHING',
                            style: TextStyle(
                              color: IvoryColors.burgundy,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.65,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 17,
                            color: IvoryColors.burgundy,
                          ),
                        ],
                      ),
                    ),
                  ),
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
