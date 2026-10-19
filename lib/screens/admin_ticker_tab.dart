import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/ivory_errors.dart';
import '../services/ticker_service.dart';
import '../theme/ivory_theme.dart';
import '../widgets/ticker_palettes.dart';
import 'admin_ticker_notes.dart';

/// ============================================================
/// ADMIN STUDIO - THE IVORY TICKER
///
/// The slim ribbons that glide across the top of members' screens.
/// Here the house can switch the Ticker off, set how often a ribbon
/// appears and how long it takes to cross, choose which of the ten
/// colours are used, change or switch off the wording for each kind
/// of moment, and write its own announcements (with a colour, an
/// optional link, a Grand look, and a time to stop). Every ribbon the
/// members see is built from something real; nothing here invents a
/// member's achievement.
/// ============================================================
class AdminTickerTab extends StatefulWidget {
  const AdminTickerTab({super.key});

  @override
  State<AdminTickerTab> createState() => _AdminTickerTabState();
}

class _AdminTickerTabState extends State<AdminTickerTab> {
  /// Plain words for each kind, so two rows with the same heading can be
  /// told apart.
  static const Map<String, String> _what = <String, String>{
    'mark': 'a Mark is earned',
    'treasure': 'a treasure is earned',
    'treasure_gift': 'a treasure with a discount',
    'rung': 'a rung is climbed',
    'fullday': 'a Full Day',
    'bellset': 'new bells are worn',
    'pledge': 'a pledge is kept',
    'glow': 'a Golden Heart streak',
    'peal': 'a Full Peal streak',
    'knockoff10': 'a perfect Knock-off',
    'gift': 'a gift on a post',
    'gift_live': 'a gift in a live session',
    'welcome': 'a new member',
    'post': 'a new post',
    'live': 'Admin goes live',
    'private': 'a private session',
    'note': 'your own announcement',
  };

  SupabaseClient get _db => Supabase.instance.client;

  bool _loading = true;
  bool _busy = false;
  String? _error;

  bool _on = true;
  int _gap = 30;
  int _ownMin = 5;
  int _ownMax = 10;
  int _cross = 10;
  int _grand = 13;
  int _delay = 20;
  int _lane = 0;
  bool _cheersKnown = false;
  bool _cheersOn = true;
  int _cheersCap = 20;
  Set<int> _off = <int>{};
  List<Map<String, dynamic>> _kinds = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  int _i(dynamic v, int d) => v is num ? v.toInt() : d;

