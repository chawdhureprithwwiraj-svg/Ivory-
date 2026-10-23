import 'dart:math' as math;

import 'package:flutter/material.dart';

/// ============================================================
/// IVORY - THE JEWEL VAULT SKIN (paid members' Profile cards)
///
/// Burgundy velvet plates framed in white gold, a seam of light at
/// the edge, a crown over the top, and minute dials set with a
/// jewel. Behind all of it a very light coloured life: gold and
/// jewel grains twinkling, a halo breathing, the light seam
/// shimmering - nothing fast, nothing loud.
///
/// Forever members and the owner never see this file's widgets.
/// ============================================================

const Color _velvetTop = Color(0xFF5C1420);
const Color _velvetDeep = Color(0xFF4A0E17);
const Color _velvetWarm = Color(0xFF6E1A2A);
const Color _whiteGold = Color(0xFFE8C86A);
const Color _paleGold = Color(0xFFFFF3CF);
const Color _softGold = Color(0xFFF0D9A8);

/// A small light label on velvet.
class VaultEyebrow extends StatelessWidget {
  const VaultEyebrow(this.text, {super.key, required this.icon});
  final String text;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Row(children: <Widget>[
      Icon(icon, size: 15, color: _whiteGold),
      const SizedBox(width: 7),
      Text(text.toUpperCase(),
          style: const TextStyle(fontSize: 10, letterSpacing: 2.5,
              fontWeight: FontWeight.w800, color: _softGold)),
    ]);
  }
}

/// The velvet plate itself, with its quiet coloured life.
class VaultPlate extends StatefulWidget {
  const VaultPlate({super.key, required this.child, this.radius = 20});

  final Widget child;
  final double radius;

  @override
  State<VaultPlate> createState() => _VaultPlateState();
}

class _VaultPlateState extends State<VaultPlate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _beat = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 11),
  )..repeat();

  @override
  void dispose() {
    _beat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.radius),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x664A0E17), blurRadius: 18, offset: Offset(0, 9)),
        ],
      ),
      child: AnimatedBuilder(
        animation: _beat,
        builder: (BuildContext c, Widget? ch) => CustomPaint(
          painter: _VelvetPainter(_beat.value, widget.radius),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 17, 18, 17),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

double _seed(int i) {
  final double x = math.sin(i * 127.1) * 43758.5453;
  return x - x.floor();
}

class _VelvetPainter extends CustomPainter {
  const _VelvetPainter(this.beat, this.radius);

  final double beat;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect r = Offset.zero & size;
    final RRect rr = RRect.fromRectAndRadius(
      r.deflate(0.75),
      Radius.circular(radius),
    );
    canvas.saveLayer(r, Paint());
    // Velvet.
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[_velvetTop, _velvetDeep, _velvetWarm],
          stops: <double>[0, 0.62, 1],
        ).createShader(r),
    );
    canvas.save();
    canvas.clipRRect(rr);
    // A halo breathing over the top.
    final double breath = 0.10 + 0.05 * math.sin(2 * math.pi * beat);
    canvas.drawRect(
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -1.4),
          radius: 1.1,
          colors: <Color>[
            Color.fromRGBO(255, 214, 110, breath),
            const Color(0x00FFD66E),
          ],
        ).createShader(r),
    );
    // Gold and jewel grains, twinkling very lightly.
    const List<Color> jewels = <Color>[Color(0xFFD42450), Color(0xFF9A55E6), Color(0xFF14B87A)];
    for (int i = 0; i < 14; i++) {
      final double tw = 0.5 + 0.5 * math.sin(2 * math.pi * (beat * 1.4 + _seed(i + 7)));
      final Color c = i % 4 == 3 ? jewels[i % 3] : const Color(0xFFFFF3CF);
      final double a = (i % 4 == 3 ? 0.09 : 0.12) * tw;
      canvas.drawCircle(Offset(_seed(i) * size.width, _seed(i + 31) * size.height),
          0.7 + _seed(i + 13) * 0.9, Paint()..color = c.withValues(alpha: a));
    }
    // The light seam at the right edge, shimmering.
    final double seam = 0.55 + 0.30 * math.sin(2 * math.pi * beat * 0.5);
    final Rect sr = Rect.fromLTWH(size.width - 9, size.height * 0.1, 5, size.height * 0.8);
    canvas.drawRRect(RRect.fromRectAndRadius(sr, const Radius.circular(3)),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: <Color>[const Color(0x00FFD66E), Color.fromRGBO(255, 246, 214, 0.55 * seam)],
          ).createShader(sr));
    canvas.restore();
    // White-gold frame, then a pale hairline inside it.
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = _whiteGold,
    );
    canvas.drawRRect(
      rr.deflate(3.0),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = const Color(0x55FFF3CF),
    );
    // The crown, top right, breathing with the halo.
    final double cx = size.width - 34;
    final Path crown = Path()
      ..moveTo(cx - 13, 26)
      ..lineTo(cx - 9, 15)
      ..lineTo(cx - 3.5, 21)
      ..lineTo(cx, 13)
      ..lineTo(cx + 3.5, 21)
      ..lineTo(cx + 9, 15)
      ..lineTo(cx + 13, 26)
      ..close();
    canvas.drawPath(
      crown,
      Paint()..color = _whiteGold.withValues(alpha: 0.55 + 0.25 * breath * 4),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_VelvetPainter old) =>
      old.beat != beat || old.radius != radius;
}

