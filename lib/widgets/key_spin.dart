import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'premium_assets.dart';
import 'vault_keys.dart';

/// ============================================================
/// IVORY - THE TEN-DAY VAULT KEY, TURNING
///
/// The owner's own golden key (`10_day_key_animation.png`) turns slowly
/// about its upright axis, CLOCKWISE seen from above: the face nearest
/// you sweeps to the left, then the key shows its edge, then its back,
/// then its face again. The key is a flat picture, so it is given
/// thickness: seven thin copies stacked in depth, darker gold behind,
/// so the edge looks like cast metal. A band of light slides down the
/// key as it turns, and the jewel in the bow twinkles. If the picture
/// is missing the older coin emblem shows instead, so nothing breaks.
/// ============================================================
class VaultKeySpin extends StatefulWidget {
  const VaultKeySpin({super.key, this.size = 62});

  /// The square it occupies; the key stands as tall as the square.
  final double size;

  @override
  State<VaultKeySpin> createState() => _VaultKeySpinState();
}

class _VaultKeySpinState extends State<VaultKeySpin>
    with SingleTickerProviderStateMixin {
  // One full turn takes eight seconds.
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();
  ui.Image? _img;

  @override
  void initState() {
    super.initState();
    PremiumAssets.image(
      'key',
      const <String>['10_day_key'],
      width: 189,
    ).then((ui.Image? i) {
      if (mounted && i != null) setState(() => _img = i);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ui.Image? im = _img;
    if (im == null) return VaultEmblem(size: widget.size);
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _c,
          builder: (BuildContext _, Widget? __) => CustomPaint(
            painter: _KeyPainter(im, _c.value),
          ),
        ),
      ),
    );
  }
}

class _KeyPainter extends CustomPainter {
  _KeyPainter(this.img, this.t);

  final ui.Image img;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.height;
    // Clockwise seen from above = a negative turn about the upright.
    final double th = -t * math.pi * 2;
    final double cs = math.cos(th);
    final double sn = math.sin(th);
    final double kh = s * 0.98;
    final double kw = kh * img.width / img.height;
    final Offset c = Offset(size.width / 2, s / 2);
    final Rect src = Rect.fromLTWH(
      0,
      0,
      img.width.toDouble(),
      img.height.toDouble(),
    );
    final double sway = math.sin(t * math.pi * 4) * 0.035;

    // A soft glow behind the key.
    canvas.drawCircle(
      c,
      s * 0.5,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            const Color(0xFFFFD34D).withValues(alpha: 0.28),
            const Color(0x00FFD34D),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: s * 0.5)),
    );

    const int layers = 7;
    final double depth = kw * 0.2;
    // Back layers first. A layer at depth z is in front when z * cos > 0.
    final List<int> order = List<int>.generate(layers, (int i) => i);
    order.sort((int a, int b) {
      final double za = (a - 3) * cs;
      final double zb = (b - 3) * cs;
      return za.compareTo(zb);
    });
    for (final int i in order) {
      final double z = (i - 3) / 3 * depth / 2;
      final bool front = (i == 6 && cs >= 0) || (i == 0 && cs < 0);
      canvas.save();
      canvas.translate(c.dx + z * sn, c.dy);
      canvas.rotate(sway);
      // Squeezed by the turn; a sliver at the edge.
      // Past the edge the back of the key shows, so it is mirrored.
      canvas.scale(cs >= 0 ? math.max(0.035, cs) : -math.max(0.035, -cs), 1);
      final Rect dst = Rect.fromCenter(
        center: Offset.zero,
        width: kw,
        height: kh,
      );
      if (front) {
        canvas.saveLayer(dst.inflate(2), Paint());
        canvas.drawImageRect(
          img,
          src,
          dst,
          Paint()
            ..filterQuality = FilterQuality.high
            ..isAntiAlias = true,
        );
        // A band of light sliding down the key.
        final double p = -0.2 + 1.4 * ((t * 2) % 1.0);
        double st(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);
        canvas.drawRect(
          dst,
          Paint()
            ..blendMode = BlendMode.srcATop
            ..shader = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                const Color(0x00FFF3C4),
                Color(0xFFFFF3C4).withValues(alpha: 0.55 * cs.abs()),
                const Color(0x00FFF3C4),
              ],
              stops: <double>[st(p - 0.12), st(p), st(p + 0.12)],
            ).createShader(dst),
        );
        canvas.restore();
      } else {
        canvas.drawImageRect(
          img,
          src,
          dst,
          Paint()
            ..filterQuality = FilterQuality.medium
            ..colorFilter = const ColorFilter.mode(
              Color(0xFF9A6208),
              BlendMode.modulate,
            ),
        );
      }
      canvas.restore();
    }

    // The jewel in the bow twinkles (mostly when the face is toward us).
    final double tw = math.pow(
      math.max(0.0, math.sin(math.pi * 2 * (t * 3 + 0.2))),
      6,
    ).toDouble();
    if (tw > 0.05 && cs.abs() > 0.3) {
      final Offset g = Offset(c.dx + kw * 0.02 * cs, c.dy - kh * 0.27);
      final Paint sp = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.95 * tw)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;
      final double len = s * (0.08 + 0.1 * tw) * cs.abs();
      canvas.drawLine(g.translate(-len, 0), g.translate(len, 0), sp);
      canvas.drawLine(g.translate(0, -len), g.translate(0, len), sp);
    }
  }

  @override
  bool shouldRepaint(_KeyPainter o) => o.t != t || o.img != img;
}

// END OF FILE - lib/widgets/key_spin.dart
