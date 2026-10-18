import 'package:flutter/material.dart';

import '../models/bell_models.dart';
import '../widgets/bell_looks.dart';
import '../widgets/bell_paint.dart';
import '../widgets/bell_sound.dart';

/// ============================================================
/// IVORY - THE CARDS UNDER THE BELLS
///
/// Ivory's line for the night, how each bell rings, the three counts
/// (Full Days in a row, best run, all Full Days) and the sound switch.
/// Kept apart from the screen so each file stays short.
/// ============================================================
BoxDecoration bellsPanel() => BoxDecoration(
  borderRadius: const BorderRadius.only(
    topLeft: Radius.circular(44),
    topRight: Radius.circular(14),
    bottomLeft: Radius.circular(14),
    bottomRight: Radius.circular(44),
  ),
  gradient: const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF3B1CA4), Color(0xFF52209C), Color(0xFF6E1D95)],
    stops: <double>[0, 0.55, 1],
  ),
  border: Border.all(color: const Color(0x8CBEA0FF)),
  boxShadow: const <BoxShadow>[
    BoxShadow(color: Color(0x663B1CA4), blurRadius: 22, offset: Offset(0, 8)),
  ],
);

Widget bellsHeading(String t) => Padding(
  padding: const EdgeInsets.only(bottom: 9),
  child: Text(
    t,
    style: const TextStyle(
      color: Color(0xFFBFF4FF),
      fontSize: 11.5,
      fontWeight: FontWeight.w800,
      letterSpacing: 2.4,
    ),
  ),
);

/// One tap to open the bell sets: shows the set being worn and the round.
class BellsSetsRow extends StatelessWidget {
  const BellsSetsRow({super.key, required this.state, required this.onTap});

  final BellsState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BellSet? w = state.setByKey(state.wear);
    final BellLook look = BellLook.of(state.wear);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
        decoration: bellsPanel(),
        child: Row(
          children: <Widget>[
            for (final Color c in look.colors)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: BellShape(color: c, width: 22, glow: 0.45),
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'BELL SETS',
                    style: TextStyle(
                      color: Color(0xFFBFF4FF),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Wearing ${w?.name ?? "Jewel"}\nRound ${state.round}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFBFF4FF)),
          ],
        ),
      ),
    );
  }
}

class BellsLineCard extends StatelessWidget {
  const BellsLineCard({super.key, required this.line});
  final String line;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: bellsPanel(),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 1400),
        curve: Curves.easeOut,
        builder: (BuildContext _, double v, Widget? child) =>
            Opacity(opacity: v, child: child),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            bellsHeading('A LINE FROM IVORY'),
            Text(
              line,
              style: const TextStyle(
                fontFamily: 'serif',
                fontStyle: FontStyle.italic,
                fontSize: 18,
                height: 1.5,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                '\u2014 Ivory',
                style: TextStyle(
                  color: Color(0xFFFFC2DD),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BellsHowBox extends StatelessWidget {
  const BellsHowBox({super.key, required this.state});
  final BellsState? state;

  @override
  Widget build(BuildContext context) {
    final BellsState? s = state;
    String t(String k, String d) => s?.byKey(k)?.timeLabel ?? d;
    const TextStyle b = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w800,
    );
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(18),
      decoration: bellsPanel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          bellsHeading('HOW EACH BELL RINGS'),
          Text.rich(
            TextSpan(
              style: const TextStyle(
                color: Color(0xFFE4DAFF),
                fontSize: 13,
                height: 1.5,
              ),
              children: <InlineSpan>[
                const TextSpan(text: 'Dawn', style: b),
                TextSpan(
                  text:
                      ' (${t('dawn', '6 AM')}) rings when you greet your '
                      'heart.\n',
                ),
                const TextSpan(text: 'Noon', style: b),
                TextSpan(
                  text: ' (${t('noon', '12 PM')}) when you read a story.\n',
                ),
                const TextSpan(text: 'Dusk', style: b),
                TextSpan(
                  text:
                      ' (${t('dusk', '6 PM')}) when you join in: a vault '
                      'key, a poll vote, a live or a wish, or a second '
                      'story.\n',
                ),
                const TextSpan(text: 'Night', style: b),
                TextSpan(
                  text:
                      " (${t('night', '9 PM')}) when you open Ivory's "
                      'closing line.\n\nA bell opens at its hour and stays open '
                      'until the day turns, and anything you already did '
                      'today is remembered. Each bell adds '
                      '${s?.ringPoints ?? 20} to your Golden Heart. Ring all '
                      'four and the day is a Full Day.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BellsCountsBox extends StatelessWidget {
  const BellsCountsBox({super.key, required this.state});
  final BellsState state;

  @override
  Widget build(BuildContext context) {
    final BellsState s = state;
    Widget ring(int v, String l) => Container(
      width: 92,
      height: 92,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const SweepGradient(
          colors: <Color>[
            Color(0xFFFF6B8B),
            Color(0xFFFFA42B),
            Color(0xFF4DF0A8),
            Color(0xFF52C7FF),
            Color(0xFFB07CFF),
            Color(0xFFFF6B8B),
          ],
        ),
      ),
      child: Container(
        width: 86,
        height: 86,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: Alignment(-0.3, -0.5),
            colors: <Color>[Color(0xFF5C2FD0), Color(0xFF26107A)],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              '$v',
              style: const TextStyle(
                fontFamily: 'serif',
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              l,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFCFF6FF),
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(18),
      decoration: bellsPanel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          bellsHeading('YOUR COUNTS'),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              ring(s.peal, 'FULL DAYS\nIN A ROW'),
              ring(s.bestPeal, 'BEST\nRUN'),
              ring(s.fullDays, 'ALL FULL\nDAYS'),
            ],
          ),
        ],
      ),
    );
  }
}

class BellsSoundRow extends StatelessWidget {
  const BellsSoundRow({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: BellSound.instance.on,
      builder: (BuildContext _, bool on, Widget? __) => Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Row(
          children: <Widget>[
            Icon(
              on ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: const Color(0xFFBFF4FF),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Bell sounds',
                style: TextStyle(
                  color: Color(0xFFE4DAFF),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Switch(
              value: on,
              activeThumbColor: const Color(0xFF4DF0A8),
              onChanged: (bool v) {
                BellSound.instance.setOn(v);
                if (v) BellSound.instance.play('tap');
              },
            ),
          ],
        ),
      ),
    );
  }
}

// END OF FILE - lib/screens/bells_panels.dart
