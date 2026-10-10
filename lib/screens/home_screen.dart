import 'package:flutter/material.dart';

import '../core/content_revision.dart';
import '../models/ivory_post.dart';
import '../services/content_service.dart';
import '../theme/ivory_theme.dart';
import '../widgets/ivory_logo.dart';
import '../widgets/live_banner.dart';
import '../widgets/ivory_signature.dart';
import '../widgets/live_record.dart';
import '../widgets/member_pulse.dart';
import '../widgets/story_door.dart';
import '../widgets/post_actions.dart';
import '../widgets/firstlist_rail.dart';
import '../widgets/post_card.dart';

/// The front page: a banner strip, the Ivory hero, the featured drop
/// and the most recent stories.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onOpenTab});

  final void Function(String tab)? onOpenTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<IvoryPost> _posts = <IvoryPost>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    contentRevision.addListener(_onContentChanged);
  }

  @override
  void dispose() {
    // Must be removed, or this calls setState on a dead screen.
    contentRevision.removeListener(_onContentChanged);
    super.dispose();
  }

  /// The library changed somewhere else in the app - a post was
  /// published, edited, hidden or deleted. This tab stays alive inside
  /// main_shell's IndexedStack, so without this it would keep showing
  /// what it fetched when the app started.
  void _onContentChanged() {
    if (mounted) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Both at once. The shelf is a separate query because the feed
      // only loads the newest 12, and a post may sit on Ivory's
      // Firstlist long after it has dropped out of that window.
      final List<dynamic> both = await Future.wait<dynamic>(<Future<dynamic>>[
        ContentService.instance.fetchFeed(limit: 12),
        ContentService.instance.fetchFirstlist(),
      ]);
      if (!mounted) return;
      setState(() {
        _posts = both[0] as List<IvoryPost>;
        _firstlist = both[1] as List<IvoryPost>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<IvoryPost> _firstlist = <IvoryPost>[];

  IvoryPost? get _featured {
    for (final IvoryPost p in _posts) {
      if (!p.isLocked && p.type != PostType.poll) return p;
    }
    return _posts.isEmpty ? null : _posts.first;
  }

  /// Whatever the shelf is already showing does not need showing again
  /// directly underneath it.
  List<IvoryPost> get _recent {
    final Set<int> shown = _firstlist.map((IvoryPost p) => p.id).toSet();
    if (_firstlist.isEmpty) {
      final IvoryPost? f = _featured;
      if (f != null) shown.add(f.id);
    }
    return _posts
        .where((IvoryPost p) => !shown.contains(p.id))
        .take(4)
        .toList();
  }

  void _go(String tab) => widget.onOpenTab?.call(tab);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: IvoryColors.pageGradient),
      child: RefreshIndicator(
        color: IvoryColors.burgundy,
        backgroundColor: IvoryColors.surface,
        onRefresh: _load,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const _BannerStrip(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _hero(),
                  // HER RECENT BROADCASTS BELONG NEAR THE FRONT DOOR,
                  // not after a member has walked the whole feed.
                  // After the hero is high enough to be easy to find,
                  // but not the first thing on the page.
                  const SizedBox(height: 22),
                  const LiveRecord(),
                  const SizedBox(height: 26),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 50),
                      child: Center(
                        child:
                            CircularProgressIndicator(color: IvoryColors.amber),
                      ),
                    )
                  else if (_error != null)
                    _errorBox()
                  else ...<Widget>[
                    // IVORY'S FIRSTLIST.
                    // The house's own running order, and it takes the
                    // top slot whenever she has put anything on it.
                    // "Ivory's Golden Reserve" was never a choice she
                    // made - it is simply the newest unlocked post -
                    // so it steps aside here, and comes back on its
                    // own if the Firstlist is ever emptied. Home is
                    // never left bare.
                    if (_firstlist.isNotEmpty) ...<Widget>[
                      const IvorySectionHeader(
                        title: "Ivory's Firstlist",
                        subtitle: 'Start here. Chosen by Ivory, in order.',
                        icon: Icons.auto_awesome,
                      ),
                      FirstlistRail(posts: _firstlist),
                      const SizedBox(height: 14),
                    ] else if (_featured != null) ...<Widget>[
                      IvorySectionHeader(
                        title: "Ivory's Golden Reserve",
                        actionLabel: 'Featured',
                        icon: Icons.auto_awesome,
                        onAction: () => _go('explore'),
                      ),
                      PostCard(
                        post: _featured!,
                        featured: true,
                        onTap: () => PostActions.open(context, _featured!),
                      ),
                      const SizedBox(height: 14),
                    ],
                    const SizedBox(height: 16),
                    IvorySectionHeader(
                      title: 'Recent stories & media',
                      subtitle: 'Written stories, voice notes and vignettes',
                      actionLabel: 'Explore all',
                      onAction: () => _go('explore'),
                    ),
                    if (_recent.isEmpty)
                      _emptyBox()
                    else
                      ..._recent.map(
                        (IvoryPost p) => PostCard(
                          post: p,
                          onTap: () => PostActions.open(context, p),
                        ),
                      ),
                  ],
                  // THE END OF THE LETTER. The promise still
                  // closes the page, after the stories themselves.
                  const SizedBox(height: 30),
                  const IvoryPromise(),
                  const SizedBox(height: 16),
                  const MemberPulseStrip(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------

  Widget _hero() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        const IvoryLogo(size: 96),
        const SizedBox(height: 20),
        Text(
          'A private world of\nstorytelling',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: 31,
                height: 1.2,
              ),
        ),
        const SizedBox(height: 12),
        _heroCopy(),
        const SizedBox(height: 22),
        // ONE DECISION, NOT THREE.
        //
        // This was two gold buttons of equal weight with a third
        // pill orphaned underneath - a lopsided triangle, and
        // nothing said which one she wanted tapped. Worse, the
        // third pill was a FACT dressed as a BUTTON: it read
        // "Free Tier Forever." and could not be tapped at all.
        // Card = decision, line = fact, and that pill broke it.
        //
        // It also used a banned word. A member is never "free"
        // and never a "guest".
        IvoryGradientButton(
          label: 'MAKE A WISH',
          icon: Icons.auto_awesome,
          onPressed: () => _go('wish'),
        ),
        const SizedBox(height: 14),
        Center(
          child: InkWell(
            onTap: () => _go('explore'),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(
                'Explore everything  \u2192',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: IvoryColors.burgundy,
                  decoration: TextDecoration.underline,
                  decorationColor: IvoryColors.gold,
                  decorationThickness: 1.6,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // The promise itself now closes the page. All that is
        // left here is the plain fact, as a line.
        Center(
          child: Text(
            'The door is open to everyone.',
            style: TextStyle(
              fontSize: 12.5,
              fontStyle: FontStyle.italic,
              color: IvoryColors.textSoft,
            ),
          ),
        ),
        const SizedBox(height: 18),
        const StoryDoorBand(),
        const SizedBox(height: 18),
        // Nothing at all unless a broadcast is actually on air.
        const LiveBanner(),
      ],
    );
  }

  /// The promise of the house. The one phrase that has to land -
  /// "Real Life Stories and Experiences" - is set in gold serif italic
  /// so the eye finds it before it reads a word of the rest.
  Widget _heroCopy() {
    final TextStyle base = TextStyle(
      fontSize: 14,
      height: 1.62,
      color: IvoryColors.textSoft,
    );
    final TextStyle accent = const TextStyle(
      fontFamily: IvoryTheme.displayFont,
      fontSize: 16,
      height: 1.5,
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
      color: IvoryColors.burgundy,
    );

    return Column(
      children: <Widget>[
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: base,
            children: <InlineSpan>[
              const TextSpan(
                text: "It's not just an app where you can only watch or "
                    'hear one sidedly. It\u2019s a ',
              ),
              TextSpan(
                text: 'connection with Me',
                style: base.copyWith(
                  fontWeight: FontWeight.w700,
                  color: IvoryColors.burgundy,
                ),
              ),
              const TextSpan(text: ' \u2014 '),
              TextSpan(
                text: 'Real Life Stories and Experiences',
                style: accent.copyWith(
                  decoration: TextDecoration.underline,
                  decorationColor: IvoryColors.gold,
                  decorationThickness: 1.6,
                ),
              ),
              const TextSpan(text: ', shared inside Ivory \u2014 and nowhere else.'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: <Color>[Color(0xFFFFFCF2), Color(0xFFFDF1DC)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border(
              left: BorderSide(color: IvoryColors.gold, width: 3),
              top: BorderSide(color: IvoryColors.hairline),
              right: BorderSide(color: IvoryColors.hairline),
              bottom: BorderSide(color: IvoryColors.hairline),
            ),
          ),
          child: Text(
            // The same promise, said as the creator: a real person
            // behind the work, a voice, a live moment. No phrase a
            // risk reviewer reads as a companion advert.
            'There is a real person behind every story \u2014 not a '
            'feed, not a script. Talk with me, hear my voice, and '
            'share a live moment made for you.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: IvoryTheme.displayFont,
              fontSize: 14.5,
              height: 1.55,
              fontStyle: FontStyle.italic,
              color: IvoryColors.burgundy.withValues(alpha: 0.88),
            ),
          ),
        ),
      ],
    );
  }

  /// The one promise worth saying out loud, dressed like the rest of the
  Widget _errorBox() => Container(
        padding: const EdgeInsets.all(20),
        decoration: IvoryTheme.card(),
        child: Column(
          children: <Widget>[
            const Icon(Icons.cloud_off, size: 40, color: IvoryColors.plum),
            const SizedBox(height: 12),
            Text('Could not load Ivory',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: IvoryColors.textFaint),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: _load, child: const Text('RETRY')),
          ],
        ),
      );

  Widget _emptyBox() => Container(
        padding: const EdgeInsets.all(24),
        decoration: IvoryTheme.card(),
        child: Column(
          children: <Widget>[
            Icon(Icons.auto_stories_outlined,
                size: 42, color: IvoryColors.amber),
            const SizedBox(height: 12),
            Text('The first story is coming',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Nothing has been shared here yet. Turn on notifications and '
              'you will know the moment it is.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
}

/// The thin gold announcement strip across the very top.
class _BannerStrip extends StatelessWidget {
  const _BannerStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 14),
      decoration: const BoxDecoration(gradient: IvoryColors.goldGradient),
      child: const Text(
        'IVORY · Golden Edition · Every story leaves a mark',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: IvoryColors.burgundy,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// END OF FILE - lib/screens/home_screen.dart
