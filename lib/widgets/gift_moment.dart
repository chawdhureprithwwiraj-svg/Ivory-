import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';

/// ============================================================
/// IVORY - THE GIFT MOMENT
///
/// A seven-second celebration when a gift is sent: the emoji
/// pops in on a gold ring burst while sparks fly out, then the
/// name card lands underneath. Pure Flutter - no assets, no
/// libraries, one short-lived controller, gone when it is done.
/// Tap anywhere to skip it.
/// ============================================================

class GiftMoment {
  static void show(
    BuildContext context, {
    required String emoji,
    required String name,
    String? from,
  }) {
    final OverlayState ov = Overlay.of(context);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _Moment(
        emoji: emoji,
        name: name,
        from: from,
        onDone: () => entry.remove(),
      ),
    );
    ov.insert(entry);
  }
}

class _Spark {
  _Spark(this.angle, this.dist, this.size, this.delay, this.color);
  final double angle;
  final double dist;
  final double size;
  final double delay;
  final Color color;
}

class _Moment extends StatefulWidget {
  const _Moment({
    required this.emoji,
    required this.name,
    this.from,
    required this.onDone,
  });

  final String emoji;
  final String name;
  final String? from;
  final VoidCallback onDone;

  @override
  State<_Moment> createState() => _MomentState();
}

class _MomentState extends State<_Moment>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 7000),
  );
  final List<_Spark> _sparks = <_Spark>[];

  @override
  void initState() {
    super.initState();
    const List<Color> cols = <Color>[
      Color(0xFFD4AF37),
      Color(0xFFE3A857),
      Color(0xFFFFB366),
      Color(0xFF4A0E17),
    ];
    final Random rnd = Random(7);
    for (int i = 0; i < 26; i++) {
      _sparks.add(_Spark(
        rnd.nextDouble() * 2 * pi,
        90 + rnd.nextDouble() * 160,
        2.5 + rnd.nextDouble() * 4.5,
        rnd.nextDouble() * 0.35,
        cols[i % cols.length],
      ));
    }
    _c.forward().then((_) => widget.onDone());
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDone,
      child: AnimatedBuilder(
        animation: _c,
        builder: (BuildContext context, Widget? child) {
          final double t = _c.value;
          final double fade = t < 0.85 ? 1 : max(0.0, 1 - (t - 0.85) / 0.15);
          final double pop =
              Curves.elasticOut.transform(min(1.0, t / 0.3));
          return Opacity(
            opacity: fade,
            child: Container(
              color: IvoryColors.burgundy.withValues(alpha: 0.35),
              child: Stack(
                children: <Widget>[
                  CustomPaint(
                    size: Size.infinite,
                    painter: _SparkPainter(t, _sparks),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Transform.scale(
                          scale: pop,
                          child: Text(widget.emoji,
                              style: const TextStyle(fontSize: 88)),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 22, vertical: 12),
                          decoration: BoxDecoration(
                            color: IvoryColors.surface,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                widget.name,
                                style: TextStyle(
                                  fontFamily: IvoryTheme.displayFont,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 19,
                                  color: IvoryColors.burgundy,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                widget.from ?? 'a gift',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: IvoryColors.textFaint,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.t, this.sparks);

  final double t;
  final List<_Spark> sparks;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);

    final double ring = min(1, t / 0.5);
    if (ring < 1) {
      final Paint p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = const Color(0xFFD4AF37).withValues(alpha: (1 - ring) * 0.8);
      canvas.drawCircle(c, 60 + ring * 140, p);
    }

    for (final _Spark s in sparks) {
      final double p = ((t - s.delay) / (1 - s.delay)).clamp(0.0, 1.0);
      if (p <= 0) continue;
      final double ease = 1 - pow(1 - p, 3).toDouble();
      final double r = 40 + s.dist * ease;
      final Offset pos =
          c + Offset(cos(s.angle) * r, sin(s.angle) * r * 0.9);
      canvas.drawCircle(
        pos,
        s.size * (1 - p * 0.5),
        Paint()..color = s.color.withValues(alpha: 1 - p),
      );
    }
  }

  @override
  bool shouldRepaint(_SparkPainter old) => true;
}

// END OF FILE - lib/widgets/gift_moment.dart
