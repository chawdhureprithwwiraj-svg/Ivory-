import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ============================================================
/// IVORY - THE EARLY DOOR, THE ONLY DOOR TO THE DATABASE
///
/// A story can be held for early readers. Paid members read it at
/// once; other members read it a number of hours early depending on
/// their rung on the Ivory Ladder, while their Golden Heart is lit.
/// The database decides everything; this service only asks and
/// remembers the last answer in [state] so the Home card, the sheet
/// and the tap on a held story all agree. Quiet calls never throw:
/// nothing here can stop the app from working.
/// ============================================================

/// One rung's early window, as the house set it.
class EarlyWindow {
  const EarlyWindow({
    required this.rung,
    required this.name,
    required this.hours,
  });

  final int rung;
  final String name;
  final int hours;

  factory EarlyWindow.fromMap(Map<String, dynamic> m) => EarlyWindow(
    rung: (m['rung'] as num?)?.toInt() ?? 1,
    name: '${m['name'] ?? ''}',
    hours: (m['hours'] as num?)?.toInt() ?? 0,
  );
}

/// A story that is held for early readers right now.
class EarlyPost {
  const EarlyPost({
    required this.id,
    required this.title,
    required this.type,
    required this.publicAt,
    required this.opensAt,
    required this.canOpen,
  });

  final int id;
  final String title;
  final String type;

  /// When everyone can read it.
  final DateTime publicAt;

  /// When THIS member can read it.
  final DateTime opensAt;
  final bool canOpen;

  factory EarlyPost.fromMap(Map<String, dynamic> m) {
    final DateTime now = DateTime.now();
    return EarlyPost(
      id: (m['post_id'] as num?)?.toInt() ?? 0,
      title: '${m['title'] ?? ''}',
      type: '${m['type'] ?? ''}',
      publicAt: DateTime.tryParse('${m['public_at']}')?.toLocal() ?? now,
      opensAt: DateTime.tryParse('${m['opens_at']}')?.toLocal() ?? now,
      canOpen: m['can_open'] == true,
    );
  }
}

/// What the database says about this member's door.
class EarlyState {
  const EarlyState({
    required this.enabled,
    required this.paid,
    required this.warm,
    required this.rung,
    required this.rungName,
    required this.hours,
    required this.rungHours,
    required this.warmDays,
    required this.callExtraDays,
    required this.pushOn,
    required this.reads,
    required this.windows,
    required this.posts,
  });

  final bool enabled;
  final bool paid;

  /// The Golden Heart was lit in the last [warmDays] days.
  final bool warm;
  final int rung;
  final String rungName;

  /// Hours this member reads ahead right now (100000 = the whole period).
  final int hours;

  /// Hours the member's rung would give while the heart is lit.
  final int rungHours;
  final int warmDays;
  final int callExtraDays;
  final bool pushOn;
  final int reads;
  final List<EarlyWindow> windows;
  final List<EarlyPost> posts;

  bool get isOpen => hours > 0;

  /// The next rung that gives early reading, if the member has none yet.
  EarlyWindow? get nextWindow {
    for (final EarlyWindow w in windows) {
      if (w.rung > rung && w.hours > 0) return w;
    }
    return null;
  }

  /// The most useful reading hint for the Home card.
  int get waiting => posts.where((EarlyPost p) => p.canOpen).length;

  factory EarlyState.fromMap(Map<String, dynamic> m) {
    List<Map<String, dynamic>> list(dynamic v) => v is List
        ? v.map((dynamic e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];
    return EarlyState(
      enabled: m['open'] == true,
      paid: m['paid'] == true,
      warm: m['warm'] == true,
      rung: (m['rung'] as num?)?.toInt() ?? 1,
      rungName: '${m['rung_name'] ?? ''}',
      hours: (m['hours'] as num?)?.toInt() ?? 0,
      rungHours: (m['rung_hours'] as num?)?.toInt() ?? 0,
      warmDays: (m['warm_days'] as num?)?.toInt() ?? 3,
      callExtraDays: (m['call_extra_days'] as num?)?.toInt() ?? 0,
      pushOn: m['push_on'] != false,
      reads: (m['reads'] as num?)?.toInt() ?? 0,
      windows: list(m['windows']).map(EarlyWindow.fromMap).toList(),
      posts: list(m['posts']).map(EarlyPost.fromMap).toList(),
    );
  }
}

class EarlyService {
  EarlyService._();
  static final EarlyService instance = EarlyService._();

  SupabaseClient get _db => Supabase.instance.client;

  /// The latest answer, or null before the first one (or when the
  /// Early Door is switched off).
  final ValueNotifier<EarlyState?> state = ValueNotifier<EarlyState?>(null);

