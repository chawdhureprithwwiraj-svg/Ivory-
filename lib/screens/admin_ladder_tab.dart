import 'package:flutter/material.dart';

import '../core/ivory_errors.dart';
import '../services/ladder_service.dart';
import '../theme/ivory_theme.dart';
import '../widgets/admin_stat_grid.dart';
import 'admin_ladder_marks.dart';

/// ============================================================
/// ADMIN STUDIO - THE IVORY LADDER
///
/// The house's numbers (members, Marks given, milestones), the ladder's
/// open switch, how many climb points each Mark is worth, the streak
/// milestones, the name and the points needed for each rung, and every
/// Mark (see AdminLadderMarks). Everything here is free and earned;
/// nothing on this page can be sold.
/// ============================================================
class AdminLadderTab extends StatefulWidget {
  const AdminLadderTab({super.key});

  @override
  State<AdminLadderTab> createState() => _AdminLadderTabState();
}

class _AdminLadderTabState extends State<AdminLadderTab> {
  Map<String, dynamic> _sum = <String, dynamic>{};
  List<Map<String, dynamic>> _rungs = <Map<String, dynamic>>[];
  bool _open = true;
  int _markPoints = 3;
  final TextEditingController _ms = TextEditingController();
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ms.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final LadderService s = LadderService.instance;
      final Map<String, dynamic> sum = await s.adminSummary();
      final Map<String, dynamic> cfg = await s.adminSettings();
      final List<Map<String, dynamic>> rungs = await s.adminRungs();
      if (!mounted) return;
      setState(() {
        _sum = sum;
        _rungs = rungs;
        _open = cfg['is_open'] != false;
        _markPoints = (cfg['mark_points'] as num?)?.toInt() ?? 3;
        final dynamic ms = cfg['milestones'];
        _ms.text = ms is List ? ms.map((dynamic e) => '$e').join(', ') : '';
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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _saveSettings() async {
    final List<int> days = _ms.text
        .split(RegExp(r'[ ,]+'))
        .map((String e) => int.tryParse(e.trim()))
        .whereType<int>()
        .where((int d) => d >= 1)
        .toSet()
        .toList()
      ..sort();
    if (days.isEmpty) {
      _say('Give at least one milestone, for example 7, 30, 100.');
      return;
    }
    setState(() => _busy = true);
    try {
      await LadderService.instance.adminSaveSettings(
        open: _open,
        markPoints: _markPoints,
        milestones: days,
      );
      _say('Saved.');
      await _load();
    } catch (e) {
      _say(adminDetail(e));
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _editRung(Map<String, dynamic> r) async {
    final TextEditingController name = TextEditingController(text: '${r['name']}');
    final TextEditingController pts = TextEditingController(text: '${r['min_points']}');
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext c) => AlertDialog(
        title: Text('Rung ${r['rung']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: name,
              maxLength: 24,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: pts,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Climb points needed'),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: IvoryColors.burgundy),
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    final String n = name.text.trim();
    final int? p = int.tryParse(pts.text.trim());
    name.dispose();
    pts.dispose();
    if (ok != true || !mounted) return;
    if (n.length < 2 || p == null || p < 0) {
      _say('Please give a name and a number of points (0 or more).');
      return;
    }
    try {
      await LadderService.instance.adminSaveRung(r['rung'] as int, n, p);
      _say('Saved.');
      await _load();
    } catch (e) {
      _say(adminDetail(e));
    }
  }

  /// The rarest Mark is only meaningful when it differs from the most
  /// earned one (with a single kind of Mark given they are the same).
  String _rarest() {
    final dynamic top = _sum['top_mark'];
    final dynamic rare = _sum['rarest_mark'];
    if (rare == null || rare == top) return '-';
    return '$rare';
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

  Widget _stat(String label, String value) => Container(
    padding: const EdgeInsets.all(14),
    decoration: IvoryTheme.card(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label.toUpperCase(),
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text(_error!, style: const TextStyle(color: IvoryColors.burgundy)),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 40),
        children: <Widget>[
          _heading('THE NUMBERS'),
          AdminStatGrid(
            children: <Widget>[
              _stat('Members who opened it', '${_sum['members'] ?? 0}'),
              _stat('Members with a Mark', '${_sum['with_marks'] ?? 0}'),
              _stat('Marks given', '${_sum['marks_given'] ?? 0}'),
              _stat('Milestones reached', '${_sum['milestones_given'] ?? 0}'),
              _stat('Most earned', '${_sum['top_mark'] ?? '-'}'),
              _stat('Rarest so far', _rarest()),
            ],
          ),
          _heading('SETTINGS'),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
            decoration: IvoryTheme.card(),
            child: Column(
              children: <Widget>[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: IvoryColors.cream,
                  title: const Text(
                    'Ladder is open',
                    style: TextStyle(
                      color: IvoryColors.burgundy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: const Text(
                    'Off hides the ladder icon from members.',
                    style: TextStyle(color: IvoryColors.plum),
                  ),
                  value: _open,
                  onChanged: _busy ? null : (bool v) => setState(() => _open = v),
                ),
                Row(
                  children: <Widget>[
                    const Expanded(
                      child: Text(
                        'Climb points per Mark',
                        style: TextStyle(
                          color: IvoryColors.burgundy,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      color: IvoryColors.burgundy,
                      onPressed: _busy || _markPoints <= 0
                          ? null
                          : () => setState(() => _markPoints--),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      '$_markPoints',
                      style: const TextStyle(
                        color: IvoryColors.burgundy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    IconButton(
                      color: IvoryColors.burgundy,
                      onPressed: _busy || _markPoints >= 50
                          ? null
                          : () => setState(() => _markPoints++),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                TextField(
                  controller: _ms,
                  style: const TextStyle(
                    color: IvoryColors.burgundy,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Streak milestones (days, separated by commas)',
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: IvoryColors.burgundy,
                    ),
                    onPressed: _busy ? null : _saveSettings,
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
          _heading('THE RUNGS (TAP TO EDIT)'),
          ..._rungs.map(
            (Map<String, dynamic> r) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: IvoryTheme.card(),
              child: ListTile(
                onTap: () => _editRung(r),
                title: Text(
                  '${r['rung']}.  ${r['name']}',
                  style: const TextStyle(
                    color: IvoryColors.burgundy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: Text(
                  '${r['min_points']} climb points',
                  style: const TextStyle(color: IvoryColors.plum),
                ),
                trailing: const Icon(Icons.edit_outlined, color: IvoryColors.plum),
              ),
            ),
          ),
          _heading('THE MARKS (TAP TO EDIT)'),
          const AdminLadderMarks(),
        ],
      ),
    );
  }
}

// END OF FILE - lib/screens/admin_ladder_tab.dart
