import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ============================================================
/// IVORY - THE PRIVATE LINE, THE ONLY DOOR TO THE DATABASE
///
/// A paid member writes a letter to Ivory; she answers as many as
/// she can. A member who has not joined may still write a letter:
/// it is kept on THIS phone as a draft and travels the moment they
/// join. The database decides everything (who may send, how many,
/// the queue); this service asks, remembers the last answer in
/// [state], and keeps the draft. Quiet calls never throw.
/// ============================================================

/// One letter, as the member sees it.
class LineLetter {
  const LineLetter({
    required this.id,
    required this.body,
    required this.status,
    required this.createdAt,
    this.readAt,
    this.answeredAt,
    this.replyText,
    this.replyKind = 'text',
    this.replyAudioUrl,
    this.seen = false,
  });

  final int id;
  final String body;

  /// held | waiting | read | answered | returned | declined
  final String status;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? answeredAt;
  final String? replyText;
  final String replyKind;
  final String? replyAudioUrl;
  final bool seen;

  bool get isOpen =>
      status == 'held' || status == 'waiting' || status == 'read';

  factory LineLetter.fromMap(Map<String, dynamic> m) {
    DateTime? t(dynamic v) => v == null ? null : DateTime.tryParse('$v')?.toLocal();
    return LineLetter(
      id: (m['id'] as num?)?.toInt() ?? 0,
      body: '${m['body'] ?? ''}',
      status: '${m['status'] ?? 'waiting'}',
      createdAt: t(m['created_at']) ?? DateTime.now(),
      readAt: t(m['read_at']),
      answeredAt: t(m['answered_at']),
      replyText: m['reply_text'] as String?,
      replyKind: '${m['reply_kind'] ?? 'text'}',
      replyAudioUrl: m['reply_audio_url'] as String?,
      seen: m['seen'] == true,
    );
  }
}

/// What the database says about this member's line.
class LineState {
  const LineState({
    required this.paid,
    required this.tierName,
    required this.maxChars,
    required this.windowDays,
    required this.allowance,
    required this.used,
    required this.canSend,
    required this.whyNot,
    required this.returnDays,
    required this.answeredToday,
    required this.answeredWeek,
    required this.queuePosition,
    required this.queueDays,
    required this.unseen,
    required this.letters,
  });

  final bool paid;
  final String tierName;
  final int maxChars;
  final int windowDays;
  final int allowance;
  final int used;
  final bool canSend;

  /// join | resting | open | used | null
  final String? whyNot;
  final int returnDays;
  final int answeredToday;
  final int answeredWeek;
  final int? queuePosition;
  final int? queueDays;
  final int unseen;
  final List<LineLetter> letters;

  LineLetter? get openLetter {
    for (final LineLetter l in letters) {
      if (l.isOpen) return l;
    }
    return null;
  }

  int get left => (allowance - used).clamp(0, 999);

  factory LineState.fromMap(Map<String, dynamic> m) {
    int i(dynamic v, [int d = 0]) => (v as num?)?.toInt() ?? d;
    final dynamic ls = m['letters'];
    return LineState(
      paid: m['paid'] == true,
      tierName: '${m['tier_name'] ?? ''}',
      maxChars: i(m['max_chars'], 750),
      windowDays: i(m['window_days'], 7),
      allowance: i(m['allowance']),
      used: i(m['used']),
      canSend: m['can_send'] == true,
      whyNot: m['why_not'] as String?,
      returnDays: i(m['return_days'], 7),
      answeredToday: i(m['answered_today']),
      answeredWeek: i(m['answered_week']),
      queuePosition: m['queue_position'] == null ? null : i(m['queue_position']),
      queueDays: m['queue_days'] == null ? null : i(m['queue_days']),
      unseen: i(m['unseen']),
      letters: ls is List
          ? ls
              .map((dynamic e) => LineLetter.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList()
          : <LineLetter>[],
    );
  }
}

/// The answer to a send.
class LineSendResult {
  const LineSendResult(this.ok, this.message, [this.held = false]);
  final bool ok;
  final String message;
  final bool held;
}

/// The letter Ivory chose to share today (with the member's permission).
/// There is never a name in it.
class LineDaily {
  const LineDaily({
    required this.id,
    required this.letter,
    required this.reply,
    required this.publishedAt,
  });

  final int id;
  final String letter;
  final String reply;
  final DateTime publishedAt;

