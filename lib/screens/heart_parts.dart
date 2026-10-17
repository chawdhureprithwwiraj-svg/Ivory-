import 'package:flutter/material.dart';

import '../models/heart_models.dart';
import '../models/reward_models.dart';
import '../services/reward_service.dart';
import '../theme/ivory_theme.dart';
import '../widgets/gold_fx.dart';
import '../widgets/gold_fx3d.dart';
import '../widgets/heart_paint.dart';

/// Small pieces of the heart sheet (heart_sheet.dart).

const TextStyle _label = TextStyle(
  color: IvoryColors.plum,
  fontSize: 11.5,
  fontWeight: FontWeight.w800,
  letterSpacing: 2.4,
);

class HeartSection extends StatelessWidget {
  const HeartSection(this.title, this.child, {super.key, this.delayMs = 0});

  final String title;
  final Widget child;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    return GoldRise(
      delayMs: delayMs,
      child: Padding(
        padding: const EdgeInsets.only(top: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: _label),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

IconData heartActionIcon(String key) {
  switch (key) {
    case 'greet':
      return Icons.favorite_border;
    case 'read_post':
      return Icons.menu_book_outlined;
    case 'vault_key':
      return Icons.vpn_key_outlined;
    case 'poll_vote':
      return Icons.how_to_vote_outlined;
    case 'live_join':
      return Icons.sensors;
    case 'reach_out':
      return Icons.card_giftcard;
    default:
      return Icons.auto_awesome;
  }
}

class HeartActionRow extends StatelessWidget {
  const HeartActionRow(this.a, {super.key});

  final HeartAction a;

  @override
  Widget build(BuildContext context) {
    final bool done = a.complete;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: IvoryTheme.card(highlighted: done, radius: 16),
      child: Row(
        children: <Widget>[
          Icon(
            heartActionIcon(a.key),
            size: 21,
            color: done ? GoldTones.deep : IvoryColors.plum,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              a.label,
              style: TextStyle(
                color: IvoryColors.burgundy,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          if (a.cap > 1 && !done)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Text(
                '${a.done}/${a.cap}',
                style: TextStyle(color: IvoryColors.textFaint, fontSize: 12),
              ),
            ),
          if (done)
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: <Color>[GoldTones.shine, GoldTones.mid],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(
                Icons.check,
                size: 16,
                color: IvoryColors.burgundy,
              ),
            )
          else
            Text(
              '+${a.points}',
              style: const TextStyle(
                color: GoldTones.deep,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
        ],
      ),
    );
  }
}

class HeartMends extends StatelessWidget {
  const HeartMends(this.s, {super.key});

  final HeartState s;

  @override
  Widget build(BuildContext context) {
    final int more = (s.mendEvery - s.mendProgress).clamp(1, 9999);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: IvoryTheme.card(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              for (int i = 0; i < s.mendMax; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: HeartPaint(
                    size: 34,
                    compact: true,
                    fill: i < s.mends ? 1 : 0,
                  ),
                ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  s.mends == 1 ? '1 mend held' : '${s.mends} mends held',
                  style: const TextStyle(
                    color: IvoryColors.burgundy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'A mend carries your glow across one missed day. '
            '${s.mends >= s.mendMax ? 'You are holding the most you can.' : 'You earn one every ${s.mendEvery} lit days, so $more more to the next.'}',
            style: TextStyle(
              color: IvoryColors.textFaint,
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class HeartWeek extends StatelessWidget {
  const HeartWeek(this.days, {super.key});

  final List<HeartDay> days;

  static const List<String> _d = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        for (int i = 0; i < days.length; i++)
          Column(
            children: <Widget>[
              Opacity(
                opacity: days[i].lit || i == days.length - 1 ? 1 : 0.55,
                child: HeartPaint(
                  size: 38,
                  compact: true,
                  fill: days[i].lit ? 1 : 0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                i == days.length - 1
                    ? 'TODAY'
                    : _d[(DateTime.tryParse(days[i].day)?.weekday ?? 1) - 1],
                style: TextStyle(
                  color: i == days.length - 1
                      ? IvoryColors.burgundy
                      : IvoryColors.textFaint,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class HeartNext extends StatelessWidget {
  const HeartNext(this.s, {super.key});

  final HeartState s;

  @override
  Widget build(BuildContext context) {
    final int? n = s.nextTierDays;
    if (s.nextTierName == null || n == null) {
      return Text(
        'You wear the highest glow there is.',
        style: TextStyle(color: IvoryColors.textFaint, fontSize: 13),
      );
    }
    final double ratio = s.streak / (s.streak + n);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '$n more lit ${n == 1 ? 'day' : 'days'} in a row to '
          '${s.nextTierName!.toUpperCase()}',
          style: const TextStyle(
            color: IvoryColors.burgundy,
            fontWeight: FontWeight.w800,
            fontSize: 13.5,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 9,
            child: Stack(
              children: <Widget>[
                Container(color: IvoryColors.hairline),
                FractionallySizedBox(
                  widthFactor: ratio.clamp(0.04, 1.0),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[GoldTones.light, GoldTones.deep],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The doorway from the heart to the treasures.
class HeartTreasuresRow extends StatelessWidget {
  const HeartTreasuresRow({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<RewardState?>(
      valueListenable: RewardService.instance.state,
      builder: (BuildContext _, RewardState? r, Widget? __) {
        final bool fresh = (r?.unseen ?? 0) > 0;
        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: IvoryTheme.card(highlighted: fresh, radius: 18),
            child: Row(
              children: <Widget>[
                const Icon(Icons.auto_awesome, color: GoldTones.deep),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'MY TREASURES',
                        style: TextStyle(
                          color: IvoryColors.burgundy,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.6,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        (r != null && r.total > 0)
                            ? '${r.earned.length} of ${r.total} earned'
                            : 'Badges and keys you earn',
                        style: TextStyle(
                          color: IvoryColors.textFaint,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (fresh)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: GoldTones.mid,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'NEW',
                      style: TextStyle(
                        color: IvoryColors.burgundy,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                const Icon(Icons.chevron_right, color: IvoryColors.plum),
              ],
            ),
          ),
        );
      },
    );
  }
}

// END OF FILE - lib/screens/heart_parts.dart
