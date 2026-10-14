import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector_math;

import '../theme/ivory_theme.dart';

/// Admin-only royal portrait: the centered frame turns clockwise while the
/// enlarged crown stays at 12 o'clock and yaws counterclockwise in 3D.
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
      'assets/premium/ivory_admin_queen_call_frame_ring.png';
  static const String _crownAsset =
      'assets/premium/ivory_admin_queen_call_crown.png';
  static const double _canvasSide = 979;
  static const double _ringVerticalShift = 52;
  static const double _crownSourceLeft = 350;
  static const double _crownSourceTop = 10;
  static const double _crownSourceWidth = 270;
  static const double _crownSourceHeight = 194;
  static const double _crownScale = 3;
  static const double _portraitScale = 0.66;
  static const double _perspective = 0.0015;

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
    final String initial =
        name.isEmpty ? 'I' : name.substring(0, 1).toUpperCase();
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
    final double frameInset = (rotationFootprint - size) / 2;
    final double portraitSize = size * _portraitScale;
    final double crownWidth =
        size * (_crownSourceWidth * _crownScale / _canvasSide);
    final double crownHeight =
        size * (_crownSourceHeight * _crownScale / _canvasSide);
    final double crownCenterX = _crownSourceLeft + _crownSourceWidth / 2;
    final double crownLeftInCanvas =
        crownCenterX - (_crownSourceWidth * _crownScale / 2);
    final double crownBaselineInCanvas =
        _crownSourceTop + _crownSourceHeight - _ringVerticalShift;
    final double crownTopInCanvas =
        crownBaselineInCanvas - _crownSourceHeight * _crownScale;

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
            builder: (BuildContext context, Widget? child) {
              // Positive Z rotation is clockwise in Flutter's downward-y plane.
              final double frameAngle = _turn.value * math.pi * 2;
              final double crownYaw = -frameAngle;
              final vector_math.Matrix4 crownTransform =
                  vector_math.Matrix4.identity()
                    ..setEntry(3, 2, _perspective)
                    ..rotateY(crownYaw);

              return SizedBox(
                width: rotationFootprint,
                height: rotationFootprint,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    Transform.rotate(
                      angle: frameAngle,
                      alignment: Alignment.center,
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
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.expand(),
                            ),
                            Positioned.fill(
                              child: IgnorePointer(
                                child: CustomPaint(
                                  painter:
                                      _DiamondShimmer(progress: _turn.value),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left:
                          frameInset + size * (crownLeftInCanvas / _canvasSide),
                      top:
                          frameInset + size * (crownTopInCanvas / _canvasSide),
                      width: crownWidth,
                      height: crownHeight,
                      child: Transform(
                        alignment: Alignment.center,
                        transform: crownTransform,
                        child: Image.asset(
                          _crownAsset,
                          fit: BoxFit.fill,
                          filterQuality: FilterQuality.high,
                          gaplessPlayback: true,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
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
    Offset(0.50, 0.12),
    Offset(0.28, 0.167),
    Offset(0.72, 0.167),
    Offset(0.105, 0.397),
    Offset(0.895, 0.397),
    Offset(0.20, 0.707),
    Offset(0.80, 0.707),
    Offset(0.40, 0.887),
    Offset(0.60, 0.887),
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
