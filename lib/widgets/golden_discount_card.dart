import 'dart:async';

import 'package:flutter/material.dart';

import '../screens/golden_quiz_screen.dart';
import '../services/quiz_service.dart';
import '../models/quiz_models.dart';
import '../models/vault_models.dart';
import '../theme/ivory_theme.dart';
import 'gold_burst.dart';
import 'gold_button.dart';
import 'gold_fx.dart';
import 'gold_fx3d.dart';
import 'color_crackers.dart';
import 'gold_plate.dart';
import 'gold_seals.dart';
import 'gold_teaser.dart';
import 'rupee_coin.dart';
import 'sound_bank.dart';

/// ============================================================
/// IVORY - THE GOLDEN KNOCK-OFF, ON THE HOME SCREEN
///
/// One card, eight faces. The database says which face a member
/// sees (ready, playing, gold, cooling, dust, paid, closed); this
/// widget only paints it, and keeps the countdown honest with the
/// house clock. Nothing on it is invented: every number is read.
/// ============================================================
class GoldenDiscountCard extends StatefulWidget {
  const GoldenDiscountCard({super.key, this.onOpenTab});

  /// Opens a bottom tab by key (the Home screen passes its own).
  final void Function(String tab)? onOpenTab;

  @override
  State<GoldenDiscountCard> createState() => _GoldenDiscountCardState();
}

