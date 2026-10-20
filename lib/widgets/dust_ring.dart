import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'heart_cine.dart';

/// ============================================================
/// IVORY - THE RING OF GOLDEN DUST
///
/// A thick, dense cloud of fine golden dust that circles clockwise
/// like the rings of Saturn: a wide band of thousands of tiny grains
/// (not a line, not sparkles), thicker and brighter on the near side,
/// with a bright crest that travels with the cloud and a soft haze
/// that makes it read as one glowing river of gold. Painted in a few
/// batches so it stays light. [t] runs 0..1 once per turn.
/// ============================================================
class DustRing {
  DustRing._();

  static const Color _pale = Color(0xFFFFF1BE);
  static const Color _gold = Color(0xFFFFC21A);
  static const Color _amber = Color(0xFFE59A10);

  /// [front] picks the half that passes in FRONT of the heart (draw the
  /// other half before the heart). [haze]: 0 none, 1 plain, 2 blurred.
  static void paint(
    Canvas c, {
    required Offset center,
    required double rx,
    required double ry,
    required double tilt,
    required double t,
    required int n,
    required bool front,
    double alpha = 1,
    double grain = 1,
    double thick = 0.2,
    int haze = 1,
    int seed = 31,
  }) {
    if (alpha <= 0.01) return;
    c.save();
    c.translate(center.dx, center.dy);
    c.rotate(tilt);

    if (haze > 0) {
      final Rect r = Rect.fromCenter(
        center: Offset.zero,
        width: rx * 2,
        height: ry * 2,
      );
      final Paint hz = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ry * (0.7 + 2.2 * thick)
        ..color = _gold.withValues(alpha: 0.13 * alpha);
      if (haze > 1) {
        hz.maskFilter = MaskFilter.blur(BlurStyle.normal, ry * 0.45);
      }
      c.drawArc(r, front ? 0 : math.pi, math.pi, false, hz);
    }

    // Six batches: three colours, two sizes.
    final List<List<Offset>> b = List<List<Offset>>.generate(
      6,
      (int _) => <Offset>[],
    );
    final double head = t * Cine.tau;
    for (int i = 0; i < n; i++) {
      final double h1 = Cine.hash(seed + i * 5);
      final double h2 = Cine.hash(seed + i * 5 + 1);
      final double h3 = Cine.hash(seed + i * 5 + 2);
      final double h4 = Cine.hash(seed + i * 5 + 3);
      final double ang = Cine.tau * h1;
      final double th = ang + head;
      final double s = math.sin(th);
      if ((s > 0) != front) continue;
      // A wide band: most grains near the middle, some far out.
      final double off = (h2 + h3 - 1.0) * thick;
      final double wob = 0.025 * math.sin(Cine.tau * (t * 3 + h4));
      final double k = 1 + off + wob;
      final double x = rx * k * math.cos(th);
      final double y = ry * k * s + (h4 - 0.5) * ry * thick * 1.6;
      // The crest travels with the cloud: brighter grains near it.
      double d = ang;
      if (d > math.pi) d -= Cine.tau;
      final double crest = math.exp(-d * d / 0.9);
      final double bright = Cine.clamp01(0.25 + 0.75 * crest + 0.35 * (h3 - 0.5));
      final int col = bright < 0.4 ? 0 : (bright < 0.7 ? 1 : 2);
      final int size = h2 > 0.82 ? 1 : 0;
      b[col * 2 + size].add(Offset(x, y));
    }
    final double depth = front ? 1.0 : 0.55;
    const List<Color> cols = <Color>[_amber, _gold, _pale];
    for (int j = 0; j < 6; j++) {
      if (b[j].isEmpty) continue;
      final int col = j ~/ 2;
      final bool big = j.isOdd;
      final double tw =
          0.78 + 0.22 * math.sin(Cine.tau * (t * (5 + j) + j * 0.17));
      final Paint p = Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = (big ? 1.9 : 1.0) * grain
        ..blendMode = BlendMode.plus
        ..color = cols[col].withValues(
          alpha: Cine.clamp01((0.34 + 0.2 * col) * depth * alpha * tw),
        );
      c.drawPoints(ui.PointMode.points, b[j], p);
    }
    c.restore();
  }
}

// END OF FILE - lib/widgets/dust_ring.dart
