import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/ivory_post.dart';
import '../models/media_ref.dart';
import '../screens/main_shell.dart';
import '../services/auth_service.dart';
import '../services/content_service.dart';
import 'gift_sheet.dart';
import '../theme/ivory_theme.dart';
import 'ivory_media_view.dart';
import 'post_poll.dart';
import 'post_unlock_sheet.dart';

/// Everything that happens when a story card is tapped, shared by
/// Home and Explore. A locked post with a price of its own opens the
/// buying sheet instead of the members-only panel.
class PostActions {
  PostActions._();

  static Future<void> open(BuildContext context, IvoryPost post) async {
    if (post.isLocked) {
      // Locked, but with its own price? Then it is a door, not a wall.
      if (post.isPurchasable) {
        final bool? bought = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => PostUnlockSheet(post: post),
        );
        if (bought == true && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('I will verify it shortly and it will open.'),
            ),
          );
        }
        return;
      }
      _sheet(context, _LockedBody(post: post));
      return;
    }
    if (post.type == PostType.poll) {
      _sheet(context, PollBody(post: post));
      return;
    }

    final IvoryPost? full = await ContentService.instance.fetchFullPost(post.id);
    if (!context.mounted) return;

    if (full == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This story is not available to you yet.'),
        ),
      );
      return;
    }

    ContentService.instance.incrementView(post.id);

    if (full.type == PostType.blog) {
      _sheet(context, _ReaderBody(post: full));
    } else {
      _sheet(context, _MediaBody(post: full));
    }
  }

  static void _sheet(BuildContext context, Widget child) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.78,
        minChildSize: 0.4,
        maxChildSize: 0.96,
        expand: false,
        builder: (BuildContext c, ScrollController sc) => Container(
          decoration: const BoxDecoration(
            gradient: IvoryColors.pageGradient,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: <Widget>[
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: IvoryColors.hairlineStrong,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: sc,
                  padding: const EdgeInsets.fromLTRB(22, 4, 22, 40),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> launch(BuildContext context, String url) async {
    final bool ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not open $url')));
    }
  }
}

String _clean(String title) => title.replaceFirst('[SAMPLE] ', '');

Widget _doorStamp(IvoryPost post) =>
    post.doorCredit == null
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'FROM THE STORY DOOR · story by ${post.doorCredit}',
              style: TextStyle(
                fontSize: 10.5,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w800,
                color: IvoryColors.plum,
              ),
            ),
          );

Widget _giftRow(BuildContext context, IvoryPost post) => Padding(
      padding: const EdgeInsets.only(top: 26),
      child: Center(
        child: TextButton.icon(
          onPressed: () => showGiftSheet(context, postId: post.id),
          icon: const Text('💌', style: TextStyle(fontSize: 15)),
          label: Text(
            'send a gift',
            style: TextStyle(color: IvoryColors.textFaint, fontSize: 12.5),
          ),
        ),
      ),
    );

// =====================================================================
// Written story
// =====================================================================
class _ReaderBody extends StatelessWidget {
  const _ReaderBody({required this.post});

  final IvoryPost post;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const IvoryEyebrow('Written story', icon: Icons.auto_stories),
        const SizedBox(height: 10),
        _doorStamp(post),
        Text(_clean(post.title),
            style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 8),
        Text(
          post.relativeTime,
          style: TextStyle(fontSize: 12.5, color: IvoryColors.textFaint),
        ),
        Divider(color: IvoryColors.hairline, height: 30),
        Text(
          post.body ?? post.summary ?? 'This story has no text yet.',
          style: const TextStyle(
            fontFamily: IvoryTheme.displayFont,
            fontSize: 16.5,
            height: 1.78,
            color: IvoryColors.burgundy,
          ),
        ),
        _giftRow(context, post),
      ],
    );
  }
}

// =====================================================================
// Video / audio
// =====================================================================
class _MediaBody extends StatelessWidget {
  const _MediaBody({required this.post});

  final IvoryPost post;

