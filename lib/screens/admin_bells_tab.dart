import 'package:flutter/material.dart';

import '../core/ivory_errors.dart';
import '../services/bells_service.dart';
import '../theme/ivory_theme.dart';
import '../widgets/admin_stat_grid.dart';

/// ============================================================
/// ADMIN STUDIO - RING MY DOORBELL
///
/// How many members rang today, the doorbell's open switch, the hour
/// each bell opens and whether it is in use, and Ivory's Night lines
/// (add, edit, switch off, delete; a line given a date is shown on
/// that day, the rest rotate).
/// ============================================================
class AdminBellsTab extends StatefulWidget {
  const AdminBellsTab({super.key});

  @override
  State<AdminBellsTab> createState() => _AdminBellsTabState();
}

class _BellDraft {
  _BellDraft(this.key, this.label, this.hour, this.active);
  final String key;
  final String label;
  int hour;
  bool active;
}

class _AdminBellsTabState extends State<AdminBellsTab> {
  Map<String, dynamic> _sum = <String, dynamic>{};
  List<_BellDraft> _bells = <_BellDraft>[];
  List<Map<String, dynamic>> _lines = <Map<String, dynamic>>[];
  bool _open = true;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final BellsService s = BellsService.instance;
      final Map<String, dynamic> sum = await s.adminSummary();
      final bool open = await s.adminIsOpen();
      final List<Map<String, dynamic>> defs = await s.adminDefs();
      final List<Map<String, dynamic>> lines = await s.adminLines();
      if (!mounted) return;
      setState(() {
        _sum = sum;
        _open = open;
        _bells = defs
            .map(
              (Map<String, dynamic> d) => _BellDraft(
                '${d['key']}',
                '${d['label']}',
                (d['open_hour'] as num?)?.toInt() ?? 0,
                d['is_active'] != false,
              ),
            )
            .toList();
        _lines = lines;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = adminDetail(e);
        _loading = false;
      });
    }
  }

  Future<void> _run(Future<void> Function() job, String done) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await job();
      if (mounted) _say(done);
      await _load();
    } catch (e) {
      if (mounted) _say(adminDetail(e));
    }
    if (mounted) setState(() => _busy = false);
  }

  void _say(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  String _hour(int h) {
    final int x = h % 12 == 0 ? 12 : h % 12;
    return '$x ${h < 12 ? 'AM' : 'PM'}';
  }

  int _n(String k) => (_sum[k] as num?)?.toInt() ?? 0;

  Future<void> _editLine(Map<String, dynamic>? line) async {
    final TextEditingController body = TextEditingController(
      text: line == null ? '' : '${line['body']}',
    );
    final TextEditingController day = TextEditingController(
      text: line == null || line['for_day'] == null ? '' : '${line['for_day']}',
    );
    bool active = line == null || line['is_active'] != false;
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext c) => StatefulBuilder(
        builder: (BuildContext c, StateSetter set2) => AlertDialog(
          backgroundColor: IvoryColors.surface,
          title: Text(line == null ? 'New Night line' : 'Edit Night line'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: body,
                  maxLines: 5,
                  maxLength: 400,
                  decoration: const InputDecoration(labelText: 'The line'),
                ),
                TextField(
                  controller: day,
                  decoration: const InputDecoration(
                    labelText: 'Show on one day (YYYY-MM-DD), or leave empty',
                  ),
                ),
                if (line != null)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: IvoryColors.burgundy,
                    title: const Text('In use'),
                    value: active,
                    onChanged: (bool v) => set2(() => active = v),
                  ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(c).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(c).pop(true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final String text = body.text.trim();
    final String? d = day.text.trim().isEmpty ? null : day.text.trim();
    if (text.length < 3) {
      _say('Write the line first.');
      return;
    }
    if (d != null && DateTime.tryParse(d) == null) {
      _say('The day must look like 2026-12-31.');
      return;
    }
    await _run(() {
      if (line == null) return BellsService.instance.adminAddLine(text, d);
      return BellsService.instance.adminSaveLine(
        (line['id'] as num).toInt(),
        body: text,
        forDay: d,
        active: active,
      );
    }, 'Saved.');
  }

  Future<void> _deleteLine(Map<String, dynamic> line) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext c) => AlertDialog(
        backgroundColor: IvoryColors.surface,
        title: const Text('Delete this line?'),
        content: Text('${line['body']}'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _run(
      () => BellsService.instance.adminDeleteLine((line['id'] as num).toInt()),
      'Deleted.',
    );
  }

  Widget _tile(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: IvoryTheme.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: IvoryColors.plum,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: IvoryColors.burgundy,
              fontFamily: IvoryTheme.displayFont,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _heading(String t) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 10),
    child: Text(
      t,
      style: const TextStyle(
        color: IvoryColors.plum,
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 2.4,
      ),
    ),
  );

  Widget _bellRow(_BellDraft b) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      decoration: IvoryTheme.card(),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              b.label,
              style: const TextStyle(
                color: IvoryColors.burgundy,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            onPressed: b.hour > 0
                ? () => setState(() => b.hour = b.hour - 1)
                : null,
            icon: const Icon(Icons.remove_circle_outline),
            color: IvoryColors.plum,
          ),
          SizedBox(
            width: 56,
            child: Text(
              _hour(b.hour),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: IvoryColors.burgundy,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            onPressed: b.hour < 23
                ? () => setState(() => b.hour = b.hour + 1)
                : null,
            icon: const Icon(Icons.add_circle_outline),
            color: IvoryColors.plum,
          ),
          Switch(
            value: b.active,
            activeThumbColor: IvoryColors.burgundy,
            onChanged: (bool v) => setState(() => b.active = v),
          ),
        ],
      ),
    );
  }

  Widget _lineRow(Map<String, dynamic> l) {
    final bool on = l['is_active'] != false;
    final String? d = l['for_day'] == null ? null : '${l['for_day']}';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
      decoration: IvoryTheme.card(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${l['body']}',
                  style: TextStyle(
                    color: on ? IvoryColors.burgundy : IvoryColors.plum,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${d == null ? 'Rotates' : 'On $d'}${on ? '' : ' (off)'}',
                  style: const TextStyle(
                    color: IvoryColors.plum,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _editLine(l),
            icon: const Icon(Icons.edit_outlined),
            color: IvoryColors.plum,
          ),
          IconButton(
            onPressed: () => _deleteLine(l),
            icon: const Icon(Icons.delete_outline),
            color: IvoryColors.plum,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: IvoryColors.burgundy),
      );
    }
    final String todays = '${_sum['todays_line'] ?? ''}';
    return RefreshIndicator(
      color: IvoryColors.burgundy,
      backgroundColor: IvoryColors.surface,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
        children: <Widget>[
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                _error!,
                style: const TextStyle(color: IvoryColors.burgundy),
              ),
            ),
          AdminStatGrid(
            children: <Widget>[
              _tile('MEMBERS RANG TODAY', '${_n('members_rang_today')}'),
              _tile('BELLS RUNG TODAY', '${_n('rings_today')}'),
              _tile('FULL DAYS TODAY', '${_n('full_today')}'),
              _tile('FULL DAYS EVER', '${_n('full_total')}'),
              _tile('BEST RUN', '${_n('best_peal')}'),
              _tile('NIGHT LINES IN USE', '${_n('lines_active')}'),
            ],
          ),
          _heading('THE DOORBELL'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: IvoryColors.burgundy,
            title: const Text(
              'Ring My Doorbell is open to members',
              style: TextStyle(
                color: IvoryColors.burgundy,
                fontWeight: FontWeight.w700,
              ),
            ),
            value: _open,
            onChanged: _busy
                ? null
                : (bool v) => _run(
                    () => BellsService.instance.adminSetOpen(v),
                    v ? 'The doorbell is open.' : 'The doorbell is closed.',
                  ),
          ),
          _heading('WHEN EACH BELL OPENS'),
          for (final _BellDraft b in _bells) _bellRow(b),
          const SizedBox(height: 4),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: IvoryColors.burgundy,
              minimumSize: const Size.fromHeight(46),
            ),
            onPressed: _busy
                ? null
                : () => _run(() async {
                    for (final _BellDraft b in _bells) {
                      await BellsService.instance.adminSaveDef(
                        b.key,
                        hour: b.hour,
                        active: b.active,
                      );
                    }
                  }, 'Bell hours saved.'),
            child: const Text('Save bell hours'),
          ),
          _heading('IVORY\'S NIGHT LINES'),
          if (todays.isNotEmpty && todays != 'null')
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                "Tonight's line: $todays",
                style: const TextStyle(
                  color: IvoryColors.plum,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _editLine(null),
            icon: const Icon(Icons.add),
            label: const Text('Add a line'),
          ),
          const SizedBox(height: 10),
          for (final Map<String, dynamic> l in _lines) _lineRow(l),
        ],
      ),
    );
  }
}

// END OF FILE - lib/screens/admin_bells_tab.dart
