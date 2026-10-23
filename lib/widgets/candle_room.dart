import 'dart:math' as math;

import 'package:flutter/material.dart';

/// ============================================================
/// IVORY - THE CANDLE ROOM
///
/// A candlelight dinner at the top of the Private Line: two cast
/// wax candles and a gold tealight on a polished table. The wax
/// is a cylinder - light across it, shade at its foot, a rim-light
/// from its own flame on its shoulder, a contact shadow beneath,
/// a blurred reflection in the table. Each flame is three truths:
/// the blue root, the gold body, the soft outer.
/// ONE heartbeat drives everything: [CandleRoom.brightness] rises
/// and falls like a real flame breathing; the room's light
/// ([CandleRoomLight]) and the tableau read the same value from
/// the same controller, so flame and room can never drift apart.
/// Flame up = the room brightens; flame down = a touch gloomier,
/// never dark, everything visible. No images, packages or black.
/// ============================================================
class CandleRoom {
  const CandleRoom._();

  /// One breath of the candle: two sines out of step, so the flame
  /// never repeats itself exactly. 0 = sunk, 1 = standing tall.
  static double brightness(double t) {
    final double b =
        0.5 + 0.34 * math.sin(t * math.pi * 2) + 0.16 * math.sin(t * math.pi * 4 + 1.3);
    return b < 0 ? 0 : (b > 1 ? 1 : b);
  }
}

/// The light the candles lend the whole room. Sits above the page,
/// ignores every touch, and breathes with [CandleRoom.brightness].
class CandleRoomLight extends CustomPainter {
  const CandleRoomLight(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final double b = CandleRoom.brightness(t);
    final Rect r = Offset.zero & size;
    // The room sinks a little when the flame does - warm, never black.
    canvas.drawRect(
      r,
      Paint()..color = const Color(0xFF2A1608).withValues(alpha: 0.13 - 0.09 * b),
    );
    // And lifts with the flame: a warm wash from where the candles stand.
    final Rect glow = Rect.fromLTWH(
      -size.width * 0.25,
      -size.height * 0.10,
      size.width * 1.5,
      size.height * 0.75,
    );
    canvas.drawRect(
      r,
      Paint()
        ..blendMode = BlendMode.screen
        ..shader = RadialGradient(
          center: const Alignment(0, -0.70),
          radius: 1.05,
          colors: <Color>[
            const Color(0xFFFFC464).withValues(alpha: 0.08 + 0.20 * b),
            const Color(0x00FFC464),
          ],
        ).createShader(glow),
    );
  }

  @override
  bool shouldRepaint(CandleRoomLight old) => old.t != t;
}

