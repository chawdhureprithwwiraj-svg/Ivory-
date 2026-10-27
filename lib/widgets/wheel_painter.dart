import 'dart:math' as math;
import 'package:flutter/material.dart';

/// One painted segment of the Wheel of Fans.
class WheelSeg {
  const WheelSeg(this.label, this.color, this.kind);
  final String label;
  final Color color;
  final String kind;
}

/// The wheel itself, painted like a piece of court jewellery: domed
/// segment gradients, an inner cream filigree ring, a cast-gold bevel rim
/// with twenty-four notches and twelve jewel studs seated one per
/// segment, embossed gold rupee marks, engraved separators, a travelling
/// specular shine and a cream coin hub whose glyph scales with the wheel
/// (the old fixed-size glyph swallowed the small medallion whole).
/// In [mini] mode labels are dropped and the jewels carry the whole
/// reading — that is the medallion's language.
class WheelPainter extends CustomPainter {
  WheelPainter({
    required this.segs,
    required this.angle,
    this.shine = 0.0,
    this.dim = false,
    this.mini = false,
  });

  final List<WheelSeg> segs;
  final double angle; // radians, whole-wheel rotation
  final double shine; // 0..1 travelling highlight position
  final bool dim;
  final bool mini;

  static Color shade(Color c, double t) {
    if (t >= 0) {
      return Color.fromRGBO(
          (c.red + (255 - c.red) * t).round(),
          (c.green + (255 - c.green) * t).round(),
          (c.blue + (255 - c.blue) * t).round(),
          1);
    }
    final double k = 1 + t;
    return Color.fromRGBO((c.red * k).round().clamp(0, 255).toInt(),
        (c.green * k).round().clamp(0, 255).toInt(),
        (c.blue * k).round().clamp(0, 255).toInt(), 1);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double r = size.shortestSide / 2;
    final Offset c = Offset(size.width / 2, size.height / 2);
    final int n = segs.isEmpty ? 12 : segs.length;
    final double arc = 6.283185307 / n;

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(angle);

    // velvet under-shadow: the wheel sits ON something
    final Paint sh = Paint()
      ..color = Color.fromRGBO(32, 10, 16, dim ? 0.16 : 0.40);
    canvas.drawCircle(Offset(0, r * 0.035), r, sh);

    // segments: domed radial gradients, bright heart to deep edge
    for (int i = 0; i < n; i++) {
      final WheelSeg s = segs[i % segs.length];
      final double a0 = i * arc - 1.5707963;
      final Path p = Path()
        ..moveTo(0, 0)
        ..arcTo(Rect.fromCircle(center: Offset.zero, radius: r * 0.90),
            a0, arc, false)
        ..close();
      final Color base = s.color;
      final Paint fill = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.15, -0.25),
          radius: 1.25,
          colors: <Color>[
            shade(base, 0.46),
            base,
            shade(base, -0.38),
          ],
          stops: const <double>[0.10, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));
      canvas.drawPath(p, fill);

      // engraved gold separator between segments
      final Paint sep = Paint()
        ..color = const Color(0x66FFE9B8)
        ..strokeWidth = mini ? 0.8 : 1.6;
      canvas.drawLine(Offset.zero, Offset.fromDirection(a0, r * 0.895), sep);

      if (!mini) {
        // label, rotated to stand upright on its segment
        canvas.save();
        canvas.rotate(a0 + arc / 2);
        final bool rupee = s.kind == 'rupee' || s.kind == 'choice';
        final TextPainter tp = TextPainter(
          text: TextSpan(
            text: rupee
                ? s.label
                : (s.kind == 'rest' ? 'rests' : s.label.toLowerCase()),
            style: TextStyle(
              color: s.kind == 'rest'
                  ? const Color(0xFF5C5142)
                  : (rupee ? const Color(0xFFFFF3C9) : const Color(0xFFFFF6E5)),
              fontSize: rupee ? r * 0.150 : r * 0.072,
              fontWeight: rupee ? FontWeight.w900 : FontWeight.w700,
              letterSpacing: rupee ? 0.4 : 1.1,
              shadows: const <Shadow>[
                Shadow(color: Color(0xB3200A10), blurRadius: 4, offset: Offset(0, 1.5)),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(r * 0.60 - tp.width / 2, -tp.height / 2));
        canvas.restore();
      }

      // jewel stud seated on the rim at each segment's heart
      final double ja = a0 + arc / 2;
      final Offset jp = Offset.fromDirection(ja, r * 0.955);
      final Paint jewel = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.4),
          colors: <Color>[shade(s.color, 0.65), s.color, shade(s.color, -0.45)],
          stops: const <double>[0.08, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: jp, radius: r * 0.045));
      canvas.drawCircle(jp, r * (mini ? 0.055 : 0.042), jewel);
      final Paint glint = Paint()
        ..color = const Color(0xCCFFFFFF);
      canvas.drawCircle(jp - Offset(r * 0.012, r * 0.012),
          r * (mini ? 0.014 : 0.010), glint);
    }

