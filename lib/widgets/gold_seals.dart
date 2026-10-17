import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';
import 'gold_fx.dart';

/// ============================================================
/// IVORY - THE TEN SEALS
///
/// One seal per topic. A seal turns to polished gold once a member
/// has played that topic, so the row is a true record of what they
/// have done, never a promise. Used on the Home card and on the
/// topic reveal.
/// ============================================================

class GoldSeal extends StatelessWidget {
  const GoldSeal({
    super.key,
    required this.size,
    this.earned = false,
    this.glow = 0,
    this.mark,
  });

  final double size;
  final bool earned;

  /// 0 to 1: how brightly this seal is glowing right now.
  final double glow;

  /// Optional icon on the seal, for the reveal.
  final IconData? mark;

  @override
  Widget build(BuildContext context) {
    final bool lit = earned || glow > 0.05;
    final double g = earned ? 1 : glow.clamp(0.0, 1.0).toDouble();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: lit
            ? RadialGradient(
                center: const Alignment(-0.35, -0.45),
                colors: <Color>[
                  GoldTones.shine,
                  GoldTones.light,
                  GoldTones.mid.withValues(alpha: 0.55 + 0.45 * g),
                  GoldTones.deep.withValues(alpha: 0.5 + 0.5 * g),
                ],
                stops: const <double>[0, 0.3, 0.7, 1],
              )
            : null,
        color: lit ? null : IvoryColors.plum,
        border: Border.all(
          color: lit ? GoldTones.rim : IvoryColors.gold.withValues(alpha: 0.38),
          width: lit ? 1.2 : 1,
        ),
        boxShadow: lit
            ? <BoxShadow>[
                BoxShadow(
                  color: IvoryColors.gold.withValues(alpha: 0.5 * g),
                  blurRadius: 4 + 14 * g,
                ),
              ]
            : null,
      ),
      child: mark == null
          ? (earned
                ? Icon(
                    Icons.favorite,
                    size: size * 0.5,
                    color: IvoryColors.burgundy,
                  )
                : null)
          : Icon(mark, size: size * 0.52, color: IvoryColors.burgundy),
    );
  }
}

class GoldSealRow extends StatelessWidget {
  const GoldSealRow({super.key, required this.earned, required this.total});

  final int earned;
  final int total;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final int n = total < 1 ? 10 : total;
        final double gap = 6;
        final double size = ((c.maxWidth - gap * (n - 1)) / n)
            .clamp(14.0, 30.0)
            .toDouble();
        return Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            for (int i = 0; i < n; i++) ...<Widget>[
              if (i > 0) SizedBox(width: gap),
              GoldSeal(size: size, earned: i < earned),
            ],
          ],
        );
      },
    );
  }
}

// END OF FILE - lib/widgets/gold_seals.dart
