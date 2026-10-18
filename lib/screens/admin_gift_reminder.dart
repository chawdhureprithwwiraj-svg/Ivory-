import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/ivory_errors.dart';
import '../theme/ivory_theme.dart';

/// ============================================================
/// ADMIN STUDIO - THE GIFT REMINDER (inside the Rewards studio)
///
/// How many days before a Ladder gift code ends the member gets one
/// gentle note ("Your door discount ends soon"). 0 switches the note
/// off. Reads and writes the single settings row; nothing else.
/// ============================================================
class AdminGiftReminder extends StatefulWidget {
  const AdminGiftReminder({super.key});

  @override
  State<AdminGiftReminder> createState() => _AdminGiftReminderState();
}

class _AdminGiftReminderState extends State<AdminGiftReminder> {
  final TextEditingController _days = TextEditingController();
  bool _ready = false;
  bool _busy = false;
  String? _note;

  SupabaseClient get _db => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _days.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final dynamic r = await _db
          .from('ladder_gift_settings')
          .select('nudge_days')
          .eq('id', 1)
          .maybeSingle();
      if (!mounted) return;
      if (r is Map) {
        setState(() {
          _days.text = '${(r['nudge_days'] as num?)?.toInt() ?? 3}';
          _ready = true;
        });
      }
    } catch (_) {
      // The database part has not been run yet: the box stays hidden.
    }
  }

  Future<void> _save() async {
    final int? n = int.tryParse(_days.text.trim());
    if (n == null || n < 0 || n > 14) {
      setState(() => _note = 'Type a number from 0 to 14.');
      return;
    }
    setState(() {
      _busy = true;
      _note = null;
    });
    try {
      await _db
          .from('ladder_gift_settings')
          .update(<String, dynamic>{'nudge_days': n}).eq('id', 1);
      if (!mounted) return;
      setState(() => _note = n == 0
          ? 'Saved. The reminder is switched off.'
          : 'Saved. Members are reminded $n ${n == 1 ? 'day' : 'days'} '
              'before a gift code ends.');
    } catch (e) {
      if (mounted) setState(() => _note = adminDetail(e));
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: IvoryTheme.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'LADDER GIFT REMINDER',
            style: TextStyle(
              color: IvoryColors.plum,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.4,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'When a member has an unused Ladder gift code that is about to '
            'end, they get ONE gentle note. Choose how many days before the '
            'end. Type 0 to switch the note off.',
            style: TextStyle(color: IvoryColors.burgundy, height: 1.45),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              SizedBox(
                width: 90,
                child: TextField(
                  controller: _days,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                  style: const TextStyle(color: IvoryColors.burgundy),
                  decoration: const InputDecoration(labelText: 'Days'),
                ),
              ),
              const SizedBox(width: 14),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: IvoryColors.burgundy,
                ),
                onPressed: _busy ? null : _save,
                child: Text(_busy ? 'SAVING...' : 'SAVE'),
              ),
            ],
          ),
          if (_note != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              _note!,
              style: const TextStyle(color: IvoryColors.plum, fontSize: 12.5),
            ),
          ],
        ],
      ),
    );
  }
}

// END OF FILE - lib/screens/admin_gift_reminder.dart
