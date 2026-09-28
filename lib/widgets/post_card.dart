import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/ivory_post.dart';
import '../theme/ivory_theme.dart';

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
            _Artwork(post: post, height: 230),
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
            _Artwork(post: post, height: 172),
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

/// The image area, including the blurred treatment for locked posts and
/// a warm typographic panel when a post has no artwork at all.
class _Artwork extends StatelessWidget {
  const _Artwork({required this.post, required this.height});

  final IvoryPost post;
  final double height;

  @override
  Widget build(BuildContext context) {
    final String? url = post.thumbnailFor();

    final Widget base = url == null
        ? Container(
            height: height,
            width: double.infinity,
            decoration: const BoxDecoration(gradient: IvoryColors.warmGradient),
            child: Center(
              child: Icon(
                PostCard.actionIcon(post.type),
                size: 44,
                color: IvoryColors.burgundy.withValues(alpha: 0.55),
              ),
            ),
          )
        : Image.network(
            url,
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: height,
              decoration:
                  const BoxDecoration(gradient: IvoryColors.warmGradient),
              child: Center(
                child: Icon(
                  PostCard.actionIcon(post.type),
                  size: 40,
                  color: IvoryColors.burgundy.withValues(alpha: 0.5),
                ),
              ),
            ),
            loadingBuilder: (BuildContext c, Widget child, ImageChunkEvent? p) {
              if (p == null) return child;
              return Container(
                height: height,
                color: IvoryColors.surfaceWarm,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: IvoryColors.amber,
                    strokeWidth: 2,
                  ),
                ),
              );
            },
          );

    // A soft burgundy wash at the bottom so overlaid text stays legible.
    final Widget scrim = Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              IvoryColors.burgundy.withValues(alpha: 0.0),
              IvoryColors.burgundy.withValues(alpha: 0.55),
            ],
            stops: const <double>[0.45, 1.0],
          ),
        ),
      ),
    );

    if (!post.isLocked) {
      return Stack(children: <Widget>[base, scrim]);
    }

    // Locked: blur is presentation only. The media link for a locked
    // post is never sent to this device in the first place.
    return Stack(
      children: <Widget>[
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: base,
        ),
        Positioned.fill(
          child: Container(
            color: IvoryColors.cream.withValues(alpha: 0.35),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: IvoryColors.goldGradient,
                      shape: BoxShape.circle,
                      boxShadow: IvoryTheme.softShadow(blur: 14, y: 5),
                    ),
                    child: const Icon(Icons.lock,
                        color: IvoryColors.burgundy, size: 25),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: IvoryColors.surface.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: IvoryColors.hairlineStrong),
                    ),
                    child: Text(
                      post.tierName != null
                          ? '${post.tierName} members'
                          : 'Members only',
                      style: const TextStyle(
                        color: IvoryColors.burgundy,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
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
              'TIER ${post.tierRequired}',
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
