import 'package:flutter/material.dart';

import '../services/early_service.dart';
import '../theme/ivory_theme.dart';
import '../widgets/early_door_view.dart';
import 'early_door_sheet.dart';

const Color _wash = IvoryColors.emeraldWash;

BoxDecoration _sheetBack() => const BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[IvoryColors.emeraldMid, IvoryColors.emerald],
  ),
  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
);

/// A member tapped a story that came back closed. If it is held for
/// early readers, explain it kindly and return true; otherwise return
/// false and let the caller say its usual words.
Future<bool> showEarlyHeld(BuildContext context, int postId) async {
  final EarlyPost? held = await EarlyService.instance.heldPost(postId);
  if (held == null || !context.mounted) return false;
  final EarlyState? s = EarlyService.instance.state.value;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (BuildContext ctx) => _HeldNote(post: held, state: s),
  );
  return true;
}

class _HeldNote extends StatelessWidget {
  const _HeldNote({required this.post, required this.state});

  final EarlyPost post;
  final EarlyState? state;

  @override
  Widget build(BuildContext context) {
    final EarlyState? s = state;
    String hint = 'Keep your Golden Heart lit and climb the Ivory Ladder '
        'to open the Early Door.';
    if (s != null) {
      if (s.rungHours > 0 && !s.warm) {
        hint = 'Light your Golden Heart today and your door opens '
            '${earlyHoursText(s.rungHours)} early.';
      } else {
        final EarlyWindow? next = s.nextWindow;
        if (next != null) {
          hint = 'Climb to ${next.name} and your door opens '
              '${earlyHoursText(next.hours)} early.';
        }
      }
    }
    return Container(
      decoration: _sheetBack(),
      padding: EdgeInsets.fromLTRB(
        22, 22, 22, 22 + MediaQuery.of(context).viewPadding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const EarlyDoorView(openness: 0.35, width: 76, height: 94),
          const SizedBox(height: 12),
          const Text(
            'Early readers have this now',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _wash,
              fontFamily: IvoryTheme.displayFont,
              fontStyle: FontStyle.italic,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            post.title,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _wash,
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'It opens for everyone ${earlyCountdown(post.publicAt)}, '
            'on ${earlyClock(post.publicAt)}.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _wash.withValues(alpha: 0.92),
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _wash.withValues(alpha: 0.78),
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _wash,
                    side: BorderSide(color: _wash.withValues(alpha: 0.6)),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _wash,
                    foregroundColor: IvoryColors.emerald,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    showEarlyDoorSheet(context);
                  },
                  child: const Text('THE EARLY DOOR'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// END OF FILE - lib/screens/early_held_note.dart
