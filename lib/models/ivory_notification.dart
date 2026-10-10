import 'package:flutter/material.dart';

/// One line in the Sanctuary Inbox.
class IvoryNotification {
  const IvoryNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.kind,
    required this.isRead,
    this.postId,
    this.actionTab,
    this.actionUrl,
    this.createdAt,
  });

  final int id;
  final String title;
  final String body;
  final String kind;
  final bool isRead;
  final int? postId;
  final String? actionTab;

  /// An optional picture, recording, video or link sent with the message.
  final String? actionUrl;
  final DateTime? createdAt;

  /// Plain owner/system notices receive priority treatment in the single Inbox.
  bool get isPriorityNotice => kind == 'system';

  factory IvoryNotification.fromMap(Map<String, dynamic> m) =>
      IvoryNotification(
        id: (m['id'] as num).toInt(),
        title: (m['title'] as String?) ?? '',
        body: (m['body'] as String?) ?? '',
        kind: (m['kind'] as String?) ?? 'system',
        isRead: (m['is_read'] as bool?) ?? false,
        postId: (m['post_id'] as num?)?.toInt(),
        actionTab: m['action_tab'] as String?,
        actionUrl: m['action_url'] as String?,
        createdAt: DateTime.tryParse((m['created_at'] as String?) ?? ''),
      );

  IconData get icon {
    switch (kind) {
      case 'video':
        return Icons.movie_creation_outlined;
      case 'audio':
        return Icons.graphic_eq;
      case 'blog':
      case 'story':
        return Icons.auto_stories_outlined;
      case 'poll':
        return Icons.how_to_vote_outlined;
      case 'wish':
        return Icons.auto_awesome;
      case 'payment':
        return Icons.verified_outlined;
      case 'live':
        return Icons.sensors;
      case 'post':
        return Icons.bookmark_border;
      default:
        return Icons.notifications_none;
    }
  }

  String get whenLabel {    final DateTime? c = createdAt;
    if (c == null) return '';
    final Duration d = DateTime.now().difference(c);
    if (d.inDays > 30) return '${d.inDays ~/ 30}mo ago';
    if (d.inDays > 0) return '${d.inDays}d ago';
    if (d.inHours > 0) return '${d.inHours}h ago';
    if (d.inMinutes > 0) return '${d.inMinutes}m ago';
    return 'just now';
  }
}

/// ============================================================
/// WHICH OFFER OF MORE TIME IS STILL THE REAL ONE.
///
/// Ivory may push an offer onto the screen whenever she likes,
/// and each one leaves its own message behind in the inbox. On
/// the owner's test two arrived a minute apart - thirty minutes
/// for one price, then eighty for another - and both sat there
/// afterwards wearing the same gold ring, both saying "open the
/// call to accept". Only one of them could possibly be real,
/// and nothing on either card said which.
///
/// Only the NEWEST offer for a session can stand. Every earlier
/// one has been replaced by definition, because a second offer
/// is Ivory changing her mind about the first.
///
/// This is decided here, from the messages themselves, rather
/// than asked of the database: the inbox already holds every
/// fact needed, and no price, payment or tier is touched by
/// reading it.
/// ============================================================
extension IvoryOfferMessages on IvoryNotification {
  /// An offer of more minutes, rather than any other message.
  /// Both halves are checked so that an unrelated message can
  /// never be dimmed by accident.
  bool get isTimeOffer =>
      title.toLowerCase().contains('more time') &&
      body.toLowerCase().contains('more minutes');
}

/// The ids of every offer that a later offer has replaced.
/// The newest is left out, because it is the one that stands.
Set<int> supersededOffers(List<IvoryNotification> all) {
  IvoryNotification? newest;
  for (final IvoryNotification n in all) {
    if (!n.isTimeOffer) continue;
    final DateTime? at = n.createdAt;
    if (at == null) continue;
    final DateTime? best = newest?.createdAt;
    if (best == null || at.isAfter(best)) newest = n;
  }
  if (newest == null) return <int>{};
  return all
      .where((IvoryNotification n) => n.isTimeOffer && n.id != newest!.id)
      .map((IvoryNotification n) => n.id)
      .toSet();
}

// END OF FILE - lib/models/ivory_notification.dart
