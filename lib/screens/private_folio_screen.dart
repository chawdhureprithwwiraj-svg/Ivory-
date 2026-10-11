import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/folio_entry.dart';
import '../models/live_models.dart';
import '../services/live_service.dart';
import '../services/private_folio_service.dart';
import '../theme/ivory_theme.dart';
import '../widgets/call_sheet_bits.dart';
import '../widgets/private_folio_entry_card.dart';
import '../widgets/private_folio_entry_editor.dart';

class PrivateFolioScreen extends StatefulWidget {
  const PrivateFolioScreen({super.key});

  @override
  State<PrivateFolioScreen> createState() => _PrivateFolioScreenState();
}

class _PrivateFolioScreenState extends State<PrivateFolioScreen> {
  final TextEditingController _search = TextEditingController();
  List<FolioEntry> _entries = <FolioEntry>[];
  List<CallRequest> _calls = <CallRequest>[];
  FolioKind? _filter;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<FolioEntry> entries =
          await PrivateFolioService.instance.fetchEntries();
      List<CallRequest> calls = <CallRequest>[];
      try {
        calls = await LiveService.instance.myCalls();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _calls = calls;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Your Folio could not load. Check the connection and retry.';
      });
    }
  }

  List<FolioEntry> get _visible {
    final String query = _search.text.trim().toLowerCase();
    return _entries.where((FolioEntry entry) {
      if (_filter != null && entry.kind != _filter) return false;
      if (query.isEmpty) return true;
      final String searchable = <String>[
        entry.title, entry.body, entry.url ?? '', ...entry.tags,
      ].join(' ').toLowerCase();
      return searchable.contains(query);
    }).toList();
  }

  Future<void> _edit({FolioEntry? entry}) async {
    final bool? saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: IvoryColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => PrivateFolioEntryEditor(entry: entry, calls: _calls),
    );
    if (saved == true) await _load();
  }

  Future<void> _delete(FolioEntry entry) async {
    final bool? yes = await showDialog<bool>(
      context: context,
      builder: (BuildContext c) => AlertDialog(
        title: const Text('Remove this page?'),
        content: const Text('This deletes it from your Folio, not your Inbox.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('KEEP IT'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await PrivateFolioService.instance.delete(entry.id);
      if (mounted) setState(() => _entries.removeWhere((e) => e.id == entry.id));
    } catch (_) {
      _notice('Could not delete that page. Please retry.');
    }
  }

  Future<void> _openLink(FolioEntry entry) async {
    final Uri? uri = Uri.tryParse(entry.url ?? '');
    if (uri == null ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty) {
      _notice('This saved link is not valid. Edit it before opening.');
      return;
    }
    final bool opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) _notice('That link could not be opened on this device.');
  }

  void _notice(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final List<FolioEntry> visible = _visible;
    return Scaffold(
      backgroundColor: IvoryColors.surface,
      appBar: AppBar(
        title: const Text('THE QUIET FOLIO'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Refresh Folio',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        backgroundColor: IvoryColors.burgundy,
        foregroundColor: IvoryColors.cream,
        icon: const Icon(Icons.bookmark_add_outlined),
        label: const Text('KEEP SOMETHING'),
      ),
      body: RefreshIndicator(
        color: IvoryColors.burgundy,
        backgroundColor: IvoryColors.surface,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 105),
          children: <Widget>[
            _hero(),
            const SizedBox(height: 14),
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Search pages, words, links or labels',
              ),
            ),
            const SizedBox(height: 11),
            _filters(),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 42),
                child: Center(
                  child: CircularProgressIndicator(color: IvoryColors.gold),
                ),
              )
            else if (_error != null)
              _empty(
                icon: Icons.cloud_off_outlined,
                title: 'Your pages are still here.',
                message: _error!,
                action: 'TRY AGAIN',
                onAction: _load,
              )
            else if (visible.isEmpty)
              _empty(
                icon: Icons.auto_stories_outlined,
                title: _search.text.trim().isNotEmpty
                    ? 'No pages found for that search.'
                    : (_entries.isEmpty
                        ? 'A page with your name on it.'
                        : 'Nothing on this shelf yet.'),
                message: _search.text.trim().isNotEmpty
                    ? 'Try another word, remove a label or clear the search.'
                    : (_entries.isEmpty
                        ? 'Not everything needs to be sent. Keep a thought, '
                            'a draft or a link here until you want it again.'
                        : 'Choose “Keep something” and add the first page here.'),
                action: _search.text.trim().isNotEmpty
                    ? 'CLEAR SEARCH'
                    : (_entries.isEmpty ? 'WRITE A FIRST PAGE' : null),
                onAction: _search.text.trim().isNotEmpty
                    ? () => setState(_search.clear)
                    : (_entries.isEmpty ? () => _edit() : null),
              )
            else
              ...visible.map((FolioEntry entry) => PrivateFolioEntryCard(
                    entry: entry,
                    onEdit: () => _edit(entry: entry),
                    onDelete: () => _delete(entry),
                    onOpenLink: () => _openLink(entry),
                  )),
            const SizedBox(height: 18),
            Center(
              child: Text(
                'Nothing is sent, posted or shared from this Folio.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: IvoryColors.textFaint,
                  fontSize: 11.5,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hero() => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 17),
        decoration: BoxDecoration(
          gradient: IvoryColors.deepGradient,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: IvoryColors.gold, width: 1.2),
          boxShadow: IvoryTheme.softShadow(blur: 15, y: 5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.menu_book_rounded,
                    color: IvoryColors.gold, size: 23),
                const SizedBox(width: 9),
                Text(
                  'A PLACE TO KEEP YOUR WORDS',
                  style: TextStyle(
                    color: IvoryColors.gold,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),
            const Text(
              'Not everything needs to be sent.',
              style: TextStyle(
                color: IvoryColors.cream,
                fontFamily: IvoryTheme.displayFont,
                fontSize: 21,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Keep notes, unfinished drafts, saved links and call thoughts '
              'for the day you want to return to them.',
              style: TextStyle(
                color: IvoryColors.cream.withValues(alpha: 0.86),
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: IvoryColors.cream.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: IvoryColors.gold.withValues(alpha: 0.5)),
              ),
              child: const Text(
                'PRIVATE TO YOUR ACCOUNT · NOT END-TO-END ENCRYPTED',
                style: TextStyle(
                  color: IvoryColors.cream,
                  fontSize: 8.8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.45,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _filters() => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: <Widget>[
            _filterChip(null, 'All pages'),
            for (final FolioKind kind in FolioKind.values)
              _filterChip(kind, kind.label),
          ],
        ),
      );

  Widget _filterChip(FolioKind? kind, String label) {
    final bool selected = _filter == kind;
    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = kind),
        selectedColor: IvoryColors.gold,
        backgroundColor: IvoryColors.surfaceWarm,
        labelStyle: TextStyle(
          color: selected ? IvoryColors.burgundy : IvoryColors.plum,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide(color: selected ? IvoryColors.amber : IvoryColors.hairline),
      ),
    );
  }

  Widget _empty({
    required IconData icon,
    required String title,
    required String message,
    String? action,
    VoidCallback? onAction,
  }) => Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: IvoryColors.surfaceWarm,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: IvoryColors.hairline),
        ),
        child: Column(
          children: <Widget>[
            Icon(icon, size: 30, color: IvoryColors.amber),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: IvoryColors.burgundy,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: IvoryColors.textSoft,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            if (action != null && onAction != null) ...<Widget>[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onAction, child: Text(action)),
            ],
          ],
        ),
      );
}

// END OF FILE - lib/screens/private_folio_screen.dart