/// A minute dial set with a jewel: ticks, a white-gold arc of what
/// is left, the jewel at its end catching a little light.
class VaultCoin extends StatefulWidget {
  const VaultCoin({
    super.key,
    required this.title,
    required this.icon,
    required this.jewel,
    required this.remaining,
    required this.allowed,
    required this.periodLabel,
  });

  final String title;
  final IconData icon;
  final Color jewel;
  final int remaining;
  final int allowed;
  final String periodLabel;

  @override
  State<VaultCoin> createState() => _VaultCoinState();
}

class _VaultCoinState extends State<VaultCoin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _beat = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  )..repeat();

  @override
  void dispose() {
    _beat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double frac =
        widget.allowed == 0 ? 0 : (widget.remaining / widget.allowed).clamp(0.0, 1.0);
    return Column(
      children: <Widget>[
        SizedBox(
          width: 96,
          height: 96,
          child: AnimatedBuilder(
            animation: _beat,
            builder: (BuildContext context, Widget? child) {
              return CustomPaint(
                painter: _DialPainter(
                  frac: frac,
                  jewel: widget.jewel,
                  beat: _beat.value,
                ),
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                    Text('${widget.remaining}',
                        style: const TextStyle(fontSize: 22, height: 1,
                            fontWeight: FontWeight.w900, color: _paleGold)),
                    const SizedBox(height: 3),
                    const Text('MIN LEFT',
                        style: TextStyle(fontSize: 8.5, letterSpacing: 1.2, color: _softGold)),
                  ]),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          Icon(widget.icon, size: 14, color: _whiteGold),
          const SizedBox(width: 6),
          Flexible(child: Text(widget.title, maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800,
                  letterSpacing: 0.4, color: _paleGold))),
        ]),
        const SizedBox(height: 3),
        Text(
          widget.allowed == 0
              ? 'not in your tier'
              : 'of ${widget.allowed} ${widget.periodLabel}',
          style: const TextStyle(fontSize: 10.5, color: Color(0xFFE8CF9A)),
        ),
      ],
    );
  }
}

class _DialPainter extends CustomPainter {
  const _DialPainter({required this.frac, required this.jewel, required this.beat});

