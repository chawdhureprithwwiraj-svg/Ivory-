import 'dart:async';

import 'package:flutter/material.dart';

import '../core/ivory_errors.dart';
import '../models/ladder_models.dart';
import '../services/ladder_service.dart';
import '../widgets/bell_sound.dart';
import '../widgets/ladder_calendar.dart';
import '../widgets/ladder_ceremony.dart';
import '../widgets/ladder_marks.dart';
import '../widgets/ladder_paint.dart';
import '../widgets/ladder_streaks.dart';

/// ============================================================
/// IVORY - THE IVORY LADDER (the long journey)
///
/// One page for everything a member has earned over time: the ladder
/// of rungs, the stars from Full Days, both streaks with their
/// milestones, a calendar of lit days, and the book of Marks. Climb
/// points are 1 for every lit heart day, 1 for every Full Day and a
/// few for every Mark. Everything is free and earned; nothing is sold.
/// The database works it all out; this page shows it and plays the
/// ceremonies for anything new.
/// ============================================================
class LadderScreen extends StatefulWidget {
  const LadderScreen({super.key});

  @override
  State<LadderScreen> createState() => _LadderScreenState();
}

class _LadderScreenState extends State<LadderScreen>
    with TickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  )..repeat();
  late final AnimationController _shine = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  )..repeat();
  bool _playing = false;
  bool _played = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    LadderService.instance.start();
    BellSound.instance.load();
    _load();
  }

  @override
  void dispose() {
    _loop.dispose();
    _shine.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final LadderState s = await LadderService.instance.refresh();
      if (!mounted) return;
      setState(() => _error = null);
      unawaited(_ceremonies(s));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = houseMessage(e));
    }
  }

  /// Plays whatever is new, once, then tells the database it was seen.
  Future<void> _ceremonies(LadderState s) async {
    if (_playing || _played || !s.hasNews) return;
    _playing = true;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      if (s.rungUp) {
        await showRungUp(context, s);
        if (!mounted) return;
      }
      final List<LadderMilestone> ms = s.newMilestones;
      if (ms.isNotEmpty) {
        await showMilestones(context, ms);
        if (!mounted) return;
      }
      final List<MarkItem> mk = s.newMarkItems;
      if (mk.isNotEmpty) {
        await showNewMarks(context, mk);
        if (!mounted) return;
      }
      _played = true;
      await LadderService.instance.markSeen();
    } catch (_) {
      // A ceremony must never break the page.
    } finally {
      _playing = false;
    }
  }

  Widget _card({required Widget child, EdgeInsets? pad}) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: pad ?? const EdgeInsets.all(18),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(26),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          LadderTones.tealMid.withValues(alpha: 0.85),
          LadderTones.tealDeep.withValues(alpha: 0.9),
        ],
      ),
      border: Border.all(color: LadderTones.mint.withValues(alpha: 0.22)),
    ),
    child: child,
  );

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      t,
      style: const TextStyle(
        color: LadderTones.mint,
        fontWeight: FontWeight.w900,
        letterSpacing: 2.6,
        fontSize: 11.5,
      ),
    ),
  );

  Widget _hero(LadderState s) {
    return _card(
      child: Column(
        children: <Widget>[
          Text(
            'RUNG ${s.rung.n} OF ${s.rungs.length}',
            style: const TextStyle(
              color: LadderTones.mist,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.6,
              fontSize: 11.5,
            ),
          ),
          const SizedBox(height: 6),
          ShaderMask(
            shaderCallback: (Rect r) => const LinearGradient(
              colors: <Color>[Colors.white, LadderTones.mint, LadderTones.aqua],
            ).createShader(r),
            child: Text(
              s.rung.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${s.points} climb points',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: s.climb,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.14),
              valueColor: const AlwaysStoppedAnimation<Color>(LadderTones.mint),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            s.next == null
                ? 'You stand on the highest rung.'
                : '${s.need} more to reach ${s.next!.name}',
            style: const TextStyle(color: LadderTones.pearl, fontSize: 13.5),
          ),
          const SizedBox(height: 12),
          Text(
            '1 point for every day your heart is lit, 1 for every Full Day, '
            'and ${s.markPoints} for every Mark.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: LadderTones.mist.withValues(alpha: 0.95),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ladder(LadderState s) {
    final int n = s.rungs.length;
    if (n == 0) return const SizedBox.shrink();
    const double rowH = 54;
    return _card(
      pad: const EdgeInsets.fromLTRB(10, 18, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: _label('THE LADDER'),
          ),
          SizedBox(
            height: rowH * n,
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 110,
                  child: AnimatedBuilder(
                    animation: _loop,
                    builder: (BuildContext _, Widget? __) => CustomPaint(
                      size: Size(110, rowH * n),
                      painter: LadderPainter(
                        rungs: n,
                        current: (s.rung.n - 1).clamp(0, n - 1),
                        climb: s.climb,
                        t: _loop.value,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: s.rungs.reversed.map((LadderRung r) {
                      final bool here = r.n == s.rung.n;
                      final bool reached = r.n <= s.rung.n;
                      return SizedBox(
                        height: rowH,
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                r.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: reached
                                      ? Colors.white
                                      : LadderTones.mist.withValues(alpha: 0.7),
                                  fontWeight: here
                                      ? FontWeight.w900
                                      : FontWeight.w700,
                                  fontSize: here ? 17 : 14.5,
                                ),
                              ),
                            ),
                            Text(
                              here ? 'YOU' : '${r.min}',
                              style: TextStyle(
                                color: here
                                    ? LadderTones.mint
                                    : LadderTones.mist.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stars(LadderState s) {
    return _card(
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 84,
            height: 84,
            child: CustomPaint(
              painter: StarBadgePainter(shine: _shine, lit: s.stars > 0),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${s.stars}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.stars == 1 ? 'Full Day star' : 'Full Day stars',
                  style: const TextStyle(
                    color: LadderTones.mint,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'A star for every day all your bells rang. Stars are yours to keep.',
                  style: TextStyle(
                    color: LadderTones.pearl,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LadderTones.teal,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              LadderTones.tealMid,
              LadderTones.teal,
              LadderTones.tealDeep,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Expanded(
                      child: Text(
                        'THE IVORY LADDER',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ValueListenableBuilder<LadderState?>(
                  valueListenable: LadderService.instance.state,
                  builder: (BuildContext context, LadderState? s, Widget? _) {
                    if (s == null) {
                      return Center(
                        child: _error != null
                            ? Padding(
                                padding: const EdgeInsets.all(28),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Text(
                                      _error!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: LadderTones.pearl,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    TextButton(
                                      onPressed: _load,
                                      child: const Text(
                                        'Try again',
                                        style: TextStyle(color: LadderTones.mint),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const CircularProgressIndicator(
                                color: LadderTones.mint,
                              ),
                      );
                    }
                    if (!s.enabled) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(28),
                          child: Text(
                            'The ladder is resting for now. It will be back soon.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: LadderTones.pearl),
                          ),
                        ),
                      );
                    }
                    return RefreshIndicator(
                      color: LadderTones.teal,
                      backgroundColor: LadderTones.mint,
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
                        children: <Widget>[
                          _hero(s),
                          _ladder(s),
                          _stars(s),
                          _card(child: LadderStreaks(state: s)),
                          _card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                _label('YOUR CALENDAR'),
                                const LadderCalendar(),
                              ],
                            ),
                          ),
                          _card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                _label(
                                  'MARKS BOOK  ${s.marksEarned} / ${s.marksTotal}',
                                ),
                                MarksBook(marks: s.marks, shine: _shine),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// END OF FILE - lib/screens/ladder_screen.dart
