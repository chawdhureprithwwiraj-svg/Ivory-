import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'dust_ring.dart';
import 'heart_cine.dart';
import 'premium_assets.dart';

/// ============================================================
/// IVORY - THE GOLDEN HEART MEDALLION (top bar)
///
/// A crystal heart of gold, with no background at all, and a thick
/// cloud of golden dust circling it clockwise like the rings of
/// Saturn, as large as the top bar allows. The higher the member's glow, the richer and
/// denser it becomes. No sound. All painted. No black anywhere.
/// ============================================================
class HeartMedallion extends StatefulWidget {
  const HeartMedallion({
    super.key,
    required this.fill,
    required this.tier,
    this.lit = false,
    this.size = 56,
  });

  final double fill;
  final int tier;
  final bool lit;
  final double size;

  static double heatOf(int tier, double fill, bool lit) {
    final int tt = tier < 0 ? 0 : (tier > 8 ? 8 : tier);
    double h = 0.3 + 0.45 * tt / 8.0 + 0.15 * Cine.clamp01(fill);
    if (lit) h += 0.1;
    return Cine.clamp01(h);
  }

  @override
  State<HeartMedallion> createState() => _HeartMedallionState();
}

class _HeartMedallionState extends State<HeartMedallion>
    with SingleTickerProviderStateMixin {
  // One turn of the dust takes eight seconds.
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  // The owner's golden heart picture, once it has loaded (shared).
  ui.Image? _img;

  @override
  void initState() {
    super.initState();
    PremiumAssets.image('heart', const <String>['golden_heart']).then((
      ui.Image? i,
    ) {
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
    final double heat = HeartMedallion.heatOf(
      widget.tier,
      widget.fill,
      widget.lit,
    );
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _c,
          builder: (BuildContext _, Widget? __) => CustomPaint(
            painter: _MedallionPainter(t: _c.value, heat: heat, img: _img),
          ),
        ),
      ),
    );
  }
}

class _MedallionPainter extends CustomPainter {
  _MedallionPainter({required this.t, required this.heat, this.img});

  final double t;
  final double heat;
  final ui.Image? img;

  // The heart in the owner's picture (1244 x 700): its box, and its
  // outline (the picture's own dust ring is cut away, so only the
  // painted, turning dust circles it). x,y pairs as a share of the
  // picture.
  static const double _px0 = 334;
  static const double _py0 = 28;
  static const double _pw = 564;
  static const double _ph = 594;
  static const List<double> _outline = <double>[
  0.3424, 0.0429,
  0.3320, 0.0671,
  0.3352, 0.1343,
  0.3304, 0.1386,
  0.3135, 0.1286,
  0.3047, 0.1371,
  0.2894, 0.1871,
  0.2966, 0.2343,
  0.2789, 0.2400,
  0.2709, 0.2614,
  0.2781, 0.2929,
  0.2685, 0.3243,
  0.2757, 0.3543,
  0.2733, 0.3871,
  0.2846, 0.4329,
  0.2910, 0.5114,
  0.3079, 0.5700,
  0.2934, 0.5943,
  0.2918, 0.6186,
  0.3023, 0.6386,
  0.3223, 0.6400,
  0.3400, 0.6571,
  0.3875, 0.7500,
  0.4413, 0.8300,
  0.5000, 0.8843,
  0.5161, 0.8857,
  0.5611, 0.8329,
  0.6190, 0.7500,
  0.6302, 0.7257,
  0.6479, 0.7257,
  0.6696, 0.7129,
  0.6785, 0.7000,
  0.6801, 0.6771,
  0.6656, 0.6471,
  0.6945, 0.5571,
  0.7066, 0.4843,
  0.7178, 0.4700,
  0.7219, 0.4543,
  0.7130, 0.4214,
  0.7002, 0.3371,
  0.6680, 0.2471,
  0.6045, 0.1971,
  0.5498, 0.2214,
  0.5305, 0.2414,
  0.5080, 0.2786,
  0.5024, 0.2757,
  0.4727, 0.2200,
  0.4068, 0.1900,
  0.3794, 0.1986,
  0.3786, 0.1929,
  0.4084, 0.1471,
  0.4092, 0.1029,
  0.3979, 0.0843,
  0.3698, 0.0900,
  0.3601, 0.0471,
  ];

