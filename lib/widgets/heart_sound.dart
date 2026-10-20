import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import 'gold_synth.dart';
import 'heart_synth.dart';

Bank _makeHeartBank(int _) => HeartSynth.build();

/// ============================================================
/// IVORY - THE GOLDEN HEART'S SOUND DESK
///
/// Plays what HeartSynth builds, the same way the doorbell and the
/// ribbons do: the app's video player plays a small WAV file from the
/// cache folder (no new package). The sounds mix with whatever else
/// the phone is playing. They are on until the member switches them
/// off (Profile, Showcase card). If anything fails it stays silent.
/// ============================================================
class HeartSound {
  HeartSound._();
  static final HeartSound instance = HeartSound._();

  static const String _key = 'heart_sound_on';

  final ValueNotifier<bool> on = ValueNotifier<bool>(true);
  final List<_HeartDeck> _players = <_HeartDeck>[];
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
      final Bank bank = await compute(_makeHeartBank, 0);
      final Directory dir = await Directory(
        '${Directory.systemTemp.path}/heart_sound',
      ).create(recursive: true);
      final File f = File('${dir.path}/heart.wav');
      await f.writeAsBytes(bank.bytes, flush: true);
      final List<_HeartDeck> made = <_HeartDeck>[];
      for (int i = 0; i < 2; i++) {
        final VideoPlayerController c = VideoPlayerController.file(
          f,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
        await c.initialize();
        await c.setVolume(0.8);
        made.add(_HeartDeck(c));
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

  /// 'kindle', 'open' or 'rain'. Returns true if it began to play.
  bool play(String name, {double volume = 0.8}) {
    if (!on.value || _players.isEmpty) return false;
    final List<int>? span = _spans[name];
    if (span == null) return false;
    final _HeartDeck d = _players[_next % _players.length];
    _next++;
    d.stop?.cancel();
    d.c
        .setVolume(volume)
        .then((_) => d.c.seekTo(Duration(milliseconds: span[0])))
        .then((_) {
          d.c.play();
          d.stop = Timer(Duration(milliseconds: span[1]), () => d.c.pause());
        })
        .catchError((Object _) {});
    return true;
  }
}

class _HeartDeck {
  _HeartDeck(this.c);

  final VideoPlayerController c;
  Timer? stop;
}

// END OF FILE - lib/widgets/heart_sound.dart
