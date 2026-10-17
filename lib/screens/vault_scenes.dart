import 'dart:async';

import 'package:flutter/material.dart';

import '../models/vault_models.dart';
import '../theme/ivory_theme.dart';
import '../widgets/gold_burst.dart';
import '../widgets/gold_button.dart';
import '../widgets/gold_fx.dart';
import '../widgets/gold_fx3d.dart';
import '../widgets/gold_light.dart';
import '../widgets/gold_sound.dart';
import '../widgets/vault_keys.dart';
import 'golden_quiz_parts.dart';

/// ============================================================
/// IVORY - THE TEN-DAY VAULT: THE ROOMS AROUND THE QUESTION
///
/// The rules before day one, the title that rises before each
/// day's key, and the quiet scene after a key is turned: the big
/// key sliding home, the keys already turned, and the clock to
/// tomorrow. The question is in vault_question_view.dart and the
/// opening of the vault in vault_ceremony.dart.
/// ============================================================

/// The rules, said plainly, before the first key.
class VaultIntro extends StatelessWidget {
  const VaultIntro({
    super.key,
    required this.s,
    required this.busy,
    required this.onStart,
    required this.onClose,
  });

  final VaultState s;
  final bool busy;
  final VoidCallback onStart;
  final VoidCallback onClose;

