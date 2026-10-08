import 'package:flutter/material.dart';

import '../core/ivory_errors.dart';
import '../models/live_models.dart';
import '../services/call_room_service.dart';
import '../services/live_service.dart';
import '../theme/ivory_theme.dart';
import 'call_sheet_bits.dart';

/// ============================================================
/// IVORY - CHOOSING THE SESSION TIME
///
/// The member picks their day and time here, inside Ivory. No
/// outside calendar, no retyping, no second answer to disagree
/// with. member_pick_slot is the only gate: it holds the notice
/// period, the hours sessions run, and how far ahead a time may
/// be chosen - all editable from the house, none of them the
/// authority in this file.
///
/// The same rules are mirrored here only so a member is told
/// kindly before they travel.
/// ============================================================

/// Hours the house keeps. These are only the starting values -
/// _loadHours() replaces them from call_policy before the
/// picker opens, so changing the rule in the database changes
/// what the member is actually offered. They remain as a
/// fallback for the moment the read fails; a member must never
/// be stopped from booking by a slow settings row.
int _noticeHours = 4;
int _opensHour = 12;
int _closesHour = 3;
int _horizonDays = 30;

/// Reads the four numbers from call_policy. Silent on failure -
/// the values above simply stand.
Future<void> _loadHours() async {
  final CallHours? h = await CallRoomService.instance.hours();
  if (h == null) return;
  if (h.noticeHours != null && h.noticeHours! >= 0) {
    _noticeHours = h.noticeHours!;
  }
  if (h.opensHour != null) _opensHour = h.opensHour!;
  if (h.closesHour != null) _closesHour = h.closesHour!;
  if (h.horizonDays != null && h.horizonDays! > 0) {
    _horizonDays = h.horizonDays!;
  }
}

/// Says an hour the way a person would: 12 -> "noon",
/// 3 -> "3 in the morning", 18 -> "6 in the evening". The
/// window is data now, so the sentence cannot be written by
/// hand any more.
String _spoken(int hour) {
  final int h = ((hour % 24) + 24) % 24;
  if (h == 0) return 'midnight';
  if (h == 12) return 'noon';
  if (h < 12) return '$h in the morning';
  if (h < 17) return '${h - 12} in the afternoon';
  if (h < 21) return '${h - 12} in the evening';
  return '${h - 12} at night';
}

bool _insideHours(DateTime when) {
  final int h = when.hour;
  return h >= _opensHour || h < _closesHour;
}

/// The notice period can land in the closed hours - 3:15 am plus
/// four hours is 7:15 am, which the house does not keep. Roll
/// forward to the next moment the door is really open, so a
/// member is never offered a time they cannot have.
DateTime _firstOpening(DateTime from) {
  if (_insideHours(from)) return from;
  return DateTime(from.year, from.month, from.day, _opensHour, 0);
}

