import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/ivory_errors.dart';
import '../models/ivory_post.dart';
import '../services/early_service.dart';
import '../widgets/dawn_key.dart';
import 'dawn_screening.dart';
import '../widgets/lane_law.dart';
import '../widgets/post_actions.dart';

/// ============================================================
/// IVORY - THE EARLY DOOR SHEET, AWAKENED (CC.229)
///
/// The Dawn Door: the sky of first light behind, the member's own brass
/// key and Dawn Circle rank at the top, the Dawn Note from Ivory, the
/// keyhole that turns once a day for a finished task, the held stories
/// with their countdowns and golden keys, the streak ladder, and the one
/// quiet band that carries devotion to the premium tiers. The old read
/// flow, the lane law and the push switch stand exactly as proven.
/// ============================================================
Future<void> showEarlyDoorSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _EarlyDoorSheet(),
  );
}

class _EarlyDoorSheet extends StatefulWidget {
  const _EarlyDoorSheet();

  @override
  State<_EarlyDoorSheet> createState() => _EarlyDoorSheetState();
}

class _EarlyDoorSheetState extends State<_EarlyDoorSheet> {
  Timer? _tick;
  bool _busy = false;
  Map<String, dynamic> _d = <String, dynamic>{};
  final Map<int, String> _peeks = <int, String>{};

  @override
  void initState() {
    super.initState();
    EarlyService.instance.state.addListener(_changed);
    EarlyService.instance.refresh(force: true);
    _dawn();
    // CC.215: while the early door is open the ribbon lane waits, so
    // the new back arrow is never covered mid-crossing.
    LaneLaw.topBusy.value = true;
    _tick = Timer.periodic(const Duration(seconds: 20), (Timer _) {
      if (mounted) {
        setState(() {});
        _dawn();
      }
    });
  }

