import 'package:supabase_flutter/supabase_flutter.dart';

/// ============================================================
/// IVORY - HOW IVORY SPEAKS WHEN SOMETHING GOES WRONG
///
/// A member must never meet a database. No "PostgresException",
/// no "P0001", no "42703" - those are our problems, not theirs.
///
/// Two voices live here:
///
///   houseMessage(e)  what a MEMBER is allowed to read. Warm,
///                    short, never technical, never alarming.
///
///   adminDetail(e)   what the HOUSE is allowed to read, in the
///                    admin console only. Precise and complete,
///                    because Ivory is the one who has to fix it.
///
/// Rule: every catch block in the app uses one of these two.
/// Never `'$e'` straight into a toast again.
/// ============================================================

/// The member-facing voice. Always safe to show to anyone.
String houseMessage(Object? e) {
  if (e == null) return 'Something did not go through. Please try again.';

  // Messages Ivory wrote herself in Postgres are already kind and
  // already in her voice - those we keep, they are meant to be read.
  if (e is PostgresException) {
    final String m = e.message.trim();
    final bool ours = e.code == 'P0001' && m.isNotEmpty && !_looksTechnical(m);
    if (ours) return m;
    return 'That did not go through. Nothing was lost - please try again '
        'in a moment.';
  }

  if (e is AuthException) {
    return 'Your sign-in has expired. Please sign in again.';
  }

  if (e is FunctionException) {
    return 'That did not go through. Nothing was lost - please try again '
        'in a moment.';
  }

  if (e is StorageException) {
    return 'The file did not make it across. Please try again.';
  }

  final String s = e.toString();
  if (_isNetwork(s)) {
    return 'Ivory could not reach the house. Check your connection and '
        'try again.';
  }
  return 'That did not go through. Nothing was lost - please try again '
      'in a moment.';
}

/// The house-facing voice. Admin console only - never a member screen.
/// Says exactly what broke so it can actually be fixed.
String adminDetail(Object? e) {
  if (e == null) return 'Unknown error.';

  if (e is PostgresException) {
    final StringBuffer b = StringBuffer(e.message.trim());
    if (e.code != null) b.write('  [${e.code}]');
    if (e.details != null) b.write('\n${e.details}');
    if (e.hint != null) b.write('\nHint: ${e.hint}');
    return b.toString();
  }

  if (e is FunctionException) {
    final StringBuffer b = StringBuffer('Edge function failed');
    b.write(' (HTTP ${e.status})');
    final Object? d = e.details;
    if (d != null) {
      final String t = d.toString().trim();
      if (t.isNotEmpty && t != 'null') b.write(': $t');
    }
    final String? r = e.reasonPhrase;
    if (r != null && r.trim().isNotEmpty) b.write(' - $r');
    return b.toString();
  }

  if (e is StorageException) {
    return 'Storage refused it: ${e.message}'
        '${e.statusCode == null ? '' : '  [${e.statusCode}]'}';
  }

  if (e is AuthException) return 'Auth: ${e.message}';

  final String s = e.toString().replaceFirst('Exception: ', '').trim();
  if (_isNetwork(s)) return 'Could not reach the network. $s';
  return s.isEmpty ? e.runtimeType.toString() : s;
}

/// True when a database message is clearly machinery rather than
/// something Ivory wrote for a member to read.
bool _looksTechnical(String m) {
  final String s = m.toLowerCase();
  return s.contains('does not exist') ||
      s.contains('violates') ||
      s.contains('duplicate key') ||
      s.contains('null value') ||
      s.contains('permission denied') ||
      s.contains('relation ') ||
      s.contains('column ') ||
      s.contains('function ') ||
      s.contains('syntax');
}

bool _isNetwork(String s) {
  final String t = s.toLowerCase();
  return t.contains('socketexception') ||
      t.contains('failed host lookup') ||
      t.contains('connection closed') ||
      t.contains('connection refused') ||
      t.contains('clientexception') ||
      t.contains('timeoutexception') ||
      t.contains('handshake');
}

// END OF FILE - lib/core/ivory_errors.dart
