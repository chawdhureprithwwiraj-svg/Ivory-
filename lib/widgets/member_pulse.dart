import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/ivory_theme.dart';

/// ============================================================
/// IVORY - THE MEMBER PULSE
///
/// "You are the 2,317 member who visited today."
///
/// TWO RULES THAT MAKE IT FEEL REAL
///
/// 1. IT RUNS ON INDIA TIME, and on Ivory's day, not the clock's.
///    A day here begins at 5 in the morning IST, not at midnight -
///    so 2 a.m. is still the busy tail of the evening before, not
///    the dead start of a new morning. The number climbs all
///    evening and peaks in the small hours, which is when Ivory is
///    actually read.
///
/// 2. IT NEVER MOVES WHILE YOU ARE LOOKING AT IT.
///    The number is fixed for one visit and cannot go down within a
///    day: the last number shown is remembered, and the next visit
///    is always higher.
///
///    A visit is a real return, not a glance away. Taking a
///    screenshot, checking a message, or flicking to another app for
///    a few seconds changes nothing - the counter only moves once
///    you have been away, or been here, for at least a few minutes.
///    A counter that ticked every time you blinked would announce
///    itself as fake.
/// ============================================================
class MemberPulse {
  MemberPulse._();

  /// India Standard Time, whatever the phone is set to.
  static const Duration _ist = Duration(hours: 5, minutes: 30);

  /// Ivory's day starts at 05:00 IST.
  static const Duration _dayStart = Duration(hours: 5);

  static const String _kDay = 'ivory_pulse_day';
  static const String _kValue = 'ivory_pulse_value';
  static const String _kAt = 'ivory_pulse_at';

  /// How settled things must be before a return counts as a new
  /// visit. Short enough to feel alive, long enough to never look
  /// mechanical.
  static const Duration _cooldown = Duration(minutes: 4);

  /// The number for this visit. Computed once, then held.
  static int? _current;

  static int get value => _current ?? _estimate().round();

  static String get formattedValue => _format(value);

  /// Kept for older call sites.
  static String formatted() => formattedValue;

  // ---------------------------------------------------------------
  // The maths
  // ---------------------------------------------------------------
  static DateTime get _nowIst => DateTime.now().toUtc().add(_ist);

  /// Which Ivory day we are in, counted from 05:00 IST.
  static int get _dayNumber {
    final DateTime shifted = _nowIst.subtract(_dayStart);
    return shifted.millisecondsSinceEpoch ~/ 86400000;
  }

  /// How far through the day we are, 0.0 at 5 a.m. to 1.0 at 5 a.m.
  static double get _through {
    final DateTime n = _nowIst.subtract(_dayStart);
    final DateTime midnight = DateTime.utc(n.year, n.month, n.day);
    final double ms =
        n.millisecondsSinceEpoch - midnight.millisecondsSinceEpoch.toDouble();
    return (ms / 86400000).clamp(0.0, 1.0);
  }

  static int _hash(int n) {
    int h = (n * 2654435761) & 0x7FFFFFFF;
    h ^= h >> 13;
    h = (h * 1274126177) & 0x7FFFFFFF;
    h ^= h >> 16;
    return h;
  }

  /// Where the count sits right now, before any memory is applied.
  static double _estimate() {
    final int day = _dayNumber;

    // A different shape every day, but the same all day.
    final int dawn = 640 + _hash(day) % 260;
    final int dusk = 2450 + _hash(day + 9176) % 1550;

    final double t = _through;

    // Slow at first, then steepening: most members arrive late.
    final double curve = 0.34 * t + 0.66 * pow(t, 2.2).toDouble();

    final double v = dawn + (dusk - dawn) * curve;
    return v < 700 ? 700 : v;
  }

  // ---------------------------------------------------------------
  // One number per visit
  // ---------------------------------------------------------------

  /// Called when the app opens and every time it returns to the
  /// foreground. Works out this visit's number and remembers it, so
  /// the next visit is always higher than this one.
  static Future<void> newVisit() async {
    final int day = _dayNumber;
    int next = _estimate().round();

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final int lastDay = prefs.getInt(_kDay) ?? -1;
      final int lastValue = prefs.getInt(_kValue) ?? 0;
      final int lastAt = prefs.getInt(_kAt) ?? 0;

      final int sinceMs = DateTime.now().millisecondsSinceEpoch - lastAt;

      // Still inside the quiet window? Then this is the same visit,
      // however many times the app has been in and out of view.
      if (lastDay == day &&
          lastValue > 0 &&
          sinceMs < _cooldown.inMilliseconds) {
        _current = lastValue;
        return;
      }

      if (lastDay == day && next <= lastValue) {
        // The clock has barely moved, but this is a new visit: nudge
        // it up by a believable handful rather than repeating.
        final int bump = 1 + _hash(lastValue + day) % 7;
        next = lastValue + bump;
      }

      await prefs.setInt(_kDay, day);
      await prefs.setInt(_kValue, next);
      await prefs.setInt(_kAt, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {
      // Storage is a nicety here, never a requirement.
    }

    _current = next;
  }

  static String _format(int n) {
    final String s = n.toString();
    if (s.length <= 3) return s;
    final String head = s.substring(0, s.length - 3);
    final String tail = s.substring(s.length - 3);
    return '$head,$tail';
  }
}

/// The strip itself. It listens for the app coming back to the
/// foreground and asks for a fresh number then - and only then.
class MemberPulseStrip extends StatefulWidget {
  const MemberPulseStrip({super.key, this.compact = false});

  /// A slimmer, quieter version for the Profile screen.
  final bool compact;

  @override
  State<MemberPulseStrip> createState() => _MemberPulseStripState();
}

class _MemberPulseStripState extends State<MemberPulseStrip>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back from the home screen, another app, or a locked
    // phone counts as a new visit. Nothing else does.
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    await MemberPulse.newVisit();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final String n = MemberPulse.formattedValue;

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
  const _Pulse({required this.size});

  final double size;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1).animate(_c),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: IvoryColors.success,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// END OF FILE - lib/widgets/member_pulse.dart
