import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';
import 'ivory_sheen.dart';

/// ============================================================
/// IVORY - THE MEMBERSHIP SCREEN, IN GOLD
///
/// Every plate on the Membership screen is a shade of gold, and each
/// tier is a deeper gold than the one before it, so climbing feels
/// like climbing in richness. The shade comes from the tier's
/// POSITION in the list (see `shadeFor`), never from a fixed count,
/// so adding, removing or renaming tiers in the database still looks
/// right. Words stay deep burgundy so they read perfectly.
///
/// Only the plate marked `shine` has any movement: one slow light
/// that crosses it now and then.
/// ============================================================
class GoldTierPlate extends StatelessWidget {
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
    colors: <Color>[Color(0xFFFFF3CF), Color(0xFFF7DE95), Color(0xFFEBC66A)],
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

  Widget _skin(double travel) {
    final int s = shade < 0 ? 0 : (shade > 3 ? 3 : shade);
    return CustomPaint(
      painter: _PlatePainter(_tones[s], radius, travel),
      child: Padding(padding: padding, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x66B9801F), blurRadius: 16, offset: Offset(0, 8)),
        ],
      ),
      child: shine
          ? IvorySheen(
              period: const Duration(seconds: 9),
              crossing: 0.22,
              child: _skin,
            )
          : _skin(-1),
    );
  }
}

class _PlatePainter extends CustomPainter {
  const _PlatePainter(this.tones, this.radius, this.travel);

  final List<Color> tones;
  final double radius;
  final double travel;

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
    canvas.drawRect(
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0x00C58A1E), Color(0x00C58A1E), Color(0x47A0640A)],
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
    canvas.restore();
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
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0xE6FFF4BE),
    );
    paintIvorySheen(canvas, size, travel, strength: 0.5);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PlatePainter old) =>
      old.travel != travel || old.tones != tones || old.radius != radius;
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
                ? const <Color>[Color(0xFFFFF8D8), Color(0xFFF8DB7A), Color(0xFFE3B040)]
                : const <Color>[Color(0xFFF6D26A), Color(0xFFE2A93A), Color(0xFFC98A22)],
          ),
          border: Border.all(color: const Color(0xFFA8731A)),
          boxShadow: const <BoxShadow>[
            BoxShadow(color: Color(0x66A8731A), blurRadius: 8, offset: Offset(0, 4)),
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
