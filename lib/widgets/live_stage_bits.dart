import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';

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
class LiveAudioStage extends StatelessWidget {
  const LiveAudioStage({
    super.key,
    required this.heading,
    this.subtitle,
  });

  final String heading;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
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
          const SizedBox(height: 22),
          Text(
            heading,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: IvoryColors.ivory,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtitle != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              subtitle!,
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
class LiveMessage extends StatelessWidget {
  const LiveMessage(this.text, {super.key, this.isError = false});

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
            IconButton(
              tooltip: 'Send a gift',
              padding: EdgeInsets.zero,
              icon: const Text('\u{1F48C}', style: TextStyle(fontSize: 18)),
              onPressed: onGift,
            ),
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

/// The video stage. A broadcast shares the screen with the chat
/// rail so its frame is wider; a call keeps the full portrait
/// stage. A landscape camera is letterboxed onto warm cream,
/// never stretched and never onto black.
class LiveVideoStage {
  LiveVideoStage._();

  static Widget? build({
    required RtcEngine engine,
    required bool selfView,
    required int? remoteUid,
    required String channel,
    required bool portrait,
    required bool pipSelf,
  }) {
    final Widget? video = selfView
        ? AgoraVideoView(
            controller: VideoViewController(
              rtcEngine: engine,
              canvas: const VideoCanvas(uid: 0),
            ),
          )
        : (remoteUid == null
            ? null
            : AgoraVideoView(
                controller: VideoViewController.remote(
                  rtcEngine: engine,
                  canvas: VideoCanvas(uid: remoteUid),
                  connection: RtcConnection(channelId: channel),
                ),
              ));
    if (video == null) return null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: AspectRatio(
        aspectRatio: portrait ? 9 / 16 : 4 / 5,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Container(color: IvoryColors.surfaceWarm),
              video,
              if (pipSelf)
                Positioned(
                  right: 10,
                  top: 10,
                  width: 96,
                  height: 96 * 16 / 9,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AgoraVideoView(
                      controller: VideoViewController(
                        rtcEngine: engine,
                        canvas: const VideoCanvas(uid: 0),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// END OF FILE - lib/widgets/live_stage_bits.dart
