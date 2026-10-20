import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import 'premium_assets.dart';

/// ============================================================
/// IVORY - THE SOUND BANK
///
/// Plays the owner's own recordings from `assets/premium/` (the app's
/// video player plays them, so no new package):
///   'click'        every_clicks      every ordinary tap
///   'bells'        bells             opening the doorbell
///   'early_door'   early_door        the Early Door
///   'private_line' private_line      the Private Line
///   'kickoff'      golden_kick_off   the Golden Knock-off
///   'notify'       in_app_notif...   a new notice while the app is open
///   'ticker'       ticker            each ribbon
/// A card that plays its own sound calls [quiet] first (or just plays),
/// so the everyday click never doubles over it. One member switch
/// (Profile, Showcase card) turns all of these off. If a file is
/// missing or cannot play, [play] answers false and the caller keeps
/// its older sound. Nothing here can throw.
/// ============================================================
class SoundBank with WidgetsBindingObserver {
  SoundBank._();
  static final SoundBank instance = SoundBank._();

  static const String _prefKey = 'ivory_app_sounds_on';

  /// How loud an everyday tap is (0 to 1). Change this ONE number.
  static const double clickVolume = 0.7;

  static const Map<String, List<String>> _words = <String, List<String>>{
    'click': <String>['every_click'],
    'bells': <String>['bells'],
    'early_door': <String>['early_door'],
    'private_line': <String>['private_line'],
    'kickoff': <String>['golden_kick_off'],
    'notify': <String>['notif'],
    'ticker': <String>['ticker'],
  };
  static const List<String> _exts = <String>['.mp3', '.wav', '.ogg', '.m4a'];

  final ValueNotifier<bool> on = ValueNotifier<bool>(true);
  final Map<String, _Deck> _decks = <String, _Deck>{};
  DateTime _quietUntil = DateTime.fromMillisecondsSinceEpoch(0);
  bool _loaded = false;
  bool _hooked = false;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      on.value = p.getBool(_prefKey) ?? true;
    } catch (_) {}
    if (!_hooked) {
      _hooked = true;
      WidgetsBinding.instance.addObserver(this);
    }
  }

  Future<void> setOn(bool v) async {
    on.value = v;
    if (!v) stopAll();
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setBool(_prefKey, v);
    } catch (_) {}
  }

  /// Gets every player ready a moment after the app opens, one by one,
  /// so the first tap is instant.
  Future<void> warm() async {
    await load();
    for (final String id in _words.keys) {
      await _deck(id).ready;
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
  }

  _Deck _deck(String id) {
    return _decks.putIfAbsent(
      id,
      () => _Deck(id, _words[id] ?? <String>[id], _exts, id == 'click' ? 3 : 1),
    );
  }

  /// Asks the everyday click to stay silent for a moment: a card with
  /// its own sound calls this.
  void quiet([int ms = 500]) {
    _quietUntil = DateTime.now().add(Duration(milliseconds: ms));
  }

  bool get _isQuiet => DateTime.now().isBefore(_quietUntil);

  /// The everyday tap sound (skipped when a card has a sound of its own).
  void click() {
    if (!on.value || _isQuiet) return;
    unawaited(_play('click', clickVolume));
  }

  /// Plays [id]; true if a recording really played.
  Future<bool> play(String id, {double volume = 1.0}) async {
    if (!on.value) return true; // switched off: stay silent, no fallback
    quiet();
    return _play(id, volume);
  }

  Future<bool> _play(String id, double volume) async {
    try {
      final _Deck d = _deck(id);
      final bool ok = await d.ready;
      if (!ok) return false;
      final VideoPlayerController c = d.next();
      await c.setVolume(volume);
      await c.seekTo(Duration.zero);
      await c.play();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Stops one recording (for example when its sheet is closed).
  void stop(String id) {
    final _Deck? d = _decks[id];
    if (d == null) return;
    for (final VideoPlayerController c in d.players) {
      try {
        c.pause();
        c.seekTo(Duration.zero);
      } catch (_) {}
    }
  }

  void stopAll() {
    for (final String id in _decks.keys.toList()) {
      stop(id);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s != AppLifecycleState.resumed) stopAll();
  }
}

class _Deck {
  _Deck(this.id, this.words, this.exts, this.size);

  final String id;
  final List<String> words;
  final List<String> exts;
  final int size;
  final List<VideoPlayerController> players = <VideoPlayerController>[];
  int _i = 0;
  Future<bool>? _ready;

  Future<bool> get ready => _ready ??= _init();

  Future<bool> _init() async {
    try {
      final String? path = await PremiumAssets.find(id, words, exts);
      if (path == null) return false;
      for (int i = 0; i < size; i++) {
        final VideoPlayerController c = VideoPlayerController.asset(
          path,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
        await c.initialize();
        players.add(c);
      }
      return players.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  VideoPlayerController next() {
    final VideoPlayerController c = players[_i % players.length];
    _i++;
    return c;
  }
}

// END OF FILE - lib/widgets/sound_bank.dart
