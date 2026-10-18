import 'package:flutter/material.dart';

import '../core/ivory_errors.dart';
import '../services/bells_service.dart';
import '../theme/ivory_theme.dart';

/// ============================================================
/// ADMIN STUDIO - RING MY DOORBELL: BELL REMINDERS
///
/// The phone reminder sent when a bell opens and is still waiting.
/// Here the house switches reminders on or off, sets how long after
/// opening a reminder may still go out, optionally stops reminding
/// members who have not opened Ivory for a while, and writes each
/// bell's title and wording (one line per version; the day picks
/// which one is sent). Members can also switch them off themselves.
/// ============================================================
class AdminBellsPush extends StatefulWidget {
  const AdminBellsPush({super.key});

  @override
  State<AdminBellsPush> createState() => _AdminBellsPushState();
}

class _PushBell {
  _PushBell(this.key, this.label, this.on, String title, String bodies)
    : title = TextEditingController(text: title),
      bodies = TextEditingController(text: bodies);

  final String key;
  final String label;
  bool on;
  final TextEditingController title;
  final TextEditingController bodies;
}

class _AdminBellsPushState extends State<AdminBellsPush> {
  bool _loading = true;
  bool _busy = false;
  String? _error;
  bool _on = true;
  int _window = 90;
  int _quiet = 0;
  Map<String, dynamic> _stats = <String, dynamic>{};
  final List<_PushBell> _bells = <_PushBell>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final _PushBell b in _bells) {
      b.title.dispose();
      b.bodies.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final Map<String, dynamic> s = await BellsService.instance
          .adminPushSettings();
      final List<Map<String, dynamic>> defs = await BellsService.instance
          .adminPushBells();
      final Map<String, dynamic> st = await BellsService.instance
          .adminPushStats();
      if (!mounted) return;
      for (final _PushBell b in _bells) {
        b.title.dispose();
        b.bodies.dispose();
      }
      setState(() {
        _on = s['push_on'] != false;
        _window = (s['push_window_min'] as num?)?.toInt() ?? 90;
        _quiet = (s['push_quiet_days'] as num?)?.toInt() ?? 0;
        _stats = st;
        _bells
          ..clear()
          ..addAll(
            defs.map((Map<String, dynamic> m) {
              final dynamic bl = m['push_bodies'];
              final String lines = bl is List
                  ? bl.map((dynamic e) => '$e').join('\n')
                  : '';
              return _PushBell(
                '${m['key']}',
                '${m['label']}',
                m['push_on'] != false,
                '${m['push_title'] ?? ''}',
                lines,
              );
            }),
          );
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

  Widget _stepper(
    String label,
    int v,
    int step,
    int min,
    int max,
    ValueChanged<int> on,
  ) {
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
          onPressed: _busy || v - step < min ? null : () => on(v - step),
          icon: const Icon(Icons.remove_circle_outline),
          color: IvoryColors.plum,
        ),
        SizedBox(
          width: 44,
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
          onPressed: _busy || v + step > max ? null : () => on(v + step),
          icon: const Icon(Icons.add_circle_outline),
          color: IvoryColors.plum,
        ),
      ],
    );
  }

  Widget _bellCard(_PushBell b) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
      decoration: IvoryTheme.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: IvoryColors.burgundy,
            title: Text(
              '${b.label} bell reminder',
              style: const TextStyle(
                color: IvoryColors.burgundy,
                fontWeight: FontWeight.w800,
              ),
            ),
            value: b.on,
            onChanged: _busy ? null : (bool v) => setState(() => b.on = v),
          ),
          TextField(
            controller: b.title,
            maxLength: 60,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          TextField(
            controller: b.bodies,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Wording (one version per line)',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: IvoryColors.burgundy,
              ),
              onPressed: _busy ? null : () => _saveBell(b),
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveBell(_PushBell b) async {
    final String t = b.title.text.trim();
    final List<String> lines = b.bodies.text
        .split('\n')
        .map((String e) => e.trim())
        .where((String e) => e.isNotEmpty)
        .toList();
    if (t.isEmpty || lines.isEmpty) {
      _say('Give it a title and at least one line of wording.');
      return;
    }
    await _run(
      () => BellsService.instance.adminSaveBellPush(
        b.key,
        on: b.on,
        title: t,
        bodies: lines,
      ),
      '${b.label} reminder saved.',
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
    String n(String k) => '${(_stats[k] as num?)?.toInt() ?? 0}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (_error != null)
          Text(_error!, style: const TextStyle(color: IvoryColors.burgundy)),
        _heading('BELL REMINDERS (PHONE)'),
        Text(
          'Sent today ${n('sent_today')}  \u00b7  this week ${n('sent_week')}\n'
          'Members who can be reached ${n('listening')}  \u00b7  '
          'switched off by members ${n('opted_out')}',
          style: const TextStyle(
            color: IvoryColors.plum,
            fontSize: 12.5,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 6),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeThumbColor: IvoryColors.burgundy,
          title: const Text(
            'Send bell reminders',
            style: TextStyle(
              color: IvoryColors.burgundy,
              fontWeight: FontWeight.w700,
            ),
          ),
          value: _on,
          onChanged: _busy ? null : (bool v) => setState(() => _on = v),
        ),
        _stepper(
          'May go out up to (minutes after opening)',
          _window,
          10,
          10,
          360,
          (int v) => setState(() => _window = v),
        ),
        _stepper(
          'Stop for members away this many days (0 = never)',
          _quiet,
          5,
          0,
          365,
          (int v) => setState(() => _quiet = v),
        ),
        const SizedBox(height: 6),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: IvoryColors.burgundy,
            minimumSize: const Size.fromHeight(46),
          ),
          onPressed: _busy
              ? null
              : () => _run(
                  () => BellsService.instance.adminSavePushSettings(
                    on: _on,
                    windowMin: _window,
                    quietDays: _quiet,
                  ),
                  'Reminder settings saved.',
                ),
          child: const Text('Save reminder settings'),
        ),
        _heading('WORDING FOR EACH BELL'),
        for (final _PushBell b in _bells) _bellCard(b),
      ],
    );
  }
}

// END OF FILE - lib/screens/admin_bells_push.dart
