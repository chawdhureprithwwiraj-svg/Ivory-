import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/quiz_models.dart';
import '../theme/ivory_theme.dart';
import '../widgets/gold_burst.dart';
import '../widgets/gold_button.dart';
import '../widgets/gold_fireworks.dart';
import '../widgets/gold_fx.dart';
import '../widgets/gold_fx3d.dart';
import '../widgets/gold_light.dart';
import '../widgets/gold_sound.dart';
import 'golden_quiz_parts.dart';

/// ============================================================
/// IVORY - THE RESULT
///
/// The finale. A score cast in gold, the member's rank, the vault
/// counting up, and what it can buy. From seven right answers a
/// glitter rain falls; a perfect ten adds a ring of light and a
/// flash. A fanfare plays, grander the better the score.
/// ============================================================
class GoldenResult extends StatefulWidget {
  const GoldenResult({
    super.key,
    required this.summary,
    required this.creditHours,
    required this.onSpend,
    required this.onClose,
    this.shareName = 'The Golden Knock-off',
    this.waitLine =
        'No gold this time. Your next quiz opens when the wait is over, and we will tell you.',
    this.extra,
  });

  /// What a shared score calls the game.
  final String shareName;

  /// Said when no gold was won.
  final String waitLine;

  /// An optional widget above the DONE button (the vault adds its review).
  final Widget? extra;

  final GoldenSummary summary;
  final int creditHours;
  final VoidCallback onSpend;
  final VoidCallback onClose;

  @override
  State<GoldenResult> createState() => _GoldenResultState();
}

class _GoldenResultState extends State<GoldenResult> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    final GoldenSummary s = widget.summary;
    GoldSound.instance.big(
      s.perfect ? 'perfect' : (s.totalInr > 0 && !s.rehearsal ? 'win' : 'lose'),
    );
    _t = Timer.periodic(const Duration(seconds: 1), (Timer _) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  String get _line {
    switch (widget.summary.rank) {
      case 'IVORY SAGE':
        return 'A perfect ten. Not one story slipped past you.';
      case 'STORYTELLER':
        return 'You know our stories well.';
      case 'KEEPER':
        return 'You keep the stories safe.';
      default:
        return 'Curiosity is where every story begins.';
    }
  }

  void _share() {
    final GoldenSummary s = widget.summary;
    Share.share(
      'I scored ${s.score}/${s.questions} on ${widget.shareName} in Ivory'
      '${s.totalInr > 0 ? ' and earned \u20B9${s.totalInr} off a membership' : ''}. '
      'Where every story leaves a mark.',
    );
  }

  Widget _row(String label, int v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: <Widget>[
        Expanded(child: Text(label, style: goldSerif(14.5))),
        Text(
          '\u20B9$v',
          style: goldSerif(16, color: GoldTones.light, w: FontWeight.w900),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final GoldenSummary s = widget.summary;
    final Duration left = s.untilExpiry;
    final bool won = s.totalInr > 0 && !s.rehearsal;
    return Stack(
      children: <Widget>[
        if (s.score >= 7)
          Positioned.fill(
            child: GoldFireworks(
              rate: s.perfect ? 2.2 : 1.2,
              strength: s.perfect ? 1 : 0.85,
              seed: 17,
            ),
          ),
        if (s.score >= 7) const Positioned.fill(child: GlitterRain(count: 46)),
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          children: <Widget>[
            const GoldRise(
              child: Center(child: Text('YOUR SCORE', style: goldKick)),
            ),
            SizedBox(
              height: 130,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  const OverflowBox(
                    maxWidth: 320,
                    maxHeight: 320,
                    child: GoldRays(size: 320, opacity: 0.3),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 2.2, end: 1),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutBack,
                    builder: (BuildContext context, double v, Widget? c) =>
                        Transform.scale(scale: v, child: c),
                    child: GoldShimmerText(
                      '${s.score}/${s.questions}',
                      extrude: 6,
                      style: goldSerif(72, w: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ),
            GoldRise(
              delayMs: 350,
              child: Center(
                child: GoldShimmerText(
                  s.rank,
                  extrude: 3,
                  style: goldSerif(
                    22,
                    w: FontWeight.w900,
                  ).copyWith(letterSpacing: 3),
                ),
              ),
            ),
            const SizedBox(height: 8),
            GoldRise(
              delayMs: 500,
              child: Center(
                child: Text(
                  _line,
                  textAlign: TextAlign.center,
                  style: goldSerif(15.5, italic: true),
                ),
              ),
            ),
            const SizedBox(height: 22),
            GoldRise(
              delayMs: 650,
              child: GoldTilt(
                lean: 0.09,
                sway: 0.6,
                child: GoldenFrame(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                  child: Column(
                    children: <Widget>[
                      const Text('YOUR VAULT', style: goldKick),
                      const SizedBox(height: 6),
                      CountUpText(
                        s.totalInr,
                        duration: const Duration(milliseconds: 1900),
                        style:
                            goldSerif(
                              54,
                              color: GoldTones.light,
                              w: FontWeight.w900,
                            ).copyWith(
                              shadows: <Shadow>[
                                Shadow(
                                  color: IvoryColors.gold.withValues(
                                    alpha: 0.7,
                                  ),
                                  blurRadius: 18,
                                ),
                              ],
                            ),
                      ),
                      const SizedBox(height: 8),
                      _row('Right answers', s.answersInr),
                      if (s.bonusInr > 0) _row('Perfect-ten bonus', s.bonusInr),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (s.rehearsal)
              Text(
                'Admin rehearsal: nothing was credited and nothing is locked.',
                textAlign: TextAlign.center,
                style: goldSerif(14, italic: true),
              )
            else if (won) ...<Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  GoldRing(
                    progress:
                        left.inSeconds / math.max(1, widget.creditHours * 3600),
                    size: 62,
                    warn: left < const Duration(hours: 1),
                  ),
                  const SizedBox(width: 14),
                  Flexible(
                    child: Text(
                      'Turns to dust in ${goldCountdown(left, seconds: true)}.\n'
                      'Spend it on any membership priced above it.',
                      style: goldSerif(14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GoldRise(
                delayMs: 900,
                child: GoldButton(
                  label: 'SPEND MY GOLD',
                  icon: Icons.workspace_premium,
                  onTap: widget.onSpend,
                ),
              ),
            ] else
              Text(
                widget.waitLine,
                textAlign: TextAlign.center,
                style: goldSerif(14, italic: true),
              ),
            if (widget.extra != null) ...<Widget>[
              const SizedBox(height: 12),
              widget.extra!,
            ],
            const SizedBox(height: 12),
            GoldButton(
              label: 'SHARE MY SCORE',
              icon: Icons.ios_share,
              ghost: true,
              onTap: _share,
            ),
            const SizedBox(height: 10),
            GoldButton(label: 'DONE', ghost: true, onTap: widget.onClose),
          ],
        ),
        if (s.perfect) ...<Widget>[
          const Positioned.fill(
            child: GoldShockwave(origin: Alignment(0, -0.5)),
          ),
          const Positioned.fill(child: GoldFlash(strength: 0.6)),
        ],
        Positioned.fill(
          child: CoinBurst(big: s.perfect, origin: const Alignment(0, -0.6)),
        ),
      ],
    );
  }
}

// END OF FILE - lib/screens/golden_result.dart