/// Opens the picker and writes the chosen time. The signature is
/// unchanged from the cal.com version, so nothing else moves.
Future<void> bookCallSlot(
  BuildContext context,
  CallRequest c, {
  required void Function(String msg) say,
  required Future<void> Function() reload,
}) async {
  await _loadHours();
  final DateTime earliest = _firstOpening(
      DateTime.now().add(Duration(hours: _noticeHours)));
  final DateTime latest =
      DateTime.now().add(Duration(days: _horizonDays));

  final bool go = await showDialog<bool>(
        context: context,
        builder: (BuildContext d) => _HoursDialog(earliest: earliest),
      ) ??
      false;
  if (!go || !context.mounted) return;

  final DateTime? day = await showDatePicker(
    context: context,
    initialDate: earliest,
    firstDate: DateTime(earliest.year, earliest.month, earliest.day),
    lastDate: latest,
    helpText: 'Choose your day',
    builder: (BuildContext ctx, Widget? child) => Theme(
      data: Theme.of(ctx).copyWith(
        colorScheme: Theme.of(ctx).colorScheme.copyWith(
              primary: IvoryColors.burgundy,
              onPrimary: IvoryColors.ivory,
              surface: IvoryColors.surface,
            ),
      ),
      child: child ?? const SizedBox.shrink(),
    ),
  );
  if (day == null || !context.mounted) return;

  final TimeOfDay? time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: earliest.hour, minute: 0),
    helpText: 'Choose your time',
    builder: (BuildContext ctx, Widget? child) => Theme(
      data: Theme.of(ctx).copyWith(
        colorScheme: Theme.of(ctx).colorScheme.copyWith(
              primary: IvoryColors.burgundy,
              onPrimary: IvoryColors.ivory,
              surface: IvoryColors.surface,
            ),
      ),
      child: child ?? const SizedBox.shrink(),
    ),
  );
  if (time == null || !context.mounted) return;

  final DateTime chosen =
      DateTime(day.year, day.month, day.day, time.hour, time.minute);

  // Told kindly here, decided firmly in the database.
  if (!_insideHours(chosen)) {
    say('Sessions run from ${_spoken(_opensHour)} through to '
        '${_spoken(_closesHour)}. Please choose a time inside '
        'those hours.');
    return;
  }
  if (chosen.isBefore(
      DateTime.now().add(Duration(hours: _noticeHours)))) {
    say('Please choose a time at least $_noticeHours hours from now, '
        'so Ivory can prepare for you.');
    return;
  }

  final bool sure = await showDialog<bool>(
        context: context,
        builder: (BuildContext d) => _ConfirmDialog(
          when: ivoryWhen(chosen),
          minutes: c.minutes,
        ),
      ) ??
      false;
  if (!sure || !context.mounted) return;

  try {
    final String word = await LiveService.instance.pickSlot(c.id, chosen);
    say(word);
  } catch (e) {
    say(houseMessage(e));
  }
  await reload();
}

class _HoursDialog extends StatelessWidget {
  const _HoursDialog({required this.earliest});

  final DateTime earliest;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: IvoryColors.surface,
      title: const Text('Choose your time',
          style: TextStyle(
              color: IvoryColors.burgundy, fontWeight: FontWeight.w700)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _Line(
            icon: Icons.schedule_rounded,
            text: 'Sessions run from ${_spoken(_opensHour)} '
                'through to ${_spoken(_closesHour)}.',
          ),
          const SizedBox(height: 10),
          _Line(
            icon: Icons.hourglass_bottom_rounded,
            text: 'The earliest you can choose is ${ivoryWhen(earliest)}.',
          ),
          const SizedBox(height: 10),
          _Line(
            icon: Icons.event_available_rounded,
            text: 'You can book up to $_horizonDays days ahead. '
                'Ivory will remind you as it comes close.',
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('LATER'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('CHOOSE',
              style: TextStyle(
                  color: IvoryColors.burgundy,
                  fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({required this.when, required this.minutes});

  final String when;
  final int minutes;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: IvoryColors.surface,
      title: const Text('Is this right?',
          style: TextStyle(
              color: IvoryColors.burgundy, fontWeight: FontWeight.w700)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(when,
              style: const TextStyle(
                color: IvoryColors.burgundy,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: 6),
          Text('Together, here.',
              style: const TextStyle(
                  color: IvoryColors.plum, fontSize: 14)),
          const SizedBox(height: 12),
          const Text(
            'Ivory is told the moment you confirm. Open Ivory a little '
            'before and tap JOIN - the call happens here, never on '
            'another app.',
            style: TextStyle(
                color: IvoryColors.plum, fontSize: 13, height: 1.35),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('CHANGE'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('CONFIRM',
              style: TextStyle(
                  color: IvoryColors.burgundy,
                  fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 18, color: IvoryColors.gold),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  color: IvoryColors.plum, fontSize: 13, height: 1.35)),
        ),
      ],
    );
  }
}

// END OF FILE - lib/widgets/call_book_flow.dart