  factory LineDaily.fromMap(Map<String, dynamic> m) => LineDaily(
    id: (m['id'] as num?)?.toInt() ?? 0,
    letter: '${m['letter_text'] ?? ''}',
    reply: '${m['reply_text'] ?? ''}',
    publishedAt:
        DateTime.tryParse('${m['published_at']}')?.toLocal() ?? DateTime.now(),
  );
}

class LineService {
  LineService._();
  static final LineService instance = LineService._();

  static const String _draftKey = 'ivory_line_draft_v1';

  SupabaseClient get _db => Supabase.instance.client;

  /// The latest answer; null before the first one or when the house has
  /// switched the Private Line off.
  final ValueNotifier<LineState?> state = ValueNotifier<LineState?>(null);

  /// The draft kept on this phone ('' = none).
  final ValueNotifier<String> draft = ValueNotifier<String>('');

  DateTime? _askedAt;
  Future<LineState?>? _inflight;
  bool _draftLoaded = false;

  Map<String, dynamic> _map(dynamic v) => Map<String, dynamic>.from(v as Map);

  Future<LineState?> refresh({bool force = false}) {
    final DateTime? at = _askedAt;
    if (!force &&
        at != null &&
        state.value != null &&
        DateTime.now().difference(at).inSeconds < 20) {
      return Future<LineState?>.value(state.value);
    }
    return _inflight ??= _ask().whenComplete(() => _inflight = null);
  }

  Future<LineState?> _ask() async {
    try {
      final dynamic r = await _db.rpc('line_state');
      final Map<String, dynamic> m = _map(r);
      _askedAt = DateTime.now();
      state.value = m['open'] == true ? LineState.fromMap(m) : null;
      return state.value;
    } catch (_) {
      return state.value;
    }
  }

  /// Seals and sends. Never throws; the message is always kind.
  /// [share] is the member's permission for Ivory to show the letter and
  /// her reply as the Letter of the Day, never with a name.
  Future<LineSendResult> send(String body, {bool share = false}) async {
    try {
      final dynamic r = await _db.rpc(
        'line_send',
        params: <String, dynamic>{'body_in': body, 'share_in': share},
      );
      final Map<String, dynamic> m = _map(r);
      final bool ok = m['ok'] == true;
      if (ok) {
        await clearDraft();
        await refresh(force: true);
      }
      return LineSendResult(
        ok,
        '${m['message'] ?? ''}',
        m['status'] == 'held',
      );
    } catch (_) {
      return const LineSendResult(
        false,
        'That did not go through. Your letter is still here. Please try again.',
      );
    }
  }

  Future<bool> delete(int id) async {
    try {
      final dynamic r = await _db.rpc(
        'line_delete',
        params: <String, dynamic>{'letter_in': id},
      );
      await refresh(force: true);
      return r == true;
    } catch (_) {
      return false;
    }
  }

  /// A one-hour link to the voice reply of this member's own letter.
  /// Null when it cannot be had (never throws).
  Future<String?> voiceUrl(String path) async {
    try {
      return await _db.storage.from('line').createSignedUrl(path, 3600);
    } catch (_) {
      return null;
    }
  }

  DateTime? _dailyAt;
  LineDaily? _daily;
  String? _dailyUid;

  /// The Letter of the Day, or null. Cached for five minutes.
  Future<LineDaily?> dailyToday({bool force = false}) async {
    final String uid = _uid;
    final DateTime? at = _dailyAt;
    if (!force && _dailyUid == uid && at != null &&
        DateTime.now().difference(at).inMinutes < 5) {
      return _daily;
    }
    try {
      final dynamic r = await _db.rpc('line_daily_today');
      _daily = r is Map ? LineDaily.fromMap(Map<String, dynamic>.from(r)) : null;
      _dailyAt = DateTime.now();
      _dailyUid = uid;
    } catch (_) {}
    return _daily;
  }

  Future<void> replySeen(int id) async {
    try {
      await _db.rpc(
        'line_reply_seen',
        params: <String, dynamic>{'letter_in': id},
      );
      await refresh(force: true);
    } catch (_) {}
  }


  // ---------------------------------------------------------------
  // CC.219 - THE LINE ECONOMY: free letters enter the Line, the free
  // queue ranks by devotion, stamps and the Saturday evening draw.
  // Every call is kind when the house has not built its side yet.
  // ---------------------------------------------------------------

