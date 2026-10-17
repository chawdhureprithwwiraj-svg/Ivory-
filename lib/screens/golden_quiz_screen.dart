import 'dart:async';

import 'package:flutter/material.dart';

import '../core/ivory_errors.dart';
import '../models/quiz_models.dart';
import '../services/quiz_service.dart';
import '../theme/ivory_theme.dart';
import '../widgets/gold_burst.dart';
import '../widgets/gold_button.dart';
import '../widgets/gold_fx.dart';
import '../widgets/gold_fireworks.dart';
import '../widgets/gold_fx3d.dart';
import '../widgets/gold_sound.dart';
import 'golden_question_view.dart';
import 'golden_quiz_parts.dart';
import 'golden_result.dart';
import 'golden_reveal.dart';

/// ============================================================
/// IVORY - THE GOLDEN KNOCK-OFF: THE QUIZ ITSELF
///
/// Rules (the database enforces all of them; this screen only
/// shows them):  one secret topic, ten questions, a real clock,
/// every right answer turns to gold. The correct answer is never
/// on the phone until the member has answered.
///
/// Flow: intro -> unsealing -> ten questions -> result.
/// Pops with 'spend' when the member taps SPEND MY GOLD.
/// ============================================================

enum _Stage { loading, intro, starting, reveal, question, result, error }

class GoldenQuizScreen extends StatefulWidget {
  const GoldenQuizScreen({super.key, this.resume = false});

  /// True when the Home card says a quiz is already open.
  final bool resume;

  @override
  State<GoldenQuizScreen> createState() => _GoldenQuizScreenState();
}

class _GoldenQuizScreenState extends State<GoldenQuizScreen> {
  final QuizService _svc = QuizService.instance;
  _Stage _stage = _Stage.loading;
  GoldenState? _gs;
  GoldenQuestion? _q;
  GoldenSummary? _sum;
  String _topic = '';
  String _tagline = '';
  String _err = '';
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    GoldSound.instance.load();
    _boot();
  }

  @override
  void dispose() {
    GoldSound.instance.release();
    super.dispose();
  }

  void _fail(Object e) {
    if (!mounted) return;
    setState(() {
      _err = houseMessage(e);
      _stage = _Stage.error;
    });
  }

  Future<void> _boot() async {
    try {
      final GoldenState gs = await _svc.homeState();
      if (!mounted) return;
      _gs = gs;
      if (gs.phase == GoldenPhase.playing || widget.resume) {
        final GoldenStart? r = await _svc.resume();
        if (!mounted) return;
        if (r != null) {
          setState(() {
            _topic = r.topicTitle;
            _q = r.first;
            _stage = _Stage.question;
          });
          return;
        }
      }
      if (gs.phase == GoldenPhase.ready) {
        setState(() => _stage = _Stage.intro);
      } else {
        setState(() {
          _err =
              'The Golden Knock-off is not open for you right now. '
              'The Home card will tell you when it is.';
          _stage = _Stage.error;
        });
      }
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> _begin() async {
    setState(() => _stage = _Stage.starting);
    try {
      final GoldenStart r = await _svc.start();
      if (!mounted) return;
      setState(() {
        _topic = r.topicTitle;
        _tagline = r.tagline;
        _q = r.first;
        _stage = r.resumed ? _Stage.question : _Stage.reveal;
      });
    } catch (e) {
      _fail(e);
    }
  }

  Future<GoldenAnswer> _submit(int choice) {
    final GoldenQuestion q = _q!;
    return _svc.answer(
      attemptId: q.attemptId,
      questionId: q.questionId,
      choice: choice,
    );
  }

  void _advance(GoldenAnswer a) {
    if (!mounted) return;
    if (a.finished && a.summary != null) {
      setState(() {
        _sum = a.summary;
        _stage = _Stage.result;
      });
    } else if (a.next != null) {
      setState(() => _q = a.next);
    } else {
      _fail('no next question');
    }
  }

  bool get _locked =>
      _stage == _Stage.starting ||
      _stage == _Stage.reveal ||
      _stage == _Stage.question;

  Future<void> _confirmLeave() async {
    final bool rehearsal = _gs?.rehearsal ?? false;
    final bool? leave = await showDialog<bool>(
      context: context,
      builder: (BuildContext c) => AlertDialog(
        title: const Text('Leave The Golden Knock-off?'),
        content: Text(
          rehearsal
              ? 'This is an admin rehearsal. Leaving costs nothing.'
              : 'This quiz will be used up, and the next one opens in '
                    '${_gs?.cooldownDays ?? 20} days. Gold you have already won '
                    'is kept, but its ${_gs?.creditHours ?? 6} hours keep '
                    'running.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('STAY'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('LEAVE'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.of(context).pop();
  }

  Widget _body() {
    switch (_stage) {
      case _Stage.loading:
        return const Center(
          child: CircularProgressIndicator(color: GoldTones.mid),
        );
      case _Stage.intro:
      case _Stage.starting:
        return GoldenIntro(
          s: _gs!,
          busy: _stage == _Stage.starting,
          onStart: _begin,
          onClose: () => Navigator.of(context).pop(),
        );
      case _Stage.reveal:
        return GoldenReveal(
          topic: _topic,
          tagline: _tagline,
          onDone: () {
            if (mounted) setState(() => _stage = _Stage.question);
          },
        );
      case _Stage.question:
        final GoldenQuestion q = _q!;
        return GoldenQuestionView(
          key: ValueKey<int>(q.questionId),
          q: q,
          topic: _topic,
          totalSeconds: _gs?.questionSeconds ?? 30,
          submit: _submit,
          onAdvance: _advance,
          streak: _streak,
          onStreak: (int n) => _streak = n,
        );
      case _Stage.result:
        return GoldenResult(
          summary: _sum!,
          creditHours: _gs?.creditHours ?? 6,
          onSpend: () => Navigator.of(context).pop('spend'),
          onClose: () => Navigator.of(context).pop(),
        );
      case _Stage.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const GoldCoin(size: 64),
                const SizedBox(height: 18),
                Text(
                  _err,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: IvoryColors.cream.withValues(alpha: 0.92),
                    fontFamily: IvoryTheme.displayFont,
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 22),
                GoldButton(
                  label: 'BACK TO HOME',
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_locked,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        backgroundColor: IvoryColors.burgundy,
        body: Container(
          decoration: const BoxDecoration(gradient: IvoryColors.deepGradient),
          child: Stack(
            children: <Widget>[
              const Positioned.fill(
                child: GoldFireworks(rate: 0.5, strength: 0.5, seed: 11),
              ),
              const Positioned(
                top: -120,
                left: -90,
                right: -90,
                child: GoldRays(size: 560, opacity: 0.1),
              ),
              SafeArea(
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        IconButton(
                          icon: const Icon(Icons.close, color: GoldTones.light),
                          onPressed: _locked
                              ? _confirmLeave
                              : () => Navigator.of(context).pop(),
                        ),
                        const Spacer(),
                        ValueListenableBuilder<bool>(
                          valueListenable: GoldSound.instance.on,
                          builder: (BuildContext context, bool on, Widget? _) =>
                              IconButton(
                                tooltip: on ? 'Sound on' : 'Sound off',
                                icon: Icon(
                                  on
                                      ? Icons.volume_up_rounded
                                      : Icons.volume_off_rounded,
                                  color: GoldTones.light,
                                ),
                                onPressed: () => GoldSound.instance.setOn(!on),
                              ),
                        ),
                      ],
                    ),
                    Expanded(child: _body()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// END OF FILE - lib/screens/golden_quiz_screen.dart
