import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/ladder_models.dart';
import '../screens/ladder_screen.dart';
import '../services/ladder_service.dart';
import 'ladder_paint.dart';
import 'sound_bank.dart';

/// ============================================================
/// IVORY - THE LADDER ICON IN THE TOP BAR
///
/// A solid gold ladder with five jewel steps that light ONE BY ONE
/// from the bottom to the top (a bright spark climbs with them), a
/// slow cloud of golden dust around it and a thin ring that shows how
/// far the member is to the next rung. It is drawn as large as the
/// top bar allows so every step reads. When something new has been
/// earned the glow grows and a badge counts the news. If the house
/// closes the ladder the icon quietly disappears.
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
    duration: const Duration(milliseconds: 4800),
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
    SoundBank.instance.play('ladder');
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
        final double boost = news > 0 ? 1.3 : 1.0;
        return Semantics(
          button: true,
          label: 'The Ivory Ladder',
          child: InkResponse(
            radius: 28,
            onTap: _open,
            child: SizedBox(
              width: 52,
              height: 52,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  if (s != null)
                    CustomPaint(
                      size: const Size(46, 46),
                      painter: _RingPainter(s.climb, news > 0),
                    ),
                  RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _loop,
                      builder: (BuildContext _, Widget? __) => CustomPaint(
                        size: const Size(46, 46),
                        painter: _GlowLadder(_loop.value, boost),
                      ),
                    ),
                  ),
                  if (news > 0)
                    Positioned(
                      right: 0,
                      top: 1,
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
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The gold ladder. One loop (t from 0 to 1): a spark climbs, and each
/// jewel step lights as the spark reaches it (bottom first), they all
/// glow together for a moment with a star on top, then fade and start
/// again. The dust circles slowly in two directions and the ladder
/// turns a little, as if it stood in the light. No flat disc, no blue.
class _GlowLadder extends CustomPainter {
  _GlowLadder(this.t, this.boost);

  final double t;
  final double boost;

  static const List<Color> _gems = <Color>[
    Color(0xFFD42450),
    Color(0xFFFF9A1F),
    Color(0xFF14B87A),
    Color(0xFF9A55E6),
    Color(0xFFFF6FA3),
  ];
  static const List<Color> _dust = <Color>[
    Color(0xFFFFD66B),
    Color(0xFFFFF0B0),
    Color(0xFFF4B63F),
  ];

  static double _ramp(double x, double a, double b) {
    final double v = ((x - a) / (b - a)).clamp(0.0, 1.0).toDouble();
    return v * v * (3 - 2 * v);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Offset c = Offset(w / 2, h / 2);
    const double tau = math.pi * 2;
    final double fade = 1 - _ramp(t, 0.84, 0.96);
    final List<double> g = List<double>.generate(5, (int i) {
      final double s = 0.03 + i * 0.14;
      return _ramp(t, s, s + 0.07) * fade;
    });
    final double all = (g[0] + g[1] + g[2] + g[3] + g[4]) / 5;

    // The warm light behind everything.
    final double a = math.min(1.0, (0.5 + 0.4 * all) * boost);
    canvas.drawCircle(
      c,
      w * 0.5,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            const Color(0xFFFFE9A0).withValues(alpha: a),
            const Color(0xFFF6C85A).withValues(alpha: a * 0.55),
            const Color(0x00F6C85A),
          ],
          stops: const <double>[0, 0.55, 1],
        ).createShader(Rect.fromCircle(center: c, radius: w * 0.5)),
    );

    // The dust: two rings going opposite ways, twinkling.
    for (int i = 0; i < 16; i++) {
      final bool outer = i.isEven;
      final double ang = i * 2.399 + (outer ? 1 : -1) * t * tau;
      final double r = w * (outer ? 0.43 : 0.35) + (i % 3) * 0.6;
      final double tw = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(t * tau * 2 + i * 1.7));
      canvas.drawCircle(
        c + Offset(math.cos(ang) * r, math.sin(ang) * r),
        0.7 + (i % 4) * 0.28,
        Paint()..color = _dust[i % 3].withValues(alpha: tw),
      );
    }

    // The ladder turns a little, as if standing in the light.
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(0.9 + 0.1 * math.cos(t * tau), 1);
    canvas.translate(-c.dx, -c.dy);

    final double yTop = h * 0.17;
    final double yBot = h * 0.83;
    final double hb = w * 0.25;
    final double ht = w * 0.145;
    double half(double y) => ht + (hb - ht) * (y - yTop) / (yBot - yTop);
    final double rw = w * 0.085;
    for (final int side in <int>[-1, 1]) {
      final Offset p0 = Offset(c.dx + side * half(yTop), yTop);
      final Offset p1 = Offset(c.dx + side * half(yBot), yBot);
      canvas.drawLine(
        p0,
        p1,
        Paint()
          ..color = const Color(0xFF7A470A)
          ..strokeWidth = rw + 1.8
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        p0,
        p1,
        Paint()
          ..strokeWidth = rw
          ..strokeCap = StrokeCap.round
          ..shader = const LinearGradient(
            colors: <Color>[
              Color(0xFF8A5410),
              Color(0xFFF4C24D),
              Color(0xFFFFF3B8),
              Color(0xFFE5A531),
              Color(0xFF7A470A),
            ],
            stops: <double>[0, 0.25, 0.45, 0.7, 1],
          ).createShader(
            Rect.fromLTWH((p0.dx + p1.dx) / 2 - rw, yTop, rw * 2, yBot - yTop),
          ),
      );
      canvas.drawLine(
        p0 + Offset(-rw * 0.18, 1),
        p1 + Offset(-rw * 0.18, -1),
        Paint()
          ..color = const Color(0x80FFFFFF)
          ..strokeWidth = 0.8
          ..strokeCap = StrokeCap.round,
      );
    }

    // The five jewel steps, bottom first.
    final double rh = h * 0.088;
    for (int i = 0; i < 5; i++) {
      final double y = yBot - (yBot - yTop) * (0.1 + i * 0.2);
      final Rect rr = Rect.fromLTRB(c.dx - half(y), y - rh / 2, c.dx + half(y), y + rh / 2);
      final double gi = g[i];
      if (gi > 0.02) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rr.inflate(1.8 + 2.2 * gi), Radius.circular(rh)),
          Paint()
            ..color = _gems[i].withValues(alpha: math.min(1.0, 0.8 * gi * boost))
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.2),
        );
      }
      final RRect body = RRect.fromRectAndRadius(rr, Radius.circular(rh / 2));
      canvas.drawRRect(body.inflate(0.7), Paint()..color = const Color(0xFF7A470A));
      final Color dim = Color.lerp(_gems[i], const Color(0xFF8A5410), 0.42)!;
      final Color lit = Color.lerp(_gems[i], Colors.white, 0.22)!;
      canvas.drawRRect(body, Paint()..color = Color.lerp(dim, lit, gi)!);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(rr.left + rh * 0.5, rr.top + 0.5, rr.right - rh * 0.5, rr.top + rh * 0.38),
          const Radius.circular(1),
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.3 + 0.45 * gi),
      );
      final double s = 0.03 + i * 0.14;
      final double flash = math.max(0.0, 1 - (t - s - 0.045).abs() / 0.05);
      if (flash > 0) {
        canvas.drawRRect(body, Paint()..color = Colors.white.withValues(alpha: 0.55 * flash));
      }
    }

    // The spark that climbs with the lights.
    if (t < 0.64) {
      final double fr = (0.1 + (t - 0.03) / 0.56 * 0.8).clamp(0.04, 0.96).toDouble();
      final double y = yBot - (yBot - yTop) * fr;
      final double sa = 1 - _ramp(t, 0.58, 0.64);
      for (final int side in <int>[-1, 1]) {
        final Offset o = Offset(c.dx + side * half(y), y);
        canvas.drawCircle(
          o,
          3.6,
          Paint()
            ..color = const Color(0xFFFFE08A).withValues(alpha: 0.75 * sa)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.4),
        );
        canvas.drawCircle(o, 1.5, Paint()..color = Colors.white.withValues(alpha: sa));
      }
    }

    // The star that says "you reached the top".
    final double st = g[4] * all;
    if (st > 0.05) {
      final double sr = h * 0.075 * (0.6 + 0.4 * st);
      final Offset so = Offset(c.dx, yTop - rh * 0.9);
      final Path star = Path()
        ..moveTo(so.dx, so.dy - sr)
        ..lineTo(so.dx + sr * 0.28, so.dy - sr * 0.28)
        ..lineTo(so.dx + sr, so.dy)
        ..lineTo(so.dx + sr * 0.28, so.dy + sr * 0.28)
        ..lineTo(so.dx, so.dy + sr)
        ..lineTo(so.dx - sr * 0.28, so.dy + sr * 0.28)
        ..lineTo(so.dx - sr, so.dy)
        ..lineTo(so.dx - sr * 0.28, so.dy - sr * 0.28)
        ..close();
      canvas.drawPath(star, Paint()..color = const Color(0xFFFFF3C4).withValues(alpha: math.min(1.0, st * 1.4)));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GlowLadder o) => o.t != t || o.boost != boost;
}

/// The thin climb ring, in gold: a faint full circle and the climbed
/// part on top (a plain arc, so there is no pale disc behind the icon).
class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.news);

  final double value;
  final bool news;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect box = (Offset.zero & size).deflate(1.5);
    canvas.drawArc(
      box,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0x40B9801F),
    );
    canvas.drawArc(
      box,
      -math.pi / 2,
      math.pi * 2 * value.clamp(0.02, 1.0),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2.6
        ..color = news ? const Color(0xFFFFC94D) : const Color(0xFFE0A02C),
    );
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.value != value || o.news != news;
}

// END OF FILE - lib/widgets/ladder_button.dart
