import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/live_models.dart';
import 'live_service.dart';

/// ============================================================
/// GIFTS.
///
/// Lifted out of live_service.dart, which had grown past the
/// size that can be pasted reliably on a phone.
///
/// It is written as an EXTENSION rather than a new service, so
/// every existing call site still reads
/// `LiveService.instance.gifts()` and not one of them had to
/// change. The only thing a screen needs is to import this
/// file alongside the service.
///
/// Nothing here changed in the move.
/// ============================================================
extension IvoryGifts on LiveService {
  SupabaseClient get _gdb => Supabase.instance.client;


  Future<List<Gift>> gifts() async {
    final List<dynamic> rows = await _gdb
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
    final dynamic res = await _gdb.rpc<dynamic>('send_gift',
        params: <String, dynamic>{
          'gift_id_in': giftId,
          'session_id_in': sessionId,
          'post_id_in': postId,
          'note_in': note,
        });
    return (res as num).toInt();
  }

  Future<void> attachGiftUtr(int sendId, String utr) async {
    await _gdb.rpc<dynamic>('attach_gift_utr', params: <String, dynamic>{
      'send_id_in': sendId,
      'utr_in': utr.trim(),
    });
  }

  Future<List<GiftSend>> sessionGifts(int sessionId) async {
    final dynamic res = await _gdb.rpc<dynamic>('session_gifts',
        params: <String, dynamic>{'session_id_in': sessionId});
    if (res is! List) return <GiftSend>[];
    return res
        .map((dynamic r) => GiftSend.fromDb(r as Map<String, dynamic>))
        .toList();
  }

  Future<List<GiftSend>> listGiftSends({String? status}) async {
    final dynamic res = await _gdb.rpc<dynamic>('list_gift_sends',
        params: <String, dynamic>{'status_in': status});
    if (res is! List) return <GiftSend>[];
    return res
        .map((dynamic r) => GiftSend.fromDb(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> confirmGift(int sendId, {bool accept = true}) async {
    await _gdb.rpc<dynamic>('confirm_gift', params: <String, dynamic>{
      'send_id_in': sendId,
      'accept_in': accept,
    });
  }
}

// END OF FILE - lib/services/gift_service.dart
