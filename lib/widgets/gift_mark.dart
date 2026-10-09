import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';

/// ============================================================
/// IVORY - THE TWO GIFT MARKS.
///
/// These replace the raw emoji that used to sit on both gift
/// buttons. An emoji is drawn by the HANDSET, not by Ivory: the
/// same character is a pale envelope on one phone, a scarlet
/// cartoon on another. The single most important thing a member
/// can tap was the one thing the house did not control.
///
/// THERE ARE TWO MARKS AND THEY MUST NEVER BECOME ONE.
/// Live and post never borrow each other's clothes.
///
///   * `GiftMarkLetter` - ON A POST. A sealed letter: plum paper,
///     gold edge, a raised wax seal. A post is something she
///     made and you are writing back about it.
///   * `GiftMarkBell`   - IN THE ROOM. A struck bell in gold and
///     amber. Live is not correspondence, it is happening now,
///     in front of her, and a bell is heard rather than read.
///
/// THE SHEEN. Both carry a slow band of light that crosses the
/// mark, takes about a second and a half, and settles - then
/// waits roughly six seconds before coming round again. Owner's
/// choice, made deliberately over a constant sparkle: a thing
/// that glitters without stopping stops being noticed and
/// starts looking cheap. Light that passes is seen every time.
///
/// IT COSTS NOTHING WHEN IT IS NOT ON SCREEN. A feed builds its
/// posts lazily, so a mark scrolled well out of view is disposed
/// and its ticker dies with it. On a 4 GB phone that matters,
/// and it is why the sheen lives on ONE controller per mark with
/// no timers left running behind it.
/// ============================================================

/// Drives the travelling light. Everything visible is painted by
/// the two painters below; this only supplies the position.
class _Sheen extends StatefulWidget {
  const _Sheen({required this.size, required this.build});

  final double size;
  final Widget Function(double travel) build;

  @override
  State<_Sheen> createState() => _SheenState();
}

class _SheenState extends State<_Sheen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 6000),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (BuildContext context, Widget? _) {
          // The light crosses during the first quarter of the
          // cycle and is simply absent for the rest. Eased, so it
          // arrives and leaves rather than snapping past.
          final double v = _c.value;
          final double travel = v > 0.25
              ? -1
              : Curves.easeInOut.transform(v / 0.25);
          return widget.build(travel);
        },
      ),
    );
  }
}

/// Paints the band of light over whatever was drawn, and only
/// over it. `saveLayer` + `srcATop` keeps the light inside the
/// mark's own silhouette - no glow leaking into the page.
void _paintSheen(Canvas canvas, Size size, double travel) {
  if (travel < 0) return;
  final double w = size.width;
  // Starts off one edge and finishes off the other.
  final double x = -w * 0.6 + travel * w * 1.9;
  final Rect band = Rect.fromLTWH(x, -w * 0.3, w * 0.42, w * 1.6);
  final Paint p = Paint()
    ..blendMode = BlendMode.srcATop
    ..shader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: <Color>[
        IvoryColors.cream.withValues(alpha: 0),
        IvoryColors.cream.withValues(alpha: 0.72),
        IvoryColors.cream.withValues(alpha: 0),
      ],
    ).createShader(band);
  canvas.save();
  // Leaned over, so it reads as light and not as a wipe.
  canvas.translate(w * 0.5, w * 0.5);
  canvas.rotate(-0.42);
  canvas.translate(-w * 0.5, -w * 0.5);
  canvas.drawRect(band, p);
  canvas.restore();
}

// =====================================================================
// ON A POST - THE SEALED LETTER
// =====================================================================

class GiftMarkLetter extends StatelessWidget {
  const GiftMarkLetter({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Send a gift',
      child: _Sheen(
        size: size,
        build: (double t) => CustomPaint(
          painter: _LetterPainter(t),
          size: Size.square(size),
        ),
      ),
    );
  }
}

class _LetterPainter extends CustomPainter {
  const _LetterPainter(this.travel);

  final double travel;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    canvas.saveLayer(Offset.zero & size, Paint());