    // travelling specular shine: a soft white sweep across the dome
    if (shine > 0 && shine < 1) {
      final double sa = shine * 6.283185307;
      final Paint gl = Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            const Color(0x4DFFFFFF),
            const Color(0x00FFFFFF),
          ],
        ).createShader(Rect.fromCircle(
            center: Offset.fromDirection(sa, r * 0.45), radius: r * 0.75));
      canvas.drawCircle(Offset.zero, r * 0.90, gl);
    }

    // inner cream filigree ring, between dome and rim
    final Paint fil = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0x80FFF6E5)
      ..strokeWidth = mini ? 1.0 : r * 0.012;
    canvas.drawCircle(Offset.zero, r * 0.905, fil);

    // cast-gold bevel rim
    final Paint rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * (mini ? 0.13 : 0.085)
      ..shader = SweepGradient(
        colors: const <Color>[
          Color(0xFFF6D98A),
          Color(0xFFB9822B),
          Color(0xFFF6D98A),
          Color(0xFF8A5E1C),
          Color(0xFFF6D98A),
        ],
        stops: const <double>[0, 0.25, 0.5, 0.75, 1],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));
    canvas.drawCircle(Offset.zero, r * 0.965, rim);
    final Paint notch = Paint()
      ..color = const Color(0xFF7A5216)
      ..strokeWidth = r * 0.014;
    for (int k = 0; k < 24; k++) {
      final double a = k * 6.283185307 / 24;
      canvas.drawLine(Offset.fromDirection(a, r * 0.925),
          Offset.fromDirection(a, r * 1.0), notch);
    }

    // cream coin hub, embossed, glyph scaled to the wheel
    final double hr = r * (mini ? 0.30 : 0.20);
    final Paint hub = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.35),
        colors: const <Color>[
          Color(0xFFFFFDF6),
          Color(0xFFF3E4C2),
          Color(0xFFD9BE8A),
        ],
        stops: const <double>[0.1, 0.65, 1],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: hr));
    canvas.drawCircle(Offset.zero, hr, hub);
    final Paint hubRing = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.018
      ..color = const Color(0xFFB9822B);
    canvas.drawCircle(Offset.zero, hr, hubRing);
    final TextPainter mark = TextPainter(
      text: TextSpan(
        text: '✦',
        style: TextStyle(
            color: const Color(0xFF4A0E17),
            fontSize: hr * 1.15,
            fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    mark.paint(canvas, Offset(-mark.width / 2, -mark.height / 2));

    canvas.restore();
  }

  @override
  bool shouldRepaint(WheelPainter old) => old.angle != angle ||
      old.shine != shine ||
      old.dim != dim ||
      old.mini != mini;
}

/// The living sky behind every wheel surface: a night-plum field with
/// three aurora ribbons (magenta, teal, marigold) sweeping on sines,
/// marigold petals and teal sparks rising, and twinkle stars. One
/// painter, one controller — the room and the salon share it, so the
/// whole wheel world breathes in the same rhythm.
class WheelSky extends StatefulWidget {
  const WheelSky({super.key, this.dense = true});
  final bool dense;

  @override
  State<WheelSky> createState() => _WheelSkyState();
}

class _WheelSkyState extends State<WheelSky>
    with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(
      vsync: this, duration: const Duration(seconds: 11))
    ..repeat();

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (BuildContext context, Widget? _) => CustomPaint(
        painter: _SkyPainter(t: _t.value, dense: widget.dense),
      ),
    );
  }
}

class _SkyPainter extends CustomPainter {
  _SkyPainter({required this.t, required this.dense});
  final double t;
  final bool dense;
  static const List<Color> _hues = <Color>[
    Color(0xFFFF4081),
    Color(0xFF00BFA5),
    Color(0xFFFFB300),
    Color(0xFF7C4DFF),
    Color(0xFFFF6E40),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final Rect full = Offset.zero & size;
    final Paint bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[Color(0xFF241033), Color(0xFF1E1B3A), Color(0xFF3A0D1C)],
        stops: <double>[0, 0.55, 1],
      ).createShader(full);
    canvas.drawRect(full, bg);