  static const List<Color> _ramp = <Color>[
    Color(0xFF8A5008),
    Color(0xFFB8740A),
    Color(0xFFE59A10),
    Color(0xFFFFC21A),
    Color(0xFFFFDF70),
    Color(0xFFFFF3C4),
  ];

  static Color _tone(double b) {
    final double x = Cine.clamp01(b) * (_ramp.length - 1);
    int i = x.floor();
    if (i > _ramp.length - 2) i = _ramp.length - 2;
    return Color.lerp(_ramp[i], _ramp[i + 1], x - i)!;
  }

  static Offset _pt(double th) {
    final double s = math.sin(th);
    final double x = s * s * s;
    final double y =
        (13 * math.cos(th) -
            5 * math.cos(2 * th) -
            2 * math.cos(3 * th) -
            math.cos(4 * th)) /
        16;
    return Offset(x, -y - 0.095);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width;
    final Offset c = Offset(s / 2, s * 0.49);
    final double rad = s / 2;
    final Rect disc = Rect.fromCircle(center: c, radius: rad);

    // Only a faint warm glow behind the heart: no background.
    canvas.drawCircle(
      c,
      rad * 0.85,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            const Color(0xFFFFC21A).withValues(alpha: 0.16 + 0.22 * heat),
            const Color(0xFFFFC21A).withValues(alpha: 0),
          ],
        ).createShader(disc),
    );

    final double beat = Cine.beat(Cine.fract(t * 6));
    final int n = (230 + 170 * heat).round();
    final double rx = rad * 0.98;
    final double ry = rad * 0.33;
    const double tilt = 0.2;

    DustRing.paint(
      canvas,
      center: c,
      rx: rx,
      ry: ry,
      tilt: tilt,
      t: t,
      n: n,
      front: false,
      alpha: 0.85,
      grain: 1.0,
      thick: 0.26,
      haze: 1,
      onLight: true,
    );

    if (img != null) {
      _photo(canvas, c, rad, beat);
    } else {
      _crystal(canvas, c, rad, beat);
    }

    DustRing.paint(
      canvas,
      center: c,
      rx: rx,
      ry: ry,
      tilt: tilt,
      t: t,
      n: n,
      front: true,
      alpha: 1,
      grain: 1.05,
      thick: 0.26,
      haze: 1,
      onLight: true,
    );
  }

  void _crystal(Canvas canvas, Offset c, double rad, double beat) {
    // The crystal heart.
    final double hw = rad * (0.6 + 0.03 * beat);
    final Offset hc = Offset(c.dx, c.dy - rad * 0.02);
    Offset at(Offset u) => Offset(hc.dx + u.dx * hw, hc.dy + u.dy * hw);
    const int k = 16;
    final List<Offset> outer = <Offset>[];
    final List<Offset> mid = <Offset>[];
    for (int i = 0; i < k; i++) {
      final Offset q = _pt(Cine.tau * i / k);
      outer.add(at(q));
      mid.add(
        at(
          Offset(
            q.dx * 0.55 + (Cine.hash(i + 40) - 0.5) * 0.1,
            q.dy * 0.55 + 0.02 + (Cine.hash(i + 90) - 0.5) * 0.1,
          ),
        ),
      );
    }
    final Offset mc = at(const Offset(0, -0.04));
    final Path body = Path();
    for (int i = 0; i <= 64; i++) {
      final Offset q = at(_pt(Cine.tau * i / 64));
      if (i == 0) {
        body.moveTo(q.dx, q.dy);
      } else {
        body.lineTo(q.dx, q.dy);
      }
    }
    body.close();
    canvas.drawPath(body, Paint()..color = _tone(0.25 + 0.2 * heat));
    final double sweep = Cine.fract(t * 2) * 3.4 - 1.7;
    final Paint fp = Paint();
    int id = 0;
    void facet(Offset a, Offset b, Offset d, Offset u) {
      final double lam = (-u.dx * 0.5 - u.dy * 0.6) * 0.5 + 0.62;
      double br = lam * (0.5 + 0.32 * heat) + 0.06 * heat;
      br += (Cine.hash(id * 7 + 3) - 0.5) * 0.34;
      final double dd = (u.dx * 0.8 + u.dy * 0.6) - sweep;
      br += 0.55 * math.exp(-dd * dd / 0.05) * (0.5 + 0.5 * heat);
      id++;
      fp.color = _tone(br);
      canvas.drawPath(
        Path()
          ..moveTo(a.dx, a.dy)
          ..lineTo(b.dx, b.dy)
          ..lineTo(d.dx, d.dy)
          ..close(),
        fp,
      );
    }

    for (int i = 0; i < k; i++) {
      final int j = (i + 1) % k;
      final Offset ua = _pt(Cine.tau * (i + 0.5) / k);
      facet(outer[i], outer[j], mid[i], ua);
      facet(mid[i], mid[j], outer[j], ua);
      facet(mid[i], mid[j], mc, Offset(ua.dx * 0.5, ua.dy * 0.5));
    }
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, hw * 0.1)
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFFB8740A),
    );
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.7, hw * 0.04)
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFFFFE9A0).withValues(alpha: 0.95),
    );

    // A glint that wakes and sleeps on the heart's shoulder.
    final double gl = math.pow(
      math.max(0.0, math.sin(Cine.tau * (t * 2 + 0.25))),
      6,
    ).toDouble();
    if (gl > 0.05) {
      final Offset gp = at(const Offset(-0.5, -0.55));
      final Paint sp = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.9 * gl)
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round;
      final double len = hw * (0.35 + 0.35 * gl);
      canvas.drawLine(gp.translate(-len, 0), gp.translate(len, 0), sp);
      canvas.drawLine(gp.translate(0, -len), gp.translate(0, len), sp);
    }
  }

  /// The owner's own golden heart: the picture, cut to the heart's
  /// outline, with a slow sheen that glides across it and a glint.
  void _photo(Canvas canvas, Offset c, double rad, double beat) {
    final ui.Image im = img!;
    final double k = im.width / 1244.0;
    final Rect src = Rect.fromLTWH(_px0 * k, _py0 * k, _pw * k, _ph * k);
    final double w = rad * (1.3 + 0.05 * beat);
    final double h = w * _ph / _pw;
    final Rect dst = Rect.fromCenter(
      center: Offset(c.dx, c.dy - rad * 0.02),
      width: w,
      height: h,
    );
    final Path clip = Path();
    for (int i = 0; i < _outline.length; i += 2) {
      final double x = dst.left + (_outline[i] * 1244 - _px0) / _pw * dst.width;
      final double y = dst.top + (_outline[i + 1] * 700 - _py0) / _ph * dst.height;
      if (i == 0) {
        clip.moveTo(x, y);
      } else {
        clip.lineTo(x, y);
      }
    }
    clip.close();
    canvas.save();
    canvas.clipPath(clip, doAntiAlias: true);
    canvas.saveLayer(dst.inflate(2), Paint());
    canvas.drawImageRect(
      im,
      src,
      dst,
      Paint()
        ..filterQuality = FilterQuality.high
        ..isAntiAlias = true,
    );
    // A band of light that glides over the gold, then rests.
    final double ph = Cine.fract(t * 2);
    final double p = -0.25 + 1.5 * ph;
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
            Color(0xFFFFF3C4).withValues(alpha: 0.38 + 0.2 * heat),
            const Color(0x00FFF3C4),
          ],
          stops: <double>[st(p - 0.14), st(p), st(p + 0.14)],
        ).createShader(dst),
    );
    canvas.restore();
    canvas.restore();

    // A glint that wakes and sleeps on the heart's shoulder.
    final double gl = math.pow(
      math.max(0.0, math.sin(Cine.tau * (t * 2 + 0.25))),
      6,
    ).toDouble();
    if (gl > 0.05) {
      final Offset gp = Offset(dst.left + dst.width * 0.3, dst.top + dst.height * 0.3);
      final Paint sp = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.9 * gl)
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round;
      final double len = w * (0.12 + 0.12 * gl);
      canvas.drawLine(gp.translate(-len, 0), gp.translate(len, 0), sp);
      canvas.drawLine(gp.translate(0, -len), gp.translate(0, len), sp);
    }
  }

  @override
  bool shouldRepaint(_MedallionPainter o) =>
      o.t != t || o.heat != heat || o.img != img;
}

// END OF FILE - lib/widgets/heart_medallion.dart
