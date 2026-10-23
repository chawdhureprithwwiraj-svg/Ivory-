import 'package:flutter/material.dart';

/// ============================================================
/// IVORY - THE LANE LAW (CC.195, mended CC.198)
///
/// Two reserved lanes carry every ribbon: TOP and BOTTOM. Each
/// live screen says which lane its furniture owns; a ribbon
/// chooses its lane the moment it starts and never jumps
/// mid-flight. Everyday screens and live video and broadcasts
/// ride the TOP lane; live audio rides the BOTTOM and never the
/// top; a broadcast whose top lane is busy slips to the BOTTOM
/// above the chat bar; if both lanes are busy the ribbon waits.
///
/// CC.198: the bottom lane of a call rides clear above the whole
/// control row on every phone we have filmed, and a standing
/// extend-time offer lifts it above its own card. The top lane
/// rides below each screen's own chrome (the gold house band,
/// tab rows, pill rows) so a ribbon never covers them.
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

  /// A sheet the member must answer (checkout, keyboard) owns bottom.
  static final ValueNotifier<bool> bottomBusy = ValueNotifier<bool>(false);

  /// CC.198: an extend-time offer card or sheet is standing at the
  /// bottom of the call. The bottom lane then rides ABOVE it instead
  /// of hiding behind it or fleeing to the top lane.
  static final ValueNotifier<bool> offerUp = ValueNotifier<bool>(false);

  /// CC.198: extra height of this screen's own top chrome (house
  /// ticker band, admin tab row, live pill row). The top lane rides
  /// below it so a ribbon never covers the band or the tabs.
  static final ValueNotifier<double> topChrome = ValueNotifier<double>(0);

  /// Listened to by the ticker host so lane changes re-decide the
  /// next ribbon at once.
  static Listenable get flags => Listenable.merge(<Listenable>[
        mode,
        topBusy,
        bottomBusy,
        offerUp,
        topChrome,
      ]);

  /// How far above the phone's bottom edge the bottom lane rides,
  /// per room: above the call controls, and above the chat bar on
  /// a broadcast. CC.198 gaps clear the filmed control rows; a
  /// standing offer lifts the lane above its card.
  static double bottomGap(LaneMode m) {
    final double lift = offerUp.value ? 236 : 0;
    switch (m) {
      case LaneMode.broadcast:
        return 132 + lift;
      case LaneMode.audio:
      case LaneMode.video:
        return 168 + lift;
      case LaneMode.everyday:
        return 84 + lift;
    }
  }

  /// The lane a ribbon starting right now should ride, or null when
  /// both lanes are busy and the ribbon must wait its turn.
  /// [keyboard] is true while a chat keyboard eats the bottom lane.
  /// CC.198: an audio call never rides the top lane - the top of a
  /// call belongs to the crest and the connected card; when the
  /// bottom lane is truly busy the ribbon waits instead.
  static Lane? laneFor(LaneMode m, bool keyboard) {
    final bool topOk = !topBusy.value;
    final bool bottomOk = !bottomBusy.value && !keyboard;
    switch (m) {
      case LaneMode.everyday:
      case LaneMode.video:
        return topOk ? Lane.top : (bottomOk ? Lane.bottom : null);
      case LaneMode.audio:
        return bottomOk ? Lane.bottom : null;
      case LaneMode.broadcast:
        return topOk ? Lane.top : (bottomOk ? Lane.bottom : null);
    }
  }
}

// END OF FILE - lib/widgets/lane_law.dart
