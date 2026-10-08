import 'package:supabase_flutter/supabase_flutter.dart';

/// ============================================================
/// IVORY - WHAT HAPPENS INSIDE A CALL
///
/// Everything that belongs to a session once the two of them
/// are actually in the room: offering more time, taking the
/// offer back, and reading the current offer.
///
/// This lives apart from LiveService on purpose. LiveService is
/// already close to the size a phone editor can handle, and the
/// room's own behaviour is a separate job from joining,
/// booking and tickets.
/// ============================================================
class CallRoomService {
  CallRoomService._();

  static final CallRoomService instance = CallRoomService._();

  SupabaseClient get _db => Supabase.instance.client;

  /// The house pushes an offer of more time onto the member's
  /// screen. She chooses the price AND the duration; the
  /// database clamps the duration to between 30 and 120
  /// minutes, so no screen can ever send something silly.
  ///
  /// Repeatable - offering again simply stamps a new time, and
  /// the member's card reappears.
  Future<void> offerExtension({
    required int callId,
    required int priceInr,
    required int minutes,
  }) async {
    await _db.rpc<dynamic>('offer_call_extension',
        params: <String, dynamic>{
          'call_id_in': callId,
          'price_in': priceInr,
          'minutes_in': minutes,
        });
  }

  /// Taking the offer back off her screen.
  Future<void> withdrawExtension(int callId) async {
    await _db.rpc<void>('withdraw_call_extension',
        params: <String, dynamic>{'call_id_in': callId});
  }

  /// The offer as it stands right now. Read once when the room
  /// opens, so a member who joins after the offer was made
  /// still sees it.
  Future<CallOffer?> currentOffer(int callId) async {
    final List<dynamic> rows = await _db
        .from('call_requests')
        .select('extension_price, extension_minutes, '
            'extension_offered_at, extension_paid')
        .eq('id', callId)
        .limit(1);
    if (rows.isEmpty) return null;
    return CallOffer.fromDb(rows.first as Map<String, dynamic>);
  }

  /// The default price and duration the house last used, so the
  /// SEND box opens already filled in rather than empty.
  Future<CallOffer> defaults({required bool premium}) async {
    try {
      final List<dynamic> rows = await _db
          .from('payment_settings')
          .select()
          .eq('id', 1)
          .limit(1);
      if (rows.isNotEmpty) {
        final Map<String, dynamic> m = rows.first as Map<String, dynamic>;
        final String priceKey =
            premium ? 'ext_price_inr_premium' : 'ext_price_inr';
        final String minsKey =
            premium ? 'ext_block_minutes_premium' : 'ext_block_minutes';
        return CallOffer(
          priceInr: (m[priceKey] as num?)?.toInt() ?? 0,
          minutes: (m[minsKey] as num?)?.toInt() ?? 30,
          offeredAt: null,
          paid: false,
        );
      }
    } catch (_) {
      // A missing settings row must not stop her offering time.
    }
    return const CallOffer(
        priceInr: 0, minutes: 30, offeredAt: null, paid: false);
  }

  /// Listens to this one session for an offer appearing. This is
  /// the path that works when the member is looking at the
  /// screen; a handset notification is sent at the same moment
  /// for when they are not.
  RealtimeChannel watchOffer(
      int callId, void Function(CallOffer offer) onOffer) {
    final RealtimeChannel channel = _db.channel('ivory-offer-$callId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'call_requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: callId,
          ),
          callback: (PostgresChangePayload p) =>
              onOffer(CallOffer.fromDb(p.newRecord)),
        )
        .subscribe();
    return channel;
  }

  Future<void> stopWatching(RealtimeChannel channel) async {
    try {
      await _db.removeChannel(channel);
    } catch (_) {
      // Closing a channel twice is harmless.
    }
  }
}

/// An offer of more time, exactly as the database holds it.
class CallOffer {
  const CallOffer({
    required this.priceInr,
    required this.minutes,
    required this.offeredAt,
    required this.paid,
  });

  final int priceInr;
  final int minutes;

  /// Null means there is no offer standing. A NEW timestamp
  /// means a NEW offer, even at the same price - which is why
  /// the card is keyed to this and not to the money.
  final DateTime? offeredAt;
  final bool paid;

  bool get isLive => offeredAt != null && !paid;

  factory CallOffer.fromDb(Map<String, dynamic> m) => CallOffer(
        priceInr: (m['extension_price'] as num?)?.toInt() ?? 0,
        minutes: (m['extension_minutes'] as num?)?.toInt() ?? 30,
        offeredAt: DateTime.tryParse(
            (m['extension_offered_at'] as String?) ?? ''),
        paid: (m['extension_paid'] as bool?) ?? false,
      );
}

// END OF FILE - lib/services/call_room_service.dart
