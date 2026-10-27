// ============================================================
// IVORY - THE FIRST SCREENING ROOM (CC.229 rev 2)
// Premium members are the director's final audience: they read the
// held cut whole before the world, seal a verdict (release it, or
// hold for notes), and stake a call (super hit, slow burn, sleeper).
// Ivory settles the call from her desk; true calls earn Seer marks.
// Forever members never reach this room - they see the tease outside.
// ============================================================
import 'package:flutter/material.dart';

import '../services/early_service.dart';
import '../widgets/dawn_key.dart';

class DawnScreening extends StatefulWidget {
  const DawnScreening({super.key, required this.postId});
  final int postId;

  @override
  State<DawnScreening> createState() => _DawnScreeningState();
}

class _DawnScreeningState extends State<DawnScreening> {
  Map<String, dynamic>? _v;
  bool _busy = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final Map<String, dynamic> r =
        await EarlyService.instance.dawnScreen(widget.postId);
    if (!mounted) return;
    setState(() {
      _v = r;
      _busy = false;
    });
  }

String _held(Map<String, dynamic> v) {
    try {
      final DateTime at = DateTime.parse(v['public_at'].toString()).toLocal();
      final Duration d = at.difference(DateTime.now());
      if (d.isNegative) return 'the world can see it now';
      return '${d.inHours} h ${d.inMinutes % 60} m until the world sees it';
    } catch (_) {
      return 'held before the world';
    }
  }

  int _i(dynamic x) => x is int ? x : (x is num ? x.toInt() : 0);

  Future<void> _seal(String verdict, String note, String hype) async {
    setState(() => _saving = true);
    final Map<String, dynamic> r = await EarlyService.instance.dawnVerdict(
      postId: widget.postId,
      verdict: verdict,
      note: note,
      hype: hype,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    final String msg = r['ok'] == true
        ? (verdict == 'notes'
            ? 'Your note is sealed. It goes straight to Ivory\u2019s desk.'
            : 'Release sealed. Your call: \u201c${hypeLabel(hype)}\u201d.')
        : 'The desk would not take it. Try again at dawn.';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 4)));
    _load();
  }

  String hypeLabel(String h) => h == 'super'
      ? 'SUPER HIT'
      : h == 'slow'
          ? 'SLOW BURN'
          : 'SLEEPER';

  Future<void> _settle(String band) async {
    await EarlyService.instance.dawnSettle(postId: widget.postId, band: band);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Call settled: ${hypeLabel(band)}. '
            'The Seers are marked.')));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> v = _v ?? <String, dynamic>{};
    return Scaffold(
      backgroundColor: const Color(0xFF120A26),
      appBar: AppBar(
        backgroundColor: const Color(0xFF120A26),
        elevation: 0,
        title: const Text('THE FIRST SCREENING',
            style: TextStyle(
                color: Color(0xFFFFE9A8),
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 2)),
        iconTheme: const IconThemeData(color: Color(0xFFFFE9A8)),
      ),
      body: _busy
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFF0C060)))
          : v['ok'] != true
              ? _closed()
              : _room(v),
    );
  }

  Widget _closed() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const <Widget>[
            Icon(Icons.meeting_room_outlined,
                color: Color(0xFF9A55E6), size: 44),
            SizedBox(height: 14),
            Text('THE DOOR IS TIERED',
                style: TextStyle(
                    color: Color(0xFFFFE9A8),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.6)),
            SizedBox(height: 10),
            Text('This room is the premium\u2019s alone: the held cut read '
                'whole before the world, the verdict, and the call. '
                'Open the ladder, and the door opens with you.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Color(0xBFFFFFFF), fontSize: 13, height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _room(Map<String, dynamic> v) {
    final Map<String, dynamic>? mine =
        v['mine'] is Map<String, dynamic> ? v['mine'] as Map<String, dynamic> : null;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      children: <Widget>[
        SeerChip(
            calls: _i(v['calls']),
            seer: _i(v['seer']),
            taken: _i(v['taken'])),
        const SizedBox(height: 12),
        Text(v['title']?.toString() ?? 'the held cut',
            style: const TextStyle(
                color: Color(0xFFFFF6E5),
                fontSize: 19,
                fontWeight: FontWeight.w900,
                height: 1.3)),
        const SizedBox(height: 4),
        Text('${_held(v)} \u00b7 '
            '${_i(v['seats'])} seat${_i(v['seats']) == 1 ? '' : 's'} in the room',
            style: const TextStyle(color: Color(0x99FFE9A8), fontSize: 11)),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: const Color(0x22191036),
            border: Border.all(color: const Color(0x44FFE9A8)),
          ),
          child: Text(v['body']?.toString() ?? '',
              style: const TextStyle(
                  color: Color(0xE6FFF6E5), fontSize: 14, height: 1.6)),
        ),
        const SizedBox(height: 16),
        if (v['is_admin'] == true) _settleRow(v),
        VerdictDesk(
          busy: _saving,
          verdict: mine?['verdict']?.toString() ?? 'release',
          hype: mine?['hype']?.toString() ?? 'super',
          note: mine?['note']?.toString() ?? '',
          onSubmit: _seal,
        ),
        const SizedBox(height: 16),
        _pulse(v),
        if (mine?['taken'] == true)
          Container(
            margin: const EdgeInsets.only(top: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x887ED99A)),
            ),
            child: const Text('YOUR NOTE MOVED THE CUT.',
                style: TextStyle(
                    color: Color(0xFF7ED99A),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4)),
          ),
      ],
    );
  }

  Widget _settleRow(Map<String, dynamic> v) {
    final String band = v['settled_band']?.toString() ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x66FF6FA5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(band.isEmpty ? 'SETTLE THE CALL (desk)' : 'SETTLED: ${hypeLabel(band)}',
              style: const TextStyle(
                  color: Color(0xFFFFB3C6),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.6)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['super', 'slow', 'sleeper'].map<Widget>((String b) {
              return GestureDetector(
                onTap: () => _settle(b),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: band == b
                        ? const Color(0xFFFF6FA5)
                        : const Color(0x22FF6FA5),
                    border: Border.all(color: const Color(0x88FF6FA5)),
                  ),
                  child: Text(hypeLabel(b),
                      style: TextStyle(
                          color: band == b
                              ? const Color(0xFF2A1033)
                              : const Color(0xFFFFB3C6),
                          fontSize: 11,
                          fontWeight: FontWeight.w900)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _pulse(Map<String, dynamic> v) {
    Widget line(String label, dynamic n, Color c) => Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Row(
            children: <Widget>[
              Container(
                  width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text('$label \u00b7 ${_i(n)}',
                  style: const TextStyle(
                      color: Color(0xCCFFFFFF),
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0x189A55E6),
        border: Border.all(color: const Color(0x449A55E6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('ROOM PULSE',
              style: TextStyle(
                  color: Color(0xFFE3C7FF),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.8)),
          const SizedBox(height: 8),
          line('verdicts to RELEASE IT', v['release_n'], const Color(0xFF7ED99A)),
          line('verdicts to HOLD FOR NOTES', v['notes_n'], const Color(0xFFFFB300)),
          line('calls: SUPER HIT', v['super_n'], const Color(0xFFFF6FA5)),
          line('calls: SLOW BURN', v['slow_n'], const Color(0xFFFF9A1F)),
          line('calls: SLEEPER', v['sleeper_n'], const Color(0xFF9A55E6)),
        ],
      ),
    );
  }
}
// END OF FILE - lib/screens/dawn_screening.dart
