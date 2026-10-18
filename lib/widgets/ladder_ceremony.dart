import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/ladder_models.dart';
import 'bell_sound.dart';
import 'ladder_paint.dart';

/// ============================================================
/// IVORY - THE IVORY LADDER: THE CEREMONIES
///
/// A moment of celebration, never fireworks: ripples of light open
/// around the news. One ceremony for a new rung, one for each streak
/// milestone (7, 30, 100, 166, 366 by default), one that turns through
/// every new Mark (however many were earned at once), and a small star
/// for each Full Day. Sound is the doorbell's own and is silent if the
/// member has switched it off.
/// ============================================================
class _Ripples extends CustomPainter {
  _Ripples(this.t, this.color) : super(repaint: null);

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // The ripples stay around the picture, above the words.
    final Offset c = Offset(size.width / 2, size.height * 0.37);
    for (int i = 0; i < 4; i++) {
      final double p = (t + i / 4) % 1.0;
      canvas.drawCircle(
        c,
        24 + p * 120,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * (1 - p) + 0.5
          ..color = color.withValues(alpha: (1 - p) * 0.55),
      );
    }
    for (int k = 0; k < 14; k++) {
      final double a = k * math.pi * 2 / 14 + t * math.pi * 2;
      final double d = 84 + 8 * math.sin(t * 12 + k);
      canvas.drawCircle(
        c + Offset(math.cos(a) * d, math.sin(a) * d),
        2,
        Paint()..color = Colors.white.withValues(alpha: 0.7),
      );
    }
  }

  @override
  bool shouldRepaint(_Ripples o) => o.t != t;
}

class _Stage extends StatefulWidget {
  const _Stage({
    required this.color,
    required this.heading,
    required this.pages,
    required this.cta,
  });

  final Color color;
  final String heading;
  final List<Widget> pages;
  final String cta;

  @override
  State<_Stage> createState() => _StageState();
}

class _StageState extends State<_Stage> with TickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat();
  final PageController _pc = PageController();
  int _i = 0;

  @override
  void dispose() {
    _loop.dispose();
    _pc.dispose();
    super.dispose();
  }

  void _next() {
    if (_i >= widget.pages.length - 1) {
      Navigator.of(context).pop();
      return;
    }
    BellSound.instance.play('tap');
    _pc.nextPage(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool last = _i >= widget.pages.length - 1;
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 22),
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 520),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              LadderTones.tealMid,
              LadderTones.teal,
              LadderTones.tealDeep,
            ],
          ),
          border: Border.all(color: widget.color.withValues(alpha: 0.7)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: widget.color.withValues(alpha: 0.4),
              blurRadius: 40,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Material(
            color: Colors.transparent,
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _loop,
                    builder: (BuildContext _, Widget? __) => CustomPaint(
                      painter: _Ripples(_loop.value, widget.color),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        widget.heading,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: widget.color,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Flexible(
                        child: SizedBox(
                          height: 330,
                          child: PageView(
                            controller: _pc,
                            onPageChanged: (int v) => setState(() => _i = v),
                            children: widget.pages,
                          ),
                        ),
                      ),
                      if (widget.pages.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List<Widget>.generate(
                              math.min(widget.pages.length, 12),
                              (int k) => Container(
                                width: k == _i ? 16 : 6,
                                height: 6,
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(3),
                                  color: k == _i
                                      ? widget.color
                                      : Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                            ),
                          ),
                        ),
                      GestureDetector(
                        onTap: _next,
                        child: Container(
                          height: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            gradient: LinearGradient(
                              colors: <Color>[
                                widget.color,
                                LadderTones.mix(
                                  widget.color,
                                  LadderTones.aqua,
                                  0.5,
                                ),
                              ],
                            ),
                          ),
                          child: Text(
                            last ? widget.cta : 'NEXT',
                            style: const TextStyle(
                              color: LadderTones.teal,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _show(BuildContext context, Widget w) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Ladder news',
    barrierColor: LadderTones.tealDeep.withValues(alpha: 0.82),
    transitionDuration: const Duration(milliseconds: 420),
    pageBuilder: (BuildContext c, Animation<double> a, Animation<double> b) => w,
    transitionBuilder:
        (BuildContext c, Animation<double> a, Animation<double> b, Widget child) =>
            FadeTransition(
              opacity: a,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.82, end: 1).animate(
                  CurvedAnimation(parent: a, curve: Curves.easeOutBack),
                ),
                child: child,
              ),
            ),
  );
}

Widget _words(String big, String small, {Widget? top}) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
      if (top != null) top,
      const SizedBox(height: 14),
      Text(
        big,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.w900,
          height: 1.1,
        ),
      ),
      const SizedBox(height: 10),
      Text(
        small,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: LadderTones.pearl.withValues(alpha: 0.92),
          height: 1.45,
          fontSize: 14.5,
        ),
      ),
    ],
  );
}

