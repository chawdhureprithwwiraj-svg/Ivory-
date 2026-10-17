import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/ivory_errors.dart';
import '../models/quiz_models.dart';
import 'payment_service.dart';

/// ============================================================
/// IVORY - THE GOLDEN KNOCK-OFF, THE ONLY DOOR TO THE DATABASE
///
/// Everything that matters - topic, order, timer, scoring, the
/// random rupees, the 6-hour fade - is decided by the database.
/// This class only asks and listens.
/// ============================================================
class QuizService {
  QuizService._();
  static final QuizService instance = QuizService._();

  SupabaseClient get _db => Supabase.instance.client;

  Map<String, dynamic> _map(dynamic v) => Map<String, dynamic>.from(v as Map);

  Future<GoldenState> homeState() async {
    final dynamic r = await _db.rpc('quiz_home_state');
    return GoldenState.fromMap(_map(r));
  }

  /// Opens a quiz (or resumes the open one).
  Future<GoldenStart> start() async {
    final dynamic r = await _db.rpc('quiz_start');
    return GoldenStart.fromMap(_map(r));
  }

  /// Null when there is no open quiz to resume.
  Future<GoldenStart?> resume() async {
    final dynamic r = await _db.rpc('quiz_resume');
    return r == null ? null : GoldenStart.fromMap(_map(r));
  }

  /// [choice] is the position on screen (0 to 3), or -1 when time ran out.
  Future<GoldenAnswer> answer({
    required int attemptId,
    required int questionId,
    required int choice,
  }) async {
    final dynamic r = await _db.rpc(
      'quiz_answer',
      params: <String, dynamic>{
        'attempt_id_in': attemptId,
        'question_id_in': questionId,
        'choice_in': choice,
      },
    );
    return GoldenAnswer.fromMap(_map(r));
  }

  /// The credit this member can spend now, or null.
  Future<GoldenCredit?> myCredit() async {
    try {
      final dynamic r = await _db.rpc('quiz_my_credit');
      return r == null ? null : GoldenCredit.fromMap(_map(r));
    } catch (_) {
      return null;
    }
  }

  /// A UPI payment with the Golden Knock-off taken off. The database
  /// re-checks the credit, the tier and the amount.
  Future<int> submitWithCredit({
    required int tierId,
    required String utr,
    required int creditId,
    String? screenshotPath,
  }) async {
    final dynamic id = await _db.rpc(
      'quiz_submit_payment',
      params: <String, dynamic>{
        'tier_id_in': tierId,
        'utr_in': utr,
        'screenshot_url_in': screenshotPath,
        'credit_id_in': creditId,
      },
    );
    return (id as num).toInt();
  }

  /// A payment error, in the house voice. Discount sentences written in
  /// Postgres are already kind; anything else uses the payment wording.
  String payError(Object e) {
    if (e is PostgrestException &&
        (e.message.contains('Golden Knock-off') ||
            e.message.contains('Golden Discount'))) {
      return houseMessage(e);
    }
    return PaymentService.friendly(e);
  }

  // ------------------------------------------------------------ admin

  Future<Map<String, dynamic>> adminSummary() async {
    final dynamic r = await _db.rpc('quiz_admin_summary');
    return _map(r);
  }

  Future<Map<String, dynamic>> adminSettings() async {
    final dynamic r = await _db
        .from('quiz_settings')
        .select()
        .eq('id', 1)
        .single();
    return _map(r);
  }

  Future<void> adminSaveSettings(Map<String, dynamic> values) async {
    final Map<String, dynamic> v = <String, dynamic>{
      ...values,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    await _db.from('quiz_settings').update(v).eq('id', 1);
  }
}

// END OF FILE - lib/services/quiz_service.dart