    // aurora ribbons: three soft diagonal bands drifting on sines
    for (int i = 0; i < 3; i++) {
      final double y =
          size.height * (0.18 + 0.26 * i) + math.sin(t * 6.283 + i * 2.1) * 26;
      final Paint a = Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[
            _hues[i].withOpacity(0),
            _hues[i].withOpacity(0.16),
            _hues[(i + 1) % 5].withOpacity(0.10),
            _hues[i].withOpacity(0),
          ],
          stops: <double>[
            0,
            0.35 + 0.10 * math.sin(t * 6.283 + i),
            0.7,
            1
          ],
        ).createShader(Rect.fromLTWH(0, y - 46, size.width, 92));
      canvas.save();
      canvas.translate(size.width / 2, y);
      canvas.rotate(-0.16 + 0.05 * math.sin(t * 6.283 + i * 1.7));
      canvas.translate(-size.width / 2, -y);
      canvas.drawRect(Rect.fromLTWH(-40, y - 46, size.width + 80, 92), a);
      canvas.restore();
    }

    // rising petals and sparks, deterministic per index
    final int n = dense ? 26 : 14;
    for (int i = 0; i < n; i++) {
      final double seed = i * 0.61803398875;
      final double x = (seed * 977) % 1 * size.width;
      final double speed = 0.05 + (seed * 31 % 1) * 0.10;
      final double y = size.height * (1 - ((t * speed + seed) % 1));
      final double wob = math.sin(t * 6.283 * 0.7 + i) * 14;
      final Color col = _hues[i % 5];
      final double tw = 0.5 + 0.5 * math.sin(t * 6.283 * 1.3 + i * 2.4);
      final Paint p = Paint()..color = col.withOpacity(0.10 + 0.30 * tw);
      if (i % 3 == 0) {
        // petal: a small rotated ellipse
        canvas.save();
        canvas.translate(x + wob, y);
        canvas.rotate(t * 3 + i);
        canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 11, height: 5.2), p);
        canvas.restore();
      } else {
        canvas.drawCircle(Offset(x + wob * 0.5, y), 1.3 + 1.5 * tw, p);
      }
    }

    // twinkle stars, high up
    for (int i = 0; i < 12; i++) {
      final double seed = i * 0.75487766624;
      final double x = (seed * 613) % 1 * size.width;
      final double y = (seed * 211) % 1 * size.height * 0.45;
      final double tw = 0.5 + 0.5 * math.sin(t * 6.283 * 2 + i * 1.9);
      final Paint s = Paint()
        ..color = const Color(0xFFFFE9B8).withOpacity(0.10 + 0.45 * tw);
      canvas.drawCircle(Offset(x, y), 0.8 + 1.1 * tw, s);
    }
  }

  @override
  bool shouldRepaint(_SkyPainter old) => old.t != t;
}

/// The royal crest header shared by the room and the salon: a small
/// living wheel turning beside the house name in gold letters.
class WheelCrest extends StatelessWidget {
  const WheelCrest({super.key, this.onClose, this.title = 'THE WHEEL OF FANS'});
  final VoidCallback? onClose;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 4),
      child: Row(
        children: <Widget>[
          _SpinSeal(),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFFFFE9B8),
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.6,
                shadows: <Shadow>[
                  Shadow(color: Color(0x99B3261E), blurRadius: 8),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: onClose ?? () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Color(0xFFFFD98A)),
          ),
        ],
      ),
    );
  }
}

class _SpinSeal extends StatefulWidget {
  @override
  State<_SpinSeal> createState() => _SpinSealState();
}

class _SpinSealState extends State<_SpinSeal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(
      vsync: this, duration: const Duration(seconds: 9))
    ..repeat();

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (BuildContext context, Widget? _) => Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE7B14C), width: 1.6),
          boxShadow: const <BoxShadow>[
            BoxShadow(color: Color(0x66E7B14C), blurRadius: 10),
          ],
        ),
        child: CustomPaint(
          painter: WheelPainter(
            segs: const <WheelSeg>[
              WheelSeg('', Color(0xFFFFB300), 'rupee'),
              WheelSeg('', Color(0xFFFF4081), 'word'),
              WheelSeg('', Color(0xFFFF7A00), 'rupee'),
              WheelSeg('', Color(0xFF00BFA5), 'rest'),
              WheelSeg('', Color(0xFF00C853), 'rupee'),
              WheelSeg('', Color(0xFF7C4DFF), 'image'),
              WheelSeg('', Color(0xFFD50000), 'rupee'),
              WheelSeg('', Color(0xFFE91E63), 'letter'),
            ],
            angle: _t.value * 1.2,
            mini: true,
          ),
        ),
      ),
    );
  }
}

// END OF FILE - lib/widgets/wheel_painter.dart
