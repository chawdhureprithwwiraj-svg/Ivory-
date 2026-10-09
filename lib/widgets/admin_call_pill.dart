import 'package:flutter/material.dart';

import '../models/live_models.dart';
import '../theme/ivory_theme.dart';

/// ============================================================
/// THE WORD ON A SESSION, IN ONE PILL.
///
/// Lifted out of admin_calls_tab.dart, which had grown past the
/// size that can be pasted reliably on a phone. Nothing about
/// it changed in the move.
///
/// The wording is deliberate. A session marked active with no
/// agreed time was never really entered - it is a leftover, and
/// saying IN THE ROOM about it would be a lie told to the only
/// person who can fix it.
/// ============================================================
class AdminCallPill extends StatelessWidget {
  const AdminCallPill({super.key, required this.call});

  final AdminCall call;

  @override
  Widget build(BuildContext context) {
    final AdminCall c = call;
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
        // A session with no agreed time was never really entered -
        // it is a leftover. Saying IN THE ROOM about it is a lie.
        text = c.requestedFor == null ? 'LEFT OPEN' : 'IN THE ROOM';
        bg = c.requestedFor == null ? IvoryColors.amber : IvoryColors.gold;
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

}

// END OF FILE - lib/widgets/admin_call_pill.dart
