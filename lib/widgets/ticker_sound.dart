import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import 'gold_synth.dart';
import 'sound_bank.dart';
import 'ticker_synth.dart';

Bank _makeTickerBank(int _) => TickerSynth.build();

/// ============================================================
/// IVORY - THE TICKER'S SOUND DESK
///
/// Plays what TickerSynth builds, the same way the doorbell does: the
/// app's video player plays a small WAV file from the cache folder
/// (no new package). The chimes are soft and mix with whatever else
/// the phone is playing. Sound is on until the member switches it off
/// (Profile, Showcase card). If anything fails it stays silent.
/// ============================================================
class TickerSound {
  TickerSound._();
  static final TickerSound instance = TickerSound._();

  static const String _key = 'ticker_sound_on';

  final ValueNotifier<bool> on = ValueNotifier<bool>(true);
  final List<_TickerDeck> _players = <_TickerDeck>[];
  Map<String, List<int>> _spans = <String, List<int>>{};
  Future<void>? _loading;
  int _next = 0;

  /// Reads the member's choice and builds the sounds. Runs once.
  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      on.value = p.getBool(_key) ?? true;
    } catch (_) {}
    if (!on.value) {
      // Built later, if the member switches it on.
      _loading = null;
      return;
    }
    try {
      final Bank bank = await compute(_makeTickerBank, 0);
      final Directory dir = await Directory(
        '${Directory.systemTemp.path}/ticker_sound',
      ).create(recursive: true);
      final File f = File('${dir.path}/ticker.wav');
      await f.writeAsBytes(bank.bytes, flush: true);
      final List<_TickerDeck> made = <_TickerDeck>[];
      for (int i = 0; i < 2; i++) {
        final VideoPlayerController c = VideoPlayerController.file(
          f,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
        await c.initialize();
        await c.setVolume(0.7);
        made.add(_TickerDeck(c));
      }
      _spans = bank.spans;
      _players.addAll(made);
    } catch (_) {}
  }

  Future<void> setOn(bool v) async {
    on.value = v;
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setBool(_key, v);
    } catch (_) {}
    if (v && _players.isEmpty) {
      _loading = null;
      unawaited(load());
    }
  }

  /// 'soft', 'grand' or 'tap'.
  void play(String name) {
    if (!on.value) return;
    // The owner's own recordings first; the old chimes are the fallback.
    if (name == 'soft' || name == 'grand') {
      SoundBank.instance.play('ticker', volume: 0.85).then((bool ok) {
        if (!ok) _chime(name);
      });
      return;
    }
    if (name == 'tap') {
      SoundBank.instance.play('click', volume: 0.8).then((bool ok) {
        if (!ok) _chime(name);
      });
      return;
    }
    _chime(name);
  }

  void _chime(String name) {
    if (_players.isEmpty) return;
    final List<int>? span = _spans[name];
    if (span == null) return;
    final _TickerDeck d = _players[_next % _players.length];
    _next++;
    d.stop?.cancel();
    d.c
        .seekTo(Duration(milliseconds: span[0]))
        .then((_) {
          d.c.play();
          d.stop = Timer(Duration(milliseconds: span[1]), () => d.c.pause());
        })
        .catchError((Object _) {});
  }
}

class _TickerDeck {
  _TickerDeck(this.c);

  final VideoPlayerController c;
  Timer? stop;
}

// END OF FILE - lib/widgets/ticker_sound.dart
