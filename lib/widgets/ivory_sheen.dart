import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';

/// ============================================================
/// IVORY - THE PASSING LIGHT.
///
/// One band of light crosses a thing, settles, and comes round
/// again a long time later. It is the house's only repeating
/// movement and it exists in exactly one file so that it can
/// never drift into two slightly different shimmer effects.
///
/// WHY A PASS AND NOT A SPARKLE. A thing that glitters without
/// stopping stops being noticed within a minute and starts
/// looking like a cheap game. Light that passes is seen fresh
/// every single time it passes. The owner chose this
/// deliberately over a constant sparkle.
///
/// SLOW IS THE POINT. The gift marks cross every 6 seconds;
/// the broadcast record crosses every 11, because it is a large
/// calm surface and a big panel flashing at the same rate as a
/// small button would feel restless. **If you are tempted to
/// speed this up, you have misunderstood it.**
///
/// IT COSTS NOTHING OFF SCREEN. A feed builds its rows lazily,
/// so a sheen scrolled well out of view is disposed and its
/// ticker dies with it. One controller per sheen, no timers
/// left running behind it. That matters on a 4 GB phone.
/// ============================================================

/// Wraps any painter-drawn widget and hands it the position of
/// the light, from 0 (entering) to 1 (gone). `-1` means the
/// light is not on the surface at all, which is most of the
/// time - and painting nothing is the cheapest thing a painter
/// can do.
class IvorySheen extends StatefulWidget {
  const IvorySheen({
    super.key,
    required this.child,
    this.period = const Duration(seconds: 11),
    this.crossing = 0.16,
  });

  /// Rebuilt as the light moves. `IvorySheenPosition.of(context)`
  /// is how the painter below it reads the position.
  final Widget Function(double travel) child;

  /// How long between one pass and the next.
  final Duration period;

  /// What fraction of that period the light is actually
  /// crossing for. 0.16 of 11 seconds is about 1.8 seconds of
  /// movement and a little over nine seconds of stillness.
  final double crossing;

  @override
  State<IvorySheen> createState() => _IvorySheenState();
}

class _IvorySheenState extends State<IvorySheen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.period)..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (BuildContext context, Widget? _) {
        final double v = _c.value;
        // Eased, so the light arrives and leaves rather than
        // snapping across. Nothing in Ivory snaps.
        final double travel = v > widget.crossing
            ? -1
            : Curves.easeInOut.transform(v / widget.crossing);
        return widget.child(travel);
      },
    );
  }
}

/// Paints the band over whatever has already been drawn, and
/// ONLY over it.
///
/// `saveLayer` plus `BlendMode.srcATop` keeps the light inside
/// the shape that was painted, so it travels across a card or a
/// seal and never leaks a glow into the page behind it. The
/// caller must have opened the layer already.
///
/// **In Flutter a Paint's shader OVERRIDES its colour.** The
/// fade therefore lives in the gradient's own stops, never in a
/// `color` set beside the shader - that would be silently
/// ignored.
void paintIvorySheen(
  Canvas canvas,
  Size size,
  double travel, {
  double strength = 0.72,
  Color tint = IvoryColors.cream,
}) {
  if (travel < 0) return;
  final double w = size.width;
  final Rect band = Rect.fromLTWH(
    -w * 0.6 + travel * w * 1.9,
    -size.height * 0.4,
    w * 0.42,
    size.height * 1.8,
  );
  final Paint p = Paint()
    ..blendMode = BlendMode.srcATop
    ..shader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: <Color>[
        tint.withValues(alpha: 0),
        tint.withValues(alpha: strength),
        tint.withValues(alpha: 0),
      ],
    ).createShader(band);
  canvas.save();
  // Leaned over, so it reads as light and not as a wipe.
  canvas.translate(w * 0.5, size.height * 0.5);
  canvas.rotate(-0.42);
  canvas.translate(-w * 0.5, -size.height * 0.5);
  canvas.drawRect(band, p);
  canvas.restore();
}

// END OF FILE - lib/widgets/ivory_sheen.dart
