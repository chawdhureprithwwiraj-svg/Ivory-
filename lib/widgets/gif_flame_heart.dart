import 'dart:math' as math;
import 'dart:ui' show Shader;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dust_ring.dart';
import 'flame_heart.dart';
import 'heart_cine.dart';

/// ============================================================
/// IVORY - THE BURNING HEART (inside the Golden Heart screen)
///
/// The owner's own cinematic film of a burning heart, played in the
/// app on the deep burgundy stage: the film's black is turned into
/// burgundy, its edges melt into the stage, and the heart glows
/// brighter and richer with the member's glow level (from a cool,
/// dim ember to the full blaze). At Crowned a thick ring of golden
/// dust circles it too. When today's heart is lit it flares once.
///
/// The film is any .gif placed in the app's assets folder (the app
/// finds it by itself). If there is none, the painted flame heart
/// is shown instead, so this screen never breaks.
/// ============================================================
class GifFlameHeart extends StatefulWidget {
  const GifFlameHeart({
    super.key,
    required this.fill,
    required this.tier,
    required this.lit,
    this.celebrate = 0,
    this.height = 340,
  });

  final double fill;
  final int tier;
  final bool lit;
  final int celebrate;
  final double height;

  @override
  State<GifFlameHeart> createState() => _GifFlameHeartState();
}

// Looked for once per app run.
Future<String?>? _gifLookup;

Future<String?> _findGif() async {
  try {
    final AssetManifest m = await AssetManifest.loadFromAssetBundle(rootBundle);
    final List<String> gifs = m
        .listAssets()
        .where((String a) => a.toLowerCase().endsWith('.gif'))
        .toList();
    if (gifs.isEmpty) return null;
    for (final String g in gifs) {
      final String l = g.toLowerCase();
      if (l.contains('flame') || l.contains('heart')) return g;
    }
    return gifs.first;
  } catch (_) {
    return null;
  }
}

