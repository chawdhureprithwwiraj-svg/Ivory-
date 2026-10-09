import 'package:flutter/material.dart';

import '../models/live_models.dart';
import '../theme/ivory_theme.dart';
import 'call_sheet_bits.dart';

/// ============================================================
/// WHAT THIS MEMBER IS ENTITLED TO, AS ONE CARD.
///
/// Lifted out of call_wish_sheet.dart, which had grown past the
/// size that can be pasted reliably on a phone. Nothing about
/// it changed in the move.
///
/// It answers one question - does your membership already cover
/// this session, or is it a wish you pay for - and it answers
/// it with the numbers rather than with adjectives.
/// ============================================================
class CallAllowanceCard extends StatelessWidget {
  const CallAllowanceCard({
    super.key,
    required this.balance,
    required this.kind,
    required this.minutes,
    required this.priceInr,
  });

  final CallBalance balance;
  final String kind;
  final int minutes;
  final int priceInr;

  /// Came across with the card. It was left behind in
  /// call_wish_sheet.dart by the lift in sprint 27c, which is
  /// what broke that build.
  String _dmy(DateTime d) {
    const List<String> m = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final bool included = balance.isIncluded;
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: IvoryTheme.card(highlighted: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          IvoryEyebrow(
            included ? 'Included with your membership' : 'Available as a wish',
            icon: included ? Icons.verified_rounded : Icons.auto_awesome,
          ),
          const SizedBox(height: 12),
          if (included) ...<Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  '${balance.remaining}',
                  style: const TextStyle(
                    color: IvoryColors.burgundy,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'of ${balance.allowed} minutes left ${balance.periodLabel}',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: IvoryColors.textSoft,
                    ),
                ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: 1 - balance.fraction,
                minHeight: 8,
                backgroundColor: IvoryColors.hairlineStrong,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(IvoryColors.gold),
              ),
            ),
            if (balance.resetsAt != null) ...<Widget>[
              const SizedBox(height: 9),
              Text(
                balance.period == 'membership'
                    ? 'This cycle ends when your membership ends. Minutes '
                        'do not carry over.'
                    : 'Your cycle renews on ${_dmy(balance.resetsAt!)} - '
                        'counted from the day you joined this tier, not '
                        'the calendar month. Minutes do not carry over.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: IvoryColors.textFaint,
                ),
              ),
            ],
            if (balance.noShows > 0) ...<Widget>[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: IvoryColors.surfaceWarm,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: IvoryColors.amber, width: 1),
                ),
                child: Text(
                  balance.noShows == 1
                      ? 'One session was missed this cycle. Missing a second '
                          'is still free - after that, a missed session uses '
                          'its minutes.'
                      : 'Two sessions have been missed this cycle. The next '
                          'one that is missed will use its minutes.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: IvoryColors.textSoft,
                  ),
                ),
              ),
            ],
          ] else
            Text(
              'Your tier does not carry ${kind == 'video' ? 'video' : 'audio'} '
              'minutes yet. You can still have this session by making it a '
              'wish - Rs.${priceInr} for $minutes minutes.',
              style: TextStyle(
                fontSize: 13.5,
                height: 1.55,
                color: IvoryColors.textSoft,
              ),
            ),
        ],
      ),
    );
  }
}

// END OF FILE - lib/widgets/call_allowance_card.dart
