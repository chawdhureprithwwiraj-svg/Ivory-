import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/live_guest_models.dart';
import '../models/premium_tier_badge.dart';
import 'member_badge_service.dart';

/// Server-gated live co-host requests, capacity and future-entry credits.
/// Prices, payment state, approvals and guest publisher permission are never
/// trusted to values supplied by the phone.
class LiveGuestService {
  LiveGuestService._();
  static final LiveGuestService instance = LiveGuestService._();

  SupabaseClient get _db => Supabase.instance.client;

  Future<LiveGuestCheckout> startRequest({
    required int sessionId,
    required String mediaKind,
  }) async {
    final dynamic result = await _db.rpc<dynamic>(
      'start_live_guest_request',
      params: <String, dynamic>{
        'session_id_in': sessionId,
        'media_kind_in': mediaKind,
      },
    );
    final dynamic row = result is List ? result.first : result;
    return LiveGuestCheckout.fromMap(Map<String, dynamic>.from(row as Map));
  }

  Future<int> submitUpiPayment({
    required int requestId,
    required String utr,
  }) async {
    final dynamic result = await _db.rpc<dynamic>(
      'submit_live_guest_payment',
      params: <String, dynamic>{
        'request_id_in': requestId,
        'utr_in': utr,
        'shot_in': null,
      },
    );
    return (result as num).toInt();
  }

  Future<bool> guestRequestsOpen(int sessionId) async {
    final Map<String, dynamic>? row = await _db
        .from('live_sessions')
        .select('guest_requests_open')
        .eq('id', sessionId)
        .maybeSingle();
    return (row?['guest_requests_open'] as bool?) ?? false;
  }

  Future<bool> hostVideoEnabled(int sessionId) async {
    final Map<String, dynamic>? row = await _db
        .from('live_sessions')
        .select('host_video_enabled')
        .eq('id', sessionId)
        .maybeSingle();
    return (row?['host_video_enabled'] as bool?) ?? true;
  }

  Future<LiveGuestDockAnchor> guestDockAnchor(int sessionId) async {
    try {
      final Map<String, dynamic>? row = await _db
          .from('live_sessions')
          .select('guest_dock_anchor')
          .eq('id', sessionId)
          .maybeSingle();
      return LiveGuestDockAnchor.fromDb(row?['guest_dock_anchor']);
    } catch (_) {
      // Keep the room usable when the additive layout migration is pending.
      return LiveGuestDockAnchor.aboveChatCenter;
    }
  }

