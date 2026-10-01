import 'package:flutter/material.dart';

import '../models/ivory_post.dart';
import '../services/content_service.dart';
import '../theme/ivory_theme.dart';
import '../widgets/ivory_logo.dart';
import '../widgets/live_banner.dart';
import '../widgets/member_pulse.dart';
import '../widgets/post_actions.dart';
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
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<IvoryPost> posts =
          await ContentService.instance.fetchFeed(limit: 12);
      if (!mounted) return;
      setState(() {
        _posts = posts;
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

  IvoryPost? get _featured {
    for (final IvoryPost p in _posts) {
      if (!p.isLocked && p.type != PostType.poll) return p;
    }
    return _posts.isEmpty ? null : _posts.first;
  }

  List<IvoryPost> get _recent {
    final IvoryPost? f = _featured;
    return _posts.where((IvoryPost p) => p.id != f?.id).take(4).toList();
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
                  const SizedBox(height: 30),
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
                    if (_featured != null) ...<Widget>[
                      IvorySectionHeader(
                        title: "Editor's Golden Reserve",
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
        Row(
          children: <Widget>[
            Expanded(
              child: IvoryGradientButton(
                label: 'MAKE A WISH',
                icon: Icons.auto_awesome,
                onPressed: () => _go('wish'),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _go('explore'),
                icon: const Icon(Icons.search, size: 18),
                label: const Text('EXPLORE'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _freeForever(),
        const SizedBox(height: 12),
        _trust(Icons.verified_user_outlined, 'Consensual & lawful'),
        const SizedBox(height: 18),
        const MemberPulseStrip(),
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
              const TextSpan(text: ', shared with you and no one else.'),
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
            'Get connected directly to a real woman according to your '
            'criteria \u2014 with whom you can talk, watch her and feel '
            'live, as per your wish!',
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
  /// Golden Edition: gold rule, serif italic, burgundy ink.
  Widget _freeForever() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: <Color>[Color(0xFFFFFCF2), Color(0xFFFDF1DC)],
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: IvoryColors.gold.withValues(alpha: 0.85),
            width: 1.3,
          ),
          boxShadow: IvoryTheme.softShadow(blur: 14, y: 5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ShaderMask(
              shaderCallback: (Rect b) =>
                  IvoryColors.goldGradient.createShader(b),
              child: const Icon(Icons.auto_awesome,
                  size: 17, color: Colors.white),
            ),
            const SizedBox(width: 9),
            const Text(
              'Free Tier Forever.',
              style: TextStyle(
                fontFamily: IvoryTheme.displayFont,
                fontSize: 17,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
                color: IvoryColors.burgundy,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _trust(IconData icon, String label) => Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 14, color: IvoryColors.success),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(fontSize: 11.8, color: IvoryColors.textSoft),
            ),
          ],
        ),
      );

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
