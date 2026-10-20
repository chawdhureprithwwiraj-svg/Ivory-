import 'dart:math' as math;

import 'package:flutter/material.dart';


/// ============================================================
/// IVORY - THE EARLY DOOR IN AMETHYST AND GOLD
///
/// The door on the Home card, rebuilt as a jewel: an arched door of
/// royal amethyst velvet with inlaid gold lines and a round gold knob
/// (lit like a bead), a polished gold frame, and warm champagne light
/// that spills through the doorway with gold motes drifting up in it.
/// It swings open by itself when it first appears, and afterwards it
/// breathes: the door drifts a hair's width, the light swells, a sheen
/// slides over the panel and the frame glints. Pure painting.
/// The inside of the Early Door sheet keeps its own door ([EarlyDoorView]).
/// ============================================================
class AmethystDoor extends StatefulWidget {
  const AmethystDoor({
    super.key,
    required this.openness,
    this.width = 84,
    this.height = 104,
  });

  /// 0 = shut, 1 = wide open (see [earlyOpenness]).
  final double openness;
  final double width;
  final double height;

  @override
  State<AmethystDoor> createState() => _AmethystDoorState();
}

class _AmethystDoorState extends State<AmethystDoor>
    with TickerProviderStateMixin {
  late final AnimationController _swing = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  )..repeat();
  late Animation<double> _open;

  @override
  void initState() {
    super.initState();
    _open = CurvedAnimation(
      parent: _swing,
      curve: Curves.easeOutCubic,
    ).drive(Tween<double>(begin: 0, end: widget.openness));
    _swing.forward();
  }

  @override
  void didUpdateWidget(AmethystDoor old) {
    super.didUpdateWidget(old);
    if (old.openness != widget.openness) {
      final double from = _open.value;
      _open = CurvedAnimation(
        parent: _swing,
        curve: Curves.easeOutCubic,
      ).drive(Tween<double>(begin: from, end: widget.openness));
      _swing.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _swing.dispose();
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size(widget.width, widget.height),
        painter: _AmethystPainter(open: _open, breath: _breath),
      ),
    );
  }
}

class _AmethystPainter extends CustomPainter {
  _AmethystPainter({required this.open, required this.breath})
    : super(repaint: Listenable.merge(<Listenable>[open, breath]));

  final Animation<double> open;
  final Animation<double> breath;

  static const Color _gold = Color(0xFFFFD34D);
  static const Color _goldDeep = Color(0xFFC98600);
  static const Color _goldPale = Color(0xFFFFF3B0);

