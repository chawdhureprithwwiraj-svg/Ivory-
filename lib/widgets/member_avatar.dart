import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';

/// A member portrait. Only an active paid membership receives the exact
/// ornate burgundy, gold and emerald frame, animated wings and moving halo.
class MemberAvatar extends StatefulWidget {
  const MemberAvatar({
    super.key,
    required this.displayName,
    required this.size,
    this.imageUrl,
    this.premiumFrame = false,
  });

  final String displayName;
  final double size;
  final String? imageUrl;
  final bool premiumFrame;

  @override
  State<MemberAvatar> createState() => _MemberAvatarState();
}

class _MemberAvatarState extends State<MemberAvatar>
    with SingleTickerProviderStateMixin {
  static const String _frameAsset =
      'assets/premium/ivory_ornate_avatar_frame.png';
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant MemberAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.premiumFrame != widget.premiumFrame) _syncMotion();
  }

  void _syncMotion() {
    final bool play =
        widget.premiumFrame && !MediaQuery.of(context).disableAnimations;
    if (play) {
      if (!_motion.isAnimating) _motion.repeat();
    } else {
      if (_motion.isAnimating) _motion.stop();
      _motion.value = 0;
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  Widget _initial(double portraitSize) {
    final String name = widget.displayName.trim();
    final String initial = name.isEmpty ? 'I' : name.substring(0, 1).toUpperCase();
    return Container(
      color: IvoryColors.gold.withValues(alpha: 0.2),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontFamily: IvoryTheme.displayFont,
          fontSize: portraitSize * 0.39,
          fontWeight: FontWeight.w800,
          color: IvoryColors.burgundy,
        ),
      ),
    );
  }

  Widget _portrait(double diameter, {bool framed = false}) {
    final String? url = widget.imageUrl;
    return Container(
      width: diameter,
      height: diameter,
      padding: EdgeInsets.all(framed ? diameter * 0.035 : 1.2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: framed ? IvoryColors.goldGradient : null,
        color: framed ? null : IvoryColors.hairline,
        boxShadow: framed ? IvoryTheme.softShadow(blur: 7, y: 2) : null,
      ),
      child: ClipOval(
        child: url == null || url.isEmpty
            ? _initial(diameter)
            : Image.network(
                url,
                width: diameter,
                height: diameter,
                fit: BoxFit.cover,
                loadingBuilder: (BuildContext context, Widget child,
                        ImageChunkEvent? progress) =>
                    progress == null ? child : _initial(diameter),
                errorBuilder: (_, __, ___) => _initial(diameter),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double frameSize = widget.size;
    if (!widget.premiumFrame) {
      return SizedBox(
        width: frameSize,
        height: frameSize,
        child: Center(child: _portrait(frameSize * 0.97)),
      );
    }

    // The side feathers need a little room beyond the circular artwork.
    final double footprint = frameSize * 1.24;
    final double portraitSize = frameSize * 0.495;
    return SizedBox(
      width: footprint,
      height: footprint,
      child: AnimatedBuilder(
        animation: _motion,
        builder: (BuildContext context, Widget? child) {
          final double flap = math.sin(_motion.value * math.pi * 2) * 0.075;
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned.fill(
                child: CustomPaint(
                  painter: _WingPainter(
                    scale: frameSize / 334,
                    flap: flap,
                  ),
                ),
              ),
              SizedBox(
                width: portraitSize,
                height: portraitSize,
                child: _portrait(portraitSize, framed: true),
              ),
              Image.asset(
                _frameAsset,
                width: frameSize,
                height: frameSize,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                gaplessPlayback: true,
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _GoldOrbitPainter(
                    frameSize: frameSize,
                    progress: _motion.value,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WingPainter extends CustomPainter {
  const _WingPainter({required this.scale, required this.flap});

  final double scale;
  final double flap;

  static final Path _wing = Path()
    ..moveTo(103, 192)
    ..cubicTo(84, 169, 53, 134, 24, 106)
    ..cubicTo(40, 139, 36, 158, 18, 184)
    ..cubicTo(43, 177, 62, 191, 81, 212)
    ..cubicTo(53, 206, 29, 221, 19, 245)
    ..cubicTo(52, 235, 77, 249, 105, 268)
    ..cubicTo(94, 239, 91, 216, 103, 192)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale);
    canvas.translate(-220, -220);
    _drawWing(canvas, flap, mirror: false);
    _drawWing(canvas, -flap * 0.86, mirror: true);
    canvas.restore();
  }

  void _drawWing(Canvas canvas, double angle, {required bool mirror}) {
    canvas.save();
    if (mirror) {
      canvas.translate(440, 0);
      canvas.scale(-1, 1);
    }
    canvas.translate(103, 218);
    canvas.rotate(angle);
    canvas.translate(-103, -218);

    final Rect bounds = Rect.fromLTRB(18, 106, 107, 268);
    final Paint shadow = Paint()
      ..color = const Color(0x994A0E17)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
    canvas.save();
    canvas.translate(1.5, 3.2);
    canvas.drawPath(_wing, shadow);
    canvas.restore();

    final Paint enamelGold = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color(0xFFFFEEC0),
          Color(0xFFD8A44D),
          Color(0xFF783C29),
          Color(0xFFF0CB77),
          Color(0xFF8C5127),
        ],
        stops: <double>[0, 0.24, 0.47, 0.7, 1],
      ).createShader(bounds);
    canvas.drawPath(_wing, enamelGold);
    canvas.drawPath(
      _wing,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF66371F),
    );

    final Path featherPaths = Path()
      ..moveTo(99, 202)
      ..lineTo(31, 117)
      ..moveTo(94, 211)
      ..lineTo(23, 159)
      ..moveTo(91, 222)
      ..lineTo(21, 190)
      ..moveTo(96, 233)
      ..lineTo(23, 232);
    canvas.drawPath(
      featherPaths,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.8
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF9D5B2A).withValues(alpha: 0.9),
    );
    canvas.drawPath(
      featherPaths,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFFFE8A6).withValues(alpha: 0.92),
    );

    final Path gem = Path()
      ..moveTo(98, 178)
      ..lineTo(107, 188)
      ..lineTo(98, 198)
      ..lineTo(89, 187)
      ..close();
    canvas.drawPath(
      gem,
      Paint()
        ..shader = const RadialGradient(
          colors: <Color>[
            Color(0xFFD8FFF0),
            Color(0xFF48BF8C),
            Color(0xFF11644D),
            Color(0xFF073B31),
          ],
          stops: <double>[0, 0.2, 0.55, 1],
        ).createShader(const Rect.fromLTWH(88, 176, 20, 22)),
    );
    canvas.drawPath(
      gem,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0xFFFFE6A3),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WingPainter oldDelegate) =>
      oldDelegate.flap != flap || oldDelegate.scale != scale;
}

class _GoldOrbitPainter extends CustomPainter {
  const _GoldOrbitPainter({required this.frameSize, required this.progress});

  final double frameSize;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = frameSize * 0.485;
    final Rect orbit = Rect.fromCircle(center: center, radius: radius);
    final double width = (frameSize * 0.018).clamp(0.8, 1.8).toDouble();
    canvas.drawArc(
      orbit,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * 0.7
        ..color = IvoryColors.gold.withValues(alpha: 0.20),
    );

    final double start = -math.pi / 2 + progress * math.pi * 2;
    final double sweep = math.pi * 0.40;
    canvas.drawArc(
      orbit,
      start,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = width * 3.4
        ..color = IvoryColors.gold.withValues(alpha: 0.68)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 2.2),
    );
    canvas.drawArc(
      orbit,
      start + 0.05,
      sweep * 0.34,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = width * 1.05
        ..color = IvoryColors.cream.withValues(alpha: 0.98),
    );
    canvas.drawArc(
      orbit,
      start + math.pi,
      0.10,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = width * 1.5
        ..color = IvoryColors.amber.withValues(alpha: 0.82),
    );
  }

  @override
  bool shouldRepaint(covariant _GoldOrbitPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.frameSize != frameSize;
}

// END OF FILE - lib/widgets/member_avatar.dart
