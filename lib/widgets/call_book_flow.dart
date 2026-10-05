import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/live_models.dart';
import '../services/live_service.dart';

/// ============================================================
/// IVORY - TELLING IVORY THE SLOT
///
/// The member picks their date and time on the house calendar
/// (cal.com - availability, notice and horizon are all controlled
/// there). Back in Ivory they confirm the slot they chose, so the
/// JOIN button, the door and the reminders all know when.
/// ============================================================
Future<void> bookCallSlot(
  BuildContext context,
  CallRequest c, {
  required void Function(String msg) say,
  required Future<void> Function() reload,
}) async {
  final BookingLink? link =
      await LiveService.instance.bookingLink(c.kind);
  final String? url = link?.url;
  if (url != null && url.isNotEmpty) {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
  if (!context.mounted) return;
  if (url == null || url.isEmpty) {
    say('The house calendar is not up yet - write to Ivory and a time '
        'will be agreed with you.');
    return;
  }
  final bool tell = await showDialog<bool>(
        context: context,
        builder: (BuildContext d) => AlertDialog(
          title: const Text('Picked a slot?'),
          content: const Text('Choose your date and time on the calendar '
              'that just opened, then tell Ivory the slot you picked. '
              'JOIN wakes up just before it.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(d).pop(false),
              child: const Text('LATER'),
            ),
            TextButton(
              onPressed: () => Navigator.of(d).pop(true),
              child: const Text('TELL IVORY'),
            ),
          ],
        ),
      ) ??
      false;
  if (!tell || !context.mounted) return;
  final DateTime now = DateTime.now();
  final DateTime? day = await showDatePicker(
    context: context,
    initialDate: now.add(const Duration(days: 1)),
    firstDate: now,
    lastDate: now.add(const Duration(days: 21)),
    helpText: 'Which day did you book?',
  );
  if (day == null || !context.mounted) return;
  final TimeOfDay? time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.now(),
    helpText: 'What time did you book? (your clock)',
  );
  if (time == null || !context.mounted) return;
  final DateTime when =
      DateTime(day.year, day.month, day.day, time.hour, time.minute);
  try {
    await LiveService.instance.confirmBooking(c.id, when);
    say('Your slot is with the house. Join a little before it.');
  } catch (e) {
    say(e.toString().replaceFirst('Exception: ', ''));
  }
  await reload();
}

// END OF FILE - lib/widgets/call_book_flow.dart
