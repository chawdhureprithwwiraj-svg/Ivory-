import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/vault_models.dart';
import '../theme/ivory_theme.dart';
import '../widgets/gold_burst.dart';
import '../widgets/gold_fx.dart';
import '../widgets/gold_fx3d.dart';
import '../widgets/gold_light.dart';
import '../widgets/gold_sound.dart';
import '../widgets/vault_keys.dart';
import 'golden_quiz_parts.dart';

/// ============================================================
/// IVORY - THE OPENING OF THE VAULT
///
/// The last key has turned. Ten plates, one for each day, flip
/// over one by one: gold with the rupees where the answer was
/// right, a dim plate where it was not. The vault counts up as
/// each one turns. About seven seconds, and a tap on SKIP shows
/// the result at once. Nothing here is decided on the phone: the
/// plates only show what the database sealed.
/// ============================================================
class VaultCeremony extends StatefulWidget {
  const VaultCeremony({super.key, required this.result, required this.onDone});

  final VaultResult result;
  final VoidCallback onDone;

  @override
  State<VaultCeremony> createState() => _VaultCeremonyState();
}

class _VaultCeremonyState extends State<VaultCeremony> {
  Timer? _t;
  int _shown = 0;
  int _boom = 0;
  bool _finished = false;

  List<VaultDay> get _days => widget.result.review;

  @override
  void initState() {
    super.initState();
    GoldSound.instance.big('reveal');
    _t = Timer.periodic(const Duration(milliseconds: 720), (Timer t) {
      if (!mounted) return;
      if (_shown < _days.length) {
        final VaultDay d = _days[_shown];
        HapticFeedback.selectionClick();
        GoldSound.instance.big(
          d.correct ? (d.golden ? 'golden' : 'correct') : 'wrong',
        );
        setState(() {
          _shown++;
          if (d.correct) _boom++;
        });
      } else {
        t.cancel();
        Timer(const Duration(milliseconds: 900), _finish);
      }
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  void _finish() {
    if (_finished || !mounted) return;
    _finished = true;
    widget.onDone();
  }

  int get _running {
    int t = 0;
    for (int i = 0; i < _shown && i < _days.length; i++) {
      t += _days[i].amountInr;
    }
    return t;
  }

  @override
  Widget build(BuildContext context) {
    final List<VaultDay> days = _days;
    return Stack(
      children: <Widget>[
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
          children: <Widget>[
            const GoldRise(
              child: Center(child: Text('THE VAULT OPENS', style: goldKick)),
            ),
            SizedBox(
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  const OverflowBox(
                    maxWidth: 320,
                    maxHeight: 320,
                    child: GoldRays(size: 320, opacity: 0.28),
                  ),
                  GoldShimmerText(
                    '\u20B9$_running',
                    extrude: 5,
                    style: goldSerif(64, w: FontWeight.w900),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                _shown < days.length
                    ? 'Turning key $_shown of ${days.length}'
                    : 'Every key is open',
                style: goldSerif(14.5, italic: true),
              ),
            ),
            const SizedBox(height: 22),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints c) {
                const double gap = 10;
                final int per = days.length > 10 ? 6 : 5;
                final double size = ((c.maxWidth - gap * (per - 1)) / per)
                    .clamp(40.0, 66.0)
                    .toDouble();
                return Wrap(
                  alignment: WrapAlignment.center,
                  spacing: gap,
                  runSpacing: gap + 4,
                  children: <Widget>[
                    for (int i = 0; i < days.length; i++)
                      VaultFlipDisc(
                        day: days[i].day,
                        flipped: i < _shown,
                        correct: days[i].correct,
                        golden: days[i].golden,
                        amountInr: days[i].amountInr,
                        size: size,
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 26),
            Center(
              child: TextButton(
                onPressed: _finish,
                child: Text(
                  'SKIP',
                  style: TextStyle(
                    color: GoldTones.light.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_boom > 0) ...<Widget>[
          Positioned.fill(child: GoldFlash(key: ValueKey<int>(_boom))),
          Positioned.fill(
            child: CoinBurst(
              key: ValueKey<int>(_boom),
              origin: const Alignment(0, -0.2),
            ),
          ),
        ],
      ],
    );
  }
}

// END OF FILE - lib/screens/vault_ceremony.dart