  final double frac;
  final Color jewel;
  final double beat;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);
    final double r = size.shortestSide / 2 - 2;
    // Velvet face with a hairline.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          colors: <Color>[_velvetWarm, _velvetDeep],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0x66FFF3CF),
    );
    // Ticks around the rim.
    final Paint tick = Paint()..strokeWidth = 1..color = const Color(0x4DE8C86A);
    for (int i = 0; i < 48; i++) {
      final double a = i * math.pi / 24;
      final double r2 = r - (i % 4 == 0 ? 8 : 6);
      canvas.drawLine(c + Offset(math.cos(a) * (r - 4), math.sin(a) * (r - 4)),
          c + Offset(math.cos(a) * r2, math.sin(a) * r2), tick);
    }
    // The arc of what is left, in white gold.
    if (frac > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r - 10),
        -math.pi / 2,
        2 * math.pi * frac,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.2
          ..strokeCap = StrokeCap.round
          ..color = _whiteGold,
      );
      // The jewel at the end of the arc, catching light.
      final double a = -math.pi / 2 + 2 * math.pi * frac;
      final Offset j = c + Offset(math.cos(a) * (r - 10), math.sin(a) * (r - 10));
      final double glint = 0.25 + 0.20 * math.sin(2 * math.pi * beat);
      canvas.drawCircle(j, 7, Paint()
        ..shader = RadialGradient(colors: <Color>[jewel.withValues(alpha: glint), const Color(0x00000000)])
            .createShader(Rect.fromCircle(center: j, radius: 7)));
      canvas.drawCircle(j, 3.4, Paint()..color = jewel);
      canvas.drawCircle(j, 3.4, Paint()
        ..style = PaintingStyle.stroke..strokeWidth = 1.0..color = const Color(0xCCFFF3CF));
    }
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.frac != frac || old.jewel != jewel || old.beat != beat;
}

/// Buttons on velvet: white gold, or an outline of it.
class VaultButton extends StatelessWidget {
  const VaultButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.outline = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool outline;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: outline
                ? null
                : const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[Color(0xFFFFFBE8), Color(0xFFE9CD7C)],
                  ),
            border: Border.all(
              color: _whiteGold,
              width: outline ? 1.5 : 1.0,
            ),
            boxShadow: outline
                ? null
                : const <BoxShadow>[
                    BoxShadow(color: Color(0x55FFD66E), blurRadius: 10, offset: Offset(0, 4)),
                  ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
                Icon(icon, size: 17, color: outline ? _softGold : const Color(0xFF4A0E17)),
                const SizedBox(width: 8),
                Flexible(child: Text(label, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: outline ? _softGold : const Color(0xFF4A0E17),
                        fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.6))),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// The paid member's membership plate: velvet, ribbon, name, days.
class VaultMembershipCard extends StatelessWidget {
  const VaultMembershipCard({
    super.key,
    required this.tierName,
    required this.daysLeft,
    required this.onManage,
  });

  final String tierName;
  final int daysLeft;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    return VaultPlate(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const VaultEyebrow('Your membership', icon: Icons.diamond_outlined),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Color(0xFFFFFBE8), Color(0xFFE9CD7C)]),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(tierName.toUpperCase(),
                style: const TextStyle(color: Color(0xFF4A0E17), fontSize: 10.5,
                    fontWeight: FontWeight.w800, letterSpacing: 1.6)),
          ),
          const SizedBox(height: 10),
          Text(tierName,
              style: const TextStyle(color: _paleGold, fontSize: 22,
                  fontWeight: FontWeight.w800, height: 1.15)),
          const SizedBox(height: 6),
          Text('Premium member \u00b7 '
              '${daysLeft == 1 ? "1 day" : "$daysLeft days"} remaining. '
              'Everything at this level is open to you.',
              style: const TextStyle(fontSize: 13, height: 1.45, color: _softGold)),
          const SizedBox(height: 16),
          VaultButton(
            label: 'MANAGE OR RENEW',
            icon: Icons.workspace_premium_outlined,
            onPressed: onManage,
          ),
        ],
      ),
    );
  }
}

// END OF FILE - lib/widgets/vault_skin.dart
