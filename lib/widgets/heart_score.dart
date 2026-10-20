import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import 'heart_sound.dart';

/// ============================================================
/// IVORY - THE SOUND OF THE GOLDEN HEART SCREEN
///
/// The owner's two recordings, played in order: "First" (the rush,
/// then the beating of the heart) plays once the moment the Golden
/// Heart screen opens; then "Second" (the heartbeat) goes on and on,
/// seamlessly, for as long as the member stays on the screen.
///
/// The recordings are two .wav files in the app's assets folder (the
/// app finds them by name: one containing "first", one containing
/// "second"). Before playing they are made LOUDER: mixed to one
/// channel, lifted to a strong level and softly limited so nothing
/// distorts, and the second one is joined end to start so the loop
/// has no gap. If the files are not there, nothing here plays and the
/// older soft opening sound is used instead.
///
/// The member's "Golden Heart sounds" switch switches all of it off.
/// ============================================================
class HeartScore {
  HeartScore._();
  static final HeartScore instance = HeartScore._();

  Future<List<String>?>? _ready;
  VideoPlayerController? _a;
  VideoPlayerController? _b;
  Timer? _next;
  int _run = 0;
  bool _paused = false;

  /// Starts the score. Returns true if the member's recordings are
  /// going to play (so the caller does not add another sound).
  Future<bool> start() async {
    final int run = ++_run;
    _paused = false;
    await HeartSound.instance.load();
    if (!HeartSound.instance.on.value) return false;
    final List<String>? files = await (_ready ??= _prepare());
    if (files == null || run != _run) return files != null;
    try {
      await _stopPlayers();
      if (run != _run) return true;
      final VideoPlayerController a = VideoPlayerController.file(
        File(files[0]),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      final VideoPlayerController b = VideoPlayerController.file(
        File(files[1]),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      _a = a;
      _b = b;
      await a.initialize();
      await b.initialize();
      if (run != _run) {
        await a.dispose();
        await b.dispose();
        return true;
      }
      await a.setVolume(1.0);
      await b.setVolume(1.0);
      await b.setLooping(true);
      if (_paused) return true;
      await a.play();
      final Duration d = a.value.duration;
      _next = Timer(d - const Duration(milliseconds: 60), () {
        if (run != _run || _paused) return;
        b.play();
      });
    } catch (_) {
      return false;
    }
    return true;
  }

  /// The app went to the background: go quiet.
  void pause() {
    _paused = true;
    _next?.cancel();
    _a?.pause();
    _b?.pause();
  }

  /// The app came back: the heartbeat goes on.
  void resume() {
    if (!_paused) return;
    _paused = false;
    final VideoPlayerController? a = _a;
    final VideoPlayerController? b = _b;
    if (a == null || b == null) return;
    final Duration left = a.value.duration - a.value.position;
    if (left > const Duration(milliseconds: 200)) {
      a.play();
      final int run = _run;
      _next = Timer(left - const Duration(milliseconds: 60), () {
        if (run != _run || _paused) return;
        b.play();
      });
    } else {
      b.play();
    }
  }

  /// The member left the screen: stop everything.
  Future<void> stop() async {
    _run++;
    await _stopPlayers();
  }

  Future<void> _stopPlayers() async {
    _next?.cancel();
    _next = null;
    final VideoPlayerController? a = _a;
    final VideoPlayerController? b = _b;
    _a = null;
    _b = null;
    try {
      await a?.pause();
      await a?.dispose();
    } catch (_) {}
    try {
      await b?.pause();
      await b?.dispose();
    } catch (_) {}
  }

  // Finds the two recordings, makes them louder and writes them to the
  // cache folder. Done once per app run.
  Future<List<String>?> _prepare() async {
    try {
      final AssetManifest m = await AssetManifest.loadFromAssetBundle(
        rootBundle,
      );
      String? first;
      String? second;
      for (final String p in m.listAssets()) {
        final String l = p.toLowerCase();
        if (!l.endsWith('.wav')) continue;
        if (l.contains('first') && first == null) first = p;
        if (l.contains('second') && second == null) second = p;
      }
      if (first == null || second == null) return null;
      final ByteData d1 = await rootBundle.load(first);
      final ByteData d2 = await rootBundle.load(second);
      final List<Uint8List> out = await compute(
        _makeScore,
        <Uint8List>[
          d1.buffer.asUint8List(d1.offsetInBytes, d1.lengthInBytes),
          d2.buffer.asUint8List(d2.offsetInBytes, d2.lengthInBytes),
        ],
      );
      final Directory dir = await Directory(
        '${Directory.systemTemp.path}/heart_score',
      ).create(recursive: true);
      final File f1 = File('${dir.path}/first.wav');
      final File f2 = File('${dir.path}/second.wav');
      await f1.writeAsBytes(out[0], flush: true);
      await f2.writeAsBytes(out[1], flush: true);
      return <String>[f1.path, f2.path];
    } catch (_) {
      return null;
    }
  }
}

// Runs in a background isolate.
List<Uint8List> _makeScore(List<Uint8List> input) {
  final _Pcm a = _readWav(input[0]);
  final _Pcm b = _readWav(input[1]);
  final List<double> x = _loud(a.samples);
  List<double> y = _loud(b.samples);
  y = _loopable(y, (0.3 * b.rate).round());
  return <Uint8List>[_writeWav(x, a.rate), _writeWav(y, b.rate)];
}

class _Pcm {
  _Pcm(this.samples, this.rate);

  final List<double> samples;
  final int rate;
}

_Pcm _readWav(Uint8List w) {
  final ByteData d = ByteData.sublistView(w);
  int channels = 2;
  int bits = 16;
  int rate = 44100;
  int dataStart = -1;
  int dataLen = 0;
  int p = 12;
  while (p + 8 <= w.length) {
    final String id = String.fromCharCodes(w.sublist(p, p + 4));
    int len = d.getUint32(p + 4, Endian.little);
    if (id == 'fmt ') {
      channels = d.getUint16(p + 10, Endian.little);
      rate = d.getUint32(p + 12, Endian.little);
      bits = d.getUint16(p + 22, Endian.little);
    } else if (id == 'data') {
      dataStart = p + 8;
      if (dataStart + len > w.length) len = w.length - dataStart;
      dataLen = len;
      break;
    }
    p += 8 + len + (len & 1);
  }
  if (dataStart < 0) return _Pcm(<double>[0.0], rate);
  final int bytes = bits ~/ 8;
  final int frames = dataLen ~/ (bytes * channels);
  final List<double> out = List<double>.filled(frames, 0.0);
  for (int i = 0; i < frames; i++) {
    double sum = 0;
    for (int c = 0; c < channels; c++) {
      final int o = dataStart + (i * channels + c) * bytes;
      double v;
      if (bits == 16) {
        v = d.getInt16(o, Endian.little) / 32768.0;
      } else if (bits == 24) {
        int n = w[o] | (w[o + 1] << 8) | (w[o + 2] << 16);
        if (n >= 0x800000) n -= 0x1000000;
        v = n / 8388608.0;
      } else if (bits == 32) {
        v = d.getInt32(o, Endian.little) / 2147483648.0;
      } else {
        v = (w[o] - 128) / 128.0;
      }
      sum += v;
    }
    out[i] = sum / channels;
  }
  return _Pcm(out, rate);
}

// Louder: remove any steady offset, lift to a strong level, and round
// off the peaks softly so it stays clean.
List<double> _loud(List<double> s) {
  if (s.isEmpty) return s;
  double mean = 0;
  for (final double v in s) {
    mean += v;
  }
  mean /= s.length;
  double sq = 0;
  for (final double v in s) {
    final double c = v - mean;
    sq += c * c;
  }
  final double rms = math.sqrt(sq / s.length);
  final double gain = rms < 0.0001 ? 1.0 : math.min(8.0, 0.36 / rms);
  final List<double> out = List<double>.filled(s.length, 0.0);
  for (int i = 0; i < s.length; i++) {
    out[i] = _tanh((s[i] - mean) * gain) * 0.97;
  }
  return out;
}

double _tanh(double x) {
  if (x > 20) return 1.0;
  if (x < -20) return -1.0;
  final double e = math.exp(2 * x);
  return (e - 1) / (e + 1);
}

// Joins the end of the sound into its beginning so it can repeat
// with no gap and no click.
List<double> _loopable(List<double> s, int overlap) {
  final int n = s.length;
  if (n < overlap * 3) return s;
  final int len = n - overlap;
  final List<double> out = List<double>.filled(len, 0.0);
  for (int i = 0; i < len; i++) {
    out[i] = s[i];
  }
  for (int i = 0; i < overlap; i++) {
    final double th = (i / overlap) * math.pi / 2;
    out[i] = s[i] * math.sin(th) + s[len + i] * math.cos(th);
  }
  return out;
}

Uint8List _writeWav(List<double> s, int rate) {
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
    final double c = s[i] > 1.0 ? 1.0 : (s[i] < -1.0 ? -1.0 : s[i]);
    d.setInt16(44 + i * 2, (c * 32767).round(), Endian.little);
  }
  return d.buffer.asUint8List();
}

// END OF FILE - lib/widgets/heart_score.dart
