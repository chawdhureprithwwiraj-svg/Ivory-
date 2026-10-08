import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';

/// THE SHARED PIECES OF THE INSTRUCTIONS.
///
/// The instructions themselves live in ONE place -
/// `SessionGuideSheet` in sessions_panel.dart. What is here is
/// only the furniture: a numbered step, a list of them, and the
/// pill that carries a member back to the top of a page.
///
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
