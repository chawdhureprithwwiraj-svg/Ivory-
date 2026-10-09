/// ============================================================
/// IVORY - ONE NIGHT ON THE RECORD.
///
/// Every field here is a fact the database actually holds.
/// Nothing is estimated and nothing is filled in to look
/// better.
///
/// `tracked` IS THE IMPORTANT ONE. Ivory did not record who was
/// in a broadcast until sprint 31, so for every night before
/// that there is simply no answer. When `tracked` is false the
/// screen must say NOTHING about attendance - not "you were
/// there", not "you missed this one", not a count. A member who
/// watched an hour in silence left no trace, and telling them
/// they missed it would be a lie told by a rounding error.
/// ============================================================
class LiveNight {
  const LiveNight({
    required this.id,
    required this.title,
    required this.startedAt,
    this.minutes,
    this.membersThere = 0,
    this.tracked = false,
    this.youWereThere = false,
  });

  final int id;
  final String title;
  final DateTime? startedAt;

  /// Real wall-clock length. Null when a broadcast never
  /// properly ended, which is a real thing that happens and is
  /// shown honestly rather than guessed at.
  final int? minutes;

  final int membersThere;
  final bool tracked;
  final bool youWereThere;

  factory LiveNight.fromDb(Map<String, dynamic> m) => LiveNight(
        id: ((m['id'] as num?) ?? 0).toInt(),
        title: (m['title'] as String?) ?? 'A broadcast',
        startedAt: DateTime.tryParse((m['started_at'] as String?) ?? ''),
        minutes: (m['minutes'] as num?)?.toInt(),
        membersThere: ((m['members_there'] as num?) ?? 0).toInt(),
        tracked: (m['tracked'] as bool?) ?? false,
        youWereThere: (m['you_were_there'] as bool?) ?? false,
      );
}

// END OF FILE - lib/models/live_night.dart
