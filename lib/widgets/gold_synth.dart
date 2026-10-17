import 'dart:math' as math;
import 'dart:typed_data';

/// ============================================================
/// IVORY - THE SOUND OF GOLD (made from mathematics, no files)
///
/// Every sound in The Golden Knock-off is built here from sine
/// waves: bells with the slightly out-of-tune overtones of real
/// metal, a rising whoosh, a soft thud. Nothing is downloaded and
/// no audio file sits in the app, so it costs the APK nothing.
///
/// Pure Dart on purpose (no Flutter imports) so it can be tested
/// on its own. Each sound is a list of samples between -1 and 1.
/// ============================================================
class GoldSynth {
  GoldSynth._();

  static const int rate = 22050;

  static List<double> _blank(double sec) =>
      List<double>.filled((sec * rate).round(), 0.0);

  /// One bell strike at [start] seconds. Real bells ring with partials
  /// that are not whole multiples; that is what makes it sound like metal.
  static void _bell(
    List<double> b,
    double start,
    double hz,
    double dur, {
    double amp = 0.5,
    double decay = 5.0,
  }) {
    const List<double> ratio = <double>[1, 2.0, 2.76, 5.4, 8.9];
    const List<double> gain = <double>[1, 0.55, 0.32, 0.16, 0.07];
    const List<double> fall = <double>[1, 1.5, 2.2, 3.4, 5.0];
    final int s0 = (start * rate).round();
    final int n = (dur * rate).round();
    for (int i = 0; i < n && s0 + i < b.length; i++) {
      final double t = i / rate;
      final double attack = math.min(1.0, t / 0.003);
      double v = 0;
      for (int k = 0; k < ratio.length; k++) {
        v +=
            gain[k] *
            math.exp(-t * decay * fall[k]) *
            math.sin(2 * math.pi * hz * ratio[k] * t);
      }
      b[s0 + i] += v * attack * amp;
    }
  }

  /// A soft, round tone (for the low notes).
  static void _tone(
    List<double> b,
    double start,
    double hz,
    double dur, {
    double amp = 0.4,
    double decay = 6.0,
    double slide = 0,
  }) {
    final int s0 = (start * rate).round();
    final int n = (dur * rate).round();
    double phase = 0;
    for (int i = 0; i < n && s0 + i < b.length; i++) {
      final double t = i / rate;
      final double f = hz * (1 - slide * (t / dur));
      phase += 2 * math.pi * f / rate;
      b[s0 + i] +=
          math.sin(phase) *
          math.exp(-t * decay) *
          math.min(1.0, t / 0.004) *
          amp;
    }
  }

