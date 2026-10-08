import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';

/// PLAIN INSTRUCTIONS, IN PLAIN WORDS.
///
/// A member cannot ask Ivory a question. There is no chat, no
/// reply button, no helpline. So anything they are unsure about
/// stays unsure, and a person who has paid and then feels lost is
/// a person who will not pay again.
///
/// Everything here is written to be read once, quickly, on a
/// phone, by somebody who is not technical. Short lines. No app
/// words like "navigate" or "interface". No minutes, no prices -
/// those differ by membership and are shown where they belong.
class WishStep {
  const WishStep(this.text);
  final String text;
}

/// One numbered step in a gold circle.
class WishStepList extends StatelessWidget {
  const WishStepList({super.key, required this.steps});

  final List<WishStep> steps;

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < steps.length; i++) {
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: i == steps.length - 1 ? 0 : 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: IvoryColors.gold,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    color: IvoryColors.burgundy,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  steps[i].text,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    color: IvoryColors.textSoft,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
    );
  }
}

/// The exact steps for a session that already has a day and time.
/// This is the one a member reads while they are waiting.
List<WishStep> sessionDaySteps({
  required bool isVideo,
  required String whenLabel,
}) {
  final String tap = isVideo ? 'Request a live session' : 'Talk to me on a call';
  return <WishStep>[
    WishStep('Your time is $whenLabel. Put it in your phone '
        'alarm now so you do not have to remember it.'),
    const WishStep('On the day, open Ivory about five minutes '
        'early. Nobody calls your phone - you come here.'),
    WishStep('Tap the Wish button at the bottom, then tap '
        '"$tap".'),
    const WishStep('You will see a JOIN button. Tap it. If it '
        'tells you it is too early, that is fine - close it, '
        'wait a few minutes and tap JOIN again.'),
    const WishStep('Once you are in, just wait. Ivory comes in '
        'from her side. The screen tells you the moment she '
        'arrives.'),
    const WishStep('Keep the app open while you wait. If you '
        'leave by accident, come straight back and tap JOIN '
        'again - your place is still held.'),
  ];
}

/// A gold-bordered panel of instructions. Collapsed by default so
/// it never buries the page, but the heading makes it obvious what
/// is inside.
class WishGuidePanel extends StatefulWidget {
  const WishGuidePanel({
    super.key,
    required this.title,
    required this.steps,
    this.intro,
    this.closing,
    this.openAtFirst = false,
  });

  final String title;
  final String? intro;
  final String? closing;
  final List<WishStep> steps;
  final bool openAtFirst;

  @override
  State<WishGuidePanel> createState() => _WishGuidePanelState();
}

class _WishGuidePanelState extends State<WishGuidePanel> {
  late bool _open = widget.openAtFirst;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: IvoryColors.surfaceWarm,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: IvoryColors.gold, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Row(
              children: <Widget>[
                Icon(Icons.menu_book_rounded,
                    size: 18, color: IvoryColors.amber),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                      color: IvoryColors.burgundy,
                    ),
                  ),
                ),
                Icon(
                  _open
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: IvoryColors.plum,
                ),
              ],
            ),
          ),
          if (_open) ...<Widget>[
            const SizedBox(height: 13),
            if (widget.intro != null) ...<Widget>[
              Text(
                widget.intro!,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  color: IvoryColors.textSoft,
                ),
              ),
              const SizedBox(height: 13),
            ],
            WishStepList(steps: widget.steps),
            if (widget.closing != null) ...<Widget>[
              const SizedBox(height: 13),
              Text(
                widget.closing!,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                  color: IvoryColors.plum,
                ),
              ),
            ],
          ] else ...<Widget>[
            const SizedBox(height: 6),
            Text(
              'Tap to read it. It takes half a minute.',
              style: TextStyle(fontSize: 12.5, color: IvoryColors.textFaint),
            ),
          ],
        ],
      ),
    );
  }
}

/// THE MEMBERSHIP GUIDE. Shown to anybody whose membership
/// includes sessions, because otherwise they have no idea the
/// sessions are theirs or where they live.
class MembershipCallGuide extends StatelessWidget {
  const MembershipCallGuide({super.key});

  @override
  Widget build(BuildContext context) {
    return WishGuidePanel(
      title: 'How a session with Ivory works - read this first',
      intro: 'Everything happens inside this app. There is '
          'nothing to book anywhere else and no number to call. '
          'If your membership includes sessions, they are '
          'already waiting for you here.',
      steps: const <WishStep>[
        WishStep('You are on the right page. The Wish button at '
            'the bottom of the screen is where every session '
            'lives.'),
        WishStep('Tap "Request a live session" to see Ivory, or '
            '"Talk to me on a call" to only hear her.'),
        WishStep('The gold box at the top of that page shows how '
            'much time your membership gives you and how much is '
            'still left.'),
        WishStep('Tap the button to ask for a session. Ivory is '
            'told straight away.'),
        WishStep('When she says yes, a gold card appears at the '
            'top of this page. That card is how you know.'),
        WishStep('Tap PICK YOUR TIME on that card and choose a '
            'day and a time that suits you.'),
        WishStep('Come back here on the day, a few minutes '
            'early, and tap JOIN. That is all there is to it.'),
      ],
      closing: 'If anything ever looks unclear, come back to '
          'this page. Whatever is happening is always shown at '
          'the top.',
    );
  }
}

/// The pill that floats above the page when a member is scrolled
/// too far down to see the card that is waiting for them.
class WaitingPill extends StatelessWidget {
  const WaitingPill({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 18,
      child: Center(
        child: Material(
          color: IvoryColors.burgundy,
          borderRadius: BorderRadius.circular(30),
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 11, 18, 11),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const <Widget>[
                  Icon(Icons.arrow_upward_rounded,
                      size: 17, color: IvoryColors.gold),
                  SizedBox(width: 9),
                  Text(
                    'SOMETHING IS WAITING FOR YOU',
                    style: TextStyle(
                      fontSize: 11.5,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w800,
                      color: IvoryColors.cream,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// END OF FILE - lib/widgets/wish_guide.dart
