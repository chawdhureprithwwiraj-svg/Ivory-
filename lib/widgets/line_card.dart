import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../screens/line_screen.dart';
import '../services/line_service.dart';
import '../theme/ivory_theme.dart';
import 'jewel_plate.dart';
import 'line_seal.dart';
import 'sound_bank.dart';

/// ============================================================
/// IVORY - THE PRIVATE LINE, ON THE HOME SCREEN
///
/// One holographic-foil jewel card (rose, apricot, orchid and mint pearl,
/// slowly shifting) with a sealed envelope that floats and glints. It says, truthfully, what
/// the member can do right now: write, wait, read a reply, or send
/// the letter that was kept for them. It disappears when the house
/// has switched the Private Line off or the database cannot be
/// reached. Tapping it opens the Private Line.
/// ============================================================
class LineCard extends StatefulWidget {
  const LineCard({super.key, this.onOpenTab});

  final void Function(String tab)? onOpenTab;

  @override
  State<LineCard> createState() => _LineCardState();
}

class _LineCardState extends State<LineCard> {
  LineService get _svc => LineService.instance;

  Map<String, dynamic>? _free;

  @override
  void initState() {
    super.initState();
    _svc.state.addListener(_changed);
    _svc.draft.addListener(_changed);
    _svc.loadDraft();
    _svc.refresh();
    _svc.freeState().then((Map<String, dynamic>? f) {
      if (mounted) setState(() => _free = f);
    });
  }

  @override
  void dispose() {
    _svc.state.removeListener(_changed);
    _svc.draft.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _open() async {
    // Your own Private Line recording (silent if it is missing).
    SoundBank.instance.play('private_line');
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LineScreen(onOpenTab: widget.onOpenTab),
      ),
    );
    SoundBank.instance.stop('private_line');
    if (mounted) _svc.refresh(force: true);
  }

  (String, String) _words(LineState s) {
    final bool draft = _svc.draft.value.trim().isNotEmpty;
    if (s.unseen > 0) {
      return ('Ivory wrote back', 'Open the Private Line to read her reply.');
    }
    if (s.paid) {
      final LineLetter? open = s.openLetter;
      if (open != null) {
        String line;
        switch (open.status) {
          case 'held':
            line = 'Held for a quick look by the house, then it travels.';
            break;
          case 'read':
            line = 'Read by Ivory. She answers as many as she can.';
            break;
          default:
            line = lineQueueText(s);
        }
        return ('Your letter is with Ivory', line);
      }
      if (s.canSend) {
        return draft
            ? ('Your letter is waiting', 'It was kept for you. Seal it and send it to Ivory.')
            : ('Write to Ivory', 'Every letter is read. She answers as many as she can.');
      }
      return ('Your letters are resting', 'A new one frees up as the days pass.');
    }
    return draft
        ? ('Your letter is kept for you', 'Seal it into the Line today - it stands in the queue even before you join.')
        : ('Write to Ivory', 'Seal a letter into the Line today. It stands in the queue even before you join - membership simply carries it to the front.');
  }

  @override
  Widget build(BuildContext context) {
    final LineState? s = _svc.state.value;
    if (s == null || s.whyNot == 'resting') return const SizedBox.shrink();
    final (String head, String line) = _words(s);
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: GestureDetector(
        onTap: _open,
        child: JewelPlate(
          foil: true,
          colors: const <Color>[
            Color(0xFFFF9CCB),
            Color(0xFFFFC777),
            Color(0xFFE7A6FF),
            Color(0xFF9FE6C0),
            Color(0xFFFF9CCB),
          ],
          rim: const Color(0xFFFFFFFF),
          spark: const Color(0xFFFFFFFF),
          shade: const Color(0xFFB0366E),
          child: Row(
            children: <Widget>[
              const _FloatingLetter(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                          'THE PRIVATE LINE',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: IvoryColors.burgundy.withValues(alpha: 0.8),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.4,
                          ),
                        ),
                        ),
                        if (s.unseen > 0) ...<Widget>[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: IvoryColors.burgundy,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              s.unseen == 1 ? 'NEW' : '${s.unseen} NEW',
                              style: const TextStyle(
                                color: Color(0xFFFFF3F7),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      head,
                      style: const TextStyle(
                        color: IvoryColors.burgundy,
                        shadows: <Shadow>[
                          Shadow(color: Color(0xAAFFFFFF), offset: Offset(0, 1)),
                        ],
                        fontFamily: IvoryTheme.displayFont,
                        fontStyle: FontStyle.italic,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      line,
                      style: TextStyle(
                        color: IvoryColors.burgundy.withValues(alpha: 0.9),
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                    if (!s.paid && _free != null && _free!['position'] != null) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        'Your letter stands at number ${_free!['position']} in the Line.',
                        style: const TextStyle(
                          color: IvoryColors.burgundy,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                    if (!s.paid) ...<Widget>[
                      const SizedBox(height: 6),
                      Text(
                        'Skip the Line: members read first - and more than one '
                        'road lowers the price.',
                        style: TextStyle(
                          color: IvoryColors.burgundy.withValues(alpha: 0.75),
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    if (s.answeredToday > 0) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        s.answeredToday == 1
                            ? 'Ivory answered 1 letter today.'
                            : 'Ivory answered ${s.answeredToday} letters today.',
                        style: const TextStyle(
                          color: IvoryColors.burgundy,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
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

/// The sealed envelope, floating gently on a soft white glow, with a
/// small shadow that breathes under it and a glint that crosses the
/// seal now and then. Slow and quiet.
class _FloatingLetter extends StatefulWidget {
  const _FloatingLetter();

  @override
  State<_FloatingLetter> createState() => _FloatingLetterState();
}

class _FloatingLetterState extends State<_FloatingLetter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5000),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: 90,
        height: 82,
        child: AnimatedBuilder(
          animation: _c,
          builder: (BuildContext context, Widget? _) {
            final double t = _c.value;
            final double bob = math.sin(t * math.pi * 2);
            return Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Container(
                  width: 86,
                  height: 74,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: <Color>[
                        const Color(0xFFFFFFFF).withValues(alpha: 0.6),
                        const Color(0x00FFFFFF),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 2,
                  child: Container(
                    width: 52 - 6 * bob,
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: const Color(0xFFB0366E).withValues(
                        alpha: 0.22 - 0.05 * bob,
                      ),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: Offset(0, -4 - 3 * bob),
                  child: Transform.rotate(
                    angle: math.sin(t * math.pi * 2 + 1) * 0.03,
                    child: const LineEnvelopeView(width: 84, height: 70),
                  ),
                ),
                IgnorePointer(
                  child: CustomPaint(
                    size: const Size(90, 82),
                    painter: _GlintPainter(t, -4 - 3 * bob),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GlintPainter extends CustomPainter {
  _GlintPainter(this.t, this.dy);

  final double t;
  final double dy;

  @override
  void paint(Canvas canvas, Size size) {
    final double g = math.pow(
      math.max(0.0, math.sin(math.pi * 2 * (t * 2 + 0.15))),
      8,
    ).toDouble();
    if (g < 0.05) return;
    final Offset c = Offset(size.width / 2 - 6, size.height / 2 + dy - 2);
    final Paint p = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.95 * g)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final double len = 4 + 8 * g;
    canvas.drawLine(c.translate(-len, 0), c.translate(len, 0), p);
    canvas.drawLine(c.translate(0, -len), c.translate(0, len), p);
  }

  @override
  bool shouldRepaint(_GlintPainter o) => o.t != t || o.dy != dy;
}

// END OF FILE - lib/widgets/line_card.dart
