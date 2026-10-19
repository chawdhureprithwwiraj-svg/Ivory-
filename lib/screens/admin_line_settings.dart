import 'package:flutter/material.dart';

import '../core/ivory_errors.dart';
import '../services/line_house_service.dart';
import '../theme/ivory_theme.dart';

/// ============================================================
/// ADMIN STUDIO - THE PRIVATE LINE: SETTINGS
///
/// The master switch, places a day, letter length, how long before
/// a letter comes back, the head start for tier and rung, the words
/// that hold a letter, the letters a week of every tier (read live,
/// so a tier added or removed later appears or disappears here), and
/// the extra letters for Ladder rungs. Nothing here is fixed.
/// ============================================================
class AdminLineSettings extends StatefulWidget {
  const AdminLineSettings({super.key, required this.data, required this.onSaved});

  /// The answer of line_admin_state.
  final Map<String, dynamic> data;

  /// Called after anything is saved, so the tab reloads.
  final VoidCallback onSaved;

  @override
  State<AdminLineSettings> createState() => _AdminLineSettingsState();
}

class _AdminLineSettingsState extends State<AdminLineSettings> {
  late bool _open;
  late bool _daily;
  late int _places;
  late int _chars;
  late int _returnDays;
  late int _retention;
  late int _window;
  late int _tierHours;
  late int _rungHours;
  late TextEditingController _words;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final Map<String, dynamic> st = widget.data['settings'] is Map
        ? Map<String, dynamic>.from(widget.data['settings'] as Map)
        : <String, dynamic>{};
    int i(String k, int d) => (st[k] as num?)?.toInt() ?? d;
    _open = st['is_open'] != false;
    _daily = st['daily_on'] != false;
    _places = i('places_per_day', 15);
    _chars = i('max_chars', 750);
    _returnDays = i('return_days', 7);
    _retention = i('retention_days', 90);
    _window = i('window_days', 7);
    _tierHours = i('tier_bonus_hours', 24);
    _rungHours = i('rung_bonus_hours', 4);
    _words = TextEditingController(text: '${widget.data['hold_words'] ?? ''}');
  }

  @override
  void dispose() {
    _words.dispose();
    super.dispose();
  }

  void _say(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  List<Map<String, dynamic>> _list(String k) {
    final dynamic v = widget.data[k];
    return v is List
        ? v.map((dynamic e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];
  }

  Future<void> _run(Future<String> Function() job) async {
    setState(() => _busy = true);
    try {
      _say(await job());
      widget.onSaved();
    } catch (e) {
      _say(adminDetail(e));
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _save() => _run(
    () => LineHouseService.instance.save(
      open: _open,
      places: _places,
      chars: _chars,
      returnDays: _returnDays,
      retentionDays: _retention,
      windowDays: _window,
      tierHours: _tierHours,
      rungHours: _rungHours,
      dailyOn: _daily,
      words: _words.text,
    ),
  );

  Future<void> _askNumber(
    String title,
    int now,
    int max,
    Future<String> Function(int v) job,
  ) async {
    final TextEditingController c = TextEditingController(text: '$now');
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'Number (0 to $max)'),
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
    final int? v = int.tryParse(c.text.trim());
    if (v == null || v < 0 || v > max) {
      _say('Please give a number from 0 to $max.');
      return;
    }
    await _run(() => job(v));
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
          color: IvoryColors.burgundy,
          onPressed:
              _busy || v <= min ? null : () => on((v - step).clamp(min, max)),
          icon: const Icon(Icons.remove_circle_outline),
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
          color: IvoryColors.burgundy,
          onPressed:
              _busy || v >= max ? null : () => on((v + step).clamp(min, max)),
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }

  Widget _row(String title, String sub, VoidCallback onTap) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: IvoryTheme.card(),
    child: ListTile(
      onTap: _busy ? null : onTap,
      title: Text(
        title,
        style: const TextStyle(
          color: IvoryColors.burgundy,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(sub, style: const TextStyle(color: IvoryColors.plum)),
      trailing: const Icon(Icons.edit_outlined, color: IvoryColors.plum),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _heading('THE LINE'),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
          decoration: IvoryTheme.card(),
          child: Column(
            children: <Widget>[
              _switch(
                'The Private Line is open',
                'Off hides it from every member. Letters are kept.',
                _open,
                (bool v) => setState(() => _open = v),
              ),
              _switch(
                'Show the Letter of the Day',
                'Off hides it on Home. Shared letters are kept.',
                _daily,
                (bool v) => setState(() => _daily = v),
              ),
              _stepper('Places a day (replies you can give)', _places, 1, 1, 40,
                  (int v) => setState(() => _places = v)),
              _stepper('Letter length (characters)', _chars, 50, 100, 2000,
                  (int v) => setState(() => _chars = v)),
              _stepper('Letters counted over (days)', _window, 1, 1, 30,
                  (int v) => setState(() => _window = v)),
              _stepper('A letter comes back after (days)', _returnDays, 1, 1,
                  60, (int v) => setState(() => _returnDays = v)),
              _stepper('Old letters kept for (days)', _retention, 7, 7, 730,
                  (int v) => setState(() => _retention = v)),
              _stepper('Head start per tier level (hours)', _tierHours, 6, 0,
                  240, (int v) => setState(() => _tierHours = v)),
              _stepper('Head start per Ladder rung (hours)', _rungHours, 1, 0,
                  48, (int v) => setState(() => _rungHours = v)),
              const SizedBox(height: 10),
              TextField(
                controller: _words,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Words that hold a letter for a look',
                  helperText: 'Separate with commas. Links, email addresses '
                      'and long numbers are always held.',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'A long wait always beats a head start, so nobody waits for '
                'ever. Places a day is the most you can answer, up to 40.',
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
        _heading('LETTERS A WEEK, BY TIER (TAP TO EDIT)'),
        ..._list('tiers').map(
          (Map<String, dynamic> t) => _row(
            '${t['name']}',
            '${t['letters']} ${t['letters'] == 1 ? 'letter' : 'letters'} in '
                'the counted days  \u00B7  tier level ${t['level']}',
            () => _askNumber(
              '${t['name']}: letters',
              (t['letters'] as num?)?.toInt() ?? 0,
              50,
              (int v) => LineHouseService.instance
                  .setTier((t['id'] as num).toInt(), v),
            ),
          ),
        ),
        _heading('EXTRA LETTERS BY LADDER RUNG (TAP TO EDIT)'),
        ..._list('rungs').map(
          (Map<String, dynamic> r) => _row(
            '${r['rung']}.  ${r['name']}',
            '+${r['extra']} extra ${r['extra'] == 1 ? 'letter' : 'letters'}',
            () => _askNumber(
              '${r['name']}: extra letters',
              (r['extra'] as num?)?.toInt() ?? 0,
              20,
              (int v) => LineHouseService.instance
                  .setRung((r['rung'] as num).toInt(), v),
            ),
          ),
        ),
      ],
    );
  }
}

// END OF FILE - lib/screens/admin_line_settings.dart
