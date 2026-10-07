import 'package:flutter/material.dart';

import '../models/ivory_post.dart';
import '../theme/ivory_theme.dart';
import 'post_actions.dart';

/// IVORY'S FIRSTLIST - the shelf of up to 25 posts the house wants every
/// member to see before anything else.
///
/// A sideways shelf rather than a stack, because 25 full-width cards
/// would bury the rest of Home. Each card is deliberately small: a
/// poster, the kind of thing it is, the title, and a number saying
/// where it sits in Ivory's order.
///
/// The word "pinned" appears nowhere a member can read. It is always
/// Ivory's Firstlist.
class FirstlistRail extends StatelessWidget {
  const FirstlistRail({super.key, required this.posts});

  final List<IvoryPost> posts;

  /// Tall enough for the poster plus two lines of title, and no taller.
  static const double _cardWidth = 182;
  static const double _posterHeight = 128;
  static const double _railHeight = 232;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: _railHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: EdgeInsets.zero,
        itemCount: posts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (BuildContext c, int i) => _FirstlistCard(
          post: posts[i],
          place: i + 1,
          width: _cardWidth,
          posterHeight: _posterHeight,
        ),
      ),
    );
  }
}

class _FirstlistCard extends StatelessWidget {
  const _FirstlistCard({
    required this.post,
    required this.place,
    required this.width,
    required this.posterHeight,
  });

  final IvoryPost post;
  final int place;
  final double width;
  final double posterHeight;

  @override
  Widget build(BuildContext context) {
    final String? art = post.thumbnailFor();
    final bool locked = post.isLocked;

    return SizedBox(
      width: width,
      child: Material(
        color: IvoryColors.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => PostActions.open(context, post),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: IvoryColors.gold.withValues(alpha: 0.55),
                width: 1.3,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _poster(art, locked),
                Padding(
                  padding: const EdgeInsets.fromLTRB(11, 9, 11, 0),
                  child: Text(
                    post.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: IvoryTheme.displayFont,
                      color: IvoryColors.burgundy,
                      fontSize: 14,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(11, 0, 11, 10),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        PostCardIcons.of(post.type),
                        size: 13,
                        color: IvoryColors.amber,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          post.type.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 0.9,
                            fontWeight: FontWeight.w800,
                            color: IvoryColors.textSoft,
                          ),
                        ),
                      ),
                      if (locked)
                        const Icon(Icons.lock_rounded,
                            size: 13, color: IvoryColors.plum),
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

  /// The poster, or a warm panel with the kind of thing it is when a
  /// post has no artwork of its own - a written story, usually.
  Widget _poster(String? art, bool locked) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
      child: SizedBox(
        height: posterHeight,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            if (art != null)
              Image.network(
                art,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback(),
              )
            else
              _fallback(),

            // The place in Ivory's order. Members read it as a running
            // order, not as a ranking of quality.
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                width: 23,
                height: 23,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: <Color>[IvoryColors.gold, IvoryColors.amber],
                  ),
                ),
                child: Text(
                  '$place',
                  style: const TextStyle(
                    color: IvoryColors.burgundy,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),

            if (locked)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: IvoryColors.surface.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'LOCKED',
                    style: TextStyle(
                      color: IvoryColors.plum,
                      fontSize: 8.5,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _fallback() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[IvoryColors.surfaceWarm, IvoryColors.cream],
        ),
      ),
      child: Center(
        child: Icon(
          PostCardIcons.of(post.type),
          size: 34,
          color: IvoryColors.amber,
        ),
      ),
    );
  }
}

// END OF FILE - lib/widgets/firstlist_rail.dart
