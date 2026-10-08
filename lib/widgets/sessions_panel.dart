import 'package:flutter/material.dart';

import '../models/live_models.dart';
import '../services/live_service.dart';
import '../theme/ivory_theme.dart';
import 'wish_guide.dart';

/// YOUR SESSIONS WITH IVORY - the card on the Profile page.
///
/// A member who pays for a tier that includes live sessions has
/// no obvious place to learn that. The Wish page sells wishes; it
/// is full of prices, which is exactly the wrong thing to show
/// somebody who has already paid. The Profile page is where a
/// member goes to find out what is theirs - so this is where the
/// answer belongs.
///
/// The card shows, at a glance, how much time each kind of
/// session has left. Everything else - what a session is, how to
/// ask for one, how to arrive - is one tap away and closed until
/// asked for.
class SessionsCard extends StatefulWidget {
  const SessionsCard({super.key, this.onOpenTab});

  final void Function(String tab)? onOpenTab;

  @override
  State<SessionsCard> createState() => _SessionsCardState();
}

class _SessionsCardState extends State<SessionsCard> {
  CallBalance? _video;
  CallBalance? _audio;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final CallBalance v = await LiveService.instance.balance('video');
      final CallBalance a = await LiveService.instance.balance('audio');
      if (!mounted) return;
      setState(() {
        _video = v;
        _audio = a;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  bool get _anyIncluded =>
      (_video?.isIncluded ?? false) || (_audio?.isIncluded ?? false);

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[IvoryColors.surfaceWarm, IvoryColors.cream],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: IvoryColors.gold, width: 1.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const IvoryEyebrow('Your sessions with Ivory',
              icon: Icons.graphic_eq_rounded),
          const SizedBox(height: 13),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: _meter(
                  'Face to face',
                  Icons.videocam_rounded,
                  _video,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: _meter(
                  'Voice only',
                  Icons.phone_in_talk_rounded,
                  _audio,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _anyIncluded
                ? 'These are already yours. Nothing more to pay, '
                    'nothing to book anywhere else.'
                : 'Your tier does not carry session time yet - but '
                    'you can still ask for one as a wish.',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: IvoryColors.textSoft,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _openGuide(context),
              icon: const Icon(Icons.auto_stories_rounded, size: 18),
              label: const Text('HOW TO USE THEM'),
            ),
          ),
          const SizedBox(height: 9),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => widget.onOpenTab?.call('wish'),
              icon: const Icon(Icons.east_rounded, size: 17),
              label: const Text('ASK FOR A SESSION'),
            ),
          ),
        ],
      ),
    );
  }

  /// One kind of session, as a number you can read in a glance
  /// and a bar you can read without reading at all.
  Widget _meter(String title, IconData icon, CallBalance? b) {
    final bool has = b?.isIncluded ?? false;
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 13),
      decoration: BoxDecoration(
        color: IvoryColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: has ? IvoryColors.gold : IvoryColors.hairlineStrong,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon,
                  size: 15,
                  color: has ? IvoryColors.amber : IvoryColors.textFaint),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: IvoryColors.plum,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!has)
            Text(
              'Not in your tier',
              style: TextStyle(fontSize: 12.5, color: IvoryColors.textFaint),
            )
          else ...<Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  '${b!.remaining}',
                  style: const TextStyle(
                    fontSize: 27,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    color: IvoryColors.burgundy,
                  ),
                ),
                const SizedBox(width: 5),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    'min',
                    style:
                        TextStyle(fontSize: 12, color: IvoryColors.textSoft),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: 1 - b.fraction,
                minHeight: 6,
                backgroundColor: IvoryColors.hairlineStrong,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(IvoryColors.gold),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'left ${b.periodLabel}',
              style: TextStyle(
                fontSize: 11,
                height: 1.35,
                color: IvoryColors.textFaint,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openGuide(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) => SessionGuideSheet(
        included: _anyIncluded,
        onGo: () {
          Navigator.of(sheetContext).pop();
          widget.onOpenTab?.call('wish');
        },
      ),
    );
  }
}

/// The whole explanation, in one place, only when asked for.
/// THE ONE MANUAL. Every explanation of how a session works
/// lives here and nowhere else. The Profile card opens it; the
/// gold card on the Wish page opens the same sheet. Two doors,
/// one room - so a member can never read the same thing twice in
/// slightly different words.
class SessionGuideSheet extends StatelessWidget {
  const SessionGuideSheet({
    super.key,
    required this.included,
    required this.onGo,
  });

  final bool included;
  final VoidCallback onGo;

  /// Open it from anywhere. [onGo] may be null when the member is
  /// already on the Wish page - the button then simply closes.
  static void open(BuildContext context,
      {bool included = true, VoidCallback? onGo}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext c) => SessionGuideSheet(
        included: included,
        onGo: onGo ?? () => Navigator.of(c).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.86,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (BuildContext context, ScrollController sc) => Container(
        decoration: const BoxDecoration(
          color: IvoryColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: ListView(
          controller: sc,
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 34),
          children: <Widget>[
            Center(
              child: Container(
                width: 46,
                height: 4,
                decoration: BoxDecoration(
                  color: IvoryColors.gold,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'A session with me',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              included
                  ? 'Live, unhurried, and already part of what you '
                      'pay for. Here is everything, start to finish.'
                  : 'Live and unhurried. Here is everything, start '
                      'to finish.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                fontStyle: FontStyle.italic,
                color: IvoryColors.plum,
              ),
            ),
            const SizedBox(height: 22),
            const IvoryEyebrow('Getting one', icon: Icons.flag_rounded),
            const SizedBox(height: 13),
            const WishStepList(steps: <WishStep>[
              WishStep('Tap Wish at the bottom of the screen. '
                  'Choose to see me, or only to hear me.'),
              WishStep('Tap the button to ask. I am told the '
                  'moment you do, and I answer from my side.'),
              WishStep('When I say yes, a gold card appears at '
                  'the top of the Wish page. That card is how '
                  'you will know - nothing else is needed.'),
              WishStep('Tap PICK YOUR TIME on it and choose any '
                  'day and time that suits you, up to a month '
                  'ahead.'),
            ]),
            const SizedBox(height: 24),
            const IvoryEyebrow('Arriving', icon: Icons.door_front_door),
            const SizedBox(height: 13),
            const WishStepList(steps: <WishStep>[
              WishStep('I will remind you as the day comes '
                  'closer - on your phone, not only in the app.'),
              WishStep('On the day, open Ivory about five '
                  'minutes early. Nobody rings your phone. You '
                  'come here.'),
              WishStep('Tap Wish, tap your session, tap JOIN. '
                  'If it says you are early, close it and tap '
                  'JOIN again in a few minutes.'),
              WishStep('Then wait. I come in from my side, and '
                  'the screen tells you the moment I do.'),
            ]),
            const SizedBox(height: 24),
            const IvoryEyebrow('Good to know', icon: Icons.favorite_rounded),
            const SizedBox(height: 13),
            const WishStepList(steps: <WishStep>[
              WishStep('The clock starts when we are actually '
                  'connected - never at the hour on the card.'),
              WishStep('If you lose the app, come straight back '
                  'and tap JOIN again. Your place is held.'),
              WishStep('If we are still talking when the time '
                  'runs out, I can offer you more. You will see '
                  'it on your screen, and it is yours to refuse.'),
              WishStep('Something came up? Ask me to move it and '
                  'I will. You will find me in the quiet door on '
                  'your Profile page.'),
            ]),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onGo,
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text('THAT IS EVERYTHING'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// END OF FILE - lib/widgets/sessions_panel.dart
