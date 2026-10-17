import 'dart:math' as math;

import 'gold_synth.dart';

/// ============================================================
/// IVORY - THE SOUND OF THE DOORBELL (made from mathematics)
///
/// A struck bell is not one note. It is a hum below the note, the note
/// itself, a minor third, a fifth, the octave and a handful of
/// out-of-tune higher partials, each dying away at its own speed, with
/// a twin of every low partial a hair off pitch so the sound shimmers
/// and beats the way real metal does. A tiny burst of noise is the
/// strike. A small room around it gives the tail. Nothing is
/// downloaded; the sounds are built once in the background.
///
/// Pure Dart on purpose (no Flutter imports) so it can be tested alone.
/// ============================================================
class BellSynth {
  BellSynth._();

  static const int rate = GoldSynth.rate;

  // ratio to the note, loudness, how long it rings (seconds at len 3.5)
  static const List<List<double>> _partials = <List<double>>[
    <double>[0.5, 0.50, 6.0],
    <double>[1.0, 1.00, 4.2],
    <double>[1.19, 0.72, 3.2],
    <double>[1.5, 0.40, 2.6],
    <double>[2.0, 0.55, 2.3],
    <double>[2.5, 0.22, 1.6],
    <double>[3.0, 0.16, 1.2],
    <double>[4.2, 0.10, 0.8],
    <double>[5.33, 0.06, 0.5],
  ];

  static List<double> _blank(double sec) =>
      List<double>.filled((sec * rate).round(), 0.0);

  /// One struck bell at [start] seconds on note [hz].
  static void strike(
    List<double> b,
    double start,
    double hz,
    double len, {
    double amp = 0.5,
  }) {
    final int s0 = (start * rate).round();
    final int n = (len * rate).round();
    for (int k = 0; k < _partials.length; k++) {
      final List<double> p = _partials[k];
      final double tau = p[2] * len / 3.5 / 2.2;
      final int twins = k < 5 ? 2 : 1;
      for (int w = 0; w < twins; w++) {
        final double f = hz * p[0] * (w == 0 ? 1.0 : 1.004 + k * 0.0007);
        final double g = amp * p[1] * (w == 0 ? 1.0 : 0.55);
        final double step = 2 * math.pi * f / rate;
        if (f > rate / 2.2) continue;
        for (int i = 0; i < n && s0 + i < b.length; i++) {
          final double t = i / rate;
          final double e = math.exp(-t / tau);
          if (e < 0.0008) break;
          b[s0 + i] += g * e * math.min(1.0, t / 0.004) * math.sin(step * i);
        }
      }
    }
    // The strike: a short tick of noise around the third partial.
    final math.Random r = math.Random(start.hashCode ^ hz.round());
    final int m = (0.045 * rate).round();
    double lp = 0;
    final double a = math.min(0.9, 2 * math.pi * hz * 3 / rate);
    for (int i = 0; i < m && s0 + i < b.length; i++) {
      final double x = r.nextDouble() * 2 - 1;
      lp += a * (x - lp);
      b[s0 + i] += (x - lp) * math.pow(1 - i / m, 3).toDouble() * amp * 0.5;
    }
  }

  /// A small room: four combs and two all-pass filters around the sound.
  static List<double> _room(List<double> dry, double wet) {
    final int n = dry.length;
    final List<double> out = List<double>.from(dry);
    const List<double> combT = <double>[0.0297, 0.0371, 0.0411, 0.0437];
    const List<double> combG = <double>[0.80, 0.78, 0.77, 0.75];
    final List<double> acc = List<double>.filled(n, 0.0);
    for (int c = 0; c < combT.length; c++) {
      final int d = (combT[c] * rate).round();
      final List<double> y = List<double>.filled(n, 0.0);
      for (int i = 0; i < n; i++) {
        final double prev = i >= d ? y[i - d] : 0.0;
        y[i] = dry[i] + combG[c] * prev;
        acc[i] += y[i];
      }
    }
    for (final double dl in <double>[0.005, 0.0017]) {
      final int d = (dl * rate).round();
      final List<double> y = List<double>.filled(n, 0.0);
      for (int i = 0; i < n; i++) {
        final double x = acc[i];
        final double xd = i >= d ? acc[i - d] : 0.0;
        final double yd = i >= d ? y[i - d] : 0.0;
        y[i] = -0.7 * x + xd + 0.7 * yd;
      }
      for (int i = 0; i < n; i++) {
        acc[i] = y[i];
      }
    }
    for (int i = 0; i < n; i++) {
      out[i] += wet * acc[i] * 0.25;
    }
    return out;
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
    // A slow fade so a long tail never ends on a click.
    final int tail = (0.25 * rate).round();
    for (int i = 0; i < tail && i < b.length; i++) {
      b[b.length - 1 - i] *= i / tail;
    }
    return b;
  }

  // the four notes of the day: C, E, G, B
  static const List<double> notes = <double>[523.25, 659.25, 783.99, 987.77];

  /// Bell [i] (0 dawn, 1 noon, 2 dusk, 3 night), rung once.
  static List<double> ring(int i) {
    final List<double> b = _blank(5.2);
    final double hz = notes[i % 4];
    strike(b, 0, hz, 3.8, amp: 0.6);
    strike(b, 0.012, hz * 2, 1.6, amp: 0.10);
    return _fin(_room(b, 1.0), 0.9);
  }

  /// The doorbell: a bright ding, then a lower dong.
  static void _door(List<double> b, double at) {
    strike(b, at, 783.99, 2.6, amp: 0.55);
    strike(b, at + 0.55, 587.33, 3.6, amp: 0.6);
  }

  static List<double> door() {
    final List<double> b = _blank(5.4);
    _door(b, 0);
    return _fin(_room(b, 1.0), 0.9);
  }

  /// A Full Day: the four notes climb, a sparkle, then the doorbell.
  static List<double> full() {
    final List<double> b = _blank(8.0);
    for (int i = 0; i < 4; i++) {
      strike(b, i * 0.24, notes[i], 3.4, amp: 0.5);
    }
    const List<double> spark = <double>[1046.5, 1318.5, 1568.0, 2093.0, 2637.0];
    for (int i = 0; i < spark.length; i++) {
      strike(b, 1.15 + i * 0.1, spark[i], 1.4, amp: 0.2);
    }
    _door(b, 2.3);
    return _fin(_room(b, 1.1), 0.92);
  }

  /// A tiny bright ping for tapping a button.
  static List<double> tap() {
    final List<double> b = _blank(0.7);
    strike(b, 0, 1567.98, 0.5, amp: 0.4);
    return _fin(_room(b, 0.5), 0.6);
  }

  /// Ivory's line opens: three soft notes slipping down.
  static List<double> line() {
    final List<double> b = _blank(7.0);
    const List<double> d = <double>[987.77, 783.99, 659.25];
    for (int i = 0; i < d.length; i++) {
      strike(b, i * 0.5, d[i], 3.6, amp: 0.38);
    }
    return _fin(_room(b, 1.3), 0.8);
  }

  /// Every sound of the doorbell in one WAV, with where each starts.
  static Bank build() {
    return GoldSynth.bank(<String, List<double>>{
      'ring0': ring(0),
      'ring1': ring(1),
      'ring2': ring(2),
      'ring3': ring(3),
      'door': door(),
      'full': full(),
      'tap': tap(),
      'line': line(),
    });
  }
}

// END OF FILE - lib/widgets/bell_synth.dart
