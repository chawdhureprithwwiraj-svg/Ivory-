import 'dart:math' as math;

import 'gold_synth.dart';

/// ============================================================
/// IVORY - THE SOUND OF THE GOLDEN HEART (made from mathematics)
///
/// Three sounds, romantic and cinematic, with no audio file in the
/// app:
///   kindle - a deep double heartbeat, a warm swelling chord that
///            opens like strings, a rush of fire with soft crackles,
///            then a rising run of pure glass notes.
///   open   - a gentle heartbeat, a quiet warm chord, embers.
///   rain   - golden dust falling: a few very pure, very soft glass
///            notes, like light touching crystal.
/// ============================================================
class HeartSynth {
  HeartSynth._();

  static const int rate = GoldSynth.rate;

  static List<double> _blank(double sec) =>
      List<double>.filled((sec * rate).round(), 0.0);

  /// One beat of a heart: a low note that falls in pitch.
  static void _thump(List<double> b, double start, double amp) {
    final int s0 = (start * rate).round();
    final int n = (0.36 * rate).round();
    double phase = 0;
    for (int i = 0; i < n && s0 + i < b.length; i++) {
      final double t = i / rate;
      final double f = 46 + 64 * math.exp(-t * 22);
      phase += 2 * math.pi * f / rate;
      final double env = math.exp(-t * 11) * math.min(1.0, t / 0.004);
      b[s0 + i] +=
          (math.sin(phase) + 0.35 * math.sin(phase * 2) * math.exp(-t * 30)) *
          env *
          amp;
    }
  }

  /// "Lub-dub".
  static void _lubdub(List<double> b, double start, double amp) {
    _thump(b, start, amp);
    _thump(b, start + 0.3, amp * 0.72);
  }

  /// A warm chord that swells like a section of strings.
  static void _pad(
    List<double> b,
    double start,
    double dur,
    List<double> hz,
    double amp, {
    double attack = 1.5,
    double release = 1.8,
  }) {
    final int s0 = (start * rate).round();
    final int n = (dur * rate).round();
    for (int k = 0; k < hz.length; k++) {
      double p = 0;
      for (int i = 0; i < n && s0 + i < b.length; i++) {
        final double t = i / rate;
        final double up = math.min(1.0, t / attack);
        final double down = math.min(1.0, (dur - t) / release);
        final double e = math.max(0.0, math.min(up, down));
        final double env = e * e;
        p +=
            2 *
            math.pi *
            hz[k] *
            (1 + 0.003 * math.sin(2 * math.pi * 5.1 * t + k)) /
            rate;
        final double v =
            math.sin(p) +
            0.55 * math.sin(p * 1.0029 + 1.1) +
            0.5 * math.sin(p * 0.9971 + 2.0) +
            0.28 * math.sin(2 * p) +
            0.1 * math.sin(3 * p);
        b[s0 + i] += v * env * amp / hz.length;
      }
    }
  }

  /// A pure glass note: nearly a sine, with a faint high partial.
  static void _ping(
    List<double> b,
    double start,
    double hz,
    double dur,
    double amp, {
    double decay = 6,
  }) {
    final int s0 = (start * rate).round();
    final int n = (dur * rate).round();
    for (int i = 0; i < n && s0 + i < b.length; i++) {
      final double t = i / rate;
      final double attack = math.min(1.0, t / 0.0015);
      final double v =
          math.sin(2 * math.pi * hz * t) +
          0.14 * math.sin(2 * math.pi * hz * 2.76 * t) * math.exp(-t * decay);
      b[s0 + i] += v * math.exp(-t * decay) * attack * amp;
    }
  }

  /// Fire: small dry crackles at random moments.
  static void _crackle(
    List<double> b,
    double start,
    double dur,
    double amp,
    int seed,
    double perSecond,
  ) {
    final math.Random r = math.Random(seed);
    double at = 0;
    while (at < dur) {
      at += -math.log(1 - r.nextDouble()) / perSecond;
      final int s0 = ((start + at) * rate).round();
      final int len = ((0.002 + 0.012 * r.nextDouble()) * rate).round();
      final double a = amp * (0.3 + 0.7 * r.nextDouble());
      double last = 0;
      for (int j = 0; j < len && s0 + j < b.length; j++) {
        final double v = r.nextDouble() * 2 - 1;
        b[s0 + j] += (v - last) * 0.5 * math.exp(-j / len * 5) * a;
        last = v;
      }
    }
  }

