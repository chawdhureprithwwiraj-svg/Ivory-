import 'dart:math' as math;
import 'package:flutter/material.dart';

/// The crown of the Wheel of Fans: the living golden feather and the
/// jewel card that declares the fortune.
///
/// The feather is no longer a sticker: it sits at the wheel's top notch,
/// breathes while the wheel rests, trembles while the feather decides,
/// and leans to the winning segment with a gold glow and three orbiting
/// sparkles when the fortune is declared. The fortune card is a framed
/// jewel — parchment gradient, double gold border, a kind medallion —
/// and it lives at the foot of the sky so the wheel and its winner stay
/// in view while the house speaks.
class LivingFeather extends StatefulWidget {
  const LivingFeather({
    super.key,
    this.mode = 'idle', // idle | spin | land
    this.lean = 0.0, // -1..1, horizontal direction of the winning segment
    this.size = 64,
  });
  final String mode;
  final double lean;
  final double size;

  @override
  State<LivingFeather> createState() => _LivingFeatherState();
}

class _LivingFeatherState extends State<LivingFeather>
    with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 3200))
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
      builder: (BuildContext context, Widget? _) {
        final double t = _t.value;
        double rot;
        double glow;
        if (widget.mode == 'spin') {
          rot = math.sin(t * 34) * 0.10;
          glow = 0.40;
        } else if (widget.mode == 'land') {
          rot = widget.lean * 0.30 + math.sin(t * 6.283) * 0.03;
          glow = 1.0;
        } else {
          rot = math.sin(t * 6.283) * 0.07;
          glow = 0.25 + 0.15 * math.sin(t * 6.283 * 2);
        }
        return IgnorePointer(
          child: SizedBox(
            width: widget.size * 1.6,
            height: widget.size * 1.25,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                CustomPaint(
                  painter: _FeatherGlow(glow),
                  size: Size.infinite,
                ),
                Transform.rotate(
                  angle: rot,
                  child: Image.asset(
                    'assets/wheels/wheel_feather.png',
                    height: widget.size,
                    fit: BoxFit.contain,
                    errorBuilder:
                        (BuildContext c, Object e, StackTrace? st) =>
                            CustomPaint(
                      size: Size(widget.size * 0.5, widget.size),
                      painter: _FeatherPaint(),
                    ),
                  ),
                ),
                if (widget.mode == 'land')
                  for (int i = 0; i < 3; i++)
                    Positioned(
                      left: widget.size * 0.8 +
                          math.cos(t * 6.283 + i * 2.094) * widget.size * 0.55,
                      top: widget.size * 0.62 +
                          math.sin(t * 6.283 + i * 2.094) * widget.size * 0.34,
                      child: CustomPaint(
                        size: const Size(7, 7),
                        painter: _Spark(i),
                      ),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A soft gold halo behind the feather; [g] is 0..1 of presence.
class _FeatherGlow extends CustomPainter {
  _FeatherGlow(this.g);
  final double g;

  @override
  void paint(Canvas canvas, Size size) {
    if (g <= 0.02) return;
    final Rect r = Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width * 0.9,
        height: size.height * 0.8);
    final Paint p = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          const Color(0xFFE7B14C).withOpacity(0.34 * g),
          const Color(0xFFE7B14C).withOpacity(0),
        ],
      ).createShader(r);
    canvas.drawOval(r, p);
  }

  @override
  bool shouldRepaint(_FeatherGlow o) => o.g != g;
}

/// A four-point sparkle that twinkles on its own index.
class _Spark extends CustomPainter {
  _Spark(this.i);
  final int i;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()
      ..color = const Color(0xFFFFF3C9).withOpacity(0.55 + 0.35 * (i % 2))
      ..strokeWidth = 1.1;
    final Offset c = Offset(size.width / 2, size.height / 2);
    canvas.drawLine(c - const Offset(3.2, 0), c + const Offset(3.2, 0), p);
    canvas.drawLine(c - const Offset(0, 3.2), c + const Offset(0, 3.2), p);
  }

  @override
  bool shouldRepaint(_Spark o) => false;
}

