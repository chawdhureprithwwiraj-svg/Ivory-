import 'dart:async';

import 'package:flutter/material.dart';

/// ============================================================
/// IVORY - THE TEASER
///
/// A line that changes every few seconds, sliding and fading in
/// golden light, to say the several true things about The Golden
/// Knock-off in the space of one. Every line is built from numbers
/// the database gave, never invented.
/// ============================================================
class GoldTeaser extends StatefulWidget {
  const GoldTeaser({super.key, required this.lines, required this.style});

  final List<String> lines;
  final TextStyle style;

  @override
  State<GoldTeaser> createState() => _GoldTeaserState();
}

class _GoldTeaserState extends State<GoldTeaser> {
  int _i = 0;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(milliseconds: 4200), (Timer _) {
      if (mounted && widget.lines.length > 1) {
        setState(() => _i = (_i + 1) % widget.lines.length);
      }
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lines.isEmpty) return const SizedBox.shrink();
    final String line = widget.lines[_i % widget.lines.length];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 900),
      switchInCurve: Curves.easeOutCubic,
      transitionBuilder: (Widget child, Animation<double> a) {
        // The old line fades out in the first half, the new one fades in
        // in the second half, so the two are never on top of each other.
        final Animation<double> late = a.drive(
          CurveTween(curve: const Interval(0.5, 1.0)),
        );
        return FadeTransition(
          opacity: late,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.35),
              end: Offset.zero,
            ).animate(late),
            child: child,
          ),
        );
      },
      layoutBuilder: (Widget? cur, List<Widget> prev) => Stack(
        alignment: Alignment.topLeft,
        children: <Widget>[...prev, if (cur != null) cur],
      ),
      child: Text(line, key: ValueKey<String>(line), style: widget.style),
    );
  }
}

// END OF FILE - lib/widgets/gold_teaser.dart