  @override
  void dispose() {
    LaneLaw.topBusy.value = false;
    EarlyService.instance.state.removeListener(_changed);
    _tick?.cancel();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _dawn() async {
    final Map<String, dynamic> m = await EarlyService.instance.dawnReport();
    if (mounted) setState(() => _d = m);
  }

  void _say(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  int _int(String k) => (_d[k] is int) ? _d[k] as int : 0;
  String _str(String k) => (_d[k] ?? '').toString();

  Future<void> _push(bool on) async {
    setState(() => _busy = true);
    try {
      await EarlyService.instance.setPush(on);
    } catch (e) {
      _say(houseMessage(e));
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _turn() async {
    setState(() => _busy = true);
    final Map<String, dynamic> m = await EarlyService.instance.dawnTaskTurn();
    if (mounted) setState(() => _busy = false);
    if (m['ok'] == true) {
      _say('The keyhole is turned. One peek is yours today.');
      await _dawn();
    } else {
      _say('${m['why']}');
    }
  }

  Future<void> _peek(EarlyPost p) async {
    setState(() => _busy = true);
    final Map<String, dynamic> m = await EarlyService.instance.dawnPeek(p.id);
    if (mounted) setState(() => _busy = false);
    if (m['ok'] == true) {
      setState(() => _peeks[p.id] = '${m['teaser']}');
      await _dawn();
    } else {
      _say(m['why'] == 'already'
          ? 'You have looked through this keyhole today.'
          : '${m['why']}');
    }
  }

  Future<void> _golden(EarlyPost p) async {
    setState(() => _busy = true);
    final Map<String, dynamic> m = await EarlyService.instance.dawnGolden(p.id);
    if (mounted) setState(() => _busy = false);
    if (m['ok'] != true) {
      _say('${m['why']}');
      return;
    }
    await _dawn();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (BuildContext c) => AlertDialog(
        backgroundColor: const Color(0xFFFFF6E5),
        title: Text('${m['title']}',
            style: const TextStyle(color: Color(0xFF4A0E17), fontSize: 17)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text('${m['body']}',
                style: const TextStyle(
                    color: Color(0xFF3A2318), fontSize: 14, height: 1.55)),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('CLOSE THE DOOR SOFTLY'),
          ),
        ],
      ),
    );
  }

  Future<void> _read(EarlyPost p) async {
    if (!p.canOpen) {
      _say('This opens for you ${earlyCountdown(p.opensAt)}, on '
          '${earlyClock(p.opensAt)}. Everyone has it ${earlyCountdown(p.publicAt)}.');
      return;
    }
    try {
      final List<dynamic> rows = await Supabase.instance.client
          .from('post_previews')
          .select()
          .eq('id', p.id)
          .limit(1);
      if (rows.isEmpty || !mounted) return;
      final IvoryPost post = IvoryPost.fromPreview(
        Map<String, dynamic>.from(rows.first as Map),
      );
      await PostActions.open(context, post);
    } catch (e) {
      _say(houseMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final EarlyState? s = EarlyService.instance.state.value;
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Stack(
          children: <Widget>[
            const DawnSky(seam: 0.24),
            SafeArea(
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 10, 10, 0),
                    child: Row(
                      children: <Widget>[
                        const Expanded(
                          child: Text('THE EARLY DOOR',
                              style: TextStyle(
                                  color: Color(0xFFFFE9A8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2.6)),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close,
                              color: Color(0xFFFFD98A)),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 6),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'the door creaked open at 06:07 IST · '
                            '${_int('foot_today') > 0 ? '${_int('foot_today')} walked in before the world today' : 'the first footsteps are yours'}',
                            style: const TextStyle(
                                color: Color(0xCCFFE9A8), fontSize: 11.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 26),
                      children: <Widget>[
                        _keyRow(s),
                        _noteCard(),
                        _taskRow(),
                        if (s != null) ..._posts(s),
                        _ladder(),
                        const SizedBox(height: 12),
                        PremiumDawnBand(
                          discount: _int('discount'),
                          cap: _int('cap'),
                          streak: _int('streak'),
                          onTap: () {
                            Navigator.pop(context);
                            _say('The tiers wait on your profile, in the '
                                'Premium room - your dawns travel with you.');
                          },
                        ),
                        if (_d['plaque'] == true) ...<Widget>[
                          const SizedBox(height: 10),
                          const Text(
                              'Your name is on this season\'s Dawn Plaque. '
                              'Ten dawns, kept.',
                              style: TextStyle(
                                  color: Color(0xFFFFE9A8), fontSize: 12.5)),
                        ],
                        const SizedBox(height: 12),
                        _pushRow(s),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _keyRow(EarlyState? s) {
    final int waiting = s?.waiting ?? 0;
    final int reads = _int('reads');
    final int next = _int('next_at');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: <Widget>[
          BrassKey(rank: _str('rank'), glow: waiting > 0, size: 68),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                DawnRankChip(rank: _str('rank'), streak: _int('streak')),
                const SizedBox(height: 7),
                Text(
                  'streak ${_int('streak')} · best ${_int('best')} · '
                  '${reads} early read${reads == 1 ? '' : 's'}',
                  style: const TextStyle(
                      color: Color(0xE6FFF6E5), fontSize: 12),
                ),
                if (next > 0) ...<Widget>[
                  const SizedBox(height: 3),
                  Text(
                    '${next - reads} more and you are '
                    '${next == 5 ? 'a Dawn Regular' : next == 12 ? 'a Dawn Keeper' : next == 25 ? 'of the Inner Room' : 'a Dawn Visitor'}',
                    style: const TextStyle(
                        color: Color(0xAAFFE9A8), fontSize: 11.5),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _noteCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xF2FFF6E5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFB9822B), width: 1.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('THE DAWN NOTE',
              style: TextStyle(
                  color: Color(0xFF8A5E1C),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.8)),
          const SizedBox(height: 6),
          Text(_str('note'),
              style: const TextStyle(
                  color: Color(0xFF3A2318),
                  fontSize: 13.5,
                  height: 1.5,
                  fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _taskRow() {
    if (_d['peek_turn'] == true) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x88FFD98A), width: 1.1),
        ),
        child: const Row(
          children: <Widget>[
            Icon(Icons.key, size: 15, color: Color(0xFFFFD98A)),
            SizedBox(width: 8),
            Expanded(
              child: Text('The keyhole is turned today - one peek is yours.',
                  style: TextStyle(color: Color(0xFFFFE9A8), fontSize: 12.5)),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ElevatedButton(
          onPressed: _busy ? null : _turn,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE7B14C),
            foregroundColor: const Color(0xFF3E1570),
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26)),
          ),
          child: const Text('TURN THE KEYHOLE',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 5, bottom: 12),
          child: Text(
            'light your Golden Heart today, or finish today\'s question - '
            'then one keyhole turns.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xAAFFE9A8), fontSize: 11),
          ),
        ),
      ],
    );
  }

  List<Widget> _posts(EarlyState s) {
    final List<Widget> out = <Widget>[];
    if (!s.paid) {
      out.add(ScreeningTease(
          seats: _int('seats_today'), superCount: _int('super_today')));
    }
    if (s.posts.isEmpty) {
      out.add(const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: Text('Nothing is held behind the door right now. When a '
            'story is held, it waits here first - for the dawn people.',
        style: TextStyle(color: Color(0xCCFFF6E5), fontSize: 12.5),
      )));
      return out;
    }
    for (final EarlyPost p in s.posts) {
      out.add(Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: const Color(0x26FFF6E5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x55FFE9A8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(p.title,
                style: const TextStyle(
                    color: Color(0xFFFFF6E5),
                    fontSize: 15,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 5),
            Text(
              p.canOpen
                  ? 'open for you now · everyone at ${earlyClock(p.publicAt)}'
                  : 'opens for you ${earlyCountdown(p.opensAt)} · everyone '
                      '${earlyCountdown(p.publicAt)}',
              style: const TextStyle(color: Color(0xCCFFE9A8), fontSize: 11.5),
            ),
            const SizedBox(height: 9),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                if (p.canOpen)
                  _btn('READ NOW', () => _read(p), true),
                if (s.paid)
                  _btn('FIRST SCREENING', () => _screen(p), false),
                if (!p.canOpen && _int('golden') > 0)
                  _btn('USE A GOLDEN KEY', () => _golden(p), true),
                if (!p.canOpen &&
                    _d['peek_turn'] == true &&
                    !_peeks.containsKey(p.id))
                  _btn('PEEK', () => _peek(p), false),
              ],
            ),
            if (_peeks.containsKey(p.id)) KeyholeTeaser(teaser: _peeks[p.id]!),
          ],
        ),
      ));
    }
    return out;
  }

  void _screen(EarlyPost p) {
    Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => DawnScreening(postId: p.id)));
  }

  Widget _btn(String label, VoidCallback onTap, bool gold) {
    return GestureDetector(
      onTap: _busy ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          gradient: gold
              ? const LinearGradient(
                  colors: <Color>[Color(0xFFF0C060), Color(0xFFC98A2E)])
              : null,
          color: gold ? null : const Color(0x22FFE9A8),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
              color: gold ? const Color(0xFF8A5E1C) : const Color(0x88FFE9A8)),
        ),
        child: Text(label,
            style: TextStyle(
                color: gold ? const Color(0xFF3E1570) : const Color(0xFFFFE9A8),
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4)),
      ),
    );
  }

  Widget _ladder() {
    final int st = _int('streak');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x44FFE9A8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('THE DAWN LADDER',
              style: TextStyle(
                  color: Color(0xFFFFE9A8),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.8)),
          const SizedBox(height: 6),
          Text(
            '3 dawns in a row: a spare keyhole token${st >= 3 ? ' - earned' : ''}.\n'
            '7 dawns: a Golden Key - one held story, whole, before its hour'
            '${st >= 7 ? ' - earned' : ''}.\n'
            '10 dawns: your name on the season\'s Dawn Plaque'
            '${_d['plaque'] == true ? ' - it is there' : ''}.',
            style: const TextStyle(
                color: Color(0xD9FFF6E5), fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _pushRow(EarlyState? s) {
    return Row(
      children: <Widget>[
        Switch(
          value: s?.pushOn ?? true,
          onChanged: _busy ? null : _push,
          activeColor: const Color(0xFFE7B14C),
        ),
        const Expanded(
          child: Text('whisper to me when the door opens',
              style: TextStyle(color: Color(0xCCFFF6E5), fontSize: 12)),
        ),
      ],
    );
  }
}

// END OF FILE - lib/screens/early_door_sheet.dart
