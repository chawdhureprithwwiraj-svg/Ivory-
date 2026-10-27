// ============================================================
// IVORY - THE DAWN DESK (CC.231)
// Your faces of the First Screening, in one room: settle the call on
// every held or recent story (your judgement is the honest metric);
// read the jury's written critiques and mark the ones that moved the
// cut; compose today's Dawn Note; turn the two dials (rupees per dawn,
// the cap); and see the Seer board - who calls it true, and often.
// ============================================================
import 'package:flutter/material.dart';

import '../services/early_service.dart';

class AdminDawnDesk extends StatefulWidget {
  const AdminDawnDesk({super.key});

  @override
  State<AdminDawnDesk> createState() => _AdminDawnDeskState();
}

class _AdminDawnDeskState extends State<AdminDawnDesk> {
  Map<String, dynamic> _d = <String, dynamic>{};
  bool _loading = true;
  bool _busy = false;
  int? _notesPost;
  List<dynamic> _notes = <dynamic>[];
  final TextEditingController _note = TextEditingController();
  final TextEditingController _per = TextEditingController();
  final TextEditingController _cap = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _note.dispose();
    _per.dispose();
    _cap.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final Map<String, dynamic> m = await EarlyService.instance.dawnDesk();
    if (!mounted) return;
    setState(() {
      _d = m;
      _loading = false;
      if (_note.text.isEmpty) {
        _note.text = (m['note_today'] ?? '').toString();
      }
      if (_per.text.isEmpty) _per.text = '${m['per_dawn'] ?? 7}';
      if (_cap.text.isEmpty) _cap.text = '${m['cap'] ?? 70}';
    });
  }

  void _say(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(m)));
  }

  List<dynamic> get _rows =>
      (_d['rows'] is List) ? _d['rows'] as List<dynamic> : <dynamic>[];

  Future<void> _settle(Map<String, dynamic> r, String band) async {
    setState(() => _busy = true);
    try {
      await EarlyService.instance
          .dawnSettle(postId: (r['id'] as num).toInt(), band: band);
      _say('Call settled: ${_bandLabel(band)}. The Seers are marked.');
      await _load();
    } catch (e) {
      _say('The desk refused: $e');
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _openNotes(Map<String, dynamic> r) async {
    final int id = (r['id'] as num).toInt();
    setState(() {
      _busy = true;
      _notesPost = id;
      _notes = <dynamic>[];
    });
    final Map<String, dynamic> m =
        await EarlyService.instance.dawnDeskNotes(id);
    if (!mounted) return;
    setState(() {
      _notes = (m['notes'] is List) ? m['notes'] as List<dynamic> : <dynamic>[];
      _busy = false;
    });
  }

  Future<void> _take(Map<String, dynamic> n, bool taken) async {
    if (_notesPost == null) return;
    setState(() => _busy = true);
    try {
      await EarlyService.instance.dawnNoteTaken(
        postId: _notesPost!,
        userId: n['user_id'].toString(),
        taken: taken,
      );
      _say(taken
          ? 'Marked taken. They will see: YOUR NOTE MOVED THE CUT.'
          : 'Unmarked.');
      await _openNotes({'id': _notesPost});
    } catch (e) {
      _say('The desk refused: $e');
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveNote() async {
    setState(() => _busy = true);
    try {
      await EarlyService.instance.dawnNoteSet(_note.text.trim());
      _say('Today\'s Dawn Note is set. The door will speak it at 06:07.');
      await _load();
    } catch (e) {
      _say('The desk refused: $e');
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _saveDials() async {
    setState(() => _busy = true);
    try {
      await EarlyService.instance.dawnAdminSave(
        per: int.parse(_per.text.trim()),
        cap: int.parse(_cap.text.trim()),
      );
      _say('The dials are turned.');
      await _load();
    } catch (e) {
      _say('The desk refused: $e');
    }
    if (mounted) setState(() => _busy = false);
  }

  String _bandLabel(String b) => b == 'super'
      ? 'SUPER HIT'
      : b == 'slow'
          ? 'SLOW BURN'
          : 'SLEEPER';

  int _n(Map<String, dynamic> m, String k) =>
      (m[k] is int) ? m[k] as int : (m[k] is num ? (m[k] as num).toInt() : 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF120A26),
      appBar: AppBar(
        backgroundColor: const Color(0xFF120A26),
        elevation: 0,
        title: const Text('THE DAWN DESK',
            style: TextStyle(
                color: Color(0xFFFFE9A8),
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 2)),
        iconTheme: const IconThemeData(color: Color(0xFFFFE9A8)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFF0C060)))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: <Widget>[
                _calls(),
                const SizedBox(height: 18),
                if (_notesPost != null) ...<Widget>[_notesBlock(), const SizedBox(height: 18)],
                _composer(),
                const SizedBox(height: 18),
                _dials(),
                const SizedBox(height: 18),
                _seers(),
              ],
            ),
    );
  }

  Widget _head(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t,
            style: const TextStyle(
                color: Color(0xFFFFE9A8),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.8)),
      );

  Widget _box(Widget child) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: const Color(0x22191036),
          border: Border.all(color: const Color(0x44FFE9A8)),
        ),
        child: child,
      );

  Widget _calls() {
    if (_rows.isEmpty) {
      return _box(const Text(
          'No story has sat in the Screening in the last fortnight. '
          'Hold one, and the jury will fill this room.',
          style: TextStyle(color: Color(0xCCFFF6E5), fontSize: 12.5)));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      _head('SETTLE THE CALL'),
      ..._rows.map((dynamic e) {
        final Map<String, dynamic> r = Map<String, dynamic>.from(e as Map);
        final String band = (r['band'] ?? '').toString();
        return _box(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(r['title']?.toString() ?? '',
                style: const TextStyle(
                    color: Color(0xFFFFF6E5),
                    fontSize: 14,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
                '${r['held'] == true ? 'HELD' : 'public now'} · '
                '${_n(r, 'seats')} seats · '
                'release ${_n(r, 'release_n')} / notes ${_n(r, 'notes_n')} · '
                'super ${_n(r, 'super_n')} / slow ${_n(r, 'slow_n')} / '
                'sleeper ${_n(r, 'sleeper_n')}',
                style: const TextStyle(color: Color(0x99FFE9A8), fontSize: 11)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>['super', 'slow', 'sleeper'].map((String b) {
                return GestureDetector(
                  onTap: _busy ? null : () => _settle(r, b),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: band == b
                          ? const Color(0xFFFF6FA5)
                          : const Color(0x22FF6FA5),
                      border: Border.all(color: const Color(0x88FF6FA5)),
                    ),
                    child: Text(_bandLabel(b),
                        style: TextStyle(
                            color: band == b
                                ? const Color(0xFF2A1033)
                                : const Color(0xFFFFB3C6),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900)),
                  ),
                );
              }).toList(),
            ),
            if (_n(r, 'written_n') > 0) ...<Widget>[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _busy ? null : () => _openNotes(r),
                child: Text('READ THE ${_n(r, 'written_n')} WRITTEN NOTE'
                    '${_n(r, 'written_n') == 1 ? '' : 'S'}',
                    style: const TextStyle(
                        color: Color(0xFF7ED99A),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2)),
              ),
            ],
          ],
        ));
      }),
    ]);
  }

  Widget _notesBlock() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      _head('THE JURY\'S NOTES'),
      ..._notes.map((dynamic e) {
        final Map<String, dynamic> n = Map<String, dynamic>.from(e as Map);
        final bool taken = n['taken'] == true;
        return _box(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
                '${n['name']} · called it ${_bandLabel(n['hype'].toString())}'
                '${taken ? ' · MOVED THE CUT' : ''}',
                style: TextStyle(
                    color: taken
                        ? const Color(0xFF7ED99A)
                        : const Color(0xCCFFE9A8),
                    fontSize: 11,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(n['note'].toString(),
                style: const TextStyle(
                    color: Color(0xE6FFF6E5), fontSize: 13, height: 1.5)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _busy ? null : () => _take(n, !taken),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: taken
                      ? const Color(0x337ED99A)
                      : const Color(0x22FFE9A8),
                  border: Border.all(
                      color: taken
                          ? const Color(0xFF7ED99A)
                          : const Color(0x66FFE9A8)),
                ),
                child: Text(taken ? 'UNMARK TAKEN' : 'MARK TAKEN',
                    style: const TextStyle(
                        color: Color(0xFFFFF6E5),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2)),
              ),
            ),
          ],
        ));
      }),
      if (_notes.isEmpty)
        _box(const Text('No written notes on this story yet.',
            style: TextStyle(color: Color(0xCCFFF6E5), fontSize: 12.5))),
    ]);
  }

  Widget _composer() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      _head('TODAY\'S DAWN NOTE'),
      _box(Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        TextField(
          controller: _note,
          maxLines: 3,
          maxLength: 240,
          style: const TextStyle(color: Color(0xFFFFF6E5), fontSize: 13),
          decoration: const InputDecoration(
            hintText: 'One line for the dawn people. Leave empty and the '
                'house seeds speak instead.',
            hintStyle: TextStyle(color: Color(0x80FFE9A8)),
            counterStyle: TextStyle(color: Color(0x66FFE9A8), fontSize: 10),
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _busy ? null : _saveNote,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: <Color>[
                Color(0xFFF0C060),
                Color(0xFFC98A2E)
              ]),
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: const Text('SET TODAY\'S NOTE',
                style: TextStyle(
                    color: Color(0xFF3E1570),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.6)),
          ),
        ),
      ])),
    ]);
  }

  Widget _dials() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      _head('THE DIALS'),
      _box(Row(children: <Widget>[
        Expanded(
          child: TextField(
            controller: _per,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Color(0xFFFFF6E5)),
            decoration: const InputDecoration(
                labelText: 'rupees per dawn',
                labelStyle: TextStyle(color: Color(0x99FFE9A8), fontSize: 11)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _cap,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Color(0xFFFFF6E5)),
            decoration: const InputDecoration(
                labelText: 'the cap',
                labelStyle: TextStyle(color: Color(0x99FFE9A8), fontSize: 11)),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: _busy ? null : _saveDials,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFF0C060)),
            ),
            child: const Text('TURN',
                style: TextStyle(
                    color: Color(0xFFF0C060),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4)),
          ),
        ),
      ])),
    ]);
  }

  Widget _seers() {
    final List<dynamic> s =
        (_d['seers'] is List) ? _d['seers'] as List<dynamic> : <dynamic>[];
    if (s.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      _head('THE SEER BOARD'),
      _box(Column(children: <Widget>[
        ...s.take(8).map((dynamic e) {
          final Map<String, dynamic> r = Map<String, dynamic>.from(e as Map);
          return Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(children: <Widget>[
              Expanded(
                  child: Text(r['name'].toString(),
                      style: const TextStyle(
                          color: Color(0xE6FFF6E5), fontSize: 12.5))),
              Text(
                  '${_n(r, 'seer')} of ${_n(r, 'calls')} true'
                  '${_n(r, 'taken') > 0 ? ' · ${_n(r, 'taken')} moved the cut' : ''}',
                  style: const TextStyle(
                      color: Color(0xCCFFB3C6),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700)),
            ]),
          );
        }),
      ])),
    ]);
  }
}
// END OF FILE - lib/screens/admin_dawn_desk.dart
