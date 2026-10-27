import 'package:supabase_flutter/supabase_flutter.dart';

/// The Wheel of Fans — member-side service.
///
/// Born with the CC.221 lesson: every cache is keyed to the signed-in
/// member, so no account ever sees another account's fortune. The server
/// draws every prize (rpc wheel_spin); this file only asks and remembers
/// for sixty seconds at a time.
class WheelService {
  WheelService._();
  static final WheelService instance = WheelService._();

  SupabaseClient get _db => Supabase.instance.client;

  String get _uid => _db.auth.currentUser?.id ?? '';

  // uid-keyed caches: [uid, timestamp, payload]
  String _stateUid = '';
  int _stateAt = 0;
  Map<String, dynamic>? _stateCache;

  /// The whole wheel truth: window open/closed, purse, streak, declared
  /// weights, ledger, next opening. Cached sixty seconds per member.
  Future<Map<String, dynamic>> state({bool force = false}) async {
    final int now = DateTime.now().millisecondsSinceEpoch;
    if (!force &&
        _stateCache != null &&
        _stateUid == _uid &&
        now - _stateAt < 60000) {
      return _stateCache!;
    }
    try {
      final dynamic r = await _db.rpc('wheel_open_state');
      final Map<String, dynamic> m =
          Map<String, dynamic>.from(r as Map);
      _stateCache = m;
      _stateUid = _uid;
      _stateAt = now;
      return m;
    } catch (e) {
      return _stateCache ??
          <String, dynamic>{
            'open': false,
            'window': '',
            'purse': 0,
            'streak': 0,
            'tokens': 0,
            'petals_owed': 0,
            'weights': <dynamic>[],
            'ledger': <dynamic>[],
            'is_admin': false,
          };
    }
  }

  /// One turn of the wheel. The server checks the hour, the uniqueness of
  /// the window and draws by declared weight. [useToken] spends a Gilded
  /// Spin token so a rest becomes three rupees.
  Future<Map<String, dynamic>> spin({bool useToken = false}) async {
    try {
      final dynamic r =
          await _db.rpc('wheel_spin', params: <String, dynamic>{
        'use_token': useToken,
      });
      _stateCache = null;
      return Map<String, dynamic>.from(r as Map);
    } catch (e) {
      return <String, dynamic>{'ok': false, 'why': 'network'};
    }
  }

  /// Spend the whole purse on one purchase. The caller shows this only
  /// when the price is greater than the purse (the house law) and when no
  /// other discount instrument is on the bill.
  Future<Map<String, dynamic>> redeem(int amount, {String ref = ''}) async {
    try {
      final dynamic r = await _db.rpc('wheel_redeem',
          params: <String, dynamic>{'amount': amount, 'ref': ref});
      _stateCache = null;
      return Map<String, dynamic>.from(r as Map);
    } catch (e) {
      return <String, dynamic>{'ok': false, 'why': 'network'};
    }
  }

  // ---------- the owner's desk (CC.224) ----------
  Future<Map<String, dynamic>> desk() async {
    try {
      final dynamic r = await _db.rpc('wheel_admin_report');
      return Map<String, dynamic>.from(r as Map);
    } catch (e) {
      return <String, dynamic>{};
    }
  }

  Future<bool> wishDeliver(int id) async {
    try {
      final dynamic r = await _db
          .rpc('wheel_wish_deliver', params: <String, dynamic>{'wid': id});
      return (r as Map)['ok'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> weightsSet(List<Map<String, dynamic>> rows) async {
    try {
      final dynamic r = await _db
          .rpc('wheel_weights_set', params: <String, dynamic>{'payload': rows});
      return (r as Map)['ok'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> bankAdd(String kind, String title, String path,
      {String? fname, int? bytes, String? mime}) async {
    try {
      final dynamic r = await _db.rpc('wheel_bank_add',
          params: <String, dynamic>{
            'kind': kind,
            'title': title,
            'path': path,
            'fname_in': fname,
            'bytes_in': bytes,
            'mime_in': mime
          });
      return (r as Map)['ok'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> bankSet(List<Map<String, dynamic>> rows) async {
    try {
      final dynamic r = await _db
          .rpc('wheel_bank_set', params: <String, dynamic>{'payload': rows});
      return (r as Map)['ok'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> bankDrop(int id, String kind) async {
    try {
      final dynamic r = await _db.rpc('wheel_bank_drop',
          params: <String, dynamic>{'bid': id, 'kind': kind});
      return (r as Map)['ok'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> windowSet(List<Map<String, dynamic>> rows) async {
    try {
      final dynamic r = await _db
          .rpc('wheel_window_set', params: <String, dynamic>{'payload': rows});
      return (r as Map)['ok'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> giftMint() async {
    try {
      final dynamic r = await _db.rpc('wheel_gift_mint');
      return Map<String, dynamic>.from(r as Map);
    } catch (e) {
      return <String, dynamic>{'ok': false};
    }
  }

  Future<Map<String, dynamic>> giftClaim(String code) async {
    try {
      final dynamic r = await _db
          .rpc('wheel_gift_claim', params: <String, dynamic>{'gcode': code});
      return Map<String, dynamic>.from(r as Map);
    } catch (e) {
      return <String, dynamic>{'ok': false};
    }
  }

  void forget() {
    _stateCache = null;
    _stateUid = '';
    _stateAt = 0;
  }
}

// END OF FILE - lib/services/wheel_service.dart
