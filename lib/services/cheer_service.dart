import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ============================================================
/// IVORY - CHEERS (the calls behind the little gift of warmth)
///
/// A Cheer is wordless: four styles, one per ribbon, a daily cap the
/// house sets. The database does all the checking (see CC.161 B);
/// this class only asks and reports the answer as a short word:
///   sent, already, cap, self, closed, gone, off, bad.
/// It never throws and never shows raw database text.
/// ============================================================
class CheerService {
  CheerService._();
  static final CheerService instance = CheerService._();

  /// The member's own choice: let other members cheer my moments.
  final ValueNotifier<bool> accepts = ValueNotifier<bool>(true);

  SupabaseClient get _db => Supabase.instance.client;

  Future<void> loadPref() async {
    try {
      final dynamic r = await _db.rpc('cheer_pref_get');
      if (r is bool) accepts.value = r;
    } catch (_) {}
  }

  Future<void> setPref(bool v) async {
    final bool before = accepts.value;
    accepts.value = v;
    try {
      final dynamic r = await _db.rpc(
        'cheer_pref_set',
        params: <String, dynamic>{'on_in': v},
      );
      if (r is bool) accepts.value = r;
    } catch (_) {
      accepts.value = before;
    }
  }

  /// Sends one cheer. Returns the status word.
  Future<String> send(String eventId, String toId, String style) async {
    try {
      final dynamic r = await _db.rpc(
        'ticker_cheer',
        params: <String, dynamic>{
          'event_in': eventId,
          'to_in': toId,
          'style_in': style,
        },
      );
      if (r is Map && r['status'] is String) return r['status'] as String;
    } catch (_) {}
    return 'bad';
  }
}

// END OF FILE - lib/services/cheer_service.dart
