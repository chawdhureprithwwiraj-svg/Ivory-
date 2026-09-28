import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/ivory_post.dart';
import '../models/media_ref.dart';
import '../services/content_service.dart';
import '../theme/ivory_theme.dart';

/// Everything that happens when a story card is tapped. Shared by the
/// Home and Explore tabs so the behaviour is identical in both.
class PostActions {
  PostActions._();

  static Future<void> open(BuildContext context, IvoryPost post) async {
    if (post.isLocked) {
      _sheet(context, _LockedBody(post: post));
      return;
    }
    if (post.type == PostType.poll) {
      _sheet(context, _PollBody(post: post));
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
    final String? external = post.media.externalUrl;
    final bool isTelegram = post.media.source == MediaSource.telegramChannel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        IvoryEyebrow(post.type.label, icon: PostCardIcons.of(post.type)),
        const SizedBox(height: 10),
        Text(_clean(post.title),
            style: Theme.of(context).textTheme.headlineLarge),
        if (post.summary != null) ...<Widget>[
          const SizedBox(height: 10),
          Text(post.summary!, style: Theme.of(context).textTheme.bodyLarge),
        ],
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: IvoryTheme.card(highlighted: true),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    isTelegram ? Icons.send_rounded : Icons.play_circle_fill,
                    color: IvoryColors.amber,
                    size: 21,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      post.media.source.label,
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
                  label: isTelegram ? 'OPEN IN TELEGRAM' : 'PLAY NOW',
                  icon: isTelegram ? Icons.send_rounded : Icons.play_arrow,
                  onPressed: () => PostActions.launch(context, external),
                )
              else
                Text(
                  'No playable link is attached to this post yet.',
                  style: TextStyle(color: IvoryColors.textSoft, fontSize: 14),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'An in-app player arrives in a later sprint. For now Ivory hands '
          'the story to the app that streams it best.',
          style: TextStyle(
            fontSize: 12.5,
            height: 1.5,
            color: IvoryColors.textFaint,
          ),
        ),
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
            post.tierName != null
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
              const IvoryEyebrow('Subscriptions arrive next sprint',
                  icon: Icons.diamond_outlined),
              const SizedBox(height: 10),
              Text(
                'Tier pricing, UPI payment and instant unlocking are being '
                'built now. This card is already fully secured: the media '
                'link for a locked story is never sent to your device.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =====================================================================
// Poll
// =====================================================================
class _PollBody extends StatefulWidget {
  const _PollBody({required this.post});

  final IvoryPost post;

  @override
  State<_PollBody> createState() => _PollBodyState();
}

class _PollBodyState extends State<_PollBody> {
  List<PollOption> _options = <PollOption>[];
  int? _myVote;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final List<PollOption> o =
        await ContentService.instance.fetchPollOptions(widget.post.id);
    final int? mine = await ContentService.instance.myVote(widget.post.id);
    if (!mounted) return;
    setState(() {
      _options = o;
      _myVote = mine;
      _loading = false;
    });
  }

  Future<void> _vote(int optionId) async {
    setState(() => _myVote = optionId);
    await ContentService.instance
        .castVote(postId: widget.post.id, optionId: optionId);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final int total =
        _options.fold<int>(0, (int s, PollOption o) => s + o.votes);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const IvoryEyebrow('Your vote counts', icon: Icons.how_to_vote),
        const SizedBox(height: 10),
        Text(_clean(widget.post.title),
            style: Theme.of(context).textTheme.headlineMedium),
        if (widget.post.summary != null) ...<Widget>[
          const SizedBox(height: 9),
          Text(widget.post.summary!,
              style: Theme.of(context).textTheme.bodyMedium),
        ],
        const SizedBox(height: 22),
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(30),
              child: CircularProgressIndicator(color: IvoryColors.amber),
            ),
          )
        else
          ..._options.map((PollOption o) {
            final bool mine = _myVote == o.id;
            final double pct = total == 0 ? 0 : o.votes / total;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _vote(o.id),
                child: Container(
                  decoration: BoxDecoration(
                    color: IvoryColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: mine
                          ? IvoryColors.gold
                          : IvoryColors.hairlineStrong,
                      width: mine ? 2 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: <Widget>[
                      FractionallySizedBox(
                        widthFactor: pct.clamp(0.0, 1.0),
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: <Color>[
                                IvoryColors.amber.withValues(alpha: 0.45),
                                IvoryColors.peach.withValues(alpha: 0.35),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 56,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Row(
                            children: <Widget>[
                              Icon(
                                mine
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                size: 19,
                                color: mine
                                    ? IvoryColors.burgundy
                                    : IvoryColors.textFaint,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  o.label,
                                  style: TextStyle(
                                    color: IvoryColors.burgundy,
                                    fontSize: 14.5,
                                    fontWeight: mine
                                        ? FontWeight.w800
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                              Text(
                                '${(pct * 100).round()}%',
                                style: const TextStyle(
                                  color: IvoryColors.burgundy,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        const SizedBox(height: 6),
        Text(
          total == 1 ? '1 vote' : '$total votes',
          style: TextStyle(fontSize: 12.5, color: IvoryColors.textFaint),
        ),
      ],
    );
  }
}