    // ---- the envelope ----
    final RRect body = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.06, h * 0.22, w * 0.88, h * 0.58),
      Radius.circular(w * 0.08),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[IvoryColors.plum, IvoryColors.burgundy],
        ).createShader(body.outerRect),
    );

    // ---- the flap, as two folded planes so it reads as paper ----
    final Path left = Path()
      ..moveTo(w * 0.06, h * 0.26)
      ..lineTo(w * 0.5, h * 0.58)
      ..lineTo(w * 0.06, h * 0.78)
      ..close();
    final Path right = Path()
      ..moveTo(w * 0.94, h * 0.26)
      ..lineTo(w * 0.5, h * 0.58)
      ..lineTo(w * 0.94, h * 0.78)
      ..close();
    canvas.drawPath(
      left,
      Paint()..color = IvoryColors.burgundy.withValues(alpha: 0.55),
    );
    canvas.drawPath(
      right,
      Paint()..color = IvoryColors.plum.withValues(alpha: 0.5),
    );

    // ---- the gold edge ----
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.055
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[IvoryColors.gold, IvoryColors.amber],
        ).createShader(body.outerRect),
    );

    // ---- the wax seal ----
    // THREE DRAFTS. Six spokes read as a wagon wheel; a
    // concentric ring read as a bullseye. Wax is neither: it is
    // a blob that was pressed, so its edge WOBBLES and its light
    // comes from one side. The wobble is what stops it looking
    // like a printed dot, and it is the only detail that
    // survives being shrunk to 22 pixels.
    final Offset c = Offset(w * 0.5, h * 0.6);
    final double r = w * 0.2;
    final Path wax = Path();
    for (int i = 0; i <= 24; i++) {
      final double a = i * math.pi * 2 / 24;
      final double rr = r * (1 + 0.045 * math.sin(a * 7 + 0.7));
      final Offset p = c + Offset(math.cos(a), math.sin(a)) * rr;
      if (i == 0) {
        wax.moveTo(p.dx, p.dy);
      } else {
        wax.lineTo(p.dx, p.dy);
      }
    }
    wax.close();
    canvas.drawPath(
      wax,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.45, -0.55),
          colors: <Color>[
            IvoryColors.cream,
            IvoryColors.gold,
            IvoryColors.amber,
          ],
          stops: const <double>[0.0, 0.42, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r * 1.1)),
    );
    // One soft crescent of shadow on the far side gives it the
    // thickness of poured wax instead of a flat coin.
    canvas.save();
    canvas.clipPath(wax);
    canvas.drawCircle(
      c + Offset(r * 0.42, r * 0.46),
      r * 0.92,
      Paint()..color = IvoryColors.burgundy.withValues(alpha: 0.22),
    );
    canvas.restore();

    _paintSheen(canvas, size, travel);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LetterPainter old) => old.travel != travel;
}

// =====================================================================
// IN THE ROOM - THE STRUCK BELL
// =====================================================================

class GiftMarkBell extends StatelessWidget {
  const GiftMarkBell({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Send a gift',
      child: _Sheen(
        size: size,
        build: (double t) => CustomPaint(
          painter: _BellPainter(t),
          size: Size.square(size),
        ),
      ),
    );
  }
}

class _BellPainter extends CustomPainter {
  const _BellPainter(this.travel);

  final double travel;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    canvas.saveLayer(Offset.zero & size, Paint());

    // ---- the body: two shoulders curving down to a wide mouth ----
    final Path bell = Path()
      ..moveTo(w * 0.5, h * 0.12)
      ..cubicTo(w * 0.73, h * 0.14, w * 0.78, h * 0.42, w * 0.80, h * 0.62)
      ..lineTo(w * 0.86, h * 0.72)
      ..lineTo(w * 0.14, h * 0.72)
      ..lineTo(w * 0.20, h * 0.62)
      ..cubicTo(w * 0.22, h * 0.42, w * 0.27, h * 0.14, w * 0.5, h * 0.12)
      ..close();
    canvas.drawPath(
      bell,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            IvoryColors.cream,
            IvoryColors.gold,
            IvoryColors.amber,
          ],
          stops: <double>[0.0, 0.45, 1.0],
        ).createShader(bell.getBounds()),
    );
    canvas.drawPath(
      bell,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.045
        ..strokeJoin = StrokeJoin.round
        ..color = IvoryColors.burgundy.withValues(alpha: 0.55),
    );

    // ---- the dark mouth, which is what makes it a bell and not
    //      a hat, and the clapper swung to one side ----
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.73),
        width: w * 0.70,
        height: h * 0.12,
      ),
      Paint()..color = IvoryColors.plum.withValues(alpha: 0.78),
    );
    canvas.drawCircle(
      Offset(w * 0.56, h * 0.775),
      w * 0.062,
      Paint()..color = IvoryColors.burgundy,
    );

    // ---- the crown loop ----
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.11),
        width: w * 0.2,
        height: h * 0.16,
      ),
      math.pi,
      math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.06
        ..strokeCap = StrokeCap.round
        ..color = IvoryColors.gold,
    );

    // ---- it has just been struck: two arcs each side, the far
    //      one fainter, so the sound reads as travelling out ----
    final Paint ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = w * 0.05;
    for (int i = 0; i < 2; i++) {
      final double rad = w * (0.44 + i * 0.13);
      ring.color = IvoryColors.amber.withValues(alpha: 0.75 - i * 0.38);
      canvas.drawArc(
        Rect.fromCircle(center: Offset(w * 0.5, h * 0.46), radius: rad),
        -2.95,
        0.62,
        false,
        ring,
      );
      canvas.drawArc(
        Rect.fromCircle(center: Offset(w * 0.5, h * 0.46), radius: rad),
        -0.82,
        0.62,
        false,
        ring,
      );
    }

    _paintSheen(canvas, size, travel);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BellPainter old) => old.travel != travel;
}

// END OF FILE - lib/widgets/gift_mark.dart
