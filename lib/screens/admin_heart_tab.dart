import 'package:flutter/material.dart';

import '../core/ivory_errors.dart';
import '../services/heart_service.dart';
import '../theme/ivory_theme.dart';
import '../widgets/heart_paint.dart';

/// ============================================================
/// ADMIN STUDIO - THE GOLDEN HEART
///
/// What the heart has done today and over time, and every dial the
/// house may turn: open or shut, the line that lights a day, the
/// hour the day turns over, how mends are earned, the reminder, the
/// points and daily limit of each action, and the names and lengths of
/// the glow tiers. The heart can never be bought; nothing here sells
/// it.
/// ============================================================
class AdminHeartTab extends StatefulWidget {
  const AdminHeartTab({super.key});

  @override
  State<AdminHeartTab> createState() => _AdminHeartTabState();
}

class _ActionDraft {
  _ActionDraft(this.key, this.label, this.points, this.cap, this.active);
  final String key;
  final String label;
  int points;
  int cap;
  bool active;
}

class _AdminHeartTabState extends State<AdminHeartTab> {
  Map<String, dynamic> _sum = <String, dynamic>{};
  List<_ActionDraft> _acts = <_ActionDraft>[];
  List<Map<String, dynamic>> _tiers = <Map<String, dynamic>>[];
  bool _open = true;
  bool _nudges = true;
  int _line = 60;
  int _start = 4;
  int _every = 7;
  int _max = 2;
  int _nudgeHour = 20;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  int _n(String k) => ((_sum[k] as num?) ?? 0).toInt();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final HeartService h = HeartService.instance;
      final Map<String, dynamic> sum = await h.adminSummary();
      final Map<String, dynamic> cfg = await h.adminSettings();
      final List<Map<String, dynamic>> acts = await h.adminActions();
      final List<Map<String, dynamic>> tiers = await h.adminTiers();
      int g(String k, int d) => ((cfg[k] as num?) ?? d).toInt();
      if (!mounted) return;
      setState(() {
        _sum = sum;
        _open = cfg['is_open'] != false;
        _nudges = cfg['nudges_on'] != false;
        _line = g('lit_points', 60);
        _start = g('day_start_hour', 4);
        _every = g('mend_every', 7);
        _max = g('mend_max', 2);
        _nudgeHour = g('nudge_hour', 20);
        _acts = acts
            .map(
              (Map<String, dynamic> a) => _ActionDraft(
                '${a['key']}',
                '${a['label']}',
                ((a['points'] as num?) ?? 0).toInt(),
                ((a['daily_cap'] as num?) ?? 1).toInt(),
                a['is_active'] != false,
              ),
            )
            .toList();
        _tiers = tiers;
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

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final HeartService h = HeartService.instance;
      await h.adminSaveSettings(<String, dynamic>{
        'is_open': _open,
        'nudges_on': _nudges,
        'lit_points': _line,
        'day_start_hour': _start,
        'mend_every': _every,
        'mend_max': _max,
        'nudge_hour': _nudgeHour,
      });
      for (final _ActionDraft a in _acts) {
        await h.adminSaveAction(
          a.key,
          points: a.points,
          cap: a.cap,
          active: a.active,
        );
      }
      if (!mounted) return;
      setState(() => _saving = false);
      _toast(
        'Saved. Members see the new numbers the next time they open their heart.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast(adminDetail(e));
    }
  }

  void _toast(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  String _hour(int h) {
    final int x = h % 12 == 0 ? 12 : h % 12;
    return '$x ${h < 12 ? 'AM' : 'PM'}';
  }

  Future<void> _editTier(Map<String, dynamic> t) async {
    final int oldDays = ((t['min_days'] as num?) ?? 1).toInt();
    final TextEditingController name = TextEditingController(
      text: '${t['name']}',
    );
    final TextEditingController days = TextEditingController(text: '$oldDays');
    final bool? go = await showDialog<bool>(
      context: context,
      builder: (BuildContext c) => AlertDialog(
        backgroundColor: IvoryColors.surface,
        title: const Text('Glow tier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: days,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Lit days in a row to reach it',
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    final String nm = name.text.trim();
    final int? d = int.tryParse(days.text.trim());
    name.dispose();
    days.dispose();
    if (go != true) return;
    if (nm.isEmpty || d == null || d < 1) {
      _toast('Give the tier a name and a number of days (1 or more).');
      return;
    }
    try {
      await HeartService.instance.adminSaveTier(oldDays, d, nm);
      await _load();
    } catch (e) {
      _toast(adminDetail(e));
    }
  }

  Widget _tile(String label, String value) {
    return Container(
      width: 150,
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

  Widget _stepper(
    String label,
    int v,
    int lo,
    int hi,
    int step,
    void Function(int) apply, {
    String unit = '',
    String Function(int)? fmt,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: IvoryColors.burgundy,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: v - step >= lo
                ? () => setState(() => apply(v - step))
                : null,
            icon: const Icon(Icons.remove_circle_outline),
            color: IvoryColors.plum,
          ),
          SizedBox(
            width: 70,
            child: Text(
              fmt == null ? '$v $unit' : fmt(v),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: IvoryColors.burgundy,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            onPressed: v + step <= hi
                ? () => setState(() => apply(v + step))
                : null,
            icon: const Icon(Icons.add_circle_outline),
            color: IvoryColors.plum,
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

  Widget _switch(String t, bool v, void Function(bool) f) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    activeThumbColor: IvoryColors.burgundy,
    title: Text(
      t,
      style: const TextStyle(
        color: IvoryColors.burgundy,
        fontWeight: FontWeight.w700,
      ),
    ),
    value: v,
    onChanged: (bool x) => setState(() => f(x)),
  );

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: IvoryColors.burgundy),
      );
    }
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
                style: const TextStyle(color: IvoryColors.danger, fontSize: 13),
              ),
            ),
          const Text(
            'THE GOLDEN HEART',
            style: TextStyle(
              color: IvoryColors.plum,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.4,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _tile('LIT TODAY', '${_n('lit_today')}'),
              _tile('TOUCHED TODAY', '${_n('touched_today')}'),
              _tile('GLOWING NOW', '${_n('glowing')}'),
              _tile('BEST GLOW NOW', '${_n('best_now')}'),
              _tile('BEST GLOW EVER', '${_n('best_ever')}'),
              _tile('AVERAGE GLOW', '${_sum['avg_glow'] ?? 0}'),
              _tile('HEARTS BEGUN', '${_n('members')}'),
              _tile('ACTIONS TODAY', '${_n('events_today')}'),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
            decoration: IvoryTheme.card(),
            child: Column(
              children: <Widget>[
                _switch(
                  'Golden Heart is open to members',
                  _open,
                  (bool v) => _open = v,
                ),
                _stepper(
                  'Points that light a day',
                  _line,
                  10,
                  1000,
                  5,
                  (int v) => _line = v,
                  unit: 'pts',
                ),
                _stepper(
                  'The day turns over at',
                  _start,
                  0,
                  23,
                  1,
                  (int v) => _start = v,
                  fmt: _hour,
                ),
                _stepper(
                  'A mend is earned every',
                  _every,
                  1,
                  60,
                  1,
                  (int v) => _every = v,
                  unit: 'days',
                ),
                _stepper(
                  'Most mends a member can hold',
                  _max,
                  0,
                  10,
                  1,
                  (int v) => _max = v,
                  unit: 'mends',
                ),
                _switch(
                  'Evening reminder to keep a glow',
                  _nudges,
                  (bool v) => _nudges = v,
                ),
                _stepper(
                  'Reminder goes out from',
                  _nudgeHour,
                  12,
                  23,
                  1,
                  (int v) => _nudgeHour = v,
                  fmt: _hour,
                ),
              ],
            ),
          ),
          _heading('WHAT FILLS THE HEART'),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
            decoration: IvoryTheme.card(),
            child: Column(
              children: <Widget>[
                for (final _ActionDraft a in _acts) ...<Widget>[
                  _switch(a.label, a.active, (bool v) => a.active = v),
                  if (a.active) ...<Widget>[
                    _stepper(
                      'Points each',
                      a.points,
                      0,
                      1000,
                      5,
                      (int v) => a.points = v,
                      unit: 'pts',
                    ),
                    _stepper(
                      'Times a day',
                      a.cap,
                      1,
                      20,
                      1,
                      (int v) => a.cap = v,
                      unit: 'x',
                    ),
                  ],
                  const Divider(height: 14),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          IvoryGradientButton(
            label: 'SAVE THE HEART SETTINGS',
            icon: Icons.check,
            busy: _saving,
            onPressed: _saving ? null : _save,
          ),
          _heading('EVERY LOOK THE HEART CAN WEAR'),
          SizedBox(
            height: 176,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 8,
              itemBuilder: (BuildContext _, int i) => Container(
                width: 150,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[Color(0xFF7A1F33), Color(0xFF4A0E17)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: IvoryColors.hairlineStrong),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    HeartPaint(size: 128, fill: 0.7, tier: i + 1),
                    Text(
                      i < _tiers.length
                          ? '${_tiers[i]['name']}'.toUpperCase()
                          : '',
                      style: const TextStyle(
                        color: IvoryColors.cream,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _heading('GLOW TIERS'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: IvoryTheme.card(),
            child: Column(
              children: <Widget>[
                for (final Map<String, dynamic> t in _tiers)
                  ListTile(
                    dense: true,
                    title: Text(
                      '${t['name']}',
                      style: const TextStyle(
                        color: IvoryColors.burgundy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: Text('${t['min_days']} lit days in a row'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      color: IvoryColors.plum,
                      onPressed: () => _editTier(t),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'A day is lit when its points reach the line. Lit days in a row '
            'are the glow; each tier is a look the heart wears. A missed day '
            'spends one mend if the member holds one, otherwise the glow '
            'restarts (the best glow is always kept). The heart is never for '
            'sale. Changes apply from the next action a member takes.',
            style: TextStyle(
              color: IvoryColors.textFaint,
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// END OF FILE - lib/screens/admin_heart_tab.dart