/// The painted stand-in feather: the owner's own art sits in the release.
class _FeatherPaint extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Path p = Path()
      ..moveTo(size.width / 2, size.height)
      ..quadraticBezierTo(0, size.height * 0.45, size.width / 2, 0)
      ..quadraticBezierTo(size.width, size.height * 0.45, size.width / 2,
          size.height);
    final Paint f = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[Color(0xFFF6D98A), Color(0xFFB9822B)],
      ).createShader(Offset.zero & size);
    canvas.drawPath(p, f);
    final Paint spine = Paint()
      ..color = const Color(0xFF7A5216)
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(size.width / 2, 2),
        Offset(size.width / 2, size.height - 2), spine);
  }

  @override
  bool shouldRepaint(_FeatherPaint o) => false;
}

/// The declared fortune, framed like a jewel at the foot of the sky.
class FortuneCard extends StatelessWidget {
  /// Read the house's own verdict map and frame it.
  static Widget fromPrize(Map<String, dynamic> prize) {
    final Map<String, dynamic> p = Map<String, dynamic>.from(
        prize['prize'] as Map? ?? <dynamic, dynamic>{});
    final String kind = (p['kind'] ?? '').toString();
    String title = 'THE FEATHER RESTS';
    String body =
        'Nothing this turn — and nothing lost. She returns at the next '
        'Gilded Hour.';
    if (kind == 'rupee') {
      title = '${p['value']} RUPEES TO YOUR PURSE';
      body = 'Your Fortune Purse now holds ₹${prize['purse']}.';
    } else if (kind == 'word') {
      title = 'A WORD FROM IVORY';
      body = '“${p['word']}” — ${p['line']}';
    } else if (kind == 'image') {
      title = 'AN IMAGE FROM IVORY';
      body = '“${p['title']}” is yours; find it in your inbox.';
    } else if (kind == 'voice') {
      title = 'A VOICE FROM IVORY';
      body = '“${p['title']}” is yours; find it in your inbox.';
    } else if (kind == 'letter') {
      title = 'A LETTER FROM IVORY';
      body = 'Ivory writes first this time. It reaches you within seven '
          'days — the house keeps its promises on a clock.';
    } else if (kind == 'moment') {
      title = 'A MOMENT FROM IVORY';
      body = 'A live moment with your name on it, within seven days.';
    } else if (kind == 'choice') {
      final String got = (p['got'] ?? '').toString();
      title = "THE FEATHER'S CHOICE";
      body = got == 'token'
          ? 'A Gilded Spin token joins your purse.'
          : got == 'rupee'
              ? 'Eleven rupees, chosen by the house itself.'
              : 'Your name rides the ticker — with Ivory\'s nod.';
    }
    return FortuneCard(
      kind: kind,
      title: title,
      body: body,
      note: (prize['note'] ?? '').toString(),
      petals: prize['petals'] as int? ?? 0,
    );
  }

  const FortuneCard({
    super.key,
    required this.kind,
    required this.title,
    required this.body,
    this.note = '',
    this.petals = 0,
  });
  final String kind;
  final String title;
  final String body;
  final String note;
  final int petals;

  String get _glyph {
    switch (kind) {
      case 'rupee':
        return '₹';
      case 'word':
        return '❝';
      case 'image':
        return '◉';
      case 'voice':
        return '♪';
      case 'letter':
        return '✉';
      case 'moment':
        return '✦';
      case 'choice':
        return '★';
      default:
        return '☾';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFFFFDF6), Color(0xFFF3E4C2)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7B14C), width: 2),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x66E7B14C), blurRadius: 26, offset: Offset(0, 8)),
          BoxShadow(color: Color(0x80200A10), blurRadius: 30, offset: Offset(0, 12)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: <Color>[
                      Color(0xFFFFF3C9),
                      Color(0xFFE7B14C),
                      Color(0xFF8A5E1C),
                    ],
                    stops: <double>[0.1, 0.6, 1],
                  ),
                  border: Border.all(color: const Color(0xFF7A5216), width: 1.2),
                ),
                alignment: Alignment.center,
                child: Text(_glyph,
                    style: const TextStyle(
                        color: Color(0xFF4A0E17),
                        fontSize: 18,
                        fontWeight: FontWeight.w900)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                        color: Color(0xFF4A0E17),
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Color(0xFF3A2318), fontSize: 13.5, height: 1.5)),
          if (note.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(note,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xFF8A5E1C),
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic)),
          ],
          if (petals > 0) ...<Widget>[
            const SizedBox(height: 8),
            Text(
                'Your unspent fortune bloomed into $petals laurel petal(s) '
                'owed to you.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xFF8A5E1C), fontSize: 12.5)),
          ],
        ],
      ),
    );
  }
}

// END OF FILE - lib/widgets/wheel_crown.dart
