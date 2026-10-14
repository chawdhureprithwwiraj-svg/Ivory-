import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';

/// Circular crowned-lion art with a restrained animated ember/flame over each
/// eye. The effect is clipped to the source artwork and respects reduced
/// motion settings.
class LionEyeFireEmblem extends StatefulWidget {
  const LionEyeFireEmblem({
    super.key,
    required this.imageAsset,
    required this.size,
  });

  final String imageAsset;
  final double size;

  @override
  State<LionEyeFireEmblem> createState() => _LionEyeFireEmblemState();
}

class _LionEyeFireEmblemState extends State<LionEyeFireEmblem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fire = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 880),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _fire.stop();
      _fire.value = 0.32;
    } else if (!_fire.isAnimating) {
      _fire.repeat();
    }
  }

  @override
  void dispose() {
    _fire.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double size = widget.size;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: IvoryColors.gold, width: 1),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: IvoryColors.gold.withValues(alpha: 0.28),
            blurRadius: size * 0.42,
          ),
        ],
      ),
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Image.asset(
              widget.imageAsset,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              gaplessPlayback: true,
            ),
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _fire,
                builder: (BuildContext context, Widget? child) => CustomPaint(
                  painter: _LionEyeFirePainter(progress: _fire.value),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LionEyeFirePainter extends CustomPainter {
  const _LionEyeFirePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final double unit = math.min(size.width, size.height);
    if (unit <= 0) return;

    // Alignment measured against the 512 x 512 crowned-lion artwork.
    final List<Offset> eyes = <Offset>[
      Offset(size.width * 0.412, size.height * 0.412),
      Offset(size.width * 0.582, size.height * 0.412),
    ];
    for (int i = 0; i < eyes.length; i++) {
      final double phase = progress * math.pi * 2 + i * 0.72;
      final double pulse = 0.78 + 0.22 * math.sin(phase);
      final double drift = unit * 0.012 * math.sin(phase * 1.65);
      final Offset eye = eyes[i] + Offset(drift, 0);
      final double halfWidth = unit * 0.055 * pulse;
      final double rise = unit * 0.18 * pulse;

      canvas.drawCircle(
        eye,
        unit * 0.12 * pulse,
        Paint()
          ..color = const Color(0xB8FF4B12)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, unit * 0.045),
      );

      final Path flame = Path()
        ..moveTo(eye.dx - halfWidth, eye.dy + unit * 0.025)
        ..cubicTo(
          eye.dx - halfWidth * 1.28,
          eye.dy - rise * 0.20,
          eye.dx - halfWidth * 0.12,
          eye.dy - rise * 0.68,
          eye.dx + halfWidth * 0.18,
          eye.dy - rise,
        )
        ..cubicTo(
          eye.dx + halfWidth * 1.28,
          eye.dy - rise * 0.52,
          eye.dx + halfWidth * 0.92,
          eye.dy - unit * 0.005,
          eye.dx + halfWidth,
          eye.dy + unit * 0.025,
        )
        ..close();
      final Rect fireBounds = Rect.fromLTRB(
        eye.dx - halfWidth * 1.4,
        eye.dy - rise,
        eye.dx + halfWidth * 1.4,
        eye.dy + unit * 0.04,
      );
      canvas.drawPath(
        flame,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: <Color>[
              Color(0xFFFFEAA0),
              Color(0xFFFF9A32),
              Color(0xFFE7371D),
            ],
          ).createShader(fireBounds)
          ..blendMode = BlendMode.screen,
      );
      canvas.drawCircle(
        eye,
        unit * 0.025,
        Paint()
          ..color = const Color(0xFFFFE5A2).withValues(
            alpha: 0.72 + 0.20 * pulse,
          ),
      );
    }
  }

  @override
  bool shouldRepaint(_LionEyeFirePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// END OF FILE - lib/widgets/lion_eye_fire_emblem.dart
