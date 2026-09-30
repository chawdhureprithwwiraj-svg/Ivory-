import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/agora_config.dart';

/// ============================================================
/// IVORY - LIVE SESSIONS AND ONE-ON-ONE CALLS
///
/// This layer never decides who may join anything. It asks Postgres
/// (join_live / join_call) and the Edge Function (agora-token), both
/// of which enforce tier level, passes and minute allowances. If the
/// member is not entitled, what comes back is a plain sentence they
/// can read, not a crash.
/// ============================================================

// =====================================================================
// MODELS
// =====================================================================

/// A broadcast as a member is allowed to see it: everything except the
/// channel name, which only ever arrives with a token.
class LiveSession {
  const LiveSession({
    required this.id,
    required this.title,
    this.subtitle,
    this.coverUrl,
    this.access = 'tier',
    this.minTier = 0,
    this.priceInr = 0,
    this.status = 'scheduled',
    this.scheduledAt,
    this.startedAt,
    this.viewerCount = 0,
    this.tierName,
    this.isEntitled = false,
  });

  final int id;
  final String title;
  final String? subtitle;
  final String? coverUrl;
  final String access;
  final int minTier;
  final int priceInr;
  final String status;
  final DateTime? scheduledAt;
  final DateTime? startedAt;
  final int viewerCount;
  final String? tierName;
  final bool isEntitled;

  bool get isLive => status == 'live';
  bool get isPayPerView => access == 'ppv';

  String get gateLabel {
    if (isEntitled) return 'Join now';
    if (isPayPerView) return 'Unlock for Rs.$priceInr';
    return tierName == null ? 'Members only' : '$tierName and above';
  }

  factory LiveSession.fromDb(Map<String, dynamic> m) => LiveSession(
        id: (m['id'] as num).toInt(),
        title: (m['title'] as String?) ?? 'Live',
        subtitle: m['subtitle'] as String?,
        coverUrl: m['cover_url'] as String?,
        access: (m['access'] as String?) ?? 'tier',
        minTier: ((m['min_tier'] as num?) ?? 0).toInt(),
        priceInr: ((m['price_inr'] as num?) ?? 0).toInt(),
        status: (m['status'] as String?) ?? 'scheduled',
        scheduledAt: DateTime.tryParse((m['scheduled_at'] as String?) ?? ''),
        startedAt: DateTime.tryParse((m['started_at'] as String?) ?? ''),
        viewerCount: ((m['viewer_count'] as num?) ?? 0).toInt(),
        tierName: m['tier_name'] as String?,
        isEntitled: (m['is_entitled'] as bool?) ?? false,
      );
}

/// Everything Agora needs to let this device into this room, once.
class AgoraTicket {
  const AgoraTicket({
    required this.appId,
    required this.channel,
    required this.token,
    required this.uid,
    required this.isPublisher,
  });

  final String appId;
  final String channel;
  final String token;
  final int uid;
  final bool isPublisher;
}

/// "78 of 120 minutes left, renews on 1 Nov."
class CallBalance {
  const CallBalance({
    required this.kind,
    required this.allowed,
    required this.used,
    required this.remaining,
    required this.period,
    this.resetsAt,
    this.tierLevel = 0,
  });

  final String kind;
  final int allowed;
  final int used;
  final int remaining;
  final String period;
  final DateTime? resetsAt;
  final int tierLevel;

  bool get isIncluded => allowed > 0;
  double get fraction => allowed == 0 ? 0 : (used / allowed).clamp(0.0, 1.0);

  String get periodLabel {
    switch (period) {
      case 'day':
        return 'today';
      case 'week':
        return 'this week';
      case 'year':
        return 'this year';
      default:
        return 'this month';
    }
  }

  static const CallBalance none = CallBalance(
    kind: 'video',
    allowed: 0,
    used: 0,
    remaining: 0,
    period: 'month',
  );

  factory CallBalance.fromDb(Map<String, dynamic> m) => CallBalance(
        kind: (m['kind'] as String?) ?? 'video',
        allowed: ((m['allowed'] as num?) ?? 0).toInt(),
        used: ((m['used'] as num?) ?? 0).toInt(),
        remaining: ((m['remaining'] as num?) ?? 0).toInt(),
        period: (m['period'] as String?) ?? 'month',
        resetsAt: DateTime.tryParse((m['resets_at'] as String?) ?? ''),
        tierLevel: ((m['tier_level'] as num?) ?? 0).toInt(),
      );
}

