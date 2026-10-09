import 'package:flutter/material.dart';

import '../models/wish.dart';
import '../screens/wish_screen.dart';
import '../theme/ivory_theme.dart';

/// ============================================================
/// ONE WISH CATEGORY, AS A CARD.
///
/// Lifted out of wish_screen.dart, which had grown past the
/// size that can be pasted reliably on a phone. Nothing about
/// it changed in the move.
///
/// The two call wishes wear the gold border because they are
/// the offer everything else supports. [included] is true when
/// this member's tier already covers the category, in which
/// case the card says so instead of naming a price.
/// ============================================================
class WishCategoryCard extends StatelessWidget {
  const WishCategoryCard({
    super.key,
    required this.category,
    required this.included,
    required this.onOpen,
  });

  final WishCategory category;
  final bool included;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final WishCategory c = category;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onOpen,
          child: Container(
            padding: EdgeInsets.all(c.highlight ? 18 : 16),
            // The two call wishes are the offer everything else
            // supports, so they wear the gold border and a warmer
            // fill rather than the plain card.
            decoration: c.highlight
                ? BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        Color(0xFFFFFCF2),
                        Color(0xFFFCEBCB),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: IvoryColors.gold, width: 1.6),
                    boxShadow: IvoryTheme.softShadow(blur: 16, y: 6),
                  )
                : IvoryTheme.card(),
            child: Row(
              children: <Widget>[
                Container(
                  width: c.highlight ? 56 : 50,
                  height: c.highlight ? 56 : 50,
                  decoration: BoxDecoration(
                    gradient: IvoryColors.goldGradient,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(wishIcon(c.icon),
                      color: IvoryColors.burgundy, size: 25),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (c.highlight) ...<Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: IvoryColors.burgundy,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            c.isVideoCall ? 'LIVE WITH ME' : 'MY VOICE, YOURS',
                            style: const TextStyle(
                              color: IvoryColors.cream,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 7),
                      ],
                      Text(
                        c.name,
                        style: TextStyle(
                          color: IvoryColors.burgundy,
                          fontSize: c.highlight ? 17 : 15.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (c.tagline != null) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(
                          c.tagline!,
                          style: c.highlight
                              // The two call wishes are the headline
                              // offer: gold serif italic, the same
                              // emphasis the Home hero uses.
                              ? const TextStyle(
                                  fontFamily: 'serif',
                                  fontSize: 14,
                                  height: 1.45,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w600,
                                  color: IvoryColors.plum,
                                )
                              : TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: IvoryColors.textSoft,
                                ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      // Quoting a price to somebody who has
                      // already paid for it is the quickest way
                      // to make them feel cheated.
                      if (c.isCall && included)
                        Row(
                          children: <Widget>[
                            const Icon(Icons.verified_rounded,
                                size: 14, color: IvoryColors.amber),
                            const SizedBox(width: 6),
                            Text(
                              'Included with your membership',
                              style: const TextStyle(
                                color: IvoryColors.plum,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: <Widget>[
                            Text(
                              c.priceLabel,
                              style: const TextStyle(
                                color: IvoryColors.plum,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              c.isCall
                                  ? c.callLabel
                                  : '~${c.deliveryDays} days',
                              style: TextStyle(
                                fontSize: 12,
                                color: IvoryColors.textFaint,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: IvoryColors.plum),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// END OF FILE - lib/widgets/wish_category_card.dart
