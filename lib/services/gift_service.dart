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


  /// The gifts for ONE surface, never both.
  ///
  /// A live gift is something Ivory DOES - dance, sing, tour the
  /// house. On a post she is not there, so that whole set was a
  /// promise nobody could keep. The post nine describe what the
  /// post did to the member instead, which fits a song, a face,
  /// a lipstick swatch and a last sentence equally.
  Future<List<Gift>> gifts({String surface = 'live'}) async {
    final List<dynamic> rows = await _gdb
        .from('gifts')
        .select()
        .eq('is_active', true)
        .eq('surface', surface)
        .order('sort_order', ascending: true);
    return rows
        .map((dynamic r) => Gift.fromDb(r as Map<String, dynamic>))
        .toList();
  }

  /// Which set every gift belongs to, by name.
  ///
  /// `list_gift_sends` does not return the surface, and that
  /// function is live and working - rewriting it to add one
  /// column would mean replacing a body this tree cannot see,
  /// for a label. So the catalogue is asked directly instead.
  ///
  /// NO `is_active` FILTER HERE, DELIBERATELY. A gift she has
  /// since retired must still be able to say which set it came
  /// from, or old entries in her list would quietly lose their
  /// label. The filter belongs on the sheet a member chooses
  /// from, not on a question about history.
  Future<Map<String, String>> giftSurfaces() async {
    final List<dynamic> rows =
        await _gdb.from('gifts').select('name, surface');
    final Map<String, String> out = <String, String>{};
    for (final dynamic r in rows) {
      final Map<String, dynamic> m = r as Map<String, dynamic>;
      final String? n = m['name'] as String?;
      if (n == null) continue;
      out[n] = (m['surface'] as String?) ?? 'live';
    }
    return out;
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

  /// Which sends belong to a post, and whose line she has taken
  /// down. Kept separate from `list_gift_sends` on purpose - see
  /// the note in sprint30_gift_notes.sql. The admin screen joins
  /// the two by id.
  Future<Map<int, GiftNoteFlag>> giftNoteFlags() async {
    final dynamic res = await _gdb.rpc<dynamic>('gift_note_flags');
    final Map<int, GiftNoteFlag> out = <int, GiftNoteFlag>{};
    for (final dynamic r in (res as List<dynamic>? ?? <dynamic>[])) {
      final Map<String, dynamic> m = r as Map<String, dynamic>;
      final int id = ((m['id'] as num?) ?? 0).toInt();
      if (id == 0) continue;
      out[id] = GiftNoteFlag(
        postId: (m['post_id'] as num?)?.toInt(),
        hidden: (m['note_hidden'] as bool?) ?? false,
      );
    }
    return out;
  }

  /// Takes a gift's line down, or puts it back. Hers alone -
  /// the database refuses anyone else. Confirming the money and
  /// publishing the words stay two separate decisions.
  Future<void> setGiftNoteHidden(int sendId, bool hidden) async {
    await _gdb.rpc<dynamic>('set_gift_note_hidden',
        params: <String, dynamic>{
          'send_id_in': sendId,
          'hidden_in': hidden,
        });
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

  /// Who gifted on one post, largest first.
  ///
  /// CONFIRMED SENDS ONLY - that rule lives in the SQL, not
  /// here, so no screen can ever ask for the pending ones. A
  /// name goes on a post when the money has been seen, and not
  /// a moment before.
  Future<List<PostGifter>> postGifters(int postId) async {
    final dynamic res = await _gdb.rpc<dynamic>('post_gifters',
        params: <String, dynamic>{'post_id_in': postId});
    if (res is! List) return <PostGifter>[];
    return res
        .map((dynamic r) => PostGifter.fromDb(r as Map<String, dynamic>))
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
