import 'package:flutter/material.dart';

import '../models/reward_models.dart';
import '../screens/treasures_sheet.dart';
import '../services/reward_service.dart';
import '../theme/ivory_theme.dart';
import 'reward_badge.dart';

/// The member's treasures on the Profile screen: a shelf of the
/// badges earned so far and a door to the full collection. It shows
/// nothing until the house has made at least one treasure.
class ProfileTreasuresCard extends StatefulWidget {
  const ProfileTreasuresCard({super.key});

  @override
  State<ProfileTreasuresCard> createState() => _ProfileTreasuresCardState();
}

class _ProfileTreasuresCardState extends State<ProfileTreasuresCard> {
  @override
  void initState() {
    super.initState();
    RewardService.instance.refreshQuietly();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<RewardState?>(
      valueListenable: RewardService.instance.state,
      builder: (BuildContext _, RewardState? r, Widget? __) {
        if (r == null || r.total == 0) return const SizedBox.shrink();
        final List<RewardItem> shelf = r.earned.take(5).toList();
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => showTreasuresSheet(context),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: IvoryTheme.card(radius: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Expanded(
                        child: IvoryEyebrow(
                          'Your treasures',
                          icon: Icons.auto_awesome,
                        ),
                      ),
                      Text(
                        '${r.earned.length} of ${r.total}',
                        style: const TextStyle(
                          color: IvoryColors.plum,
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: IvoryColors.plum),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (shelf.isEmpty)
                    Text(
                      'Light your Golden Heart to begin your collection.',
                      style: TextStyle(
                        color: IvoryColors.textFaint,
                        fontSize: 12.5,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      children: <Widget>[
                        for (final RewardItem e in shelf)
                          RewardBadge(
                            shape: e.shape,
                            metal: e.metal,
                            size: 52,
                            animate: false,
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// END OF FILE - lib/widgets/profile_treasures_card.dart
