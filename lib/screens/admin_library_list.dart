import 'package:flutter/material.dart';

import '../core/ivory_errors.dart';
import '../services/admin_service.dart';
import '../theme/ivory_theme.dart';
import 'admin_edit_post.dart';

/// Everything already published or drafted, with a switch to take a post
/// live or hide it and a button to delete it for good.
class AdminLibraryList extends StatefulWidget {
  const AdminLibraryList({super.key, this.refreshStamp = 0});

  /// Bumped by the composer after a successful publish so this list
  /// reloads itself.
  final int refreshStamp;

  @override
  State<AdminLibraryList> createState() => _AdminLibraryListState();
}

class _AdminLibraryListState extends State<AdminLibraryList> {
  List<Map<String, dynamic>> _items = <Map<String, dynamic>>[];

  /// Ids on Ivory's Firstlist. Read from the database on every load so
  /// the stars always show the truth, never a guess kept in the app.
  Set<int> _firstlist = <int>{};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(AdminLibraryList old) {
    super.didUpdateWidget(old);
    if (old.refreshStamp != widget.refreshStamp) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final List<Map<String, dynamic>> rows =
          await AdminService.instance.fetchLibrary();
      // A failure here must not cost the house its Library. The list
      // still works with every star dark.
      Set<int> onList = <int>{};
      try {
        onList = await AdminService.instance.firstlistIds();
      } catch (_) {
        onList = <int>{};
      }
      if (!mounted) return;
      _firstlist = onList;
      setState(() {
        _items = rows;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _toast(String m, {bool bad = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m),
        backgroundColor: bad ? IvoryColors.danger : IvoryColors.plum,
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'audio':
        return Icons.headphones_outlined;
      case 'video':
        return Icons.play_circle_outline;
      case 'image':
        return Icons.image_outlined;
      case 'poll':
        return Icons.how_to_vote_outlined;
      default:
        return Icons.auto_stories_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const IvoryEyebrow('The library',
                icon: Icons.inventory_2_outlined),
            const Spacer(),
            IconButton(
              onPressed: _load,
              icon: const Icon(Icons.refresh, color: IvoryColors.plum),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: CircularProgressIndicator(color: IvoryColors.amber),
            ),
          )
        else if (_items.isEmpty)
          Text('Nothing published yet.',
              style: TextStyle(color: IvoryColors.textFaint))
        else
          ..._items.map(_row),
      ],
    );
  }

  /// Add this post to Ivory's Firstlist, or take it off.
  ///
  /// The 25 place cap is the database's rule, not this screen's. When
  /// the list is full Postgres refuses and sends back a sentence
  /// already written for a person to read; houseMessage() lets that
  /// sentence through untouched and hides anything technical.
  Future<void> _toggleFirstlist(int id, bool pinned) async {
    // Move the star at once so the tap feels answered, then put it
    // back if the database disagrees.
    setState(() {
      if (pinned) {
        _firstlist.remove(id);
      } else {
        _firstlist.add(id);
      }
    });
    try {
      await AdminService.instance.setFirstlist(id, !pinned);
      if (!mounted) return;
      _toast(pinned
          ? 'Taken off Ivory\u2019s Firstlist.'
          : 'Added to Ivory\u2019s Firstlist.');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (pinned) {
          _firstlist.add(id);
        } else {
          _firstlist.remove(id);
        }
      });
      _toast(houseMessage(e), bad: true);
    }
  }

  Widget _row(Map<String, dynamic> p) {
    final int id = ((p['id'] as num?) ?? 0).toInt();
    final bool live = p['is_published'] == true;
    final bool pinned = _firstlist.contains(id);
    final int tier = ((p['tier_required'] as num?) ?? 0).toInt();

    // SPRINT 24i - a post sold on its own carries a price and a
    // sentinel tier (9 = "Nobody - all pay"). Printing "Tier 9" told
    // the house nothing. Show the price, which is the real rule.
    final num? price = (p['price_inr'] ?? p['price']) as num?;
    final bool priced = price != null && price > 0;

    final String tierName = priced
        ? 'Paid \u00b7 \u20b9${price.toInt()}'
        : (tier == 0
            ? 'Free'
            : (tier >= 9
                ? 'Everyone pays'
                : ((p['tier_name'] as String?) ?? 'Tier $tier')));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
      decoration: IvoryTheme.card(radius: 16),
      child: Row(
        children: <Widget>[
          Icon(
            _iconFor((p['type'] as String?) ?? 'blog'),
            size: 20,
            color: live ? IvoryColors.gold : IvoryColors.textFaint,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  (p['title'] as String?) ?? 'Untitled',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: IvoryColors.burgundy,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${live ? 'Live' : 'Draft'} \u00b7 $tierName \u00b7 '
                  '${(p['view_count'] as num?)?.toInt() ?? 0} views',
                  style:
                      TextStyle(fontSize: 11.5, color: IvoryColors.textFaint),
                ),
              ],
            ),
          ),
          // ---- change it, rather than delete and repost ----
          // Deleting and reposting used to be the only way to fix a
          // typo. It re-notified all 45 members, reset the views,
          // dropped the poll votes and orphaned anyone who had paid.
          // This keeps the same post.
          IconButton(
            tooltip: 'Edit this post',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.edit_outlined,
                size: 20, color: IvoryColors.plum),
            onPressed: () async {
              final bool saved = await AdminEditPost.open(context, id);
              if (saved) await _load();
            },
          ),

          // ---- Ivory's Firstlist ----
          IconButton(
            tooltip: pinned
                ? 'On Ivory\u2019s Firstlist'
                : 'Add to Ivory\u2019s Firstlist',
            visualDensity: VisualDensity.compact,
            icon: Icon(
              pinned ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 22,
              color: pinned ? IvoryColors.gold : IvoryColors.textFaint,
            ),
            onPressed: () => _toggleFirstlist(id, pinned),
          ),

          Switch.adaptive(
            value: live,
            activeColor: IvoryColors.gold,
            onChanged: (bool v) async {
              try {
                await AdminService.instance.setPublished(id, v);
                await _load();
                _toast(v ? 'Live now.' : 'Hidden from the feed.');
              } catch (e) {
                _toast('Could not change that: $e', bad: true);
              }
            },
          ),
          IconButton(
            tooltip: 'Delete for good',
            visualDensity: VisualDensity.compact,
            onPressed: () => _confirmDelete(id, (p['title'] as String?) ?? ''),
            icon: const Icon(Icons.delete_outline,
                size: 20, color: IvoryColors.plum),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(int id, String title) async {
    final bool? yes = await showDialog<bool>(
      context: context,
      builder: (BuildContext c) => AlertDialog(
        backgroundColor: IvoryColors.surface,
        title: const Text('Delete this post?',
            style: TextStyle(color: IvoryColors.burgundy)),
        content: Text(
          '"$title" will be removed for everyone. This cannot be undone.',
          style: TextStyle(color: IvoryColors.textSoft),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            style: TextButton.styleFrom(foregroundColor: IvoryColors.plum),
            child: const Text('KEEP'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            style: TextButton.styleFrom(foregroundColor: IvoryColors.danger),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await AdminService.instance.deletePost(id);
      await _load();
      _toast('Deleted.');
    } catch (e) {
      _toast('Could not delete: $e', bad: true);
    }
  }
}

// END OF FILE - lib/screens/admin_library_list.dart
