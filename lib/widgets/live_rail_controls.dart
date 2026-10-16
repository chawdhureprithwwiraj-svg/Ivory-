import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';

/// The few buttons Ivory and a co-host still need during a broadcast: mic,
/// camera, flip camera (or speaker for audio only). They float in a slim
/// column at the right edge just above the chat, so the chat can sit at the
/// very bottom of the screen. Viewers who are not speaking see nothing here.
///
/// There is deliberately NO red leave button: the X in the top corner already
/// leaves the room. A co-host gets one small "step down" button instead,
/// because that is different from leaving: it returns them to the audience.
class LiveRailControls extends StatelessWidget {
  const LiveRailControls({
    super.key,
    required this.visible,
    required this.publishes,
    required this.videoEnabled,
    required this.micOn,
    required this.speakerOn,
    required this.camOn,
    required this.canStepDown,
    required this.onToggleMic,
    required this.onToggleSpeaker,
    required this.onToggleCam,
    required this.onSwitchCamera,
    required this.onStepDown,
  });

  final bool visible;
  final bool publishes;
  final bool videoEnabled;
  final bool micOn;
  final bool speakerOn;
  final bool camOn;
  final bool canStepDown;
  final VoidCallback onToggleMic;
  final VoidCallback onToggleSpeaker;
  final VoidCallback onToggleCam;
  final VoidCallback onSwitchCamera;
  final VoidCallback onStepDown;

  @override
  Widget build(BuildContext context) {
    if (!visible || !publishes) return const SizedBox.shrink();
    final List<Widget> buttons = <Widget>[
      _RailButton(
        icon: micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
        active: micOn,
        onTap: onToggleMic,
      ),
      if (!videoEnabled)
        _RailButton(
          icon: speakerOn ? Icons.volume_up_rounded : Icons.hearing_rounded,
          active: speakerOn,
          onTap: onToggleSpeaker,
        ),
      if (videoEnabled) ...<Widget>[
        _RailButton(
          icon: camOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
          active: camOn,
          onTap: onToggleCam,
        ),
        _RailButton(
          icon: Icons.cameraswitch_rounded,
          active: true,
          onTap: onSwitchCamera,
        ),
      ],
      if (canStepDown)
        _RailButton(
          icon: Icons.logout_rounded,
          active: true,
          danger: true,
          label: 'STEP DOWN',
          onTap: onStepDown,
        ),
    ];
    final List<Widget> spaced = <Widget>[];
    for (int i = 0; i < buttons.length; i++) {
      if (i > 0) spaced.add(const SizedBox(height: 10));
      spaced.add(buttons[i]);
    }
    return Column(mainAxisSize: MainAxisSize.min, children: spaced);
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({
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
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: danger ? null : IvoryColors.goldGradient,
          color: danger ? IvoryColors.plum : null,
          shape: BoxShape.circle,
          border: Border.all(
            color: danger
                ? IvoryColors.gold
                : (active ? IvoryColors.gold : IvoryColors.cream),
            width: danger ? 1.2 : (active ? 0 : 1.4),
          ),
          boxShadow: IvoryTheme.softShadow(blur: 8, y: 2),
        ),
        child: Icon(
          icon,
          color: danger ? IvoryColors.cream : IvoryColors.burgundy,
          size: 22,
        ),
      ),
    );
    if (label == null) return button;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        button,
        const SizedBox(height: 3),
        Text(
          label!,
          style: TextStyle(
            color: IvoryColors.cream,
            fontSize: 8.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            shadows: <Shadow>[
              Shadow(
                color: IvoryColors.burgundy.withValues(alpha: 0.95),
                blurRadius: 5,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// END OF FILE - lib/widgets/live_rail_controls.dart
