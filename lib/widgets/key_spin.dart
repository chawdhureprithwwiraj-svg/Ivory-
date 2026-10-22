import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'premium_assets.dart';
import 'vault_keys.dart';

/// ============================================================
/// IVORY - THE TEN-DAY VAULT KEY, TURNING IN ITS LOCK
///
/// The owner's own golden key (`10_day_key_animation.png`) hangs upright
/// on its velvet ring and is never still: it sways gently like a key on
/// a hook and breathes up and down, and once every cycle it TURNS IN
/// ITS LOCK - a slow quarter-turn against the plate and back, as if it
/// were unlocking the day. At the peak of the turn the jewel in the bow
/// flashes, one soft ring of light breathes out from the medallion, and
/// afterwards a band of sheen crosses the blade. The key keeps its cast
/// thickness: darker gold copies sit behind the face like metal depth.
/// If the picture is missing the older coin emblem shows instead, so
/// nothing breaks.
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
  // One whole ritual - sway, breath, turn, flash, ring, sheen - 5.2 s.
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5200),
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

double _smooth(double x) => x * x * (3 - 2 * x);

double _clamp01(double x) => x < 0 ? 0 : (x > 1 ? 1 : x);

/// The turn of the lock, in radians: still, a quarter-turn against the
/// plate, a breath held, then home again.
double _lockTurn(double t) {
  if (t < 0.58) return 0;
  if (t < 0.72) return -0.70 * _smooth((t - 0.58) / 0.14);
  if (t < 0.84) return -0.70;
  if (t < 0.96) return -0.70 * (1 - _smooth((t - 0.84) / 0.12));
  return 0;
}

class _KeyPainter extends CustomPainter {
  _KeyPainter(this.img, this.t);

  final ui.Image img;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.height;
    final Offset c = Offset(size.width / 2, s / 2);
    final double kh = s * 0.98;
    final double kw = kh * img.width / img.height;
    // The sway of a key on a hook, and a slow breath up and down.
    final double sway = math.sin(t * math.pi * 2 * (5.2 / 3.4)) * 0.042;
    final double bob = math.sin(t * math.pi * 2 * 2) * s * 0.018;
    final double turn = _lockTurn(t);
    final Rect src = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());

    // A soft glow behind the key, warming as the turn comes.
    final double heat = t > 0.58 && t < 0.96 ? 0.16 : 0;
    canvas.drawCircle(
      c,
      s * 0.5,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            const Color(0xFFFFD34D).withValues(alpha: 0.26 + heat),
            const Color(0x00FFD34D),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: s * 0.5)),
    );

    // The ring of light breathing out just after the turn peaks.
    if (t > 0.72 && t < 0.98) {
      final double q = (t - 0.72) / 0.26;
      canvas.drawCircle(
        c,
        s * (0.30 + 0.32 * _smooth(q)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFFFFF3CF).withValues(alpha: 0.8 * (1 - q)),
      );
    }

    canvas.save();
    canvas.translate(c.dx, c.dy + bob);
    canvas.rotate(sway + turn);
    final Rect dst = Rect.fromCenter(center: Offset.zero, width: kw, height: kh);
    // Cast thickness: darker copies a hair behind, down and right.
    for (int i = 5; i >= 0; i--) {
      final double d = (i + 1) * 0.7;
      canvas.drawImageRect(
        img,
        src,
        dst.shift(Offset(d * 0.6, d)),
        Paint()
          ..filterQuality = FilterQuality.medium
          ..colorFilter = ColorFilter.mode(
            Color(0xFF9A6208).withValues(alpha: 0.55 - i * 0.08),
            BlendMode.modulate,
          ),
      );
    }
    // The face of the key.
    canvas.saveLayer(dst.inflate(2), Paint());
    canvas.drawImageRect(
      img,
      src,
      dst,
      Paint()
        ..filterQuality = FilterQuality.high
        ..isAntiAlias = true,
    );
    // A band of sheen crossing the blade after the turn.
    if (t > 0.84) {
      final double p = -0.25 + 1.5 * _clamp01((t - 0.84) / 0.16);
      canvas.drawRect(
        dst,
        Paint()
          ..blendMode = BlendMode.srcATop
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              const Color(0x00FFF3C4),
              const Color(0x8CFFF3C4),
              const Color(0x00FFF3C4),
            ],
            stops: <double>[
              _clamp01(p - 0.12),
              _clamp01(p),
              _clamp01(p + 0.12),
            ],
          ).createShader(dst),
      );
    }
    canvas.restore();

    // The jewel in the bow flashes at the peak of the turn.
    final double w = 1 - ((t - 0.74) / 0.10).abs();
    if (w > 0) {
      final double f = _smooth(_clamp01(w));
      final Offset g = Offset(kw * 0.02, -kh * 0.27);
      canvas.drawCircle(
        g,
        s * 0.10 * f,
        Paint()
          ..shader = RadialGradient(
            colors: <Color>[
              const Color(0xFFFFFBE8).withValues(alpha: 0.9 * f),
              const Color(0x00FFFBE8),
            ],
          ).createShader(Rect.fromCircle(center: g, radius: s * 0.10 * f)),
      );
      final Paint sp = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.95 * f)
        ..strokeWidth = 1.3
        ..strokeCap = StrokeCap.round;
      final double len = s * (0.06 + 0.10 * f);
      canvas.drawLine(g.translate(-len, 0), g.translate(len, 0), sp);
      canvas.drawLine(g.translate(0, -len), g.translate(0, len), sp);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_KeyPainter o) => o.t != t || o.img != img;
}

// END OF FILE - lib/widgets/key_spin.dart
