import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'wheel_fx.dart';
import 'wheel_painter.dart';

/// The floating Wheel of Fans medallion — present at every hour on every
/// member screen, never a gate. In the Gilded Hours it breathes, turns
/// slowly and sprinkles gold dust; outside them it rests warm and quiet,
/// a promise of the hour to come. Tap opens the wheel room (the ceremony
/// inside the hours, the salon outside them).
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
      duration: const Duration(seconds: widget.open ? 7 : 11))
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
                1.0 + (open ? 0.055 : 0.022) * math.sin(_t.value * 6.283);
            return Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                if (open)
                  Positioned(
                    left: -26,
                    top: -30,
                    right: -26,
                    bottom: -26,
                    child: GoldDust(count: 12),
                  ),
                Transform.scale(
                  scale: breath,
                  child: Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: const Alignment(-0.3, -0.35),
                        colors: open
                            ? const <Color>[
                                Color(0xFFFFF3D0),
                                Color(0xFFE7B14C),
                                Color(0xFF8A5E1C)
                              ]
                            : const <Color>[
                                Color(0xFFF3E4C2),
                                Color(0xFFC9A05A),
                                Color(0xFF7A5216)
                              ],
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: const Color(0xFFE7B14C)
                              .withOpacity(open ? 0.55 : 0.22),
                          blurRadius: open ? 22 : 10,
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
                          WheelSeg('₹3', Color(0xFFFFB300), 'rupee'),
                          WheelSeg('', Color(0xFFFF4081), 'word'),
                          WheelSeg('₹7', Color(0xFFFF7A00), 'rupee'),
                          WheelSeg('', Color(0xFFC0B7A6), 'rest'),
                          WheelSeg('₹15', Color(0xFF00C853), 'rupee'),
                          WheelSeg('', Color(0xFFC2185B), 'image'),
                          WheelSeg('₹21', Color(0xFFD50000), 'rupee'),
                          WheelSeg('', Color(0xFFE91E63), 'letter'),
                          WheelSeg('', Color(0xFFB0A692), 'rest'),
                          WheelSeg('', Color(0xFFAD1457), 'voice'),
                          WheelSeg('', Color(0xFFE7B14C), 'choice'),
                          WheelSeg('', Color(0xFFFF6E40), 'moment'),
                        ],
                        angle: _t.value * (open ? 1.4 : 0.35),
                        shine: _t.value,
                        dim: !open,
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
