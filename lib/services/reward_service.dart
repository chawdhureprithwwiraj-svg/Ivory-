import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/reward_models.dart';

/// ============================================================
/// IVORY - THE REWARDS STUDIO, THE ONLY DOOR TO THE DATABASE
///
/// Holds the latest treasures in [state]. Nothing here can stop a
/// screen from opening: the quiet refresh swallows its errors.
/// ============================================================
class RewardService {
  RewardService._();
  static final RewardService instance = RewardService._();

  SupabaseClient get _db => Supabase.instance.client;

  final ValueNotifier<RewardState?> state = ValueNotifier<RewardState?>(null);

  Map<String, dynamic> _map(dynamic v) => Map<String, dynamic>.from(v as Map);

  Future<RewardState> refresh() async {
    final dynamic r = await _db.rpc('reward_state');
    final RewardState s = RewardState.fromMap(_map(r));
    state.value = s;
    return s;
  }

  Future<void> refreshQuietly() async {
    try {
      await refresh();
    } catch (_) {}
  }

  Future<void> markSeen() async {
    try {
      await _db.rpc('reward_mark_seen');
    } catch (_) {}
  }

  /// Does this member hold this access key right now? For the screens
  /// that gate something behind an access treasure.
  Future<bool> hasAccess(String key) async {
    try {
      final dynamic r = await _db.rpc(
        'has_access',
        params: <String, dynamic>{'key_in': key},
      );
      return r == true;
    } catch (_) {
      return false;
    }
  }

  // ------------------------------------------------------------ ADMIN

  Future<List<Map<String, dynamic>>> adminDefs() async {
    final List<dynamic> r = await _db
        .from('reward_defs')
        .select()
        .order('sort', ascending: true)
        .order('id', ascending: true);
    return r.map(_map).toList();
  }

  Future<Map<String, dynamic>> adminSummary() async {
    final dynamic r = await _db.rpc('reward_admin_summary');
    return _map(r);
  }

  /// member id -> the badges they hold (for the Members list).
  Future<Map<String, List<Map<String, dynamic>>>> adminMemberBadges() async {
    final Map<String, dynamic> r = _map(
      await _db.rpc('reward_admin_member_badges'),
    );
    return r.map(
      (String k, dynamic v) => MapEntry<String, List<Map<String, dynamic>>>(
        k,
        (v as List).map((dynamic e) => _map(e)).toList(),
      ),
    );
  }

  /// Creates a reward (id null) or changes one. Rewards are never
  /// deleted: switch one off instead and members keep what they earned.
  Future<void> adminSaveDef(int? id, Map<String, dynamic> v) async {
    if (id == null) {
      await _db.from('reward_defs').insert(v);
    } else {
      await _db.from('reward_defs').update(v).eq('id', id);
    }
  }
}

// END OF FILE - lib/services/reward_service.dart
