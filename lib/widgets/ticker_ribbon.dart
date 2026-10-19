import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/ticker_service.dart';
import 'ticker_palettes.dart';

/// ============================================================
/// IVORY - THE RIBBON ITSELF
///
/// A rich little jewel-box ribbon: a flowing gradient body with a
/// glossy top, a pale trim, a sweeping glint, painted four-point
/// twinkle stars, and a 3D medallion (rim, bevel, highlight, shadow).
/// A Grand ribbon is a touch larger, with a rotating ring of light
/// around the medallion and a burst of gold sparkles as it arrives.
/// Ten colours, none of them blue, none of them black.
/// ============================================================
Path _star(Offset c, double r) {
  final double k = r * 0.22;
  return Path()
    ..moveTo(c.dx, c.dy - r)
    ..quadraticBezierTo(c.dx + k, c.dy - k, c.dx + r, c.dy)
    ..quadraticBezierTo(c.dx + k, c.dy + k, c.dx, c.dy + r)
    ..quadraticBezierTo(c.dx - k, c.dy + k, c.dx - r, c.dy)
    ..quadraticBezierTo(c.dx - k, c.dy - k, c.dx, c.dy - r)
    ..close();
}

void _twinkle(Canvas canvas, Offset c, double r, double a, Color glow) {
  if (a <= 0.02 || r <= 0.3) return;
  canvas.drawCircle(
    c,
    r * 0.95,
    Paint()
      ..color = glow.withValues(alpha: 0.5 * a)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.7),
  );
  canvas.drawPath(
    _star(c, r),
    Paint()..color = Colors.white.withValues(alpha: a.clamp(0.0, 1.0)),
  );
}

/// The body of the ribbon.
class _PillPainter extends CustomPainter {
  _PillPainter(this.pal, this.t, this.grand) : super(repaint: t);

  final TickerPalette pal;
  final Animation<double> t;
  final bool grand;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final RRect rr = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(h / 2),
    );
    // Drop shadow, and a soft glow in the ribbon's own colour.
    canvas.drawRRect(
      rr.shift(const Offset(0, 5)),
      Paint()
        ..color = pal.deep.withValues(alpha: 0.42)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
    final double pulse = 0.5 + 0.5 * math.sin(t.value * math.pi * 8);
    canvas.drawRRect(
      rr.inflate(grand ? 3 : 1),
      Paint()
        ..color = pal.light.withValues(alpha: (grand ? 0.42 : 0.26) + 0.14 * pulse)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, grand ? 12 : 8),
    );
    // Body: a gradient that flows slowly along the ribbon.
    final double rw = w * 1.3;
    final double dx = -t.value * rw;
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = LinearGradient(
          colors: <Color>[pal.base, pal.mid, pal.light, pal.mid, pal.base],
          tileMode: TileMode.mirror,
        ).createShader(Rect.fromLTWH(dx, 0, rw, h)),
    );
    canvas.save();
    canvas.clipRRect(rr);
    // Glossy top.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h * 0.52),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.white.withValues(alpha: 0.40),
            Colors.white.withValues(alpha: 0.02),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h * 0.52)),
    );
    // A little depth along the bottom edge.
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.6, w, h * 0.4),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            pal.deep.withValues(alpha: 0.0),
            pal.deep.withValues(alpha: 0.38),
          ],
        ).createShader(Rect.fromLTWH(0, h * 0.6, w, h * 0.4)),
    );
    // The glint that sweeps across.
    final double gx = -w * 0.3 + (w * 1.6) * ((t.value * 2.4) % 1.0);
    final Path band = Path()
      ..moveTo(gx + 10, 0)
      ..lineTo(gx + 34, 0)
      ..lineTo(gx + 24, h)
      ..lineTo(gx, h)
      ..close();
    canvas.drawPath(
      band,
      Paint()
        ..shader = LinearGradient(
          colors: <Color>[
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: 0.5),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(gx, 0, 34, h)),
    );
    canvas.restore();
    // Pale trim and a fine inner highlight.
    canvas.drawRRect(
      rr.deflate(0.7),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            pal.trim,
            pal.trim.withValues(alpha: 0.5),
            pal.trim,
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawRRect(
      rr.deflate(2.4),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = Colors.white.withValues(alpha: 0.2),
    );
  }

  @override
  bool shouldRepaint(covariant _PillPainter old) =>
      old.pal != pal || old.grand != grand;
}

/// Painted twinkle stars across the ribbon (and the gold burst of a
/// Grand ribbon as it arrives).
class _SparklePainter extends CustomPainter {
  _SparklePainter(this.pal, this.t, this.grand, this.seed, this.medal)
    : super(repaint: t) {
    final math.Random r = math.Random(seed);
    final int n = grand ? 9 : 5;
    for (int i = 0; i < n; i++) {
      _fx.add(0.24 + r.nextDouble() * 0.74);
      _fy.add(0.12 + r.nextDouble() * 0.76);
      _ph.add(r.nextDouble());
      _sz.add(2.6 + r.nextDouble() * (grand ? 3.6 : 2.6));
    }
  }

