import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/ivory_theme.dart';

/// ADMIN - THE DOOR
///
/// Every story left at the member door, newest first. Two taps to
/// answer one: CHOOSE (it moved me), MARK PRODUCED (it is live and
/// the member is told), or PASS (quietly). The door is free, forever.
class AdminStoriesTab extends StatefulWidget {
  const AdminStoriesTab({super.key});

  @override
  State<AdminStoriesTab> createState() => _AdminStoriesTabState();
}

class _AdminStoriesTabState extends State<AdminStoriesTab> {
  List<Map<String, dynamic>> _rows = <Map<String, dynamic>>[];
  Map<String, String> _names = <String, String>{};
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final List<dynamic> rows = await Supabase.instance.client
          .from('story_submissions')
          .select('id, member_id, body, credit_name, status, created_at')
          .order('created_at', ascending: false)
          .limit(60);
      final List<String> ids = rows
          .map((dynamic r) => (r as Map<String, dynamic>)['member_id']
              .toString())
          .toSet()
          .toList();
      final Map<String, String> names = <String, String>{};
      if (ids.isNotEmpty) {
        final List<dynamic> prof = await Supabase.instance.client
            .from('profiles')
            .select('id, display_name')
            .inFilter('id', ids);
        for (final dynamic p in prof) {
          final Map<String, dynamic> m = p as Map<String, dynamic>;
          names[m['id'].toString()] =
              (m['display_name'] as String?) ?? 'A member';
        }
      }
      if (!mounted) return;
      setState(() {
        _rows = rows.cast<Map<String, dynamic>>();
        _names = names;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _setStatus(int id, String status) async {
    setState(() => _busy = true);
    try {
      await Supabase.instance.client
          .from('story_submissions')
          .update(<String, dynamic>{'status': status})
          .eq('id', id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not update: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 40),
        children: <Widget>[
          Text('The door', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(
            'Stories left by members. Free, forever. Chosen ones are '
            'produced in your voice with their name stamped on them - '
            'and they are told at every step.',
            style: TextStyle(fontSize: 12.5, height: 1.45,
                color: IvoryColors.textFaint),
          ),
          const SizedBox(height: 16),
          if (_error != null)
            Text(_error!,
                style: TextStyle(fontSize: 12.5, color: IvoryColors.danger)),
          if (_rows.isEmpty && _error == null)
            Padding(
              padding: const EdgeInsets.only(top: 30),
              child: Center(
                child: Text(
                  _busy ? 'Opening the door...' : 'No stories at the door yet.',
                  style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: IvoryColors.textFaint),
                ),
              ),
            ),
          ..._rows.map(_card),
        ],
      ),
    );
  }

  Widget _card(Map<String, dynamic> r) {
    final int id = (r['id'] as num).toInt();
    final String status = (r['status'] as String?) ?? 'submitted';
    final String name = (r['credit_name'] as String?) ??
        (_names[r['member_id'].toString()] ?? 'A member');
    final bool anon = (r['credit_name'] as String?) == null;
    final DateTime? at = DateTime.tryParse((r['created_at'] as String?) ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: IvoryColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: IvoryColors.hairline, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Row(
                  children: <Widget>[
                    Transform.scale(
                      scaleX: -1,
                      child: Text(anon ? '🕊️' : '🪶',
                          style: const TextStyle(fontSize: 13.5)),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
              _statusChip(status),
            ],
          ),
          if (at != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '${at.day}/${at.month}/${at.year}',
                style: TextStyle(
                    fontSize: 10.5, color: IvoryColors.textFaint),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            r['body'] as String? ?? '',
            style: const TextStyle(fontSize: 13, height: 1.55),
          ),
          const SizedBox(height: 12),
          if (status == 'submitted') ...<Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: IvoryGradientButton(
                    label: _busy ? '...' : 'IT MOVED ME',
                    icon: Icons.favorite_outline,
                    busy: _busy,
                    onPressed: _busy ? null : () => _setStatus(id, 'chosen'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _busy ? null : () => _setStatus(id, 'passed'),
                    child: const Text('PASS'),
                  ),
                ),
              ],
            ),
          ] else if (status == 'chosen') ...<Widget>[
            IvoryGradientButton(
              label: _busy ? '...' : 'MARK PRODUCED - TELL THEM',
              icon: Icons.record_voice_over_outlined,
              busy: _busy,
              onPressed: _busy ? null : () => _setStatus(id, 'produced'),
            ),
          ] else if (status == 'produced') ...<Widget>[
            Text('Live in the house. They have been told.',
                style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: IvoryColors.success)),
          ] else ...<Widget>[
            Text('Passed, quietly.',
                style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: IvoryColors.textFaint)),
          ],
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    final String label = status == 'submitted'
        ? 'AT THE DOOR'
        : status == 'chosen'
            ? 'CHOSEN'
            : status == 'produced'
                ? 'PRODUCED'
                : 'PASSED';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: status == 'produced'
            ? IvoryColors.gold.withValues(alpha: 0.18)
            : IvoryColors.surfaceWarm,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: IvoryColors.hairlineStrong, width: 0.8),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 9.5,
              letterSpacing: 1,
              fontWeight: FontWeight.w800,
              color: IvoryColors.burgundy)),
    );
  }
}

// END OF FILE - lib/screens/admin_stories_tab.dart