/// The tableau itself: candles, flames, table, reflections, motes.
class CandleTableau extends CustomPainter {
  const CandleTableau(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double b = CandleRoom.brightness(t);
    final double tableTop = h * 0.78;

    // Depth behind the candles: a warm vignette and two far bokeh
    // lights, so the room has a behind as well as a before.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, 0.35),
          radius: 1.05,
          colors: <Color>[
            const Color(0xFFFFE9BC).withValues(alpha: 0.55 + 0.25 * b),
            const Color(0x40E9D3A6), const Color(0x00E9D3A6)],
          stops: const <double>[0, 0.55, 1],
        ).createShader(Offset.zero & size),
    );
    for (int i = 0; i < 2; i++) {
      final Offset o = Offset(w * (0.16 + i * 0.66), h * (0.20 + i * 0.10));
      final double r = 16 + i * 8;
      canvas.drawCircle(
        o,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: <Color>[
              const Color(0xFFFFDF9E).withValues(alpha: 0.10 + 0.10 * b),
              const Color(0x00FFDF9E),
            ],
          ).createShader(Rect.fromCircle(center: o, radius: r)),
      );
    }

    // The polished table.
    final Rect table = Rect.fromLTRB(0, tableTop, w, h);
    canvas.drawRect(
      table,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFFE4CF9F), Color(0xFFD6BC85), Color(0xFFC4A668)],
          stops: <double>[0, 0.45, 1],
        ).createShader(table),
    );
    // The linen runner and its sheen.
    final Rect runner = Rect.fromLTRB(w * 0.07, tableTop, w * 0.93, h);
    canvas.drawRect(
      runner,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[const Color(0x8CFFFCF0), const Color(0x33FFFCF0)],
        ).createShader(runner),
    );
    // The pool of light on the table, breathing with the flame.
    final Rect pool = Rect.fromCenter(
        center: Offset(w * 0.5, tableTop + 8), width: w * 0.85, height: 52);
    canvas.drawOval(
      pool,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            const Color(0xFFFFCE6E).withValues(alpha: 0.28 + 0.34 * b),
            const Color(0x00FFCE6E),
          ],
        ).createShader(pool),
    );

    _candle(canvas, w * 0.30, tableTop, 34, 92, 0.0, b);
    _candle(canvas, w * 0.52, tableTop, 31, 60, 0.37, b * 0.94);
    _tealight(canvas, w * 0.70, tableTop, 0.61, b);

    // Warm motes rising through the light.
    for (int i = 0; i < 4; i++) {
      final double f = (t * (0.45 + i * 0.13) + i * 0.27) % 1.0;
      final double x = w * (0.22 + i * 0.18) + 12 * math.sin(f * math.pi * 3 + i);
      final double y = tableTop - 8 - f * (tableTop - 26);
      final double a = 0.6 * math.sin(f * math.pi) * (0.45 + 0.55 * b);
      canvas.drawCircle(Offset(x, y), 1.7,
          Paint()..color = const Color(0xFFF6DE9C).withValues(alpha: a));
    }
  }

  /// One cast wax candle: cylinder light, contact shadow, rim-light
  /// from its own flame, three-truth flame, reflection in the table.
  void _candle(Canvas canvas, double cx, double tableTop, double cw, double ch,
      double phase, double b) {
    // Contact shadow: the candle stands ON something.
    final Rect cs = Rect.fromCenter(
      center: Offset(cx, tableTop + 3),
      width: cw * 2.5,
      height: 12,
    );
    canvas.drawOval(
      cs,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            const Color(0xFF6B4A1E).withValues(alpha: 0.34),
            const Color(0x006B4A1E),
          ],
        ).createShader(cs),
    );
    final Rect shaft = Rect.fromLTWH(cx - cw / 2, tableTop - ch, cw, ch);
    // The wax cylinder: seven stops of light falling across.
    canvas.drawRRect(
      RRect.fromRectAndRadius(shaft, const Radius.circular(6)),
      Paint()
        ..shader = LinearGradient(
          colors: <Color>[const Color(0xFF9A6B3C), const Color(0xFFDDB488),
            const Color(0xFFFFF6E2), const Color(0xFFFBEBC8),
            const Color(0xFFE2BE8C), const Color(0xFFA97844)],
          stops: const <double>[0, 0.14, 0.38, 0.55, 0.82, 1],
        ).createShader(shaft),
    );
    // Ambient: the foot of the candle sits in shade.
    canvas.drawRRect(
      RRect.fromRectAndRadius(shaft, const Radius.circular(6)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            const Color(0x00593A17),
            const Color(0x59593A17),
          ],
        ).createShader(shaft),
    );
    // A run of wax down one side.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - cw / 2 - 1.5, tableTop - ch + 7, 5, ch * 0.22),
        const Radius.circular(2.5),
      ),
      Paint()..color = const Color(0xFFFFF6E2).withValues(alpha: 0.9),
    );
    // The melted rim and its lit pool.
    final Rect rim = Rect.fromLTWH(cx - cw / 2, tableTop - ch - 5, cw, 10);
    canvas.drawOval(
      rim,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            const Color(0xFFFFE2A6),
            const Color(0xFFF0D19C),
            const Color(0xFFC99B62),
          ],
        ).createShader(rim),
    );
    canvas.drawOval(
      Rect.fromLTWH(cx - cw * 0.3, tableTop - ch - 2, cw * 0.6, 5),
      Paint()..color = const Color(0xFFFFD682).withValues(alpha: 0.5 + 0.45 * b),
    );
    // Rim-light: the flame warms the shoulder of its own wax.
    final Rect shoulder = Rect.fromLTWH(cx - cw / 2, tableTop - ch - 2, cw, ch * 0.4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(shoulder, const Radius.circular(6)),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.9),
          radius: 1.1,
          colors: <Color>[
            const Color(0xFFFFC464).withValues(alpha: 0.20 + 0.25 * b),
            const Color(0x00FFC464),
          ],
        ).createShader(shoulder),
    );
    // The wick.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 1.2, tableTop - ch - 12, 2.4, 8),
        const Radius.circular(1.2),
      ),
      Paint()..color = const Color(0xFF3A2A1A),
    );
    _flame(canvas, Offset(cx, tableTop - ch - 12), 1.0, phase, b);
    // The table gives wax and flame back, blurred and humble.
    final Rect rr = Rect.fromLTWH(cx - cw / 2, tableTop + 2, cw, ch * 0.5);
    canvas.drawRect(
      rr,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            const Color(0xFFFFE9BE).withValues(alpha: 0.20 + 0.10 * b),
            const Color(0x00FFE9BE),
          ],
        ).createShader(rr),
    );
    final Rect fr = Rect.fromLTWH(cx - 6, tableTop + 2, 12, 26);
    canvas.drawRect(
      fr,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.topCenter,
          colors: <Color>[
            const Color(0xFFFFE296).withValues(alpha: 0.14 + 0.16 * b),
            const Color(0x00FFE296),
          ],
        ).createShader(fr),
    );
  }

  /// The little gold cup with its small brave flame.
  void _tealight(Canvas canvas, double cx, double tableTop, double phase, double b) {
    final Rect cs = Rect.fromCenter(
      center: Offset(cx, tableTop + 3),
      width: 62,
      height: 10,
    );
    canvas.drawOval(
      cs,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            const Color(0xFF6B4A1E).withValues(alpha: 0.30),
            const Color(0x006B4A1E),
          ],
        ).createShader(cs),
    );
    final Rect cup = Rect.fromLTWH(cx - 16, tableTop - 14, 32, 14);
    canvas.drawRRect(
      RRect.fromRectAndRadius(cup, const Radius.circular(3)),
      Paint()
        ..shader = LinearGradient(
          colors: <Color>[const Color(0xFF7A4A12), const Color(0xFFE2B34C),
            const Color(0xFFFFF0BE), const Color(0xFFE2B34C), const Color(0xFF7A4A12)],
          stops: const <double>[0, 0.3, 0.5, 0.7, 1],
        ).createShader(cup),
    );
    canvas.drawOval(
      Rect.fromLTWH(cx - 16, tableTop - 16, 32, 5),
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            const Color(0xFFFFE9BE).withValues(alpha: 0.6 + 0.3 * b),
            const Color(0xFFC9962C),
          ],
        ).createShader(Rect.fromLTWH(cx - 16, tableTop - 16, 32, 5)),
    );
    _flame(canvas, Offset(cx, tableTop - 15), 0.6, phase, b);
    final Rect rr = Rect.fromLTWH(cx - 5, tableTop + 2, 10, 14);
    canvas.drawRect(
      rr,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.topCenter,
          colors: <Color>[
            const Color(0xFFFFE296).withValues(alpha: 0.10 + 0.12 * b),
            const Color(0x00FFE296),
          ],
        ).createShader(rr),
    );
  }

  /// Three truths: the blue root, the gold body, the soft outer -
  /// swaying on a slow rhythm with a quicker tremble inside, and
  /// standing up or sinking with the breath [b].
  void _flame(Canvas canvas, Offset base, double scale, double phase, double b) {
    final double sway = 0.07 * math.sin(t * math.pi * 2 + phase * 6) +
        0.03 * math.sin(t * math.pi * 7.4 + phase * 9);
    final double trem = 1 + 0.03 * math.sin(t * math.pi * 14.6 + phase * 5);
    final double rise = (0.78 + 0.34 * b) * trem * scale;
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(sway);
    canvas.scale(1, rise);
    // The halo the flame lends the air.
    final Rect halo = Rect.fromCenter(center: const Offset(0, -18), width: 130, height: 130);
    canvas.drawOval(
      halo,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            const Color(0xFFFFC464).withValues(alpha: 0.14 + 0.30 * b),
            const Color(0x00FFC464),
          ],
        ).createShader(halo),
    );
    // The soft outer.
    canvas.drawPath(
      _tear(9, 34),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, 0.55),
          radius: 0.85,
          colors: <Color>[
            const Color(0xFFFFF6D6).withValues(alpha: 0.95),
            const Color(0xFFFFD66E).withValues(alpha: 0.85),
            const Color(0xFFFF9E2C).withValues(alpha: 0.55),
            const Color(0x00FF7814),
          ],
          stops: const <double>[0, 0.34, 0.6, 0.8],
        ).createShader(Rect.fromLTRB(-9, -34, 9, 2)),
    );
    // The gold body.
    canvas.drawPath(
      _tear(6, 26),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, 0.6),
          radius: 0.8,
          colors: <Color>[
            const Color(0xFFFFFDF2),
            const Color(0xFFFFE9A8),
            const Color(0x00FFB63E),
          ],
          stops: const <double>[0, 0.45, 0.95],
        ).createShader(Rect.fromLTRB(-6, -26, 6, 1)),
    );
    // The blue root.
    canvas.drawOval(
      Rect.fromLTRB(-3.4, -9, 3.4, 0.5),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, 0.4),
          colors: <Color>[
            const Color(0xFFD6F0FF).withValues(alpha: 0.95),
            const Color(0xFF7EBEFF).withValues(alpha: 0.55),
            const Color(0x007EBEFF),
          ],
        ).createShader(Rect.fromLTRB(-3.4, -9, 3.4, 0.5)),
    );
    canvas.restore();
  }

  /// A teardrop standing on the wick: wide low, pointed high.
  Path _tear(double hw, double hgt) {
    return Path()
      ..moveTo(0, 1)
      ..cubicTo(-hw, 1 - hgt * 0.28, -hw * 0.92, -hgt * 0.62, 0, -hgt)
      ..cubicTo(hw * 0.92, -hgt * 0.62, hw, 1 - hgt * 0.28, 0, 1)
      ..close();
  }

  @override
  bool shouldRepaint(CandleTableau old) => old.t != t;
}

