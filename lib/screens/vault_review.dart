import 'package:flutter/material.dart';

import '../models/vault_models.dart';
import '../theme/ivory_theme.dart';
import '../widgets/gold_fx.dart';
import 'golden_quiz_parts.dart';

/// ============================================================
/// IVORY - THE VAULT, OPENED: EVERY DAY'S QUESTION
///
/// Shown only after the last key. For each day: the question,
/// what the member chose, the right answer and the little fact
/// behind it. Reading this never costs anything and can be done
/// any time the member wants to remember what they learned.
/// ============================================================
class VaultReviewScreen extends StatelessWidget {
  const VaultReviewScreen({super.key, required this.result});

  final VaultResult result;

  Widget _option(VaultDay d, int i) {
    final bool right = i == d.correctIdx;
    final bool mine = i == d.chosen;
    final bool wrongPick = mine && !right;
    final Color c = right
        ? GoldTones.light
        : wrongPick
        ? IvoryColors.peach
        : IvoryColors.cream.withValues(alpha: 0.6);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            right
                ? Icons.check_circle_rounded
                : wrongPick
                ? Icons.cancel_rounded
                : Icons.circle_outlined,
            size: 17,
            color: c,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${d.options[i]}${mine ? '  (your choice)' : ''}',
              style: TextStyle(
                color: c,
                fontSize: 14,
                height: 1.3,
                fontWeight: right || mine ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _day(VaultDay d) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GoldenFrame(
        calm: true,
        sparkles: false,
        radius: 20,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text('DAY ${d.day}', style: goldKick),
                const Spacer(),
                Text(
                  d.correct ? '\u20B9${d.amountInr}' : 'Missed',
                  style: TextStyle(
                    color: d.correct
                        ? GoldTones.light
                        : IvoryColors.cream.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(d.question, style: goldSerif(16.5)),
            const SizedBox(height: 10),
            if (d.chosen < 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Time ran out on this day.',
                  style: goldSerif(
                    13.5,
                    color: IvoryColors.peach,
                    italic: true,
                  ),
                ),
              ),
            for (int i = 0; i < d.options.length; i++) _option(d, i),
            if (d.fact.isNotEmpty) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                d.fact,
                style: TextStyle(
                  color: IvoryColors.cream.withValues(alpha: 0.85),
                  fontSize: 13,
                  height: 1.4,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IvoryColors.burgundy,
      body: Container(
        decoration: const BoxDecoration(gradient: IvoryColors.deepGradient),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: GoldTones.light),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      'YOUR ${vaultWord(result.days)} ANSWERS',
                      style: goldKick.copyWith(fontSize: 13),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 30),
                  children: <Widget>[
                    for (final VaultDay d in result.review) _day(d),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// END OF FILE - lib/screens/vault_review.dart
