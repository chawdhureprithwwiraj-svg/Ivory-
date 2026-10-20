import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';

/// A personal writing shelf, deliberately not styled as another inbox.
///
/// It is a raised, lifted button of rich Dark Ivory (a deep warm ivory)
/// with a thick golden edge beneath it, a glassy reflection over the
/// top, a streak of light that sweeps across now and then, ribbons of
/// real, truly golden silk with a bright edge, and a few sparkles
/// spread evenly (never crowded). The whole card breathes very slowly
/// (one breath in four seconds) so the member's eye is drawn here:
/// this is the door to the Folio. When pressed it sinks, then springs
/// back up.
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

  bool _down = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _press(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedBuilder(
        animation: _c,
        builder: (BuildContext context, Widget? child) {
          // One slow breath: 0 -> 1 -> 0.
          final double br = 0.5 - 0.5 * math.cos(2 * math.pi * _c.value);
          return Transform.scale(
            scale: 1 + 0.016 * br,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: const Color(0xFFB37A0A).withValues(
                      alpha: 0.32 + 0.18 * br,
                    ),
                    blurRadius: 14 + 10 * br,
                    offset: const Offset(0, 9),
                  ),
                  BoxShadow(
                    color: const Color(0xFFFFC928).withValues(
                      alpha: 0.12 + 0.4 * br,
                    ),
                    blurRadius: 12 + 14 * br,
                    spreadRadius: 0.5 + 1.5 * br,
                  ),
                ],
              ),
              child: child,
            ),
          );
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (TapDownDetails _) => _press(true),
          onTapUp: (TapUpDetails _) => _press(false),
          onTapCancel: () => _press(false),
          onTap: widget.onOpen,
          child: Stack(
            children: <Widget>[
              // The thick golden edge under the button (its raised side).
              Positioned(
                left: 0,
                right: 0,
                top: 8,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Color(0xFFE9AE17),
                        Color(0xFFB77A06),
                        Color(0xFF8F5B00),
                      ],
                    ),
                  ),
                ),
              ),
              // The face of the button, lifted.
              AnimatedPadding(
                duration: const Duration(milliseconds: 110),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(
                  top: _down ? 5.0 : 0.0,
                  bottom: _down ? 3.0 : 8.0,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: CustomPaint(
                    painter: _FolioFacePainter(repaint: _c),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(17, 17, 15, 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFE3A915),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 54,
                            height: 58,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: <Color>[
                                  Color(0xFF8A2238),
                                  Color(0xFF4A0E17),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: const Color(0xFFF2C230),
                                width: 1.3,
                              ),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: const Color(0xFF4A0E17).withValues(
                                    alpha: 0.45,
                                  ),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: <Widget>[
                                Positioned(
                                  left: 3,
                                  right: 3,
                                  top: 2,
                                  height: 18,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: <Color>[
                                          const Color(0xFFFFFFFF).withValues(
                                            alpha: 0.32,
                                          ),
                                          const Color(0xFFFFFFFF).withValues(
                                            alpha: 0,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
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
                                      color: Color(0xFFFFD34D),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'THE QUIET FOLIO',
                                  style: TextStyle(
                                    color: Color(0xFF7A4E00),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.45,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'Unsent words. Good links. Things worth keeping.',
                                  style: TextStyle(
                                    color: IvoryColors.burgundy,
                                    fontSize: 13,
                                    height: 1.35,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'PRIVATE TO YOUR ACCOUNT  ·  OPEN FOLIO  ›',
                                  style: TextStyle(
                                    color: Color(0xFF6B2A3A),
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
            ],
          ),
        ),
      ),
    );
  }
}

/// The face: rich Dark Ivory, golden silk ribbons, glassy reflection,
/// a raised bevel, a sweep of light and a few evenly spread sparkles.
class _FolioFacePainter extends CustomPainter {
  _FolioFacePainter({required this.repaint}) : super(repaint: repaint);

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
    final double br = 0.5 - 0.5 * math.cos(2 * math.pi * t);

    // Rich Dark Ivory.
    canvas.drawRect(
      all,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFFBF3BE),
            Color(0xFFF5E9A0),
            Color(0xFFF2E58F),
            Color(0xFFEBD97A),
          ],
          stops: <double>[0, 0.38, 0.6, 1],
        ).createShader(all),
    );

    // Ribbons of truly golden silk.
    final List<Path> ribbons = <Path>[
      Path()
        ..moveTo(w * 0.72, -6)
        ..cubicTo(w * 0.79, h * 0.24, w * 0.94, h * 0.06, w + 6, h * 0.34),
      Path()
        ..moveTo(-6, h * 0.62)
        ..cubicTo(w * 0.06, h * 0.84, w * 0.13, h * 0.96, w * 0.26, h + 6),
      Path()
        ..moveTo(w * 0.88, h + 6)
        ..cubicTo(w * 0.92, h * 0.92, w * 0.98, h * 0.86, w + 6, h * 0.72),
    ];
    const List<double> widths = <double>[13, 11, 6];
    for (int r = 0; r < ribbons.length; r++) {
      final Path p = ribbons[r];
      final double wd = widths[r];
      canvas.drawPath(
        p.shift(const Offset(0, 3)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = wd
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF8F5B00).withValues(alpha: 0.4),
      );
      canvas.drawPath(
        p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = wd
          ..strokeCap = StrokeCap.round
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFFFFE066),
              Color(0xFFF2B01E),
              Color(0xFFFFF0A0),
              Color(0xFFD9960C),
              Color(0xFFB97A06),
            ],
          ).createShader(all),
      );
      canvas.drawPath(
        p.shift(Offset(0, -wd * 0.24)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = wd * 0.26
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.9),
      );
    }

    // Glassy reflection over the upper part.
    final Rect topR = Rect.fromLTWH(0, 0, w, h * 0.48);
    canvas.drawRect(
      topR,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            const Color(0xFFFFFFFF).withValues(alpha: 0.6),
            const Color(0xFFFFFFFF).withValues(alpha: 0.12),
            const Color(0xFFFFFFFF).withValues(alpha: 0),
          ],
          stops: const <double>[0, 0.62, 1],
        ).createShader(topR),
    );

    // Raised bevel: light along the top and left, shade along the bottom.
    final Rect botR = Rect.fromLTWH(0, h * 0.8, w, h * 0.2);
    canvas.drawRect(
      botR,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            const Color(0xFFBE8C14).withValues(alpha: 0),
            const Color(0xFFBE8C14).withValues(alpha: 0.42),
          ],
        ).createShader(botR),
    );
    final Paint edge = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.8
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.9);
    canvas.drawLine(Offset(20, 3), Offset(w - 20, 3), edge);
    canvas.drawLine(
      Offset(3, 20),
      Offset(3, h - 20),
      edge..color = const Color(0xFFFFFFFF).withValues(alpha: 0.55),
    );

    // A streak of light that sweeps across once a breath-and-a-half.
    final double p = (t / 0.6).clamp(0.0, 1.0).toDouble();
    if (p < 1) {
      final double bw = w * 0.3;
      final double x = -bw + (w + bw * 2) * p;
      final Rect band = Rect.fromLTWH(x, -h, bw, h * 3);
      canvas.save();
      canvas.translate(w / 2, h / 2);
      canvas.rotate(0.34);
      canvas.translate(-w / 2, -h / 2);
      canvas.drawRect(
        band,
        Paint()
          ..shader = LinearGradient(
            colors: <Color>[
              const Color(0xFFFFFFFF).withValues(alpha: 0),
              const Color(0xFFFFFFFF).withValues(alpha: 0.7),
              const Color(0xFFFFFFFF).withValues(alpha: 0),
            ],
          ).createShader(band),
      );
      canvas.restore();
    }

    // The slow pulse also brightens the whole face a little.
    canvas.drawRect(
      all,
      Paint()..color = const Color(0xFFFFFBE0).withValues(alpha: 0.1 * br),
    );

    // A few sparkles, one in each cell of a loose grid: evenly spread.
    const int cols = 5;
    const int rows = 2;
    final Paint dot = Paint();
    final Paint line = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.0;
    for (int i = 0; i < cols * rows; i++) {
      final int cx = i % cols;
      final int cy = i ~/ cols;
      final double x = w * (cx + 0.2 + 0.6 * _h(i + 1)) / cols;
      final double y = h * (cy + 0.2 + 0.6 * _h(i + 50)) / rows;
      final double ph = (t * (1 + i % 2) + _h(i + 90)) % 1.0;
      final double tw = math.pow(
        math.max(0.0, math.sin(math.pi * ph)),
        5,
      ).toDouble();
      if (tw < 0.08) continue;
      final double len = 2.5 + 4.5 * tw;
      line.color = const Color(0xFFFFFFFF).withValues(alpha: 0.9 * tw);
      canvas.drawLine(Offset(x - len, y), Offset(x + len, y), line);
      canvas.drawLine(Offset(x, y - len), Offset(x, y + len), line);
      dot.color = const Color(0xFFFFFFFF).withValues(alpha: tw);
      canvas.drawCircle(Offset(x, y), 0.8 + 0.8 * tw, dot);
    }
  }

  @override
  bool shouldRepaint(_FolioFacePainter o) => false;
}

// END OF FILE - lib/widgets/profile_folio_card.dart
