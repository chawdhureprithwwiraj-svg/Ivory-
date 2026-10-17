import 'package:flutter/material.dart';

import '../models/reward_models.dart';
import '../screens/treasures_sheet.dart';
import '../theme/ivory_theme.dart';
import 'gold_burst.dart';
import 'gold_button.dart';
import 'gold_fx.dart';
import 'gold_fx3d.dart';
import 'gold_light.dart';
import 'gold_sound.dart';
import 'reward_badge.dart';

/// Shows the treasures a member has just earned, one after another.
Future<void> showTreasureReveal(BuildContext context, List<RewardItem> items) {
  if (items.isEmpty) return Future<void>.value();
  GoldSound.instance.load();
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Treasure earned',
    barrierColor: IvoryColors.burgundy.withValues(alpha: 0.86),
    transitionDuration: const Duration(milliseconds: 380),
    transitionBuilder:
        (BuildContext _, Animation<double> a, Animation<double> __, Widget c) =>
            FadeTransition(opacity: a, child: c),
    pageBuilder:
        (BuildContext _, Animation<double> __, Animation<double> ___) =>
            _Reveal(items: items),
  );
}

/// ============================================================
/// IVORY - A TREASURE IS YOURS
///
/// Light turns behind a large badge that leans in 3D, with a flash, a
/// shockwave, coins and glitter. Several treasures show one by one.
/// ============================================================
class _Reveal extends StatefulWidget {
  const _Reveal({required this.items});

  final List<RewardItem> items;

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> {
  int _i = 0;

  @override
  void initState() {
    super.initState();
    GoldSound.instance.big('golden');
  }

  void _next() {
    if (_i + 1 < widget.items.length) {
      setState(() => _i++);
      GoldSound.instance.big('golden');
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final RewardItem r = widget.items[_i];
    final bool last = _i + 1 >= widget.items.length;
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          const Positioned.fill(child: IgnorePointer(child: GlitterRain())),
          Positioned.fill(
            child: IgnorePointer(
              child: GoldFlash(key: ValueKey<int>(_i), strength: 0.5),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: GoldShockwave(
                key: ValueKey<int>(_i),
                origin: const Alignment(0, -0.25),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CoinBurst(
                key: ValueKey<int>(_i),
                big: true,
                origin: const Alignment(0, -0.25),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const SizedBox(height: 24),
                  GoldShimmerText(
                    r.isAccess ? 'A KEY IS YOURS' : 'A TREASURE IS YOURS',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: IvoryTheme.displayFont,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      const GoldRays(size: 330, opacity: 0.26),
                      GoldTilt(
                        radius: 40,
                        child: RewardBadge(
                          key: ValueKey<int>(r.id),
                          shape: r.shape,
                          metal: r.metal,
                          size: 200,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    r.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: IvoryColors.cream,
                      fontFamily: IvoryTheme.displayFont,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  if (r.blurb.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        r.blurb,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: IvoryColors.cream.withValues(alpha: 0.85),
                          fontSize: 14.5,
                          height: 1.45,
                        ),
                      ),
                    ),
                  if (r.prize?.code != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Text(
                        'A DISCOUNT CODE CAME WITH IT: ${r.prize!.offText}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: GoldTones.light,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          height: 1.4,
                        ),
                      ),
                    ),
                  const SizedBox(height: 26),
                  GoldButton(
                    label: last ? 'VIEW MY TREASURES' : 'NEXT TREASURE',
                    icon: last ? Icons.auto_awesome : Icons.arrow_forward,
                    onTap: () {
                      if (last) {
                        final NavigatorState nav = Navigator.of(context);
                        nav.pop();
                        showTreasuresSheet(nav.context);
                      } else {
                        _next();
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  if (last)
                    GoldButton(label: 'CLOSE', ghost: true, onTap: _next),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// END OF FILE - lib/widgets/treasure_reveal.dart
