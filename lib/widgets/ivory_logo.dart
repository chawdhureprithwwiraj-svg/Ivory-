import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';

/// The Ivory mark: the gold monogram on burgundy.
///
/// It draws assets/logo/ivory_logo.png when that file is present and falls
/// back to a hand-drawn monogram if it is not, so the app never shows a
/// broken image box while the asset is being uploaded.
class IvoryLogo extends StatelessWidget {
  const IvoryLogo({
    super.key,
    this.size = 84,
    this.radius,
    this.showGlow = true,
  });

  final double size;
  final double? radius;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    final double r = radius ?? size * 0.28;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        boxShadow: showGlow
            ? <BoxShadow>[
                BoxShadow(
                  color: IvoryColors.burgundy.withValues(alpha: 0.22),
                  blurRadius: size * 0.28,
                  offset: Offset(0, size * 0.10),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r),
        child: Image.asset(
          'assets/logo/ivory_logo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          errorBuilder: (BuildContext context, Object error, StackTrace? s) =>
              _FallbackMark(size: size, radius: r),
        ),
      ),
    );
  }
}

class _FallbackMark extends StatelessWidget {
  const _FallbackMark({required this.size, required this.radius});

  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: IvoryColors.deepGradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: IvoryColors.gold.withValues(alpha: 0.65),
          width: size * 0.018,
        ),
      ),
      alignment: Alignment.center,
      child: ShaderMask(
        shaderCallback: (Rect b) => IvoryColors.goldGradient.createShader(b),
        child: Text(
          'I',
          style: TextStyle(
            fontFamily: IvoryTheme.displayFont,
            fontSize: size * 0.52,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}

/// The wordmark, for headers and the login screen.
class IvoryWordmark extends StatelessWidget {
  const IvoryWordmark({
    super.key,
    this.fontSize = 34,
    this.showTagline = true,
  });

  final double fontSize;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          'IVORY',
          style: TextStyle(
            fontFamily: IvoryTheme.displayFont,
            color: IvoryColors.burgundy,
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            letterSpacing: fontSize * 0.18,
          ),
        ),
        if (showTagline) ...<Widget>[
          SizedBox(height: fontSize * 0.22),
          Text(
            'EVERY STORY LEAVES A MARK',
            style: TextStyle(
              color: IvoryColors.plum.withValues(alpha: 0.75),
              fontSize: fontSize * 0.27,
              fontWeight: FontWeight.w700,
              letterSpacing: fontSize * 0.09,
            ),
          ),
        ],
      ],
    );
  }
}
