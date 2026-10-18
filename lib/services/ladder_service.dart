import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/ladder_models.dart';
import 'bells_service.dart';
import 'heart_service.dart';

/// ============================================================
/// IVORY - THE IVORY LADDER, THE ONLY DOOR TO THE DATABASE
///
/// Holds the latest ladder in [state] so the top-bar icon and the
/// screen always agree. Whenever the heart or the bells change, the
/// ladder is asked again (a little later), because a Mark may have
/// just been earned. Asking the ladder never touches the heart or the
/// bells services, so the three cannot loop. Quiet refreshes swallow
/// every failure: nothing here can stop the app from working.
/// ============================================================
class LadderService {
  LadderService._();
  static final LadderService instance = LadderService._();

  SupabaseClient get _db => Supabase.instance.client;

  /// The latest ladder, or null before the first answer.
  final ValueNotifier<LadderState?> state = ValueNotifier<LadderState?>(null);

  bool _listening = false;
  Timer? _debounce;

  Map<String, dynamic> _map(dynamic v) => Map<String, dynamic>.from(v as Map);

  /// Starts listening to the heart and the bells. Safe to call again.
  void start() {
    if (_listening) return;
    _listening = true;
    HeartService.instance.state.addListener(_later);
    BellsService.instance.state.addListener(_later);
  }

  void _later() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 1500), refreshQuietly);
  }

  /// Asks the database. Throws on failure so the screen can say so.
  Future<LadderState> refresh() async {
    final dynamic r = await _db.rpc('ladder_state');
    final LadderState s = LadderState.fromMap(_map(r));
    state.value = s;
    return s;
  }

  /// A quiet refresh for the top bar: never throws.
  Future<void> refreshQuietly() async {
    try {
      await refresh();
    } catch (_) {}
  }

  /// The member has watched the ceremonies; do not play them again.
  Future<void> markSeen() async {
    await _db.rpc('ladder_mark_seen');
    final LadderState? s = state.value;
    if (s == null) return;
    state.value = LadderState(
      enabled: s.enabled,
      points: s.points,
      litDays: s.litDays,
      stars: s.stars,
      markPoints: s.markPoints,
      marksEarned: s.marksEarned,
      marksTotal: s.marksTotal,
      rung: s.rung,
      next: s.next,
      rungUp: false,
      rungs: s.rungs,
      marks: s.marks
          .map(
            (MarkItem m) => MarkItem(
              key: m.key,
              name: m.name,
              blurb: m.blurb,
              rarity: m.rarity,
              glyph: m.glyph,
              target: m.target,
              have: m.have,
              earned: m.earned,
              at: m.at,
              isNew: false,
            ),
          )
          .toList(),
      newMarks: const <String>[],
      glowNow: s.glowNow,
      glowBest: s.glowBest,
      pealNow: s.pealNow,
      pealBest: s.pealBest,
      milestoneDays: s.milestoneDays,
      milestones: s.milestones
          .map(
            (LadderMilestone m) =>
                LadderMilestone(kind: m.kind, days: m.days, isNew: false),
          )
          .toList(),
    );
  }

  /// One month of the member's own days.
  Future<LadderMonth> calendar(int year, int month) async {
    final dynamic r = await _db.rpc(
      'ladder_calendar',
      params: <String, dynamic>{'y': year, 'm': month},
    );
    return LadderMonth.fromMap(_map(r));
  }

  // ---------------------------------------------------------------
  // The house (admin) side. Row-level security lets only the house in.
  // ---------------------------------------------------------------

  Future<Map<String, dynamic>> adminSummary() async {
    final dynamic r = await _db.rpc('ladder_admin_summary');
    return _map(r);
  }

  Future<Map<String, dynamic>> adminSettings() async {
    final dynamic r = await _db
        .from('ladder_settings')
        .select()
        .eq('id', 1)
        .single();
    return _map(r);
  }

  Future<void> adminSaveSettings({
    required bool open,
    required int markPoints,
    required List<int> milestones,
  }) async {
    await _db
        .from('ladder_settings')
        .update(<String, dynamic>{
          'is_open': open,
          'mark_points': markPoints,
          'milestones': milestones,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', 1);
  }

  Future<List<Map<String, dynamic>>> adminRungs() async {
    final dynamic r = await _db.from('ladder_rungs').select().order('rung');
    return (r as List).map((dynamic e) => _map(e)).toList();
  }

  Future<void> adminSaveRung(int rung, String name, int minPoints) async {
    await _db
        .from('ladder_rungs')
        .update(<String, dynamic>{'name': name, 'min_points': minPoints})
        .eq('rung', rung);
  }

  Future<List<Map<String, dynamic>>> adminMarks() async {
    final dynamic r = await _db.from('mark_defs').select().order('sort');
    return (r as List).map((dynamic e) => _map(e)).toList();
  }

  Future<void> adminSaveMark(
    String key, {
    required String name,
    required String blurb,
    required int target,
    required String rarity,
    required bool active,
  }) async {
    await _db
        .from('mark_defs')
        .update(<String, dynamic>{
          'name': name,
          'blurb': blurb,
          'target': target,
          'rarity': rarity,
          'is_active': active,
        })
        .eq('key', key);
  }
}

// END OF FILE - lib/services/ladder_service.dart
