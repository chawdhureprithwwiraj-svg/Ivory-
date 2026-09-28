import 'dart:async';

import 'package:flutter/material.dart';

import '../models/ivory_post.dart';
import '../services/content_service.dart';
import '../theme/ivory_theme.dart';
import '../widgets/post_actions.dart';
import '../widgets/post_card.dart';

/// Explore the whole Ivory library: search by title or feeling, then
/// narrow by kind of story.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _search = TextEditingController();
  Timer? _debounce;

  List<IvoryPost> _posts = <IvoryPost>[];
  bool _loading = true;
  String? _error;
  String? _type;

  /// Label, database value. Add a kind here only if the posts table
  /// gains a new type; tiers and categories stay data-driven elsewhere.
  static const List<List<String?>> _filters = <List<String?>>[
    <String?>[null, 'All'],
    <String?>['blog', 'Stories'],
    <String?>['audio', 'Voice notes'],
    <String?>['video', 'Cinema'],
    <String?>['poll', 'Polls'],
    <String?>['image', 'Photos'],
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<IvoryPost> posts = await ContentService.instance.fetchFeed(
        typeFilter: _type,
        search: _search.text,
      );
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

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _load);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: IvoryColors.pageGradient),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Explore the library',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 5),
                Text(
                  'Search by title, place or feeling.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _search,
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _load(),
                  decoration: InputDecoration(
                    hintText: 'Florence, silk, rain, desire...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _search.clear();
                              _load();
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _filters.length,
              itemBuilder: (BuildContext c, int i) {
                final String? value = _filters[i][0];
                final String label = _filters[i][1]!;
                final bool active = _type == value;
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: active,
                    showCheckmark: false,
                    onSelected: (_) {
                      setState(() => _type = value);
                      _load();
                    },
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: IvoryColors.burgundy,
              backgroundColor: IvoryColors.surface,
              onRefresh: _load,
              child: _body(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: IvoryColors.amber),
      );
    }
    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          const SizedBox(height: 60),
          const Icon(Icons.cloud_off, size: 44, color: IvoryColors.plum),
          const SizedBox(height: 14),
          Text('Could not search',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: IvoryColors.textFaint),
          ),
          const SizedBox(height: 18),
          Center(
            child: OutlinedButton(onPressed: _load, child: const Text('RETRY')),
          ),
        ],
      );
    }
    if (_posts.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(28),
        children: <Widget>[
          const SizedBox(height: 70),
          Icon(Icons.travel_explore, size: 48, color: IvoryColors.amber),
          const SizedBox(height: 14),
          Text('Nothing matches yet',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Try a different word, or clear the filters.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: _posts.length,
      itemBuilder: (BuildContext c, int i) => PostCard(
        post: _posts[i],
        onTap: () => PostActions.open(context, _posts[i]),
      ),
    );
  }
}
