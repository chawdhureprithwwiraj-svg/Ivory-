import 'package:flutter/material.dart';

import '../models/quiz_models.dart';
import '../theme/ivory_theme.dart';
import '../widgets/gold_burst.dart';
import '../widgets/gold_button.dart';
import '../widgets/gold_fx.dart';
import '../widgets/gold_fx3d.dart';

/// ============================================================
/// IVORY - THE GOLDEN KNOCK-OFF: BEFORE THE QUIZ
///
/// The rules, said plainly, in a room full of light: a coin
/// turning in rays, the title cast in gold, the rules rising one
/// by one on a panel that leans toward the finger. The unsealing
/// is in golden_reveal.dart and the result in golden_result.dart.
/// ============================================================

TextStyle goldSerif(
  double size, {
  Color? color,
  FontWeight? w,
  bool italic = false,
}) => TextStyle(
  fontFamily: IvoryTheme.displayFont,
  fontSize: size,
  color: color ?? IvoryColors.cream,
  fontWeight: w ?? FontWeight.w700,
  fontStyle: italic ? FontStyle.italic : FontStyle.normal,
  height: 1.3,
);

const TextStyle goldKick = TextStyle(
  color: GoldTones.light,
  fontSize: 11,
  fontWeight: FontWeight.w800,
  letterSpacing: 2.4,
);

class GoldenIntro extends StatelessWidget {
  const GoldenIntro({
    super.key,
    required this.s,
    required this.busy,
    required this.onStart,
    required this.onClose,
  });

  final GoldenState s;
  final bool busy;
  final VoidCallback onStart;
  final VoidCallback onClose;

  Widget _rule(int n, IconData icon, String text) => GoldRise(
    delayMs: 380 + n * 140,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                center: Alignment(-0.4, -0.5),
                colors: <Color>[GoldTones.shine, GoldTones.mid, GoldTones.deep],
              ),
              border: Border.all(color: GoldTones.rim),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: IvoryColors.gold.withValues(alpha: 0.45),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(icon, size: 18, color: IvoryColors.burgundy),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                text,
                style: TextStyle(
                  color: IvoryColors.cream.withValues(alpha: 0.94),
                  fontSize: 14.5,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: <Widget>[
        SizedBox(
          height: 190,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              const OverflowBox(
                maxWidth: 340,
                maxHeight: 340,
                child: GoldRays(size: 340, opacity: 0.32),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.2, end: 1),
                duration: const Duration(milliseconds: 1100),
                curve: Curves.easeOutBack,
                builder: (BuildContext context, double v, Widget? c) =>
                    Transform.scale(
                      scale: v,
                      child: Opacity(
                        opacity: v.clamp(0.0, 1.0).toDouble(),
                        child: c,
                      ),
                    ),
                child: const GoldCoin(size: 96),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const GoldRise(
          delayMs: 150,
          child: Center(
            child: Text(
              'EVERY STEP TO CLIMB UP THE MEMBERSHIP LADDER',
              textAlign: TextAlign.center,
              style: goldKick,
            ),
          ),
        ),
        const SizedBox(height: 8),
        GoldRise(
          delayMs: 250,
          child: Center(
            child: GoldShimmerText(
              'THE GOLDEN\nKNOCK-OFF',
              textAlign: TextAlign.center,
              extrude: 5,
              style: goldSerif(
                38,
                w: FontWeight.w900,
              ).copyWith(letterSpacing: 1.4),
            ),
          ),
        ),
        const SizedBox(height: 24),
        GoldTilt(
          radius: 26,
          lean: 0.07,
          sway: 0.5,
          child: GoldenFrame(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 9),
            child: Column(
              children: <Widget>[
                _rule(
                  0,
                  Icons.lock_outline,
                  'Ten questions on one secret topic, chosen for you.',
                ),
                _rule(
                  1,
                  Icons.timer_outlined,
                  '${s.questionSeconds} seconds for each question. The clock is real.',
                ),
                _rule(
                  2,
                  Icons.auto_awesome,
                  'Every right answer turns to gold, up to \u20B9${s.maxPerAnswer} each.'
                  '${s.maxBonus > 0 ? ' A perfect ten adds a bonus of up to \u20B9${s.maxBonus}.' : ''}',
                ),
                _rule(
                  3,
                  Icons.hourglass_bottom,
                  'Spend your gold within ${s.creditHours} hours, on a membership priced above it. You pay the difference.',
                ),
                _rule(
                  4,
                  Icons.exit_to_app,
                  'Leave halfway and this quiz is used up. The next one opens in ${s.cooldownDays} days.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        GoldRise(
          delayMs: 1100,
          child: GoldButton(
            label: s.rehearsal ? 'START THE REHEARSAL' : 'BREAK THE SEAL',
            icon: Icons.auto_awesome,
            busy: busy,
            onTap: onStart,
          ),
        ),
        const SizedBox(height: 10),
        GoldRise(
          delayMs: 1250,
          child: GoldButton(
            label: 'NOT NOW',
            ghost: true,
            onTap: busy ? null : onClose,
          ),
        ),
        if (s.rehearsal)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(
              'Admin rehearsal: nothing is won and nothing is locked.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: IvoryColors.cream.withValues(alpha: 0.75),
                fontSize: 12.5,
              ),
            ),
          ),
      ],
    );
  }
}

// END OF FILE - lib/screens/golden_quiz_parts.dart
