import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/l10n.dart';

/// ============================================================
/// IVORY - QUIZ AND VAULT QUESTIONS IN THE MEMBER'S LANGUAGE
///
/// The database keeps a translated twin of each quiz function whose name ends
/// in _l (quiz_start_l, quiz_answer_l ...). It runs the very same function and
/// then swaps the question, the four answers and the fact for the member's
/// language, in the same trip, so the clock is not affected.
///
/// English members, and any phone whose database does not have the twin yet,
/// use the original function exactly as before.
/// ============================================================
Future<dynamic> quizRpc(String name, {Map<String, dynamic>? params}) async {
  final SupabaseClient db = Supabase.instance.client;
  if (L10n.instance.code == 'en') {
    return db.rpc<dynamic>(name, params: params);
  }
  try {
    return await db.rpc<dynamic>('${name}_l', params: params);
  } on PostgrestException catch (e) {
    final String c = e.code ?? '';
    final bool missing = c == 'PGRST202' || c == '42883' || c == '404';
    if (!missing) rethrow;
    return db.rpc<dynamic>(name, params: params);
  }
}

// END OF FILE - lib/services/quiz_rpc.dart