  DateTime? _askedAt;
  Future<EarlyState?>? _inflight;

  Map<String, dynamic> _map(dynamic v) => Map<String, dynamic>.from(v as Map);

  /// Asks the database. Never throws. Answers asked within 20 seconds
  /// are reused unless [force] is true.
  Future<EarlyState?> refresh({bool force = false}) {
    final DateTime? at = _askedAt;
    if (!force &&
        at != null &&
        DateTime.now().difference(at).inSeconds < 20 &&
        state.value != null) {
      return Future<EarlyState?>.value(state.value);
    }
    return _inflight ??= _ask().whenComplete(() => _inflight = null);
  }

  Future<EarlyState?> _ask() async {
    try {
      final dynamic r = await _db.rpc('early_state');
      final EarlyState s = EarlyState.fromMap(_map(r));
      _askedAt = DateTime.now();
      state.value = s.enabled ? s : null;
      return state.value;
    } catch (_) {
      return state.value;
    }
  }

  /// The member opened a story. Counted only if it was still early.
  /// Skipped quietly when the last answer shows the story is not held.
  Future<void> noteRead(int postId) async {
    try {
      final EarlyState? s = state.value;
      if (s != null && !s.posts.any((EarlyPost p) => p.id == postId)) return;
      final dynamic counted = await _db.rpc(
        'early_note_read',
        params: <String, dynamic>{'post_id_in': postId},
      );
      if (counted == true) await refresh(force: true);
    } catch (_) {}
  }

  /// The member's switch for the "early story" notification.
  Future<void> setPush(bool on) async {
    await _db.rpc('early_set_push', params: <String, dynamic>{'on_in': on});
    await refresh(force: true);
  }

  /// The held story with this id, using a fresh answer.
  Future<EarlyPost?> heldPost(int postId) async {
    final EarlyState? s = await refresh(force: true);
    if (s == null) return null;
    for (final EarlyPost p in s.posts) {
      if (p.id == postId) return p;
    }
    return null;
  }

  // ---------------------------------------------------------------
  // The house (Admin). These throw, so the screen can say why.
  // ---------------------------------------------------------------

  Future<Map<String, dynamic>> adminState() async {
    final dynamic r = await _db.rpc('early_admin_state');
    return _map(r);
  }

  Future<void> adminSave({
    required bool open,
    required int defaultHours,
    required int warmDays,
    required bool paidFull,
    required int callExtraDays,
    required bool pushOn,
  }) async {
    await _db.rpc(
      'early_admin_save',
      params: <String, dynamic>{
        'open_in': open,
        'default_hours_in': defaultHours,
        'warm_in': warmDays,
        'paid_full_in': paidFull,
        'extra_in': callExtraDays,
        'push_in': pushOn,
      },
    );
    state.value = null;
    _askedAt = null;
  }

  Future<void> adminWindow(int rung, int hours) async {
    await _db.rpc(
      'early_admin_window',
      params: <String, dynamic>{'rung_in': rung, 'hours_in': hours},
    );
  }

  /// Hold a story for [hours] from now; 0 opens it to everyone now.
  Future<String> adminSetPost(int postId, int hours) async {
    final dynamic r = await _db.rpc(
      'early_admin_set_post',
      params: <String, dynamic>{'post_in': postId, 'hours_in': hours},
    );
    return '$r';
  }
}

/// "3 hours", "a day", "2 days": early time in plain words.
String earlyHoursText(int hours) {
  if (hours >= 100000) return 'the whole early period';
  if (hours <= 0) return 'no time';
  if (hours == 1) return '1 hour';
  if (hours < 24) return '$hours hours';
  if (hours % 24 == 0) {
    final int d = hours ~/ 24;
    return d == 1 ? 'a day' : '$d days';
  }
  return '$hours hours';
}

/// "in 3h 12m", "in 2d 4h", "any moment now".
String earlyCountdown(DateTime to) {
  final Duration d = to.difference(DateTime.now());
  if (d.inSeconds <= 30) return 'any moment now';
  if (d.inHours >= 48) return 'in ${d.inDays}d ${d.inHours % 24}h';
  if (d.inHours >= 1) return 'in ${d.inHours}h ${d.inMinutes % 60}m';
  return 'in ${d.inMinutes}m';
}

/// "18 Oct, 6:30 PM" in the member's own clock.
String earlyClock(DateTime t) {
  const List<String> months = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final int h12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final String mm = t.minute.toString().padLeft(2, '0');
  final String ap = t.hour >= 12 ? 'PM' : 'AM';
  return '${t.day} ${months[t.month - 1]}, $h12:$mm $ap';
}

// END OF FILE - lib/services/early_service.dart
