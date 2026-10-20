
import 'package:flutter/material.dart';

import 'rising_lights.dart';

/// ============================================================
/// IVORY - THE TEN-DAY VAULT: THE SUNRISE
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
                        Color(0xFFFF7AA2),
                        Color(0xFFFF8F66),
                        Color(0xFFFFB347),
                        Color(0xFFFFD966),
                        Color(0xFFFFF0B8),
                      ],
                      stops: <double>[0, 0.28, 0.55, 0.8, 1],
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
                    const Color(0xFFFFFBE0).withValues(alpha: 0.85),
                    const Color(0xFFFFFBE0).withValues(alpha: 0),
                  ],
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
/// ring, the key) so they stand out against the sunrise.
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

// END OF FILE - lib/widgets/vault_sky.dart
