import 'package:flutter/material.dart';

import '../models/reward_models.dart';
import '../services/early_service.dart';
import '../services/ladder_service.dart';
import '../services/reward_service.dart';
import 'ladder_paint.dart';

/// ============================================================
/// IVORY - WHAT THE CLIMB GIVES YOU (CC.218)
///
/// The ladder's plain-words explainer. One honest card that tells any
/// member - new or old, in any language of the heart - exactly what
/// climbing pays, in the order a newcomer asks it: how do I rise, what
/// opens as I rise, and why does anyone come back tomorrow. Every number
/// is read from the house's own settings (Early Door hours, Mark points,
/// door gifts), so the card can never promise what the house has switched
/// off. Nothing here is for sale; the last line says so and means it.
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

  /// A small heading in the ladder's mint voice.
  Widget _head(String t) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(
      t,
      style: const TextStyle(
        color: LadderTones.mint,
        fontWeight: FontWeight.w900,
        letterSpacing: 2.2,
        fontSize: 11.5,
      ),
    ),
  );

  /// One plain-words line: mint icon, bright head, pearl body.
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
                  text: head.isEmpty ? '' : '$head  ',
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
        final List<Widget> opens = <Widget>[];
        if (e != null) {
          if (e.paid && e.hours >= 100000) {
            opens.add(
              _line(
                Icons.door_front_door_outlined,
                'You read first.',
                'Your membership opens held stories for you the moment '
                    'they are held - you are in the room before the world '
                    'knocks.',
              ),
            );
          } else if (e.rungHours > 0) {
            opens.add(
              _line(
                Icons.door_front_door_outlined,
                'You read first.',
                'At ${e.rungName} you read every new story ${_hours(e.rungHours)} '
                    'before everyone else, while your Golden Heart is lit. '
                    'The first reader of a story is part of its history.',
              ),
            );
          } else if (e.nextWindow != null) {
            opens.add(
              _line(
                Icons.door_front_door_outlined,
                'You read first.',
                'Reach ${e.nextWindow!.name} and every new story opens for you '
                    '${_hours(e.nextWindow!.hours)} before everyone else, while '
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
            opens.add(
              _line(
                Icons.card_giftcard,
                'The rung pays you back.',
                'Some rungs hand you a one-time discount on a membership - '
                    'the climb itself buys your way deeper in. The next gift '
                    'is shown above.',
              ),
            );
          }
        }
        opens.add(
          _line(
            Icons.verified_outlined,
            'Your Marks are worth points.',
            'Every Mark you leave adds +$mp climb points, can be pinned to '
                'your Showcase, and collecting Marks unlocks treasures of '
                'their own. Kindness, here, literally moves you up.',
          ),
        );
        opens.add(
          _line(
            Icons.workspace_premium_outlined,
            'Your name carries its history.',
            'Your rung, your bells and your pinned Marks are shown on your '
                'Profile and, while you leave it on, as a small tag beside '
                'your name in live chat. People see how long you have been '
                'standing here.',
          ),
        );
        opens.add(
          _line(
            Icons.military_tech_outlined,
            'Treasures with names.',
            'Eternal Glow, Crowned, First Light, Peal of a Hundred - each '
                'badge on this screen is a story of showing up, and the '
                'house keeps your whole shelf on your Profile forever.',
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
              const Text(
                'WHAT THE CLIMB GIVES YOU',
                style: TextStyle(
                  color: LadderTones.mint,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.6,
                  fontSize: 11.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'In plain words, for anyone standing here for the first '
                'time: the ladder is the house saying thank you for '
                'coming back. You rise by showing up - never by paying - '
                'and everything you earn stays earned.',
                style: TextStyle(
                  color: LadderTones.pearl,
                  height: 1.45,
                  fontSize: 13,
                ),
              ),
              _head('HOW YOU RISE - ONE TAP A DAY'),
              _line(
                Icons.favorite_border,
                'Light your heart.',
                'One tap on your Golden Heart, once a day, is +1 climb '
                    'point. Stay a Full Day and it is +1 more. That is the '
                    'whole daily ask: ten seconds of presence.',
              ),
              _line(
                Icons.show_chart,
                'Points become rungs.',
                'Twelve rungs stand above you - Pearl, then Quill, and on '
                    'toward the Ivory Crown - each with its points written '
                    'on the rail. Twelve lit days carry you from Pearl to '
                    'Quill; a Mark left on a story is +$mp in a single step.',
              ),
              _line(
                Icons.shield_outlined,
                'Nothing is lost forever.',
                'Miss a day and your streak rests; your rung, your points '
                    'and every treasure you have earned stay exactly where '
                    'you left them. The climb waits for you.',
              ),
              _head('WHAT OPENS AS YOU RISE'),
              ...opens,
              _head('WHY MEMBERS COME BACK EVERY DAY'),
              _line(
                Icons.edit_note,
                'Because the writer sees you.',
                'Your Mark tells the real person behind the story that '
                    'someone was in the room - and your name is stamped on '
                    'the moment you were there. Few places on earth still '
                    'do that.',
              ),
              _line(
                Icons.calendar_today_outlined,
                'Because small days become a year of light.',
                'Seven lit days is a badge. Thirty is a bell. A hundred, '
                    'a year - the calendar on this screen is quietly '
                    'becoming the truest diary you own.',
              ),
              _line(
                Icons.emoji_events_outlined,
                'Because no one can buy past you.',
                'Every rung in this house was stood on, not paid for. When '
                    'a name glows at the top of the ladder, everyone knows '
                    'it means a thousand ordinary mornings - and that is '
                    'why it is worth wanting.',
              ),
              const SizedBox(height: 12),
              const Text(
                'One lit heart a day is the whole climb. Begin from your '
                'Golden Heart - it takes ten seconds, and the house '
                'remembers every one.',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  height: 1.45,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
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