  Future<void> _load() async {
    try {
      final dynamic s = await _db
          .from('ticker_settings')
          .select()
          .eq('id', 1)
          .maybeSingle();
      final dynamic k = await _db
          .from('ticker_kinds')
          .select()
          .order('sort', ascending: true);
      if (!mounted) return;
      final Map<String, dynamic> m = s is Map
          ? Map<String, dynamic>.from(s)
          : <String, dynamic>{};
      setState(() {
        _on = m['is_on'] != false;
        _gap = _i(m['gap_seconds'], 30);
        _ownMin = _i(m['own_min_minutes'], 5);
        _ownMax = _i(m['own_max_minutes'], 10);
        _cross = _i(m['cross_seconds'], 10);
        _grand = _i(m['grand_seconds'], 13);
        _delay = _i(m['start_delay_seconds'], 20);
        _lane = _i(m['lane_offset'], 0);
        _cheersKnown = m.containsKey('cheers_on');
        _cheersOn = m['cheers_on'] != false;
        _cheersCap = _i(m['cheers_daily_cap'], 20);
        _off = m['colours_off'] is List
            ? (m['colours_off'] as List).map((dynamic e) => _i(e, 0)).toSet()
            : <int>{};
        _kinds = (k as List)
            .map((dynamic e) => Map<String, dynamic>.from(e as Map))
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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final int hi = _ownMax < _ownMin ? _ownMin : _ownMax;
      await _db.from('ticker_settings').update(<String, dynamic>{
        'is_on': _on,
        'gap_seconds': _gap,
        'own_min_minutes': _ownMin,
        'own_max_minutes': hi,
        'cross_seconds': _cross,
        'grand_seconds': _grand,
        'start_delay_seconds': _delay,
        'lane_offset': _lane,
        'colours_off': (_off.toList()..sort()),
        if (_cheersKnown) 'cheers_on': _cheersOn,
        if (_cheersKnown) 'cheers_daily_cap': _cheersCap,
      }).eq('id', 1);
      _say('Saved. Members see it within about five minutes.');
      await _load();
      TickerService.instance.pull();
    } catch (e) {
      _say(adminDetail(e));
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _kindOn(Map<String, dynamic> k, bool v) async {
    try {
      await _db
          .from('ticker_kinds')
          .update(<String, dynamic>{'is_on': v})
          .eq('kind', k['kind'] as String);
      await _load();
    } catch (e) {
      _say(adminDetail(e));
    }
  }

  Future<void> _editKind(Map<String, dynamic> k) async {
    final TextEditingController c =
        TextEditingController(text: '${k['template']}');
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text('${k['label']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              controller: c,
              maxLines: 3,
              maxLength: 160,
              decoration: const InputDecoration(labelText: 'Wording'),
            ),
            const Text(
              'Use {name} for the member, {thing} for what they earned, '
              '{n} for a number and {extra} where a second name is needed.',
              style: TextStyle(color: IvoryColors.plum, fontSize: 12),
            ),
          ],
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
    final String t = c.text.trim();
    if (ok != true) return;
    if (t.length < 3) {
      _say('Please write at least a few words.');
      return;
    }
    try {
      await _db
          .from('ticker_kinds')
          .update(<String, dynamic>{'template': t})
          .eq('kind', k['kind'] as String);
      _say('Saved.');
      await _load();
    } catch (e) {
      _say(adminDetail(e));
    }
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
          onPressed: _busy || v <= min
              ? null
              : () => on((v - step).clamp(min, max)),
          icon: const Icon(Icons.remove_circle_outline),
        ),
        SizedBox(
          width: 40,
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
          onPressed: _busy || v >= max
              ? null
              : () => on((v + step).clamp(min, max)),
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }

  Widget _swatch(TickerPalette p) => Container(
    width: 16,
    height: 16,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(colors: <Color>[p.base, p.mid, p.light]),
      border: Border.all(color: p.trim, width: 1),
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
          _heading('THE IVORY TICKER'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: IvoryTheme.card(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: IvoryColors.cream,
                  title: const Text(
                    'Show ribbons to members',
                    style: TextStyle(
                      color: IvoryColors.burgundy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: const Text(
                    'Slim ribbons glide across the top of the screen to '
                    'celebrate real moments: Marks, rungs, treasures, new '
                    'stories and more. Switch off to stop them for everyone.',
                    style: TextStyle(color: IvoryColors.plum),
                  ),
                  value: _on,
                  onChanged: _busy ? null : (bool v) => setState(() => _on = v),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Every ribbon is built from something that really happened. '
                  'A member who switched their Showcase off is never named. '
                  'A member sees their own moments in the same public wording '
                  'as anyone else\'s.',
                  style: TextStyle(color: IvoryColors.plum, fontSize: 12.5, height: 1.4),
                ),
              ],
            ),
          ),
          _heading('HOW OFTEN AND HOW LONG'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: IvoryTheme.card(),
            child: Column(
              children: <Widget>[
                _stepper('A ribbon about every (seconds)', _gap, 5, 10, 900,
                    (int v) => setState(() => _gap = v)),
                _stepper('Quiet at the start (seconds)', _delay, 5, 0, 300,
                    (int v) => setState(() => _delay = v)),
                _stepper('Crossing takes (seconds)', _cross, 1, 5, 25,
                    (int v) => setState(() => _cross = v)),
                _stepper('Grand crossing takes (seconds)', _grand, 1, 6, 30,
                    (int v) => setState(() => _grand = v)),
                _stepper('A member\'s own moment, at soonest (minutes)',
                    _ownMin, 1, 1, 120, (int v) => setState(() => _ownMin = v)),
                _stepper('A member\'s own moment, at latest (minutes)',
                    _ownMax, 1, 1, 240, (int v) => setState(() => _ownMax = v)),
                _stepper('Move the ribbon lower (pixels)', _lane, 4, -30, 120,
                    (int v) => setState(() => _lane = v)),
              ],
            ),
          ),
          _heading('CHEERS'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: IvoryTheme.card(),
            child: !_cheersKnown
                ? const Text(
                    'Cheers are not set up in the database yet. Run the '
                    'Cheers database sheet and this section comes alive.',
                    style: TextStyle(color: IvoryColors.plum, height: 1.4),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: IvoryColors.cream,
                        title: const Text(
                          'Let members send cheers',
                          style: TextStyle(
                            color: IvoryColors.burgundy,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        subtitle: const Text(
                          'Touching a ribbon opens a small sheet: four '
                          'wordless cheers (applause, sparkle, heart, crown) '
                          'and OPEN IT. The member is told in one note per '
                          'moment. Switch off and ribbons simply open as before.',
                          style: TextStyle(color: IvoryColors.plum),
                        ),
                        value: _cheersOn,
                        onChanged: _busy
                            ? null
                            : (bool v) => setState(() => _cheersOn = v),
                      ),
                      _stepper('Cheers a member can send each day', _cheersCap,
                          1, 1, 100, (int v) => setState(() => _cheersCap = v)),
                      const Text(
                        'Cheers are only for moments of members, never for '
                        'private sessions, new posts, live calls or your own '
                        'announcements. Being cheered 10, 50 and 200 times '
                        'earns the three keepsake treasures (change them in '
                        'REWARDS).',
                        style: TextStyle(
                          color: IvoryColors.plum,
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
          ),
          _heading('COLOURS'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: IvoryTheme.card(),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: <Widget>[
                for (int i = 0; i < kTickerPalettes.length; i++)
                  FilterChip(
                    avatar: _swatch(kTickerPalettes[i]),
                    label: Text(kTickerPalettes[i].name),
                    selected: !_off.contains(i + 1),
                    onSelected: _busy
                        ? null
                        : (bool v) => setState(() {
                            if (v) {
                              _off.remove(i + 1);
                            } else if (_off.length < kTickerPalettes.length - 1) {
                              _off.add(i + 1);
                            }
                          }),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _busy ? null : _save,
              child: Text(_busy ? 'SAVING...' : 'SAVE THESE SETTINGS'),
            ),
          ),
          _heading('WORDING FOR EACH MOMENT'),
          for (final Map<String, dynamic> k in _kinds)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: IvoryTheme.card(),
              child: ListTile(
                onTap: () => _editKind(k),
                title: Text(
                  '${k['label']}  \u00B7  ${_what[k['kind']] ?? k['kind']}',
                  style: const TextStyle(
                    color: IvoryColors.burgundy,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                    letterSpacing: 1.2,
                  ),
                ),
                subtitle: Text(
                  '${k['template']}',
                  style: const TextStyle(color: IvoryColors.plum),
                ),
                trailing: Switch(
                  value: k['is_on'] != false,
                  onChanged: (bool v) => _kindOn(k, v),
                ),
              ),
            ),
          const AdminTickerNotes(),
        ],
      ),
    );
  }
}

// END OF FILE - lib/screens/admin_ticker_tab.dart
