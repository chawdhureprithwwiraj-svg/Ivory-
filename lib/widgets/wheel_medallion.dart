import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'wheel_fx.dart';
import 'wheel_painter.dart';

/// The floating Wheel of Fans medallion — present at every hour on every
/// member screen, never a gate. It is a true miniature of the wheel:
/// jewel studs and cast gold, no labels, turning slowly and regally at
/// all hours (faster and dusted with gold inside the Gilded Hours), set
/// in a cream halo ring so it reads as a sealed court button wherever
/// it floats. Tap opens the wheel room (the ceremony inside the hours,
/// the salon outside them).
class WheelMedallion extends StatefulWidget {
  const WheelMedallion({super.key, required this.open, required this.onTap});
  final bool open;
  final VoidCallback onTap;

  @override
  State<WheelMedallion> createState() => _WheelMedallionState();
}

class _WheelMedallionState extends State<WheelMedallion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.open ? 7 : 11))
    ..repeat();

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool open = widget.open;
    return GestureDetector(
      onTap: widget.onTap,
      child: Semantics(
        button: true,
        label: 'Wheel of Fans',
        child: AnimatedBuilder(
          animation: _t,
          builder: (BuildContext context, Widget? _) {
            final double breath =
                1.0 + (open ? 0.05 : 0.02) * math.sin(_t.value * 6.283);
            return Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                if (open)
                  const Positioned(
                    left: -26,
                    top: -30,
                    right: -26,
                    bottom: -26,
                    child: GoldDust(count: 12),
                  ),
                Transform.scale(
                  scale: breath,
                  child: Container(
                    width: 60,
                    height: 60,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFF6E5),
                      border: Border.all(
                          color: const Color(0xFFE7B14C), width: 1.6),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: const Color(0xFFE7B14C)
                              .withOpacity(open ? 0.60 : 0.30),
                          blurRadius: open ? 22 : 12,
                          spreadRadius: open ? 3 : 1,
                        ),
                        const BoxShadow(
                            color: Color(0x59200A10),
                            blurRadius: 8,
                            offset: Offset(0, 4)),
                      ],
                    ),
                    child: CustomPaint(
                      painter: WheelPainter(
                        segs: const <WheelSeg>[
                          WheelSeg('', Color(0xFFFFB300), 'rupee'),
                          WheelSeg('', Color(0xFFFF4081), 'word'),
                          WheelSeg('', Color(0xFFFF7A00), 'rupee'),
                          WheelSeg('', Color(0xFF00BFA5), 'rest'),
                          WheelSeg('', Color(0xFF00C853), 'rupee'),
                          WheelSeg('', Color(0xFF7C4DFF), 'image'),
                          WheelSeg('', Color(0xFFD50000), 'rupee'),
                          WheelSeg('', Color(0xFFE91E63), 'letter'),
                          WheelSeg('', Color(0xFF00BFA5), 'rest'),
                          WheelSeg('', Color(0xFFAD1457), 'voice'),
                          WheelSeg('', Color(0xFFE7B14C), 'choice'),
                          WheelSeg('', Color(0xFFFF6E40), 'moment'),
                        ],
                        angle: _t.value * (open ? 1.6 : 0.55),
                        shine: _t.value,
                        dim: !open,
                        mini: true,
                      ),
                    ),
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

// END OF FILE - lib/widgets/wheel_medallion.dart
