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
        // IN THE ROOM IS A CLAIM ABOUT RIGHT NOW, SO IT HAS TO
        // EXPIRE.
        //
        // `call_finish` is the only thing that really ends a
        // session, so a call whose app was closed stays
        // 'active' in the database for ever. The pill then
        // said IN THE ROOM about a session from last Tuesday.
        //
        // Two ways it can be a lie, and both are caught here:
        // no agreed time means it was never really entered,
        // and an agreed time long past means whatever happened
        // is over. Six hours is far beyond the longest session
        // Ivory sells, so nothing live can ever be mislabelled.
        final DateTime? when = c.requestedFor;
        final bool stale = when != null &&
            DateTime.now().difference(when.toLocal()) >
                const Duration(hours: 6);
        final bool really = when != null && !stale;
        text = really ? 'IN THE ROOM' : 'LEFT OPEN';
        bg = really ? IvoryColors.gold : IvoryColors.amber;
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
