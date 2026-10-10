import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';
import 'live_gift_button.dart';

// LIFTED, NOT TRIMMED.
//
// This file reached the paste ceiling, so the whole video
// stage moved out into `live_video_stage.dart` and is exported
// from here. **No call site changes.** Lift a responsibility;
// never shave comments to make room.
export 'live_video_stage.dart';

/// ============================================================
/// IVORY - PIECES OF THE LIVE ROOM
///
/// The live room screen had grown past the size a phone editor
/// can comfortably handle, so the three parts that only draw -
/// the audio panel, the centred message and the round control
/// button - were lifted out whole. Nothing here knows about
/// Agora, Supabase or the session; it is pure appearance.
/// ============================================================

/// The audio-only stage. A warm gold disc, never a dark
/// rectangle, because an audio call has nothing to show.
/// WHAT TO SAY ABOUT WHO IS IN THE ROOM.
///
/// Whoever arrives first used to see "Connecting..." and had no
/// way of telling whether the session was working, whether the
/// other person was late, or whether they had come to the wrong
/// place. On an audio session there is nothing on screen but
/// these words, so they are the entire experience of waiting.
///
/// One source for both surfaces, so the video screen and the
/// audio screen can never drift into saying different things.
class PresenceWords {
  const PresenceWords(this.heading, this.note);

  final String heading;
  final String? note;

  /// WHO THE OTHER PERSON IS, IN WORDS.
  ///
  /// On a one-to-one session both handsets run the same screen,
  /// so the side asking has to be told whether it is Ivory's own
  /// phone. When it is, the other person is the member, and we
  /// use the name already shown in the title bar rather than a
  /// flat "They" - being spoken to by name is the whole point of
  /// this room.
  static String other(bool host, String? name) {
    if (!host) return 'Ivory';
    final String n = (name ?? '').trim();
    return n.isEmpty ? 'They' : n;
  }

  /// "They have" but "Thea has" - the verb has to follow.
  static String _has(String who) => who == 'They' ? 'have' : 'has';

  /// "They are" but "Thea is".
  static String _is(String who) => who == 'They' ? 'are' : 'is';

  /// "Waiting for They" is not English. Only the bare pronoun
  /// needs the swap; a real name reads correctly as it stands.
  static String _forWhom(String who) => who == 'They' ? 'them' : who;

  /// Used by the live status line as well as the stage, so the
  /// two can never say different things about the same moment.
  static String steppedOutNote(bool host, [String? name]) {
    final String them = other(host, name);
    return '$them ${_has(them)} stepped out for some unavoidable '
        'reasons, may be back very soon.';
  }

  factory PresenceWords.of({
    required bool host,
    required bool present,
    required bool left,
    String? subtitle,
    String? name,
    bool broadcast = false,
    bool audience = false,
  }) {
    // THREE DIFFERENT ROOMS, THREE DIFFERENT VOICES.
    //
    // A BROADCAST is Ivory on air and everyone else watching.
    // She waits for nobody; they are not seen, not counted to
    // her, and not spoken to one by one.
    //
    // A SESSION is two people, each able to see that the other
    // has arrived.
    //
    // These must never borrow each other's words. Telling a
    // member of the audience "I can see that you are in" would
    // be a promise the broadcast cannot keep.
    if (broadcast) {
      return PresenceWords(
        'You are on air',
        'Your camera and microphone are open. Everyone who is '
            'entitled can see and hear you from this moment.',
      );
    }

    // Watching a broadcast. Nobody is waiting on this member,
    // and nothing is expected of them but to stay.
    if (audience) {
      return PresenceWords(
        left ? 'Ivory has stepped away' : 'Ivory is not on camera yet',
        left
            ? 'The broadcast is still open. Stay here - she can '
                'come straight back.'
            : 'You are in. The moment Ivory appears she will be '
                'here on this screen.',
      );
    }

    final String them = other(host, name);

    if (present) {
      return PresenceWords('$them ${_is(them)} here', subtitle);
    }
    if (left) {
      return PresenceWords(
        '$them ${_has(them)} stepped out',
        'for some unavoidable reasons, may be back very soon.',
      );
    }
    return PresenceWords(
      host ? 'Waiting for ${_forWhom(them)}' : 'Waiting for Ivory',
      host
          ? 'You are in. They will see that you are here the '
              'moment they come in.'
          : 'You are in, and I can see that. Stay on this screen '
              '- I will be with you.',
    );
  }
}