  @override
  Widget build(BuildContext context) {
    // A file Ivory can stream itself: Supabase Storage, Cloudflare R2 or
    // any direct https link. YouTube and Telegram still open outside.
    final String? playable = post.media.directUrl();
    final String? external = post.media.externalUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        IvoryEyebrow(post.type.label, icon: PostCardIcons.of(post.type)),
        const SizedBox(height: 10),
        _doorStamp(post),
        Text(_clean(post.title),
            style: Theme.of(context).textTheme.headlineLarge),
        if (post.summary != null) ...<Widget>[
          const SizedBox(height: 10),
          Text(post.summary!, style: Theme.of(context).textTheme.bodyLarge),
        ],
        const SizedBox(height: 20),

        // ---- in-app viewing / playback ----
        if (playable != null && post.type == PostType.image)
          IvoryImageView(url: playable)
        else if (playable != null)
          IvoryPlayer(
            url: playable,
            audioOnly: post.type == PostType.audio,
            posterUrl: post.thumbnailFor(),
          )
        else
          Container(
            padding: const EdgeInsets.all(18),
            decoration: IvoryTheme.card(highlighted: true),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      playable != null
                          ? Icons.play_circle_fill
                          : Icons.open_in_new_rounded,
                      color: IvoryColors.amber,
                      size: 21,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        playable != null ? 'PLAYS IN IVORY' : 'OPENS OUTSIDE',
                        style: const TextStyle(
                          color: IvoryColors.plum,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    if (post.durationLabel != null)
                      Text(
                        post.durationLabel!,
                        style: TextStyle(
                          color: IvoryColors.textFaint,
                          fontSize: 12.5,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (external != null)
                  IvoryGradientButton(
                    label: 'WATCH NOW',
                    icon: Icons.play_arrow,
                    onPressed: () => PostActions.launch(context, external),
                  )
                else
                  Text(
                    'No playable link is attached to this post yet.',
                    style: TextStyle(
                      color: IvoryColors.textSoft,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),

        // ---- footer line ----
        if (playable != null) ...<Widget>[
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Icon(Icons.verified_rounded,
                  size: 15, color: IvoryColors.gold),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  post.durationLabel != null
                      ? 'Streaming inside Ivory - ${post.durationLabel}'
                      : 'Streaming inside Ivory',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: IvoryColors.textFaint,
                  ),
                ),
              ),
              if (external != null)
                TextButton(
                  onPressed: () => PostActions.launch(context, external),
                  child: const Text('Open externally'),
                ),
            ],
          ),
        ],
        _giftRow(context, post),
      ],
    );
  }
}


/// Tiny helper so the sheets can reuse the card's icon mapping.
class PostCardIcons {
  PostCardIcons._();
  static IconData of(PostType t) {
    switch (t) {
      case PostType.video:
        return Icons.movie_creation_outlined;
      case PostType.audio:
        return Icons.graphic_eq;
      case PostType.blog:
        return Icons.auto_stories;
      case PostType.image:
        return Icons.image_outlined;
      case PostType.poll:
        return Icons.how_to_vote_outlined;
      case PostType.unknown:
        return Icons.bookmark_border;
    }
  }
}

// =====================================================================
// Locked teaser
// =====================================================================
class _LockedBody extends StatelessWidget {
  const _LockedBody({required this.post});

  final IvoryPost post;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Center(
          child: Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              gradient: IvoryColors.goldGradient,
              shape: BoxShape.circle,
              boxShadow: IvoryTheme.softShadow(blur: 16, y: 6),
            ),
            child:
                const Icon(Icons.lock, color: IvoryColors.burgundy, size: 30),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Text(
            _clean(post.title),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            post.isForSale
                ? 'Rs.${post.priceInr} to open, or free from '
                    '${post.tierName ?? 'the higher tiers'}'
                : post.tierName != null
                    ? 'Available to ${post.tierName} members'
                    : 'Available to members',
            style: TextStyle(fontSize: 14.5, color: IvoryColors.textSoft),
          ),
        ),
        if (post.summary != null) ...<Widget>[
          const SizedBox(height: 18),
          Text(
            post.summary!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: IvoryTheme.card(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const IvoryEyebrow('Unlock this story',
                  icon: Icons.diamond_outlined),
              const SizedBox(height: 10),
              Text(
                'Open the Premium tab to choose your plan. Payment is '
                'instant over UPI and the story unlocks the moment it is '
                'confirmed. This card is fully secured: the media link '
                'for a locked story never reaches your device.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        IvoryGradientButton(
          label: 'SEE THE PLANS',
          icon: Icons.workspace_premium_rounded,
          onPressed: () {
            Navigator.of(context).pop();
            MainShell.openTab('premium');
          },
        ),
      ],
    );
  }
}

// =====================================================================
// Poll
// =====================================================================
// END OF FILE - lib/widgets/post_actions.dart
