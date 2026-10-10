import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';

/// ============================================================
/// IVORY - HOW A BROADCAST IS ARRANGED ON THE GLASS.
///
/// Lifted out of `live_screen.dart`, which had reached the size
/// ceiling with twenty bytes to spare. **Lift a whole
/// responsibility, never shave comments.** The responsibility
/// lifted here is one honest question: how much of the screen
/// belongs to her picture and how much to the conversation.
///
/// THE OLD ARRANGEMENT WAS A COLUMN, AND IT HAD ONE FLAW.
/// The stage took the height it wanted and the conversation got
/// whatever was left. That is fine until the keyboard opens -
/// and then the keyboard eats the leftovers, the picture does
/// not move an inch, and the member is typing into a letterbox
/// three lines tall. **The thing that shrank was the only thing
/// they were looking at.**
///
/// THE REFINED ARRANGEMENT.
///   * The conversation FLOATS over a short, capped lower rail
///     rather than covering nearly half the picture.
///   * **When the keyboard opens, the rail grows only to a
///     measured cap.** The composer remains usable, but most of
///     the video stays visible behind it.
///   * Ivory's own line keeps its gold name/accent and a quiet
///     burgundy backing, but becomes a compact callout instead
///     of a full-width slab. Member messages and reporting stay.
///   * A soft, translucent fall helps the words read against
///     the picture without turning it into a burgundy panel.
///
/// NOTHING SNAPS. The stage EASES between its two heights over
/// 260 ms. A picture that jumped would be worse than the
/// letterbox it replaced.
///
/// A CALL IS NOT A BROADCAST AND IS NOT ARRANGED HERE AT ALL -
/// a call has no chat, because the two of you are already
/// talking.
/// ============================================================
class LiveRoomBody extends StatelessWidget {
  const LiveRoomBody({
    super.key,
    required this.bar,
    required this.stage,
    required this.controls,
    this.chat,
    this.isCall = false,
  });

  final Widget bar;
  final Widget stage;
  final Widget controls;

  /// Null on a call, and null once a broadcast has ended -
  /// leaving a writing box on an ended broadcast invited
  /// members to type into somewhere nobody was listening.
  final Widget? chat;

  final bool isCall;

  @override
  Widget build(BuildContext context) {
    if (isCall || chat == null) {
      return Column(
        children: <Widget>[
          bar,
          Expanded(child: Center(child: stage)),
          controls,
        ],
      );
    }

    final bool typing = MediaQuery.of(context).viewInsets.bottom > 80;

    return Column(
      children: <Widget>[
        bar,
        Expanded(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints box) {
              // THE PICTURE TAKES EVERYTHING.
              //
              // It used to be given a share of the height, and
              // inside that share it was locked to a 4:5 box -
              // so she ended up as a small square with dead
              // space all round it while the words sat below.
              // Now the broadcast fills the whole room and the
              // conversation lies ON it. There is nothing left
              // over to waste.
              //
              // The keyboard may give the rail a little more room,
              // but the rail is capped. It must never expand over
              // most of the picture. Ivory's compact, gold-marked
              // line remains distinct without becoming a burgundy slab.
              // Keep the video visibly present beneath the chat; the
              // veil stays translucent enough to show it through.
              final double proportionalHeight =
                  box.maxHeight * (typing ? 0.62 : 0.30);
              final double heightCap = typing ? 360 : 270;
              final double chatHeight = proportionalHeight < heightCap
                  ? proportionalHeight
                  : heightCap;
              return Stack(
                children: <Widget>[
                  Positioned.fill(child: stage),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: chatHeight,
                    child: _Veiled(child: chat!),
                  ),
                ],
              );
            },
          ),
        ),
        controls,
      ],
    );
  }
}

/// The soft fall where the picture becomes the conversation.
class _Veiled extends StatelessWidget {
  const _Veiled({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            IvoryColors.burgundy.withValues(alpha: 0),
            IvoryColors.burgundy.withValues(alpha: 0.16),
            IvoryColors.burgundy.withValues(alpha: 0.42),
          ],
          stops: const <double>[0, 0.22, 0.56],
        ),
      ),
      child: child,
    );
  }
}

// END OF FILE - lib/widgets/live_room_body.dart
