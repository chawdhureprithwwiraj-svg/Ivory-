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
  Future<IvoryPost?> fetchFullPost(int id) async {
    final Map<String, dynamic>? row =
        await _db.from('posts').select().eq('id', id).maybeSingle();
    if (row == null) return null;
    return IvoryPost.fromFull(row);
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
