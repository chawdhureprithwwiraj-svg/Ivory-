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
/// THE NEW ARRANGEMENT.
///   * The conversation FLOATS over the lower part of the
///     picture instead of being parked below it, so the words
///     and her face occupy the same screen rather than
///     competing for it.
///   * **When the keyboard opens, the PICTURE gives up the
///     room, not the conversation.** The stage eases down, the
///     words keep their height. That is the correct trade: a
///     member who is typing is reading, not staring.
///   * A soft fall of ivory sits where the picture meets the
///     words, so the one dissolves into the other. A hard edge
///     between a face and a list of text looks like two apps
///     stacked on top of each other.
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
              // The words keep their height when the keyboard
              // opens; it is the picture behind them that gives
              // way, because the keyboard has already taken the
              // room from the bottom. A member who is typing is
              // reading, not staring.
              // Keep the video visibly present beneath the chat.
              // The rail still has room for words, but its veil must
              // not turn the lower half into a solid burgundy panel.
              final double chatHeight =
                  box.maxHeight * (typing ? 0.76 : 0.42);
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
            IvoryColors.burgundy.withValues(alpha: 0.30),
            IvoryColors.burgundy.withValues(alpha: 0.62),
          ],
          stops: const <double>[0, 0.18, 0.48],
        ),
      ),
      child: child,
    );
  }
}

// END OF FILE - lib/widgets/live_room_body.dart
