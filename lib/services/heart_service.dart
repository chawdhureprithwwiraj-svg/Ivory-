import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/heart_models.dart';

/// ============================================================
/// IVORY - THE GOLDEN HEART, THE ONLY DOOR TO THE DATABASE
///
/// Holds the latest heart in [state] so the top-bar heart and the
/// sheet always agree. Nothing here can ever stop a story from
/// opening: reading a story is reported quietly and any failure is
/// swallowed.
/// ============================================================
class HeartService {
  HeartService._();
  static final HeartService instance = HeartService._();

  SupabaseClient get _db => Supabase.instance.client;

  /// The latest heart, or null before the first answer.
  final ValueNotifier<HeartState?> state = ValueNotifier<HeartState?>(null);

  Map<String, dynamic> _map(dynamic v) => Map<String, dynamic>.from(v as Map);

  /// Asks the database. Throws on failure so the sheet can say so.
  Future<HeartState> refresh() async {
    final dynamic r = await _db.rpc('heart_state');
    final HeartState s = HeartState.fromMap(_map(r));
    state.value = s;
    return s;
  }

  /// A quiet refresh for the top bar: never throws.
  Future<void> refreshQuietly() async {
    try {
      await refresh();
    } catch (_) {}
  }

  /// The member greets the heart (once a day).
  Future<HeartState> greet() async {
    final dynamic r = await _db.rpc('heart_greet');
    final HeartState s = HeartState.fromMap(_map(r));
    state.value = s;
    return s;
  }

  /// A story was opened. Returns true when this lit today's heart.
  /// Never throws.
  Future<bool> readPost(dynamic postId) async {
    try {
      final int? id = postId is int ? postId : int.tryParse('$postId');
      if (id == null) return false;
      final dynamic r = await _db.rpc(
        'heart_read_post',
        params: <String, dynamic>{'post_id_in': id},
      );
      await refreshQuietly();
      return r == true;
    } catch (_) {
      return false;
    }
  }

  void clear() => state.value = null;

  // ------------------------------------------------------------ ADMIN

  Future<Map<String, dynamic>> adminSummary() async {
    final dynamic r = await _db.rpc('heart_admin_summary');
    return _map(r);
  }

  Future<Map<String, dynamic>> adminSettings() async {
    final dynamic r = await _db
        .from('heart_settings')
        .select()
        .eq('id', 1)
        .single();
    return _map(r);
  }

  Future<void> adminSaveSettings(Map<String, dynamic> v) async {
    await _db
        .from('heart_settings')
        .update(<String, dynamic>{
          ...v,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', 1);
  }

  Future<List<Map<String, dynamic>>> adminActions() async {
    final List<dynamic> r = await _db
        .from('heart_actions')
        .select()
        .order('sort');
    return r.map(_map).toList();
  }

  Future<void> adminSaveAction(
    String key, {
    required int points,
    required int cap,
    required bool active,
  }) async {
    await _db
        .from('heart_actions')
        .update(<String, dynamic>{
          'points': points,
          'daily_cap': cap,
          'is_active': active,
        })
        .eq('key', key);
  }

  Future<List<Map<String, dynamic>>> adminTiers() async {
    final List<dynamic> r = await _db
        .from('heart_tiers')
        .select()
        .order('min_days');
    return r.map(_map).toList();
  }

  Future<void> adminSaveTier(int oldDays, int days, String name) async {
    await _db
        .from('heart_tiers')
        .update(<String, dynamic>{'min_days': days, 'name': name})
        .eq('min_days', oldDays);
  }
}

// END OF FILE - lib/services/heart_service.dart
