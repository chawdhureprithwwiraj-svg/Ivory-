import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/ivory_errors.dart';
import '../theme/ivory_theme.dart';

/// ============================================================
/// ADMIN - TRANSLATING MY OWN WORDS
///
/// Sits at the top of the Translate tab. Shows how the automatic translator
/// is doing, lets the house switch it on or off, set the daily limit, choose
/// whether the full text of PAID posts may be sent out for translation, retry
/// anything that failed, and translate what was posted before it existed.
/// ============================================================
class AdminTranslatorBox extends StatefulWidget {
  const AdminTranslatorBox({super.key});

  @override
  State<AdminTranslatorBox> createState() => _AdminTranslatorBoxState();
}

class _AdminTranslatorBoxState extends State<AdminTranslatorBox> {
  SupabaseClient get _db => Supabase.instance.client;

  Map<String, dynamic>? _s;
  String? _error;
  bool _busy = false;
  final TextEditingController _cap = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _cap.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final dynamic r = await _db.rpc<dynamic>('translate_admin_state');
      if (!mounted) return;
      setState(() {
        _s = Map<String, dynamic>.from(r as Map);
        _error = null;
        _cap.text = '${_n('cap')}';
      });
    } catch (e) {
      if (mounted) setState(() => _error = adminDetail(e));
    }
  }

  int _n(String k) => (_s?[k] as num?)?.toInt() ?? 0;

  void _say(String m) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
    }
  }

  Future<void> _save({bool? enabled, bool? paidBodies}) async {
    setState(() => _busy = true);
    try {
      await _db.rpc<dynamic>('translate_admin_set', params: <String, dynamic>{
        'enabled_in': enabled ?? (_s?['enabled'] == true),
        'cap_in': int.tryParse(_cap.text.trim()) ?? _n('cap'),
        'paid_bodies_in': paidBodies ?? (_s?['paid_bodies'] == true),
      });
      await _load();
      _say('Saved.');
    } catch (e) {
      _say(adminDetail(e));
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _retry() async {
    setState(() => _busy = true);
    try {
      final dynamic n = await _db.rpc<dynamic>('translate_admin_retry');
      await _load();
      _say('$n item(s) put back in the queue.');
    } catch (e) {
      _say(adminDetail(e));
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _backfill() async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext c) => AlertDialog(
        title: const Text('Translate everything now?'),
        content: const Text(
            'Every published post, poll option and recent broadcast notice, '
            'plus all the words on the app screens, join the queue for each '
            'language that is switched on. Use this after switching a new '
            'language ON. It is done a little at a time within your daily '
            'limit, so it can take a day or two on the free plan.'),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('NOT NOW')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('YES, QUEUE THEM')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      final dynamic n = await _db.rpc<dynamic>('translate_admin_backfill');
      await _load();
      _say('$n job(s) added to the queue.');
    } catch (e) {
      _say(adminDetail(e));
    }
    if (mounted) setState(() => _busy = false);
  }

  String _ago(dynamic iso) {
    final DateTime? t = DateTime.tryParse('${iso ?? ''}')?.toLocal();
    if (t == null) return 'not yet';
    final Duration d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes} min ago';
    if (d.inHours < 48) return '${d.inHours} h ago';
    return '${d.inDays} days ago';
  }

  @override
  Widget build(BuildContext context) {
    const TextStyle small = TextStyle(color: IvoryColors.burgundy, height: 1.45);
    final Map<String, dynamic>? s = _s;
    Widget inner;
    if (_error != null) {
      inner = Text('The translator is not ready yet.\n$_error', style: small);
    } else if (s == null) {
      inner = const Center(
          child: Padding(
        padding: EdgeInsets.all(12),
        child: CircularProgressIndicator(color: IvoryColors.amber),
      ));
    } else {
      final String? err = s['last_error'] as String?;
      inner = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeColor: IvoryColors.plum,
            title: const Text('Translate what I write'),
            subtitle: const Text(
                'Posts, poll options and broadcast notices are translated '
                'automatically for every language switched on below.'),
            value: s['enabled'] == true,
            onChanged: _busy ? null : (bool v) => _save(enabled: v),
          ),
          const SizedBox(height: 4),
          Text(
            'Today: ${_n('today')} of ${_n('cap')} translator calls used\n'
            'Waiting: ${_n('waiting')}   Failed: ${_n('failed')}   '
            'Lines translated: ${_n('lines')}\n'
            'Model: ${s['model']}   Last success: ${_ago(s['last_ok'])}',
            style: small,
          ),
          if (err != null && err.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Text('Last problem: $err',
                style: const TextStyle(
                    color: IvoryColors.burgundy,
                    fontWeight: FontWeight.w700,
                    height: 1.4)),
          ],
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _cap,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Daily limit (translator calls)',
                    helperText: 'The free plan allows only a few hundred a day.',
                    helperMaxLines: 2,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: _busy ? null : () => _save(),
                child: const Text('SAVE'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeColor: IvoryColors.plum,
            title: const Text('Send the full text of paid posts too'),
            subtitle: const Text(
                'Off (recommended on the free plan): only the title and '
                'summary of a paid post are sent to Google; the full text '
                'stays in your own language. The free plan lets Google learn '
                'from what it receives.'),
            value: s['paid_bodies'] == true,
            onChanged: _busy ? null : (bool v) => _save(paidBodies: v),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: <Widget>[
              OutlinedButton(
                onPressed: _busy ? null : _backfill,
                child: const Text('TRANSLATE EVERYTHING NOW'),
              ),
              OutlinedButton(
                onPressed: _busy || _n('failed') == 0 ? null : _retry,
                child: Text('RETRY FAILED (${_n('failed')})'),
              ),
              OutlinedButton(
                onPressed: _busy ? null : _load,
                child: const Text('REFRESH'),
              ),
            ],
          ),
        ],
      );
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: IvoryTheme.card(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'TRANSLATING MY OWN WORDS',
            style: TextStyle(
              color: IvoryColors.plum,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.4,
            ),
          ),
          const SizedBox(height: 8),
          inner,
        ],
      ),
    );
  }
}

// END OF FILE - lib/screens/admin_translator_box.dart
