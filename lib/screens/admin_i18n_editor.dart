import 'package:flutter/material.dart';

import '../core/ivory_errors.dart';
import '../services/i18n_admin_service.dart';
import '../theme/ivory_theme.dart';

/// ============================================================
/// ADMIN - TRANSLATE one language
///
/// The words of one language, English on top and the translation under
/// it. Search, show only the missing ones or only the House names, tap a
/// word to change it, or paste many at once with IMPORT.
/// ============================================================
class AdminI18nEditor extends StatefulWidget {
  const AdminI18nEditor({
    super.key,
    required this.code,
    required this.english,
    required this.native,
  });

  final String code;
  final String english;
  final String native;

  @override
  State<AdminI18nEditor> createState() => _AdminI18nEditorState();
}

class _AdminI18nEditorState extends State<AdminI18nEditor> {
  static const int _page = 60;

  final TextEditingController _search = TextEditingController();
  final List<Map<String, dynamic>> _items = <Map<String, dynamic>>[];
  String _filter = 'all';
  bool _loading = true;
  bool _more = false;
  String? _error;

  I18nAdminService get _svc => I18nAdminService.instance;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({required bool reset}) async {
    setState(() {
      _loading = true;
      _error = null;
      if (reset) _items.clear();
    });
    try {
      final List<Map<String, dynamic>> r = await _svc.words(
        lang: widget.code,
        q: _search.text.trim(),
        filter: _filter,
        limit: _page,
        offset: _items.length,
      );
      if (!mounted) return;
      setState(() {
        _items.addAll(r);
        _more = r.length >= _page;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = adminDetail(e);
          _loading = false;
        });
      }
    }
  }

  void _say(String t) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
  }

  Future<void> _edit(Map<String, dynamic> item) async {
    final TextEditingController ctl =
        TextEditingController(text: '${item['txt'] ?? ''}');
    final String? out = await showDialog<String>(
      context: context,
      builder: (BuildContext c) => AlertDialog(
        title: Text(widget.english),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('${item['src']}',
                  style: const TextStyle(
                      color: IvoryColors.plum, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              TextField(
                controller: ctl,
                autofocus: true,
                minLines: 2,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: 'Translation in ${widget.english}',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Keep any {word} in curly brackets exactly as it is. '
                'Leave empty to go back to English.',
                style: TextStyle(fontSize: 12, color: IvoryColors.plum),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, ctl.text),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
    if (out == null) return;
    try {
      await _svc.save(widget.code, '${item['src']}', out);
      if (!mounted) return;
      setState(() => item['txt'] = out.trim().isEmpty ? null : out.trim());
      _say('Saved.');
    } catch (e) {
      _say(adminDetail(e));
    }
  }

  Future<void> _import() async {
    final TextEditingController ctl = TextEditingController();
    final bool? go = await showDialog<bool>(
      context: context,
      builder: (BuildContext c) => AlertDialog(
        title: Text('Import ${widget.english}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'One word or line per row:\n'
                'English text ||| translation\n'
                'Add ||| name at the end for a House name. Rows that start '
                'with # are ignored.',
                style: TextStyle(fontSize: 12.5, color: IvoryColors.plum),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: ctl,
                minLines: 6,
                maxLines: 10,
                decoration: const InputDecoration(hintText: 'Paste here'),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('IMPORT'),
          ),
        ],
      ),
    );
    if (go != true || ctl.text.trim().isEmpty) return;
    try {
      final Map<String, dynamic> r =
          await _svc.importBlock(widget.code, ctl.text);
      if (!mounted) return;
      _say('Saved ${r['saved']} rows, skipped ${r['skipped']}.');
      _load(reset: true);
    } catch (e) {
      _say(adminDetail(e));
    }
  }

  Widget _chip(String key, String label) {
    final bool on = _filter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: on,
        selectedColor: IvoryColors.amber.withValues(alpha: 0.35),
        onSelected: (_) {
          setState(() => _filter = key);
          _load(reset: true);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.native),
        actions: <Widget>[
          TextButton.icon(
            onPressed: _import,
            icon: const Icon(Icons.upload_file, size: 18),
            label: const Text('IMPORT'),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _load(reset: true),
              decoration: InputDecoration(
                hintText: 'Search the words',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _search.clear();
                    _load(reset: true);
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Row(
              children: <Widget>[
                _chip('all', 'ALL'),
                _chip('missing', 'MISSING'),
                _chip('names', 'NAMES'),
              ],
            ),
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: IvoryColors.burgundy)),
        ),
      );
    }
    if (_items.isEmpty && _loading) {
      return const Center(
          child: CircularProgressIndicator(color: IvoryColors.amber));
    }
    if (_items.isEmpty) {
      return const Center(
        child: Text('Nothing here.',
            style: TextStyle(color: IvoryColors.burgundy)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: _items.length + (_more ? 1 : 0),
      itemBuilder: (BuildContext c, int i) {
        if (i >= _items.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: OutlinedButton(
              onPressed: _loading ? null : () => _load(reset: false),
              child: Text(_loading ? 'LOADING' : 'LOAD MORE'),
            ),
          );
        }
        final Map<String, dynamic> it = _items[i];
        final String? txt = it['txt'] as String?;
        final bool isName = it['is_name'] == true;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: IvoryTheme.card(radius: 14),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _edit(it),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${isName ? 'NAME · ' : ''}${it['src']}',
                      style: TextStyle(
                        color: IvoryColors.textSoft,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (txt == null || txt.isEmpty)
                          ? 'Not translated yet (shows English)'
                          : txt,
                      style: TextStyle(
                        color: (txt == null || txt.isEmpty)
                            ? IvoryColors.textFaint
                            : IvoryColors.burgundy,
                        fontSize: 15,
                        height: 1.4,
                        fontStyle: (txt == null || txt.isEmpty)
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// END OF FILE - lib/screens/admin_i18n_editor.dart
