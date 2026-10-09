import 'package:flutter/material.dart';

import 'call_owner_controls.dart';
import 'live_stage_bits.dart';

/// ============================================================
/// THE ROW OF BUTTONS AT THE FOOT OF A LIVE ROOM.
///
/// Lifted out of live_screen.dart, which had grown past the
/// size that can be pasted reliably on a phone. Nothing about
/// it changed in the move.
///
/// It owns no state of its own. Every button reports upwards
/// and the screen decides - which is why the microphone can
/// never disagree with the engine that is actually muted.
/// ============================================================
class LiveControls extends StatelessWidget {
  const LiveControls({
    super.key,
    required this.visible,
    required this.publishes,
    required this.videoEnabled,
    required this.micOn,
    required this.speakerOn,
    required this.camOn,
    required this.isCall,
    required this.isOwner,
    required this.callId,
    required this.premium,
    required this.onToggleMic,
    required this.onToggleSpeaker,
    required this.onToggleCam,
    required this.onSwitchCamera,
    required this.onLeave,
    required this.onEnd,
  });

  final bool visible;
  final bool publishes;
  final bool videoEnabled;
  final bool micOn;
  final bool speakerOn;
  final bool camOn;
  final bool isCall;
  final bool isOwner;
  final int callId;
  final bool premium;

  final VoidCallback onToggleMic;
  final VoidCallback onToggleSpeaker;
  final VoidCallback onToggleCam;
  final VoidCallback onSwitchCamera;
  final VoidCallback onLeave;
  final Future<void> Function() onEnd;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox(height: 28);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (publishes)
            LiveRoundButton(
              icon: micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
              active: micOn,
              onTap: onToggleMic,
            ),
          // An audio session is held against the ear or across a
          // room, and nothing on screen let them choose. A video
          // call is already loudspeaker by its nature.
          if (publishes && !videoEnabled) ...<Widget>[
            const SizedBox(width: 14),
            LiveRoundButton(
              icon: speakerOn
                  ? Icons.volume_up_rounded
                  : Icons.hearing_rounded,
              active: speakerOn,
              onTap: onToggleSpeaker,
            ),
          ],
          if (publishes && videoEnabled) ...<Widget>[
            const SizedBox(width: 14),
            LiveRoundButton(
              icon: camOn
                  ? Icons.videocam_rounded
                  : Icons.videocam_off_rounded,
              active: camOn,
              onTap: onToggleCam,
            ),
            const SizedBox(width: 14),
            LiveRoundButton(
              icon: Icons.cameraswitch_rounded,
              active: true,
              onTap: onSwitchCamera,
            ),
          ],
          const SizedBox(width: 14),
          LiveRoundButton(
            icon: Icons.call_end_rounded,
            active: true,
            danger: true,
            label: isCall ? 'LEAVE' : null,
            onTap: onLeave,
          ),
          if (isCall && isOwner)
            CallOwnerControls(
              callId: callId,
              premium: premium,
              onEnd: onEnd,
            ),
        ],
      ),
    );
  }
}

// END OF FILE - lib/widgets/live_controls.dart
