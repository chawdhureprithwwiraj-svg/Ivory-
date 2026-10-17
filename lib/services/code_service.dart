import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/ivory_errors.dart';
import '../models/discount_models.dart';
import 'payment_service.dart';

/// ============================================================
/// IVORY - DISCOUNT CODES, THE ONLY DOOR TO THE DATABASE
///
/// The phone never decides a price. [quote] asks the house what a
/// code takes off; the house asks again when the order is made.
/// ============================================================
class CodeService {
  CodeService._();
  static final CodeService instance = CodeService._();

  SupabaseClient get _db => Supabase.instance.client;

  Map<String, dynamic> _map(dynamic v) => Map<String, dynamic>.from(v as Map);

  /// What [code] would take off the tier. Throws a kind sentence.
  Future<CodeQuote> quote(int tierId, String code) async {
    final dynamic r = await _db.rpc(
      'code_quote',
      params: <String, dynamic>{'tier_id_in': tierId, 'code_in': code},
    );
    return CodeQuote.fromMap(_map(r));
  }

  /// The member's own one-time codes that can still be used.
  Future<List<PrizeCode>> myPrizes() async {
    try {
      final dynamic r = await _db.rpc('code_my_prizes');
      if (r is! List) return <PrizeCode>[];
      return r.map((dynamic e) => PrizeCode.fromMap(_map(e))).toList();
    } catch (_) {
      return <PrizeCode>[];
    }
  }

  /// A UPI payment with a code taken off. The database re-checks the
  /// code, the tier and the amount.
  Future<int> submitWithCode({
    required int tierId,
    required String utr,
    required String code,
    String? screenshotPath,
  }) async {
    final dynamic id = await _db.rpc(
      'code_submit_payment',
      params: <String, dynamic>{
        'tier_id_in': tierId,
        'utr_in': utr,
        'screenshot_url_in': screenshotPath,
        'code_in': code,
      },
    );
    return (id as num).toInt();
  }

  /// A payment error in the house voice. Sentences about the code were
  /// written in Postgres and are already kind; the rest use the
  /// payment wording.
  String payError(Object e) {
    if (e is PostgrestException && e.message.contains('code')) {
      return houseMessage(e);
    }
    return PaymentService.friendly(e);
  }

  // ------------------------------------------------------------ admin

  Future<List<Map<String, dynamic>>> adminCodes() async {
    final dynamic r = await _db.rpc('code_admin_list');
    if (r is! List) return <Map<String, dynamic>>[];
    return r.map(_map).toList();
  }

  /// The membership tiers, for the "only these tiers" choice.
  Future<List<Map<String, dynamic>>> adminTiers() async {
    final List<dynamic> r = await _db
        .from('subscription_tiers')
        .select('id, name, level')
        .order('level', ascending: true);
    return r.map(_map).toList();
  }

  Future<Map<String, dynamic>> adminSummary() async {
    final dynamic r = await _db.rpc('code_admin_summary');
    return _map(r);
  }

  /// Creates a code (id null) or changes one. Codes are never deleted:
  /// switch one off instead.
  Future<void> adminSave(int? id, Map<String, dynamic> v) async {
    if (id == null) {
      await _db.from('discount_codes').insert(v);
    } else {
      await _db.from('discount_codes').update(v).eq('id', id);
    }
  }
}

// END OF FILE - lib/services/code_service.dart
