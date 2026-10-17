import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import 'gold_synth.dart';

/// ============================================================
/// IVORY - THE SOUND DESK
///
/// Plays the sounds that GoldSynth builds. The app already carries
/// the video player, which plays any WAV file, so no new package
/// and no audio asset is added: the sounds are written once into
/// the app's cache folder and played from there.
///
/// Two small banks, each one file with a player: quick sounds (tap,
/// tick, seal notes) and the bigger ones (reveal, right, golden,
/// wrong, finale). It mixes with other audio and never pauses a
/// member's music. If anything fails, it stays silent: sound is a
/// pleasure here, never a requirement.
/// ============================================================
class GoldSound {
  GoldSound._();
  static final GoldSound instance = GoldSound._();

  static const String _key = 'gold_sound_on';

  final ValueNotifier<bool> on = ValueNotifier<bool>(true);
  final Map<String, _Deck> _decks = <String, _Deck>{};
  Future<void>? _loading;
  int _gen = 0;

  /// Builds and opens the sounds. Safe to call again; runs once.
  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    final int gen = _gen;
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      on.value = p.getBool(_key) ?? true;
    } catch (_) {}
    try {
      final Map<String, List<double>> quick = <String, List<double>>{
        'tap': GoldSynth.tap(),
        'tick': GoldSynth.tick(),
        for (int i = 0; i < 10; i++) 'seal$i': GoldSynth.seal(i),
      };
      final Map<String, List<double>> big = <String, List<double>>{
        'reveal': GoldSynth.reveal(),
        'correct': GoldSynth.correct(),
        'golden': GoldSynth.golden(),
        'wrong': GoldSynth.wrong(),
        'timeout': GoldSynth.timeout(),
        'win': GoldSynth.finish(perfect: false, won: true),
        'perfect': GoldSynth.finish(perfect: true, won: true),
        'lose': GoldSynth.finish(perfect: false, won: false),
      };
      await Future.wait(<Future<void>>[
        _open(gen, 'quick', GoldSynth.bank(quick)),
        _open(gen, 'big', GoldSynth.bank(big)),
      ]);
    } catch (_) {}
  }

  Future<void> _open(int gen, String name, Bank bank) async {
    try {
      final Directory dir = await Directory(
        '${Directory.systemTemp.path}/gold_sound',
      ).create(recursive: true);
      final File f = File('${dir.path}/$name.wav');
      await f.writeAsBytes(bank.bytes, flush: true);
      final VideoPlayerController c = VideoPlayerController.file(
        f,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      await c.initialize();
      await c.setVolume(1);
      if (gen != _gen) {
        await c.dispose();
        return;
      }
      _decks[name] = _Deck(c, bank.spans);
    } catch (_) {}
  }

  Future<void> setOn(bool v) async {
    on.value = v;
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setBool(_key, v);
    } catch (_) {}
  }

  /// Plays a quick sound ('tap', 'tick', 'seal0' to 'seal9').
  void quick(String name) => _play('quick', name);

  /// Plays a big sound ('reveal', 'correct', 'golden', 'wrong',
  /// 'timeout', 'win', 'perfect', 'lose').
  void big(String name) => _play('big', name);

  void _play(String deck, String name) {
    if (!on.value) return;
    final _Deck? d = _decks[deck];
    final List<int>? span = d?.spans[name];
    if (d == null || span == null) return;
    d.stop?.cancel();
    d.c
        .seekTo(Duration(milliseconds: span[0]))
        .then((_) {
          d.c.play();
          d.stop = Timer(Duration(milliseconds: span[1]), () => d.c.pause());
        })
        .catchError((Object _) {});
  }

  /// Frees the players when the member leaves the quiz.
  Future<void> release() async {
    _loading = null;
    _gen++;
    final List<_Deck> all = _decks.values.toList();
    _decks.clear();
    for (final _Deck d in all) {
      d.stop?.cancel();
      try {
        await d.c.dispose();
      } catch (_) {}
    }
  }
}

class _Deck {
  _Deck(this.c, this.spans);

  final VideoPlayerController c;
  final Map<String, List<int>> spans;
  Timer? stop;
}

// END OF FILE - lib/widgets/gold_sound.dart
