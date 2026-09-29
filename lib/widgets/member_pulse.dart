import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';

/// ============================================================
/// THE MEMBER PULSE
///
/// "You are the 1,842 member who visited today."
///
/// The number is generated on the phone, entirely offline, from the
/// calendar date plus the time of day, so:
///
///   * every member sees the same number on the same day at the same
///     minute (it is seeded by the date, not by a random call),
///   * it only ever climbs as the day goes on - quiet in the morning,
///     busy at night,
///   * it resets to a fresh, different figure at midnight,
///   * the day's closing figure lands anywhere between roughly 2,400
///     and 4,000, while the first hours of the morning sit near 700.
///
/// No server call, no cost, no stored state.
/// ============================================================
class MemberPulse {
  MemberPulse._();

  /// Deterministic 32-bit hash of an integer seed.
  static int _hash(int seed) {
    int x = (seed * 2654435761) & 0x7FFFFFFF;
    x ^= (x >> 13);
    x = (x * 1274126177) & 0x7FFFFFFF;
    x ^= (x >> 16);
    return x & 0x7FFFFFFF;
  }

  /// How many members have "visited" so far today.
  static int count([DateTime? at]) {
    final DateTime now = at ?? DateTime.now();
    final int dayNumber =
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch ~/
            Duration.millisecondsPerDay;

    // Two independent daily seeds: where the day starts and where it ends.
    final int h1 = _hash(dayNumber);
    final int h2 = _hash(dayNumber + 9176);

    final int dawn = 640 + (h1 % 260); //  640 -  899
    final int dusk = 2450 + (h2 % 1550); // 2450 - 3999

    // Share of the day already gone, 0.0 at midnight to 1.0 at 23:59.
    final double t =
        ((now.hour * 60 + now.minute) / 1440.0).clamp(0.0, 1.0).toDouble();

    // A night-heavy curve: a slow linear trickle plus an accelerating
    // evening rush, so 8 a.m. is calm and 11 p.m. is the day's peak.
    final double curve = 0.34 * t + 0.66 * math.pow(t, 2.2).toDouble();

    final int value = dawn + ((dusk - dawn) * curve).round();
    return value < 700 ? 700 : value;
  }

  /// 1842 -> "1,842"
  static String formatted([DateTime? at]) {
    final String s = count(at).toString();
    final StringBuffer out = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
      out.write(s[i]);
    }
    return out.toString();
  }
}

/// The little live strip shown on Home and Profile. It refreshes itself
/// every minute so the figure visibly creeps upward while the app is open.
class MemberPulseStrip extends StatefulWidget {
  const MemberPulseStrip({super.key, this.compact = false});

  /// A slimmer, quieter version for the Profile screen.
  final bool compact;

  @override
  State<MemberPulseStrip> createState() => _MemberPulseStripState();
}

class _MemberPulseStripState extends State<MemberPulseStrip> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 45), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String n = MemberPulse.formatted();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.compact ? 14 : 18,
        vertical: widget.compact ? 8 : 11,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFFFFFCF2), Color(0xFFFDF1DC)],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: IvoryColors.hairline),
        boxShadow: IvoryTheme.softShadow(blur: 10, y: 4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _Pulse(size: widget.compact ? 7 : 8),
          SizedBox(width: widget.compact ? 8 : 10),
          Flexible(
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  fontSize: widget.compact ? 12 : 13,
                  color: IvoryColors.textSoft,
                  height: 1.35,
                ),
                children: <TextSpan>[
                  const TextSpan(text: 'You are the '),
                  TextSpan(
                    text: n,
                    style: TextStyle(
                      fontFamily: IvoryTheme.displayFont,
                      fontSize: widget.compact ? 14.5 : 16,
                      fontWeight: FontWeight.w700,
                      color: IvoryColors.burgundy,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const TextSpan(text: ' member who visited today.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A slowly breathing gold dot - the "live" tell.
class _Pulse extends StatefulWidget {
  const _Pulse({this.size = 8});

  final double size;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (BuildContext context, Widget? child) {
        final double v = 0.35 + 0.65 * _c.value;
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: IvoryColors.success.withValues(alpha: v),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: IvoryColors.success.withValues(alpha: 0.30 * v),
                blurRadius: 7 * v,
                spreadRadius: 1.5 * v,
              ),
            ],
          ),
        );
      },
    );
  }
}
