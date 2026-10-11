import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';

/// A member portrait. Active paid members keep the existing gold entitlement
/// cue, now dressed as an original Ivory crown-and-laurel frame.
class MemberAvatar extends StatelessWidget {
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

  Widget _initial(double portraitSize) {
    final String name = displayName.trim();
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

  @override
  Widget build(BuildContext context) {
    final String? url = imageUrl;
    final double inset = premiumFrame ? (size >= 44 ? 0.08 : 0.10) : 0.015;
    final double top = premiumFrame ? (size >= 60 ? 0.14 : 0.12) : 0.015;
    final double bottom = premiumFrame
        ? (size >= 60 ? 0.02 : (size >= 44 ? 0.04 : 0.08))
        : 0.015;
    final double portraitSize = size * (1 - inset * 2);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (premiumFrame)
            CustomPaint(painter: _RoyalAvatarFramePainter(size: size)),
          Positioned(
            left: size * inset,
            right: size * inset,
            top: size * top,
            bottom: size * bottom,
            child: Container(
              padding: EdgeInsets.all(premiumFrame ? size * 0.025 : 1.2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: premiumFrame ? IvoryColors.goldGradient : null,
                color: premiumFrame ? null : IvoryColors.hairline,
                boxShadow: premiumFrame
                    ? IvoryTheme.softShadow(blur: 7, y: 2)
                    : null,
              ),
              child: ClipOval(
                child: url == null || url.isEmpty
                    ? _initial(portraitSize)
                    : Image.network(
                        url,
                        width: portraitSize,
                        height: portraitSize,
                        fit: BoxFit.cover,
                        loadingBuilder: (BuildContext context, Widget child,
                                ImageChunkEvent? progress) =>
                            progress == null ? child : _initial(portraitSize),
                        errorBuilder: (_, __, ___) => _initial(portraitSize),
                      ),
              ),
            ),
          ),
          if (premiumFrame)
            CustomPaint(painter: _RoyalAvatarCrownPainter()),
        ],
      ),
    );
  }
}

class _RoyalAvatarFramePainter extends CustomPainter {
  const _RoyalAvatarFramePainter({required this.size});

  final double size;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final double w = canvasSize.width;
    final double h = canvasSize.height;
    final Paint gold = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[IvoryColors.amber, IvoryColors.gold, IvoryColors.peach],
      ).createShader(Offset.zero & canvasSize)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (w * 0.035).clamp(1.0, 2.5).toDouble();
    final Rect halo = Rect.fromCenter(
      center: Offset(w / 2, h * 0.56),
      width: w * 0.86,
      height: h * 0.82,
    );
    canvas.drawOval(halo, gold);
    final Paint fine = Paint()
      ..color = IvoryColors.cream.withValues(alpha: 0.88)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (w * 0.012).clamp(0.6, 1.0).toDouble();
    canvas.drawOval(halo.deflate(w * 0.035), fine);

    // Full laurel is reserved for the larger Profile portrait; tiny chat
    // portraits keep the frame legible with just the crown and halo.
    if (size >= 58) {
      final Paint leaf = Paint()
        ..shader = const LinearGradient(
          colors: <Color>[IvoryColors.gold, IvoryColors.amber],
        ).createShader(Offset.zero & canvasSize);
      for (int i = 0; i < 4; i++) {
        final double y = h * (0.38 + i * 0.12);
        final double x = w * (0.08 + i * 0.012);
        for (final bool right in <bool>[false, true]) {
          canvas.save();
          canvas.translate(right ? w - x : x, y);
          canvas.rotate(right ? -0.55 : 0.55);
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset.zero,
              width: w * 0.13,
              height: h * 0.055,
            ),
            leaf,
          );
          canvas.restore();
        }
      }
      final Paint branch = Paint()
        ..color = IvoryColors.amber
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.018
        ..strokeCap = StrokeCap.round;
      final Path leftBranch = Path()
        ..moveTo(w * 0.06, h * 0.79)
        ..quadraticBezierTo(w * 0.00, h * 0.55, w * 0.13, h * 0.34);
      final Path rightBranch = Path()
        ..moveTo(w * 0.94, h * 0.79)
        ..quadraticBezierTo(w, h * 0.55, w * 0.87, h * 0.34);
      canvas.drawPath(leftBranch, branch);
      canvas.drawPath(rightBranch, branch);
    }
  }

  @override
  bool shouldRepaint(covariant _RoyalAvatarFramePainter oldDelegate) =>
      oldDelegate.size != size;
}

class _RoyalAvatarCrownPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Path crown = Path()
      ..moveTo(w * 0.34, h * 0.20)
      ..lineTo(w * 0.31, h * 0.055)
      ..lineTo(w * 0.43, h * 0.13)
      ..lineTo(w * 0.50, h * 0.015)
      ..lineTo(w * 0.57, h * 0.13)
      ..lineTo(w * 0.69, h * 0.055)
      ..lineTo(w * 0.66, h * 0.20)
      ..close();
    final Paint crownPaint = Paint()
      ..shader = const LinearGradient(
        colors: <Color>[IvoryColors.peach, IvoryColors.gold, IvoryColors.amber],
      ).createShader(Rect.fromLTWH(w * 0.3, h * 0.02, w * 0.4, h * 0.19));
    canvas.drawPath(crown, crownPaint);
    canvas.drawLine(
      Offset(w * 0.34, h * 0.20),
      Offset(w * 0.66, h * 0.20),
      Paint()
        ..color = IvoryColors.amber
        ..strokeWidth = (w * 0.035).clamp(1.0, 2.0).toDouble()
        ..strokeCap = StrokeCap.round,
    );
    for (final Offset jewel in <Offset>[
      Offset(w * 0.31, h * 0.05),
      Offset(w * 0.50, h * 0.015),
      Offset(w * 0.69, h * 0.05),
    ]) {
      canvas.drawCircle(
        jewel,
        (w * 0.027).clamp(1.0, 2.3).toDouble(),
        Paint()..color = IvoryColors.cream,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RoyalAvatarCrownPainter oldDelegate) => false;
}

// END OF FILE - lib/widgets/member_avatar.dart
