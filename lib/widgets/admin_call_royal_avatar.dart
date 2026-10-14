import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';

/// The administrator's audio-call portrait. The single transparent artwork
/// keeps the crown and jewelled frame on one clock, rotating clockwise together.
class AdminCallRoyalAvatar extends StatefulWidget {
  const AdminCallRoyalAvatar({
    super.key,
    required this.displayName,
    required this.size,
    this.imageUrl,
  });

  final String displayName;
  final double size;
  final String? imageUrl;

  @override
  State<AdminCallRoyalAvatar> createState() => _AdminCallRoyalAvatarState();
}

class _AdminCallRoyalAvatarState extends State<AdminCallRoyalAvatar>
    with SingleTickerProviderStateMixin {
  static const String _frameAsset =
      'assets/premium/ivory_admin_queen_call_frame.png';

  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 48),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  void _syncMotion() {
    if (MediaQuery.of(context).disableAnimations) {
      if (_turn.isAnimating) _turn.stop();
      _turn.value = 0;
    } else if (!_turn.isAnimating) {
      _turn.repeat();
    }
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  Widget _initial(double diameter) {
    final String name = widget.displayName.trim();
    final String initial = name.isEmpty ? 'I' : name.substring(0, 1).toUpperCase();
    return Container(
      color: IvoryColors.gold.withValues(alpha: 0.20),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontFamily: IvoryTheme.displayFont,
          fontSize: diameter * 0.38,
          fontWeight: FontWeight.w800,
          color: IvoryColors.burgundy,
        ),
      ),
    );
  }

  Widget _portrait(double diameter) {
    final String? url = widget.imageUrl;
    return SizedBox(
      width: diameter,
      height: diameter,
      child: ClipOval(
        child: url == null || url.isEmpty
            ? _initial(diameter)
            : Image.network(
                url,
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
    final double size = widget.size;
    final double rotationFootprint = size * 1.45;
    // The artwork's measured clear opening is 63.3% of its square canvas.
    // A 60% portrait leaves a clean margin beneath the jewelled inner rim.
    final double portraitSize = size * 0.60;
    return SizedBox(
      width: rotationFootprint,
      height: rotationFootprint,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: <Widget>[
          _portrait(portraitSize),
          AnimatedBuilder(
            animation: _turn,
            builder: (BuildContext context, Widget? child) => Transform.rotate(
              // Flutter's positive angle is clockwise in its downward-y canvas.
              angle: _turn.value * math.pi * 2,
              child: child,
            ),
            child: SizedBox(
              width: size,
              height: size,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Image.asset(
                    _frameAsset,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    gaplessPlayback: true,
                    errorBuilder: (_, __, ___) => const SizedBox.expand(),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _turn,
                        builder: (BuildContext context, Widget? child) =>
                            CustomPaint(
                          painter: _DiamondShimmer(progress: _turn.value),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiamondShimmer extends CustomPainter {
  const _DiamondShimmer({required this.progress});

  final double progress;

  static const List<Offset> _points = <Offset>[
    Offset(0.50, 0.055),
    Offset(0.28, 0.22),
    Offset(0.72, 0.22),
    Offset(0.105, 0.45),
    Offset(0.895, 0.45),
    Offset(0.20, 0.76),
    Offset(0.80, 0.76),
    Offset(0.40, 0.94),
    Offset(0.60, 0.94),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < _points.length; i++) {
      final double phase =
          (progress * math.pi * 2 * 27) + (i * math.pi * 0.71);
      final double wave = (math.sin(phase) + 1) * 0.5;
      if (wave < 0.80) continue;

      final double strength = (wave - 0.80) / 0.20;
      final double radius = size.shortestSide * (0.006 + strength * 0.006);
      final Offset point = Offset(
        size.width * _points[i].dx,
        size.height * _points[i].dy,
      );
      final Paint glow = Paint()
        ..color = Colors.white.withValues(alpha: strength * 0.22)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 3.2);
      canvas.drawCircle(point, radius * 2.2, glow);

      final Path star = Path()
        ..moveTo(point.dx, point.dy - radius * 2.8)
        ..lineTo(point.dx + radius * 0.42, point.dy - radius * 0.42)
        ..lineTo(point.dx + radius * 2.8, point.dy)
        ..lineTo(point.dx + radius * 0.42, point.dy + radius * 0.42)
        ..lineTo(point.dx, point.dy + radius * 2.8)
        ..lineTo(point.dx - radius * 0.42, point.dy + radius * 0.42)
        ..lineTo(point.dx - radius * 2.8, point.dy)
        ..lineTo(point.dx - radius * 0.42, point.dy - radius * 0.42)
        ..close();
      canvas.drawPath(
        star,
        Paint()..color = Colors.white.withValues(alpha: strength * 0.78),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DiamondShimmer oldDelegate) =>
      oldDelegate.progress != progress;
}

// END OF FILE - lib/widgets/admin_call_royal_avatar.dart
