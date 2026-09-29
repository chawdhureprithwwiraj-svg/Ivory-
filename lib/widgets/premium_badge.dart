import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';

/// ============================================================
/// THE PREMIUM BADGE
///
/// Awarded the moment a member's tier level rises above zero. Three
/// sizes of the same jewel:
///
///   PremiumBadge.chip(...)    - inline, next to a name
///   PremiumBadge.crest(...)   - the large medallion on the Profile
///   PremiumBadge.ribbon(...)  - a full-width "member since" plaque
///
/// Gold leaf, a burgundy core, a moving sheen and a soft burgundy glow -
/// no black anywhere, exactly as the house rule demands.
/// ============================================================
class PremiumBadge extends StatelessWidget {
  const PremiumBadge._({
    required this.tierName,
    required this.level,
    required this.variant,
    this.subtitle,
  });

  /// A small pill for headers, list rows and app bars.
  factory PremiumBadge.chip({required String tierName, required int level}) =>
      PremiumBadge._(
        tierName: tierName,
        level: level,
        variant: _BadgeVariant.chip,
      );

  /// The circular medallion for the Profile header.
  factory PremiumBadge.crest({required String tierName, required int level}) =>
      PremiumBadge._(
        tierName: tierName,
        level: level,
        variant: _BadgeVariant.crest,
      );

  /// A wide plaque with a line of supporting text.
  factory PremiumBadge.ribbon({
    required String tierName,
    required int level,
    String? subtitle,
  }) =>
      PremiumBadge._(
        tierName: tierName,
        level: level,
        variant: _BadgeVariant.ribbon,
        subtitle: subtitle,
      );

  final String tierName;
  final int level;
  final _BadgeVariant variant;
  final String? subtitle;

  /// Level one is a crown; every step up adds a star to the right of it.
  IconData get _icon {
    switch (level) {
      case 0:
        return Icons.auto_awesome_outlined;
      case 1:
        return Icons.workspace_premium;
      case 2:
        return Icons.military_tech;
      case 3:
        return Icons.diamond;
      default:
        return Icons.emoji_events;
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case _BadgeVariant.chip:
        return _chip();
      case _BadgeVariant.crest:
        return _crest();
      case _BadgeVariant.ribbon:
        return _ribbon();
    }
  }

  // ---------------------------------------------------------------- chip

  Widget _chip() {
    return _Sheen(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFFF3D98A),
              IvoryColors.gold,
              Color(0xFFE8C766),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFB8942B), width: 1),
          boxShadow: IvoryTheme.softShadow(blur: 10, y: 4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(_icon, size: 14, color: IvoryColors.burgundy),
            const SizedBox(width: 6),
            Text(
              tierName.toUpperCase(),
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
                color: IvoryColors.burgundy,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------- crest

  Widget _crest() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _Sheen(
          borderRadius: BorderRadius.circular(60),
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const SweepGradient(
                colors: <Color>[
                  Color(0xFFF7E7B0),
                  IvoryColors.gold,
                  Color(0xFFB8942B),
                  IvoryColors.amber,
                  Color(0xFFF7E7B0),
                ],
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: IvoryColors.burgundy.withValues(alpha: 0.18),
                  blurRadius: 22,
                  offset: const Offset(0, 9),
                ),
                BoxShadow(
                  color: IvoryColors.gold.withValues(alpha: 0.35),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: IvoryColors.deepGradient,
                  border: Border.all(
                    color: const Color(0xFFF3D98A),
                    width: 1.6,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    ShaderMask(
                      shaderCallback: (Rect b) =>
                          IvoryColors.goldGradient.createShader(b),
                      child: Icon(_icon, size: 26, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'TIER $level',
                      style: TextStyle(
                        fontSize: 8.5,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w800,
                        color: IvoryColors.gold.withValues(alpha: 0.95),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          tierName,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: IvoryTheme.displayFont,
            fontSize: 18,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w700,
            color: IvoryColors.burgundy,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------- ribbon

  Widget _ribbon() {
    return _Sheen(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          gradient: IvoryColors.deepGradient,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: IvoryColors.gold, width: 1.4),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: IvoryColors.burgundy.withValues(alpha: 0.22),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: IvoryColors.goldGradient,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: IvoryColors.gold.withValues(alpha: 0.45),
                    blurRadius: 14,
                  ),
                ],
              ),
              child: Icon(_icon, size: 24, color: IvoryColors.burgundy),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      ShaderMask(
                        shaderCallback: (Rect b) =>
                            IvoryColors.goldGradient.createShader(b),
                        child: Text(
                          tierName,
                          style: const TextStyle(
                            fontFamily: IvoryTheme.displayFont,
                            fontSize: 19,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ...List<Widget>.generate(
                        level.clamp(1, 5),
                        (int i) => const Padding(
                          padding: EdgeInsets.only(right: 2),
                          child: Icon(Icons.star_rounded,
                              size: 12, color: IvoryColors.gold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle ?? 'Premium membership active',
                    style: TextStyle(
                      fontSize: 11.8,
                      letterSpacing: 0.4,
                      color: IvoryColors.cream.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.verified_rounded,
                size: 20, color: IvoryColors.gold.withValues(alpha: 0.9)),
          ],
        ),
      ),
    );
  }
}

enum _BadgeVariant { chip, crest, ribbon }

/// A slow diagonal highlight that travels across the badge, the way
/// light moves over polished metal.
class _Sheen extends StatefulWidget {
  const _Sheen({required this.child, required this.borderRadius});

  final Widget child;
  final BorderRadius borderRadius;

  @override
  State<_Sheen> createState() => _SheenState();
}

class _SheenState extends State<_Sheen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: Stack(
        children: <Widget>[
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _c,
                builder: (BuildContext context, Widget? child) {
                  final double p = _c.value * 2.6 - 0.8;
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(p - 0.35, -1),
                        end: Alignment(p + 0.35, 1),
                        colors: <Color>[
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.38),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                        stops: const <double>[0.0, 0.5, 1.0],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The quiet counterpart shown to members who have not upgraded yet:
/// same shape, no gold leaf, and an invitation instead of a rank.
class FreeMemberChip extends StatelessWidget {
  const FreeMemberChip({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: IvoryColors.surfaceWarm,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: IvoryColors.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.auto_awesome_outlined,
                size: 13, color: IvoryColors.textFaint),
            const SizedBox(width: 6),
            Text(
              'FREE MEMBER',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: IvoryColors.textSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
