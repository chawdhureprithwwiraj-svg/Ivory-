import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/ivory_theme.dart';

/// ============================================================
/// IVORY - THE PRIVATE LINE, DRAWN
///
/// A cream envelope, a deep-burgundy wax seal stamped with an "I",
/// and the little film of a letter being sealed and sent. Pure
/// drawing and one soft haptic: no pictures, no sound.
/// ============================================================

const Color _waxLight = Color(0xFF8A2A38);
const Color _waxDeep = IvoryColors.burgundy;

/// A wax seal. [press] 0..1 plays the stamp: it lands from above, the
/// wax spreads, a faint ring ripples out. At 1 it simply rests.
class LineSealPainter extends CustomPainter {
  const LineSealPainter({this.press = 1});

  final double press;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);
    final double r = size.shortestSide * 0.36;
    final double p = press.clamp(0.0, 1.0);

    // Landing: big and faint, then pressed down a little too far.
    double scale = 1;
    double alpha = 1;
    if (p < 0.5) {
      final double k = Curves.easeIn.transform(p / 0.5);
      scale = 1.5 - 0.58 * k;
      alpha = 0.15 + 0.85 * k;
    } else {
      final double k = Curves.easeOut.transform((p - 0.5) / 0.5);
      scale = 0.92 + 0.08 * k;
    }
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(scale);

    // The ripple.
    if (p > 0.5 && p < 1) {
      final double k = (p - 0.5) / 0.5;
      canvas.drawCircle(
        Offset.zero,
        r * (1.05 + 0.8 * k),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = _waxLight.withValues(alpha: 0.5 * (1 - k)),
      );
    }

    // The wax: a round blob with a slightly wavy edge and two drips.
    final Path wax = Path();
    const int steps = 72;
    for (int i = 0; i <= steps; i++) {
      final double a = i / steps * math.pi * 2;
      final double rr = r *
          (1 +
              0.05 * math.sin(a * 7 + 0.6) +
              0.025 * math.sin(a * 13 + 1.7));
      final Offset o = Offset(math.cos(a) * rr, math.sin(a) * rr);
      if (i == 0) {
        wax.moveTo(o.dx, o.dy);
      } else {
        wax.lineTo(o.dx, o.dy);
      }
    }
    wax.close();
    canvas.drawShadow(wax, _waxDeep.withValues(alpha: 0.6), 4, false);
    final Rect box = Rect.fromCircle(center: Offset.zero, radius: r * 1.1);
    canvas.drawPath(
      wax,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          radius: 1.0,
          colors: <Color>[
            _waxLight.withValues(alpha: alpha),
            _waxDeep.withValues(alpha: alpha),
          ],
        ).createShader(box),
    );
    // The pressed rim.
    canvas.drawCircle(
      Offset.zero,
      r * 0.74,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.07
        ..color = _waxLight.withValues(alpha: 0.55 * alpha),
    );
    // The gloss.
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: r * 0.88),
      math.pi * 1.1,
      math.pi * 0.35,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = r * 0.07
        ..color = const Color(0xFFFBFFF8).withValues(alpha: 0.35 * alpha),
    );
    // The "I".
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: 'I',
        style: TextStyle(
          color: IvoryColors.ivory.withValues(alpha: 0.92 * alpha),
          fontFamily: IvoryTheme.displayFont,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w800,
          fontSize: r * 1.15,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(LineSealPainter old) => old.press != press;
}

/// An envelope: [flap] 0 = closed, 1 = open with the letter rising out;
/// [seal] 0 = no seal yet, otherwise the stamp's progress.
class LineEnvelopePainter extends CustomPainter {
  const LineEnvelopePainter({this.flap = 0, this.seal = 1, this.lift = 0});

  final double flap;
  final double seal;

  /// How far the letter inside is raised (only seen while the flap is up).
  final double lift;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Rect body = Rect.fromLTWH(w * 0.06, h * 0.24, w * 0.88, h * 0.62);
    final RRect rb = RRect.fromRectAndRadius(body, Radius.circular(w * 0.04));

    final double tipY = body.top + body.height * 0.58 -
        flap * (body.height * 0.58 + body.height * 0.55);
    final Path fl = Path()
      ..moveTo(body.left, body.top)
      ..lineTo(body.right, body.top)
      ..lineTo(body.center.dx, tipY)
      ..close();
    final Paint flapFill = Paint()
      ..color = Color.lerp(
        IvoryColors.surfaceWarm,
        const Color(0xFFF1E3C6),
        flap,
      )!;
    final Paint flapLine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = IvoryColors.emeraldLight.withValues(alpha: 0.35);
    // An open flap is behind the letter; a closing one is in front.
    if (flap > 0.5) {
      canvas.drawPath(fl, flapFill);
      canvas.drawPath(fl, flapLine);
    }

