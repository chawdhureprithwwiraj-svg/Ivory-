import 'package:flutter/material.dart';

import '../models/ladder_models.dart';
import 'ladder_paint.dart';

/// ============================================================
/// IVORY - THE TWO STREAKS AND THEIR MILESTONES
///
/// The heart glow and the bell Peal, side by side. Each shows its run
/// now, its best, and a chip for every milestone (7, 30, 100, 166, 366
/// by default; the house can change them). A reached milestone is lit.
/// ============================================================
class LadderStreaks extends StatelessWidget {
  const LadderStreaks({super.key, required this.state});

  final LadderState state;

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      t,
      style: const TextStyle(
        color: LadderTones.mint,
        fontWeight: FontWeight.w900,
        letterSpacing: 2.6,
        fontSize: 11.5,
      ),
    ),
  );

  Widget _row(String title, String kind, int now, int best, LadderState s) {
    int? nextMs;
    for (final int d in s.milestoneDays) {
      if (d > now && (nextMs == null || d < nextMs)) nextMs = d;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
            Text(
              '$now now  \u00B7  best $best',
              style: const TextStyle(color: LadderTones.pearl, fontSize: 12.5),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: s.milestoneDays.map((int d) {
            final bool got = s.hasMilestone(kind, d);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: got
                    ? LadderTones.mint
                    : LadderTones.tealDeep.withValues(alpha: 0.6),
                border: Border.all(
                  color: got
                      ? LadderTones.mint
                      : LadderTones.mist.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                '$d',
                style: TextStyle(
                  color: got ? LadderTones.teal : LadderTones.mist,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          nextMs == null
              ? 'Every milestone reached.'
              : '${nextMs - now} more ${nextMs - now == 1 ? 'day' : 'days'} to your $nextMs-day mark.',
          style: TextStyle(
            color: LadderTones.mist.withValues(alpha: 0.95),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final LadderState s = state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _label('YOUR STREAKS'),
        _row('Heart glow', 'glow', s.glowNow, s.glowBest, s),
        const SizedBox(height: 18),
        _row('Bell Peal', 'peal', s.pealNow, s.pealBest, s),
      ],
    );
  }
}

// END OF FILE - lib/widgets/ladder_streaks.dart
