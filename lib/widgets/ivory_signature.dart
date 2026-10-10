import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';

/// ============================================================
/// IVORY - THE SIGNATURE, AND THE PROMISE IT SIGNS.
///
/// Drawn from curves, exactly like the nine gift scenes and the
/// crown on the gift wall. It is NOT a font: a font can be
/// downloaded and typed by anyone, and a signature that anyone
/// can type is not a signature.
///
/// The path below was drawn, rendered and LOOKED AT five times
/// before it was trusted. Draft two read "Rvamy" - the capital
/// had a closed bowl so it read as an R. Draft three read
/// "Ivomy" - the o, r and y made three identical humps. Draft
/// four sat in a neat symmetrical basin and looked printed.
/// **IF YOU EDIT THESE NUMBERS, RENDER IT AND LOOK AT IT. The
/// coordinates do not tell you what the word says.**
///
/// Two things make it read as a hand and not a drawing:
///
/// 1. THE PEN CHANGES WEIGHT. 4.1 through the letters, 3.1 into
///    the tail, 2.1 on the final flick. One even thickness is
///    the giveaway of a fake.
/// 2. THE FLICK IS ASYMMETRIC. Deep where the pen leaves the y,
///    flattening as it runs back left, tapering out. Symmetry
///    is what made draft four look machine-made.
///
/// RULES FOR USING IT:
/// * **ONCE per screen, and only at the foot of the promise.**
///   A signature repeated is a logo, and a logo is worth
///   nothing emotionally.
/// * **Never let it be the only place the word "Ivory"
///   appears.** Handwriting is unreadable at small sizes and
///   invisible to a screen reader, which is why this widget
///   carries a `Semantics` label.
/// * It is a mark on a promise. It is not an autograph on an
///   agreement and must never be used as one.
/// ============================================================
class IvorySignature extends StatelessWidget {
  const IvorySignature({super.key, this.width = 150, this.ink});

  final double width;
  final Color? ink;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Signed, Ivory',
      child: SizedBox(
        width: width,
        // The drawing is 230 x 130, so the box keeps that ratio
        // and the hand never stretches.
        height: width * 130 / 230,
        child: CustomPaint(
          painter: _SignaturePainter(ink ?? IvoryColors.burgundy),
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  const _SignaturePainter(this.ink);

  final Color ink;

  /// Every stroke as (startX, startY, [c1x,c1y,c2x,c2y,x,y]...),
  /// in the 230 x 130 space the signature was drawn in.
  static const List<List<double>> _word = <List<double>>[
    <double>[54, 12, 36, 22, 43, 39],
    <double>[48, 53, 51, 72, 49, 88],
    <double>[48, 96, 57, 97, 65, 88],
    <double>[71, 78, 73, 58, 78, 56],
    <double>[83, 54, 84, 78, 88, 90],
    <double>[90, 95, 94, 72, 98, 60],
    <double>[103, 50, 121, 52, 122, 65],
    <double>[123, 79, 109, 90, 102, 83],
    <double>[96, 77, 100, 62, 113, 59],
    <double>[120, 58, 124, 63, 126, 70],
    <double>[130, 57, 136, 45, 141, 47],
    <double>[145, 49, 140, 60, 135, 66],
    <double>[140, 62, 148, 58, 154, 62],
    <double>[158, 57, 161, 76, 165, 88],
    <double>[167, 94, 171, 94, 174, 87],
    <double>[178, 76, 182, 60, 187, 56],
  ];
  static const List<List<double>> _tail = <List<double>>[
    <double>[193, 74, 194, 96, 183, 104],
  ];
  static const List<List<double>> _flick = <List<double>>[
    <double>[168, 112, 130, 112, 96, 106],
    <double>[76, 102, 62, 98, 52, 93],
  ];

  Path _path(double sx, double sy, List<List<double>> segs, double k) {
    final Path p = Path()..moveTo(sx * k, sy * k);
    for (final List<double> c in segs) {
      p.cubicTo(c[0] * k, c[1] * k, c[2] * k, c[3] * k, c[4] * k, c[5] * k);
    }
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double k = size.width / 230;
    final Paint pen = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = ink;

    canvas.drawPath(_path(72, 22, _word, k), pen..strokeWidth = 4.1 * k);
    canvas.drawPath(_path(187, 56, _tail, k), pen..strokeWidth = 3.1 * k);
    canvas.drawPath(_path(183, 104, _flick, k), pen..strokeWidth = 2.1 * k);
  }

  @override
  bool shouldRepaint(_SignaturePainter old) => old.ink != ink;
}

/// THE PROMISE, AND WHERE IT BELONGS.
///
/// At the FOOT of home, not near the top. A signature is how a
/// letter ends: a third of the way down the page it signs off
/// something nobody has finished reading. A member walks the
/// whole house, reaches the end, and finds she signed it.
///
/// THE WORDING IS SCOPED ON PURPOSE AND MUST STAY SCOPED. It
/// promises THE DOOR - that entry stays open - and never the
/// rooms. What is behind the door stays hers to price and tier.
/// The old line framed the public door as a tier and promised
/// more than the house intended. **Do not widen this sentence.**
class IvoryPromise extends StatelessWidget {
  const IvoryPromise({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[IvoryColors.surface, IvoryColors.surfaceWarm],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: IvoryColors.gold.withValues(alpha: 0.75),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            "It's my promise: the door to Ivory stays open, always.",
            style: TextStyle(
              fontFamily: IvoryTheme.displayFont,
              fontSize: 16.5,
              height: 1.5,
              fontStyle: FontStyle.italic,
              color: IvoryColors.burgundy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Yours, in the quiet hours.',
            style: TextStyle(
              fontFamily: IvoryTheme.displayFont,
              fontSize: 16.5,
              height: 1.5,
              fontStyle: FontStyle.italic,
              color: IvoryColors.burgundy,
            ),
          ),
          const SizedBox(height: 2),
          const IvorySignature(width: 148),
        ],
      ),
    );
  }
}

// END OF FILE - lib/widgets/ivory_signature.dart
