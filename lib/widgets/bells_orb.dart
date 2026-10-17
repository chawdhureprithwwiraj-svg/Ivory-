import 'package:flutter/material.dart';

import '../models/bell_models.dart';
import 'bell_paint.dart';

class _BellOrbData {
  static const List<IconData> icons = <IconData>[
    Icons.favorite_rounded,
    Icons.menu_book_rounded,
    Icons.groups_rounded,
    Icons.nightlight_round,
  ];
  static const List<String> names = <String>[
    'GREET',
    'READ',
    'JOIN IN',
    'OPEN LINE',
  ];
}

/// ============================================================
/// IVORY - THE ROUND BUTTON UNDER EACH BELL
///
/// A glossy jewel-coloured orb with an icon, its name and a small line
/// telling the member whether to tap it, when it opens, or that it has
/// rung. Also holds the rainbow rope the four bells hang from.
/// ============================================================
class BellOrb extends StatelessWidget {
  const BellOrb({
    super.key,
    required this.bellKey,
    required this.item,
    required this.isRung,
    required this.onTap,
  });

  final String bellKey;
  final BellItem? item;
  final bool isRung;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String key = bellKey;
    final BellItem? it = item;
    final bool rung = isRung;
    final int i = BellTones.keys.indexOf(key);
    final Color c = BellTones.of(i);
    final String time = it?.timeLabel ?? '';
    String sub;
    if (rung) {
      sub = 'rung';
    } else if (it != null && !it.isOpen) {
      sub = it.done && !it.isLine ? 'ready at $time' : 'opens $time';
    } else {
      sub = 'tap to ring';
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: rung ? null : onTap,
      child: Opacity(
        opacity: rung ? 0.5 : 1,
        child: SizedBox(
          width: 78,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.3, -0.45),
                    colors: <Color>[
                      Colors.white,
                      c,
                      BellTones.mix(c, BellTones.deep, 0.45),
                    ],
                    stops: const <double>[0, 0.52, 1],
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(color: c.withValues(alpha: 0.7), blurRadius: 18),
                  ],
                ),
                child: Icon(
                  rung ? Icons.check_rounded : _BellOrbData.icons[i],
                  color: BellTones.deep,
                  size: 26,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _BellOrbData.names[i],
                style: const TextStyle(
                  color: Color(0xFFEDE6FF),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                sub,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFBFB0F0), fontSize: 9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BellRopePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final Path p = Path()
      ..moveTo(0, 56)
      ..quadraticBezierTo(w / 2, -12, w, 56);
    canvas.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.4
        ..strokeCap = StrokeCap.round
        ..shader = const LinearGradient(
          colors: <Color>[
            Color(0xFFFF8FB5),
            Color(0xFF8FE3FF),
            Color(0xFFB6FFD2),
            Color(0xFFFFD59B),
          ],
          stops: <double>[0, 0.35, 0.7, 1],
        ).createShader(Rect.fromLTWH(0, 0, w, 60)),
    );
  }

  @override
  bool shouldRepaint(BellRopePainter o) => false;
}

// END OF FILE - lib/widgets/bells_orb.dart