  /// The low breath of a fire.
  static void _rumble(
    List<double> b,
    double start,
    double dur,
    double amp,
    int seed,
  ) {
    final math.Random r = math.Random(seed);
    final int s0 = (start * rate).round();
    final int n = (dur * rate).round();
    double lp = 0;
    for (int i = 0; i < n && s0 + i < b.length; i++) {
      final double p = i / n;
      lp += 0.02 * ((r.nextDouble() * 2 - 1) - lp);
      final double env = math.sin(math.pi * math.pow(p, 0.8).toDouble());
      final double wob = 0.75 + 0.25 * math.sin(2 * math.pi * 1.7 * i / rate);
      b[s0 + i] += lp * env * wob * amp * 5;
    }
  }

  /// Air rushing up as the fire catches.
  static void _air(
    List<double> b,
    double start,
    double dur,
    double amp,
    int seed,
  ) {
    final math.Random r = math.Random(seed);
    final int s0 = (start * rate).round();
    final int n = (dur * rate).round();
    double lp = 0;
    for (int i = 0; i < n && s0 + i < b.length; i++) {
      final double p = i / n;
      lp += (0.03 + 0.4 * p * p) * ((r.nextDouble() * 2 - 1) - lp);
      final double env = math.sin(math.pi * math.pow(p, 0.7).toDouble());
      b[s0 + i] += lp * env * amp * 2.2;
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
    final int f = (0.02 * rate).round();
    for (int i = 0; i < f && i < b.length; i++) {
      final double w = i / f;
      b[i] *= w;
      b[b.length - 1 - i] *= w;
    }
    return b;
  }

  // D major ninth, voiced low and warm: D3 A3 F#4 C#5 E5.
  static const List<double> _chord = <double>[
    146.83,
    220.0,
    369.99,
    554.37,
    659.25,
  ];

  static List<double> kindle() {
    final List<double> b = _blank(6.2);
    _rumble(b, 0.0, 3.6, 0.55, 11);
    _lubdub(b, 0.05, 0.9);
    _lubdub(b, 1.15, 0.85);
    _lubdub(b, 2.25, 1.0);
    _pad(b, 0.2, 5.8, _chord, 0.9, attack: 2.3, release: 2.4);
    _pad(b, 0.2, 5.6, <double>[73.42], 0.55, attack: 2.0, release: 2.4);
    _air(b, 1.4, 1.6, 0.3, 5);
    const List<double> run = <double>[1174.7, 1480.0, 1760.0, 2217.5, 2637.0];
    for (int i = 0; i < run.length; i++) {
      _ping(b, 2.55 + i * 0.11, run[i], 2.2, 0.36, decay: 3.2);
    }
    final math.Random r = math.Random(3);
    for (int i = 0; i < 9; i++) {
      _ping(
        b,
        3.5 + i * 0.17 + r.nextDouble() * 0.08,
        2300 + r.nextDouble() * 1600,
        1.0,
        0.1,
        decay: 6.5,
      );
    }
    _crackle(b, 0.3, 4.8, 0.22, 21, 22);
    return _fin(b, 0.8);
  }

  static List<double> open() {
    final List<double> b = _blank(3.6);
    _rumble(b, 0.0, 3.2, 0.25, 9);
    _lubdub(b, 0.1, 0.6);
    _lubdub(b, 1.25, 0.55);
    _pad(
      b,
      0.0,
      3.5,
      <double>[146.83, 220.0, 277.18, 369.99],
      0.7,
      attack: 1.3,
      release: 1.6,
    );
    _crackle(b, 0.4, 2.8, 0.12, 4, 12);
    _ping(b, 1.9, 1318.5, 1.5, 0.22, decay: 4);
    _ping(b, 2.15, 1760.0, 1.4, 0.18, decay: 4.5);
    return _fin(b, 0.6);
  }

  static List<double> rain() {
    final List<double> b = _blank(1.9);
    const List<double> notes = <double>[
      1760.0,
      2093.0,
      2349.3,
      2637.0,
      3136.0,
      3520.0,
      3951.1,
    ];
    const List<double> times = <double>[
      0.0,
      0.14,
      0.31,
      0.47,
      0.66,
      0.82,
      1.02,
      1.22,
    ];
    for (int i = 0; i < times.length; i++) {
      _ping(
        b,
        times[i],
        notes[(i * 3 + 1) % notes.length],
        1.1,
        0.3 - i * 0.015,
        decay: 6.5,
      );
    }
    _air(b, 0.0, 1.6, 0.025, 8);
    return _fin(b, 0.5);
  }

  static Bank build() => GoldSynth.bank(<String, List<double>>{
    'kindle': kindle(),
    'open': open(),
    'rain': rain(),
  });
}

// END OF FILE - lib/widgets/heart_synth.dart
