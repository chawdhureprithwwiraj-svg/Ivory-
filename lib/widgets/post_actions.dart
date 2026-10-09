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
import 'post_media_body.dart';
import 'post_poll.dart';
import 'post_surface.dart';
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
      return;
    }
    // Film and photograph fill the screen. A voice note is listened
    // to, not watched, so it stays a sheet like the writing does.
    final bool immersive =
        full.type == PostType.video || full.type == PostType.image;
    _sheet(context, PostMediaBody(post: full), immersive: immersive);
  }

  /// A story, a voice note or a poll rises as a sheet that can reach
  /// the very top. A film or a photograph takes the whole screen at
  /// once - it is the thing itself, not an attachment to a page.
  static void _sheet(
    BuildContext context,
    Widget child, {
    bool immersive = false,
  }) {
    IvoryPostSurface.show(context, child, immersive: immersive);
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

/// Shared with post_media_body.dart, so it cannot stay
/// private. A private name does not cross a file boundary in
/// Dart - which is exactly what broke the 27c build.
String postCleanTitle(String title) => title.replaceFirst('[SAMPLE] ', '');

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

/// Shared with post_media_body.dart - see above.
Widget postGiftRow(BuildContext context, IvoryPost post) => Padding(
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
        Text(postCleanTitle(post.title),
            style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 8),
        Text(
          post.relativeTime,
          style: TextStyle(fontSize: 12.5, color: IvoryColors.textFaint),
        ),
        Divider(color: IvoryColors.hairline, height: 30),

        // SPRINT 24o - THE FILM NO LONGER WAITS AT THE BOTTOM.
        // 24k fixed 'the attached file is invisible' by drawing it
        // under the writing, which buried it: a 3,000 character story
        // meant a member scrolled past everything before discovering
        // there was a film at all. The story is now broken into its
        // paragraphs and the file sits after the FIRST one, so the
        // opening lines lead, the film arrives early, and the rest of
        // the writing carries on beneath it. A story with a single
        // paragraph behaves exactly as it did before.
        ..._flow(post),

        postGiftRow(context, post),
      ],
    );
  }

  static const TextStyle _prose = TextStyle(
    fontFamily: IvoryTheme.displayFont,
    fontSize: 16.5,
    height: 1.78,
    color: IvoryColors.burgundy,
  );

  /// The writing, with the attached file set after the opening
  /// paragraph. Never truncates: a story may be any length at all.
  List<Widget> _flow(IvoryPost post) {
    final List<String> paras = _paragraphs(
      post.body ?? post.summary ?? 'This story has no text yet.',
    );
    final List<Widget> out = <Widget>[];
    for (int i = 0; i < paras.length; i++) {
      out.add(Text(paras[i], style: _prose));
      if (i == 0) {
        out.add(_StoryMedia(post: post));
      } else if (i < paras.length - 1) {
        out.add(const SizedBox(height: 15));
      }
    }
    return out;
  }

  /// Blank lines separate paragraphs. If she wrote without blank
  /// lines, single breaks are used instead, so her story is never
  /// served as one unbroken slab whichever way she types.
  static List<String> _paragraphs(String raw) {
    List<String> parts = _splitOn(raw, RegExp(r'\n\s*\n'));
    if (parts.length < 2) parts = _splitOn(raw, RegExp(r'\n'));
    return parts.isEmpty ? <String>[raw.trim()] : parts;
  }

  static List<String> _splitOn(String raw, RegExp pattern) {
    final List<String> out = <String>[];
    for (final String piece in raw.split(pattern)) {
      final String t = piece.trim();
      if (t.isNotEmpty) out.add(t);
    }
    return out;
  }
}

// =====================================================================
// The file hanging off a written story
// =====================================================================
/// Draws whatever the story carries, or nothing at all when it carries
/// only words. Deliberately silent on failure: a story with no file is
/// the normal case, not an error, and must never show a warning.
class _StoryMedia extends StatelessWidget {
  const _StoryMedia({required this.post});

  final IvoryPost post;

  static const List<String> _pictures = <String>[
    '.jpg', '.jpeg', '.png', '.webp', '.gif', '.heic', '.bmp',
  ];
  static const List<String> _sounds = <String>[
    '.mp3', '.m4a', '.aac', '.wav', '.ogg', '.opus', '.flac',
  ];

  /// The post type says 'story', so it cannot tell us what the file is.
  /// The name can. A signed address carries its key before the '?', so
  /// the extension survives signing - but check the stored reference
  /// first, which is always clean.
  static bool _looksLike(List<String> endings, String? ref, String url) {
    for (final String candidate in <String>[ref ?? '', url]) {
      final String name = candidate.split('?').first.toLowerCase();
      for (final String e in endings) {
        if (name.endsWith(e)) return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final String? playable = post.media.directUrl();
    if (playable == null) return const SizedBox.shrink();

    final String? ref = post.media.ref;
    final bool isPicture = _looksLike(_pictures, ref, playable);
    final bool isSound = _looksLike(_sounds, ref, playable);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: isPicture
          ? IvoryImageView(url: playable)
          : IvoryPlayer(
              url: playable,
              audioOnly: isSound,
              posterUrl: post.thumbnailFor(),
            ),
    );
  }
}

// =====================================================================
// Video / audio
// =====================================================================
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
            postCleanTitle(post.title),
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
            MainShell.onOpenTab?.call('premium');
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
