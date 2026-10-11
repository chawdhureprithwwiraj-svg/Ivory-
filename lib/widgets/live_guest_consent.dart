import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';

Future<bool> askLiveGuestConsent(
  BuildContext context, {
  required String title,
  required bool video,
}) async {
  final bool? agreed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) => AlertDialog(
      backgroundColor: IvoryColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(
        video ? 'Join on video?' : 'Join on audio?',
        style: TextStyle(
          fontFamily: IvoryTheme.displayFont,
          fontWeight: FontWeight.w700,
          color: IvoryColors.burgundy,
        ),
      ),
      content: Text(
        'You will join “$title” as a guest. Everyone watching this live '
        'broadcast can hear you${video ? ' and see your video' : ''}. '
        '${video ? 'You can turn your camera off and stay on audio.' : 'You will join on audio only.'} '
        'Ready to join?', 
        style: TextStyle(color: IvoryColors.textSoft, height: 1.5),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('NOT NOW'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('JOIN BROADCAST'),
        ),
      ],
    ),
  );
  return agreed == true;
}

// END OF FILE - lib/widgets/live_guest_consent.dart
