import 'package:flutter/material.dart';

import '../core/ivory_errors.dart';
import '../services/i18n_admin_service.dart';
import '../theme/ivory_theme.dart';
import 'admin_i18n_editor.dart';

/// ============================================================
/// ADMIN - TRANSLATE
///
/// Every language Ivory can speak, how many of the words are done, a
/// switch to show or hide it in the language screen, and a way in to
/// edit its words. English is the app itself: always on, nothing to edit.
/// ============================================================
class AdminI18nTab extends StatefulWidget {
  const AdminI18nTab({super.key});

  @override
  State<AdminI18nTab> createState() => _AdminI18nTabState();
}

class _AdminI18nTabState extends State<AdminI18nTab> {
  List<Map<String, dynamic>>? _rows;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final List<Map<String, dynamic>> r =
          await I18nAdminService.instance.languages();
      if (!mounted) return;
      setState(() {
        _rows = r;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = adminDetail(e));
    }
  }

  int _n(dynamic v) => (v as num?)?.toInt() ?? 0;

  Future<void> _toggle(Map<String, dynamic> row, bool on) async {
    final String code = '${row['code']}';
    if (on && _n(row['done']) == 0) {
      final bool? ok = await showDialog<bool>(
        context: context,
        builder: (BuildContext c) => AlertDialog(
          title: const Text('No words yet'),
          content: Text(
              '${row['english']} has no translated words yet, so members '
              'would still read English. Switch it on anyway?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('NOT YET'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('SWITCH ON'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    try {
      await I18nAdminService.instance.setOn(code, on);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(adminDetail(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'The language tools are not ready yet.\n$_error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: IvoryColors.burgundy, height: 1.5),
          ),
        ),
      );
    }
    final List<Map<String, dynamic>>? rows = _rows;
    if (rows == null) {
      return const Center(
          child: CircularProgressIndicator(color: IvoryColors.amber));
    }
    return RefreshIndicator(
      color: IvoryColors.amber,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          const Text(
            'LANGUAGES',
            style: TextStyle(
              color: IvoryColors.plum,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.4,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Members pick a language when they first open the app. The '
            'switch decides which languages they are offered. Tap a '
            'language to read or change its words, or to paste a whole '
            'block with IMPORT. A word with no translation shows in '
            'English, so nothing is ever broken.',
            style: TextStyle(color: IvoryColors.burgundy, height: 1.45),
          ),
          const SizedBox(height: 14),
          for (final Map<String, dynamic> r in rows) _card(r),
        ],
      ),
    );
  }

  Widget _card(Map<String, dynamic> r) {
    final String code = '${r['code']}';
    final bool isEn = code == 'en';
    final int done = _n(r['done']);
    final int total = _n(r['total']);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: IvoryTheme.card(radius: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isEn
              ? null
              : () async {
                  await Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => AdminI18nEditor(
                        code: code,
                        english: '${r['english']}',
                        native: '${r['native']}',
                      ),
                    ),
                  );
                  _load();
                },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '${r['native']}',
                        style: const TextStyle(
                          color: IvoryColors.plum,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isEn
                            ? 'English · the app itself, always on'
                            : '${r['english']} · $done of $total words'
                                '${total > 0 && done >= total ? ' · complete' : ''}',
                        style: TextStyle(
                          color: IvoryColors.textSoft,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isEn)
                  const Icon(Icons.edit_outlined,
                      size: 18, color: IvoryColors.plum),
                Switch(
                  value: r['is_on'] == true,
                  activeColor: IvoryColors.amber,
                  onChanged: isEn ? null : (bool v) => _toggle(r, v),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// END OF FILE - lib/screens/admin_i18n_tab.dart
