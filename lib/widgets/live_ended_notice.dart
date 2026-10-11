import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';

class LiveEndedNotice extends StatelessWidget {
  const LiveEndedNotice(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 350),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 28),
              decoration: BoxDecoration(
                color: IvoryColors.plum.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: IvoryColors.gold.withValues(alpha: 0.82),
                  width: 1.3,
                ),
                boxShadow: IvoryTheme.softShadow(blur: 28, y: 10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 62,
                    height: 62,
                    decoration: const BoxDecoration(
                      gradient: IvoryColors.goldGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: IvoryColors.burgundy,
                      size: 31,
                    ),
                  ),
                  const SizedBox(height: 19),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: IvoryColors.cream,
                      fontFamily: IvoryTheme.displayFont,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

// END OF FILE - lib/widgets/live_ended_notice.dart