class _GoldenDiscountCardState extends State<GoldenDiscountCard>
    with WidgetsBindingObserver {
  GoldenState? _s;
  bool _failed = false;
  bool _reloading = false;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _tick = Timer.periodic(const Duration(seconds: 1), (Timer _) => _onTick());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tick?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    if (_reloading) return;
    _reloading = true;
    try {
      final GoldenState s = await QuizService.instance.homeState();
      if (!mounted) return;
      setState(() {
        _s = s;
        _failed = false;
      });
    } catch (_) {
      if (mounted && _s == null) setState(() => _failed = true);
    } finally {
      _reloading = false;
    }
  }

  void _onTick() {
    final GoldenState? s = _s;
    if (!mounted || s == null) return;
    final bool gold = s.phase == GoldenPhase.gold && !s.reserved;
    final bool wait =
        s.phase == GoldenPhase.cooling || s.phase == GoldenPhase.dust;
    if (gold && s.untilExpiry <= Duration.zero) {
      _load();
    } else if (wait && s.untilOpen <= Duration.zero) {
      _load();
    }
    if (gold || wait) setState(() {});
  }

  Future<void> _open() async {
    // Your own Golden Knock-off recording (silent if it is missing).
    SoundBank.instance.play('kickoff');
    final String? r = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (BuildContext _) =>
            GoldenQuizScreen(resume: _s?.phase == GoldenPhase.playing),
      ),
    );
    SoundBank.instance.stop('kickoff');
    await _load();
    if (r == 'spend') widget.onOpenTab?.call('premium');
  }

  void _spend() => widget.onOpenTab?.call('premium');

  static const TextStyle _kicker = TextStyle(
    color: IvoryColors.burgundy,
    fontSize: 10.5,
    fontWeight: FontWeight.w800,
    letterSpacing: 2.2,
  );

  static TextStyle _lead() => const TextStyle(
    color: IvoryColors.burgundy,
    fontFamily: IvoryTheme.displayFont,
    fontSize: 17,
    height: 1.32,
    fontStyle: FontStyle.italic,
  );

  static TextStyle _fine() => TextStyle(
    color: IvoryColors.burgundy.withValues(alpha: 0.9),
    fontSize: 12.5,
    height: 1.4,
  );

  Widget _head(bool calm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'EVERY STEP TO CLIMB UP THE MEMBERSHIP LADDER',
          style: _kicker.copyWith(letterSpacing: 1.5),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: const Text(
                  'THE GOLDEN\nKNOCK-OFF',
                  style: TextStyle(
                    color: IvoryColors.burgundy,
                    fontFamily: IvoryTheme.displayFont,
                    fontSize: 31,
                    height: 1.04,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    shadows: <Shadow>[
                      Shadow(color: Color(0xFFFFF3B8), offset: Offset(0, 1)),
                      Shadow(color: Color(0xFF8A5A00), offset: Offset(0, -1)),
                      Shadow(
                        color: Color(0x66784600),
                        offset: Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            calm
                ? const Opacity(
                    opacity: 0.7,
                    child: GoldWell(circle: true, child: RupeeCoin(size: 44)),
                  )
                : const GoldWell(
                    circle: true,
                    padding: EdgeInsets.all(5),
                    child: RupeeCoin(size: 64),
                  ),
          ],
        ),
      ],
    );
  }

  Widget _ready(GoldenState s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: IvoryColors.burgundy,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            GoldBeat(
              child: Text(
                s.rehearsal ? 'ADMIN REHEARSAL' : 'OPEN FOR YOU NOW',
                style: _kicker.copyWith(
                  fontSize: 12.5,
                  letterSpacing: 2.4,
                  color: IvoryColors.burgundy,
                  shadows: const <Shadow>[
                    Shadow(color: Color(0xFFFFF3B8), offset: Offset(0, 1)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 46),
          child: GoldTeaser(
            style: _lead(),
            lines: <String>[
              'Ten questions. Every right answer turns to gold.',
              '${s.sealTotal} topics. ${s.sealTotal} seals. Which one is yours?',
            ],
          ),
        ),
        const SizedBox(height: 14),
        GoldWell(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: GoldSealRow(earned: s.seals, total: s.sealTotal),
        ),
        const SizedBox(height: 8),
        Text(
          s.seals == 0
              ? 'Ten topics, ten seals. Your first is waiting.'
              : '${s.seals} of ${s.sealTotal} seals won.',
          style: _fine(),
        ),
        const SizedBox(height: 12),
        Text(
          'Up to \u20B9${s.maxPerAnswer} off for every correct answer.'
          '${s.maxBonus > 0 ? ' A perfect 10 out of 10 adds an additional bonus of up to \u20B9${s.maxBonus}.' : ''}',
          style: _fine(),
        ),
        const SizedBox(height: 4),
        Text(
          'Get ${s.creditHours} hours of buffer time to spend your gold. '
          'You get one chance in every ${s.cooldownDays} days. '
          "So let's bring out the champion within.",
          style: _fine(),
        ),
        const SizedBox(height: 16),
        GoldWell(
          radius: 34,
          child: GoldButton(
            label: s.rehearsal ? 'REHEARSE THE QUIZ' : 'UNSEAL MY TOPIC',
            icon: Icons.auto_awesome,
            onTap: _open,
          ),
        ),
        if (s.rehearsal)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Admin rehearsal: nothing is won and nothing is locked.',
              style: _fine(),
            ),
          ),
      ],
    );
  }

  Widget _playing(GoldenState s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Your quiz is open and the clock is running.', style: _lead()),
        const SizedBox(height: 10),
        Text(
          'Question ${s.position} of ${s.total}. '
          'Your vault holds \u20B9${s.runningInr} so far.',
          style: _fine(),
        ),
        const SizedBox(height: 16),
        GoldWell(
          radius: 34,
          child: GoldButton(
            label: 'BACK TO MY QUESTION',
            icon: Icons.play_arrow_rounded,
            onTap: _open,
          ),
        ),
      ],
    );
  }

  Widget _gold(GoldenState s) {
    if (s.reserved) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CountUpText(
            s.creditInr,
            style: const TextStyle(
              color: IvoryColors.burgundy,
              fontFamily: IvoryTheme.displayFont,
              fontSize: 38,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your payment is being checked. Your gold is held for you '
            'until the house decides.',
            style: _lead(),
          ),
        ],
      );
    }
    final Duration left = s.untilExpiry;
    final double p = s.creditHours <= 0
        ? 0
        : left.inSeconds / (s.creditHours * 3600);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            GoldWell(
              circle: true,
              padding: const EdgeInsets.all(5),
              child: GoldRing(
              progress: p,
              size: 92,
              warn: left < const Duration(hours: 1),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: FittedBox(
                  child: Text(
                    goldCountdown(left),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: IvoryColors.cream,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  CountUpText(
                    s.creditInr,
                    style: const TextStyle(
                      color: IvoryColors.burgundy,
                      fontFamily: IvoryTheme.displayFont,
                      fontSize: 40,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('of gold is yours to spend.', style: _lead()),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'It turns to dust in ${goldCountdown(left, seconds: true)}. '
          'It works on any membership priced above it, and you pay only '
          'the difference.',
          style: _fine(),
        ),
        const SizedBox(height: 14),
        GoldWell(
          radius: 34,
          child: GoldButton(
            label: 'SPEND MY GOLD',
            icon: Icons.workspace_premium,
            onTap: _spend,
          ),
        ),
      ],
    );
  }

  Widget _waiting(GoldenState s) {
    final bool dust = s.phase == GoldenPhase.dust;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          dust
              ? 'Your gold turned to dust before it was spent.'
              : 'Your last quiz won \u20B9${s.lastInr}.',
          style: _lead(),
        ),
        const SizedBox(height: 12),
        Text('NEXT GOLDEN KNOCK-OFF OPENS IN', style: _kicker),
        const SizedBox(height: 4),
        Text(
          goldCountdown(s.untilOpen),
          style: const TextStyle(
            color: IvoryColors.burgundy,
            fontFamily: IvoryTheme.displayFont,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        GoldWell(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: GoldSealRow(earned: s.seals, total: s.sealTotal),
        ),
        const SizedBox(height: 8),
        Text(
          dust
              ? 'Next time, spend it within ${s.creditHours} hours. '
                    'We will tell you the moment it opens.'
              : 'Your next topic is a secret. We will tell you the moment '
                    'it opens.',
          style: _fine(),
        ),
      ],
    );
  }

  Widget _quiet(String line) => Padding(
    padding: const EdgeInsets.only(top: 2),
    child: Text(line, style: _fine().copyWith(fontSize: 14)),
  );

  @override
  Widget build(BuildContext context) {
    final GoldenState? s = _s;
    if (s != null && s.phase == GoldenPhase.signedOut) {
      return const SizedBox.shrink();
    }
    final bool calm =
        s == null ||
        s.phase == GoldenPhase.closed ||
        s.phase == GoldenPhase.paid;
    Widget body;
    if (s == null) {
      body = _failed
          ? GestureDetector(
              onTap: () {
                setState(() => _failed = false);
                _load();
              },
              child: _quiet('Tap to open The Golden Knock-off.'),
            )
          : const Padding(
              padding: EdgeInsets.only(top: 6),
              child: SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: IvoryColors.burgundy,
                ),
              ),
            );
    } else {
      body = switch (s.phase) {
        GoldenPhase.ready => _ready(s),
        GoldenPhase.playing => _playing(s),
        GoldenPhase.gold => _gold(s),
        GoldenPhase.cooling || GoldenPhase.dust => _waiting(s),
        GoldenPhase.paid => _quiet(
          s.unlockAt == null
              ? 'Your membership has no end date, so the Golden Knock-off '
                    'stays closed for you.'
              : 'Your membership is running. The Golden Knock-off opens '
                    'again when it has ${s.renewDays} days left, on '
                    '${vaultDate(s.unlockAt!)}.',
        ),
        GoldenPhase.closed => _quiet(
          'The Golden Knock-off is resting. Please come back soon.',
        ),
        GoldenPhase.signedOut => const SizedBox.shrink(),
      };
    }
    return SizedBox(
      width: double.infinity,
      child: GoldTilt(
        lean: calm ? 0.05 : 0.1,
        sway: calm ? 0.3 : 1,
        child: GoldPlate(
          calm: calm,
          child: Stack(
            children: <Widget>[
              // The old firecrackers, back again: in colour, so they show
              // on the gold.
              if (!calm) const Positioned.fill(child: ColorCrackers()),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _head(calm),
                  const SizedBox(height: 14),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: SizedBox(width: double.infinity, child: body),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// END OF FILE - lib/widgets/golden_discount_card.dart
