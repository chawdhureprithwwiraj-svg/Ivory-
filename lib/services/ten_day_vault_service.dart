import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/vault_models.dart';

/// ============================================================
/// IVORY - THE TEN-DAY VAULT, THE ONLY DOOR TO THE DATABASE
///
/// The day, the order, the clock, the scoring, the rupees and the
/// reveal on the last day are all decided by the database. This
/// class only asks and listens.
/// ============================================================
class TenDayVaultService {
  TenDayVaultService._();
  static final TenDayVaultService instance = TenDayVaultService._();

  SupabaseClient get _db => Supabase.instance.client;

  Map<String, dynamic> _map(dynamic v) => Map<String, dynamic>.from(v as Map);

  Future<VaultState> homeState() async {
    final dynamic r = await _db.rpc('vault_home_state');
    return VaultState.fromMap(_map(r));
  }

  /// Begins a new vault (or returns today's key if one is running).
  Future<VaultQuestion> start() async {
    final dynamic r = await _db.rpc('vault_start');
    return VaultQuestion.fromMap(_map(r));
  }

  /// Opens today's key: the question and its clock.
  Future<VaultQuestion> openKey() async {
    final dynamic r = await _db.rpc('vault_open_key');
    return VaultQuestion.fromMap(_map(r));
  }

  /// [choice] is the position on screen (0 to 3), or -1 when time ran out.
  Future<VaultSealed> answer({
    required int runId,
    required int questionId,
    required int choice,
  }) async {
    final dynamic r = await _db.rpc(
      'vault_answer',
      params: <String, dynamic>{
        'run_id_in': runId,
        'question_id_in': questionId,
        'choice_in': choice,
      },
    );
    return VaultSealed.fromMap(_map(r));
  }

  /// Only works once the last key has turned.
  Future<VaultResult> result([int? runId]) async {
    final dynamic r = await _db.rpc(
      'vault_result',
      params: <String, dynamic>{'run_id_in': runId},
    );
    return VaultResult.fromMap(_map(r));
  }

  Future<void> markSeen(int runId) async {
    try {
      await _db.rpc(
        'vault_mark_seen',
        params: <String, dynamic>{'run_id_in': runId},
      );
    } catch (_) {}
  }

  // ------------------------------------------------------------ admin

  Future<Map<String, dynamic>> adminSummary() async {
    final dynamic r = await _db.rpc('vault_admin_summary');
    return _map(r);
  }

  Future<void> rehearsalNextDay() async {
    await _db.rpc('vault_rehearsal_next_day');
  }

  Future<void> rehearsalReset() async {
    await _db.rpc('vault_rehearsal_reset');
  }
}

// END OF FILE - lib/services/ten_day_vault_service.dart
