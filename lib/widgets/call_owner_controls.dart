import 'package:flutter/material.dart';

import 'call_more_time.dart';
import 'live_stage_bits.dart';

/// The two buttons only the house ever sees inside a session:
/// MORE TIME and END SESSION.
///
/// Lifted out of the call screen when that file reached the size a
/// phone can comfortably paste. They belong together anyway - they
/// are the two decisions only she can make once a room is open.
class CallOwnerControls extends StatelessWidget {
  const CallOwnerControls({
    super.key,
    required this.callId,
    required this.premium,
    required this.onEnd,
  });

  final int callId;

  /// Which pair of default prices the offer box should open with.
  final bool premium;

  /// Closes the session for both sides. Unlike leaving, this is final.
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const SizedBox(width: 14),
        LiveRoundButton(
          icon: Icons.more_time_rounded,
          active: true,
          label: 'MORE TIME',
          onTap: () async {
            final bool sent = await showOfferMoreTime(
              context,
              callId: callId,
              premium: premium,
            );
            if (sent && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sent. It is on their screen now.'),
                ),
              );
            }
          },
        ),
        const SizedBox(width: 14),
        LiveRoundButton(
          icon: Icons.stop_circle_outlined,
          active: false,
          label: 'END SESSION',
          onTap: onEnd,
        ),
      ],
    );
  }
}

// END OF FILE - lib/widgets/call_owner_controls.dart
