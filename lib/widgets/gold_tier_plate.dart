import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';
import 'ivory_sheen.dart';

/// ============================================================
/// IVORY - THE MEMBERSHIP SCREEN, IN ROYAL METAL
///
/// Every plate on the Membership screen is a shade of gold, and each
/// tier is a deeper gold than the one before it, so climbing feels
/// like climbing in richness. The shade comes from the tier's
/// POSITION in the list (see `shadeFor`), never from a fixed count,
/// so adding, removing or renaming tiers in the database still looks
/// right. Words stay deep burgundy so they read perfectly.
///
/// Each plate is brushed metal: fine hairlines, a coin-edge ring on
/// the deeper plates, and on the top plate a crowned seal with three
/// jewels. Behind every plate a very quiet light lives - a slow
/// sheen, a few twinkling grains, a breathing halo on the crown -
/// quicker and a little brighter as the tier rises, but always
/// whisper-soft. The plate marked `shine` also keeps the one slow
/// crossing light of the house.
/// ============================================================
class GoldTierPlate extends StatefulWidget {
  const GoldTierPlate({
    super.key,
    required this.child,
    this.shade = 0,
    this.shine = false,
    this.radius = 22,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;

  /// 0 (pale champagne) to 3 (deep antique gold).
  final int shade;
  final bool shine;
  final double radius;
  final EdgeInsets padding;

  /// The page behind the plates: champagne falling to warm gold.
  static const LinearGradient pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      Color(0xFFFFF3CF),
      Color(0xFFF7DE95),
      Color(0xFFEBC66A),
      Color(0xFFE2B352),
    ],
    stops: <double>[0, 0.45, 0.8, 1],
  );

  /// Position in the list to a shade from 0 to 3.
  static int shadeFor(int index, int count) =>
      count <= 1 ? 0 : (index * 3 / (count - 1)).round();

  static const List<List<Color>> _tones = <List<Color>>[
    <Color>[Color(0xFFFFF9E0), Color(0xFFFBEAB4), Color(0xFFF2D88A)],
    <Color>[Color(0xFFFFEFB8), Color(0xFFF7D876), Color(0xFFE9BE52)],
    <Color>[Color(0xFFF8D771), Color(0xFFE8B63F), Color(0xFFD29A2A)],
    <Color>[Color(0xFFF1C657), Color(0xFFDCA132), Color(0xFFC58A1E)],
  ];

  @override
  State<GoldTierPlate> createState() => _GoldTierPlateState();
}

class _GoldTierPlateState extends State<GoldTierPlate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _beat;

  static int _clampShade(int s) => s < 0 ? 0 : (s > 3 ? 3 : s);

  /// One quiet loop per plate: slower on the pale tiers, a little
  /// livelier as the gold deepens. Never fast, never loud.
  static Duration _period(int shade) {
    switch (shade) {
      case 0:
        return const Duration(seconds: 16);
      case 1:
        return const Duration(seconds: 13);
      case 2:
        return const Duration(seconds: 11);
      default:
        return const Duration(seconds: 9);
    }
  }

  @override
  void initState() {
    super.initState();
    _beat = AnimationController(
      vsync: this,
      duration: _period(_clampShade(widget.shade)),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant GoldTierPlate old) {
    super.didUpdateWidget(old);
    if (old.shade != widget.shade) {
      _beat.duration = _period(_clampShade(widget.shade));
    }
  }

  @override
  void dispose() {
    _beat.dispose();
    super.dispose();
  }

  Widget _skin(double travel) {
    final int s = _clampShade(widget.shade);
    return CustomPaint(
      painter: _MetalPainter(
        GoldTierPlate._tones[s],
        widget.radius,
        travel,
        _beat.value,
        s,
      ),
      child: Padding(padding: widget.padding, child: widget.child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.radius),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x77B9801F), blurRadius: 18, offset: Offset(0, 9)),
          BoxShadow(color: Color(0x33A0640A), blurRadius: 5, offset: Offset(0, 2)),
        ],
      ),
      child: widget.shine
          ? IvorySheen(
              period: const Duration(seconds: 9),
              crossing: 0.22,
              child: _skin,
            )
          : _skin(-1),
    );
  }
}

