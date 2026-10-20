import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/ivory_errors.dart';
import '../models/vault_models.dart';
import '../theme/ivory_theme.dart';
import '../widgets/gold_burst.dart';
import '../widgets/gold_button.dart';
import '../widgets/gold_fx.dart';
import '../widgets/gold_fx3d.dart';
import '../widgets/gold_sound.dart';
import '../widgets/golden_option_key.dart';
import '../widgets/vault_keys.dart';
import '../widgets/vault_sky.dart';

/// ============================================================
/// IVORY - THE TEN-DAY VAULT: ONE SEALED QUESTION
///
/// The clock is the phone's own, started when the question
/// appears; the database keeps the real one and is the only
/// judge. After a choice there is no verdict: the key simply
/// turns, because the database sends no answer, no score and no
/// rupees until the last key. The member's choice is final.
/// ============================================================
class VaultQuestionView extends StatefulWidget {
  const VaultQuestionView({
    super.key,
    required this.q,
    required this.totalSeconds,
    required this.submit,
    required this.onSealed,
  });

  final VaultQuestion q;
  final int totalSeconds;
  final Future<VaultSealed> Function(int choice) submit;
  final void Function(VaultSealed s) onSealed;

  @override
  State<VaultQuestionView> createState() => _VaultQuestionViewState();
}

class _VaultQuestionViewState extends State<VaultQuestionView> {
  late final DateTime _deadline = DateTime.now().add(
    Duration(seconds: widget.q.secondsLeft),
  );
  Timer? _t;
  double _left = 0;
  int _lastSec = 99;
  int _sel = -2;
  bool _busy = false;
  bool _timedOut = false;
  bool _done = false;
  String _problem = '';

  @override
  void initState() {
    super.initState();
    _left = widget.q.secondsLeft.toDouble();
    _t = Timer.periodic(
      const Duration(milliseconds: 100),
      (Timer _) => _tick(),
    );
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  void _tick() {
    if (!mounted || _busy || _done || _timedOut) return;
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
    if (_busy || _done) return;
    setState(() {
      _busy = true;
      _sel = i;
      _problem = '';
    });
    try {
      final VaultSealed r = await widget.submit(i);
      if (!mounted) return;
      _done = true;
      HapticFeedback.heavyImpact();
      widget.onSealed(r);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _problem = houseMessage(e);
        if (i >= 0) _sel = -2;
      });
    }
  }

  Widget _option(int i) {
    final bool picked = _sel == i;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: GoldRise(
        delayMs: 70 * i,
        child: GoldenOptionKey(
          letter: String.fromCharCode(65 + i),
          text: widget.q.options[i],
          state: picked
              ? AnswerKeyState.picked
              : (_busy ? AnswerKeyState.dim : AnswerKeyState.idle),
          onTap: _busy || _done ? null : () => _choose(i),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final VaultQuestion q = widget.q;
    final double total = widget.totalSeconds <= 0
        ? 30
        : widget.totalSeconds.toDouble();
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'DAY ${q.dayNo} OF ${q.days}',
                    style: const TextStyle(
                      color: vaultInk,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  VaultKeyRow(
                    total: q.days,
                    turned: q.dayNo - 1,
                    today: true,
                    maxSize: 22,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            VaultWell(
              circle: true,
              padding: const EdgeInsets.all(5),
              child: GoldRing(
              progress: _busy ? 0 : _left / total,
              size: 62,
              warn: _left <= 8,
              child: Transform.scale(
                scale: _left <= 5 && !_busy
                    ? 1 + 0.3 * (_left - _left.floor())
                    : 1,
                child: Text(
                  _busy ? '' : '${_left.ceil()}',
                  style: TextStyle(
                    color: _left <= 5 ? IvoryColors.peach : IvoryColors.cream,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            ),
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
        Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 8),
          child: Text(
            _busy
                ? 'Turning your key\u2026'
                : 'Your choice is final, and sealed until Day ${q.days}.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: vaultInk,
              fontSize: 12.5,
            ),
          ),
        ),
        if (_problem.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              _problem,
              style: const TextStyle(
                color: vaultInk,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        if (_timedOut && !_busy && !_done)
          VaultWell(
            radius: 34,
            child: GoldButton(label: 'TRY AGAIN', onTap: () => _choose(-1)),
          ),
      ],
    );
  }
}

// END OF FILE - lib/screens/vault_question_view.dart
