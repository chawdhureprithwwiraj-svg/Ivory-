import 'package:flutter/material.dart';

import '../core/ivory_errors.dart';
import '../models/bell_models.dart';
import '../services/bells_service.dart';
import '../widgets/bell_looks.dart';
import '../widgets/bell_paint.dart';
import '../widgets/bell_sound.dart';

/// ============================================================
/// IVORY - BELL SETS (earned by Full Days, never for sale)
///
/// Every set is four bells in their own colours and their own notes.
/// The member wears any set they have earned. After the last set the
/// count of Full Days starts again from 0, and every set reached
/// again earns a small star. Locked sets say how many Full Days to go.
/// ============================================================
Future<void> showBellSets(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF2A0E72),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    builder: (BuildContext c) => const _SetsBody(),
  );
}

class _SetsBody extends StatefulWidget {
  const _SetsBody();

  @override
  State<_SetsBody> createState() => _SetsBodyState();
}

class _SetsBodyState extends State<_SetsBody> {
  bool _busy = false;

  Future<void> _tap(BellSet s) async {
    final BellsState? st = BellsService.instance.state.value;
    if (st == null || _busy) return;
    if (!s.owned) {
      _say(
        '${s.name} comes at ${s.min} Full Days in a round. '
        '${s.remaining} to go.',
      );
      return;
    }
    if (st.wear == s.key) return;
    setState(() => _busy = true);
    try {
      await BellsService.instance.wear(s.key);
      BellSound.instance.play('ring0');
      if (mounted) _say('The bells now wear ${s.name}.');
    } catch (e) {
      if (mounted) _say(houseMessage(e));
    }
    if (mounted) setState(() => _busy = false);
  }

  void _say(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<BellsState?>(
      valueListenable: BellsService.instance.state,
      builder: (BuildContext _, BellsState? st, Widget? __) {
        final List<BellSet> sets = st?.sets ?? <BellSet>[];
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.82,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (BuildContext c, ScrollController sc) => ListView(
            controller: sc,
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
            children: <Widget>[
              const Text(
                'BELL SETS',
                style: TextStyle(
                  color: Color(0xFFBFF4FF),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.6,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Round ${st?.round ?? 1}. Every set has its own colours and '
                'its own notes, and is earned by Full Days, never bought. '
                'After the last set the count starts again from 0, and every '
                'set you reach again earns a star.',
                style: const TextStyle(
                  color: Color(0xFFE4DAFF),
                  height: 1.5,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  for (final BellSet s in sets) _tile(c, s, st!),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _tile(BuildContext c, BellSet s, BellsState st) {
    final double w = (MediaQuery.of(c).size.width - 16 * 2 - 12) / 2;
    final BellLook look = BellLook.of(s.key);
    final bool worn = st.wear == s.key;
    return GestureDetector(
      onTap: () => _tap(s),
      child: Container(
        width: w,
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF3B1CA4), Color(0xFF52209C)],
          ),
          border: Border.all(
            color: worn ? BellTones.noon : const Color(0x66BEA0FF),
            width: worn ? 2 : 1,
          ),
        ),
        child: Opacity(
          opacity: s.owned ? 1 : 0.55,
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  for (final Color col in look.colors)
                    BellShape(
                      color: col,
                      width: (w - 20) / 4 - 4,
                      glow: s.owned ? 0.5 : 0.1,
                      dim: !s.owned,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                s.name.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.6,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                worn
                    ? 'WEARING'
                    : s.owned
                    ? (s.min == 0 ? 'FROM THE START' : '${s.min} FULL DAYS')
                    : '${s.remaining} TO GO',
                style: TextStyle(
                  color: worn ? BellTones.noon : const Color(0xFFCFC2F5),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              if (s.stars > 0) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  List<String>.filled(
                        s.stars > 6 ? 6 : s.stars,
                        '\u2605',
                      ).join() +
                      (s.stars > 6 ? ' +${s.stars - 6}' : ''),
                  style: const TextStyle(
                    color: Color(0xFFFFD84D),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The small ceremony when a set is earned (or earned again).
/// Returns true if the member chose to wear it.
Future<bool> showSetUnlock(BuildContext context, BellsState st) async {
  if (st.newSets.isEmpty) return false;
  final BellSet? s = st.setByKey(st.newSets.last);
  if (s == null) return false;
  final BellLook look = BellLook.of(s.key);
  BellSound.instance.play('ring3');
  final bool already = st.wear == s.key;
  final bool? wear = await showDialog<bool>(
    context: context,
    builder: (BuildContext c) => Dialog(
      backgroundColor: const Color(0xFF2A0E72),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(34)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              s.stars > 0 ? 'A STAR FOR ${s.name.toUpperCase()}' : 'A NEW SET',
              style: const TextStyle(
                color: Color(0xFFBFF4FF),
                fontWeight: FontWeight.w800,
                letterSpacing: 2.4,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 14),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.elasticOut,
              builder: (BuildContext _, double v, Widget? ch) =>
                  Transform.scale(scale: v, child: ch),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  for (final Color col in look.colors)
                    BellShape(color: col, width: 46, glow: 0.7),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              s.name,
              style: const TextStyle(
                fontFamily: 'serif',
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              s.stars > 0
                  ? 'You reached it again. It now carries '
                        '${s.stars == 1 ? "a star" : "${s.stars} stars"}.'
                  : 'Earned with Full Days. Its bells have their own notes.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFE4DAFF), height: 1.5),
            ),
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                if (!already)
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(c).pop(false),
                      child: const Text(
                        'NOT NOW',
                        style: TextStyle(color: Color(0xFFCFC2F5)),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(c).pop(!already),
                    child: Container(
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(23),
                        gradient: LinearGradient(colors: look.colors),
                      ),
                      child: Text(
                        already ? 'LOVELY' : 'WEAR IT',
                        style: TextStyle(
                          color: BellTones.deep,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.6,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return wear == true;
}

// END OF FILE - lib/screens/bells_sets_sheet.dart