/// A deterministic sparkle seed so the grains never jump between
/// frames: the i-th grain always sits in the same place.
double _seed(int i) {
  final double x = math.sin(i * 127.1) * 43758.5453;
  return x - x.floor();
}

class _MetalPainter extends CustomPainter {
  const _MetalPainter(this.tones, this.radius, this.travel, this.beat, this.shade);

  final List<Color> tones;
  final double radius;
  final double travel;
  final double beat;
  final int shade;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect r = Offset.zero & size;
    final RRect rr = RRect.fromRectAndRadius(
      r.deflate(0.75),
      Radius.circular(radius),
    );
    canvas.saveLayer(r, Paint());
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: tones,
        ).createShader(r),
    );
    canvas.save();
    canvas.clipRRect(rr);
    _brush(canvas, size);
    if (shade >= 2) _damask(canvas, size);
    _quietSheen(canvas, size);
    _grains(canvas, size);
    canvas.drawRect(
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0x00C58A1E), Color(0x00C58A1E), Color(0x4CA0640A)],
          stops: <double>[0, 0.6, 1],
        ).createShader(r),
    );
    canvas.drawRect(
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.8, -1.2),
          radius: 1.0,
          colors: <Color>[Color(0x80FFFFFF), Color(0x00FFFFFF)],
        ).createShader(r),
    );
    // A thin reflected light just above the bottom edge: metal depth.
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - 12, size.width, 12),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: <Color>[Color(0x2BFFFFFF), Color(0x00FFFFFF)],
        ).createShader(Rect.fromLTWH(0, size.height - 12, size.width, 12)),
    );
    if (shade >= 2) _coinEdge(canvas, rr);
    if (shade == 3) _seal(canvas, size);
    canvas.restore();
    // Bevel: bright top edge fading down.
    canvas.drawRRect(
      rr.deflate(0.8),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xE6FFFFFF), Color(0x00FFFFFF)],
          stops: <double>[0, 0.35],
        ).createShader(r),
    );
    // Inner pale hairline, then the deep gold rim outside it.
    canvas.drawRRect(
      rr.deflate(2.6),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = const Color(0x55FFF9E0),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0xD9A8731A),
    );
    paintIvorySheen(canvas, size, travel, strength: 0.5);
    canvas.restore();
  }

  /// Fine brushed hairlines; the brush angle turns with the tier.
  void _brush(Canvas canvas, Size size) {
    const List<double> angle = <double>[0, 1.5708, 1.0472, 1.5708];
    final double gap = shade == 3 ? 3.0 : 4.0;
    final double alpha = 0.045 + 0.012 * shade;
    final double diag = math.sqrt(
      size.width * size.width + size.height * size.height,
    );
    final Paint p = Paint()
      ..strokeWidth = 1
      ..color = Color.fromRGBO(255, 255, 255, alpha);
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(angle[shade]);
    for (double y = -diag / 2; y < diag / 2; y += gap) {
      canvas.drawLine(Offset(-diag / 2, y), Offset(diag / 2, y), p);
    }
    canvas.restore();
  }

  /// Two offset dot grids, like an embossed damask under the metal.
  void _damask(Canvas canvas, Size size) {
    final Paint a = Paint()..color = const Color(0x14FFF6D6);
    final Paint b = Paint()..color = const Color(0x12A0640A);
    for (double x = 6; x < size.width; x += 26) {
      for (double y = 8; y < size.height; y += 26) {
        canvas.drawCircle(Offset(x, y), 1.3, a);
        canvas.drawCircle(Offset(x + 13, y + 13), 1.1, b);
      }
    }
  }

  /// The quiet light behind each plate: one soft band drifting
  /// across, brighter by a whisper as the tier rises.
  void _quietSheen(Canvas canvas, Size size) {
    final double w = size.width;
    final double band = w * 0.34;
    final double x = -band + (w + band * 2) * beat;
    final double alpha = 0.05 + 0.02 * shade;
    canvas.save();
    canvas.rotate(-0.16);
    canvas.drawRect(
      Rect.fromLTWH(x - band, -size.height, band, size.height * 3),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[
            const Color(0x00FFFFFF),
            Color.fromRGBO(255, 255, 255, alpha),
            const Color(0x00FFFFFF),
          ],
        ).createShader(Rect.fromLTWH(x - band, -size.height, band, size.height * 3)),
    );
    canvas.restore();
  }

  /// A few twinkling grains of gold dust on the metal.
  void _grains(Canvas canvas, Size size) {
    final int n = 8 + 4 * shade;
    final double speed = 1 + shade * 0.35;
    for (int i = 0; i < n; i++) {
      final double px = _seed(i) * size.width;
      final double py = _seed(i + 31) * size.height;
      final double tw = 0.5 + 0.5 * math.sin(2 * math.pi * (beat * speed + _seed(i + 7)));
      final Paint p = Paint()
        ..color = Color.fromRGBO(255, 255, 255, (0.05 + 0.03 * shade) * tw);
      canvas.drawCircle(Offset(px, py), 0.7 + _seed(i + 13) * 0.8, p);
    }
  }

  /// The engraved coin edge of the deeper plates.
  void _coinEdge(Canvas canvas, RRect rr) {
    final Path path = Path()..addRRect(rr.deflate(7));
    final Paint p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0x59A0640A);
    for (final PathMetric m in path.computeMetrics()) {
      for (double d = 0; d < m.length; d += 10) {
        canvas.drawPath(m.extractPath(d, math.min(d + 5, m.length)), p);
      }
    }
  }

  /// The crowned seal of the innermost circle, bottom right, with a
  /// breathing halo and three jewels: ruby, amethyst, jade.
  void _seal(Canvas canvas, Size size) {
    final double cx = size.width - 44;
    final double cy = size.height - 40;
    final double breath = 0.10 + 0.05 * math.sin(2 * math.pi * beat);
    canvas.drawCircle(
      Offset(cx, cy),
      46,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            Color.fromRGBO(255, 250, 228, breath),
            const Color(0x00FFFBE8),
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 46)),
    );
    final Path crown = Path()
      ..moveTo(cx - 16, cy + 6)
      ..lineTo(cx - 11, cy - 8)
      ..lineTo(cx - 4, cy)
      ..lineTo(cx, cy - 10)
      ..lineTo(cx + 4, cy)
      ..lineTo(cx + 11, cy - 8)
      ..lineTo(cx + 16, cy + 6)
      ..close();
    canvas.drawPath(
      crown,
      Paint()
        ..color = const Color(0xE6FFF3CF)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      crown,
      Paint()
        ..color = const Color(0x66A0640A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 16, cy + 7, 32, 4),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xE6FFF3CF),
    );
    const List<Color> jewels = <Color>[
      Color(0xFFD42450),
      Color(0xFF9A55E6),
      Color(0xFF14B87A),
    ];
    for (int i = 0; i < 3; i++) {
      final Offset o = Offset(cx - 12 + i * 12, cy + 17);
      canvas.drawCircle(o, 3.0, Paint()..color = jewels[i]);
      canvas.drawCircle(
        o,
        3.6,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = const Color(0xCCFFF3CF),
      );
    }
  }

  @override
  bool shouldRepaint(_MetalPainter old) =>
      old.travel != travel ||
      old.beat != beat ||
      old.tones != tones ||
      old.radius != radius ||
      old.shade != shade;
}

/// The gold button of a tier. `deep` is for the deeper plates, where a
/// pale button stands out; on the pale plates the button is deeper gold.
class GoldTierButton extends StatelessWidget {
  const GoldTierButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.deep = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool deep;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.55 : 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: deep
                ? const <Color>[
                    Color(0xFFFFFBE8),
                    Color(0xFFFFF8D8),
                    Color(0xFFF8DB7A),
                    Color(0xFFE3B040),
                  ]
                : const <Color>[
                    Color(0xFFFBE39A),
                    Color(0xFFF6D26A),
                    Color(0xFFE2A93A),
                    Color(0xFFC98A22),
                  ],
            stops: const <double>[0, 0.12, 0.5, 1],
          ),
          border: Border.all(color: const Color(0xFFA8731A)),
          boxShadow: const <BoxShadow>[
            BoxShadow(color: Color(0x77A8731A), blurRadius: 9, offset: Offset(0, 4)),
            BoxShadow(color: Color(0x33A0640A), blurRadius: 3, offset: Offset(0, 1)),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(icon, size: 18, color: IvoryColors.burgundy),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: IvoryColors.burgundy,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// END OF FILE - lib/widgets/gold_tier_plate.dart