/// One requested or confirmed one-on-one session.
class CallRequest {
  const CallRequest({
    required this.id,
    required this.kind,
    required this.minutes,
    required this.status,
    this.priceInr = 0,
    this.note,
    this.requestedFor,
    this.createdAt,
  });

  final int id;
  final String kind;
  final int minutes;
  final String status;
  final int priceInr;
  final String? note;
  final DateTime? requestedFor;
  final DateTime? createdAt;

  bool get isVideo => kind == 'video';
  bool get canJoin => status == 'accepted' || status == 'active';

  String get statusLabel {
    switch (status) {
      case 'requested':
        return 'Waiting for confirmation';
      case 'accepted':
        return 'Confirmed';
      case 'active':
        return 'In progress';
      case 'completed':
        return 'Finished';
      case 'declined':
        return 'Not accepted';
      default:
        return 'Cancelled';
    }
  }

  factory CallRequest.fromDb(Map<String, dynamic> m) => CallRequest(
        id: (m['id'] as num).toInt(),
        kind: (m['kind'] as String?) ?? 'video',
        minutes: ((m['minutes'] as num?) ?? 15).toInt(),
        status: (m['status'] as String?) ?? 'requested',
        priceInr: ((m['price_inr'] as num?) ?? 0).toInt(),
        note: m['note'] as String?,
        requestedFor: DateTime.tryParse((m['requested_for'] as String?) ?? ''),
        createdAt: DateTime.tryParse((m['created_at'] as String?) ?? ''),
      );
}

/// Where a member goes to pick a time slot. Provider-agnostic on
/// purpose: Cal.com today, anything with a URL tomorrow.
class BookingLink {
  const BookingLink({
    required this.kind,
    required this.provider,
    this.url,
    this.headline,
    this.note,
  });

  final String kind;
  final String provider;
  final String? url;
  final String? headline;
  final String? note;

  bool get isReady => url != null && url!.startsWith('http');

  factory BookingLink.fromDb(Map<String, dynamic> m) => BookingLink(
        kind: (m['kind'] as String?) ?? 'video',
        provider: (m['provider'] as String?) ?? 'cal_com',
        url: m['url'] as String?,
        headline: m['headline'] as String?,
        note: m['note'] as String?,
      );
}

// =====================================================================
// SERVICE
// =====================================================================
class LiveService {
  LiveService._();
  static final LiveService instance = LiveService._();

  SupabaseClient get _db => Supabase.instance.client;

  // ---------------------------------------------------------------
  // Broadcasts
  // ---------------------------------------------------------------

  /// Everything on air or coming up, newest first.
  Future<List<LiveSession>> fetchSessions() async {
    final List<dynamic> rows = await _db
        .from('live_public')
        .select()
        .order('status')
        .order('started_at', ascending: false)
        .limit(30);
    return rows
        .map((dynamic r) => LiveSession.fromDb(r as Map<String, dynamic>))
        .toList();
  }

  /// The one broadcast that is on air right now, if any. This is what
  /// the Home banner watches.
  Future<LiveSession?> fetchOnAir() async {
    final List<dynamic> rows = await _db
        .from('live_public')
        .select()
        .eq('status', 'live')
        .order('started_at', ascending: false)
        .limit(1);
    if (rows.isEmpty) return null;
    return LiveSession.fromDb(rows.first as Map<String, dynamic>);
  }

