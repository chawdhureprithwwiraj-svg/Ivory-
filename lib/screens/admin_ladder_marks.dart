import 'package:flutter/material.dart';

import '../core/ivory_errors.dart';
import '../services/ladder_service.dart';
import '../theme/ivory_theme.dart';

/// ============================================================
/// ADMIN STUDIO - THE MARKS
///
/// Every Mark in the book. The house can rename a Mark, change its
/// wording, retarget it (how many it takes), change its rarity or
/// switch it off. A switched-off Mark is hidden from members; ones
/// already earned are kept and still count towards climb points.
/// What a Mark counts (its metric) is fixed by the rules, so a Mark
/// cannot be pointed at something the database does not track.
/// ============================================================
class AdminLadderMarks extends StatefulWidget {
  const AdminLadderMarks({super.key});

  @override
  State<AdminLadderMarks> createState() => _AdminLadderMarksState();
}

class _AdminLadderMarksState extends State<AdminLadderMarks> {
  List<Map<String, dynamic>> _marks = <Map<String, dynamic>>[];
  bool _loading = true;
  String? _error;

  static const List<String> _rarities = <String>[
    'common',
    'uncommon',
    'rare',
    'epic',
    'legendary',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final List<Map<String, dynamic>> m = await LadderService.instance
          .adminMarks();
      if (!mounted) return;
      setState(() {
        _marks = m;
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

  Future<void> _edit(Map<String, dynamic> m) async {
    final TextEditingController name = TextEditingController(text: '${m['name']}');
    final TextEditingController blurb = TextEditingController(text: '${m['blurb']}');
    final TextEditingController target = TextEditingController(text: '${m['target']}');
    String rarity = '${m['rarity']}';
    bool active = m['is_active'] != false;
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext c) => StatefulBuilder(
        builder: (BuildContext c, StateSetter set) => AlertDialog(
          title: Text('${m['key']}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: name,
                  maxLength: 30,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: blurb,
                  maxLength: 120,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'What it takes'),
                ),
                TextField(
                  controller: target,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Target (counts ${markMetricName('${m['metric']}')})',
                  ),
                ),
                DropdownButtonFormField<String>(
                  initialValue: rarity,
                  decoration: const InputDecoration(labelText: 'Rarity'),
                  items: _rarities
                      .map(
                        (String r) =>
                            DropdownMenuItem<String>(value: r, child: Text(r)),
                      )
                      .toList(),
                  onChanged: (String? v) => set(() => rarity = v ?? rarity),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: IvoryColors.burgundy,
                  title: const Text('Shown to members'),
                  value: active,
                  onChanged: (bool v) => set(() => active = v),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(c).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: IvoryColors.burgundy,
              ),
              onPressed: () => Navigator.of(c).pop(true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    final String n = name.text.trim();
    final String b = blurb.text.trim();
    final int? t = int.tryParse(target.text.trim());
    name.dispose();
    blurb.dispose();
    target.dispose();
    if (ok != true || !mounted) return;
    if (n.length < 2 || b.length < 3 || t == null || t < 1) {
      _say('Please give a name, some wording and a target of 1 or more.');
      return;
    }
    try {
      await LadderService.instance.adminSaveMark(
        '${m['key']}',
        name: n,
        blurb: b,
        target: t,
        rarity: rarity,
        active: active,
      );
      _say('Saved.');
      await _load();
    } catch (e) {
      if (mounted) _say(adminDetail(e));
    }
  }

  void _say(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Text(_error!, style: const TextStyle(color: IvoryColors.burgundy));
    }
    return Column(
      children: _marks.map((Map<String, dynamic> m) {
        final bool on = m['is_active'] != false;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: IvoryTheme.card(),
          child: ListTile(
            onTap: () => _edit(m),
            title: Text(
              '${m['name']}',
              style: TextStyle(
                color: IvoryColors.burgundy,
                fontWeight: FontWeight.w800,
                decoration: on ? null : TextDecoration.lineThrough,
              ),
            ),
            subtitle: Text(
              '${_cap('${m['rarity']}')}  \u00B7  ${markMetricName('${m['metric']}')}: ${m['target']}${m['is_active'] == false ? '  \u00B7  hidden' : ''}',
              style: const TextStyle(color: IvoryColors.plum),
            ),
            trailing: const Icon(Icons.edit_outlined, color: IvoryColors.plum),
          ),
        );
      }).toList(),
    );
  }
}

/// What each Mark counts, in plain words (the database keeps the code).
const Map<String, String> _metricNames = <String, String>{
  'lit_days': 'Lit days',
  'best_glow': 'Best glow (days in a row)',
  'bell_rings': 'Bell rings',
  'full_days': 'Full Days',
  'best_peal': 'Best Peal (Full Days in a row)',
  'pledges_kept': 'Pledges kept',
  'sets_owned': 'Bell sets owned',
  'rounds': 'Rounds finished',
  'reads': 'Stories read',
  'poll_votes': 'Poll votes',
  'live_joins': 'Lives joined',
  'reach_outs': 'Reach-outs',
  'vault_keys': 'Vault keys turned',
  'vault_done': 'Vaults opened',
  'knockoff_played': 'Knock-offs played',
  'knockoff_perfect': 'Perfect tens',
  'treasures': 'Treasures earned',
  'early_reads': 'Early reads',
  'line_sent': 'Private Line letters sent',
  'line_heard': 'Private Line replies heard',
};

/// The plain name for a metric code (the code itself if unknown).
String markMetricName(String code) => _metricNames[code] ?? code;

String _cap(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

// END OF FILE - lib/screens/admin_ladder_marks.dart
