import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/bell_models.dart';
import '../widgets/bell_looks.dart';
import '../widgets/bell_sound.dart';
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

  /// Whether the house sends bell reminders at all (null until asked).
  final ValueNotifier<bool?> pushHouseOn = ValueNotifier<bool?>(null);

  /// Whether this member wants the reminders.
  final ValueNotifier<bool> pushOn = ValueNotifier<bool>(true);

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

  /// Asks whether reminders are on for the house and for this member.
  Future<void> loadPush() async {
    final dynamic r = await _db.rpc('bell_push_state');
    final Map<String, dynamic> m = _map(r);
    pushHouseOn.value = m['house_on'] == true;
    pushOn.value = m['on'] != false;
  }

  /// The member switches their own bell reminders on or off.
  Future<void> setPush(bool on) async {
    final dynamic r = await _db.rpc(
      'bell_push_set',
      params: <String, dynamic>{'v': on},
    );
    final Map<String, dynamic> m = _map(r);
    pushHouseOn.value = m['house_on'] == true;
    pushOn.value = m['on'] != false;
  }

  /// The member makes a free pledge of [len] Full Days in a row.
  Future<BellsState> pledge(int len) async {
    final dynamic r = await _db.rpc(
      'bell_pledge_make',
      params: <String, dynamic>{'n': len},
    );
    return _accept(BellsState.fromMap(_map(r)));
  }

  /// The member chooses which earned set the bells wear.
  Future<BellsState> wear(String key) async {
    final dynamic r = await _db.rpc(
      'bell_set_wear',
      params: <String, dynamic>{'k': key},
    );
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
    // The bells wear the member's set, in colour and in sound.
    BellLook.apply(s.wear);
    BellSound.instance.useSet(s.wear);
    state.value = s;
    // A ring adds to the heart, so the heart is asked again - without
    // asking the bells again in return.
    if (s.rungN > before || s.hasCeremony) {
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

  Future<List<Map<String, dynamic>>> adminSets() async {
    final List<dynamic> r = await _db
        .from('bell_sets')
        .select()
        .order('min_full_days');
    return r.map(_map).toList();
  }

  Future<void> adminSaveSet(
    String key, {
    required String name,
    required int minFullDays,
    required bool active,
  }) async {
    await _db
        .from('bell_sets')
        .update(<String, dynamic>{
          'name': name,
          'min_full_days': minFullDays,
          'is_active': active,
        })
        .eq('key', key);
  }

  Future<List<int>> adminPledgeLens() async {
    final dynamic r = await _db
        .from('bell_settings')
        .select('pledge_lens')
        .eq('id', 1)
        .single();
    final dynamic l = _map(r)['pledge_lens'];
    return l is List
        ? l.map((dynamic e) => (e as num).toInt()).toList()
        : <int>[];
  }

  Future<void> adminSetPledgeLens(List<int> lens) async {
    await _db
        .from('bell_settings')
        .update(<String, dynamic>{'pledge_lens': lens})
        .eq('id', 1);
  }

  /// House reminder settings: on/off, window in minutes, quiet days.
  Future<Map<String, dynamic>> adminPushSettings() async {
    final dynamic r = await _db
        .from('bell_settings')
        .select('push_on, push_window_min, push_quiet_days')
        .eq('id', 1)
        .single();
    return _map(r);
  }

  Future<void> adminSavePushSettings({
    required bool on,
    required int windowMin,
    required int quietDays,
  }) async {
    await _db
        .from('bell_settings')
        .update(<String, dynamic>{
          'push_on': on,
          'push_window_min': windowMin,
          'push_quiet_days': quietDays,
        })
        .eq('id', 1);
  }

  Future<List<Map<String, dynamic>>> adminPushBells() async {
    final List<dynamic> r = await _db
        .from('bell_defs')
        .select('key, label, push_on, push_title, push_bodies')
        .order('sort');
    return r.map(_map).toList();
  }

  Future<void> adminSaveBellPush(
    String key, {
    required bool on,
    required String title,
    required List<String> bodies,
  }) async {
    await _db
        .from('bell_defs')
        .update(<String, dynamic>{
          'push_on': on,
          'push_title': title,
          'push_bodies': bodies,
        })
        .eq('key', key);
  }

  Future<Map<String, dynamic>> adminPushStats() async {
    final dynamic r = await _db.rpc('bell_push_admin');
    return _map(r);
  }
}

// END OF FILE - lib/services/bells_service.dart
