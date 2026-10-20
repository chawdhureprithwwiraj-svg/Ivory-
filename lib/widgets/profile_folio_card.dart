import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';

/// A personal writing shelf, deliberately not styled as another inbox.
///
/// It is pure ivory, shot through with a few ribbons of rich, real
/// gold whose grains glitter, and the whole card breathes very slowly
/// (about one breath in four seconds) so the member's eye is drawn
/// here: this is the door to the Folio.
class ProfileFolioCard extends StatefulWidget {
  const ProfileFolioCard({super.key, required this.onOpen});

  final VoidCallback onOpen;

  @override
  State<ProfileFolioCard> createState() => _ProfileFolioCardState();
}

class _ProfileFolioCardState extends State<ProfileFolioCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedBuilder(
        animation: _c,
        builder: (BuildContext context, Widget? child) {
          // One slow breath: 0 -> 1 -> 0.
          final double br = 0.5 - 0.5 * math.cos(2 * math.pi * _c.value);
          return Transform.scale(
            scale: 1 + 0.012 * br,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: const Color(0xFFE5A91A).withValues(
                      alpha: 0.18 + 0.3 * br,
                    ),
                    blurRadius: 10 + 14 * br,
                    spreadRadius: 0.5 + 1.5 * br,
                  ),
                ],
              ),
              child: child,
            ),
          );
        },
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: widget.onOpen,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: CustomPaint(
                painter: _GildedPainter(repaint: _c),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(17, 16, 15, 15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: IvoryColors.gold, width: 1.25),
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 54,
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: IvoryColors.deepGradient,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: IvoryColors.gold,
                            width: 1.1,
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            const Icon(
                              Icons.menu_book_rounded,
                              color: IvoryColors.cream,
                              size: 28,
                            ),
                            Positioned(
                              right: 8,
                              top: 7,
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: IvoryColors.gold,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'THE QUIET FOLIO',
                              style: TextStyle(
                                color: IvoryColors.amber,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.45,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'Unsent words. Good links. Things worth keeping.',
                              style: TextStyle(
                                color: IvoryColors.burgundy,
                                fontSize: 13,
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'PRIVATE TO YOUR ACCOUNT  ·  OPEN FOLIO  ›',
                              style: TextStyle(
                                color: IvoryColors.plum,
                                fontSize: 9.3,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.55,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ivory paper with ribbons of gold and glittering grains.
class _GildedPainter extends CustomPainter {
  _GildedPainter({required this.repaint}) : super(repaint: repaint);

  final Animation<double> repaint;

  static double _h(int n) {
    final double s = math.sin(n * 12.9898 + 78.233) * 43758.5453;
    return s - s.floorToDouble();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Rect all = Offset.zero & size;
    final double t = repaint.value;

    // The ivory itself, with a soft sheen travelling very slowly.
    canvas.drawRect(
      all,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFFFFEF8),
            Color(0xFFFBF3DC),
            Color(0xFFFFFCF2),
          ],
          stops: <double>[0, 0.55, 1],
        ).createShader(all),
    );

    // Ribbons of gold.
    final List<Path> ribbons = <Path>[
      Path()
        ..moveTo(w * 0.74, -4)
        ..cubicTo(w * 0.8, h * 0.2, w * 0.94, h * 0.06, w + 4, h * 0.3),
      Path()
        ..moveTo(-4, h * 0.66)
        ..cubicTo(w * 0.06, h * 0.86, w * 0.13, h * 0.96, w * 0.25, h + 4),
      Path()
        ..moveTo(w * 0.9, h + 4)
        ..cubicTo(w * 0.93, h * 0.92, w * 0.98, h * 0.88, w + 4, h * 0.76),
    ];
    const List<double> widths = <double>[11, 9, 5];
    for (int r = 0; r < ribbons.length; r++) {
      final Path p = ribbons[r];
      final double wd = widths[r];
      // A soft shadow under the ribbon.
      canvas.drawPath(
        p.shift(const Offset(0, 2.2)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = wd
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFFC9962A).withValues(alpha: 0.22),
      );
      // The gold body, lit from the upper left.
      canvas.drawPath(
        p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = wd
          ..strokeCap = StrokeCap.round
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: const <Color>[
              Color(0xFFF7D56A),
              Color(0xFFD69A12),
              Color(0xFFFFE9A0),
              Color(0xFFB87A08),
            ],
          ).createShader(all),
      );
      // The bright edge of the silk.
      canvas.drawPath(
        p.shift(Offset(0, -wd * 0.22)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = wd * 0.26
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFFFFF6D0).withValues(alpha: 0.85),
      );
    }

    // Glitter: grains scattered along the ribbons that wake and sleep.
    final Paint dot = Paint();
    final Paint line = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.0;
    int id = 0;
    for (int r = 0; r < ribbons.length; r++) {
      for (final m in ribbons[r].computeMetrics()) {
        final int count = r == 2 ? 14 : 22;
        for (int i = 0; i < count; i++) {
          id++;
          final double d = m.length * (i + _h(id)) / count;
          final tg = m.getTangentForOffset(d);
          if (tg == null) continue;
          final double off = (_h(id + 500) - 0.5) * widths[r] * 1.5;
          final Offset p = Offset(
            tg.position.dx - tg.vector.dy * off * 0.1,
            tg.position.dy + tg.vector.dx * off * 0.1,
          );
          final double ph = (t * (2 + id % 3) + _h(id + 900)) % 1.0;
          final double tw = math.pow(
            math.max(0.0, math.sin(math.pi * ph)),
            4,
          ).toDouble();
          final double rad = 0.5 + 0.9 * _h(id + 300);
          dot.color = const Color(0xFFFFF3B8).withValues(alpha: 0.25 + 0.6 * tw);
          canvas.drawCircle(p, rad + 0.7 * tw, dot);
          if (tw > 0.5) {
            final double len = 2.5 + 4.5 * tw * (0.6 + 0.6 * _h(id + 700));
            line.color = const Color(0xFFFFFFFF).withValues(alpha: 0.9 * tw);
            canvas.drawLine(p.translate(-len, 0), p.translate(len, 0), line);
            canvas.drawLine(p.translate(0, -len), p.translate(0, len), line);
          }
        }
      }
    }

    // A few loose flecks of gold dust on the ivory.
    for (int i = 0; i < 26; i++) {
      final double x = w * _h(i * 3 + 1000);
      final double y = h * _h(i * 3 + 1001);
      final double ph = (t * 2 + _h(i + 1100)) % 1.0;
      final double tw = math.pow(
        math.max(0.0, math.sin(math.pi * ph)),
        3,
      ).toDouble();
      dot.color = const Color(0xFFE0A21C).withValues(alpha: 0.18 + 0.5 * tw);
      canvas.drawCircle(Offset(x, y), 0.6 + 0.8 * _h(i + 1200), dot);
    }
  }

  @override
  bool shouldRepaint(_GildedPainter o) => false;
}

// END OF FILE - lib/widgets/profile_folio_card.dart
