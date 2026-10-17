import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/ivory_errors.dart';
import '../models/quiz_models.dart';
import '../theme/ivory_theme.dart';
import '../widgets/gold_burst.dart';
import '../widgets/gold_button.dart';
import '../widgets/gold_fx.dart';
import '../widgets/gold_fx3d.dart';
import '../widgets/gold_light.dart';
import '../widgets/gold_sound.dart';
import '../widgets/golden_option_key.dart';
import 'golden_verdict.dart';

/// ============================================================
/// IVORY - THE GOLDEN KNOCK-OFF: ONE QUESTION
///
/// The clock is the phone's own, started when the question appears;
/// the database keeps the real one and is the only judge. After an
/// answer the verdict, the fact and the rupees show for a few
/// seconds and the next question follows by itself, so a slow
/// reader can never lose time on the next question.
/// ============================================================

/// One question: the ring, the four doors, the verdict and the fact.
class GoldenQuestionView extends StatefulWidget {
  const GoldenQuestionView({
    super.key,
    required this.q,
    required this.topic,
    required this.totalSeconds,
    required this.submit,
    required this.onAdvance,
    this.streak = 0,
    this.onStreak,
  });

  final GoldenQuestion q;
  final String topic;
  final int totalSeconds;
  final Future<GoldenAnswer> Function(int choice) submit;
  final void Function(GoldenAnswer a) onAdvance;

  /// Right answers in a row so far in this sitting (counted on the phone).
  final int streak;
  final void Function(int streak)? onStreak;

  @override
  State<GoldenQuestionView> createState() => _GoldenQuestionViewState();
}

