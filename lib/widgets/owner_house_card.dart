import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';

/// ============================================================
/// IVORY - THE OWNER'S OWN MEMBERSHIP CARD
///
/// THE OWNER IS NOT A CUSTOMER OF HER OWN HOUSE.
///
/// She has not bought a tier, so Profile used to fall into the
/// default-access branch and offer to sell her a membership.
/// Her own app was advertising to her.
///
/// So she gets a different card: what she HOLDS, not what she
/// lacks. One deep burgundy panel edged in gold - the same
/// cloth the member's premium ribbon is cut from, so it reads
/// as the top of the house rather than the absence of a plan.
///
/// No tier name, because she is not on a tier. No days
/// remaining, because nothing of hers expires. No price and no
/// button, because there is nowhere for her to go and nothing
/// for her to buy. Deliberately plain: this is the back of the
/// house, not a shop window.
///
/// Lifted into its own file because profile_screen.dart was at
/// the paste ceiling, and because speaking to the owner as the
/// owner is a responsibility of its own.
/// ============================================================
class OwnerHouseCard extends StatelessWidget {
  const OwnerHouseCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[IvoryColors.burgundy, IvoryColors.plum],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: IvoryColors.gold, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.workspace_premium_rounded,
                  color: IvoryColors.gold, size: 22),
              const SizedBox(width: 9),
              Text(
                'Ivory',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: IvoryColors.gold,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          const Text(
            'This is your house. Every tier, every room and every '
            'door is already open to you, and none of it expires.',
            style: TextStyle(
              color: IvoryColors.cream,
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// END OF FILE - lib/widgets/owner_house_card.dart
