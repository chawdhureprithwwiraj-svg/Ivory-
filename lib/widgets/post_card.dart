import 'package:flutter/material.dart';

import '../models/ivory_post.dart';
import '../theme/ivory_theme.dart';
import 'poll_card.dart';
import 'post_artwork.dart';

/// A story card in the Ivory Golden Edition style: a near-white card
/// with a hairline gold border, a tall image, a category pill and an
/// Unlocked / Members-only badge. Locked posts blur behind a gold lock.
class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.onTap,
    this.featured = false,
  });

  final IvoryPost post;
  final VoidCallback onTap;

  /// The big "Editor's Golden Reserve" treatment: taller image with the
  /// title laid over it.
  final bool featured;

  @override
  Widget build(BuildContext context) {
    // SPRINT 24i - a poll is not a post with a missing picture. It gets
    // its own card: badge, question, and votable bars. Everything below
    // this line is for posts that carry media.
    if (post.type == PostType.poll) {
      return PollCard(post: post, onTap: onTap);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Container(
            decoration: IvoryTheme.card(highlighted: featured, radius: 22),
            clipBehavior: Clip.antiAlias,
            child: featured ? _featuredBody(context) : _standardBody(context),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  // Featured: title sits over the artwork, details underneath.
  // ---------------------------------------------------------------
  Widget _featuredBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Stack(
          children: <Widget>[
            if (post.type == PostType.poll)
              const SizedBox(height: 56)
            else
              PostArtwork(post: post, maxHeight: 470),
            Positioned(
              left: 14,
              top: 14,
              child: _TypePill(type: post.type),
            ),
            Positioned(
              right: 14,
              top: 14,
              child: _StatePill(post: post),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    post.title.replaceFirst('[SAMPLE] ', ''),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: IvoryTheme.displayFont,
                      color: IvoryColors.cream,
                      fontSize: 22,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (post.summary != null) ...<Widget>[
                    const SizedBox(height: 6),
                    Text(
                      post.summary!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: IvoryColors.cream.withValues(alpha: 0.9),
                        fontSize: 13.5,
                        height: 1.45,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
          child: Row(
            children: <Widget>[
              Text(
                'Ivory',
                style: TextStyle(
                  color: IvoryColors.textSoft,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              _dot(),
              Text(
                post.relativeTime,
                style: TextStyle(color: IvoryColors.textFaint, fontSize: 12.5),
              ),
              if (post.viewCount > 0) ...<Widget>[
                _dot(),
                Text(
                  '${post.viewCount} views',
                  style:
                      TextStyle(color: IvoryColors.textFaint, fontSize: 12.5),
                ),
              ],
              const Spacer(),
              Text(
                post.isLocked ? 'Unlock' : _actionLabel(post.type),
                style: const TextStyle(
                  color: IvoryColors.plum,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward, size: 15, color: IvoryColors.plum),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------
  // Standard card.
  // ---------------------------------------------------------------
  Widget _standardBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Stack(
          children: <Widget>[
            if (post.type == PostType.poll)
              const SizedBox(height: 52)
            else
              PostArtwork(post: post, maxHeight: 360),
            Positioned(left: 12, top: 12, child: _TypePill(type: post.type)),
            Positioned(right: 12, top: 12, child: _StatePill(post: post)),
            if (post.durationLabel != null)
              Positioned(
                right: 12,
                bottom: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: IvoryColors.burgundy.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    post.durationLabel!,
                    style: const TextStyle(
                      color: IvoryColors.cream,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                post.title.replaceFirst('[SAMPLE] ', ''),
                style: const TextStyle(
                  fontFamily: IvoryTheme.displayFont,
                  color: IvoryColors.burgundy,
                  fontSize: 18,
                  height: 1.28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (post.summary != null &&
                  post.summary!.trim().isNotEmpty) ...<Widget>[
                const SizedBox(height: 7),
                Text(
                  post.summary!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: IvoryColors.textSoft,
                    fontSize: 13.5,
                    height: 1.48,
                  ),
                ),
              ],
              const SizedBox(height: 13),
              Divider(color: IvoryColors.hairline, height: 1),
              const SizedBox(height: 11),
              Row(
                children: <Widget>[
                  Text(
                    post.relativeTime,
                    style: TextStyle(
                      color: IvoryColors.textFaint,
                      fontSize: 12.5,
                    ),
                  ),
                  if (post.viewCount > 0) ...<Widget>[
                    _dot(),
                    Text(
                      '${post.viewCount} views',
                      style: TextStyle(
                        color: IvoryColors.textFaint,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    post.isLocked ? 'Unlock' : _actionLabel(post.type),
                    style: const TextStyle(
                      color: IvoryColors.plum,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward,
                      size: 15, color: IvoryColors.plum),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _dot() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7),
        child: Text('·', style: TextStyle(color: IvoryColors.textFaint)),
      );

  static IconData actionIcon(PostType t) {
    switch (t) {
      case PostType.video:
        return Icons.play_arrow_rounded;
      case PostType.audio:
        return Icons.headphones;
      case PostType.blog:
        return Icons.menu_book;
      case PostType.image:
        return Icons.image_outlined;
      case PostType.poll:
        return Icons.how_to_vote_outlined;
      case PostType.unknown:
        return Icons.open_in_new;
    }
  }

  static String _actionLabel(PostType t) {
    switch (t) {
      case PostType.video:
        return 'Watch';
      case PostType.audio:
        return 'Listen';
      case PostType.blog:
        return 'Read';
      case PostType.image:
        return 'View';
      case PostType.poll:
        return 'Vote';
      case PostType.unknown:
        return 'Open';
    }
  }
}


class _TypePill extends StatelessWidget {
  const _TypePill({required this.type});

  final PostType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: IvoryColors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: IvoryColors.hairlineStrong),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(PostCard.actionIcon(type), size: 13, color: IvoryColors.plum),
          const SizedBox(width: 5),
          Text(
            type.label,
            style: const TextStyle(
              color: IvoryColors.burgundy,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Unlocked" in soft green, or a gold "Tier N" badge.
class _StatePill extends StatelessWidget {
  const _StatePill({required this.post});

  final IvoryPost post;

  @override
  Widget build(BuildContext context) {
    final List<int>? at = post.allowedTiers;
    final String lockLabel = at == null
        ? 'TIER ${post.tierRequired}'
        : at.isEmpty
            ? 'PAY TO OPEN'
            : 'TIER ' + at.join(' · ');
    if (post.isLocked) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          gradient: IvoryColors.goldGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.lock, size: 11, color: IvoryColors.burgundy),
            const SizedBox(width: 4),
            Text(
              lockLabel,
              style: const TextStyle(
                color: IvoryColors.burgundy,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: IvoryColors.success.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Unlocked',
        style: TextStyle(
          color: IvoryColors.cream,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// END OF FILE - lib/widgets/post_card.dart