  /// Fires whenever a broadcast starts or ends, so the banner appears
  /// without anyone pulling to refresh.
  RealtimeChannel watchSessions(void Function() onChange) {
    final RealtimeChannel channel = _db.channel('ivory-live');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'live_sessions',
          callback: (_) => onChange(),
        )
        .subscribe();
    return channel;
  }

  Future<void> stopWatching(RealtimeChannel channel) async {
    await _db.removeChannel(channel);
  }

  // ---------------------------------------------------------------
  // Getting in
  // ---------------------------------------------------------------

  /// Asks the Edge Function for a token. Every check happens on the
  /// server; a refusal comes back as a readable sentence.
  Future<AgoraTicket> _ticket({required String mode, required int id}) async {
    if (!AgoraConfig.isConfigured) {
      throw 'Live sessions are not switched on yet.';
    }

    final FunctionResponse res = await _db.functions.invoke(
      AgoraConfig.tokenFunction,
      body: <String, dynamic>{'mode': mode, 'id': id},
    );

    final dynamic data = res.data;
    if (data is Map && data['error'] != null) {
      throw data['error'].toString();
    }
    if (data is! Map || data['token'] == null) {
      throw 'Could not open that session. Try again in a moment.';
    }

    return AgoraTicket(
      appId: (data['appId'] as String?) ?? AgoraConfig.appId,
      channel: data['channel'] as String,
      token: data['token'] as String,
      uid: (data['uid'] as num).toInt(),
      isPublisher: data['role'] == 'publisher',
    );
  }

  Future<AgoraTicket> joinLive(int sessionId) =>
      _ticket(mode: 'live', id: sessionId);

  Future<AgoraTicket> joinCall(int callId) =>
      _ticket(mode: 'call', id: callId);

  Future<void> leaveLive(int sessionId) async {
    try {
      await _db.rpc<void>('leave_live',
          params: <String, dynamic>{'session_id_in': sessionId});
    } catch (_) {
      // A missed decrement is cosmetic; never bother the member.
    }
  }

  // ---------------------------------------------------------------
  // Going live (administrator only)
  // ---------------------------------------------------------------
  Future<int> startLive({
    required String title,
    String? subtitle,
    String access = 'tier',
    int minTier = 0,
    int priceInr = 0,
    String? coverUrl,
  }) async {
    final dynamic res = await _db.rpc<dynamic>('start_live', params:
        <String, dynamic>{
      'title_in': title,
      'subtitle_in': subtitle,
      'access_in': access,
      'min_tier_in': minTier,
      'price_in': priceInr,
      'cover_in': coverUrl,
    });
    if (res is List && res.isNotEmpty) {
      return ((res.first as Map<String, dynamic>)['id'] as num).toInt();
    }
    throw 'The broadcast could not be started.';
  }

  Future<void> endLive(int sessionId) async {
    await _db.rpc<void>('end_live',
        params: <String, dynamic>{'session_id_in': sessionId});
  }

  // ---------------------------------------------------------------
  // One-on-one
  // ---------------------------------------------------------------

  /// How many minutes this member has left for [kind] this period.
  Future<CallBalance> balance(String kind) async {
    final dynamic res = await _db
        .rpc<dynamic>('call_balance', params: <String, dynamic>{'kind_in': kind});
    if (res is List && res.isNotEmpty) {
      return CallBalance.fromDb(res.first as Map<String, dynamic>);
    }
    if (res is Map<String, dynamic>) return CallBalance.fromDb(res);
    return CallBalance.none;
  }

  /// [priceInr] above zero marks this as a paid wish, which does not
  /// consume the membership allowance.
  Future<int> requestCall({
    String kind = 'video',
    int minutes = 15,
    int priceInr = 0,
    String? note,
    DateTime? when,
  }) async {
    final dynamic res =
        await _db.rpc<dynamic>('request_call', params: <String, dynamic>{
      'kind_in': kind,
      'minutes_in': minutes,
      'price_in': priceInr,
      'note_in': note,
      'when_in': when?.toIso8601String(),
    });
    return (res as num).toInt();
  }

  Future<List<CallRequest>> myCalls() async {
    final List<dynamic> rows = await _db
        .from('call_requests')
        .select()
        .order('created_at', ascending: false)
        .limit(30);
    return rows
        .map((dynamic r) => CallRequest.fromDb(r as Map<String, dynamic>))
        .toList();
  }

  Future<List<CallRequest>> pendingCalls() async {
    final List<dynamic> rows = await _db
        .from('call_requests')
        .select()
        .eq('status', 'requested')
        .order('created_at', ascending: false);
    return rows
        .map((dynamic r) => CallRequest.fromDb(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> respondToCall(int callId, {required bool accept}) async {
    await _db.rpc<dynamic>('respond_call', params: <String, dynamic>{
      'call_id_in': callId,
      'accept_in': accept,
    });
  }

  Future<void> endCall(int callId) async {
    await _db
        .rpc<void>('end_call', params: <String, dynamic>{'call_id_in': callId});
  }

  // ---------------------------------------------------------------
  // Booking links
  // ---------------------------------------------------------------
  Future<BookingLink?> bookingLink(String kind) async {
    final List<dynamic> rows = await _db
        .from('booking_settings')
        .select()
        .eq('kind', kind)
        .eq('is_active', true)
        .limit(1);
    if (rows.isEmpty) return null;
    return BookingLink.fromDb(rows.first as Map<String, dynamic>);
  }

  Future<void> saveBookingLink({
    required String kind,
    required String provider,
    required String url,
    String? headline,
  }) async {
    await _db.from('booking_settings').update(<String, dynamic>{
      'provider': provider,
      'url': url,
      if (headline != null) 'headline': headline,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('kind', kind);
  }
}

// END OF FILE - lib/services/live_service.dart
