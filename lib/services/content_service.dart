import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/ivory_post.dart';

/// Reads the storytelling feed. All access rules are enforced by the
/// database, so this layer never has to decide what a user may see.
class ContentService {
  ContentService._();
  static final ContentService instance = ContentService._();

  SupabaseClient get _db => Supabase.instance.client;

  /// Feed cards. Comes from the `post_previews` view, which contains no
  /// media links - locked posts are safe to send to any device.
  Future<List<IvoryPost>> fetchFeed({
    int limit = 50,
    String? typeFilter,
    String? search,
  }) async {
    dynamic query = _db.from('post_previews').select();
    if (typeFilter != null) {
      query = query.eq('type', typeFilter);
    }
    if (search != null && search.trim().isNotEmpty) {
      final String s = search.trim();
      query = query.or('title.ilike.%$s%,summary.ilike.%$s%');
    }
    final List<dynamic> rows =
        await query.order('created_at', ascending: false).limit(limit);

    return rows
        .map((dynamic r) => IvoryPost.fromPreview(r as Map<String, dynamic>))
        .toList();
  }

  /// Full post including the media link. Returns null when the database
  /// refuses access, which is exactly what should happen for a locked
  /// post - the check is server-side and cannot be bypassed.
  /// Buying a single post: the member sends the money over UPI and
  /// submits the reference. Postgres refuses a reference that has
  /// been used before, so one payment can never open two posts.
  Future<void> submitPostPayment({
    required int postId,
    required String utr,
    String? screenshotUrl,
  }) async {
    await _db.rpc<dynamic>('submit_post_payment', params: <String, dynamic>{
      'post_id_in': postId,
      'utr_in': utr.trim(),
      'shot_in': screenshotUrl,
    });
  }

  Future<void> submitLivePassPayment({
    required int sessionId,
    required String utr,
  }) async {
    await _db.rpc<dynamic>('submit_live_pass_payment',
        params: <String, dynamic>{
          'session_id_in': sessionId,
          'utr_in': utr.trim(),
        });
  }

  /// The only place a media link is handed out. open_post() checks
  /// the tier, the price and whether this member bought it, and
  /// returns nothing at all if none of those apply.
  Future<IvoryPost?> fetchFullPost(int id) async {
    final dynamic res = await _db
        .rpc<dynamic>('open_post', params: <String, dynamic>{'post_id_in': id});
    if (res is List && res.isNotEmpty) {
      final Map<String, dynamic> row = res.first as Map<String, dynamic>;
      // Vault media is private: swap the raw path for a one-hour
      // signed URL. The vault's storage policy re-checks
      // can_open_post(), so signing only ever succeeds for a member
      // who may open the post.
      final String? ref = row['media_ref'] as String?;
      if (row['media_bucket'] == 'vault' &&
          ref != null && !ref.startsWith('http')) {
        try {
          final String signed =
              await _db.storage.from('vault').createSignedUrl(ref, 3600);
          if (signed.isNotEmpty) row['media_ref'] = signed;
        } catch (_) {
          // Not entitled or storage hiccup: playback shows the
          // normal locked message instead of a URL.
        }
      }
      return IvoryPost.fromFull(row);
    }
    return null;
  }

  Future<List<PollOption>> fetchPollOptions(int postId) async {
    final List<dynamic> rows = await _db
        .from('poll_results')
        .select()
        .eq('post_id', postId)
        .order('sort_order', ascending: true);
    return rows
        .map((dynamic r) => PollOption.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// One vote per person per poll. Voting again replaces the old choice.
  Future<void> castVote({required int postId, required int optionId}) async {
    final String? uid = _db.auth.currentUser?.id;
    if (uid == null) return;
    await _db.from('poll_votes').upsert(<String, dynamic>{
      'post_id': postId,
      'option_id': optionId,
      'user_id': uid,
    }, onConflict: 'post_id,user_id');
  }

  Future<int?> myVote(int postId) async {
    final String? uid = _db.auth.currentUser?.id;
    if (uid == null) return null;
    final Map<String, dynamic>? row = await _db
        .from('poll_votes')
        .select('option_id')
        .eq('post_id', postId)
        .eq('user_id', uid)
        .maybeSingle();
    return (row?['option_id'] as num?)?.toInt();
  }

  Future<void> incrementView(int postId) async {
    try {
      await _db.rpc('increment_view', params: <String, dynamic>{
        'post_id_in': postId,
      });
    } catch (_) {
      // A failed view count must never interrupt playback.
    }
  }

  /// The subscription tiers, newest pricing straight from the database.
  Future<List<Map<String, dynamic>>> fetchTiers() async {
    final List<dynamic> rows = await _db
        .from('subscription_tiers')
        .select()
        .eq('is_active', true)
        .order('level', ascending: true);
    return rows.cast<Map<String, dynamic>>();
  }
}

// END OF FILE - lib/services/content_service.dart
