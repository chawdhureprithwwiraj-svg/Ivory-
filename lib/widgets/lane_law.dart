import 'package:flutter/material.dart';

/// ============================================================
/// IVORY - THE LANE LAW (CC.195)
///
/// Two reserved lanes carry every ribbon: TOP and BOTTOM. Each
/// live screen says which lane its furniture owns; a ribbon
/// chooses its lane the moment it starts and never jumps
/// mid-flight. Everyday screens and live video and broadcasts
/// ride the TOP lane; live audio rides the BOTTOM; a broadcast
/// whose top lane is busy slips to the BOTTOM above the chat
/// bar; if both lanes are busy the ribbon waits.
///
/// The lanes are measured above the phone's own bars and above
/// each screen's furniture, so a ribbon never sits on a control,
/// a keyboard or a gesture pill.
/// ============================================================
enum LaneMode { everyday, audio, video, broadcast }

enum Lane { top, bottom }

class LaneLaw {
  LaneLaw._();

  /// Which kind of room is open right now.
  static final ValueNotifier<LaneMode> mode =
      ValueNotifier<LaneMode>(LaneMode.everyday);

  /// The joined-members strip (or anything else) owns the top lane.
  static final ValueNotifier<bool> topBusy = ValueNotifier<bool>(false);

  /// The extend-time offer (or anything else) owns the bottom lane.
  static final ValueNotifier<bool> bottomBusy = ValueNotifier<bool>(false);

  /// Listened to by the ticker host so lane changes re-decide the
  /// next ribbon at once.
  static Listenable get flags =>
      Listenable.merge(<Listenable>[mode, topBusy, bottomBusy]);

  /// How far above the phone's bottom edge the bottom lane rides,
  /// per room: above the call controls, and above the chat bar on
  /// a broadcast.
  static double bottomGap(LaneMode m) {
    switch (m) {
      case LaneMode.broadcast:
        return 132;
      case LaneMode.audio:
      case LaneMode.video:
        return 96;
      case LaneMode.everyday:
        return 84;
    }
  }

  /// The lane a ribbon starting right now should ride, or null when
  /// both lanes are busy and the ribbon must wait its turn.
  /// [keyboard] is true while a chat keyboard eats the bottom lane.
  static Lane? laneFor(LaneMode m, bool keyboard) {
    final bool topOk = !topBusy.value;
    final bool bottomOk = !bottomBusy.value && !keyboard;
    switch (m) {
      case LaneMode.everyday:
      case LaneMode.video:
        return topOk ? Lane.top : (bottomOk ? Lane.bottom : null);
      case LaneMode.audio:
        return bottomOk ? Lane.bottom : (topOk ? Lane.top : null);
      case LaneMode.broadcast:
        return topOk ? Lane.top : (bottomOk ? Lane.bottom : null);
    }
  }
}

// END OF FILE - lib/widgets/lane_law.dart
