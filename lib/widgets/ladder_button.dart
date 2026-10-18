import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/ladder_models.dart';
import '../screens/ladder_screen.dart';
import '../services/ladder_service.dart';
import 'ladder_paint.dart';

/// ============================================================
/// IVORY - THE LADDER ICON IN THE TOP BAR
///
/// A small glowing ladder with a ring that shows how far the member
/// is to the next rung. When something new has been earned (a Mark, a
/// rung, a streak milestone) the ladder shimmers and a badge counts
/// the news. If the house closes the ladder the icon quietly
/// disappears.
/// ============================================================
class LadderButton extends StatefulWidget {
  const LadderButton({super.key});

  @override
  State<LadderButton> createState() => _LadderButtonState();
}

class _LadderButtonState extends State<LadderButton>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat();
  Timer? _later;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    LadderService.instance.start();
    _later = Timer(
      const Duration(milliseconds: 1200),
      LadderService.instance.refreshQuietly,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) {
      LadderService.instance.refreshQuietly();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _later?.cancel();
    _loop.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const LadderScreen()),
    );
    LadderService.instance.refreshQuietly();
  }

  int _news(LadderState s) =>
      s.newMarks.length +
      (s.rungUp ? 1 : 0) +
      s.milestones.where((LadderMilestone m) => m.isNew).length;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<LadderState?>(
      valueListenable: LadderService.instance.state,
      builder: (BuildContext context, LadderState? s, Widget? _) {
        if (s != null && !s.enabled) return const SizedBox.shrink();
        final int news = s == null ? 0 : _news(s);
        return Semantics(
          button: true,
          label: 'The Ivory Ladder',
          child: InkResponse(
            radius: 26,
            onTap: _open,
            child: SizedBox(
              width: 46,
              height: 48,
              child: AnimatedBuilder(
                animation: _loop,
                builder: (BuildContext _, Widget? __) {
                  final double t = _loop.value;
                  // The top bar is light, so the ladder is drawn in deep
                  // teal, and cycles teal to blue when there is news.
                  final Color c = news > 0
                      ? LadderTones.mix(
                          const Color(0xFF0FA39A),
                          const Color(0xFF1B7FD0),
                          0.5 + 0.5 * math.sin(t * math.pi * 2),
                        )
                      : LadderTones.tealMid;
                  return Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      if (s != null)
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            value: s.climb,
                            strokeWidth: 2,
                            backgroundColor: LadderTones.tealMid.withValues(
                              alpha: 0.16,
                            ),
                            valueColor: AlwaysStoppedAnimation<Color>(c),
                          ),
                        ),
                      CustomPaint(
                        size: const Size(22, 26),
                        painter: _MiniLadder(color: c, t: t, glow: news > 0),
                      ),
                      if (news > 0)
                        Positioned(
                          right: 1,
                          top: 3,
                          child: Container(
                            constraints: const BoxConstraints(minWidth: 16),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: LadderTones.rose,
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                            child: Text(
                              '$news',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                height: 1.15,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MiniLadder extends CustomPainter {
  _MiniLadder({required this.color, required this.t, required this.glow});

  final Color color;
  final double t;
  final bool glow;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()
      ..color = color
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    if (glow) {
      canvas.drawLine(
        Offset(size.width * 0.2, 0),
        Offset(size.width * 0.2, size.height),
        Paint()
          ..color = color.withValues(alpha: 0.5)
          ..strokeWidth = 6
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawLine(
        Offset(size.width * 0.8, 0),
        Offset(size.width * 0.8, size.height),
        Paint()
          ..color = color.withValues(alpha: 0.5)
          ..strokeWidth = 6
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }
    canvas.drawLine(
      Offset(size.width * 0.2, 0),
      Offset(size.width * 0.2, size.height),
      p,
    );
    canvas.drawLine(
      Offset(size.width * 0.8, 0),
      Offset(size.width * 0.8, size.height),
      p,
    );
    for (int i = 0; i < 4; i++) {
      final double y = size.height * (0.12 + i * 0.25);
      canvas.drawLine(
        Offset(size.width * 0.2, y),
        Offset(size.width * 0.8, y),
        p,
      );
    }
    // A bright climber going up the ladder.
    final double y = size.height * (1 - ((t * 1.0) % 1.0));
    canvas.drawCircle(
      Offset(size.width / 2, y),
      2.4,
      Paint()..color = const Color(0xFFFF7FA8),
    );
  }

  @override
  bool shouldRepaint(_MiniLadder o) =>
      o.t != t || o.color != color || o.glow != glow;
}

// END OF FILE - lib/widgets/ladder_button.dart
