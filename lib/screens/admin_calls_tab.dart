import 'package:flutter/material.dart';

import '../models/live_models.dart';
import '../services/live_service.dart';
import '../theme/ivory_theme.dart';
import '../widgets/admin_bits.dart';
import 'live_screen.dart';

/// ============================================================
/// ADMIN STUDIO - CALLS
///
/// Your consent gate. A member can ask for a session; nobody can
/// put one in your evening without you tapping ACCEPT.
///
///   ACCEPT   creates the private room, sets the agreed time and
///            tells them it is confirmed
///   DECLINE  no room is ever created, no minutes are touched
///
/// The sweep runs each time this tab opens: any session whose
/// window closed with nobody inside is marked missed - forgiven
/// twice per cycle, charged from the third.
/// ============================================================
class AdminCallsTab extends StatefulWidget {
  const AdminCallsTab({super.key});

  @override
  State<AdminCallsTab> createState() => _AdminCallsTabState();
}

class _AdminCallsTabState extends State<AdminCallsTab> {
  List<AdminCall> _calls = <AdminCall>[];
  bool _loading = true;
  String? _note;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final int swept = await LiveService.instance.sweepMissed();
      final List<AdminCall> rows = await LiveService.instance.listCalls();
      if (!mounted) return;
      setState(() {
        _calls = rows;
        _loading = false;
        _note = swept > 0
            ? '$swept session${swept == 1 ? '' : 's'} closed as missed.'
            : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _note = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _accept(AdminCall c) async {
    final DateTime? when = await _pickTime(c);
    if (when == null) return;
    try {
      await LiveService.instance.respondToCall(c.id, accept: true);
      await LiveService.instance.setCallTime(c.id, when);
      _say('Accepted. ${c.displayName} has been told.');
    } catch (e) {
      _say(e.toString().replaceFirst('Exception: ', ''));
    }
    _load();
  }

  Future<void> _decline(AdminCall c) async {
    final bool ok = await _confirm(
      'Decline this session?',
      'They will be asked to choose another time. Nothing is charged '
          'and no minutes are used.',
    );
    if (!ok) return;
    try {
      await LiveService.instance.respondToCall(c.id, accept: false);
      _say('Declined, and they have been told kindly.');
    } catch (e) {
      _say(e.toString().replaceFirst('Exception: ', ''));
    }
    _load();
  }

  Future<DateTime?> _pickTime(AdminCall c) async {
    final DateTime now = DateTime.now();
    final DateTime? day = await showDatePicker(
      context: context,
      initialDate: c.requestedFor ?? now.add(const Duration(days: 1)),
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 120)),
      helpText: 'Which day?',
    );
    if (day == null || !mounted) return null;

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        c.requestedFor ?? now.add(const Duration(hours: 2)),
      ),
      helpText: 'What time? (your clock)',
    );
    if (time == null) return null;

    return DateTime(day.year, day.month, day.day, time.hour, time.minute);
  }

  Future<bool> _confirm(String title, String body) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext c) => AlertDialog(
        backgroundColor: IvoryColors.surface,
        title: Text(title,
            style: const TextStyle(color: IvoryColors.burgundy)),
        content: Text(body, style: TextStyle(color: IvoryColors.textSoft)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('KEEP IT'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('DECLINE'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  void _say(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _join(AdminCall c) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => LiveScreen(
          sessionId: c.id,
          title: c.displayName,
          subtitle: '${c.minutes} minutes - ${c.kind}',
          mode: LiveMode.call,
          videoEnabled: c.kind == 'video',
        ),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: IvoryColors.amber),
      );
    }

    final List<AdminCall> waiting =
        _calls.where((AdminCall c) => c.status == 'requested').toList();
    final List<AdminCall> confirmed = _calls
        .where((AdminCall c) =>
            c.status == 'accepted' || c.status == 'active')
        .toList();
    final List<AdminCall> past = _calls
        .where((AdminCall c) =>
            c.status == 'completed' ||
            c.status == 'missed' ||
            c.status == 'declined')
        .toList();

    return RefreshIndicator(
      color: IvoryColors.amber,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: <Widget>[
          if (_note != null) ...<Widget>[
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: IvoryColors.surfaceWarm,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: IvoryColors.gold, width: 1),
              ),
              child: Text(
                _note!,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: IvoryColors.textSoft,
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          if (_calls.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: <Widget>[
                  Icon(Icons.call_outlined,
                      size: 44, color: IvoryColors.textFaint),
                  const SizedBox(height: 14),
                  Text(
                    'No sessions yet',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'When a member asks for a call it lands here first. '
                    'Nothing is confirmed until you accept it.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.5,
                      color: IvoryColors.textSoft,
                    ),
                  ),
                ],
              ),
            ),
          if (waiting.isNotEmpty) ...<Widget>[
            const AdminLabel('Waiting for you'),
            ...waiting.map(_card),
            const SizedBox(height: 10),
          ],
          if (confirmed.isNotEmpty) ...<Widget>[
            const AdminLabel('Confirmed'),
            ...confirmed.map(_card),
            const SizedBox(height: 10),
          ],
          if (past.isNotEmpty) ...<Widget>[
            const AdminLabel('Finished'),
            ...past.map(_card),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  Widget _card(AdminCall c) {
    final bool pending = c.status == 'requested';
    final bool joinable = c.status == 'accepted' || c.status == 'active';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: IvoryTheme.card(highlighted: pending),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: IvoryColors.goldGradient,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  c.kind == 'video'
                      ? Icons.videocam_rounded
                      : Icons.call_rounded,
                  color: IvoryColors.burgundy,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      c.displayName,
                      style: const TextStyle(
                        color: IvoryColors.burgundy,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (c.memberEmail != null)
                      Text(
                        c.memberEmail!,
                        style: TextStyle(
                          fontSize: 12,
                          color: IvoryColors.textFaint,
                        ),
                      ),
                  ],
                ),
              ),
              _statusPill(c),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${c.kind == 'video' ? 'Video' : 'Audio'} - ${c.minutes} minutes'
            '${c.priceInr > 0 ? ' - Rs.${c.priceInr} wish' : ' - included'}',
            style: TextStyle(fontSize: 13, color: IvoryColors.textSoft),
          ),
          if (c.note != null && c.note!.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              c.note!,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                fontStyle: FontStyle.italic,
                color: IvoryColors.textSoft,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            c.requestedFor != null
                ? 'Agreed for ${_when(c.requestedFor!)}'
                : 'No time agreed yet',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: c.requestedFor != null
                  ? IvoryColors.plum
                  : IvoryColors.textFaint,
            ),
          ),
          if (c.status == 'missed')
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                c.charged
                    ? 'Missed - minutes were used (third this cycle).'
                    : 'Missed - forgiven, no minutes used.',
                style: TextStyle(fontSize: 12, color: IvoryColors.textFaint),
              ),
            ),
          if (pending) ...<Widget>[
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _decline(c),
                    child: const Text('DECLINE'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: IvoryGradientButton(
                    label: 'ACCEPT',
                    icon: Icons.check_rounded,
                    onPressed: () => _accept(c),
                  ),
                ),
              ],
            ),
          ],
          if (joinable) ...<Widget>[
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final DateTime? when = await _pickTime(c);
                      if (when == null) return;
                      await LiveService.instance.setCallTime(c.id, when);
                      _say('Time updated. They have been told.');
                      _load();
                    },
                    child: const Text('CHANGE TIME'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: IvoryGradientButton(
                    label: 'JOIN',
                    icon: Icons.videocam_rounded,
                    onPressed: () => _join(c),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusPill(AdminCall c) {
    late final String text;
    late final Color bg;
    switch (c.status) {
      case 'requested':
        text = 'ASKED';
        bg = IvoryColors.amber;
        break;
      case 'accepted':
        text = 'CONFIRMED';
        bg = IvoryColors.gold;
        break;
      case 'active':
        text = 'IN THE ROOM';
        bg = IvoryColors.gold;
        break;
      case 'completed':
        text = 'DONE';
        bg = IvoryColors.success;
        break;
      case 'missed':
        text = 'MISSED';
        bg = IvoryColors.danger;
        break;
      default:
        text = 'DECLINED';
        bg = IvoryColors.plum;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: bg == IvoryColors.amber || bg == IvoryColors.gold
              ? IvoryColors.burgundy
              : IvoryColors.cream,
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }

  String _when(DateTime d) {
    const List<String> m = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final DateTime l = d.toLocal();
    final int h12 = l.hour % 12 == 0 ? 12 : l.hour % 12;
    final String mm = l.minute.toString().padLeft(2, '0');
    final String ap = l.hour < 12 ? 'am' : 'pm';
    return '${l.day} ${m[l.month - 1]}, $h12:$mm $ap';
  }
}

// END OF FILE - lib/screens/admin_calls_tab.dart
