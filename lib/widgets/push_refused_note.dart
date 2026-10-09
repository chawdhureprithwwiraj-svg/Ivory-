import 'package:flutter/material.dart';

import '../services/push_service.dart';
import '../theme/ivory_theme.dart';

/// ============================================================
/// WHY YOUR PHONE HAS GONE QUIET.
///
/// If a member taps "Don't allow" on the notification request -
/// or taps it away by accident, which is more common - Ivory
/// can never reach their phone again. Every reminder, every
/// confirmed session, every answer from the house arrives only
/// if they happen to open the app.
///
/// Until now that answer went to the debug log and nowhere
/// else. The member was simply left wondering.
///
/// This says so plainly, and tells them the one place it can
/// be undone. It cannot be fixed from inside the app - Android
/// only lets the system Settings grant it - so the words have
/// to do the work.
/// ============================================================
class PushRefusedNote extends StatelessWidget {
  const PushRefusedNote({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: PushService.refused,
      builder: (BuildContext context, bool refused, _) {
        if (!refused) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: IvoryColors.surfaceWarm,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: IvoryColors.amber, width: 1.4),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(Icons.notifications_off_rounded,
                  size: 20, color: IvoryColors.plum),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Your phone will stay quiet',
                      style: TextStyle(
                        fontFamily: IvoryTheme.displayFont,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: IvoryColors.burgundy,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Notifications are switched off for Ivory, so a '
                      'confirmed session, a reminder before it starts, '
                      'or an answer from the house will only reach you '
                      'when you open the app yourself.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.55,
                        color: IvoryColors.textSoft,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      'To turn them back on: your phone Settings, then '
                      'Apps, then Ivory, then Notifications. It cannot '
                      'be done from in here.',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.5,
                        fontWeight: FontWeight.w700,
                        color: IvoryColors.plum,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// END OF FILE - lib/widgets/push_refused_note.dart
