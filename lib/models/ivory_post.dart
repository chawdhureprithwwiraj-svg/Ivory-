import 'media_ref.dart';

enum PostType { video, audio, blog, image, poll, unknown }

PostType postTypeFromDb(String? v) {
  switch (v) {
    case 'video':
      return PostType.video;
    case 'audio':
      return PostType.audio;
    case 'blog':
      return PostType.blog;
    case 'image':
      return PostType.image;
    case 'poll':
      return PostType.poll;
    default:
      return PostType.unknown;
  }
}

extension PostTypeInfo on PostType {
  String get label {
    switch (this) {
      case PostType.video:
        return 'VIDEO';
      case PostType.audio:
        return 'AUDIO';
      case PostType.blog:
        return 'STORY';
      case PostType.image:
        return 'PHOTO';
      case PostType.poll:
        return 'POLL';
      case PostType.unknown:
        return 'POST';
    }
  }
}

/// A card in the storytelling feed.
///
/// Loaded from the `post_previews` view, which deliberately does NOT
/// contain media_ref or body. Those arrive only when the full post is
/// opened and the database confirms the user is entitled to it.
class IvoryPost {
  const IvoryPost({
    required this.id,
    required this.type,
    required this.title,
    required this.tierRequired,
    required this.isUnlocked,
    this.summary,
    this.body,
    this.tierName,
    this.durationSecs,
    this.viewCount = 0,
    this.createdAt,
    this.media = const MediaRef(source: MediaSource.none, ref: null),
    this.thumb = const MediaRef(source: MediaSource.none, ref: null),
    this.thumbnailUrl,
  });

  final int id;
  final PostType type;
  final String title;
  final String? summary;
  final String? body;
  final int tierRequired;
  final bool isUnlocked;
  final String? tierName;
  final int? durationSecs;
  final int viewCount;
  final DateTime? createdAt;
  final MediaRef media;
  final MediaRef thumb;
  final String? thumbnailUrl;

  bool get isPremium => tierRequired > 0;
  bool get isLocked => isPremium && !isUnlocked;

  /// mm:ss or h:mm:ss, or null when the post has no duration.
  String? get durationLabel {
    final int? s = durationSecs;
    if (s == null || s <= 0) return null;
    final int h = s ~/ 3600;
    final int m = (s % 3600) ~/ 60;
    final int sec = s % 60;
    final String two = sec.toString().padLeft(2, '0');
    if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:$two';
    return '$m:$two';
  }

  /// Best available thumbnail URL, falling back to YouTube's free
  /// auto-generated image when the post itself has none.
  String? thumbnailFor({String? supabasePublicBase}) {
    if (thumbnailUrl != null && thumbnailUrl!.startsWith('http')) {
      return thumbnailUrl;
    }
    final String? fromThumb =
        thumb.directUrl(supabasePublicBase: supabasePublicBase) ??
            thumb.youtubeThumbnail;
    if (fromThumb != null) return fromThumb;
    return media.youtubeThumbnail;
  }

  String get relativeTime {
    final DateTime? c = createdAt;
    if (c == null) return '';
    final Duration d = DateTime.now().difference(c);
    if (d.inDays > 365) return '${d.inDays ~/ 365}y ago';
    if (d.inDays > 30) return '${d.inDays ~/ 30}mo ago';
    if (d.inDays > 0) return '${d.inDays}d ago';
    if (d.inHours > 0) return '${d.inHours}h ago';
    if (d.inMinutes > 0) return '${d.inMinutes}m ago';
    return 'just now';
  }

  /// From the `post_previews` view (no media_ref, no body).
  factory IvoryPost.fromPreview(Map<String, dynamic> m) {
    return IvoryPost(
      id: (m['id'] as num).toInt(),
      type: postTypeFromDb(m['type'] as String?),
      title: (m['title'] as String?) ?? 'Untitled',
      summary: m['summary'] as String?,
      tierRequired: ((m['tier_required'] as num?) ?? 0).toInt(),
      isUnlocked: (m['is_unlocked'] as bool?) ?? false,
      tierName: m['tier_name'] as String?,
      durationSecs: (m['duration_secs'] as num?)?.toInt(),
      viewCount: ((m['view_count'] as num?) ?? 0).toInt(),
      createdAt: DateTime.tryParse((m['created_at'] as String?) ?? ''),
      thumb: MediaRef(
        source: MediaSource.fromDb(m['thumb_source'] as String?),
        ref: m['thumb_ref'] as String?,
      ),
      thumbnailUrl: m['thumbnail_url'] as String?,
    );
  }

  /// From the full `posts` table, fetched only when entitled.
  factory IvoryPost.fromFull(Map<String, dynamic> m) {
    final IvoryPost preview = IvoryPost.fromPreview(<String, dynamic>{
      ...m,
      'is_unlocked': true,
    });
    return IvoryPost(
      id: preview.id,
      type: preview.type,
      title: preview.title,
      summary: preview.summary,
      body: m['body'] as String?,
      tierRequired: preview.tierRequired,
      isUnlocked: true,
      tierName: preview.tierName,
      durationSecs: preview.durationSecs,
      viewCount: preview.viewCount,
      createdAt: preview.createdAt,
      media: MediaRef(
        source: MediaSource.fromDb(m['media_source'] as String?),
        ref: (m['media_ref'] as String?) ?? (m['media_url'] as String?),
      ),
      thumb: preview.thumb,
      thumbnailUrl: preview.thumbnailUrl,
    );
  }
}

/// One option in a poll, with its live vote count.
class PollOption {
  const PollOption({
    required this.id,
    required this.label,
    required this.votes,
  });

  final int id;
  final String label;
  final int votes;

  factory PollOption.fromMap(Map<String, dynamic> m) => PollOption(
        id: (m['option_id'] as num).toInt(),
        label: (m['label'] as String?) ?? '',
        votes: ((m['votes'] as num?) ?? 0).toInt(),
      );
}