  final TickerPalette pal;
  final Animation<double> t;
  final bool grand;
  final int seed;
  final double medal;
  final List<double> _fx = <double>[];
  final List<double> _fy = <double>[];
  final List<double> _ph = <double>[];
  final List<double> _sz = <double>[];

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < _fx.length; i++) {
      final double s = math.sin(2 * math.pi * (t.value * 4 + _ph[i]));
      final double a = s <= 0 ? 0.0 : s * s;
      _twinkle(
        canvas,
        Offset(_fx[i] * size.width, _fy[i] * size.height),
        _sz[i] * (0.4 + 0.6 * a),
        a,
        pal.trim,
      );
    }
    if (grand) {
      final double b = ((t.value - 0.02) / 0.2).clamp(0.0, 1.0);
      if (b > 0 && b < 1) {
        final Offset c = Offset(8 + medal / 2, size.height / 2);
        final double e = Curves.easeOut.transform(b);
        for (int i = 0; i < 10; i++) {
          final double ang = (i / 10) * 2 * math.pi + 0.3;
          final double d = 8 + 30 * e;
          _twinkle(
            canvas,
            c + Offset(math.cos(ang) * d, math.sin(ang) * d * 0.8),
            (i.isEven ? 5.5 : 3.6) * (1 - 0.5 * b),
            (1 - b),
            const Color(0xFFFFE9A8),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter old) =>
      old.pal != pal || old.seed != seed;
}

/// The 3D medallion.
class _MedalPainter extends CustomPainter {
  _MedalPainter(this.pal, this.t, this.grand) : super(repaint: t);

  final TickerPalette pal;
  final Animation<double> t;
  final bool grand;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);
    final double r = size.width / 2;
    canvas.drawCircle(
      c + Offset(0, r * 0.2),
      r,
      Paint()
        ..color = pal.deep.withValues(alpha: 0.55)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.38),
    );
    // Metal rim.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = SweepGradient(
          transform: GradientRotation(t.value * math.pi * 2),
          colors: <Color>[
            pal.trim,
            Colors.white,
            Color.lerp(pal.trim, pal.mid, 0.5)!,
            pal.trim,
            Colors.white,
            Color.lerp(pal.trim, pal.mid, 0.45)!,
            pal.trim,
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    // Bevel: light at the top left, shade at the bottom right.
    final double rd = r * 0.8;
    canvas.drawCircle(
      c,
      rd + r * 0.08,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.12
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Colors.white.withValues(alpha: 0.7),
            pal.deep.withValues(alpha: 0.55),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    // The jewel disc.
    canvas.drawCircle(
      c,
      rd,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          radius: 1.0,
          colors: <Color>[pal.light, pal.mid, pal.base],
          stops: const <double>[0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: rd)),
    );
    // Specular highlight and a tiny second glint.
    final Rect hi = Rect.fromCenter(
      center: c + Offset(-rd * 0.28, -rd * 0.46),
      width: rd * 0.95,
      height: rd * 0.46,
    );
    canvas.drawOval(
      hi,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.white.withValues(alpha: 0.85),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(hi),
    );
    canvas.drawCircle(
      c + Offset(rd * 0.42, rd * 0.46),
      r * 0.07,
      Paint()..color = Colors.white.withValues(alpha: 0.6),
    );
    if (grand) {
      // A ring of light turning around the medallion.
      final Rect ring = Rect.fromCircle(center: c, radius: r + 4);
      final Paint glow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          transform: GradientRotation(t.value * math.pi * 2 * 4),
          colors: const <Color>[
            Color(0x00FFE9A8),
            Color(0xFFFFE9A8),
            Color(0x00FFE9A8),
            Color(0x00FFE9A8),
            Color(0xCCFFFFFF),
            Color(0x00FFE9A8),
          ],
          stops: const <double>[0.0, 0.12, 0.3, 0.5, 0.62, 0.8],
        ).createShader(ring);
      canvas.drawCircle(c, r + 4, glow);
      canvas.drawCircle(
        c,
        r + 4,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
          ..shader = glow.shader,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MedalPainter old) =>
      old.pal != pal || old.grand != grand;
}

/// One ribbon, drawn. [t] runs 0 to 1 over the crossing.
class TickerPill extends StatelessWidget {
  const TickerPill({super.key, required this.show, required this.t});

  final TickerShow show;
  final Animation<double> t;

  List<Shadow> _shadows(TickerPalette p) {
    if (!p.outline) {
      return <Shadow>[
        Shadow(
          color: p.deep.withValues(alpha: 0.6),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ];
    }
    const List<Offset> d = <Offset>[
      Offset(0.9, 0),
      Offset(-0.9, 0),
      Offset(0, 0.9),
      Offset(0, -0.9),
      Offset(0.7, 0.7),
      Offset(-0.7, 0.7),
      Offset(0.7, -0.7),
      Offset(-0.7, -0.7),
    ];
    return <Shadow>[
      for (final Offset o in d) Shadow(color: p.deep, offset: o),
      Shadow(
        color: p.deep.withValues(alpha: 0.7),
        blurRadius: 3,
        offset: const Offset(0, 1),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final TickerPalette p = kTickerPalettes[show.palette % kTickerPalettes.length];
    final bool grand = show.grand;
    final double medal = grand ? 34 : 30;
    final List<Shadow> sh = _shadows(p);
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: grand ? 50 : 46),
      child: Stack(
        alignment: Alignment.centerLeft,
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned.fill(
            child: CustomPaint(painter: _PillPainter(p, t, grand)),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(8, 5, grand ? 18 : 15, 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  width: medal,
                  height: medal,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      Positioned.fill(
                        child: CustomPaint(painter: _MedalPainter(p, t, grand)),
                      ),
                      Icon(
                        tickerGlyph(show.event.kind),
                        size: grand ? 18 : 16,
                        color: kTickerCream,
                        shadows: <Shadow>[
                          Shadow(
                            color: p.deep.withValues(alpha: 0.7),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 9),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (show.label.isNotEmpty)
                        Text(
                          show.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: p.trim,
                            fontSize: 8.6,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.6,
                            height: 1.2,
                            shadows: sh,
                          ),
                        ),
                      Text(
                        show.text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: kTickerCream,
                          fontSize: 11.8,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                          shadows: sh,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _SparklePainter(p, t, grand, show.seed, medal),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// END OF FILE - lib/widgets/ticker_ribbon.dart
