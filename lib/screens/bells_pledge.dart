import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/bell_models.dart';
import '../widgets/bell_paint.dart';
import '../widgets/bell_sound.dart';
import 'bells_panels.dart';

/// ============================================================
/// IVORY - THE PLEDGE (free, nothing at stake)
///
/// A member promises 3, 7, 14 or 30 Full Days in a row (the lengths
/// are the house's to change). The card shows the pledge going as a
/// ring of days, or the lengths to choose from. A heart mend carries
/// a missed day. When a pledge is kept a small ceremony plays; when
/// it ends, the member is told kindly. Counting is done by the
/// database; this only shows it.
/// ============================================================
class BellsPledgeCard extends StatelessWidget {
  const BellsPledgeCard({
    super.key,
    required this.state,
    required this.busy,
    required this.onPick,
    this.onRelease,
  });

  final BellsState state;
  final bool busy;
  final ValueChanged<int> onPick;
  final VoidCallback? onRelease;

  @override
  Widget build(BuildContext context) {
    final BellPledge? p = state.pledge;
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(18),
      decoration: bellsPanel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          bellsHeading(p == null ? 'MAKE A PLEDGE' : 'YOUR PLEDGE'),
          if (p == null) ..._choose() else ..._going(p),
        ],
      ),
    );
  }

  List<Widget> _choose() {
    const TextStyle soft = TextStyle(
      color: Color(0xFFE4DAFF),
      fontSize: 13,
      height: 1.5,
    );
    return <Widget>[
      Text(
        'Promise yourself a number of Full Days in a row. It is free and '
        'nothing is at stake. A heart mend carries a missed day.'
        '${state.full ? " Today's bells are all rung, so today counts as your first day." : ''}',
        style: soft,
      ),
      const SizedBox(height: 14),
      LayoutBuilder(
        builder: (BuildContext _, BoxConstraints box) {
          // Two equal columns, so the buttons line up.
          final double w = (box.maxWidth - 10) / 2;
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              for (int i = 0; i < state.pledgeLens.length; i++)
                _chip(state.pledgeLens[i], BellTones.of(i), w),
            ],
          );
        },
      ),
      if (state.pledgesKept > 0) ...<Widget>[
        const SizedBox(height: 12),
        Text(
          state.pledgesKept == 1
              ? 'Pledges kept: 1'
              : 'Pledges kept: ${state.pledgesKept}',
          style: const TextStyle(
            color: Color(0xFFBFF4FF),
            fontWeight: FontWeight.w800,
            fontSize: 12,
            letterSpacing: 1,
          ),
        ),
      ],
    ];
  }

  Widget _chip(int n, Color c, double w) {
    return GestureDetector(
      onTap: busy ? null : () => onPick(n),
      child: Container(
        width: w,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: LinearGradient(
            colors: <Color>[c, BellTones.mix(c, BellTones.amethyst, 0.5)],
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(color: c.withValues(alpha: 0.45), blurRadius: 14),
          ],
        ),
        child: Text(
          '$n DAYS',
          style: const TextStyle(
            color: BellTones.deep,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  List<Widget> _going(BellPledge p) {
    return <Widget>[
      Row(
        children: <Widget>[
          SizedBox(
            width: 112,
            height: 112,
            child: CustomPaint(
              painter: _DialPainter(p.got, p.len),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      '${p.got}',
                      style: const TextStyle(
                        fontFamily: 'serif',
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    Text(
                      'of ${p.len}',
                      style: const TextStyle(
                        color: Color(0xFFCFF6FF),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'A pledge of ${p.len} Full Days',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${p.left} to go. ${state.full ? "Today is done." : "Ring every bell today to count it."} '
                  'A heart mend carries a missed day.',
                  style: const TextStyle(
                    color: Color(0xFFE4DAFF),
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
                if (onRelease != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: busy ? null : onRelease,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.only(top: 6),
                        minimumSize: const Size(0, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'LET GO OF THIS PLEDGE',
                        style: TextStyle(
                          color: Color(0xFFCFC2F5),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ];
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter(this.got, this.len);

  final int got;
  final int len;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);
    final double r = size.width / 2 - 8;
    final int n = len.clamp(1, 366);
    final double gap = n > 14 ? 0.03 : 0.09;
    final double seg = 2 * math.pi / n;
    for (int i = 0; i < n; i++) {
      final bool on = i < got;
      final Color col = on
          ? BellTones.mix(
              BellTones.of(0),
              BellTones.of(3),
              n == 1 ? 0 : i / (n - 1),
            )
          : Colors.white.withValues(alpha: 0.16);
      final Paint p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..color = col;
      if (on) {
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: r),
          -math.pi / 2 + i * seg + gap,
          seg - gap * 2,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 11
            ..color = col.withValues(alpha: 0.35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );
      }
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        -math.pi / 2 + i * seg + gap,
        seg - gap * 2,
        false,
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_DialPainter o) => o.got != got || o.len != len;
}

/// Plays the little ceremony for a pledge that has been kept or has ended.
Future<void> showPledgeResult(BuildContext context, PledgeResult r) {
  if (r.kept) BellSound.instance.play('full');
  return showDialog<void>(
    context: context,
    builder: (BuildContext c) => Dialog(
      backgroundColor: const Color(0xFF2A0E72),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(34)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 1100),
              curve: Curves.elasticOut,
              builder: (BuildContext _, double v, Widget? ch) =>
                  Transform.scale(scale: v, child: ch),
              child: Icon(
                r.kept ? Icons.auto_awesome_rounded : Icons.favorite_rounded,
                size: 64,
                color: r.kept ? BellTones.dusk : BellTones.dawn,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              r.kept ? 'Pledge kept' : 'This pledge has ended',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'serif',
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              r.kept
                  ? 'You rang all the bells on ${r.len} days in a row, as you '
                        'promised. That is a real thing to be proud of.'
                  : 'You reached ${r.got} of ${r.len} Full Days. Every one of '
                        'them is still yours, and so is your best run. Begin a '
                        'new pledge whenever you like.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFE4DAFF),
                height: 1.5,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: () => Navigator.of(c).pop(),
              child: Container(
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: <Color>[BellTones.noon, BellTones.night],
                  ),
                ),
                child: const Text(
                  'LOVELY',
                  style: TextStyle(
                    color: BellTones.deep,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// END OF FILE - lib/screens/bells_pledge.dart
