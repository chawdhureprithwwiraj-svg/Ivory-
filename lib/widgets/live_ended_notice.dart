import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';

class LiveEndedNotice extends StatefulWidget {
  const LiveEndedNotice(this.message, {super.key});

  final String message;

  @override
  State<LiveEndedNotice> createState() => _LiveEndedNoticeState();
}

class _LiveEndedNoticeState extends State<LiveEndedNotice>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wink;

  @override
  void initState() {
    super.initState();
    _wink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _wink.stop();
      _wink.value = 0;
    } else if (!_wink.isAnimating) {
      _wink.repeat();
    }
  }

  @override
  void dispose() {
    _wink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 350),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 28),
              decoration: BoxDecoration(
                color: IvoryColors.plum.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: IvoryColors.gold.withValues(alpha: 0.82),
                  width: 1.3,
                ),
                boxShadow: IvoryTheme.softShadow(blur: 28, y: 10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: AnimatedBuilder(
                      animation: _wink,
                      builder: (BuildContext context, _) {
                        final double phase = _wink.value;
                        final double blink = phase < 0.72 || phase > 0.86
                            ? 0
                            : phase < 0.78
                                ? (phase - 0.72) / 0.06
                                : (0.86 - phase) / 0.08;
                        return CustomPaint(
                          painter: _WinkingWomanPainter(blink),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 19),
                  Text(
                    widget.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: IvoryColors.cream,
                      fontFamily: IvoryTheme.displayFont,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _WinkingWomanPainter extends CustomPainter {
  const _WinkingWomanPainter(this.blink);

  final double blink;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    canvas.drawCircle(
      center,
      31,
      Paint()..shader = const LinearGradient(
        colors: <Color>[IvoryColors.gold, IvoryColors.amber],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size),
    );
    canvas.drawCircle(
      center,
      30,
      Paint()
        ..color = IvoryColors.burgundy.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final Paint hair = Paint()..color = const Color(0xFF65162F);
    canvas.drawOval(const Rect.fromLTRB(9, 5, 55, 60), hair);
    canvas.drawOval(
      const Rect.fromLTRB(15, 11, 49, 53),
      Paint()..color = const Color(0xFFFFC49C),
    );

    final Path fringe = Path()
      ..moveTo(13, 25)
      ..cubicTo(12, 10, 22, 7, 32, 8)
      ..cubicTo(45, 7, 52, 17, 49, 28)
      ..cubicTo(43, 21, 37, 19, 30, 20)
      ..cubicTo(23, 20, 19, 23, 14, 31)
      ..close();
    canvas.drawPath(fringe, hair);

    final Paint blush = Paint()..color = const Color(0xFFE58B82);
    canvas.drawOval(const Rect.fromLTRB(18, 34, 26, 38), blush);
    canvas.drawOval(const Rect.fromLTRB(39, 34, 47, 38), blush);

    final Paint eye = Paint()
      ..color = IvoryColors.burgundy
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawOval(const Rect.fromLTRB(22, 25, 26, 31), eye);
    if (blink > 0.82) {
      final Path closedEye = Path()
        ..moveTo(37, 29)
        ..quadraticBezierTo(41, 32, 45, 28);
      canvas.drawPath(closedEye, eye);
    } else {
      final double eyeHeight =
          (5.0 * (1 - blink).clamp(0.08, 1.0)).toDouble();
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(41, 28), width: 4, height: eyeHeight),
        eye..style = PaintingStyle.fill,
      );
    }

    final Path smile = Path()
      ..moveTo(25, 39)
      ..quadraticBezierTo(32, 46, 40, 39);
    canvas.drawPath(
      smile,
      Paint()
        ..color = IvoryColors.burgundy
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.1
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(const Offset(47, 14), 2.1, Paint()..color = IvoryColors.gold);
  }

  @override
  bool shouldRepaint(covariant _WinkingWomanPainter oldDelegate) =>
      oldDelegate.blink != blink;
}

// END OF FILE - lib/widgets/live_ended_notice.dart
