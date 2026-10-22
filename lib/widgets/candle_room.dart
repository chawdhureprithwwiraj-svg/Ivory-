import 'dart:math' as math;

import 'package:flutter/material.dart';

/// ============================================================
/// IVORY - THE CANDLE ROOM
///
/// A candlelight dinner painted at the top of the Private Line:
/// three candles on a polished table - two cast wax, one little
/// gold tealight - each flame built of three truths (the blue root,
/// the gold body, the soft outer) and the table giving back a
/// blurred reflection of every flame.
///
/// ONE heartbeat drives everything: [CandleRoom.brightness] rises
/// and falls like a real flame breathing. When the flame stands up
/// the whole room brightens with it; when the flame sinks the room
/// goes a little gloomier - never dark, everything always visible.
/// The light overlay ([CandleRoomLight]) and the tableau read the
/// same value from the same controller, so they can never drift
/// apart. No images, no packages, no dark colour anywhere.
/// ============================================================
class CandleRoom {
  const CandleRoom._();

  /// One breath of the candle: two sines out of step, so the flame
  /// never repeats itself exactly. 0 = sunk, 1 = standing tall.
  static double brightness(double t) {
    final double b =
        0.5 + 0.32 * math.sin(t * math.pi * 2) + 0.18 * math.sin(t * math.pi * 4 + 1.3);
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
      Paint()..color = const Color(0xFF2A1608).withValues(alpha: 0.10 - 0.07 * b),
    );
    // And lifts with the flame: a warm wash from where the candles stand.
    final Rect glow = Rect.fromLTWH(
      size.width * 0.5 - size.width * 0.75,
      -size.height * 0.10,
      size.width * 1.5,
      size.height * 0.72,
    );
    canvas.drawRect(
      r,
      Paint()
        ..blendMode = BlendMode.plusLighter
        ..shader = RadialGradient(
          center: const Alignment(0, -0.72),
          radius: 1.05,
          colors: <Color>[
            const Color(0xFFFFC464).withValues(alpha: 0.10 + 0.16 * b),
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
    final double tableTop = h * 0.62;

    // The polished table.
    final Rect table = Rect.fromLTRB(0, tableTop, w, h);
    canvas.drawRect(
      table,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFFEAD9B4), Color(0xFFDFC79A), Color(0xFFD2B781)],
          stops: <double>[0, 0.5, 1],
        ).createShader(table),
    );
    canvas.drawRect(
      Rect.fromLTRB(w * 0.08, tableTop, w * 0.92, h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            const Color(0xFFFFFCF0).withValues(alpha: 0.5),
            const Color(0x00FFFCF0),
          ],
        ).createShader(Rect.fromLTRB(w * 0.08, tableTop, w * 0.92, h)),
    );
    // The pool of light on the table, breathing with the flame.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, tableTop + 6),
        width: w * 0.78,
        height: 46,
      ),
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            const Color(0xFFFFCE6E).withValues(alpha: 0.30 + 0.28 * b),
            const Color(0x00FFCE6E),
          ],
        ).createShader(
          Rect.fromCenter(center: Offset(w * 0.5, tableTop + 6), width: w * 0.78, height: 46),
        ),
    );

    _candle(canvas, w * 0.31, tableTop, 36, 118, 0.0, b, true);
    _candle(canvas, w * 0.53, tableTop, 34, 76, 0.37, b * 0.94, true);
    _tealight(canvas, w * 0.71, tableTop, 0.61, b);

    // Warm motes rising through the light.
    for (int i = 0; i < 3; i++) {
      final double f = (t * (0.5 + i * 0.17) + i * 0.31) % 1.0;
      final double x = w * (0.26 + i * 0.22) + 10 * math.sin(f * math.pi * 3 + i);
      final double y = tableTop - f * (tableTop - 10);
      final double a = 0.55 * math.sin(f * math.pi) * (0.5 + 0.5 * b);
      canvas.drawCircle(
        Offset(x, y),
        1.8,
        Paint()..color = const Color(0xFFF6DE9C).withValues(alpha: a),
      );
    }
  }

  /// One cast wax candle with its three-truth flame and reflection.
  void _candle(Canvas canvas, double cx, double tableTop, double cw, double ch,
      double phase, double b, bool reflect) {
    final Rect shaft = Rect.fromLTWH(cx - cw / 2, tableTop - ch, cw, ch);
    // The wax: light falling across a cylinder.
    canvas.drawRRect(
      RRect.fromRectAndRadius(shaft, const Radius.circular(6)),
      Paint()
        ..shader = LinearGradient(
          colors: <Color>[
            const Color(0xFFB5824F),
            const Color(0xFFE9C89B),
            const Color(0xFFFFF8E6),
            const Color(0xFFF6E3BC),
            const Color(0xFFC08E58),
          ],
          stops: const <double>[0, 0.16, 0.42, 0.66, 1],
        ).createShader(shaft),
    );
    // A run of wax down one side.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - cw / 2 - 2, tableTop - ch + 6, 6, ch * 0.2),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFFFFF8E6).withValues(alpha: 0.85),
    );
    // The melted rim and its lit pool.
    canvas.drawOval(
      Rect.fromLTWH(cx - cw / 2, tableTop - ch - 5, cw, 11),
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            const Color(0xFFFFE2A6),
            const Color(0xFFF3D9A8),
            const Color(0xFFDDB57E),
          ],
        ).createShader(Rect.fromLTWH(cx - cw / 2, tableTop - ch - 5, cw, 11)),
    );
    canvas.drawOval(
      Rect.fromLTWH(cx - cw * 0.3, tableTop - ch - 2, cw * 0.6, 6),
      Paint()
        ..color = const Color(0xFFFFD682).withValues(alpha: 0.55 + 0.4 * b),
    );
    // The wick.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 1.2, tableTop - ch - 13, 2.4, 9),
        const Radius.circular(1.2),
      ),
      Paint()..color = const Color(0xFF3A2A1A),
    );
    _flame(canvas, Offset(cx, tableTop - ch - 13), 1.0, phase, b);
    if (reflect) {
      // The table gives the flame back, blurred and humble.
      final Rect rr = Rect.fromLTWH(cx - 7, tableTop + 4, 14, 30);
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
  }

  /// The little gold cup with its small brave flame.
  void _tealight(Canvas canvas, double cx, double tableTop, double phase, double b) {
    final Rect cup = Rect.fromLTWH(cx - 17, tableTop - 15, 34, 15);
    canvas.drawRRect(
      RRect.fromRectAndRadius(cup, const Radius.circular(3)),
      Paint()
        ..shader = LinearGradient(
          colors: <Color>[
            const Color(0xFF8A5A16),
            const Color(0xFFE2B34C),
            const Color(0xFFFFF0BE),
            const Color(0xFFE2B34C),
            const Color(0xFF8A5A16),
          ],
          stops: const <double>[0, 0.3, 0.5, 0.7, 1],
        ).createShader(cup),
    );
    _flame(canvas, Offset(cx, tableTop - 16), 0.62, phase, b);
    final Rect rr = Rect.fromLTWH(cx - 5, tableTop + 3, 10, 16);
    canvas.drawRect(
      rr,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.topCenter,
          colors: <Color>[
            const Color(0xFFFFE296).withValues(alpha: 0.08 + 0.10 * b),
            const Color(0x00FFE296),
          ],
        ).createShader(rr),
    );
  }

  /// Three truths: the blue root, the gold body, the soft outer -
  /// swaying on a slow rhythm with a quicker tremble inside, and
  /// standing up or sinking with the breath [b].
  void _flame(Canvas canvas, Offset base, double scale, double phase, double b) {
    final double sway = 0.05 * math.sin(t * math.pi * 2 + phase * 6) +
        0.02 * math.sin(t * math.pi * 7.4 + phase * 9);
    final double trem = 1 + 0.02 * math.sin(t * math.pi * 14.6 + phase * 5);
    final double rise = (0.86 + 0.24 * b) * trem * scale;
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(sway);
    canvas.scale(1, rise);
    // The halo the flame lends the air.
    final Rect halo = Rect.fromCenter(center: const Offset(0, -16), width: 116, height: 116);
    canvas.drawOval(
      halo,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            const Color(0xFFFFC464).withValues(alpha: 0.16 + 0.22 * b),
            const Color(0x00FFC464),
          ],
        ).createShader(halo),
    );
    // The soft outer.
    final Path outer = _tear(9, 34);
    canvas.drawPath(
      outer,
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
              size: const Size(double.infinity, 208),
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
