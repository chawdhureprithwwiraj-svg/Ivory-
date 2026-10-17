import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';
import 'gold_burst.dart';
import 'gold_fx.dart';

/// ============================================================
/// IVORY - THE VAULT KEYS
///
/// Ten keys, one a day. A key that has been turned is polished
/// gold with a glint; today's key breathes; the keys still to
/// come are engraved and dark. Everything is painted with plain
/// Flutter, so it costs the app nothing. No black: shadows and
/// engraving are burgundy and plum.
/// ============================================================

enum VaultKeyMode { turned, today, locked }

/// One round key-plate.
class VaultKeyDisc extends StatefulWidget {
  const VaultKeyDisc({super.key, required this.mode, this.size = 28});

  final VaultKeyMode mode;
  final double size;

  @override
  State<VaultKeyDisc> createState() => _VaultKeyDiscState();
}

class _VaultKeyDiscState extends State<VaultKeyDisc>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  @override
  void initState() {
    super.initState();
    if (widget.mode == VaultKeyMode.today) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant VaultKeyDisc old) {
    super.didUpdateWidget(old);
    if (widget.mode == VaultKeyMode.today) {
      if (!_c.isAnimating) _c.repeat(reverse: true);
    } else {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double s = widget.size;
    return AnimatedBuilder(
      animation: _c,
      builder: (BuildContext context, Widget? _) {
        final double p = Curves.easeInOut.transform(_c.value);
        switch (widget.mode) {
          case VaultKeyMode.turned:
            return Container(
              width: s,
              height: s,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  center: Alignment(-0.35, -0.45),
                  colors: <Color>[
                    GoldTones.shine,
                    GoldTones.light,
                    GoldTones.mid,
                    GoldTones.deep,
                  ],
                  stops: <double>[0, 0.3, 0.7, 1],
                ),
                border: Border.all(color: GoldTones.rim, width: 1.1),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: IvoryColors.gold.withValues(alpha: 0.5),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Transform.rotate(
                angle: -math.pi / 4,
                child: Icon(
                  Icons.vpn_key_rounded,
                  size: s * 0.56,
                  color: IvoryColors.burgundy,
                ),
              ),
            );
          case VaultKeyMode.today:
            return Container(
              width: s,
              height: s,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: IvoryColors.plum,
                border: Border.all(
                  color: Color.lerp(GoldTones.mid, GoldTones.shine, p)!,
                  width: 1.6,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: GoldTones.light.withValues(alpha: 0.25 + 0.55 * p),
                    blurRadius: 6 + 14 * p,
                    spreadRadius: 1 + 2 * p,
                  ),
                ],
              ),
              child: Transform.rotate(
                angle: -math.pi / 4,
                child: Icon(
                  Icons.vpn_key_outlined,
                  size: s * 0.56,
                  color: Color.lerp(GoldTones.mid, GoldTones.shine, p),
                ),
              ),
            );
          case VaultKeyMode.locked:
            return Container(
              width: s,
              height: s,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: IvoryColors.plum.withValues(alpha: 0.85),
                border: Border.all(
                  color: IvoryColors.gold.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(
                Icons.lock_outline_rounded,
                size: s * 0.46,
                color: IvoryColors.gold.withValues(alpha: 0.5),
              ),
            );
        }
      },
    );
  }
}

/// A row of keys: [turned] gold, then today's (when [today]), then locked.
class VaultKeyRow extends StatelessWidget {
  const VaultKeyRow({
    super.key,
    required this.total,
    required this.turned,
    this.today = false,
    this.maxSize = 30,
  });

  final int total;
  final int turned;
  final bool today;
  final double maxSize;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        const double gap = 5;
        final int per = math.min(total, 10);
        final double w = c.maxWidth.isFinite ? c.maxWidth : 300;
        final double size = ((w - gap * (per - 1)) / per)
            .clamp(16.0, maxSize)
            .toDouble();
        return Wrap(
          alignment: WrapAlignment.start,
          spacing: gap,
          runSpacing: gap,
          children: <Widget>[
            for (int i = 0; i < total; i++)
              VaultKeyDisc(
                size: size,
                mode: i < turned
                    ? VaultKeyMode.turned
                    : (i == turned && today
                          ? VaultKeyMode.today
                          : VaultKeyMode.locked),
              ),
          ],
        );
      },
    );
  }
}

