

import 'package:flutter/material.dart';

import 'rising_lights.dart';

/// ============================================================
/// IVORY - THE TEN-DAY VAULT: THE RICH PEACH
///
/// The Vault's whole background, the burgundy wells that hold its
/// gold-made parts, and its lettering. The rising lanterns and
/// jewels are in rising_lights.dart.
/// ============================================================

const Color vaultInk = Color(0xFF4A0E17);

/// The Ten-Day Vault's whole background. By day (the question, the
/// keys, the rules) it is a rich sunrise of rose, coral, amber and
/// gold with the lights climbing through it; for the opening of the
/// vault ([dark]) it is the deep burgundy night with the same lights.
class VaultSky extends StatelessWidget {
  const VaultSky({super.key, required this.child, this.dark = false});

  final Widget child;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: dark
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Color(0xFF7A1F33),
                        Color(0xFF5C1222),
                        Color(0xFF4A0E17),
                      ],
                    )
                  : const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Color(0xFFFF9A78),
                        Color(0xFFFFB08A),
                        Color(0xFFFFC9A3),
                        Color(0xFFFFDDBF),
                        Color(0xFFFFEBD3),
                      ],
                      stops: <double>[0, 0.3, 0.6, 0.85, 1],
                    ),
            ),
          ),
        ),
        if (!dark)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, 1.15),
                  radius: 1.0,
                  colors: <Color>[
                    const Color(0xFFFFF4E4).withValues(alpha: 0.85),
                    const Color(0xFFFFF4E4).withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        // A soft diagonal satin sheen, like polished silk.
        if (!dark)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    const Color(0x00FFFFFF),
                    const Color(0xFFFFFFFF).withValues(alpha: 0.22),
                    const Color(0x00FFFFFF),
                  ],
                  stops: const <double>[0.2, 0.42, 0.66],
                ),
              ),
            ),
          ),
        Positioned.fill(child: RisingLights(onDark: dark)),
        child,
      ],
    );
  }
}

/// A small burgundy well that holds gold-made parts (the button, the
/// ring, the key) so they stand out against the peach.
class VaultWell extends StatelessWidget {
  const VaultWell({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(5),
    this.radius = 18,
    this.circle = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF7A1F33), Color(0xFF4A0E17)],
        ),
        border: Border.all(color: const Color(0xFFFFE27A), width: 1.4),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF4A0E17).withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Deep burgundy lettering with a raised, golden 3D edge, for titles
/// that sit directly on the sunrise.
class VaultInkTitle extends StatelessWidget {
  const VaultInkTitle(
    this.text, {
    super.key,
    required this.size,
    this.depth = 4,
    this.textAlign = TextAlign.center,
    this.fontFamily,
  });

  final String text;
  final double size;
  final int depth;
  final TextAlign textAlign;
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    final List<Shadow> sh = <Shadow>[
      const Shadow(color: Color(0xCCFFFFFF), offset: Offset(0, -1.2)),
      for (int i = 1; i <= depth; i++)
        Shadow(color: const Color(0xFFA86A00), offset: Offset(0, i * 1.0)),
      Shadow(
        color: const Color(0x99784600),
        offset: Offset(0, depth + 3.0),
        blurRadius: 6,
      ),
    ];
    return Text(
      text,
      textAlign: textAlign,
      style: TextStyle(
        color: vaultInk,
        fontFamily: fontFamily,
        fontSize: size,
        fontWeight: FontWeight.w900,
        height: 1.05,
        letterSpacing: size > 40 ? 2 : 1.4,
        shadows: sh,
      ),
    );
  }
}

/// ============================================================
/// THE PEACH PLATE: the Ten-Day Vault card on Home. A slab of rich,
/// satin peach: banded like polished enamel, a thin gold rim, a raised
/// edge (light on top, a burnt-coral shade below), a glassy gloss over
/// the upper half and a streak of light that sweeps across now and
/// then. Writing on it is deep burgundy; parts made of gold sit in a
/// [VaultWell]. Pure painting.
/// ============================================================
class VaultPlate extends StatefulWidget {
  const VaultPlate({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(18, 18, 18, 18),
    this.radius = 26,
    this.calm = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final bool calm;

  @override
  State<VaultPlate> createState() => _VaultPlateState();
}

class _VaultPlateState extends State<VaultPlate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 7000),
  );

  @override
  void initState() {
    super.initState();
    if (!widget.calm) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double r = widget.radius;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFFC9603A).withValues(alpha: 0.45),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: const Color(0xFFFFC9A0).withValues(alpha: 0.4),
            blurRadius: 18,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(r),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      Color(0xFFFFDCC2),
                      Color(0xFFFFBF98),
                      Color(0xFFFFA97C),
                      Color(0xFFFFCFAE),
                      Color(0xFFFF9F72),
                      Color(0xFFFFBE96),
                      Color(0xFFF58E62),
                    ],
                    stops: <double>[0, 0.14, 0.3, 0.46, 0.62, 0.78, 1],
                  ),
                  border: Border.all(color: const Color(0xFFFFE08A), width: 2),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (BuildContext context, Widget? _) => CustomPaint(
                    painter: _PeachPainter(
                      t: widget.calm ? 0.9 : _c.value,
                      radius: r,
                      calm: widget.calm,
                    ),
                  ),
                ),
              ),
            ),
            if (!widget.calm)
              const Positioned.fill(
                child: RisingLights(
                  scale: 0.55,
                  lanterns: 4,
                  gems: 6,
                  embers: 14,
                  surge: false,
                  seed: 3,
                ),
              ),
            Padding(padding: widget.padding, child: widget.child),
          ],
        ),
      ),
    );
  }
}

class _PeachPainter extends CustomPainter {
  _PeachPainter({required this.t, required this.radius, required this.calm});

  final double t;
  final double radius;
  final bool calm;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final RRect body = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    canvas.save();
    canvas.clipRRect(body);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h * 0.5),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            const Color(0xFFFFFFFF).withValues(alpha: 0.5),
            const Color(0xFFFFFFFF).withValues(alpha: 0.08),
            const Color(0xFFFFFFFF).withValues(alpha: 0),
          ],
          stops: const <double>[0, 0.6, 1],
        ).createShader(Rect.fromLTWH(0, 0, w, h * 0.5)),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.82, w, h * 0.18),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            const Color(0xFFB8552F).withValues(alpha: 0),
            const Color(0xFFB8552F).withValues(alpha: 0.32),
          ],
        ).createShader(Rect.fromLTWH(0, h * 0.82, w, h * 0.18)),
    );
    canvas.drawLine(
      Offset(radius * 0.7, 2.6),
      Offset(w - radius * 0.7, 2.6),
      Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.85)
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );
    if (!calm) {
      final double p = (t / 0.55).clamp(0.0, 1.0).toDouble();
      if (p < 1) {
        final double bw = w * 0.3;
        final double x = -bw + (w + bw * 2) * p;
        final Rect band = Rect.fromLTWH(x, -h, bw, h * 3);
        canvas.save();
        canvas.translate(w / 2, h / 2);
        canvas.rotate(0.36);
        canvas.translate(-w / 2, -h / 2);
        canvas.drawRect(
          band,
          Paint()
            ..shader = LinearGradient(
              colors: <Color>[
                const Color(0xFFFFFFFF).withValues(alpha: 0),
                const Color(0xFFFFFFFF).withValues(alpha: 0.6),
                const Color(0xFFFFFFFF).withValues(alpha: 0),
              ],
            ).createShader(band),
        );
        canvas.restore();
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PeachPainter o) => o.t != t || o.calm != calm;
}

// END OF FILE - lib/widgets/vault_sky.dart
