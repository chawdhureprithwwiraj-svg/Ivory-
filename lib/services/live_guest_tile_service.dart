import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Where ONE co-host window sits on the broadcast screen.
///
/// [x] and [y] are fractions from 0 to 1 of the room the window may travel
/// in (0,0 = top-left corner of the safe area, 1,1 = bottom-right just above
/// the chat). Fractions, not pixels, so every phone shows the same spot
/// whatever its screen size.
@immutable
class LiveGuestTilePosition {
  const LiveGuestTilePosition({required this.x, required this.y});

  final double x;
  final double y;

  /// Four decimals is plenty, and it is exactly what the database keeps.
  factory LiveGuestTilePosition.rounded(double x, double y) =>
      LiveGuestTilePosition(
        x: (x.clamp(0.0, 1.0) * 10000).round() / 10000,
        y: (y.clamp(0.0, 1.0) * 10000).round() / 10000,
      );

  static Map<String, LiveGuestTilePosition> parseAll(Object? raw) {
    final Map<String, LiveGuestTilePosition> out =
        <String, LiveGuestTilePosition>{};
    if (raw is! Map) return out;
    raw.forEach((Object? key, Object? value) {
      if (key is! String || value is! Map) return;
      final num? x = value['x'] as num?;
      final num? y = value['y'] as num?;
      if (x == null || y == null) return;
      out[key] = LiveGuestTilePosition.rounded(x.toDouble(), y.toDouble());
    });
    return out;
  }

  @override
  bool operator ==(Object other) =>
      other is LiveGuestTilePosition &&
      (other.x - x).abs() < 0.0002 &&
      (other.y - y).abs() < 0.0002;

  @override
  int get hashCode => Object.hash((x * 1000).round(), (y * 1000).round());
}

/// Reads and saves the position of each co-host window.
/// Only Ivory (the host) can save; Postgres checks that, not the app.
class LiveGuestTileService {
  LiveGuestTileService._();
  static final LiveGuestTileService instance = LiveGuestTileService._();

  SupabaseClient get _db => Supabase.instance.client;

  /// Null when the positions could not be read (for example before the
  /// CC.121 database step is run). The caller then keeps what it has and the
  /// windows simply use their tidy default places.
  Future<Map<String, LiveGuestTilePosition>?> positions(int sessionId) async {
    try {
      final Map<String, dynamic>? row = await _db
          .from('live_sessions')
          .select('guest_tile_positions')
          .eq('id', sessionId)
          .maybeSingle();
      if (row == null) return null;
      return LiveGuestTilePosition.parseAll(row['guest_tile_positions']);
    } catch (_) {
      return null;
    }
  }

  Future<void> setPosition(
    int sessionId,
    String memberId,
    LiveGuestTilePosition position,
  ) =>
      _db.rpc<void>(
        'set_live_guest_tile_position',
        params: <String, dynamic>{
          'session_id_in': sessionId,
          'member_in': memberId,
          'x_in': position.x,
          'y_in': position.y,
        },
      );
}

// END OF FILE - lib/services/live_guest_tile_service.dart
