import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/ivory_theme.dart';

/// ============================================================
/// IVORY - THE HOUSE PROMISE
///
/// The two consent moments of the house, written once and used
/// anywhere: the adult promise on the create-account form, and
/// "Just between us." before a call. Every tick becomes a
/// timestamped row in member_consents - the database is the
/// memory of the house.
/// ============================================================

/// The create-account promise. Pure presentation: the screen owns
/// the bool, and Postgres records the row once the account exists.
class AdultPromiseTile extends StatelessWidget {
  const AdultPromiseTile({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'This is a private world, for adults only.',
          style: TextStyle(
            fontFamily: IvoryTheme.displayFont,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w700,
            fontSize: 14.5,
            color: IvoryColors.burgundy,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Checkbox(
              value: value,
              onChanged: (bool? v) => onChanged(v ?? false),
              side: const BorderSide(color: IvoryColors.gold, width: 1.4),
              checkColor: IvoryColors.burgundy,
              fillColor: WidgetStateProperty.resolveWith<Color>(
                (Set<WidgetState> states) =>
                    states.contains(WidgetState.selected)
                        ? IvoryColors.gold
                        : Colors.transparent,
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(!value),
                child: Text(
                  "I'm 18 or over, and what happens in Ivory stays in "
                  'Ivory - no recording, no screenshots, no sharing.',
                  style: TextStyle(
                    color: IvoryColors.textSoft,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// "Just between us." - the only gate before a call. Declining
/// leaves the room untouched; accepting writes a timestamped
/// call_consent row and returns true.
Future<bool> askBetweenUs(BuildContext context) async {
  final bool? ready = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) => AlertDialog(
      backgroundColor: IvoryColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      title: Text(
        'Just between us.',
        style: TextStyle(
          fontFamily: IvoryTheme.displayFont,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: IvoryColors.burgundy,
        ),
      ),
      content: Text(
        "No recording, no screenshots - from either of us. I don't "
        'record either. Ready?',
        style: TextStyle(
          color: IvoryColors.textSoft,
          fontSize: 14,
          height: 1.5,
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'NOT NOW',
            style: TextStyle(color: IvoryColors.textFaint, fontSize: 13),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            "I'M READY",
            style: TextStyle(
              color: IvoryColors.burgundy,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    ),
  );
  if (ready != true) return false;

  try {
    final String? uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid != null) {
      await Supabase.instance.client
          .from('member_consents')
          .insert(<String, dynamic>{'user_id': uid, 'kind': 'call_consent'});
    }
  } catch (_) {
    // The promise was given in the moment; a storage hiccup
    // must not cancel the call itself.
  }
  return true;
}

// END OF FILE - lib/widgets/house_consent.dart
