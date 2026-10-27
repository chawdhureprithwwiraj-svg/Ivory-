import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../services/b2_media_service.dart';
import '../services/wheel_service.dart';
import '../theme/ivory_theme.dart';
import '../widgets/wheel_painter.dart';

/// The WHEEL spoke of the owner's steering wheel (CC.224, royale pass
/// CC.226): the living miniature; today; the odds dials (weights only -
/// members see rupees, never percentages); the hours; the wish queue;
/// the word bank; the voices and images she uploads, as many at once as
/// she likes; the petals owed.
class AdminWheelTab extends StatefulWidget {
  const AdminWheelTab({super.key});

  @override
  State<AdminWheelTab> createState() => _AdminWheelTabState();
}

class _AdminWheelTabState extends State<AdminWheelTab>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic> _d = <String, dynamic>{};
  bool _busy = false;
  String _msg = '';
  late final AnimationController _t = AnimationController(
      vsync: this, duration: const Duration(seconds: 24))
    ..repeat();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final Map<String, dynamic> m = await WheelService.instance.desk();
    if (mounted) setState(() => _d = m);
  }

  List<dynamic> _list(String k) => (_d[k] as List<dynamic>?) ?? <dynamic>[];

  void _say(String s) => setState(() => _msg = s);

  Future<void> _after(Future<bool> f, String ok) async {
    setState(() => _busy = true);
    final bool good = await f;
    await _load();
    if (mounted) {
      setState(() => _busy = false);
      _say(good ? ok : 'The desk refused that - try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: <Widget>[
        if (_msg.isNotEmpty) _note(_msg),
        Center(
          child: AnimatedBuilder(
            animation: _t,
            builder: (BuildContext c, Widget? _) => CustomPaint(
              size: const Size(104, 104),
              painter: WheelPainter(
                segs: const <WheelSeg>[
                  WheelSeg('₹3', Color(0xFFFFB300), 'rupee'),
                  WheelSeg('WORD', Color(0xFFFF4081), 'word'),
                  WheelSeg('₹7', Color(0xFFFF7A00), 'rupee'),
                  WheelSeg('RESTS', Color(0xFFC0B7A6), 'rest'),
                  WheelSeg('₹15', Color(0xFF00C853), 'rupee'),
                  WheelSeg('IMAGE', Color(0xFF7C4DFF), 'image'),
                  WheelSeg('₹21', Color(0xFFD50000), 'rupee'),
                  WheelSeg('LETTER', Color(0xFFE91E63), 'letter'),
                  WheelSeg('RESTS', Color(0xFFB0A692), 'rest'),
                  WheelSeg('VOICE', Color(0xFFAD1457), 'voice'),
                  WheelSeg('CHOICE', Color(0xFFE7B14C), 'choice'),
                  WheelSeg('MOMENT', Color(0xFFFF6E40), 'moment'),
                ],
                angle: _t.value * 6.283185307,
                shine: _t.value,
              ),
            ),
          ),
        ),
        const Center(
          child: Text('the wheel as members see it, turning at rest',
              style: TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic)),
        ),
        _head('TODAY',
            '${_d['today_spins'] ?? 0} turnings · ₹${_d['today_rupees'] ?? 0} given'),
        _odds(),
        _hours(),
        _wishes(),
        _words(),
        _media('VOICES', 'voice', true),
        _media('IMAGES', 'image', false),
        _petals(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _note(String s) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: IvoryTheme.card(radius: 12),
        child: Text(s, style: const TextStyle(fontSize: 12.5)),
      );

  Widget _head(String t, String sub) => Container(
        margin: const EdgeInsets.only(top: 14, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(t,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: IvoryColors.plum)),
            if (sub.isNotEmpty)
              Text(sub,
                  style: const TextStyle(fontSize: 12.5, height: 1.4)),
          ],
        ),
      );

  // ---------- odds dials ----------
  Widget _odds() {
    final List<dynamic> ws = List<dynamic>.from(_list('weights'));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _head('ODDS DIALS',
            'weights, not promises - higher rides oftener; members see rupees only'),
        ...ws.map((dynamic w) => Row(
              children: <Widget>[
                Expanded(
                  child: Text('${w['label']}',
                      style: const TextStyle(fontSize: 12.5)),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: _busy ? null : () => _bump(w, -10),
                  icon: const Icon(Icons.remove, size: 18),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(8, 3, 8, 3),
                  decoration: BoxDecoration(
                    color: const Color(0x147A1626),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${w['weight']}',
                      style: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w800)),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: _busy ? null : () => _bump(w, 10),
                  icon: const Icon(Icons.add, size: 18),
                ),
                Switch(
                  value: w['enabled'] == true,
                  onChanged: _busy
                      ? null
                      : (bool v) {
                          w['enabled'] = v;
                          _saveWeights(ws);
                        },
                ),
              ],
            )),
        TextButton(
          onPressed: _busy ? null : () => _saveWeights(ws),
          child: const Text('SAVE THE DIALS'),
        ),
      ],
    );
  }

  void _bump(dynamic w, int d) {
    final int v = ((w['weight'] as int?) ?? 0) + d;
    w['weight'] = v < 0 ? 0 : v;
    setState(() {});
  }

  Future<void> _saveWeights(List<dynamic> ws) => _after(
      WheelService.instance.weightsSet(ws
          .map((dynamic w) => <String, dynamic>{
                'id': w['id'],
                'weight': w['weight'],
                'enabled': w['enabled'],
              })
          .toList()),
      'The dials are set.');

  // ---------- the hours ----------
  Widget _hours() {
    final List<dynamic> ws = List<dynamic>.from(_list('windows'));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _head('THE HOURS', 'IST, server-locked; never a bell\'s minute'),
        ...ws.map((dynamic w) => Row(
              children: <Widget>[
                Expanded(
                  child: Text('${w['name']}\n${w['open']} - ${w['close']}'
                      '${(w['boost'] as num? ?? 1) > 1 ? ' · doubled rupees' : ''}',
                      style: const TextStyle(fontSize: 12.5, height: 1.4)),
                ),
                TextButton(
                  onPressed: _busy ? null : () => _pickTime(w, true),
                  child: const Text('OPEN'),
                ),
                TextButton(
                  onPressed: _busy ? null : () => _pickTime(w, false),
                  child: const Text('CLOSE'),
                ),
                Switch(
                  value: w['active'] == true,
                  onChanged: _busy
                      ? null
                      : (bool v) {
                          w['active'] = v;
                          _saveWindows(ws);
                        },
                ),
              ],
            )),
        TextButton(
          onPressed: _busy ? null : () => _saveWindows(ws),
          child: const Text('SAVE THE HOURS'),
        ),
      ],
    );
  }

  Future<void> _pickTime(dynamic w, bool open) async {
    final List<String> cur = '${open ? w['open'] : w['close']}'.split(':');
    final TimeOfDay? t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
          hour: int.tryParse(cur[0]) ?? 9, minute: int.tryParse(cur[1]) ?? 7),
    );
    if (t == null) return;
    setState(() {
      if (open) {
        w['open'] =
            '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
      } else {
        w['close'] =
            '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
      }
    });
  }

  Future<void> _saveWindows(List<dynamic> ws) => _after(
      WheelService.instance.windowSet(ws
          .map((dynamic w) => <String, dynamic>{
                'id': w['id'],
                'open': w['open'],
                'close': w['close'],
                'boost': w['boost'],
                'active': w['active'],
              })
          .toList()),
      'The hours are set.');

  // ---------- the wish queue ----------
  Widget _wishes() {
    final List<dynamic> ws = _list('open_wishes');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _head('THE WISH QUEUE', 'letters, moments and ticker names owed'),
        if (ws.isEmpty) const Text('Nothing owed. The house is square.'),
        ...ws.map((dynamic w) {
          final int age = (w['age'] as int?) ?? 0;
          final Color c = age >= 6
              ? const Color(0xFFD50000)
              : age >= 4
                  ? const Color(0xFFFF7A00)
                  : IvoryColors.plum;
          return ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text('${w['kind']} · due ${w['by']}',
                style:
                    TextStyle(fontSize: 13, color: c, fontWeight: FontWeight.w700)),
            subtitle: Text('member ${'${w['uid']}'.substring(0, 8)} · day $age',
                style: const TextStyle(fontSize: 12)),
            trailing: TextButton(
              onPressed: _busy
                  ? null
                  : () => _after(WheelService.instance
                      .wishDeliver((w['id'] as num).toInt()),
                      'Delivered. The queue shortens.'),
              child: const Text('DELIVERED'),
            ),
          );
        }),
      ],
    );
  }

  // ---------- the word bank ----------
  Widget _words() {
    final List<dynamic> ws = _list('words');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _head('THE WORD BANK', 'reword, cull or grow; the wheel delivers'),
        ...ws.map((dynamic w) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text('${w['word']} · ${w['line']}',
                  style: const TextStyle(fontSize: 12.5)),
              subtitle: Text('given ${w['uses']} time(s)',
                  style: const TextStyle(fontSize: 11)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Switch(
                    value: w['enabled'] == true,
                    onChanged: (bool v) {
                      w['enabled'] = v;
                      _after(
                          WheelService.instance.bankSet(<Map<String, dynamic>>[
                            <String, dynamic>{
                              'id': w['id'],
                              'kind': 'word',
                              'enabled': v
                            }
                          ]),
                          'The bank is set.');
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: () => _wordDialog(w: w),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: () => _after(WheelService.instance
                        .bankDrop((w['id'] as num).toInt(), 'word'), 'Culled.'),
                  ),
                ],
              ),
            )),
        TextButton(
          onPressed: () => _wordDialog(),
          child: const Text('ADD A WORD'),
        ),
      ],
    );
  }

  Future<void> _wordDialog({dynamic w}) async {
    final TextEditingController a =
        TextEditingController(text: w == null ? '' : '${w['word']}');
    final TextEditingController b =
        TextEditingController(text: w == null ? '' : '${w['line']}');
    await showDialog<void>(
      context: context,
      builder: (BuildContext c) => AlertDialog(
        title: Text(w == null ? 'A NEW WORD' : 'REWORD'),
        content: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          TextField(controller: a, decoration: const InputDecoration(labelText: 'word')),
          TextField(controller: b, decoration: const InputDecoration(labelText: 'its line')),
        ]),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              Navigator.pop(c);
              if (w == null) {
                _after(WheelService.instance
                    .bankAdd('word', a.text.trim(), b.text.trim()), 'The bank grows.');
              } else {
                _after(
                    WheelService.instance.bankSet(<Map<String, dynamic>>[
                      <String, dynamic>{
                        'id': w['id'],
                        'kind': 'word',
                        'word': a.text.trim(),
                        'line': b.text.trim()
                      }
                    ]),
                    'Reworded.');
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  // ---------- voices and images ----------
  Widget _media(String title, String kind, bool audio) {
    final List<dynamic> ws = _list(audio ? 'voices' : 'images');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _head(title, 'uploaded once, delivered by the wheel at its own time'),
        ...ws.map((dynamic w) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text('${w['title']}',
                  style: const TextStyle(fontSize: 12.5)),
              subtitle: Text('given ${w['uses']} time(s)',
                  style: const TextStyle(fontSize: 11)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Switch(
                    value: w['enabled'] == true,
                    onChanged: (bool v) {
                      w['enabled'] = v;
                      _after(
                          WheelService.instance.bankSet(<Map<String, dynamic>>[
                            <String, dynamic>{
                              'id': w['id'],
                              'kind': kind,
                              'enabled': v
                            }
                          ]),
                          'The bank is set.');
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: () => _after(WheelService.instance
                        .bankDrop((w['id'] as num).toInt(), kind), 'Culled.'),
                  ),
                ],
              ),
            )),
        TextButton(
          onPressed: _busy ? null : () => _upload(kind, audio),
          child: Text(audio ? 'UPLOAD A VOICE' : 'UPLOAD AN IMAGE',
              style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
        const Text('pick as many as you like - the desk carries them one by one',
            style: TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic)),
      ],
    );
  }

  Future<void> _upload(String kind, bool audio) async {
    setState(() {
      _busy = true;
      _msg = 'Picking your files…';
    });
    try {
      final List<XFile> xs = await openFiles(
        acceptedTypeGroups: <XTypeGroup>[
          audio
              ? const XTypeGroup(
                  label: 'Audio',
                  extensions: <String>['mp3', 'm4a', 'aac', 'wav', 'ogg', 'opus', 'flac'],
                  mimeTypes: <String>['audio/*'])
              : const XTypeGroup(
                  label: 'Images',
                  extensions: <String>['jpg', 'jpeg', 'png', 'webp', 'gif', 'heic'],
                  mimeTypes: <String>['image/*']),
        ],
      );
      if (xs.isEmpty) {
        setState(() {
          _busy = false;
          _msg = '';
        });
        return;
      }
      int done = 0;
      int failed = 0;
      for (final XFile x in xs) {
        final Uint8List bytes = await x.readAsBytes();
        if (bytes.isEmpty) {
          failed++;
          continue;
        }
        setState(() => _msg =
            'Carrying ${done + 1} of ${xs.length}: ${x.name} - keep open.');
        final String url = await B2MediaService.instance.uploadBytes(
          bytes: bytes,
          name: x.name,
          kind: audio ? 'audio' : 'image',
        );
        final bool ok = await WheelService.instance.bankAdd(
            kind,
            audio ? 'A voice from Ivory' : 'An image from Ivory',
            url);
        if (ok) {
          done++;
        } else {
          failed++;
        }
      }
      await _load();
      if (mounted) {
        setState(() {
          _busy = false;
          _msg = failed == 0
              ? '$done banked. The wheel will deliver them in their own time.'
              : '$done banked, $failed refused - try smaller files.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _msg = 'The upload failed - try smaller files.';
        });
      }
    }
  }

  // ---------- petals owed ----------
  Widget _petals() {
    final List<dynamic> ps = _list('petals_owed');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _head('PETALS OWED',
            'unspent fortunes bloomed; place them from the REWARDS spoke'),
        if (ps.isEmpty) const Text('No petals owed.'),
        ...ps.map((dynamic p) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text('member ${'${p['uid']}'.substring(0, 8)}',
                  style: const TextStyle(fontSize: 12.5)),
              trailing: Text('${p['petals']} petal(s)',
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w700)),
            )),
      ],
    );
  }
}

// END OF FILE - lib/screens/admin_wheel_tab.dart