  RealtimeChannel watchSettings(int sessionId, void Function() onChange) {
    final RealtimeChannel channel = _db.channel(
        'ivory-guest-settings-$sessionId-${DateTime.now().microsecondsSinceEpoch}');
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
          callback: (_) => onChange(),
        )
        .subscribe();
    return channel;
  }

  Future<int> creditBalance() async {
    final dynamic result = await _db.rpc<dynamic>('live_guest_credit_balance');
    return (result as num?)?.toInt() ?? 0;
  }

  Future<LiveGuestRequest?> myRequest(int sessionId) async {
    final List<dynamic> rows = await _db
        .from('live_guest_requests')
        .select()
        .eq('session_id', sessionId)
        .order('created_at', ascending: false)
        .limit(1);
    if (rows.isEmpty) return null;
    return LiveGuestRequest.fromMap(rows.first as Map<String, dynamic>);
  }

  Future<List<LiveGuestRequest>> requestsForHost(int sessionId) async {
    final dynamic result = await _db.rpc<dynamic>(
      'live_guest_requests_for_host',
      params: <String, dynamic>{'session_id_in': sessionId},
    );
    if (result is! List) return <LiveGuestRequest>[];
    return result
        .map((dynamic row) =>
            LiveGuestRequest.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<List<LiveGuestParticipant>> participants(int sessionId) async {
    final dynamic result = await _db.rpc<dynamic>(
      'live_guest_participants',
      params: <String, dynamic>{'session_id_in': sessionId},
    );
    if (result is! List) return <LiveGuestParticipant>[];
    final List<LiveGuestParticipant> rows = result
        .map((dynamic row) => LiveGuestParticipant.fromMap(
            Map<String, dynamic>.from(row as Map)))
        .toList();
    final Map<String, PremiumTierBadge>? badges =
        await MemberBadgeService.instance.forLiveSession(sessionId);
    if (badges == null) return rows;
    return rows.map((LiveGuestParticipant participant) {
      final PremiumTierBadge? badge = badges[participant.userId];
      return participant.withPremiumTier(
        tierName: badge?.tierName,
        tierLevel: badge?.tierLevel ?? 0,
      );
    }).toList();
  }

  Future<void> respond(int requestId, {required bool approve}) => _db.rpc<void>(
        'respond_live_guest_request',
        params: <String, dynamic>{
          'request_id_in': requestId,
          'approve_in': approve,
        },
      );

  Future<void> remove(int requestId) => _db.rpc<void>(
        'remove_live_guest',
        params: <String, dynamic>{'request_id_in': requestId},
      );

  Future<void> cancelRequest(int requestId) => _db.rpc<void>(
        'cancel_live_guest_request',
        params: <String, dynamic>{'request_id_in': requestId},
      );

  Future<void> setRequestsOpen(int sessionId, bool open) => _db.rpc<void>(
        'set_live_guest_requests_open',
        params: <String, dynamic>{
          'session_id_in': sessionId,
          'open_in': open,
        },
      );

  Future<void> markJoined(int requestId) async {
    final dynamic result = await _db.rpc<dynamic>(
      'mark_live_guest_joined',
      params: <String, dynamic>{'request_id_in': requestId},
    );
    if (result == 'expired') {
      throw Exception('The broadcast ended before you connected.');
    }
  }

  Future<void> leave(int requestId) async {
    try {
      await _db.rpc<void>(
        'leave_live_guest',
        params: <String, dynamic>{'request_id_in': requestId},
      );
    } catch (_) {
      // The RTC leave must still finish if presence bookkeeping is offline.
    }
  }

  Future<void> setVideo(int requestId, bool enabled) => _db.rpc<void>(
        'set_live_guest_video',
        params: <String, dynamic>{
          'request_id_in': requestId,
          'enabled_in': enabled,
        },
      );

  Future<void> setHostVideo(int sessionId, bool enabled) => _db.rpc<void>(
        'set_live_host_video',
        params: <String, dynamic>{
          'session_id_in': sessionId,
          'enabled_in': enabled,
        },
      );

  Future<void> setGuestDockAnchor(
    int sessionId,
    LiveGuestDockAnchor anchor,
  ) =>
      _db.rpc<void>(
        'set_live_guest_dock_anchor',
        params: <String, dynamic>{
          'session_id_in': sessionId,
          'anchor_in': anchor.dbValue,
        },
      );

  RealtimeChannel watchRequests(
    int sessionId,
    void Function() onChange,
  ) {
    final RealtimeChannel channel = _db.channel(
        'ivory-guests-$sessionId-${DateTime.now().microsecondsSinceEpoch}');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'live_guest_requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'session_id',
            value: sessionId,
          ),
          callback: (_) => onChange(),
        )
        .subscribe();
    return channel;
  }

  RealtimeChannel watchParticipants(
    int sessionId,
    void Function() onChange,
  ) {
    final RealtimeChannel channel = _db.channel('ivory-guest-presence-$sessionId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'live_guest_presence',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'session_id',
            value: sessionId,
          ),
          callback: (_) => onChange(),
        )
        .subscribe();
    return channel;
  }

  Future<void> stopWatching(RealtimeChannel channel) async {
    await _db.removeChannel(channel);
  }
}

// END OF FILE - lib/services/live_guest_service.dart
