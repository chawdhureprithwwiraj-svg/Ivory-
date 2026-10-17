import 'package:flutter/material.dart';

import '../models/quiz_models.dart';
import '../theme/ivory_theme.dart';
import '../widgets/gold_fx.dart';

/// ============================================================
/// IVORY - THE VERDICT
///
/// What shows after an answer: right (a golden banner), wrong, or
/// time up; the true fact; a thin bar counting down to the next
/// question; a tap to go on at once.
/// ============================================================
class GoldenVerdict extends StatelessWidget {
  const GoldenVerdict({
    super.key,
    required this.a,
    required this.timedOut,
    required this.advance,
    required this.streak,
    required this.onTap,
  });

  final GoldenAnswer a;
  final bool timedOut;
  final Animation<double> advance;
  final int streak;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GoldenFrame(
        calm: !a.correct,
        radius: 20,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (a.correct)
              Row(
                children: <Widget>[
                  Expanded(
                    child: GoldShimmerText(
                      a.golden
                          ? 'GOLDEN ANSWER  +\u20B9${a.amountInr}'
                          : 'RIGHT  +\u20B9${a.amountInr}',
                      extrude: 3,
                      style: const TextStyle(
                        fontFamily: IvoryTheme.displayFont,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  if (streak >= 2) _Streak(streak),
                ],
              )
            else
              Text(
                timedOut ? 'Time is up.' : 'Not this time.',
                style: TextStyle(
                  color: IvoryColors.cream.withValues(alpha: 0.95),
                  fontFamily: IvoryTheme.displayFont,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            if (a.fact.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                a.fact,
                style: TextStyle(
                  color: IvoryColors.cream.withValues(alpha: 0.9),
                  fontSize: 13.5,
                  height: 1.45,
                ),
              ),
            ],
            const SizedBox(height: 12),
            AnimatedBuilder(
              animation: advance,
              builder: (BuildContext context, Widget? _) => ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: advance.value,
                  minHeight: 4,
                  color: GoldTones.mid,
                  backgroundColor: IvoryColors.gold.withValues(alpha: 0.2),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                a.finished
                    ? 'TAP TO SEE YOUR GOLD'
                    : 'TAP FOR THE NEXT QUESTION',
                style: const TextStyle(
                  color: GoldTones.light,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "3 IN A ROW": a pulsing little medal. Counted on this phone only.
class _Streak extends StatelessWidget {
  const _Streak(this.n);
  final int n;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        gradient: GoldTones.flat,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GoldTones.shine),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: IvoryColors.gold.withValues(alpha: 0.6),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.local_fire_department,
            size: 14,
            color: IvoryColors.burgundy,
          ),
          const SizedBox(width: 3),
          Text(
            '$n IN A ROW',
            style: const TextStyle(
              color: IvoryColors.burgundy,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

// END OF FILE - lib/screens/golden_verdict.dart
