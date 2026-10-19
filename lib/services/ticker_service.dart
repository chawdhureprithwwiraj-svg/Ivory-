import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/l10n.dart';
import '../screens/bells_screen.dart';
import '../screens/ladder_screen.dart';
import '../screens/main_shell.dart';
import '../widgets/ticker_sound.dart';

/// ============================================================
/// IVORY - THE IVORY TICKER (the service behind the ribbons)
///
/// A slim ribbon glides across the top of the screen, now and then,
/// to celebrate something real a member has earned. Every ribbon is
/// built from a REAL event the database reports (nothing is made up
/// and nothing is simulated). Every ribbon reads the same way for
/// everyone: a member's own moments appear in the very same public
/// wording as anyone else's, a few minutes apart, so it all looks like
/// the quiet activity of a busy house.
///
/// Rhythm: one ribbon about every 30 seconds (the house can change
/// it), none in the first 20 seconds, never the same colour twice in
/// a row, never the same member within the last two ribbons, nothing
/// repeated while there is something new, and silence when there is
/// nothing true to say. One quiet call to the database every five
/// minutes; no live connection. A member who switched their
/// Showcase off is never named, to themselves or to anyone.
/// ============================================================

/// The app's navigator, so a tap on a ribbon can open a screen from
/// above the navigator (the ribbon lives outside it).
class TickerNav {
  TickerNav._();
  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();
}

class TickerSettings {
  const TickerSettings({
    this.on = false,
    this.gap = 30,
    this.ownMin = 5,
    this.ownMax = 10,
    this.cross = 10,
    this.grand = 13,
    this.startDelay = 20,
    this.laneOffset = 0,
    this.coloursOff = const <int>[],
  });

  final bool on;
  final int gap;
  final int ownMin;
  final int ownMax;
  final int cross;
  final int grand;
  final int startDelay;
  final int laneOffset;
  final List<int> coloursOff;

  static int _i(dynamic v, int d) => v is num ? v.toInt() : d;

  factory TickerSettings.fromMap(Map<String, dynamic> m) {
    final dynamic c = m['colours_off'];
    return TickerSettings(
      on: true,
      gap: _i(m['gap_seconds'], 30),
      ownMin: _i(m['own_min_minutes'], 5),
      ownMax: _i(m['own_max_minutes'], 10),
      cross: _i(m['cross_seconds'], 10),
      grand: _i(m['grand_seconds'], 13),
      startDelay: _i(m['start_delay_seconds'], 20),
      laneOffset: _i(m['lane_offset'], 0),
      coloursOff: c is List
          ? c.map((dynamic e) => _i(e, 0)).toList()
          : const <int>[],
    );
  }
}

class TickerEvent {
  const TickerEvent({
    required this.id,
    required this.kind,
    required this.at,
    this.actor,
    this.name,
    this.n,
    this.thing,
    this.extra,
    this.grand = false,
    this.colour,
    this.ref,
  });

  final String id;
  final String kind;
  final DateTime at;
  final String? actor;
  final String? name;
  final int? n;
  final String? thing;
  final String? extra;
  final bool grand;
  final int? colour;
  final String? ref;

  static String? _s(dynamic v) => v == null ? null : '$v';

  factory TickerEvent.fromMap(Map<String, dynamic> m) => TickerEvent(
    id: '${m['id']}',
    kind: '${m['kind']}',
    at: DateTime.tryParse('${m['at']}') ?? DateTime.now(),
    actor: _s(m['actor']),
    name: _s(m['name']),
    n: m['n'] is num ? (m['n'] as num).toInt() : null,
    thing: _s(m['thing']),
    extra: _s(m['extra']),
    grand: m['grand'] == true,
    colour: m['colour'] is num ? (m['colour'] as num).toInt() : null,
    ref: _s(m['ref']),
  );
}

/// One ribbon, ready to cross the screen.
class TickerShow {
  const TickerShow({
    required this.event,
    required this.label,
    required this.text,
    required this.palette,
    required this.seconds,
    required this.seed,
  });

  final TickerEvent event;
  final String label;
  final String text;
  final int palette;
  final int seconds;
  final int seed;

  bool get grand => event.grand;
}

class TickerService {
  TickerService._();
  static final TickerService instance = TickerService._();

  static const String _kRibbons = 'ticker_ribbons_on';

  /// The ribbon on its way across right now, or null.
  final ValueNotifier<TickerShow?> current = ValueNotifier<TickerShow?>(null);

  /// The member's own choice, on this phone: show the ribbons at all.
  final ValueNotifier<bool> showRibbons = ValueNotifier<bool>(true);
  final ValueNotifier<bool> signedIn = ValueNotifier<bool>(false);

  /// Set by the lane while a screen asks for quiet (live room, calls,
  /// full-screen films, the keyboard). Nothing new starts meanwhile.
  final ValueNotifier<bool> blocked = ValueNotifier<bool>(false);