class _GoldenQuestionViewState extends State<GoldenQuestionView>
    with SingleTickerProviderStateMixin {
  late final DateTime _deadline = DateTime.now().add(
    Duration(seconds: widget.q.secondsLeft),
  );
  late final AnimationController _adv = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4500),
  );
  Timer? _t;
  double _left = 0;
  int _lastSec = 99;
  int _sel = -2;
  bool _busy = false;
  bool _timedOut = false;
  bool _went = false;
  String _problem = '';
  GoldenAnswer? _a;
  late int _vault = widget.q.runningInr;
  late int _streak = widget.streak;
  bool _bump = false;

  @override
  void initState() {
    super.initState();
    _left = widget.q.secondsLeft.toDouble();
    _adv.addStatusListener((AnimationStatus s) {
      if (s == AnimationStatus.completed) _go();
    });
    _t = Timer.periodic(
      const Duration(milliseconds: 100),
      (Timer _) => _tick(),
    );
  }

  @override
  void dispose() {
    _t?.cancel();
    _adv.dispose();
    super.dispose();
  }

  void _tick() {
    if (!mounted || _busy || _a != null || _timedOut) return;
    final double l = _deadline.difference(DateTime.now()).inMilliseconds / 1000;
    final int sec = l.ceil();
    if (sec <= 5 && sec > 0 && sec != _lastSec) {
      HapticFeedback.selectionClick();
      GoldSound.instance.quick('tick');
    }
    _lastSec = sec;
    if (l <= 0) {
      setState(() => _left = 0);
      _timedOut = true;
      _choose(-1);
    } else {
      setState(() => _left = l);
    }
  }

  Future<void> _choose(int i) async {
    if (_busy || _a != null) return;
    setState(() {
      _busy = true;
      _sel = i;
      _problem = '';
    });
    try {
      final GoldenAnswer a = await widget.submit(i);
      if (!mounted) return;
      if (a.correct) HapticFeedback.heavyImpact();
      if (a.finished && a.correctIdx < 0) {
        widget.onAdvance(a);
        return;
      }
      _streak = a.correct ? _streak + 1 : 0;
      widget.onStreak?.call(_streak);
      GoldSound.instance.big(
        a.correct
            ? (a.golden ? 'golden' : 'correct')
            : (i < 0 ? 'timeout' : 'wrong'),
      );
      setState(() {
        _a = a;
        _busy = false;
        _vault = a.runningInr;
        _bump = a.correct;
      });
      if (a.correct) {
        Timer(const Duration(milliseconds: 520), () {
          if (mounted) setState(() => _bump = false);
        });
      }
      _adv.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _problem = houseMessage(e);
        if (i >= 0) _sel = -2;
      });
    }
  }

  void _go() {
    if (_went || _a == null || !mounted) return;
    _went = true;
    widget.onAdvance(_a!);
  }

  Widget _option(int i) {
    final GoldenAnswer? a = _a;
    final bool picked = _sel == i;
    final bool isRight = a != null && a.correctIdx == i;
    final bool isWrong = a != null && picked && !a.correct;
    final AnswerKeyState st = isRight
        ? AnswerKeyState.right
        : isWrong
        ? AnswerKeyState.wrong
        : a != null
        ? AnswerKeyState.dim
        : picked
        ? AnswerKeyState.picked
        : AnswerKeyState.idle;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: GoldRise(
        delayMs: 70 * i,
        child: GoldShake(
          trigger: isWrong ? 1 : 0,
          child: GoldenOptionKey(
            letter: String.fromCharCode(65 + i),
            text: widget.q.options[i],
            state: st,
            onTap: _busy || a != null ? null : () => _choose(i),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final GoldenQuestion q = widget.q;
    final GoldenAnswer? a = _a;
    final double total = widget.totalSeconds <= 0
        ? 30
        : widget.totalSeconds.toDouble();
    return Stack(
      children: <Widget>[
        ListView(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'QUESTION ${q.position} OF ${q.total}',
                        style: const TextStyle(
                          color: GoldTones.light,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      AnimatedScale(
                        scale: _bump ? 1.22 : 1,
                        alignment: Alignment.centerLeft,
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutBack,
                        child: Row(
                          children: <Widget>[
                            const Icon(
                              Icons.savings_outlined,
                              size: 20,
                              color: GoldTones.light,
                            ),
                            const SizedBox(width: 6),
                            CountUpText(
                              _vault,
                              duration: const Duration(milliseconds: 700),
                              style: TextStyle(
                                color: _bump
                                    ? GoldTones.shine
                                    : GoldTones.light,
                                fontFamily: IvoryTheme.displayFont,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                shadows: <Shadow>[
                                  Shadow(
                                    color: IvoryColors.gold.withValues(
                                      alpha: _bump ? 0.9 : 0.4,
                                    ),
                                    blurRadius: _bump ? 16 : 8,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                GoldRing(
                  progress: a != null ? 0 : _left / total,
                  size: 62,
                  warn: _left <= 8,
                  child: Transform.scale(
                    scale: _left <= 5 && a == null
                        ? 1 + 0.3 * (_left - _left.floor())
                        : 1,
                    child: Text(
                      a != null ? '' : '${_left.ceil()}',
                      style: TextStyle(
                        color: _left <= 5
                            ? IvoryColors.peach
                            : IvoryColors.cream,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                for (int i = 1; i <= q.total; i++) ...<Widget>[
                  if (i > 1) const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: i <= q.position
                            ? GoldTones.mid
                            : IvoryColors.gold.withValues(alpha: 0.22),
                        boxShadow: i == q.position
                            ? <BoxShadow>[
                                BoxShadow(
                                  color: GoldTones.shine.withValues(alpha: 0.8),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 18),
            GoldRise(
              child: GoldTilt(
                radius: 22,
                lean: 0.1,
                sway: 0.35,
                child: GoldenFrame(
                  radius: 22,
                  sparkles: false,
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                  child: Text(
                    q.text,
                    style: const TextStyle(
                      color: IvoryColors.cream,
                      fontFamily: IvoryTheme.displayFont,
                      fontSize: 20,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            for (int i = 0; i < q.options.length; i++) _option(i),
            if (_problem.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  _problem,
                  style: const TextStyle(
                    color: IvoryColors.peach,
                    fontSize: 13,
                  ),
                ),
              ),
            if (_timedOut && a == null && !_busy)
              GoldButton(label: 'TRY AGAIN', onTap: () => _choose(-1)),
            if (a != null)
              GoldenVerdict(
                a: a,
                timedOut: _sel == -1,
                advance: _adv,
                streak: _streak,
                onTap: _go,
              ),
          ],
        ),
        if (a != null && a.correct) ...<Widget>[
          Positioned.fill(
            child: GoldShockwave(key: ValueKey<int>(q.questionId)),
          ),
          Positioned.fill(
            child: GoldFlash(
              key: ValueKey<int>(q.questionId),
              strength: a.golden ? 0.55 : 0.3,
            ),
          ),
          Positioned.fill(
            child: CoinBurst(
              key: ValueKey<int>(q.questionId),
              big: a.golden,
              origin: const Alignment(0.6, -0.8),
            ),
          ),
        ],
      ],
    );
  }
}

// END OF FILE - lib/screens/golden_question_view.dart
