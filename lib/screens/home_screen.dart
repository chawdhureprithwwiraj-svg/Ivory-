import 'package:flutter/material.dart';

import '../models/ivory_post.dart';
import '../models/wish.dart';
import '../services/content_service.dart';
import '../services/wish_service.dart';
import '../theme/ivory_theme.dart';
import '../widgets/post_actions.dart';
import '../widgets/post_card.dart';

/// The front page: a banner strip, the Ivory hero, the featured drop,
/// the Wish highlight, and the most recent stories.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onOpenTab});

  final void Function(String tab)? onOpenTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<IvoryPost> _posts = <IvoryPost>[];
  int _wishFrom = 999;
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
      int from = 999;
      try {
        final List<WishCategory> cats =
            await WishService.instance.fetchCategories();
        if (cats.isNotEmpty) {
          from = cats
              .map((WishCategory c) => c.basePriceInr)
              .reduce((int a, int b) => a < b ? a : b);
        }
      } catch (_) {
        // The Wish price is decoration here; never block the home page.
      }
      if (!mounted) return;
      setState(() {
        _posts = posts;
        _wishFrom = from;
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
                    _wishCard(),
                    const SizedBox(height: 30),
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
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            gradient: IvoryColors.goldGradient,
            borderRadius: BorderRadius.circular(26),
            boxShadow: IvoryTheme.softShadow(blur: 22, y: 9),
          ),
          child: Center(
            child: Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                gradient: IvoryColors.deepGradient,
                borderRadius: BorderRadius.circular(21),
              ),
              child: const Center(
                child: Text(
                  'I',
                  style: TextStyle(
                    fontFamily: IvoryTheme.displayFont,
                    color: IvoryColors.gold,
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
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
        Text(
          'Curated stories, voice notes, cinema vignettes and polls — '
          'and wishes made only for you.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
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
        const SizedBox(height: 18),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 14,
          runSpacing: 6,
          children: <Widget>[
            _trust(Icons.verified_user_outlined, 'Consensual & lawful'),
            _trust(Icons.shield_outlined, 'No phone number ever'),
            _trust(Icons.currency_rupee, 'Free tier, always'),
          ],
        ),
      ],
    );
  }

  Widget _trust(IconData icon, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: IvoryColors.success),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(fontSize: 11.8, color: IvoryColors.textSoft),
          ),
        ],
      );

  Widget _wishCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _go('wish'),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
          decoration: BoxDecoration(
            gradient: IvoryColors.deepGradient,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: IvoryColors.gold, width: 1.4),
            boxShadow: IvoryTheme.softShadow(blur: 22, y: 9),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      gradient: IvoryColors.goldGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome,
                        color: IvoryColors.burgundy, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'THE WISH',
                      style: TextStyle(
                        color: IvoryColors.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3.5,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: IvoryColors.goldGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '₹$_wishFrom+',
                      style: const TextStyle(
                        color: IvoryColors.burgundy,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Just close your eyes\nand make a wish',
                style: TextStyle(
                  fontFamily: IvoryTheme.displayFont,
                  color: IvoryColors.cream,
                  fontSize: 25,
                  height: 1.22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 11),
              Text(
                'Request anything from me — entirely virtual. A story with '
                'your name in it, a voice note meant only for you, a vignette '
                'shot to your brief.',
                style: TextStyle(
                  color: IvoryColors.cream.withValues(alpha: 0.82),
                  fontSize: 14,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 18),
              IvoryGradientButton(
                label: 'MAKE YOUR WISH',
                icon: Icons.nightlight_round,
                onPressed: () => _go('wish'),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
            Text('No stories yet',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Run ivory_backend_v2.sql in Supabase to load the samples, or '
              'publish your first post from the admin console.',
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