  /// Air rushing upward: noise whose brightness climbs.
  static void _whoosh(List<double> b, double start, double dur, double amp) {
    final math.Random r = math.Random(7);
    final int s0 = (start * rate).round();
    final int n = (dur * rate).round();
    double lp = 0;
    for (int i = 0; i < n && s0 + i < b.length; i++) {
      final double p = i / n;
      final double a = 0.04 + 0.5 * p * p;
      lp += a * ((r.nextDouble() * 2 - 1) - lp);
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
    // A short fade at both ends so nothing ever clicks.
    final int f = (0.004 * rate).round();
    for (int i = 0; i < f && i < b.length; i++) {
      final double w = i / f;
      b[i] *= w;
      b[b.length - 1 - i] *= w;
    }
    return b;
  }

  // ------------------------------------------------------------ sounds

  static List<double> tap() {
    final List<double> b = _blank(0.09);
    _bell(b, 0, 1568, 0.09, amp: 0.4, decay: 40);
    return _fin(b, 0.55);
  }

  static List<double> tick() {
    final List<double> b = _blank(0.07);
    _tone(b, 0, 1320, 0.07, amp: 0.5, decay: 55);
    return _fin(b, 0.5);
  }

  /// Seal [i] (0 to 9): a bright note climbing a pentatonic scale.
  static List<double> seal(int i) {
    const List<double> scale = <double>[
      523.25,
      587.33,
      659.25,
      783.99,
      880.0,
      1046.5,
      1174.7,
      1318.5,
      1568.0,
      1760.0,
    ];
    final List<double> b = _blank(0.16);
    _bell(b, 0, scale[i % 10], 0.16, amp: 0.45, decay: 14);
    return _fin(b, 0.6);
  }

  static List<double> reveal() {
    final List<double> b = _blank(1.9);
    _whoosh(b, 0, 0.55, 0.5);
    const List<double> chord = <double>[523.25, 659.25, 783.99, 1046.5];
    for (int i = 0; i < chord.length; i++) {
      _bell(b, 0.5 + i * 0.07, chord[i], 1.3, amp: 0.5, decay: 2.6);
    }
    for (int i = 0; i < 6; i++) {
      _bell(b, 0.75 + i * 0.09, 2093.0 + i * 260, 0.4, amp: 0.12, decay: 9);
    }
    return _fin(b, 0.85);
  }

  static List<double> correct() {
    final List<double> b = _blank(0.8);
    _bell(b, 0, 659.25, 0.5, amp: 0.5, decay: 5);
    _bell(b, 0.1, 880.0, 0.7, amp: 0.55, decay: 4);
    _bell(b, 0.1, 1318.5, 0.5, amp: 0.2, decay: 6);
    return _fin(b, 0.8);
  }

  static List<double> golden() {
    final List<double> b = _blank(1.4);
    const List<double> arp = <double>[1046.5, 1318.5, 1568.0, 2093.0, 2637.0];
    for (int i = 0; i < arp.length; i++) {
      _bell(b, i * 0.075, arp[i], 0.9, amp: 0.4, decay: 3.5);
    }
    _bell(b, 0.3, 523.25, 1.0, amp: 0.4, decay: 3);
    for (int i = 0; i < 8; i++) {
      _bell(
        b,
        0.2 + i * 0.07,
        3136.0 + (i % 3) * 400,
        0.3,
        amp: 0.1,
        decay: 10,
      );
    }
    return _fin(b, 0.9);
  }

  static List<double> wrong() {
    final List<double> b = _blank(0.45);
    _tone(b, 0, 150, 0.45, amp: 0.6, decay: 7, slide: 0.45);
    _tone(b, 0, 75, 0.45, amp: 0.4, decay: 8, slide: 0.3);
    return _fin(b, 0.7);
  }

  static List<double> timeout() {
    final List<double> b = _blank(0.7);
    _tone(b, 0, 196, 0.3, amp: 0.5, decay: 5);
    _tone(b, 0.22, 147, 0.45, amp: 0.55, decay: 4.5);
    return _fin(b, 0.7);
  }

  /// The finale. A perfect ten gets the full fanfare.
  static List<double> finish({required bool perfect, required bool won}) {
    final List<double> b = _blank(perfect ? 3.0 : 2.0);
    if (!won) {
      _bell(b, 0, 392.0, 1.2, amp: 0.5, decay: 3.5);
      _bell(b, 0.18, 493.9, 1.4, amp: 0.45, decay: 3.2);
      return _fin(b, 0.7);
    }
    const List<double> up = <double>[523.25, 659.25, 783.99, 1046.5];
    final int n = perfect ? up.length : 3;
    for (int i = 0; i < n; i++) {
      _bell(b, i * 0.13, up[i], 1.6, amp: 0.5, decay: 2.4);
    }
    if (perfect) {
      for (int i = 0; i < 3; i++) {
        _bell(b, 0.7, up[i] * 2, 2.0, amp: 0.35, decay: 1.8);
      }
      for (int i = 0; i < 14; i++) {
        _bell(
          b,
          0.8 + i * 0.12,
          2637.0 + (i % 4) * 330,
          0.45,
          amp: 0.1,
          decay: 8,
        );
      }
    }
    return _fin(b, 0.9);
  }

  // -------------------------------------------------------------- WAV

  /// Joins sounds into one WAV with a gap between, and says where each is.
  static Bank bank(Map<String, List<double>> sounds) {
    final List<double> all = <double>[];
    final Map<String, List<int>> spans = <String, List<int>>{};
    final int gap = (0.06 * rate).round();
    sounds.forEach((String name, List<double> s) {
      final int startMs = (all.length * 1000 / rate).round();
      all.addAll(s);
      spans[name] = <int>[startMs, (s.length * 1000 / rate).round()];
      all.addAll(List<double>.filled(gap, 0.0));
    });
    return Bank(wav(all), spans);
  }

  static Uint8List wav(List<double> s) {
    final int n = s.length;
    final ByteData d = ByteData(44 + n * 2);
    void str(int o, String t) {
      for (int i = 0; i < t.length; i++) {
        d.setUint8(o + i, t.codeUnitAt(i));
      }
    }

    str(0, 'RIFF');
    d.setUint32(4, 36 + n * 2, Endian.little);
    str(8, 'WAVE');
    str(12, 'fmt ');
    d.setUint32(16, 16, Endian.little);
    d.setUint16(20, 1, Endian.little);
    d.setUint16(22, 1, Endian.little);
    d.setUint32(24, rate, Endian.little);
    d.setUint32(28, rate * 2, Endian.little);
    d.setUint16(32, 2, Endian.little);
    d.setUint16(34, 16, Endian.little);
    str(36, 'data');
    d.setUint32(40, n * 2, Endian.little);
    for (int i = 0; i < n; i++) {
      final int v = (s[i].clamp(-1.0, 1.0) * 32767).round();
      d.setInt16(44 + i * 2, v, Endian.little);
    }
    return d.buffer.asUint8List();
  }
}

/// A WAV file plus where each named sound starts and how long it runs
/// (both in milliseconds).
class Bank {
  Bank(this.bytes, this.spans);

  final Uint8List bytes;
  final Map<String, List<int>> spans;
}

// END OF FILE - lib/widgets/gold_synth.dart