  /// Seals a Forever member's letter INTO the Line (no hard gate).
  Future<LineSendResult> queueJoin(String body, {bool share = false}) async {
    try {
      final dynamic r = await _db.rpc(
        'line_queue_join',
        params: <String, dynamic>{'body_in': body, 'share_in': share},
      );
      final Map<String, dynamic> m = _map(r);
      final bool ok = m['ok'] == true;
      if (ok) {
        await clearDraft();
        await refresh(force: true);
        await freeState(force: true);
      }
      return LineSendResult(
        ok,
        '${m['message'] ?? ''}',
        false,
      );
    } catch (_) {
      return const LineSendResult(
        false,
        'That did not go through. Your letter is still here. Please try again.',
      );
    }
  }

  Map<String, dynamic>? _free;
  DateTime? _freeAt;
  String? _freeUid;

  /// The member's place in the free queue, their stamps and the
  /// Invitation. Null until the house's SQL spine exists or the
  /// database cannot be reached - the screens then simply hide
  /// those shelves. Cached for five minutes.
  String get _uid => '${_db.auth.currentUser?.id ?? ''}';

  Future<Map<String, dynamic>?> freeState({bool force = false}) async {
    final String uid = _uid;
    final DateTime? at = _freeAt;
    if (!force && _freeUid == uid && at != null &&
        DateTime.now().difference(at).inMinutes < 5) {
      return _free;
    }
    try {
      final dynamic r = await _db.rpc('line_free_state');
      _free = r is Map ? Map<String, dynamic>.from(r) : null;
      _freeAt = DateTime.now();
      _freeUid = uid;
    } catch (_) {
      _free = null;
    }
    return _free;
  }

  DateTime? _drawAt;
  Map<String, dynamic>? _draw;
  String? _drawUid;

  /// This week's Saturday evening draw state: drawn or not, and who
  /// was chosen (never a name). Cached for five minutes.
  Future<Map<String, dynamic>?> saturdayState({bool force = false}) async {
    final String uid = _uid;
    final DateTime? at = _drawAt;
    if (!force && _drawUid == uid && at != null &&
        DateTime.now().difference(at).inMinutes < 5) {
      return _draw;
    }
    try {
      final dynamic r = await _db.rpc('line_saturday_state');
      _draw = r is Map ? Map<String, dynamic>.from(r) : null;
      _drawAt = DateTime.now();
      _drawUid = uid;
    } catch (_) {
      _draw = null;
    }
    return _draw;
  }

  /// Pulls the cord: draws this week's Saturday evening letter at
  /// random. Any member present may pull it; luck alone chooses.
  Future<String?> saturdayDraw() async {
    try {
      final dynamic r = await _db.rpc('line_saturday_draw');
      final Map<String, dynamic> m = _map(r);
      await saturdayState(force: true);
      await dailyToday(force: true);
      return '${m['message'] ?? ''}';
    } catch (_) {
      return 'The draw did not go through. Please try again.';
    }
  }


  DateTime? _repAt;
  Map<String, dynamic>? _rep;
  String? _repUid;

  /// CC.220 - the steering wheel for the admin Line tab: draw
  /// history, the free board's top ten, stamp counts. Aggregates
  /// only - no bodies, no names. Cached five minutes.
  Future<Map<String, dynamic>?> adminReport({bool force = false}) async {
    final String uid = _uid;
    final DateTime? at = _repAt;
    if (!force && _repUid == uid && at != null &&
        DateTime.now().difference(at).inMinutes < 5) {
      return _rep;
    }
    try {
      final dynamic r = await _db.rpc('line_admin_report');
      _rep = r is Map ? Map<String, dynamic>.from(r) : null;
      _repAt = DateTime.now();
      _repUid = uid;
    } catch (_) {
      _rep = null;
    }
    return _rep;
  }

  // ---------------------------------------------------------------
  // The draft: kept on this phone only. Ivory has not seen it.
  // ---------------------------------------------------------------

  Future<void> loadDraft() async {
    if (_draftLoaded) return;
    _draftLoaded = true;
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      draft.value = p.getString(_draftKey) ?? '';
    } catch (_) {}
  }

  Future<void> saveDraft(String text) async {
    draft.value = text;
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      if (text.trim().isEmpty) {
        await p.remove(_draftKey);
      } else {
        await p.setString(_draftKey, text);
      }
    } catch (_) {}
  }

  Future<void> clearDraft() => saveDraft('');
}

/// "waiting for a place" in plain words, only from true numbers.
String lineQueueText(LineState s) {
  final int? p = s.queuePosition;
  final int? d = s.queueDays;
  if (p == null || d == null) return 'Waiting for a place.';
  final String when = d <= 1 ? 'likely within a day' : 'about $d days';
  return 'Waiting for a place. You are number $p, $when.';
}

// END OF FILE - lib/services/line_service.dart