    // The letter inside.
    if (flap > 0.02) {
      final double up = body.height * (0.04 + 0.62 * lift);
      final Rect paper = Rect.fromLTWH(
        body.left + body.width * 0.08,
        body.top - up + body.height * 0.12,
        body.width * 0.84,
        body.height * 0.78,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(paper, Radius.circular(w * 0.02)),
        Paint()..color = const Color(0xFFFFFDF6),
      );
      final Paint ink = Paint()
        ..color = IvoryColors.emeraldLight.withValues(alpha: 0.4)
        ..strokeWidth = 1.2;
      for (int i = 0; i < 4; i++) {
        final double y = paper.top + paper.height * (0.18 + 0.17 * i);
        canvas.drawLine(
          Offset(paper.left + paper.width * 0.12, y),
          Offset(paper.right - paper.width * (i == 3 ? 0.4 : 0.12), y),
          ink,
        );
      }
    }

    // The envelope body.
    canvas.drawShadow(
      Path()..addRRect(rb),
      _waxDeep.withValues(alpha: 0.5),
      5,
      false,
    );
    canvas.drawRRect(
      rb,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[IvoryColors.surface, IvoryColors.surfaceWarm],
        ).createShader(body),
    );
    canvas.drawRRect(
      rb,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = IvoryColors.emeraldLight.withValues(alpha: 0.35),
    );
    // The folds at the bottom.
    final Paint fold = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = IvoryColors.emeraldLight.withValues(alpha: 0.3);
    canvas.drawLine(
      Offset(body.left, body.bottom),
      Offset(body.center.dx, body.top + body.height * 0.5),
      fold,
    );
    canvas.drawLine(
      Offset(body.right, body.bottom),
      Offset(body.center.dx, body.top + body.height * 0.5),
      fold,
    );

    if (flap <= 0.5) {
      canvas.drawPath(fl, flapFill);
      canvas.drawPath(fl, flapLine);
    }

    // The seal sits where the flap tip meets the body.
    if (seal > 0 && flap < 0.2) {
      final double s = w * 0.56;
      canvas.save();
      canvas.translate(body.center.dx - s / 2, body.top + body.height * 0.58 - s / 2);
      LineSealPainter(press: seal).paint(canvas, Size(s, s));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(LineEnvelopePainter old) =>
      old.flap != flap || old.seal != seal || old.lift != lift;
}

/// The small resting envelope with its seal, for the Home card.
class LineEnvelopeView extends StatelessWidget {
  const LineEnvelopeView({super.key, this.width = 84, this.height = 70});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: const LineEnvelopePainter(),
    );
  }
}

/// The film of a letter being sealed and sent. Shows as a dialog on top of
/// whatever is open and closes itself.
Future<void> playLineSendAnimation(BuildContext context) {
  HapticFeedback.mediumImpact();
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: IvoryColors.burgundy.withValues(alpha: 0.35),
    transitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (BuildContext ctx, Animation<double> a, Animation<double> b) =>
        const _SendFilm(),
  );
}

class _SendFilm extends StatefulWidget {
  const _SendFilm();

  @override
  State<_SendFilm> createState() => _SendFilmState();
}

class _SendFilmState extends State<_SendFilm>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3000),
  );
  bool _thud = false;

  @override
  void initState() {
    super.initState();
    _c.addListener(() {
      if (!_thud && _c.value > 0.52) {
        _thud = true;
        HapticFeedback.heavyImpact();
      }
    });
    _c.forward().whenComplete(() {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _seg(double a, double b, [Curve curve = Curves.easeInOut]) =>
      curve.transform(((_c.value - a) / (b - a)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _c,
        builder: (BuildContext context, Widget? w) {
          final double lift = 1 - _seg(0.08, 0.32);
          final double flap = 1 - _seg(0.28, 0.5);
          final double stamp = _seg(0.5, 0.72, Curves.linear);
          final double fly = _seg(0.78, 1.0, Curves.easeInCubic);
          final double settle = _seg(0.0, 0.14, Curves.easeOut);
          return Opacity(
            opacity: (1 - fly).clamp(0.0, 1.0) * settle.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(fly * 160, -fly * 420),
              child: Transform.rotate(
                angle: -fly * 0.35,
                child: Transform.scale(
                  scale: 1.0 - fly * 0.5,
                  child: CustomPaint(
                    size: const Size(240, 200),
                    painter: LineEnvelopePainter(
                      flap: flap,
                      seal: stamp,
                      lift: lift,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// END OF FILE - lib/widgets/line_seal.dart