/// A shared little animation for the ceremonies' pictures.
class _Shine extends StatefulWidget {
  const _Shine({required this.build});

  final Widget Function(Animation<double> shine) build;

  @override
  State<_Shine> createState() => _ShineState();
}

class _ShineState extends State<_Shine> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.build(_c);
}

/// The member has climbed to a new rung.
Future<void> showRungUp(BuildContext context, LadderState s) {
  BellSound.instance.play('full');
  return _show(
    context,
    _Stage(
      color: LadderTones.mint,
      heading: 'YOU CLIMBED',
      cta: 'KEEP CLIMBING',
      pages: <Widget>[
        _words(
          s.rung.name,
          'Rung ${s.rung.n} of ${s.rungs.length}. ${s.points} climb points, '
          'every one of them earned.',
          top: _Shine(
            build: (Animation<double> a) => CustomPaint(
              size: const Size(110, 110),
              painter: StarBadgePainter(shine: a),
            ),
          ),
        ),
      ],
    ),
  );
}

/// A streak has reached a milestone.
Future<void> showMilestones(BuildContext context, List<LadderMilestone> ms) {
  BellSound.instance.play('full');
  return _show(
    context,
    _Stage(
      color: LadderTones.aqua,
      heading: 'A MILESTONE',
      cta: 'LOVELY',
      pages: ms
          .map(
            (LadderMilestone m) => _words(
              '${m.days} days',
              m.kind == 'glow'
                  ? 'Your Golden Heart has glowed ${m.days} days in a row.'
                  : 'You have rung a Full Day ${m.days} days in a row.',
              top: Text(
                '${m.days}',
                style: const TextStyle(
                  color: LadderTones.mint,
                  fontSize: 84,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          )
          .toList(),
    ),
  );
}

/// New Marks turn through one by one.
Future<void> showNewMarks(BuildContext context, List<MarkItem> marks) {
  BellSound.instance.play('ring2');
  final MarkItem best = marks.reduce(
    (MarkItem a, MarkItem b) => b.rarityIndex > a.rarityIndex ? b : a,
  );
  return _show(
    context,
    _Stage(
      color: LadderTones.rarity[best.rarityIndex],
      heading: marks.length == 1 ? 'A NEW MARK' : '${marks.length} NEW MARKS',
      cta: 'ADD TO MY BOOK',
      pages: marks
          .map(
            (MarkItem m) => _words(
              m.name,
              '${m.blurb}\n${LadderTones.rarityName[m.rarityIndex]}',
              top: _Shine(
                build: (Animation<double> a) => MarkMedallion(
                  glyph: m.glyph,
                  rarity: m.rarityIndex,
                  earned: true,
                  fraction: 1,
                  shine: a,
                  size: 120,
                  label: m.target > 1 ? '${m.target}' : '',
                ),
              ),
            ),
          )
          .toList(),
    ),
  );
}

/// The star for a Full Day: shown briefly over the doorbell screen.
Future<void> showFullDayStar(BuildContext context, int n) {
  BellSound.instance.play('full');
  return _show(
    context,
    _Stage(
      color: LadderTones.rose,
      heading: 'FULL DAY',
      cta: 'LOVELY',
      pages: <Widget>[
        _words(
          'Star number $n',
          'All your bells rang today. Every star is yours to keep.',
          top: _Shine(
            build: (Animation<double> a) => CustomPaint(
              size: const Size(120, 120),
              painter: StarBadgePainter(shine: a),
            ),
          ),
        ),
      ],
    ),
  );
}

// END OF FILE - lib/widgets/ladder_ceremony.dart
