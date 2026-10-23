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
/// video player plays them, so no new package). Each recording has
/// ONE place it belongs to, and nothing else plays there:
///   'bells'         bells                    opening the doorbell
///   'heartlit'      bell_heartlit_tap        Greet, Read, Join in, Open Line
///   'early_door'    early_door               the Early Door card
///   'private_line'  the_private_line_        the Private Line card
///   'ladder'        ladder                   the ladder icon in the top bar
///   'ivory_ladder'  the_ivory_ladder         the Marks on the Ivory Ladder page
///   'showcase'      your_showcase            the bell-set row and its sheet
///   'pinned_marks'  showcase_pinned_marks    the pinned Marks area
///   'treasure'      your_treasure            the Your Treasures card
///   'kickoff'       golden_kick_off          the Golden Knock-off
///   'notify'        in_app_notification      a new notice while the app is open
///   'ticker'        ticker                   each ribbon
///   'missed_you'    missed_you               the missed-you glass at open
///   'dream_ribbon'  dream_ribbon             a dream house ribbon crossing
/// There is NO everyday tap click any more. One member switch
/// (Profile, Showcase card) turns all of these off. If a file is
/// missing or cannot play, [play] answers false and the caller keeps
/// its older sound. Nothing here can throw or hang.
///
/// Speed: every player is opened a few seconds after the app starts
/// (two at a time, so the phone never stutters) and rewinds itself
/// when it finishes, so a tap only has to press play.
/// ============================================================
class SoundBank with WidgetsBindingObserver {
  SoundBank._();
  static final SoundBank instance = SoundBank._();

  static const String _prefKey = 'ivory_app_sounds_on';

  // A word starting with '=' must equal the whole file name.
  static const Map<String, List<String>> _words = <String, List<String>>{
    'bells': <String>['bells'],
    'heartlit': <String>['bell_heartlit_tap'],
    'early_door': <String>['early_door'],
    'private_line': <String>['the_private_line'],
    'ladder': <String>['=ladder.mp3'],
    'ivory_ladder': <String>['the_ivory_ladder'],
    'showcase': <String>['your_showcase'],
    'pinned_marks': <String>['showcase_pinned_marks'],
    'treasure': <String>['your_treasure'],
    'kickoff': <String>['golden_kick_off'],
    'notify': <String>['notif'],
    'ticker': <String>['ticker'],
    'missed_you': <String>['missed_you'],
    'dream_ribbon': <String>['dream_ribbon'],
  };

  /// The order they are made ready: the ones a member taps first.
  static const List<String> _warmOrder = <String>[
    'missed_you',
    'dream_ribbon',
    'private_line',
    'early_door',
    'ladder',
    'bells',
    'heartlit',
    'showcase',
    'pinned_marks',
    'treasure',
    'ivory_ladder',
    'kickoff',
    'notify',
    'ticker',
  ];
  static const List<String> _exts = <String>['.mp3', '.wav', '.ogg', '.m4a'];

  final ValueNotifier<bool> on = ValueNotifier<bool>(true);
  final Map<String, _Deck> _decks = <String, _Deck>{};
  bool _loaded = false;
  bool _hooked = false;
  bool _warming = false;

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

  /// Gets every player ready, two at a time, so the first tap is instant.
  Future<void> warm() async {
    if (_warming) return;
    _warming = true;
    try {
      await load();
      for (int i = 0; i < _warmOrder.length; i += 2) {
        final List<Future<bool>> batch = <Future<bool>>[];
        for (int j = i; j < i + 2 && j < _warmOrder.length; j++) {
          batch.add(_deck(_warmOrder[j]).ready);
        }
        await Future.wait<bool>(batch);
        await Future<void>.delayed(const Duration(milliseconds: 120));
      }
    } catch (_) {}
    _warming = false;
  }

  _Deck _deck(String id) {
    return _decks.putIfAbsent(
      id,
      () => _Deck(id, _words[id] ?? <String>[id], _exts),
    );
  }

  /// Plays [id]; true if a recording really played (or sound is off).
  Future<bool> play(String id, {double volume = 1.0}) async {
    if (!on.value) return true; // switched off: stay silent, no fallback
    try {
      final _Deck d = _deck(id);
      final bool ok = d.isReady ? true : await d.ready;
      if (!ok) return false;
      final VideoPlayerController c = d.player!;
      final VideoPlayerValue v = c.value;
      if (v.volume != volume) unawaited(c.setVolume(volume));
      if (v.isPlaying || v.position > const Duration(milliseconds: 120)) {
        await c.seekTo(Duration.zero);
      }
      unawaited(c.play());
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Stops one recording (for example when its screen is closed).
  void stop(String id) {
    final VideoPlayerController? c = _decks[id]?.player;
    if (c == null) return;
    try {
      c.pause();
      c.seekTo(Duration.zero);
    } catch (_) {}
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
  _Deck(this.id, this.words, this.exts);

  final String id;
  final List<String> words;
  final List<String> exts;
  VideoPlayerController? player;
  Future<bool>? _ready;
  DateTime _failedAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _rewinding = false;

  bool get isReady => player != null && player!.value.isInitialized;

  Future<bool> get ready {
    final Future<bool>? r = _ready;
    if (r != null) {
      // A failed start may be tried again, but not more than every 20 s.
      if (player == null &&
          _failedAt.millisecondsSinceEpoch > 0 &&
          DateTime.now().difference(_failedAt).inSeconds > 20) {
        _ready = null;
      } else {
        return r;
      }
    }
    return _ready ??= _init();
  }

  Future<bool> _init() async {
    try {
      final String? path = await PremiumAssets.find(id, words, exts);
      if (path == null) {
        _failedAt = DateTime.now();
        return false;
      }
      final VideoPlayerController c = VideoPlayerController.asset(
        path,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      await c.initialize().timeout(const Duration(seconds: 8));
      // When the recording ends it rewinds itself, ready for the next tap.
      c.addListener(() => _onTick(c));
      player = c;
      return true;
    } catch (_) {
      _failedAt = DateTime.now();
      return false;
    }
  }

  void _onTick(VideoPlayerController c) {
    final VideoPlayerValue v = c.value;
    if (_rewinding || !v.isInitialized || v.isPlaying) return;
    if (v.duration <= Duration.zero) return;
    if (v.position >= v.duration - const Duration(milliseconds: 80)) {
      _rewinding = true;
      c.seekTo(Duration.zero).whenComplete(() => _rewinding = false);
    }
  }
}

// END OF FILE - lib/widgets/sound_bank.dart