  TickerSettings _settings = const TickerSettings();
  TickerSettings get settings => _settings;
  Map<String, Map<String, String>> _kinds = <String, Map<String, String>>{};
  List<TickerEvent> _events = <TickerEvent>[];
  final Map<String, DateTime> _played = <String, DateTime>{};
  final List<String> _recentActors = <String>[];
  int _lastPalette = -1;
  DateTime? _began;
  DateTime? _lastEnd;
  DateTime? _lastOwn;
  int _ownGapSecs = 450;
  Timer? _pullTimer;
  Timer? _tickTimer;
  StreamSubscription<AuthState>? _auth;
  bool _started = false;
  final math.Random _rng = math.Random();

  SupabaseClient get _db => Supabase.instance.client;

  /// Called once, when the lane is first built. Safe to call again.
  void start() {
    if (_started) return;
    _started = true;
    unawaited(_readPrefs());
    unawaited(TickerSound.instance.load());
    try {
      _auth = _db.auth.onAuthStateChange.listen(
        (AuthState s) => _sync(s.session != null),
        onError: (Object _) {},
      );
      _sync(_db.auth.currentSession != null);
    } catch (_) {}
  }

  Future<void> _readPrefs() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      showRibbons.value = p.getBool(_kRibbons) ?? true;
    } catch (_) {}
  }

  Future<void> setRibbons(bool v) async {
    showRibbons.value = v;
    if (!v) current.value = null;
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setBool(_kRibbons, v);
    } catch (_) {}
  }

  void _sync(bool inNow) {
    if (inNow && !signedIn.value) {
      signedIn.value = true;
      _begin();
    } else if (!inNow && signedIn.value) {
      signedIn.value = false;
      _end();
    }
  }

  void _begin() {
    _began = DateTime.now();
    _lastEnd = null;
    _lastOwn = _began;
    _rollOwnGap();
    _played.clear();
    _recentActors.clear();
    _pullTimer?.cancel();
    _tickTimer?.cancel();
    unawaited(pull());
    _pullTimer = Timer.periodic(
      const Duration(minutes: 5),
      (Timer _) => unawaited(pull()),
    );
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (Timer _) => _tick());
  }

  void _end() {
    _pullTimer?.cancel();
    _tickTimer?.cancel();
    _events = <TickerEvent>[];
    current.value = null;
  }

  void _rollOwnGap() {
    final int lo = _settings.ownMin.clamp(1, 240);
    final int hi = math.max(lo, _settings.ownMax);
    _ownGapSecs = (lo * 60) + _rng.nextInt(((hi - lo) * 60) + 1);
  }

  /// One quiet call. Failing is fine: the ribbons simply wait.
  Future<void> pull() async {
    try {
      final dynamic r = await _db.rpc('ticker_pull');
      if (r is! Map) return;
      final Map<String, dynamic> m = Map<String, dynamic>.from(r);
      if (m['on'] != true) {
        _settings = const TickerSettings();
        _events = <TickerEvent>[];
        return;
      }
      _settings = TickerSettings.fromMap(
        Map<String, dynamic>.from(m['settings'] as Map),
      );
      final Map<String, Map<String, String>> kinds =
          <String, Map<String, String>>{};
      if (m['kinds'] is Map) {
        (m['kinds'] as Map).forEach((dynamic k, dynamic v) {
          if (v is Map) {
            kinds['$k'] = <String, String>{
              'label': '${v['label'] ?? ''}',
              'template': '${v['template'] ?? '{thing}'}',
            };
          }
        });
      }
      _kinds = kinds;
      final List<TickerEvent> list = <TickerEvent>[];
      if (m['events'] is List) {
        for (final dynamic e in m['events'] as List) {
          if (e is Map) {
            list.add(TickerEvent.fromMap(Map<String, dynamic>.from(e)));
          }
        }
      }
      _events = list;
    } catch (_) {}
  }

  void _tick() {
    if (!signedIn.value || !showRibbons.value) return;
    if (blocked.value || current.value != null) return;
    final TickerSettings s = _settings;
    if (!s.on || _events.isEmpty || _began == null) return;
    final DateTime now = DateTime.now();
    if (now.difference(_began!).inSeconds < s.startDelay) return;
    if (_lastEnd != null && now.difference(_lastEnd!).inSeconds < s.gap) return;
    final TickerEvent? e = _choose(now);
    if (e == null) return;
    _present(e, now);
  }

  TickerEvent? _choose(DateTime now) {
    final String? me = _db.auth.currentUser?.id;
    final bool ownDue =
        _lastOwn != null && now.difference(_lastOwn!).inSeconds >= _ownGapSecs;
    for (final bool recycle in <bool>[false, true]) {
      final List<TickerEvent> ok = _events.where((TickerEvent e) {
        if (!_kinds.containsKey(e.kind)) return false;
        final DateTime? p = _played[e.id];
        if (recycle) {
          // Only recent real events (or the house's own notes) come round
          // again, and not within half an hour of last time.
          if (p == null || now.difference(p).inMinutes < 30) return false;
          if (e.kind != 'note' && now.difference(e.at).inHours >= 12) {
            return false;
          }
        } else if (p != null) {
          return false;
        }
        if (e.actor != null && _recentActors.contains(e.actor)) return false;
        return true;
      }).toList();
      if (ok.isEmpty) continue;
      final List<TickerEvent> mine = me == null
          ? <TickerEvent>[]
          : ok.where((TickerEvent e) => e.actor == me).toList();
      final List<TickerEvent> others = ok
          .where((TickerEvent e) => me == null || e.actor != me)
          .toList();
      List<TickerEvent> pool;
      bool own = false;
      if (ownDue && mine.isNotEmpty) {
        pool = mine;
        own = true;
      } else {
        pool = others;
      }
      if (pool.isEmpty) continue;
      final List<TickerEvent> grands =
          pool.where((TickerEvent e) => e.grand).toList();
      if (grands.isNotEmpty && _rng.nextDouble() < 0.5) pool = grands;
      pool.sort((TickerEvent a, TickerEvent b) => b.at.compareTo(a.at));
      final int top = math.min(6, pool.length);
      final TickerEvent pick = pool[_rng.nextInt(top)];
      if (own) {
        _lastOwn = now;
        _rollOwnGap();
      }
      return pick;
    }
    return null;
  }

  static String _cut(String? v, int max) {
    final String t = (v ?? '').trim();
    if (t.length <= max) return t;
    return '${t.substring(0, max - 1).trimRight()}…';
  }

  int _pickPalette(TickerEvent e) {
    final int? forced = e.colour;
    if (forced != null && forced >= 1 && forced <= 10) {
      return forced - 1;
    }
    final List<int> open = <int>[
      for (int i = 0; i < 10; i++)
        if (!_settings.coloursOff.contains(i + 1)) i,
    ];
    if (open.isEmpty) return _rng.nextInt(10);
    final List<int> pool = open.length > 1
        ? open.where((int i) => i != _lastPalette).toList()
        : open;
    return pool[_rng.nextInt(pool.length)];
  }

  void _present(TickerEvent e, DateTime now) {
    final Map<String, String> k =
        _kinds[e.kind] ?? <String, String>{'label': '', 'template': '{thing}'};
    final String name = (e.name == null || e.name!.trim().isEmpty)
        ? 'A member'.tr
        : _cut(e.name, 18);
    final String text = (k['template'] ?? '{thing}').tr
        .replaceAll('{name}', name)
        .replaceAll('{thing}', _cut(e.thing, 34))
        .replaceAll('{extra}', _cut(e.extra, 34))
        .replaceAll('{n}', e.n == null ? '' : '${e.n}');
    final int pal = _pickPalette(e);
    final TickerShow show = TickerShow(
      event: e,
      label: k['label'] ?? '',
      text: text,
      palette: pal,
      seconds: e.grand ? _settings.grand : _settings.cross,
      seed: _rng.nextInt(1 << 30),
    );
    _played[e.id] = now;
    if (e.actor != null) {
      _recentActors.add(e.actor!);
      while (_recentActors.length > 2) {
        _recentActors.removeAt(0);
      }
    }
    _lastPalette = pal;
    TickerSound.instance.play(e.grand ? 'grand' : 'soft');
    current.value = show;
  }

  /// The lane calls this when the last letter has gone.
  void finish(TickerShow? s) {
    if (s != null && identical(current.value, s)) {
      current.value = null;
    }
    _lastEnd = DateTime.now();
  }

  /// A tap on a ribbon opens the place it is about.
  void open(TickerShow s) {
    final NavigatorState? nav = TickerNav.key.currentState;
    if (nav == null) return;
    TickerSound.instance.play('tap');
    void tab(String t) {
      nav.popUntil((Route<dynamic> r) => r.isFirst);
      MainShell.onOpenTab?.call(t);
    }

    void ladder() => nav.push<void>(
      MaterialPageRoute<void>(builder: (_) => const LadderScreen()),
    );
    void bells() => nav.push<void>(
      MaterialPageRoute<void>(
        builder: (_) => BellsScreen(onOpenTab: tab),
      ),
    );

    switch (s.event.kind) {
      case 'mark':
      case 'rung':
      case 'glow':
      case 'peal':
        ladder();
        break;
      case 'fullday':
      case 'bellset':
      case 'pledge':
        bells();
        break;
      case 'treasure':
      case 'treasure_gift':
        tab('profile');
        break;
      case 'post':
        tab('explore');
        break;
      case 'knockoff10':
      case 'live':
      case 'gift_live':
      case 'welcome':
        tab('home');
        break;
      case 'gift':
        tab('explore');
        break;
      case 'note':
        final String r = s.event.ref ?? '';
        if (r == 'ladder') {
          ladder();
        } else if (r == 'bells') {
          bells();
        } else if (r.isNotEmpty) {
          tab(r);
        }
        break;
      default:
        break;
    }
  }
}

// END OF FILE - lib/services/ticker_service.dart
