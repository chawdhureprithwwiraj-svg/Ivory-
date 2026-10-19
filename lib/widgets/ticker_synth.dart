import 'dart:math' as math;

import 'gold_synth.dart';

/// ============================================================
/// IVORY - THE TICKER'S CHIMES (made from mathematics, no files)
///
/// Soft music-box notes: a small, sweet three-note chime for an
/// ordinary ribbon, a brighter sparkling run for a Grand one, and a
/// tiny ping. Every note is a plucked sine with a faint shimmer, kept
/// quiet on purpose. Nothing is downloaded and no audio file sits in
/// the app.
/// ============================================================
class TickerSynth {
  TickerSynth._();

  static const int rate = GoldSynth.rate;

  static List<double> _blank(double sec) =>
      List<double>.filled((sec * rate).round(), 0.0);

  /// One music-box pluck at [start] seconds.
  static void _box(
    List<double> b,
    double start,
    double hz,
    double dur, {
    double amp = 0.4,
    double decay = 7.5,
  }) {
    final int s0 = (start * rate).round();
    final int n = (dur * rate).round();
    for (int i = 0; i < n && s0 + i < b.length; i++) {
      final double t = i / rate;
      final double attack = math.min(1.0, t / 0.002);
      final double v =
          math.sin(2 * math.pi * hz * t) +
          0.32 * math.sin(2 * math.pi * hz * 2 * t) * math.exp(-t * 9) +
          0.12 * math.sin(2 * math.pi * hz * 3.01 * t) * math.exp(-t * 14) +
          0.45 * math.sin(2 * math.pi * hz * 1.004 * t) * math.exp(-t * 8);
      b[s0 + i] += v * math.exp(-t * decay) * attack * amp;
    }
  }

  static List<double> _fin(List<double> b, double peak) {
    double m = 0.0001;
    for (final double v in b) {
      if (v.abs() > m) m = v.abs();
    }
    final double g = peak / m;
    for (int i = 0; i < b.length; i++) {
      b[i] *= g;
    }
    final int f = (0.006 * rate).round();
    for (int i = 0; i < f && i < b.length; i++) {
      final double w = i / f;
      b[i] *= w;
      b[b.length - 1 - i] *= w;
    }
    return b;
  }

  /// E6, G6, C7: a small sweet rise.
  static List<double> soft() {
    final List<double> b = _blank(0.95);
    _box(b, 0.00, 1318.5, 0.7, amp: 0.5);
    _box(b, 0.11, 1568.0, 0.7, amp: 0.45);
    _box(b, 0.22, 2093.0, 0.8, amp: 0.4);
    return _fin(b, 0.5);
  }

  /// C6 up to E7 with a shimmer on top, for a Grand moment.
  static List<double> grand() {
    final List<double> b = _blank(1.9);
    _box(b, 0.00, 1046.5, 0.9, amp: 0.5);
    _box(b, 0.09, 1318.5, 0.9, amp: 0.46);
    _box(b, 0.18, 1568.0, 0.9, amp: 0.44);
    _box(b, 0.27, 2093.0, 1.0, amp: 0.42);
    _box(b, 0.36, 2637.0, 1.2, amp: 0.4);
    _box(b, 0.52, 3136.0, 0.9, amp: 0.16, decay: 5);
    _box(b, 0.60, 4186.0, 0.9, amp: 0.1, decay: 5);
    return _fin(b, 0.55);
  }

  /// G6, B6, D7, G7: a bright little sparkle for a cheer sent.
  static List<double> cheer() {
    final List<double> b = _blank(1.1);
    _box(b, 0.00, 1568.0, 0.8, amp: 0.5);
    _box(b, 0.08, 1975.5, 0.8, amp: 0.46);
    _box(b, 0.16, 2349.3, 0.8, amp: 0.42);
    _box(b, 0.24, 3136.0, 0.9, amp: 0.38);
    _box(b, 0.34, 3951.1, 0.7, amp: 0.14, decay: 5);
    return _fin(b, 0.5);
  }

  static List<double> tap() {
    final List<double> b = _blank(0.3);
    _box(b, 0.0, 2093.0, 0.25, amp: 0.4, decay: 12);
    _box(b, 0.06, 2637.0, 0.22, amp: 0.3, decay: 12);
    return _fin(b, 0.45);
  }

  static Bank build() => GoldSynth.bank(<String, List<double>>{
    'soft': soft(),
    'grand': grand(),
    'tap': tap(),
    'cheer': cheer(),
  });
}

// END OF FILE - lib/widgets/ticker_synth.dart