  Path _arch(Rect r) {
    final double rad = r.width / 2;
    return Path()
      ..moveTo(r.left, r.bottom)
      ..lineTo(r.left, r.top + rad)
      ..arcToPoint(Offset(r.right, r.top + rad), radius: Radius.circular(rad))
      ..lineTo(r.right, r.bottom)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double b = breath.value;
    final double pulse = 0.5 + 0.5 * math.sin(b * 2 * math.pi);
    final double base = open.value.clamp(0.0, 1.0).toDouble();
    // A door that is open drifts a hair's width, slowly.
    final double o = (base +
            0.03 * math.sin(b * 4 * math.pi) * math.min(1.0, base * 4))
        .clamp(0.0, 1.0)
        .toDouble();

    // The wall tile around the doorway.
    final Rect wall = Rect.fromLTWH(0, 0, w, h);
    final RRect tile = RRect.fromRectAndRadius(wall, Radius.circular(w * 0.18));
    canvas.drawRRect(
      tile,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF7C35C4), Color(0xFF4F1A8A)],
        ).createShader(wall),
    );
    canvas.drawRRect(
      tile.deflate(0.6),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = _gold.withValues(alpha: 0.55),
    );

    final Rect way = Rect.fromLTRB(w * 0.14, h * 0.08, w * 0.86, h * 0.94);
    final Path hole = _arch(way);

    // The champagne light inside the doorway.
    final double lit = 0.16 + 0.84 * o;
    canvas.save();
    canvas.clipPath(hole);
    canvas.drawRect(
      way,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.1, 0.35),
          radius: 0.95,
          colors: <Color>[
            const Color(0xFFFFFBEA).withValues(
              alpha: (0.6 + 0.4 * lit) * (0.93 + 0.07 * pulse),
            ),
            const Color(0xFFFFE29A).withValues(alpha: 0.4 + 0.5 * lit),
            const Color(0xFFD79BFF).withValues(alpha: 0.7),
          ],
          stops: const <double>[0, 0.5, 1],
        ).createShader(way),
    );
    if (o > 0.04) {
      for (int i = 0; i < 4; i++) {
        final double a = (i - 1.5) * 0.3;
        canvas.drawPath(
          Path()
            ..moveTo(way.center.dx, way.top + 2)
            ..lineTo(
              way.center.dx + math.sin(a - 0.07) * way.height * 1.1,
              way.bottom,
            )
            ..lineTo(
              way.center.dx + math.sin(a + 0.07) * way.height * 1.1,
              way.bottom,
            )
            ..close(),
          Paint()
            ..color = const Color(0xFFFFFFFF).withValues(
              alpha: (0.1 + 0.14 * pulse) * o * (i.isEven ? 1.0 : 0.7),
            ),
        );
      }
      // Gold motes drifting up through the light.
      for (int i = 0; i < 9; i++) {
        final double ph = i / 9.0;
        final double t = (b * (1 + (i % 3) * 0.5) + ph) % 1.0;
        final double x =
            way.center.dx +
            math.sin((t * 2 + ph) * math.pi * 2) * way.width * 0.27;
        final double y = way.bottom - t * way.height * 0.88;
        final double fade = math.sin(t * math.pi);
        canvas.drawCircle(
          Offset(x, y),
          0.9 + (i % 3) * 0.5,
          Paint()
            ..color = (i.isEven ? _gold : const Color(0xFFFFFFFF)).withValues(
              alpha: 0.9 * fade * o,
            ),
        );
      }
    }
    canvas.restore();

    // The door, hinged on the left, swinging away.
    final double ang = o * 1.22;
    final double cosA = math.cos(ang);
    final double pw = way.width * cosA;
    if (pw > 1.5) {
      canvas.save();
      canvas.clipPath(hole);
      final Matrix4 squeeze = Matrix4(
        cosA, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        way.left * (1 - cosA), 0, 0, 1,
      );
      final Path panel = hole.transform(squeeze.storage);
      final Rect pb = panel.getBounds();
      canvas.drawPath(
        panel,
        Paint()
          ..shader = const LinearGradient(
            colors: <Color>[
              Color(0xFFB06CF0),
              Color(0xFF8A3FD1),
              Color(0xFF5A1B96),
            ],
            stops: <double>[0, 0.45, 1],
          ).createShader(pb),
      );
      // Inlaid gold panels.
      final Paint inlay = Paint()
        ..color = _gold.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1;
      if (pw > 8) {
        for (final List<double> f in const <List<double>>[
          <double>[0.34, 0.58],
          <double>[0.66, 0.86],
        ]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTRB(
                way.left + pw * 0.16,
                way.top + way.height * f[0],
                way.left + pw * 0.84,
                way.top + way.height * f[1],
              ),
              const Radius.circular(2),
            ),
            inlay,
          );
        }
      }
      // A sheen sliding down the panel.
      final double sp = -0.3 + 1.6 * ((b * 1.0) % 1.0);
      double st(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);
      canvas.drawRect(
        pb,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              const Color(0x00FFFFFF),
              const Color(0xFFFFFFFF).withValues(alpha: 0.32),
              const Color(0x00FFFFFF),
            ],
            stops: <double>[st(sp - 0.14), st(sp), st(sp + 0.14)],
          ).createShader(pb),
      );
      // The door's thick edge, and the light that catches it.
      final double ex = way.left + pw;
      canvas.drawLine(
        Offset(ex, way.top + way.width / 2),
        Offset(ex, way.bottom),
        Paint()
          ..color = const Color(0xFF3A0F6B).withValues(alpha: 0.55)
          ..strokeWidth = 3.2,
      );
      canvas.drawLine(
        Offset(ex - 1.2, way.top + way.width / 2),
        Offset(ex - 1.2, way.bottom),
        Paint()
          ..color = _goldPale.withValues(alpha: 0.5 + 0.4 * o)
          ..strokeWidth = 1.3,
      );
      // The gold knob, lit like a bead.
      if (pw > 10) {
        final Offset k = Offset(ex - 5, way.top + way.height * 0.57);
        canvas.drawCircle(
          k.translate(0.6, 1.2),
          3.4,
          Paint()..color = const Color(0xFF3A0F6B).withValues(alpha: 0.5),
        );
        canvas.drawCircle(
          k,
          3.4,
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(-0.4, -0.5),
              colors: const <Color>[_goldPale, _gold, _goldDeep],
              stops: const <double>[0, 0.45, 1],
            ).createShader(Rect.fromCircle(center: k, radius: 3.4)),
        );
      }
      canvas.restore();
    }

    // The polished gold frame, and the light that spills on the floor.
    canvas.drawPath(
      hole,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[_goldPale, _gold, _goldDeep, _gold],
        ).createShader(way),
    );
    final double glint = math.pow(
      math.max(0.0, math.sin(2 * math.pi * (b * 2 + 0.3))),
      8,
    ).toDouble();
    if (glint > 0.05) {
      final Offset g = Offset(way.left + 3, way.top + way.width * 0.55);
      final Paint sp = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.95 * glint)
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round;
      final double len = 3 + 5 * glint;
      canvas.drawLine(g.translate(-len, 0), g.translate(len, 0), sp);
      canvas.drawLine(g.translate(0, -len), g.translate(0, len), sp);
    }
    final double spill = 0.14 + 0.86 * o;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.955),
        width: w * (0.34 + 0.6 * spill),
        height: h * (0.035 + 0.05 * spill),
      ),
      Paint()
        ..color = const Color(0xFFFFF3B0).withValues(
          alpha: (0.3 + 0.5 * spill) * (0.9 + 0.1 * pulse),
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  @override
  bool shouldRepaint(_AmethystPainter old) => false;
}

// END OF FILE - lib/widgets/amethyst_door.dart
