import 'package:flutter/material.dart';

import '../services/b2_media_service.dart';
import '../services/wheel_service.dart';

/// ============================================================
// IVORY - THE WHEEL BANK VAULT (CC.232)
///
/// The room the wheel never had: everything the banks already hold,
/// in plain sight. Per bank - how many files, how many enabled, the
/// measured weight of them; per file - its name (the original for new
/// uploads, recovered from the B2 key for the old ones), its size, the
/// dawns it was given, the day it was banked, its enabled switch, a
/// rename and a cull. Files banked before the vault say plainly that
/// their size was never measured - the vault never guesses. One line
/// remembers the whole private B2, across all of Ivory's media.
/// ============================================================
class WheelBankVault extends StatefulWidget {
  const WheelBankVault({super.key});

  @override
  State<WheelBankVault> createState() => _WheelBankVaultState();
}

class _WheelBankVaultState extends State<WheelBankVault> {
  Map<String, dynamic> _d = <String, dynamic>{};
  int? _bucket;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final Map<String, dynamic> m = await WheelService.instance.desk();
    final int? used = await B2MediaService.instance.usedBytes();
    if (!mounted) return;
    setState(() {
      _d = m;
      _bucket = used;
      _loading = false;
    });
  }

  List<dynamic> _rows(String k) =>
      (_d[k] is List) ? _d[k] as List<dynamic> : <dynamic>[];

  static const String _genVoice = 'A voice from Ivory';
  static const String _genImage = 'An image from Ivory';

  String _name(Map<String, dynamic> r, String kind) {
    final String title = (r['title'] ?? '').toString();
    if (title.isNotEmpty &&
        title != _genVoice &&
        title != _genImage) return title;
    final String f = (r['fname'] ?? '').toString();
    return f.isNotEmpty ? f : 'untitled';
  }

  String _fmt(num b) {
    if (b < 1024) return '${b.round()} B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(0)} KB';
    if (b < 1024 * 1024 * 1024) {
      return '${(b / 1024 / 1024).toStringAsFixed(1)} MB';
    }
    return '${(b / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }

  String _when(Map<String, dynamic> r) {
    final String a = (r['added_at'] ?? '').toString();
    if (a.isEmpty) return 'banked before the vault';
    try {
      final DateTime t = DateTime.parse(a).toLocal();
      return 'banked ${t.day} ${_mon(t.month)} ${t.year}';
    } catch (_) {
      return 'banked before the vault';
    }
  }

  String _mon(int m) => const <String>[
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m - 1];

  Future<void> _enable(Map<String, dynamic> r, String kind, bool v) async {
    setState(() => _busy = true);
    final bool ok = await WheelService.instance
        .bankSet(<Map<String, dynamic>>[
      <String, dynamic>{'id': r['id'], 'kind': kind, 'enabled': v}
    ]);
    await _load();
    if (mounted) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok
              ? (v ? 'Back in the bank.' : 'Resting.')
              : 'The desk refused.')));
    }
  }

  Future<void> _rename(Map<String, dynamic> r, String kind) async {
    final TextEditingController c =
        TextEditingController(text: _name(r, kind));
    final String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Name it plainly',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'what the bank holds'),
        ),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('KEEP')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(c.text.trim()),
              child: const Text('NAME IT')),
        ],
      ),
    );
    c.dispose();
    if (name == null || name.isEmpty || !mounted) return;
    setState(() => _busy = true);
    final bool ok = await WheelService.instance.bankSet(<Map<String, dynamic>>[
      <String, dynamic>{'id': r['id'], 'kind': kind, 'title': name}
    ]);
    await _load();
    if (mounted) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok ? 'Named.' : 'The desk refused.')));
    }
  }

  Future<void> _cull(Map<String, dynamic> r, String kind) async {
    final bool? yes = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Cull it from the bank?',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        content: Text('“${_name(r, kind)}” leaves the bank. The file itself '
            'stays in the private B2 until you cull it there too.'),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('KEEP')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('CULL')),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    setState(() => _busy = true);
    final bool ok = await WheelService.instance
        .bankDrop((r['id'] as num).toInt(), kind);
    await _load();
    if (mounted) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ok ? 'Culled.' : 'The desk refused.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF17100A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF17100A),
        elevation: 0,
        title: const Text('THE BANK VAULT',
            style: TextStyle(
                color: Color(0xFFE7B14C),
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 2)),
        iconTheme: const IconThemeData(color: Color(0xFFE7B14C)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
                children: <Widget>[
                  _totals(),
                  const SizedBox(height: 16),
                  _bank('THE VOICE BANK', 'voice', _rows('voices'),
                      Icons.graphic_eq_outlined),
                  const SizedBox(height: 16),
                  _bank('THE IMAGE BANK', 'image', _rows('images'),
                      Icons.image_outlined),
                ],
              ),
            ),
    );
  }

  Widget _totals() {
    int measured(String k) => _rows(k).fold<int>(
        0,
        (int a, dynamic r) =>
            a + (((r as Map)['bytes'] is num) ? (r['bytes'] as num).toInt() : 0));
    int unmeasured(String k) => _rows(k)
        .where((dynamic r) => !((r as Map)['bytes'] is num))
        .length;
    final int im = measured('images');
    final int vm = measured('voices');
    final int iu = unmeasured('images');
    final int vu = unmeasured('voices');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0x14E7B14C),
        border: Border.all(color: const Color(0x55E7B14C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('WHAT THE BANKS HOLD',
              style: TextStyle(
                  color: Color(0xFFE7B14C),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.8)),
          const SizedBox(height: 8),
          Text(
              '${_rows('voices').length} voice notes · '
              '${_fmt(vm)} measured'
              '${vu > 0 ? ' · $vu unmeasured (before the vault)' : ''}',
              style: const TextStyle(color: Color(0xE6FFF6E5), fontSize: 12.5)),
          const SizedBox(height: 4),
          Text(
              '${_rows('images').length} images · '
              '${_fmt(im)} measured'
              '${iu > 0 ? ' · $iu unmeasured (before the vault)' : ''}',
              style: const TextStyle(color: Color(0xE6FFF6E5), fontSize: 12.5)),
          if (_bucket != null) ...<Widget>[
            const SizedBox(height: 8),
            Text('the private B2 holds ${_fmt(_bucket!)} across all of '
                'Ivory\u2019s media, wheel and otherwise',
                style: const TextStyle(
                    color: Color(0x99FFE9A8),
                    fontSize: 11,
                    fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }

  Widget _bank(String head, String kind, List<dynamic> rows, IconData ic) {
    final int enabled =
        rows.where((dynamic r) => (r as Map)['enabled'] == true).length;
    final int given = rows.fold<int>(
        0,
        (int a, dynamic r) =>
            a + (((r as Map)['uses'] is num) ? (r['uses'] as num).toInt() : 0));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('$head  ·  ${rows.length} in bank · $enabled enabled · '
            'given $given time${given == 1 ? '' : 's'}',
            style: const TextStyle(
                color: Color(0xFFE7B14C),
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4)),
        const SizedBox(height: 8),
        if (rows.isEmpty)
          const Text('Nothing banked yet. Upload from the wheel spoke.',
              style: TextStyle(color: Color(0x99FFF6E5), fontSize: 12)),
        ...rows.map((dynamic e) {
          final Map<String, dynamic> r = Map<String, dynamic>.from(e as Map);
          final num? b = (r['bytes'] is num) ? r['bytes'] as num : null;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: const Color(0x22FFF6E5),
              border: Border.all(color: const Color(0x33E7B14C)),
            ),
            child: Row(
              children: <Widget>[
                Icon(ic, color: const Color(0x88E7B14C), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(_name(r, kind),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Color(0xFFFFF6E5),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(
                          '${b != null ? _fmt(b) : 'size unmeasured'} · '
                          'given ${r['uses'] ?? 0} · ${_when(r)}',
                          style: const TextStyle(
                              color: Color(0x99FFE9A8), fontSize: 10.5)),
                    ],
                  ),
                ),
                Switch(
                  value: r['enabled'] == true,
                  onChanged: _busy ? null : (bool v) => _enable(r, kind, v),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  onPressed: _busy ? null : () => _rename(r, kind),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 16),
                  onPressed: _busy ? null : () => _cull(r, kind),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// END OF FILE - lib/screens/wheel_bank_vault.dart
