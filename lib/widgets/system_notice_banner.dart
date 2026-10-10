import 'package:flutter/material.dart';

import '../models/ivory_notification.dart';
import '../theme/ivory_theme.dart';

/// A brief in-app arrival signal for a new system notice.
///
/// The Inbox remains the only message destination. This banner is
/// transient: it auto-dismisses after ten seconds, while dismissing
/// it manually hides only the preview and never marks the notice read.
class SystemNoticeBanner extends StatelessWidget {
  const SystemNoticeBanner({
    super.key,
    required this.notice,
    required this.onOpenInbox,
    required this.onDismiss,
  });

  final IvoryNotification notice;
  final VoidCallback onOpenInbox;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[IvoryColors.cream, IvoryColors.surfaceWarm],
        ),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: IvoryColors.amber, width: 2),
        boxShadow: <BoxShadow>[
          ...IvoryTheme.softShadow(blur: 18, y: 6),
          BoxShadow(
            color: IvoryColors.gold.withValues(alpha: 0.24),
            blurRadius: 15,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 11, 7, 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: IvoryColors.goldGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.campaign_rounded,
                color: IvoryColors.burgundy,
                size: 21,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: InkWell(
                onTap: onOpenInbox,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'A NOTE FROM IVORY',
                        style: TextStyle(
                          color: IvoryColors.plum,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        notice.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: IvoryColors.burgundy,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        notice.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: IvoryColors.textSoft,
                          fontSize: 12.3,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'OPEN IN SANCTUARY INBOX',
                        style: TextStyle(
                          color: IvoryColors.burgundy,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Dismiss preview; keep notice unread',
              visualDensity: VisualDensity.compact,
              onPressed: onDismiss,
              icon: const Icon(
                Icons.close_rounded,
                color: IvoryColors.plum,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// END OF FILE - lib/widgets/system_notice_banner.dart