class _GifFlameHeartState extends State<GifFlameHeart>
    with TickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat();
  late final AnimationController _flare = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  // CC.242: the soft vignette over the heart used to build a fresh
  // radial shader on every painted frame - one allocation per frame
  // for a shape that never changes. It is built once per size now.
  Size? _maskSize;
  late Shader _maskShader;

  Shader _mask(Rect r) {
    if (_maskSize != r.size) {
      _maskSize = r.size;
      _maskShader = const RadialGradient(
        center: Alignment(0, 0.08),
        radius: 0.58,
        colors: <Color>[
          Color(0xFFFFFFFF),
          Color(0xFFFFFFFF),
          Color(0x00FFFFFF),
        ],
        stops: <double>[0, 0.6, 1],
      ).createShader(r);
    }
    return _maskShader;
  }

  @override
  void initState() {
    super.initState();
    _gifLookup ??= _findGif();
  }

  @override
  void didUpdateWidget(GifFlameHeart old) {
    super.didUpdateWidget(old);
    if (widget.celebrate != old.celebrate) _flare.forward(from: 0);
  }

  @override
  void dispose() {
    _loop.dispose();
    _flare.dispose();
    super.dispose();
  }

  // Rich, bright gold at every level; only the strength grows. The
  // warm channels are lifted and the blue is held back so the fire
  // reads as molten gold, never as brown.
  static ColorFilter _heat(double heat) {
    final double k = 0.9 + 0.35 * heat;
    final double r = 1.12 * k;
    final double g = 1.04 * k;
    final double b = 0.82 * k;
    return ColorFilter.matrix(<double>[
      r, 0, 0, 0, 6, //
      0, g, 0, 0, 2, //
      0, 0, b, 0, 0, //
      0, 0, 0, 1, 0,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final double heat = FlameHeart.heatOf(widget.tier, widget.fill, widget.lit);
    return FutureBuilder<String?>(
      future: _gifLookup,
      builder: (BuildContext context, AsyncSnapshot<String?> snap) {
        if (snap.connectionState != ConnectionState.done) {
          return SizedBox(height: widget.height);
        }
        final String? path = snap.data;
        if (path == null) {
          return FlameHeart(
            fill: widget.fill,
            tier: widget.tier,
            lit: widget.lit,
            celebrate: widget.celebrate,
            height: widget.height,
          );
        }
        return LayoutBuilder(builder: (BuildContext _, BoxConstraints bc) {
        // As large as the stage allows: the heart fills it.
        final double side = math.min(
          (bc.maxWidth.isFinite ? bc.maxWidth : 340.0) * 1.2,
          widget.height * 1.08,
        );
        return RepaintBoundary(
          child: SizedBox(
            width: double.infinity,
            height: widget.height,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                // The warm glow behind the heart, stronger with the glow.
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, 0.1),
                        radius: 0.6,
                        colors: <Color>[
                          const Color(0xFFFFB02E).withValues(
                            alpha: 0.1 + 0.3 * heat,
                          ),
                          const Color(0xFFFFB02E).withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
                ClipRect(
                  child: OverflowBox(
                  maxWidth: side,
                  maxHeight: side,
                  child: SizedBox(
                    width: side,
                    height: side,
                    child: ShaderMask(
                    blendMode: BlendMode.dstIn,
                    shaderCallback: _mask,
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF4A0E17),
                        BlendMode.lighten,
                      ),
                      child: ColorFiltered(
                        colorFilter: _heat(heat),
                        child: Image.asset(
                          path,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                          filterQuality: FilterQuality.medium,
                          cacheWidth: 560,
                          errorBuilder: (BuildContext _, Object __, StackTrace? ___) =>
                              const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),
                  ),
                  ),
                ),
                if (widget.tier >= 8)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _loop,
                        builder: (BuildContext _, Widget? __) => CustomPaint(
                          painter: _CrownRingPainter(t: _loop.value),
                        ),
                      ),
                    ),
                  ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _flare,
                      builder: (BuildContext _, Widget? __) => _flare.value <= 0 ||
                              _flare.value >= 1
                          ? const SizedBox.shrink()
                          : CustomPaint(
                              painter: _FlarePainter(f: _flare.value),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        });
      },
    );
  }
}

class _CrownRingPainter extends CustomPainter {
  _CrownRingPainter({required this.t});

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = Offset(size.width / 2, size.height * 0.5);
    final double rx = math.min(size.width * 0.5, size.height * 0.62);
    final double ry = rx * 0.27;
    DustRing.paint(
      canvas,
      center: c,
      rx: rx,
      ry: ry,
      tilt: 0.17,
      t: t,
      n: 900,
      front: false,
      alpha: 0.6,
      grain: 1.2,
      thick: 0.24,
      haze: 2,
      seed: 77,
    );
    DustRing.paint(
      canvas,
      center: c,
      rx: rx,
      ry: ry,
      tilt: 0.17,
      t: t,
      n: 900,
      front: true,
      alpha: 1,
      grain: 1.2,
      thick: 0.24,
      haze: 2,
      seed: 77,
    );
  }

  @override
  bool shouldRepaint(_CrownRingPainter o) => o.t != t;
}

/// The one flare when today's heart is lit.
class _FlarePainter extends CustomPainter {
  _FlarePainter({required this.f});

  final double f;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset mid = Offset(size.width / 2, size.height * 0.52);
    final double hh = size.height * 0.5;
    final double pulse = math.sin(math.pi * f);
    canvas.drawCircle(
      mid,
      hh * 1.3,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            const Color(0xFFFFF4C8).withValues(alpha: 0.45 * pulse * pulse),
            const Color(0xFFFFB02E).withValues(alpha: 0.14 * pulse),
            const Color(0xFFFFB02E).withValues(alpha: 0),
          ],
          stops: const <double>[0, 0.4, 1],
        ).createShader(Rect.fromCircle(center: mid, radius: hh * 1.3)),
    );
    for (int k = 0; k < 2; k++) {
      final double ff = Cine.clamp01(f - k * 0.14);
      if (ff <= 0) continue;
      canvas.drawCircle(
        mid,
        hh * (0.3 + 0.95 * ff),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 + 7 * (1 - ff)
          ..color = const Color(0xFFFFE9A0).withValues(
            alpha: math.pow(1 - ff, 1.5).toDouble() * 0.8,
          ),
      );
    }
    final Paint sp = Paint()..blendMode = BlendMode.plus;
    for (int i = 0; i < 90; i++) {
      final double ang = Cine.tau * Cine.hash(i * 3 + 5);
      final double dist =
          math.pow(f, 0.6).toDouble() * hh * (0.5 + 0.8 * Cine.hash(i * 7 + 1));
      final double a = (1 - f) * (0.4 + 0.6 * Cine.hash(i));
      sp.color = Cine.mix(const Color(0xFFFFF0B0), const Color(0xFFFF9A2A), f)
          .withValues(alpha: Cine.clamp01(a));
      canvas.drawCircle(
        Offset(mid.dx + math.cos(ang) * dist, mid.dy + math.sin(ang) * dist),
        0.8 + 1.8 * Cine.hash(i * 11),
        sp,
      );
    }
  }

  @override
  bool shouldRepaint(_FlarePainter o) => o.f != f;
}

// END OF FILE - lib/widgets/gif_flame_heart.dart
