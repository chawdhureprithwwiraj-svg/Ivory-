import 'package:flutter/material.dart';

/// HOW MUCH ROOM A BOTTOM SHEET MUST LEAVE AT ITS FOOT.
///
/// `viewInsets.bottom` is the KEYBOARD and nothing else. The
/// system navigation bar - the back/home/recents strip along the
/// foot of the phone - lives in `viewPadding.bottom`. A sheet
/// that counts only the first puts its last button underneath
/// that strip, where no finger can reach it.
///
/// Every bottom sheet in Ivory had this wrong, which is why SAVE
/// AND NOTIFY THEM could not be tapped. One function now, so it
/// cannot drift apart again.
///
/// [extra] is the breathing room you want above the bar.
double ivorySheetFoot(BuildContext context, {double extra = 18}) {
  final MediaQueryData mq = MediaQuery.of(context);
  return mq.viewInsets.bottom + mq.viewPadding.bottom + extra;
}

// END OF FILE - lib/theme/ivory_insets.dart