/// The vault's emblem: the golden coin with a key laid across it.
class VaultEmblem extends StatelessWidget {
  const VaultEmblem({super.key, this.size = 62});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          GoldCoin(
            size: size,
            glyph: Transform.rotate(
              angle: -math.pi / 2,
              child: Icon(
                Icons.vpn_key_rounded,
                size: size * 0.4,
                color: IvoryColors.burgundy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The big key that slides into the lock and turns, once.
class VaultBigKey extends StatefulWidget {
  const VaultBigKey({super.key, this.animate = true, this.onTurned});

  /// False shows the key already turned (for a member who comes back).
  final bool animate;

  /// Called at the moment the key clicks home.
  final VoidCallback? onTurned;

  @override
  State<VaultBigKey> createState() => _VaultBigKeyState();
}

class _VaultBigKeyState extends State<VaultBigKey>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2300),
  );
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _c.addListener(() {
        if (!_fired && _c.value >= 0.78) {
          _fired = true;
          widget.onTurned?.call();
        }
      });
      _c.forward();
    } else {
      _c.value = 1;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _seg(double a, double b, Curve k) =>
      k.transform(((_c.value - a) / (b - a)).clamp(0.0, 1.0).toDouble());

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (BuildContext context, Widget? _) {
        final double slide = _seg(0, 0.38, Curves.easeOutCubic);
        final double turn = _seg(0.4, 0.78, Curves.easeInOutCubic);
        final double glow = _seg(0.76, 1, Curves.easeOut);
        const double plate = 150;
        return SizedBox(
          width: 230,
          height: 190,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: <Widget>[
              Container(
                width: plate + 40 * glow,
                height: plate + 40 * glow,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: GoldTones.light.withValues(
                        alpha: 0.18 + 0.5 * glow,
                      ),
                      blurRadius: 24 + 40 * glow,
                      spreadRadius: 2 + 8 * glow,
                    ),
                  ],
                ),
              ),
              Container(
                width: plate,
                height: plate,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    center: Alignment(-0.4, -0.5),
                    colors: <Color>[
                      GoldTones.shine,
                      GoldTones.light,
                      GoldTones.mid,
                      GoldTones.deep,
                      GoldTones.rim,
                    ],
                    stops: <double>[0, 0.25, 0.55, 0.85, 1],
                  ),
                  border: Border.all(color: GoldTones.rim, width: 2),
                ),
              ),
              Container(
                width: plate * 0.78,
                height: plate * 0.78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: GoldTones.rim.withValues(alpha: 0.55),
                    width: 1.2,
                  ),
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: IvoryColors.burgundy,
                ),
              ),
              Transform.translate(
                offset: const Offset(0, 11),
                child: Container(
                  width: 9,
                  height: 24,
                  decoration: BoxDecoration(
                    color: IvoryColors.burgundy,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(70 * (1 - slide), -60 * (1 - slide)),
                child: Opacity(
                  opacity: slide,
                  child: Transform.rotate(
                    angle: -math.pi / 2 - 1.1 * (1 - turn),
                    child: ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (Rect r) =>
                          GoldTones.foil.createShader(r),
                      child: Icon(
                        Icons.vpn_key_rounded,
                        size: 118,
                        color: IvoryColors.cream,
                        shadows: <Shadow>[
                          Shadow(
                            color: IvoryColors.burgundy.withValues(alpha: 0.6),
                            blurRadius: 10,
                            offset: const Offset(2, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A key-plate that flips over to show how that day went.
class VaultFlipDisc extends StatelessWidget {
  const VaultFlipDisc({
    super.key,
    required this.day,
    required this.flipped,
    required this.correct,
    required this.golden,
    required this.amountInr,
    this.size = 56,
  });

  final int day;
  final bool flipped;
  final bool correct;
  final bool golden;
  final int amountInr;
  final double size;

  Widget _front() => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: IvoryColors.plum,
      border: Border.all(color: GoldTones.mid.withValues(alpha: 0.7)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(Icons.lock_rounded, size: size * 0.3, color: GoldTones.mid),
        Text(
          '$day',
          style: TextStyle(
            color: GoldTones.light,
            fontSize: size * 0.24,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );

  Widget _back() {
    if (!correct) {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: IvoryColors.plum.withValues(alpha: 0.7),
          border: Border.all(color: IvoryColors.gold.withValues(alpha: 0.25)),
        ),
        child: Icon(
          Icons.close_rounded,
          size: size * 0.42,
          color: IvoryColors.cream.withValues(alpha: 0.55),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.35, -0.45),
          colors: <Color>[
            GoldTones.shine,
            GoldTones.light,
            GoldTones.mid,
            GoldTones.deep,
          ],
          stops: <double>[0, 0.3, 0.7, 1],
        ),
        border: Border.all(
          color: golden ? GoldTones.shine : GoldTones.rim,
          width: golden ? 2.2 : 1.2,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: GoldTones.light.withValues(alpha: golden ? 0.85 : 0.5),
            blurRadius: golden ? 18 : 9,
            spreadRadius: golden ? 2 : 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: FittedBox(
          child: Text(
            '\u20B9$amountInr',
            style: const TextStyle(
              color: IvoryColors.burgundy,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: flipped ? 1 : 0),
      duration: const Duration(milliseconds: 560),
      curve: Curves.easeInOutCubic,
      builder: (BuildContext context, double v, Widget? _) {
        final bool back = v > 0.5;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0016)
            ..rotateY(v * math.pi),
          child: back
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(math.pi),
                  child: _back(),
                )
              : _front(),
        );
      },
    );
  }
}

// END OF FILE - lib/widgets/vault_keys.dart
