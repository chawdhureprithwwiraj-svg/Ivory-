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
    this.createdAt,
  });

  final int id;
  final String title;
  final String body;
  final String kind;
  final bool isRead;
  final int? postId;
  final String? actionTab;
  final DateTime? createdAt;

  factory IvoryNotification.fromMap(Map<String, dynamic> m) =>
      IvoryNotification(
        id: (m['id'] as num).toInt(),
        title: (m['title'] as String?) ?? '',
        body: (m['body'] as String?) ?? '',
        kind: (m['kind'] as String?) ?? 'system',
        isRead: (m['is_read'] as bool?) ?? false,
        postId: (m['post_id'] as num?)?.toInt(),
        actionTab: m['action_tab'] as String?,
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

  String get whenLabel {
    final DateTime? c = createdAt;
    if (c == null) return '';
    final Duration d = DateTime.now().difference(c);
    if (d.inDays > 30) return '${d.inDays ~/ 30}mo ago';
    if (d.inDays > 0) return '${d.inDays}d ago';
    if (d.inHours > 0) return '${d.inHours}h ago';
    if (d.inMinutes > 0) return '${d.inMinutes}m ago';
    return 'just now';
  }
}
