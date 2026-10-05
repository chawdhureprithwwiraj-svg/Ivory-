import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/agora_config.dart';
import '../models/live_models.dart';

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
        .order('status', ascending: true)
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

  /// Closes a session nobody joined. Forgiven twice per cycle.
  Future<void> markMissed(int callId) async {
    await _db.rpc<dynamic>('mark_call_missed',
        params: <String, dynamic>{'call_id_in': callId});
  }

  Future<void> endCall(int callId) async {
    await _db
        .rpc<void>('end_call', params: <String, dynamic>{'call_id_in': callId});
  }


  // ---------------------------------------------------------------
  // The administrator's console
  // ---------------------------------------------------------------

  /// Every session, newest and most urgent first. Postgres refuses
  /// this to anyone who is not the administrator.
  Future<List<AdminCall>> listCalls({String? status}) async {
    final dynamic res = await _db.rpc<dynamic>('list_calls',
        params: <String, dynamic>{'status_in': status});
    if (res is! List) return <AdminCall>[];
    return res
        .map((dynamic r) => AdminCall.fromDb(r as Map<String, dynamic>))
        .toList();
  }

  /// Writes the agreed slot and tells the member the door will open.
  Future<void> setCallTime(int callId, DateTime when,
      {DateTime? windowEnd}) async {
    await _db.rpc<dynamic>('set_call_time', params: <String, dynamic>{
      'call_id_in': callId,
      'when_in': when.toUtc().toIso8601String(),
      'window_end_in': windowEnd?.toUtc().toIso8601String(),
    });
  }

  /// Closes anything whose window passed with nobody inside.
  /// Returns how many were closed.
  Future<int> sweepMissed() async {
    try {
      final dynamic res = await _db.rpc<dynamic>('sweep_missed_calls');
      return (res as num?)?.toInt() ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// 'early', 'open', 'closed' or 'anytime'.
  Future<String> callWindow(int callId) async {
    try {
      final dynamic res = await _db.rpc<dynamic>('call_window',
          params: <String, dynamic>{'call_id_in': callId});
      if (res is List && res.isNotEmpty) {
        return ((res.first as Map<String, dynamic>)['state'] as String?) ??
            'anytime';
      }
    } catch (_) {}
    return 'anytime';
  }


  // ---------------------------------------------------------------
  // Live chat - how a viewer takes part
  // ---------------------------------------------------------------

  Future<List<LiveMessage>> fetchMessages(int sessionId) async {
    final List<dynamic> rows = await _db
        .from('live_messages')
        .select()
        .eq('session_id', sessionId)
        .order('created_at', ascending: true)
        .limit(200);
    return rows
        .map((dynamic r) => LiveMessage.fromDb(r as Map<String, dynamic>))
        .toList();
  }

  /// Postgres checks entitlement again here, so a member who is not
  /// in the room cannot write into it.
  Future<void> sendMessage(int sessionId, String body) async {
    await _db.rpc<dynamic>('send_live_message', params: <String, dynamic>{
      'session_id_in': sessionId,
      'body_in': body,
    });
  }

  RealtimeChannel watchMessages(
    int sessionId,
    void Function(LiveMessage) onMessage,
  ) {
    final RealtimeChannel channel = _db.channel('ivory-chat-$sessionId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'live_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'session_id',
            value: sessionId,
          ),
          callback: (PostgresChangePayload payload) =>
              onMessage(LiveMessage.fromDb(payload.newRecord)),
        )
        .subscribe();
    return channel;
  }

  /// The room itself, closing: members learn the moment it ends.
  RealtimeChannel watchStatus(
      int sessionId, void Function(String) onStatus) {
    final RealtimeChannel channel =
        _db.channel('ivory-status-$sessionId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'live_sessions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: sessionId,
          ),
          callback: (PostgresChangePayload p) =>
              onStatus((p.newRecord['status'] as String?) ?? ''),
        )
        .subscribe();
    return channel;
  }

  // ---------------------------------------------------------------
  // Gifts
  // ---------------------------------------------------------------

  Future<List<Gift>> gifts() async {
    final List<dynamic> rows = await _db
        .from('gifts')
        .select()
        .eq('is_active', true)
        .order('sort_order', ascending: true);
    return rows
        .map((dynamic r) => Gift.fromDb(r as Map<String, dynamic>))
        .toList();
  }

  /// Shows in the room immediately, marked pending. Returns the id
  /// so the reference can be attached a moment later.
  Future<int> sendGift({
    required int giftId,
    int? sessionId,
    int? postId,
    String? note,
  }) async {
    final dynamic res = await _db.rpc<dynamic>('send_gift',
        params: <String, dynamic>{
          'gift_id_in': giftId,
          'session_id_in': sessionId,
          'post_id_in': postId,
          'note_in': note,
        });
    return (res as num).toInt();
  }

  Future<void> attachGiftUtr(int sendId, String utr) async {
    await _db.rpc<dynamic>('attach_gift_utr', params: <String, dynamic>{
      'send_id_in': sendId,
      'utr_in': utr.trim(),
    });
  }

  Future<List<GiftSend>> sessionGifts(int sessionId) async {
    final dynamic res = await _db.rpc<dynamic>('session_gifts',
        params: <String, dynamic>{'session_id_in': sessionId});
    if (res is! List) return <GiftSend>[];
    return res
        .map((dynamic r) => GiftSend.fromDb(r as Map<String, dynamic>))
        .toList();
  }

  Future<List<GiftSend>> listGiftSends({String? status}) async {
    final dynamic res = await _db.rpc<dynamic>('list_gift_sends',
        params: <String, dynamic>{'status_in': status});
    if (res is! List) return <GiftSend>[];
    return res
        .map((dynamic r) => GiftSend.fromDb(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> confirmGift(int sendId, {bool accept = true}) async {
    await _db.rpc<dynamic>('confirm_gift', params: <String, dynamic>{
      'send_id_in': sendId,
      'accept_in': accept,
    });
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
