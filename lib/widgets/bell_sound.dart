import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import 'bell_synth.dart';
import 'gold_synth.dart';

Bank _makeBellBank(int _) => BellSynth.build();

/// ============================================================
/// IVORY - THE DOORBELL'S SOUND DESK
///
/// Plays what BellSynth builds. The app already carries the video
/// player, which plays any WAV file, so no new package is added. The
/// sounds are built once on a background thread, written into the
/// app's cache folder and played from there. Three players share the
/// same file so a new bell can ring while the last one is still
/// fading, the way real bells overlap. Sound is on unless the member
/// switches it off. If anything fails it stays silent: sound is a
/// pleasure here, never a requirement.
/// ============================================================
class BellSound {
  BellSound._();
  static final BellSound instance = BellSound._();

  static const String _key = 'bell_sound_on';
  static const int _decks = 3;

  final ValueNotifier<bool> on = ValueNotifier<bool>(true);
  final List<_BellDeck> _players = <_BellDeck>[];
  Map<String, List<int>> _spans = <String, List<int>>{};
  Future<void>? _loading;
  int _gen = 0;
  int _next = 0;

  /// Builds and opens the sounds. Safe to call again; runs once.
  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    final int gen = _gen;
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      on.value = p.getBool(_key) ?? true;
    } catch (_) {}
    try {
      final Bank bank = await compute(_makeBellBank, 0);
      if (gen != _gen) return;
      final Directory dir = await Directory(
        '${Directory.systemTemp.path}/bell_sound',
      ).create(recursive: true);
      final File f = File('${dir.path}/doorbell.wav');
      await f.writeAsBytes(bank.bytes, flush: true);
      final List<_BellDeck> made = <_BellDeck>[];
      for (int i = 0; i < _decks; i++) {
        final VideoPlayerController c = VideoPlayerController.file(
          f,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
        await c.initialize();
        await c.setVolume(1);
        made.add(_BellDeck(c));
      }
      if (gen != _gen) {
        for (final _BellDeck d in made) {
          await d.c.dispose();
        }
        return;
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
  }

  /// 'ring0'..'ring3', 'door', 'full', 'tap' or 'line'.
  void play(String name) {
    if (!on.value || _players.isEmpty) return;
    final List<int>? span = _spans[name];
    if (span == null) return;
    final _BellDeck d = _players[_next % _players.length];
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

  /// Frees the players when the member leaves the doorbell.
  Future<void> release() async {
    _loading = null;
    _gen++;
    final List<_BellDeck> all = List<_BellDeck>.from(_players);
    _players.clear();
    for (final _BellDeck d in all) {
      d.stop?.cancel();
      try {
        await d.c.dispose();
      } catch (_) {}
    }
  }
}

class _BellDeck {
  _BellDeck(this.c);

  final VideoPlayerController c;
  Timer? stop;
}

// END OF FILE - lib/widgets/bell_sound.dart
