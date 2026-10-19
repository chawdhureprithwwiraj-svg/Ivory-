import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ============================================================
/// IVORY - THE SHOWCASE, THE ONLY DOOR TO THE DATABASE
///
/// A member's Showcase is their rung on the Ivory Ladder, the bell set
/// their bells are wearing, and up to three Marks they chose to pin.
/// This service keeps the member's own choices in [mine] and, for the
/// small tag beside a name in live chat, asks for other members'
/// Showcases a few at a time and remembers the answers for ten
/// minutes. A member who switched the Showcase off is never returned
/// by the database. Every call here is quiet: nothing can stop the
/// app from working, and a missing answer simply shows nothing.
/// ============================================================

class CrestMine {
  const CrestMine({this.pins = const <String>[], this.showOthers = true});

  final List<String> pins;
  final bool showOthers;

  factory CrestMine.fromMap(Map<String, dynamic> m) => CrestMine(
    pins: m['pins'] is List
        ? (m['pins'] as List).map((dynamic e) => '$e').toList()
        : <String>[],
    showOthers: m['show_others'] != false,
  );
}

/// What another member's Showcase shows.
class CrestPublic {
  const CrestPublic({
    required this.id,
    required this.rung,
    required this.rungName,
    required this.wear,
    required this.pins,
  });

  final String id;
  final int rung;
  final String rungName;

  /// The key of the bell set they wear (a key we do not know wears Jewel).
  final String wear;
  final List<String> pins;

  factory CrestPublic.fromMap(Map<String, dynamic> m) => CrestPublic(
    id: '${m['id']}',
    rung: (m['rung'] as num?)?.toInt() ?? 1,
    rungName: '${m['rung_name'] ?? ''}',
    wear: '${m['wear'] ?? 'jewel'}',
    pins: m['pins'] is List
        ? (m['pins'] as List)
              .map((dynamic e) => '${(e as Map)['key']}')
              .toList()
        : <String>[],
  );
}

class _Entry {
  _Entry(this.value, this.at, this.ttl);

  final CrestPublic? value;
  final DateTime at;
  final Duration ttl;

  bool get fresh => DateTime.now().difference(at) < ttl;
}

class CrestService {
  CrestService._();
  static final CrestService instance = CrestService._();

  SupabaseClient get _db => Supabase.instance.client;

  /// The member's own choices, or null before the first answer.
  final ValueNotifier<CrestMine?> mine = ValueNotifier<CrestMine?>(null);

  final Map<String, _Entry> _cache = <String, _Entry>{};
  final Map<String, List<Completer<CrestPublic?>>> _waiting =
      <String, List<Completer<CrestPublic?>>>{};
  Timer? _flushTimer;

  Map<String, dynamic> _map(dynamic v) => Map<String, dynamic>.from(v as Map);

  Future<void> refreshQuietly() async {
    try {
      final dynamic r = await _db.rpc('crest_mine');
      mine.value = CrestMine.fromMap(_map(r));
    } catch (_) {}
  }

  /// Saves the pins and/or the switch. Throws on failure so the screen
  /// can say so in its own words.
  Future<void> save({List<String>? pins, bool? show}) async {
    final CrestMine cur = mine.value ?? const CrestMine();
    final dynamic r = await _db.rpc(
      'crest_save',
      params: <String, dynamic>{'pins_in': pins ?? cur.pins, 'show_in': show},
    );
    mine.value = CrestMine.fromMap(_map(r));
  }

  void clear() {
    mine.value = null;
    _cache.clear();
  }

  /// Another member's Showcase, or null when they keep it private or the
  /// answer is not available. Asked in small batches.
  Future<CrestPublic?> of(String id) {
    final _Entry? e = _cache[id];
    if (e != null && e.fresh) return Future<CrestPublic?>.value(e.value);
    final Completer<CrestPublic?> c = Completer<CrestPublic?>();
    (_waiting[id] ??= <Completer<CrestPublic?>>[]).add(c);
    _flushTimer ??= Timer(const Duration(milliseconds: 250), _flush);
    return c.future;
  }

  Future<void> _flush() async {
    _flushTimer = null;
    final List<String> ids = _waiting.keys.take(60).toList();
    if (ids.isEmpty) return;
    final Map<String, CrestPublic> got = <String, CrestPublic>{};
    bool ok = true;
    try {
      final dynamic r = await _db.rpc(
        'crest_of',
        params: <String, dynamic>{'ids': ids},
      );
      if (r is List) {
        for (final dynamic x in r) {
          final CrestPublic p = CrestPublic.fromMap(_map(x));
          got[p.id] = p;
        }
      }
    } catch (_) {
      ok = false;
    }
    final DateTime now = DateTime.now();
    for (final String id in ids) {
      final CrestPublic? v = got[id];
      _cache[id] = _Entry(
        v,
        now,
        ok ? const Duration(minutes: 10) : const Duration(minutes: 1),
      );
      final List<Completer<CrestPublic?>> list =
          _waiting.remove(id) ?? <Completer<CrestPublic?>>[];
      for (final Completer<CrestPublic?> c in list) {
        if (!c.isCompleted) c.complete(v);
      }
    }
    if (_waiting.isNotEmpty) {
      _flushTimer ??= Timer(const Duration(milliseconds: 250), _flush);
    }
  }
}

// END OF FILE - lib/services/crest_service.dart
