import 'package:flutter/material.dart';

import '../models/ivory_notification.dart';
import '../theme/ivory_theme.dart';

/// One Inbox row. Unread system notices use a pinned, priority treatment;
/// ordinary notices keep the shared card style.
class InboxNotificationTile extends StatelessWidget {
  const InboxNotificationTile({
    super.key,
    required this.item,
    required this.onTap,
    this.onLongPress,
    this.priority = false,
    this.superseded = false,
    this.showAttachment = false,
  });

  final IvoryNotification item;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool priority;

  /// An offer of more time that a later offer has replaced.
  final bool superseded;
  final bool showAttachment;

  @override
  Widget build(BuildContext context) {
    // A replaced offer must never wear the gold ring of
    // something waiting to be acted on.
    final bool unread = !item.isRead && !superseded;
    final BoxDecoration cardDecoration = priority
        ? BoxDecoration(
            gradient: IvoryColors.cardGradient,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: IvoryColors.amber, width: 2.2),
            boxShadow: <BoxShadow>[
              ...IvoryTheme.softShadow(blur: 20, y: 8),
              BoxShadow(
                color: IvoryColors.gold.withValues(alpha: 0.22),
                blurRadius: 14,
              ),
            ],
          )
        : IvoryTheme.card(highlighted: unread, radius: 18);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            padding: const EdgeInsets.fromLTRB(15, 15, 15, 15),
            decoration: cardDecoration,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: priority
                        ? null
                        : (unread ? IvoryColors.goldGradient : null),
                    color: priority
                        ? IvoryColors.burgundy
                        : (unread ? null : IvoryColors.surfaceWarm),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    priority ? Icons.campaign_rounded : item.icon,
                    size: 20,
                    color: priority ? IvoryColors.gold : IvoryColors.burgundy,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (priority) ...<Widget>[
                        Row(
                          children: <Widget>[
                            const Icon(
                              Icons.push_pin_rounded,
                              size: 13,
                              color: IvoryColors.plum,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'A NOTE FROM IVORY',
                              style: TextStyle(
                                color: IvoryColors.plum,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                color: IvoryColors.burgundy,
                                fontSize: 15,
                                fontWeight: unread
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                          if (unread)
                            Container(
                              width: 9,
                              height: 9,
                              decoration: const BoxDecoration(
                                color: IvoryColors.amber,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      // WHICH OFFER IS THE REAL ONE.
                      //
                      // Two offers arrived a minute apart and
                      // both said "open the call to accept".
                      // Only the newest can stand, so the older
                      // one says so in plain words rather than
                      // leaving her member to guess at a price.
                      if (superseded) ...<Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: IvoryColors.surfaceWarm,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Ivory has since sent a newer offer. '
                            'This one no longer stands.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              fontWeight: FontWeight.w700,
                              color: IvoryColors.plum,
                            ),
                          ),
                        ),
                        const SizedBox(height: 7),
                      ],
                      Text(
                        item.body,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.45,
                          color: superseded
                              ? IvoryColors.textFaint
                              : IvoryColors.textSoft,
                        ),
                      ),
                      if (showAttachment &&
                          item.actionUrl != null &&
                          item.actionUrl!.trim().isNotEmpty) ...<Widget>[
                        const SizedBox(height: 10),
                        InboxAttachment(url: item.actionUrl!.trim()),
                      ],
                      const SizedBox(height: 7),
                      Text(
                        item.whenLabel,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: IvoryColors.textFaint,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// What an attachment looks like inside a message: pictures show
/// themselves, everything else becomes a gold "open" strip.
class InboxAttachment extends StatelessWidget {
  const InboxAttachment({super.key, required this.url});

  final String url;

  bool get _isImage {
    final String u = url.toLowerCase().split('?').first;
    return u.endsWith('.jpg') ||
        u.endsWith('.jpeg') ||
        u.endsWith('.png') ||
        u.endsWith('.webp') ||
        u.endsWith('.gif');
  }

  bool get _isAudio {
    final String u = url.toLowerCase().split('?').first;
    return u.endsWith('.mp3') ||
        u.endsWith('.m4a') ||
        u.endsWith('.aac') ||
        u.endsWith('.wav') ||
        u.endsWith('.ogg') ||
        u.endsWith('.opus');
  }

  bool get _isVideo {
    final String u = url.toLowerCase().split('?').first;
    return u.endsWith('.mp4') || u.endsWith('.mov') || u.endsWith('.webm');
  }

  @override
  Widget build(BuildContext context) {
    if (_isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: IvoryColors.hairline),
          ),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            height: 168,
            width: double.infinity,
            errorBuilder: (BuildContext c, Object e, StackTrace? st) =>
                _strip(Icons.image_outlined, 'Open the picture'),
            loadingBuilder: (BuildContext c, Widget child, ImageChunkEvent? p) {
              if (p == null) return child;
              return Container(
                height: 168,
                alignment: Alignment.center,
                color: IvoryColors.surfaceWarm,
                child: const CircularProgressIndicator(
                  color: IvoryColors.amber,
                  strokeWidth: 2,
                ),
              );
            },
          ),
        ),
      );
    }
    if (_isAudio) return _strip(Icons.play_circle_fill, 'Play the recording');
    if (_isVideo) return _strip(Icons.movie_outlined, 'Watch the video');
    return _strip(Icons.open_in_new, 'Open the attachment');
  }

  Widget _strip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: <Color>[Color(0xFFFFFCF2), Color(0xFFFDF1DC)],
          ),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: IvoryColors.hairlineStrong),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 18, color: IvoryColors.plum),
            const SizedBox(width: 9),
            Text(
              label,
              style: const TextStyle(
                color: IvoryColors.burgundy,
                fontSize: 12.8,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, size: 18, color: IvoryColors.plum),
          ],
        ),
      );
}

// END OF FILE - lib/widgets/inbox_notification_tile.dart
