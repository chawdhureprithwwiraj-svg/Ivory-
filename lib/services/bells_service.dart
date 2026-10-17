import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/bell_models.dart';
import 'heart_service.dart';

/// ============================================================
/// IVORY - RING MY DOORBELL, THE ONLY DOOR TO THE DATABASE
///
/// Holds the latest bells in [state] so the top-bar icon and the
/// screen always agree. Whenever the Golden Heart changes (a greeting,
/// a story read) the bells are asked again, because a bell may have
/// just rung. Nothing here can stop the app from working: quiet
/// refreshes swallow every failure.
/// ============================================================
class BellsService {
  BellsService._();
  static final BellsService instance = BellsService._();

  SupabaseClient get _db => Supabase.instance.client;

  /// The latest bells, or null before the first answer.
  final ValueNotifier<BellsState?> state = ValueNotifier<BellsState?>(null);

  bool _listening = false;
  bool _muteHeart = false;
  Timer? _debounce;

  Map<String, dynamic> _map(dynamic v) => Map<String, dynamic>.from(v as Map);

  /// Starts listening to the heart. Safe to call again.
  void start() {
    if (_listening) return;
    _listening = true;
    HeartService.instance.state.addListener(_onHeart);
  }

  void _onHeart() {
    if (_muteHeart) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), refreshQuietly);
  }

  /// Asks the database. Throws on failure so the screen can say so.
  Future<BellsState> refresh() async {
    final dynamic r = await _db.rpc('bells_state');
    return _accept(BellsState.fromMap(_map(r)));
  }

  /// A quiet refresh for the top bar: never throws.
  Future<void> refreshQuietly() async {
    try {
      await refresh();
    } catch (_) {}
  }

  /// The member opens tonight's line (rings the Night bell once it is open).
  Future<BellsState> openLine() async {
    final dynamic r = await _db.rpc('bell_open_line');
    return _accept(BellsState.fromMap(_map(r)));
  }

  /// The ceremony has been watched; do not play it again.
  Future<void> markSeen() async {
    try {
      await _db.rpc('bells_mark_seen');
    } catch (_) {}
  }

  Future<BellsState> _accept(BellsState s) async {
    final int before = state.value?.rungN ?? 0;
    state.value = s;
    // A ring adds to the heart, so the heart is asked again - without
    // asking the bells again in return.
    if (s.rungN > before || s.hasUnseen) {
      _muteHeart = true;
      try {
        await HeartService.instance.refreshQuietly();
      } finally {
        _muteHeart = false;
      }
    }
    return s;
  }

  void clear() => state.value = null;

  // ------------------------------------------------------------ ADMIN

  Future<Map<String, dynamic>> adminSummary() async {
    final dynamic r = await _db.rpc('bells_admin_summary');
    return _map(r);
  }

  Future<bool> adminIsOpen() async {
    final dynamic r = await _db
        .from('bell_settings')
        .select()
        .eq('id', 1)
        .single();
    return _map(r)['is_open'] != false;
  }

  Future<void> adminSetOpen(bool open) async {
    await _db
        .from('bell_settings')
        .update(<String, dynamic>{
          'is_open': open,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', 1);
  }

  Future<List<Map<String, dynamic>>> adminDefs() async {
    final List<dynamic> r = await _db.from('bell_defs').select().order('sort');
    return r.map(_map).toList();
  }

  Future<void> adminSaveDef(
    String key, {
    required int hour,
    required bool active,
  }) async {
    await _db
        .from('bell_defs')
        .update(<String, dynamic>{'open_hour': hour, 'is_active': active})
        .eq('key', key);
  }

  Future<List<Map<String, dynamic>>> adminLines() async {
    final List<dynamic> r = await _db
        .from('bell_lines')
        .select()
        .order('id', ascending: false);
    return r.map(_map).toList();
  }

  Future<void> adminAddLine(String body, String? forDay) async {
    await _db.from('bell_lines').insert(<String, dynamic>{
      'body': body,
      'for_day': forDay,
    });
  }

  Future<void> adminSaveLine(
    int id, {
    required String body,
    required String? forDay,
    required bool active,
  }) async {
    await _db
        .from('bell_lines')
        .update(<String, dynamic>{
          'body': body,
          'for_day': forDay,
          'is_active': active,
        })
        .eq('id', id);
  }

  Future<void> adminDeleteLine(int id) async {
    await _db.from('bell_lines').delete().eq('id', id);
  }
}

// END OF FILE - lib/services/bells_service.dart
