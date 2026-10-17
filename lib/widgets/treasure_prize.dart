import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/reward_models.dart';
import '../theme/ivory_theme.dart';
import 'gold_fx.dart';

/// The discount code that came with an earned treasure, with a copy
/// button and what state it is in.
class TreasurePrizeLine extends StatelessWidget {
  const TreasurePrizeLine({
    super.key,
    required this.prize,
    required this.untilText,
  });

  final RewardPrize prize;

  /// The end date, already written for a member ("16 Nov 2026").
  final String untilText;

  @override
  Widget build(BuildContext context) {
    final String code = prize.code ?? '';
    final bool live = !prize.used && !prize.ended;
    final String status = prize.used
        ? 'Used'
        : prize.ended
        ? 'Ended $untilText'
        : '${prize.offText} \u00B7 until $untilText';
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
      decoration: BoxDecoration(
        color: IvoryColors.gold.withValues(alpha: live ? 0.26 : 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: IvoryColors.hairlineStrong),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'YOUR DISCOUNT CODE',
                  style: TextStyle(
                    color: GoldTones.deep,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  code,
                  style: TextStyle(
                    color: IvoryColors.burgundy.withValues(
                      alpha: live ? 1 : 0.5,
                    ),
                    fontWeight: FontWeight.w900,
                    fontSize: 13.5,
                    letterSpacing: 0.6,
                  ),
                ),
                Text(
                  status,
                  style: TextStyle(color: IvoryColors.textFaint, fontSize: 11),
                ),
              ],
            ),
          ),
          if (live)
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.copy_rounded, size: 18),
              color: IvoryColors.plum,
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: code));
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Code copied.')));
                }
              },
            ),
        ],
      ),
    );
  }
}

/// What a still-locked treasure will also give.
class TreasurePrizeHint extends StatelessWidget {
  const TreasurePrizeHint({super.key, required this.prize});

  final RewardPrize prize;

  @override
  Widget build(BuildContext context) {
    final int? d = prize.days;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        'Comes with a discount code: ${prize.offText}'
        '${d == null ? '' : ', yours for $d days'}',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: GoldTones.deep,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          height: 1.3,
        ),
      ),
    );
  }
}

// END OF FILE - lib/widgets/treasure_prize.dart
