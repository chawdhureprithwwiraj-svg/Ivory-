import 'package:flutter/material.dart';

import '../core/ivory_errors.dart';
import '../services/bells_service.dart';
import '../theme/ivory_theme.dart';

/// ============================================================
/// ADMIN STUDIO - RING MY DOORBELL: PLEDGES AND BELL SETS
///
/// The lengths a member may pledge (Full Days in a row) and the bell
/// sets: each one's name, the Full Days that earn it, and whether it
/// is in use. After the last set the count starts again from 0, so
/// the round is one more than the highest number. The look and sound
/// of each set belong to its key and are fixed in the app.
/// ============================================================
class AdminBellsPlus extends StatefulWidget {
  const AdminBellsPlus({super.key, required this.onChanged});

  /// Called after something is saved so the tab can reload its numbers.
  final VoidCallback onChanged;

  @override
  State<AdminBellsPlus> createState() => _AdminBellsPlusState();
}

class _SetDraft {
  _SetDraft(this.key, this.name, this.min, this.active);
  final String key;
  String name;
  int min;
  bool active;
}

class _AdminBellsPlusState extends State<AdminBellsPlus> {
  List<int> _lens = <int>[];
  List<_SetDraft> _sets = <_SetDraft>[];
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
      final List<int> lens = await BellsService.instance.adminPledgeLens();
      final List<Map<String, dynamic>> sets = await BellsService.instance
          .adminSets();
      if (!mounted) return;
      setState(() {
        _lens = lens..sort();
        _sets = sets
            .map(
              (Map<String, dynamic> m) => _SetDraft(
                '${m['key']}',
                '${m['name']}',
                (m['min_full_days'] as num).toInt(),
                m['is_active'] != false,
              ),
            )
            .toList();
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

  void _say(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _run(Future<void> Function() job, String done) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await job();
      if (mounted) _say(done);
      widget.onChanged();
      await _load();
    } catch (e) {
      if (mounted) _say(adminDetail(e));
    }
    if (mounted) setState(() => _busy = false);
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

  Future<void> _addLen() async {
    final TextEditingController c = TextEditingController();
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext d) => AlertDialog(
        backgroundColor: IvoryColors.surface,
        title: const Text('A new pledge length'),
        content: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Full Days (1 to 366)'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(d).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(d).pop(true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    final int? n = int.tryParse(c.text.trim());
    if (ok != true) return;
    if (n == null || n < 1 || n > 366) {
      _say('Type a number from 1 to 366.');
      return;
    }
    if (_lens.contains(n)) {
      _say('That length is already there.');
      return;
    }
    final List<int> next = <int>[..._lens, n]..sort();
    await _run(
      () => BellsService.instance.adminSetPledgeLens(next),
      'Pledge lengths saved.',
    );
  }

  Future<void> _dropLen(int n) async {
    if (_lens.length <= 1) {
      _say('Keep at least one pledge length.');
      return;
    }
    final List<int> next = _lens.where((int x) => x != n).toList();
    await _run(
      () => BellsService.instance.adminSetPledgeLens(next),
      'Pledge lengths saved.',
    );
  }

  Future<void> _editSet(_SetDraft s) async {
    final TextEditingController name = TextEditingController(text: s.name);
    final TextEditingController min = TextEditingController(text: '${s.min}');
    bool active = s.active;
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext d) => StatefulBuilder(
        builder: (BuildContext d, StateSetter set2) => AlertDialog(
          backgroundColor: IvoryColors.surface,
          title: Text('Bell set: ${s.key}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: name,
                  maxLength: 24,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: min,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Full Days that earn it (0 = from the start)',
                  ),
                ),
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
              onPressed: () => Navigator.of(d).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(d).pop(true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final String nm = name.text.trim();
    final int? mn = int.tryParse(min.text.trim());
    if (nm.length < 2 || mn == null || mn < 0) {
      _say('Give it a name and a number of Full Days (0 or more).');
      return;
    }
    if (_sets.any((_SetDraft o) => o.key != s.key && o.min == mn)) {
      _say('Another set already starts at $mn Full Days.');
      return;
    }
    await _run(
      () => BellsService.instance.adminSaveSet(
        s.key,
        name: nm,
        minFullDays: mn,
        active: active,
      ),
      'Saved.',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: CircularProgressIndicator(color: IvoryColors.burgundy),
        ),
      );
    }
    int top = 0;
    for (final _SetDraft s in _sets) {
      if (s.active && s.min > top) top = s.min;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (_error != null)
          Text(_error!, style: const TextStyle(color: IvoryColors.burgundy)),
        _heading('PLEDGE LENGTHS (FULL DAYS IN A ROW)'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final int n in _lens)
              InputChip(
                label: Text(
                  '$n days',
                  style: const TextStyle(
                    color: IvoryColors.burgundy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                onDeleted: _busy ? null : () => _dropLen(n),
              ),
            ActionChip(
              label: const Text('Add'),
              avatar: const Icon(Icons.add, size: 18),
              onPressed: _busy ? null : _addLen,
            ),
          ],
        ),
        _heading('BELL SETS'),
        Text(
          'A round is ${top + 1} Full Days: after the highest number the '
          'count starts again from 0 and every set reached again earns a '
          'star. Sets are never sold.',
          style: const TextStyle(
            color: IvoryColors.plum,
            fontSize: 12.5,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 10),
        for (final _SetDraft s in _sets)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.fromLTRB(14, 6, 4, 6),
            decoration: IvoryTheme.card(),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '${s.name}  \u00b7  ${s.min} Full Days${s.active ? '' : '  (off)'}',
                    style: TextStyle(
                      color: s.active ? IvoryColors.burgundy : IvoryColors.plum,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _busy ? null : () => _editSet(s),
                  icon: const Icon(Icons.edit_outlined),
                  color: IvoryColors.plum,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// END OF FILE - lib/screens/admin_bells_plus.dart
