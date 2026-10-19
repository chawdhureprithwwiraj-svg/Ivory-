import 'package:flutter/material.dart';

import '../models/reward_models.dart';
import '../services/early_service.dart';
import '../services/ladder_service.dart';
import '../services/reward_service.dart';
import 'ladder_paint.dart';

/// ============================================================
/// IVORY - WHAT CLIMBING GIVES YOU
///
/// One honest card on the Ladder screen that says what a member gains
/// by climbing. Every line is read from the house's own settings
/// (the Early Door hours, the treasures), so it changes when the house
/// changes them, and a line whose feature is switched off is simply
/// not shown. Nothing here is for sale.
/// ============================================================
class LadderPerks extends StatefulWidget {
  const LadderPerks({super.key});

  @override
  State<LadderPerks> createState() => _LadderPerksState();
}

class _LadderPerksState extends State<LadderPerks> {
  @override
  void initState() {
    super.initState();
    EarlyService.instance.refresh();
    RewardService.instance.refreshQuietly();
  }

  String _hours(int h) {
    if (h >= 24 && h % 24 == 0) {
      final int d = h ~/ 24;
      return d == 1 ? '1 day' : '$d days';
    }
    return h == 1 ? '1 hour' : '$h hours';
  }

  Widget _line(IconData icon, String head, String body) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 1, right: 10),
          child: Icon(icon, size: 18, color: LadderTones.mint),
        ),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: <InlineSpan>[
                TextSpan(
                  text: '$head  ',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(text: body),
              ],
            ),
            style: const TextStyle(
              color: LadderTones.pearl,
              height: 1.45,
              fontSize: 13,
            ),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[
        EarlyService.instance.state,
        RewardService.instance.state,
        LadderService.instance.state,
      ]),
      builder: (BuildContext c, Widget? _) {
        final EarlyState? e = EarlyService.instance.state.value;
        final RewardState? r = RewardService.instance.state.value;
        final int mp = LadderService.instance.state.value?.markPoints ?? 3;
        final List<Widget> lines = <Widget>[];
        if (e != null) {
          if (e.paid && e.hours >= 100000) {
            lines.add(
              _line(
                Icons.door_front_door_outlined,
                'Early Door.',
                'Your membership opens held stories for you the moment '
                    'they are held.',
              ),
            );
          } else if (e.rungHours > 0) {
            lines.add(
              _line(
                Icons.door_front_door_outlined,
                'Early Door.',
                'At ${e.rungName} you read new stories ${_hours(e.rungHours)} '
                    'before everyone, while your Golden Heart is lit.',
              ),
            );
          } else if (e.nextWindow != null) {
            lines.add(
              _line(
                Icons.door_front_door_outlined,
                'Early Door.',
                'Reach ${e.nextWindow!.name} and you read new stories '
                    '${_hours(e.nextWindow!.hours)} before everyone, while '
                    'your Golden Heart is lit.',
              ),
            );
          }
        }
        if (r != null) {
          final bool gifts = <RewardItem>[...r.earned, ...r.locked].any(
            (RewardItem x) => x.trigger == 'ladder_rung' && x.prize != null,
          );
          if (gifts) {
            lines.add(
              _line(
                Icons.card_giftcard,
                'Door gifts.',
                'Some rungs give a one-time discount on a membership. The '
                    'next one is shown above.',
              ),
            );
          }
        }
        lines.add(
          _line(
            Icons.verified_outlined,
            'Marks.',
            'Each Mark adds +$mp climb points, can be pinned to your '
                'Showcase, and collecting them earns treasures.',
          ),
        );
        lines.add(
          _line(
            Icons.workspace_premium_outlined,
            'Your Showcase.',
            'Your rung, your bells and your pinned Marks are shown on your '
                'Profile and, while you leave it on, as a small tag beside '
                'your name in live chat.',
          ),
        );
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                LadderTones.tealMid.withValues(alpha: 0.85),
                LadderTones.tealDeep.withValues(alpha: 0.9),
              ],
            ),
            border: Border.all(color: LadderTones.mint.withValues(alpha: 0.22)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'WHAT CLIMBING GIVES YOU',
                  style: TextStyle(
                    color: LadderTones.mint,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.6,
                    fontSize: 11.5,
                  ),
                ),
              ),
              ...lines,
              const Text(
                'Climbing is earned by showing up. It can never be bought.',
                style: TextStyle(color: LadderTones.mist, fontSize: 11.5),
              ),
            ],
          ),
        );
      },
    );
  }
}

// END OF FILE - lib/widgets/ladder_perks.dart
