import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';

/// How wide the door stands for a number of early hours: shut just
/// before the first hour, wider with every hour, wide open at two days
/// or for a paid member.
double earlyOpenness(int hours) {
  if (hours <= 0) return 0;
  if (hours >= 48) return 1;
  return 0.22 + 0.78 * (hours / 48);
}

/// ============================================================
/// IVORY - THE EARLY DOOR, DRAWN
///
/// An arched emerald door that swings open on its left hinge, with
/// pearl light spilling out, a few motes drifting up through the
/// light and a brass knob. It opens by itself when it first appears
/// and the light breathes slowly. A shut door shows only a thin line
/// of light underneath it. Pure drawing: no pictures, no sound.
/// ============================================================
class EarlyDoorView extends StatefulWidget {
  const EarlyDoorView({
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
  State<EarlyDoorView> createState() => _EarlyDoorViewState();
}

class _EarlyDoorViewState extends State<EarlyDoorView>
    with TickerProviderStateMixin {
  late final AnimationController _swing = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();
  late Animation<double> _open;

  @override
  void initState() {
    super.initState();
    _open = CurvedAnimation(parent: _swing, curve: Curves.easeOutCubic)
        .drive(Tween<double>(begin: 0, end: widget.openness));
    _swing.forward();
  }

  @override
  void didUpdateWidget(EarlyDoorView old) {
    super.didUpdateWidget(old);
    if (old.openness != widget.openness) {
      final double from = _open.value;
      _open = CurvedAnimation(parent: _swing, curve: Curves.easeOutCubic)
          .drive(Tween<double>(begin: from, end: widget.openness));
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
        painter: _DoorPainter(open: _open, breath: _breath),
      ),
    );
  }
}

class _DoorPainter extends CustomPainter {
  _DoorPainter({required this.open, required this.breath})
    : super(repaint: Listenable.merge(<Listenable>[open, breath]));

  final Animation<double> open;
  final Animation<double> breath;

  static const Color _pearl = Color(0xFFFBFFF8);
  static const Color _wash = IvoryColors.emeraldWash;

  Path _arch(Rect r) {
    final double rad = r.width / 2;
    return Path()
      ..moveTo(r.left, r.bottom)
      ..lineTo(r.left, r.top + rad)
      ..arcToPoint(
        Offset(r.right, r.top + rad),
        radius: Radius.circular(rad),
      )
      ..lineTo(r.right, r.bottom)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double o = open.value.clamp(0.0, 1.0);
    final double pulse = 0.5 + 0.5 * math.sin(breath.value * 2 * math.pi);

    // The doorway.
    final Rect way = Rect.fromLTRB(w * 0.14, h * 0.08, w * 0.86, h * 0.94);
    final Path hole = _arch(way);

    // The wall around it.
    final Rect wall = Rect.fromLTWH(0, 0, w, h);
    canvas.drawRRect(
      RRect.fromRectAndRadius(wall, Radius.circular(w * 0.18)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[IvoryColors.emeraldMid, IvoryColors.emerald],
        ).createShader(wall),
    );

    // The light inside the doorway.
    final double lit = 0.14 + 0.86 * o;
    canvas.save();
    canvas.clipPath(hole);
    canvas.drawRect(
      way,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.1, 0.35),
          radius: 0.95,
          colors: <Color>[
            _pearl.withValues(alpha: (0.55 + 0.4 * lit) * (0.94 + 0.06 * pulse)),
            _wash.withValues(alpha: 0.35 + 0.45 * lit),
            IvoryColors.emeraldLight.withValues(alpha: 0.55),
          ],
          stops: const <double>[0.0, 0.5, 1.0],
        ).createShader(way),
    );
    // Rays fanning down from the top of the arch.
    if (o > 0.04) {
      for (int i = 0; i < 4; i++) {
        final double a = (i - 1.5) * 0.30;
        final Path ray = Path()
          ..moveTo(way.center.dx, way.top + 2)
          ..lineTo(way.center.dx + math.sin(a - 0.07) * way.height * 1.1,
              way.bottom)
          ..lineTo(way.center.dx + math.sin(a + 0.07) * way.height * 1.1,
              way.bottom)
          ..close();
        canvas.drawPath(
          ray,
          Paint()
            ..color = _pearl.withValues(
              alpha: (0.10 + 0.12 * pulse) * o * (i.isEven ? 1.0 : 0.7),
            ),
        );
      }
      // Motes drifting up through the light.
      for (int i = 0; i < 8; i++) {
        final double ph = i / 8.0;
        final double t = (breath.value * (1 + (i % 3) * 0.5) + ph) % 1.0;
        final double x = way.center.dx +
            math.sin((t * 2 + ph) * math.pi * 2) * way.width * 0.26;
        final double y = way.bottom - t * way.height * 0.85;
        final double fade = math.sin(t * math.pi);
        canvas.drawCircle(
          Offset(x, y),
          0.9 + (i % 3) * 0.5,
          Paint()..color = _pearl.withValues(alpha: 0.85 * fade * o),
        );
      }
    }
    canvas.restore();

    // The door itself, hinged on the left, swinging away.
    final double ang = o * 1.22;
    final double cosA = math.cos(ang);
    final double pw = way.width * cosA;
    if (pw > 1.5) {
      canvas.save();
      canvas.clipPath(hole);
      // Squeeze sideways about the hinge: x' = cosA * x + left * (1 - cosA).
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
          ..shader = LinearGradient(
            colors: <Color>[
              IvoryColors.emeraldMid,
              Color.lerp(IvoryColors.emerald, IvoryColors.emeraldMid, 0.4)!,
              IvoryColors.emerald,
            ],
          ).createShader(pb),
      );
      // Panels set into the door.
      final Paint line = Paint()
        ..color = IvoryColors.emeraldLight.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      if (pw > 8) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(way.left + pw * 0.16, way.top + way.height * 0.34,
                way.left + pw * 0.84, way.top + way.height * 0.58),
            const Radius.circular(2),
          ),
          line,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(way.left + pw * 0.16, way.top + way.height * 0.66,
                way.left + pw * 0.84, way.top + way.height * 0.86),
            const Radius.circular(2),
          ),
          line,
        );
      }
      // A bright edge where the door catches the light, and a brass knob.
      canvas.drawLine(
        Offset(way.left + pw, way.top + way.width / 2),
        Offset(way.left + pw, way.bottom),
        Paint()
          ..color = _pearl.withValues(alpha: 0.35 + 0.4 * o)
          ..strokeWidth = 1.6,
      );
      if (pw > 10) {
        canvas.drawCircle(
          Offset(way.left + pw - 4.5, way.top + way.height * 0.56),
          2.6,
          Paint()..color = IvoryColors.gold,
        );
        canvas.drawCircle(
          Offset(way.left + pw - 5.3, way.top + way.height * 0.56 - 0.8),
          0.9,
          Paint()..color = _pearl.withValues(alpha: 0.9),
        );
      }
      canvas.restore();
    }

    // The frame, and the light that spills onto the floor.
    canvas.drawPath(
      hole,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[_wash, IvoryColors.emeraldLight],
        ).createShader(way),
    );
    final double spill = 0.12 + 0.88 * o;
    final Rect floor = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.955),
      width: w * (0.34 + 0.6 * spill),
      height: h * (0.035 + 0.05 * spill),
    );
    canvas.drawOval(
      floor,
      Paint()
        ..color = _pearl.withValues(alpha: (0.25 + 0.5 * spill) * (0.9 + 0.1 * pulse))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  @override
  bool shouldRepaint(_DoorPainter old) => false;
}

// END OF FILE - lib/widgets/early_door_view.dart
