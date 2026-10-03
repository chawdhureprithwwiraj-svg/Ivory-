import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/ivory_theme.dart';

/// ============================================================
/// IVORY - THE OFFICER DESK
///
/// The admin REPORTS tab. The only surface in the house where
/// clocks exist: first-acknowledgement countdowns, the 15-day
/// outer clock and the 90-day erasure queue. Members never see
/// any of this; every write here is officer-only in Postgres.
/// ============================================================

class AdminReportsTab extends StatefulWidget {
  const AdminReportsTab({super.key});

  @override
  State<AdminReportsTab> createState() => _AdminReportsTabState();
}

class _AdminReportsTabState extends State<AdminReportsTab> {
  static const Map<String, String> _labels = <String, String>{
    'payment': 'payment / refund',
    'missing': 'purchase missing',
    'content': 'something written',
    'explicit': 'off-limits / impersonation',
    'privacy': 'privacy',
    'data': 'account / data',
    'other': 'other',
  };

  List<Map<String, dynamic>> _reports = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _erasures = <Map<String, dynamic>>[];
  Map<String, Map<String, dynamic>> _members =
      <String, Map<String, dynamic>>{};
  bool _loaded = false;
  String? _error;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final SupabaseClient client = Supabase.instance.client;
      final dynamic reps = await client
          .from('reports')
          .select()
          .order('created_at', ascending: false)
          .limit(100);
      final dynamic eras = await client
          .from('erasure_requests')
          .select()
          .order('requested_at', ascending: false)
          .limit(50);
      final List<String> ids = <String>[
        ...<String>{
          for (final dynamic r in (reps as List)) r['user_id'] as String,
          for (final dynamic e in (eras as List)) e['user_id'] as String,
        },
      ];
      Map<String, Map<String, dynamic>> members =
          <String, Map<String, dynamic>>{};
      if (ids.isNotEmpty) {
        final dynamic pros = await client
            .from('profiles')
            .select('id,display_name,email')
            .inFilter('id', ids);
        members = <String, Map<String, dynamic>>{
          for (final dynamic p in (pros as List))
            p['id'] as String: Map<String, dynamic>.from(p as Map),
        };
      }
      if (!mounted) return;
      setState(() {
        _reports = <Map<String, dynamic>>[
          for (final dynamic r in reps) Map<String, dynamic>.from(r as Map),
        ];
        _erasures = <Map<String, dynamic>>[
          for (final dynamic e in eras) Map<String, dynamic>.from(e as Map),
        ];
        _members = members;
        _loaded = true;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _loaded = true;
      });
    }
  }

  Future<void> _setStatus(Map<String, dynamic> r, String status) async {
    final Map<String, dynamic> patch = <String, dynamic>{'status': status};
    if (status == 'ack') {
      patch['ack_at'] = DateTime.now().toIso8601String();
    }
    if (status == 'closed') {
      patch['closed_at'] = DateTime.now().toIso8601String();
    }
    await Supabase.instance.client
        .from('reports')
        .update(patch)
        .eq('id', r['id']);
    await _load();
  }

  Future<void> _markErasureDone(Map<String, dynamic> e) async {
    await Supabase.instance.client.from('erasure_requests').update(
        <String, dynamic>{
          'status': 'done',
          'done_at': DateTime.now().toIso8601String(),
        }).eq('id', e['id']);
    await _load();
  }

  String _clock(String iso) {
    final DateTime due = DateTime.parse(iso).toLocal();
    final Duration d = due.difference(DateTime.now());
    final int h = d.inHours;
    if (d.isNegative) {
      return 'OVERDUE ${-h}h';
    }
    if (h < 48) return '${h}h left';
    return '${d.inDays}d left';
  }

  Color _clockColor(String iso) {
    final DateTime due = DateTime.parse(iso).toLocal();
    final Duration d = due.difference(DateTime.now());
    if (d.isNegative) return IvoryColors.danger;
    if (d.inHours < 12) return IvoryColors.danger;
    if (d.inHours < 24) return IvoryColors.amber;
    return IvoryColors.success;
  }

  String _who(String id) {
    final Map<String, dynamic>? m = _members[id];
    if (m == null) return id.length > 8 ? id.substring(0, 8) : id;
    return (m['display_name'] as String?) ??
        (m['email'] as String?) ??
        'A member';
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Center(child: CircularProgressIndicator());
    }
    final List<Map<String, dynamic>> shown = _filter == 'all'
        ? _reports
        : _reports
            .where((Map<String, dynamic> r) => r['status'] == _filter)
            .toList();
    final int open =
        _reports.where((Map<String, dynamic> r) => r['status'] == 'open').length;
    final int erOpen = _erasures
        .where((Map<String, dynamic> e) => e['status'] == 'open').length;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
        children: <Widget>[
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(_error!,
                  style: TextStyle(color: IvoryColors.danger, fontSize: 12)),
            ),
          Row(
            children: <Widget>[
              Text('$open open · $erOpen erasures',
                  style: TextStyle(
                      color: IvoryColors.burgundy,
                      fontWeight: FontWeight.w800,
                      fontSize: 14)),
              const Spacer(),
              for (final String f in <String>['all', 'open', 'ack', 'closed'])
                Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: ChoiceChip(
                    label: Text(f.toUpperCase(),
                        style: const TextStyle(fontSize: 10.5)),
                    selected: _filter == f,
                    onSelected: (bool v) =>
                        setState(() => _filter = v ? f : 'all'),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (shown.isEmpty)
            const Center(child: Text('Nothing here.'))
          else
            ...shown.map((Map<String, dynamic> r) => _card(r)),
          const SizedBox(height: 22),
          Text('ERASURE QUEUE',
              style: TextStyle(
                  color: IvoryColors.burgundy,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 1.1)),
          const SizedBox(height: 8),
          if (_erasures.isEmpty)
            const Text('No erasure requests.')
          else
            ..._erasures.map((Map<String, dynamic> e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: IvoryTheme.card(),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(_who(e['user_id'] as String),
                                  style: TextStyle(
                                      color: IvoryColors.burgundy,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.5)),
                              const SizedBox(height: 3),
                              Text(
                                '90-day clock: ${_clock(e['due_at'] as String)}'
                                '${e['status'] == 'done' ? ' · done' : ''}',
                                style: TextStyle(
                                    color: e['status'] == 'done'
                                        ? IvoryColors.textFaint
                                        : _clockColor(e['due_at'] as String),
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        if (e['status'] == 'open')
                          TextButton(
                            onPressed: () => _markErasureDone(e),
                            child: const Text('MARK DONE'),
                          ),
                      ],
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  Widget _card(Map<String, dynamic> r) {
    final String status = r['status'] as String;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: IvoryTheme.card(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    _labels[r['category']] ?? r['category'] as String,
                    style: TextStyle(
                        color: IvoryColors.burgundy,
                        fontWeight: FontWeight.w800,
                        fontSize: 13),
                  ),
                ),
                Text(status.toUpperCase(),
                    style: TextStyle(
                        color: status == 'open'
                            ? IvoryColors.danger
                            : status == 'ack'
                                ? IvoryColors.amber
                                : IvoryColors.success,
                        fontWeight: FontWeight.w800,
                        fontSize: 11)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${_who(r['user_id'] as String)} · '
              '${(DateTime.parse(r['created_at'] as String).toLocal())
                  .toString()
                  .substring(0, 16)}',
              style:
                  TextStyle(color: IvoryColors.textFaint, fontSize: 11.5),
            ),
            const SizedBox(height: 6),
            Text(r['detail'] as String,
                style: TextStyle(
                    color: IvoryColors.textSoft,
                    fontSize: 13,
                    height: 1.45)),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Text('ack ${_clock(r['due_at'] as String)}',
                    style: TextStyle(
                        color: status == 'closed'
                            ? IvoryColors.textFaint
                            : _clockColor(r['due_at'] as String),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700)),
                const SizedBox(width: 10),
                Text('outer ${_clock(r['outer_due_at'] as String)}',
                    style: TextStyle(
                        color: IvoryColors.textFaint, fontSize: 11.5)),
                const Spacer(),
                if (status == 'open')
                  TextButton(
                    onPressed: () => _setStatus(r, 'ack'),
                    child: const Text('ACKNOWLEDGE'),
                  ),
                if (status != 'closed')
                  TextButton(
                    onPressed: () => _setStatus(r, 'closed'),
                    child: const Text('CLOSE'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// END OF FILE - lib/screens/admin_reports_tab.dart
