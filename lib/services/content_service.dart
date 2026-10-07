import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/ivory_post.dart';
import 'vault_service.dart';

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

  /// Ivory's Firstlist: the posts the house wants every member to see
  /// before anything else, in the order she put them there.
  ///
  /// Comes from the `firstlist()` function, which returns
  /// `setof post_previews` and runs as the caller - so each row has
  /// already passed the same entitlement rules as the ordinary feed.
  /// A locked post may appear here, locked, exactly as it would below.
  ///
  /// Returns an empty list rather than throwing: Home must still draw
  /// itself if this one shelf cannot be read.
  Future<List<IvoryPost>> fetchFirstlist() async {
    try {
      final dynamic rows = await _db.rpc('firstlist');
      if (rows is! List) return <IvoryPost>[];
      return rows
          .map((dynamic r) =>
              IvoryPost.fromPreview(r as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <IvoryPost>[];
    }
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
      // Vault films live in Cloudflare R2: the edge signs a GET for
      // this member (it re-checks can_open_post), and the in-app
      // player streams the signed url.
      if (row['media_source'] == 'r2' &&
          ref != null && !ref.startsWith('http')) {
        final String? signed = await VaultService.instance.openUrl(id);
        if (signed != null && signed.isNotEmpty) row['media_ref'] = signed;
      }
      if (row['media_source'] == 'supabase' &&
          ref != null && !ref.startsWith('http')) {
        // Vault media is private, and some older posts kept the raw
        // path with the bucket column still on 'media'. Sign from
        // whichever bucket actually holds the file. The vault's
        // storage policy re-checks can_open_post(), so signing only
        // ever succeeds for a member who may open the post.
        String? signed;
        for (final String bucket in <String>['vault', 'media']) {
          try {
            signed = await _db.storage.from(bucket).createSignedUrl(ref, 3600);
            break;
          } catch (_) {
            signed = null;
          }
        }
        if (signed != null && signed.isNotEmpty) row['media_ref'] = signed;
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

  /// Admin only: who voted what. optionId -> member names.
  Future<Map<int, List<String>>> fetchPollVoters(int postId) async {
    try {
      final List<dynamic> rows = await _db
          .rpc<dynamic>('poll_voters', params: <String, dynamic>{
        'post_id_in': postId,
      });
      final Map<int, List<String>> out = <int, List<String>>{};
      for (final dynamic r in rows) {
        final Map<String, dynamic> m = r as Map<String, dynamic>;
        out
            .putIfAbsent((m['option_id'] as num).toInt(),
                () => <String>[])
            .add((m['member_name'] as String?) ?? 'A member');
      }
      return out;
    } catch (_) {
      return <int, List<String>>{};
    }
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
