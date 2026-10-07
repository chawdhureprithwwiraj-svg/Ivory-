import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';

/// ============================================================
/// IVORY - SMALL PIECES THE CALL SHEET USES
///
/// Lifted out of call_wish_sheet.dart so that file stays under
/// the size ceiling, and so the time wording lives in exactly
/// one place.
///
/// THE TIME RULE, WRITTEN ONCE:
///   Postgres hands every time over in UTC. A member must never
///   be shown UTC. Everything here calls toLocal() first, so a
///   session agreed for noon says noon on both phones.
/// ============================================================

/// "8 Oct, 12:00 pm" - the member's own clock, never UTC.
String ivoryWhen(DateTime d) {
  final DateTime l = d.toLocal();
  const List<String> months = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final int hour12 = l.hour % 12 == 0 ? 12 : l.hour % 12;
  final String mm = l.minute.toString().padLeft(2, '0');
  final String ampm = l.hour < 12 ? 'am' : 'pm';
  return '${l.day} ${months[l.month - 1]}, $hour12:$mm $ampm';
}

/// "12:00 pm" alone, for the second half of a window.
String ivoryClock(DateTime d) {
  final DateTime l = d.toLocal();
  final int hour12 = l.hour % 12 == 0 ? 12 : l.hour % 12;
  final String mm = l.minute.toString().padLeft(2, '0');
  final String ampm = l.hour < 12 ? 'am' : 'pm';
  return '$hour12:$mm $ampm';
}

/// One numbered step in "How it works".
class CallStep extends StatelessWidget {
  const CallStep({
    super.key,
    required this.number,
    required this.title,
    required this.body,
  });

  final int number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: IvoryColors.surfaceWarm,
              shape: BoxShape.circle,
              border: Border.all(color: IvoryColors.gold, width: 1.2),
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: IvoryColors.burgundy,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    color: IvoryColors.burgundy,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 12.8,
                    height: 1.45,
                    color: IvoryColors.textSoft,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// END OF FILE - lib/widgets/call_sheet_bits.dart
