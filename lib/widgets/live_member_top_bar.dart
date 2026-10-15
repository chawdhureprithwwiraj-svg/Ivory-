import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';
import 'live_stage_bits.dart';
import 'premium_badge.dart';

/// Keeps LiveTopBar's controls intact. Call badges belong beside the
/// member identity tile; a header badge is opt-in to avoid misattribution.
class LiveMemberTopBar {
  LiveMemberTopBar._();

  static Widget forRoom({
    required String title,
    required String clock,
    required bool live,
    required bool isCall,
    required bool hosting,
    required bool watching,
    required VoidCallback onClose,
    String? memberTierName,
    int memberTierLevel = 0,
    bool forSelf = false,
    bool showTierInHeader = false,
    VoidCallback? onGift,
    VoidCallback? onBeauty,
  }) {
    final Widget roomBar = LiveTopBar.forRoom(
      title: title,
      clock: clock,
      live: live,
      isCall: isCall,
      hosting: hosting,
      watching: watching,
      onClose: onClose,
      onGift: onGift,
      onBeauty: onBeauty,
    );
    if (!isCall || memberTierLevel <= 0 || !showTierInHeader) return roomBar;
    final Widget insignia = PremiumBadge.compact(
      tierName: memberTierName ?? '',
      level: memberTierLevel,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        roomBar,
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 58, bottom: 4),
            child: forSelf
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Text(
                        'YOUR MEMBERSHIP',
                        style: TextStyle(
                          color: IvoryColors.cream,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(width: 6),
                      insignia,
                    ],
                  )
                : insignia,
          ),
        ),
      ],
    );
  }
}

// END OF FILE - lib/widgets/live_member_top_bar.dart
