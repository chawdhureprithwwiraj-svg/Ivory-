import 'package:flutter/material.dart';

import '../models/live_models.dart';
import '../theme/ivory_theme.dart';
import 'member_avatar.dart';
import 'premium_badge.dart';
import 'report_sheet.dart';

/// One broadcast-chat message, including the sender's current paid-tier mark.
class LiveMessageBubble extends StatelessWidget {
  const LiveMessageBubble({super.key, required this.message});

  final LiveMessage message;

  @override
  Widget build(BuildContext context) {
    final LiveMessage m = message;
    final List<Shadow> readableShadow = <Shadow>[
      Shadow(
        color: IvoryColors.burgundy.withValues(alpha: 0.88),
        blurRadius: 5,
        offset: const Offset(0, 1),
      ),
      Shadow(
        color: IvoryColors.burgundy.withValues(alpha: 0.42),
        blurRadius: 11,
      ),
    ];
    if (m.isHost) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onLongPress: () => showReportSheet(context, preset: 'content'),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.94,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: IvoryColors.burgundy.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: IvoryColors.gold.withValues(alpha: 0.16),
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: IvoryColors.burgundy.withValues(alpha: 0.34),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Icon(
                        Icons.circle,
                        size: 8,
                        color: IvoryColors.gold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      fit: FlexFit.loose,
                      child: RichText(
                        text: TextSpan(
                          children: <TextSpan>[
                            TextSpan(
                              text: 'IVORY  ',
                              style: TextStyle(
                                fontFamily: IvoryTheme.displayFont,
                                fontWeight: FontWeight.w900,
                                fontSize: 12.5,
                                letterSpacing: 1,
                                color: IvoryColors.gold,
                                shadows: readableShadow,
                              ),
                            ),
                            TextSpan(
                              text: m.body,
                              style: TextStyle(
                                fontFamily: IvoryTheme.displayFont,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                height: 1.32,
                                color: IvoryColors.cream,
                                shadows: readableShadow,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final String displayText = _said(m.body).$1;
    final String? note = _said(m.body).$2;
    final bool premium = m.senderMembershipResolved &&
        m.senderHasActivePaidTier &&
        m.senderTierLevel > 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: GestureDetector(
        onLongPress: () => showReportSheet(context, preset: 'content'),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            MemberAvatar(
              displayName: m.senderName ?? 'A member',
              imageUrl: m.senderAvatarUrl,
              size: 36,
              premiumFrame: premium && (m.senderAvatarUrl?.isNotEmpty ?? false),
            ),
            const SizedBox(width: 8),
            Flexible(
              fit: FlexFit.loose,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: IvoryColors.burgundy.withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: IvoryColors.cream.withValues(alpha: 0.10),
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: IvoryColors.burgundy.withValues(alpha: 0.30),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 15.5,
                      height: 1.35,
                      color: IvoryColors.cream,
                      shadows: readableShadow,
                    ),
                    children: <InlineSpan>[
                      TextSpan(
                        text: "${m.senderName ?? 'A member'}  ",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14.5,
                          color: IvoryColors.peach,
                          shadows: readableShadow,
                        ),
                      ),
                      if (premium)
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 5),
                            child: PremiumBadge.compact(
                              tierName: m.senderTierName ?? '',
                              level: m.senderTierLevel,
                            ),
                          ),
                        ),
                      TextSpan(text: displayText),
                      if (note != null)
                        TextSpan(
                          text: '\n\u201C$note\u201D',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 15,
                            color: IvoryColors.gold,
                            shadows: readableShadow,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static (String, String?) _said(String body) {
    final int cut = body.indexOf('\n');
    if (cut < 0) return (body, null);
    final String note = body.substring(cut + 1).trim();
    final String quoted = note.startsWith('"') && note.endsWith('"')
        ? note.substring(1, note.length - 1)
        : note;
    return (body.substring(0, cut), quoted.isEmpty ? null : quoted);
  }
}

// END OF FILE - lib/widgets/live_message_bubble.dart
