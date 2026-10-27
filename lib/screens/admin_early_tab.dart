import 'package:flutter/material.dart';

import '../core/ivory_errors.dart';
import '../services/early_service.dart';
import '../theme/ivory_theme.dart';
import '../widgets/admin_stat_grid.dart';
import 'admin_dawn_desk.dart';

/// ============================================================
/// ADMIN STUDIO - THE EARLY DOOR
///
/// The master switch, the numbers (paid members always read early;
/// others by rung while their Golden Heart is lit), how many hours
/// each rung reads ahead, and which stories are held right now. A
/// story that is free for everyone can be held for a number of hours;
/// paid-tier stories and stories a member bought are never held.
/// ============================================================
class AdminEarlyTab extends StatefulWidget {
  const AdminEarlyTab({super.key});

  @override
  State<AdminEarlyTab> createState() => _AdminEarlyTabState();
}

class _AdminEarlyTabState extends State<AdminEarlyTab> {
  Map<String, dynamic> _data = <String, dynamic>{};
  bool _open = true;
  bool _paidFull = true;
  bool _push = true;
  int _defaultHours = 0;
  int _warmDays = 3;
  int _callExtra = 7;
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
      final Map<String, dynamic> d = await EarlyService.instance.adminState();
      final Map<String, dynamic> st = d['settings'] is Map
          ? Map<String, dynamic>.from(d['settings'] as Map)
          : <String, dynamic>{};
      if (!mounted) return;
      setState(() {
        _data = d;
        _open = st['is_open'] != false;
        _paidFull = st['paid_full'] != false;
        _push = st['push_on'] != false;
        _defaultHours = (st['default_post_hours'] as num?)?.toInt() ?? 0;
        _warmDays = (st['warm_days'] as num?)?.toInt() ?? 3;
        _callExtra = (st['call_extra_days'] as num?)?.toInt() ?? 7;
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

  List<Map<String, dynamic>> _list(String k) {
    final dynamic v = _data[k];
    return v is List
        ? v.map((dynamic e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];
  }

  int get _heldNow => _list('posts').where((Map<String, dynamic> p) {
    final DateTime? t = DateTime.tryParse('${p['public_at']}');
    return t != null && t.isAfter(DateTime.now());
  }).length;

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await EarlyService.instance.adminSave(
        open: _open,
        defaultHours: _defaultHours,
        warmDays: _warmDays,
        paidFull: _paidFull,
        callExtraDays: _callExtra,
        pushOn: _push,
      );
      _say('Saved.');
      await _load();
    } catch (e) {
      _say(adminDetail(e));
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _editWindow(Map<String, dynamic> w) async {
    final TextEditingController c = TextEditingController(text: '${w['hours']}');
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text('${w['name']}: hours read early'),
        content: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Hours (0 = none, up to 720)',
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final int? h = int.tryParse(c.text.trim());
    if (h == null || h < 0 || h > 720) {
      _say('Please give hours between 0 and 720.');
      return;
    }
    try {
      await EarlyService.instance.adminWindow((w['rung'] as num).toInt(), h);
      _say('Saved.');
      await _load();
    } catch (e) {
      _say(adminDetail(e));
    }
  }

  Future<void> _editPost(Map<String, dynamic> p) async {
    final TextEditingController c = TextEditingController(text: '24');
    final String? act = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text('${p['title']}', maxLines: 2, overflow: TextOverflow.ellipsis),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _status(p),
              style: const TextStyle(color: IvoryColors.plum),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: c,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Hold for how many hours from now?',
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'open'),
            child: const Text('OPEN TO ALL NOW'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'hold'),
            child: const Text('HOLD'),
          ),
        ],
      ),
    );
    if (act == null) return;
    int h = 0;
    if (act == 'hold') {
      final int? v = int.tryParse(c.text.trim());
      if (v == null || v < 1 || v > 720) {
        _say('Please give hours between 1 and 720.');
        return;
      }
      h = v;
    }
    try {
      final String m =
          await EarlyService.instance.adminSetPost((p['id'] as num).toInt(), h);
      _say(m);
      await _load();
    } catch (e) {
      _say(adminDetail(e));
    }
  }

  String _status(Map<String, dynamic> p) {
    final DateTime? t = DateTime.tryParse('${p['public_at']}')?.toLocal();
    if (t == null) return 'Open to everyone.';
    if (t.isAfter(DateTime.now())) {
      return 'Held for early readers until ${earlyClock(t)}.';
    }
    return 'Was early; open to everyone since ${earlyClock(t)}.';
  }

  Widget _heading(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 22, 2, 10),
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

  Widget _switch(String title, String sub, bool v, ValueChanged<bool> on) =>
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        activeThumbColor: IvoryColors.cream,
        title: Text(
          title,
          style: const TextStyle(
            color: IvoryColors.burgundy,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(sub, style: const TextStyle(color: IvoryColors.plum)),
        value: v,
        onChanged: _busy ? null : on,
      );

  Widget _stepper(String label, int v, int step, int min, int max,
      ValueChanged<int> on) {
    return Row(
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
          color: IvoryColors.burgundy,
          onPressed: _busy || v <= min ? null : () => on((v - step).clamp(min, max)),
          icon: const Icon(Icons.remove_circle_outline),
        ),
        SizedBox(
          width: 34,
          child: Text(
            '$v',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: IvoryColors.burgundy,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        IconButton(
          color: IvoryColors.burgundy,
          onPressed: _busy || v >= max ? null : () => on((v + step).clamp(min, max)),
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }

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
          GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => const AdminDawnDesk())),
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                    colors: <Color>[Color(0xFF3E1570), Color(0xFF2A1650)]),
                border: Border.all(color: const Color(0x88FFE9A8)),
              ),
              alignment: Alignment.center,
              child: const Text('OPEN THE DAWN DESK',
                  style: TextStyle(
                      color: Color(0xFFFFE9A8),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2)),
            ),
          ),
          _heading('THE NUMBERS'),
          AdminStatGrid(
            children: <Widget>[
              _stat('Doors open now', '${_data['doors_open'] ?? 0}'),
              _stat('Stories held now', '$_heldNow'),
              _stat('Early reads', '${_data['early_reads'] ?? 0}'),
              _stat('Door switch', _open ? 'ON' : 'OFF'),
            ],
          ),
          _heading('SETTINGS'),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
            decoration: IvoryTheme.card(),
            child: Column(
              children: <Widget>[
                _switch(
                  'Early Door is open',
                  'Off holds nothing back and hides the door from members.',
                  _open,
                  (bool v) => setState(() => _open = v),
                ),
                _switch(
                  'Paid members always read early',
                  'On: paid members read every early story at once. Off: they follow their rung like everyone.',
                  _paidFull,
                  (bool v) => setState(() => _paidFull = v),
                ),
                _switch(
                  'Notify when a story opens early',
                  'One message to members who can read it now (they can switch it off).',
                  _push,
                  (bool v) => setState(() => _push = v),
                ),
                _stepper(
                  'Hold every new free story (hours, 0 = off)',
                  _defaultHours, 6, 0, 720,
                  (int v) => setState(() => _defaultHours = v),
                ),
                _stepper(
                  'Heart must be lit within (days)',
                  _warmDays, 1, 1, 30,
                  (int v) => setState(() => _warmDays = v),
                ),
                _stepper(
                  'Extra days to book a call ahead',
                  _callExtra, 1, 0, 60,
                  (int v) => setState(() => _callExtra = v),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Members whose door is open can book a call this many days further ahead than your call settings allow everyone else.',
                  style: TextStyle(color: IvoryColors.plum, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: IvoryColors.burgundy,
                    ),
                    onPressed: _busy ? null : _save,
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
          _heading('HOURS EACH RUNG READS AHEAD (TAP TO EDIT)'),
          ..._list('windows').map(
            (Map<String, dynamic> w) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: IvoryTheme.card(),
              child: ListTile(
                onTap: () => _editWindow(w),
                title: Text(
                  '${w['rung']}.  ${w['name']}',
                  style: const TextStyle(
                    color: IvoryColors.burgundy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: Text(
                  '${w['hours']} hours early  \u00B7  from ${w['min_points']} climb points',
                  style: const TextStyle(color: IvoryColors.plum),
                ),
                trailing: const Icon(Icons.edit_outlined, color: IvoryColors.plum),
              ),
            ),
          ),
          _heading('RECENT STORIES (TAP TO HOLD OR OPEN)'),
          ..._list('posts').map(
            (Map<String, dynamic> p) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: IvoryTheme.card(),
              child: ListTile(
                onTap: () => _editPost(p),
                title: Text(
                  '${p['title']}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: IvoryColors.burgundy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: Text(
                  _status(p),
                  style: const TextStyle(color: IvoryColors.plum),
                ),
                trailing: const Icon(Icons.edit_outlined, color: IvoryColors.plum),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// END OF FILE - lib/screens/admin_early_tab.dart