/// The opening of the Private Line: the tableau, the gold rule and
/// the whispered line beneath it.
class CandleRoomOpening extends StatelessWidget {
  const CandleRoomOpening({super.key, required this.flick});

  final Animation<double> flick;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: flick,
      builder: (BuildContext context, Widget? child) {
        return Column(
          children: <Widget>[
            CustomPaint(
              size: const Size(double.infinity, 236),
              painter: CandleTableau(flick.value),
            ),
            const SizedBox(height: 4),
            CustomPaint(
              size: const Size(double.infinity, 10),
              painter: _RulePainter(),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 7),
              child: Text(
                'a table laid for two, and the second place is yours',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 1.3,
                  color: Color(0xFF6A8A7C),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RulePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final Rect r = Rect.fromLTRB(cx - 60, 4, cx + 60, 6);
    canvas.drawRect(
      r,
      Paint()
        ..shader = LinearGradient(
          colors: <Color>[
            const Color(0x00C9962C),
            const Color(0xFFC9962C),
            const Color(0x00C9962C),
          ],
        ).createShader(r),
    );
    final Path d = Path()
      ..moveTo(cx, 0)
      ..lineTo(cx + 4, 5)
      ..lineTo(cx, 10)
      ..lineTo(cx - 4, 5)
      ..close();
    canvas.drawPath(d, Paint()..color = const Color(0xFFC9962C));
  }

  @override
  bool shouldRepaint(_RulePainter old) => false;
}

// END OF FILE - lib/widgets/candle_room.dart