  Widget _rule(int n, IconData icon, String text) => GoldRise(
    delayMs: 380 + n * 130,
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
          height: 180,
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
                child: const VaultEmblem(size: 96),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        GoldRise(
          delayMs: 150,
          child: Center(
            child: Text(
              'ONE KEY A DAY FOR ${vaultWord(s.days)} DAYS',
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
              'THE ${vaultWord(s.days)}-DAY\nVAULT',
              textAlign: TextAlign.center,
              extrude: 5,
              style: goldSerif(
                38,
                w: FontWeight.w900,
              ).copyWith(letterSpacing: 1.4),
            ),
          ),
        ),
        const SizedBox(height: 22),
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
                  Icons.vpn_key_rounded,
                  'One question a day for ${s.days} days. Each day turns over '
                  'at ${vaultHour(s.dayStartHour)}.',
                ),
                _rule(
                  1,
                  Icons.lock_outline,
                  'Every answer is sealed the moment you give it. Right or '
                  'wrong, you learn nothing until the last key turns.',
                ),
                _rule(
                  2,
                  Icons.trending_up_rounded,
                  'The questions grow harder with every day. Day 1 is gentle.',
                ),
                _rule(
                  3,
                  Icons.timer_outlined,
                  '${s.questionSeconds} seconds for each question. The clock '
                  'is real, and it starts the moment the question appears.',
                ),
                _rule(
                  4,
                  Icons.auto_awesome,
                  'Every right answer turns to gold, up to \u20B9${s.maxPerAnswer} each.'
                  '${s.maxBonus > 0 ? ' A perfect ${s.days} adds a bonus of up to \u20B9${s.maxBonus}.' : ''}',
                ),
                _rule(
                  5,
                  Icons.event_busy_rounded,
                  'Miss a day and the vault starts over from Day 1. Taking a '
                  'membership while a vault is running ends it too.',
                ),
                _rule(
                  6,
                  Icons.hourglass_bottom,
                  'On Day ${s.days} the vault opens. Spend your gold within '
                  '${s.creditHours} hours, on a membership priced above it.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        GoldRise(
          delayMs: 1250,
          child: GoldButton(
            label: s.rehearsal ? 'START THE REHEARSAL' : 'BEGIN DAY 1 NOW',
            icon: Icons.vpn_key_rounded,
            busy: busy,
            onTap: onStart,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'The Day 1 question appears right after the title, and its '
            '${s.questionSeconds}-second clock starts with it.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: IvoryColors.cream.withValues(alpha: 0.75),
              fontSize: 12.5,
            ),
          ),
        ),
        const SizedBox(height: 10),
        GoldRise(
          delayMs: 1400,
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

/// "DAY 4" rising in cast gold, for about two seconds, before the key
/// is opened. The question's clock has not started yet.
class VaultDayTitle extends StatefulWidget {
  const VaultDayTitle({
    super.key,
    required this.day,
    required this.days,
    required this.onDone,
  });

  final int day;
  final int days;
  final VoidCallback onDone;

  @override
  State<VaultDayTitle> createState() => _VaultDayTitleState();
}

class _VaultDayTitleState extends State<VaultDayTitle> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    GoldSound.instance.quick('seal${(widget.day - 1).clamp(0, 9)}');
    _t = Timer(const Duration(milliseconds: 2100), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool last = widget.day >= widget.days;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            height: 260,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                const OverflowBox(
                  maxWidth: 360,
                  maxHeight: 360,
                  child: GoldRays(size: 360, opacity: 0.3),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 2.4, end: 1),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutBack,
                  builder: (BuildContext context, double v, Widget? c) =>
                      Transform.scale(scale: v, child: c),
                  child: GoldShimmerText(
                    'DAY ${widget.day}',
                    extrude: 7,
                    style: goldSerif(
                      64,
                      w: FontWeight.w900,
                    ).copyWith(letterSpacing: 2),
                  ),
                ),
              ],
            ),
          ),
          GoldRise(
            delayMs: 500,
            child: Text(
              last ? 'THE LAST KEY' : 'OF ${vaultWord(widget.days)}',
              style: goldKick.copyWith(fontSize: 13),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: GoldRise(
              delayMs: 800,
              child: Text(
                last
                    ? 'The hardest question of all. After this, the vault opens.'
                    : widget.day == 1
                    ? 'The gentlest key of all. Take a breath.'
                    : 'Today\u2019s key is a little harder than yesterday\u2019s.',
                textAlign: TextAlign.center,
                style: goldSerif(15.5, italic: true),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// After a key is turned: the big key slides home, the clock to tomorrow.
class VaultSealedScene extends StatefulWidget {
  const VaultSealedScene({
    super.key,
    required this.s,
    required this.animate,
    required this.onClose,
  });

  final VaultState s;

  /// True right after an answer, false for a member who comes back.
  final bool animate;
  final VoidCallback onClose;

  @override
  State<VaultSealedScene> createState() => _VaultSealedSceneState();
}

class _VaultSealedSceneState extends State<VaultSealedScene> {
  Timer? _t;
  bool _boom = false;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (Timer _) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  void _turned() {
    GoldSound.instance.big('reveal');
    if (mounted) setState(() => _boom = true);
  }

  @override
  Widget build(BuildContext context) {
    final VaultState s = widget.s;
    final int done = s.answered;
    final Duration left = s.untilNextDay;
    return Stack(
      children: <Widget>[
        ListView(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 30),
          children: <Widget>[
            Center(
              child: VaultBigKey(animate: widget.animate, onTurned: _turned),
            ),
            const SizedBox(height: 8),
            GoldRise(
              delayMs: widget.animate ? 1800 : 100,
              child: Center(
                child: GoldShimmerText(
                  'DAY $done SEALED',
                  extrude: 4,
                  style: goldSerif(
                    32,
                    w: FontWeight.w900,
                  ).copyWith(letterSpacing: 1.6),
                ),
              ),
            ),
            const SizedBox(height: 10),
            GoldRise(
              delayMs: widget.animate ? 2000 : 200,
              child: Text(
                'Your answer is locked in the vault. Right or wrong, nothing '
                'is revealed until Day ${s.days}.',
                textAlign: TextAlign.center,
                style: goldSerif(15.5, italic: true),
              ),
            ),
            const SizedBox(height: 22),
            GoldRise(
              delayMs: widget.animate ? 2200 : 300,
              child: GoldenFrame(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                child: Column(
                  children: <Widget>[
                    VaultKeyRow(total: s.days, turned: done),
                    const SizedBox(height: 16),
                    Text('DAY ${done + 1} OPENS IN', style: goldKick),
                    const SizedBox(height: 4),
                    Text(
                      goldCountdown(left, seconds: true),
                      style: goldSerif(
                        30,
                        color: GoldTones.light,
                        w: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Each day turns over at ${vaultHour(s.dayStartHour)}. '
                      'We will remind you. Miss a day and the vault starts '
                      'over from Day 1.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: IvoryColors.cream.withValues(alpha: 0.8),
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            GoldRise(
              delayMs: widget.animate ? 2500 : 400,
              child: GoldButton(label: 'DONE', onTap: widget.onClose),
            ),
          ],
        ),
        if (_boom) ...<Widget>[
          const Positioned.fill(
            child: GoldShockwave(origin: Alignment(0, -0.55)),
          ),
          const Positioned.fill(child: GoldFlash(strength: 0.35)),
          const Positioned.fill(child: CoinBurst(origin: Alignment(0, -0.55))),
        ],
      ],
    );
  }
}

// END OF FILE - lib/screens/vault_scenes.dart