/// THE BOOKED TIME IS FINISHED - AND NOTHING HAPPENS.
///
/// The owner's standing instruction is that running out of
/// minutes must NEVER cut a call off. So this is a line of
/// text and nothing more: no countdown, no timer going red, no
/// button. The session carries on exactly as it was, and Ivory
/// has been nudged once, privately, to offer more time if she
/// wants to.
class TimeUpBar extends StatelessWidget {
  const TimeUpBar({super.key, required this.owner});

  final bool owner;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      color: IvoryColors.plum,
      child: Text(
        owner
            ? 'Past the booked time. Still running - offer more '
                'time, or close it when you are both done.'
            : 'Your booked time is finished. Nothing has been cut '
                'off - stay as long as Ivory is here.',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12.5,
          height: 1.45,
          fontWeight: FontWeight.w600,
          color: IvoryColors.cream,
        ),
      ),
    );
  }
}

class LiveAudioStage extends StatefulWidget {
  const LiveAudioStage({
    super.key,
    required this.heading,
    this.subtitle,
    this.pulse = false,
  });

  final String heading;
  final String? subtitle;
  final bool pulse;

  @override
  State<LiveAudioStage> createState() => _LiveAudioStageState();
}

class _LiveAudioStageState extends State<LiveAudioStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse();
  }

  @override
  void didUpdateWidget(covariant LiveAudioStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pulse != widget.pulse) _syncPulse();
  }

  void _syncPulse() {
    if (!widget.pulse || MediaQuery.of(context).disableAnimations) {
      _pulse.stop();
      _pulse.value = 0;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool motionOff = MediaQuery.of(context).disableAnimations;
    final String? stageSubtitle =
        widget.pulse ? 'Together, here' : widget.subtitle;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: 168,
            height: 168,
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (BuildContext context, Widget? child) {
                final bool animate = widget.pulse && !motionOff;
                final double breath = animate
                    ? Curves.easeInOutCubic.transform(_pulse.value)
                    : 0;
                return Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    if (animate)
                      Transform.scale(
                        scale: 1 + 0.25 * breath,
                        child: Container(
                          width: 132,
                          height: 132,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: IvoryColors.gold.withValues(
                                  alpha: 0.62 * (1 - breath)),
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                    Transform.scale(
                      scale: 1 + 0.10 * breath,
                      child: child,
                    ),
                  ],
                );
              },
              child: Container(
                width: 132,
                height: 132,
                decoration: BoxDecoration(
                  gradient: IvoryColors.goldGradient,
                  shape: BoxShape.circle,
                  boxShadow: IvoryTheme.softShadow(blur: 26, y: 10),
                ),
                child: const Icon(Icons.graphic_eq_rounded,
                    color: IvoryColors.burgundy, size: 58),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            widget.heading,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: IvoryColors.ivory,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (stageSubtitle != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              stageSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: IvoryColors.cream.withValues(alpha: 0.8),
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A centred sentence in the middle of the stage. A spinner
/// while something is still happening, a quiet mark when it is
/// news rather than progress.
class LiveNotice extends StatelessWidget {
  const LiveNotice(this.text, {super.key, this.isError = false});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (!isError)
            const CircularProgressIndicator(
                color: IvoryColors.gold, strokeWidth: 2.4)
          else
            const Icon(Icons.info_outline_rounded,
                color: IvoryColors.gold, size: 40),
          const SizedBox(height: 18),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: IvoryColors.cream.withValues(alpha: 0.92),
              fontSize: 14.5,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

/// One round control at the foot of the room: microphone,
/// camera, flip, leave.
class LiveRoundButton extends StatelessWidget {
  const LiveRoundButton({
    super.key,
    required this.icon,
    required this.active,
    required this.onTap,
    this.danger = false,
    this.label,
  });

  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final bool danger;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final Widget button = InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          gradient: danger ? null : IvoryColors.goldGradient,
          color: danger ? IvoryColors.plum : null,
          shape: BoxShape.circle,
          border: Border.all(
            color: active ? IvoryColors.gold : IvoryColors.cream,
            width: active ? 0 : 1.4,
          ),
        ),
        child: Icon(
          icon,
          color: danger ? IvoryColors.cream : IvoryColors.burgundy,
          size: 25,
        ),
      ),
    );

    if (label == null) return button;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        button,
        const SizedBox(height: 6),
        Text(
          label!,
          style: TextStyle(
            color: IvoryColors.cream.withValues(alpha: 0.85),
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

/// The strip across the top of the room: the clock, the gift
/// button, the title, and the way out.
class LiveTopBar extends StatelessWidget {
  const LiveTopBar({
    super.key,
    required this.title,
    required this.clock,
    required this.showClock,
    required this.clockPrefix,
    required this.onClose,
    this.onGift,
    this.note,
  });

  final String title;
  final String clock;
  final bool showClock;
  final String clockPrefix;
  final VoidCallback onClose;
  final VoidCallback? onGift;
  final String? note;

  /// THE WHOLE TOP STRIP, DECIDED IN ONE PLACE.
  ///
  /// Which parts of the strip appear depends only on what kind
  /// of room this is and whether it is still running, so the
  /// decisions belong beside the thing being drawn rather than
  /// scattered through the screen.
  static Widget forRoom({
    required String title,
    required String clock,
    required bool live,
    required bool isCall,
    required bool hosting,
    required bool watching,
    required VoidCallback onClose,
    VoidCallback? onGift,
  }) {
    return LiveTopBar(
      title: title,
      clock: clock,
      showClock: live,
      clockPrefix: isCall ? '' : 'LIVE  ',
      note: hosting && live ? 'Only you see this count' : null,
      // Gifts belong to a broadcast, where the room is watching
      // together. In a one-to-one session they were only ever
      // decoration, and they did nothing when tapped.
      onGift: live && watching ? onGift : null,
      onClose: onClose,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      child: Row(
        children: <Widget>[
          if (showClock) ...<Widget>[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                gradient: IvoryColors.goldGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$clockPrefix$clock',
                style: const TextStyle(
                  color: IvoryColors.burgundy,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          if (onGift != null) ...<Widget>[
            LiveGiftButton(onPressed: onGift!),
            const SizedBox(width: 2),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: IvoryColors.ivory,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (note != null)
                  Text(
                    note!,
                    style: TextStyle(
                      color: IvoryColors.cream.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, color: IvoryColors.ivory),
          ),
        ],
      ),
    );
  }
}

/// Asks before the one action in a call that cannot be undone.
/// Leaving keeps the room open; this does not.
Future<bool> confirmEndSession(BuildContext context) async {
  final bool? sure = await showDialog<bool>(
    context: context,
    builder: (BuildContext c) => AlertDialog(
      backgroundColor: IvoryColors.surface,
      title: const Text('End this session?'),
      content: const Text(
        'This closes the call for both of you and the remaining '
        'minutes are used up. Leaving instead keeps the room open, '
        'so either of you can come back.',
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(c).pop(false),
          child: const Text('Keep it open'),
        ),
        TextButton(
          onPressed: () => Navigator.of(c).pop(true),
          child: const Text('End session'),
        ),
      ],
    ),
  );
  return sure == true;
}
// END OF FILE - lib/widgets/live_stage_bits.dart
