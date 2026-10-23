import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/ivory_errors.dart';
import '../services/ticker_service.dart';
import '../theme/ivory_theme.dart';
import '../widgets/ticker_palettes.dart';

/// ============================================================
/// ADMIN STUDIO - THE TICKER'S OWN ANNOUNCEMENTS
///
/// Lines the house writes itself. Each can have a colour, a Grand
/// look, a place a tap opens, and a time to stop. They join the real
/// moments in the ribbons, and come round again if nothing newer is
/// waiting.
/// ============================================================
class AdminTickerNotes extends StatefulWidget {
  const AdminTickerNotes({super.key});

  @override
  State<AdminTickerNotes> createState() => _AdminTickerNotesState();
}

class _AdminTickerNotesState extends State<AdminTickerNotes> {
  SupabaseClient get _db => Supabase.instance.client;

  List<Map<String, dynamic>> _notes = <Map<String, dynamic>>[];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final dynamic n = await _db
          .from('ticker_notes')
          .select()
          .order('id', ascending: false)
          .limit(30);
      if (!mounted) return;
      setState(() {
        _notes = (n as List)
            .map((dynamic e) => Map<String, dynamic>.from(e as Map))
            .toList();
      });
    } catch (e) {
      _say(adminDetail(e));
    }
  }

  void _say(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _addNote() async {
    final TextEditingController text = TextEditingController();
    final TextEditingController hours = TextEditingController(text: '24');
    int colour = 0;
    bool grand = false;
    String link = '';
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (BuildContext ctx, StateSetter setS) => AlertDialog(
          title: const Text('New announcement'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextField(
                  controller: text,
                  maxLines: 3,
                  maxLength: 140,
                  decoration: const InputDecoration(labelText: 'What it says'),
                ),
                // CC.200: breathing room, so no border ever sits on
                // the next field's border.
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: colour,
                  decoration: const InputDecoration(labelText: 'Colour'),
                  items: <DropdownMenuItem<int>>[
                    const DropdownMenuItem<int>(
                      value: 0,
                      child: Text('Any (chosen for me)'),
                    ),
                    for (int i = 0; i < kTickerPalettes.length; i++)
                      DropdownMenuItem<int>(
                        value: i + 1,
                        child: Text(kTickerPalettes[i].name),
                      ),
                  ],
                  onChanged: (int? v) => setS(() => colour = v ?? 0),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: link,
                  decoration: const InputDecoration(labelText: 'A tap opens'),
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem<String>(value: '', child: Text('Nothing')),
                    DropdownMenuItem<String>(value: 'home', child: Text('Home')),
                    DropdownMenuItem<String>(
                      value: 'explore',
                      child: Text('Explore'),
                    ),
                    DropdownMenuItem<String>(value: 'wish', child: Text('The Wish')),
                    DropdownMenuItem<String>(
                      value: 'premium',
                      child: Text('Membership'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'ladder',
                      child: Text('The Ivory Ladder'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'bells',
                      child: Text('The Four Bells'),
                    ),
                  ],
                  onChanged: (String? v) => setS(() => link = v ?? ''),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: hours,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Show for how many hours (0 = until I remove it)',
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Grand look (longer, with a gold burst)'),
                  value: grand,
                  onChanged: (bool v) => setS(() => grand = v),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('ADD'),
            ),
          ],
        ),
      ),
    );
    final String body = text.text.trim();
    final int? h = int.tryParse(hours.text.trim());
    if (ok != true) return;
    if (body.length < 3) {
      _say('Please write what the announcement says.');
      return;
    }
    if (h == null || h < 0 || h > 8760) {
      _say('Please give hours between 0 and 8760.');
      return;
    }
    try {
      await _db.from('ticker_notes').insert(<String, dynamic>{
        'body': body,
        'colour': colour == 0 ? null : colour,
        'grand': grand,
        'link': link.isEmpty ? null : link,
        'ends_at': h == 0
            ? null
            : DateTime.now().add(Duration(hours: h)).toUtc().toIso8601String(),
      });
      _say('Added. Members see it within about five minutes.');
      await _load();
      TickerService.instance.pull();
    } catch (e) {
      _say(adminDetail(e));
    }
  }

  Future<void> _noteOn(Map<String, dynamic> n, bool v) async {
    try {
      await _db
          .from('ticker_notes')
          .update(<String, dynamic>{'is_on': v})
          .eq('id', n['id']);
      await _load();
    } catch (e) {
      _say(adminDetail(e));
    }
  }

  Future<void> _noteDelete(Map<String, dynamic> n) async {
    try {
      await _db.from('ticker_notes').delete().eq('id', n['id']);
      await _load();
    } catch (e) {
      _say(adminDetail(e));
    }
  }

  String _noteLine(Map<String, dynamic> n) {
    final String g = n['grand'] == true ? 'Grand · ' : '';
    final dynamic e = n['ends_at'];
    if (e == null) return '${g}until removed';
    final DateTime? t = DateTime.tryParse('$e')?.toLocal();
    if (t == null) return '${g}until removed';
    final String clock = t.toString().substring(0, 16);
    return '${g}until $clock';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.fromLTRB(2, 22, 2, 10),
          child: Text(
            'YOUR OWN ANNOUNCEMENTS',
            style: TextStyle(
              color: IvoryColors.plum,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.4,
            ),
          ),
        ),
        for (final Map<String, dynamic> n in _notes)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: IvoryTheme.card(),
              child: ListTile(
                title: Text(
                  '${n['body']}',
                  style: const TextStyle(
                    color: IvoryColors.burgundy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  _noteLine(n),
                  style: const TextStyle(color: IvoryColors.plum),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Switch(
                      value: n['is_on'] != false,
                      onChanged: (bool v) => _noteOn(n, v),
                    ),
                    IconButton(
                      color: IvoryColors.burgundy,
                      onPressed: () => _noteDelete(n),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
            ),
          OutlinedButton.icon(
            onPressed: _busy ? null : _addNote,
            icon: const Icon(Icons.campaign_outlined),
            label: const Text('WRITE AN ANNOUNCEMENT'),
          ),
      ],
    );
  }
}

// END OF FILE - lib/screens/admin_ticker_notes.dart
