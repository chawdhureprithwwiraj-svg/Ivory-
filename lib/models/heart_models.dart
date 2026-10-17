/// ============================================================
/// IVORY - THE GOLDEN HEART: WHAT THE DATABASE TELLS THE APP
///
/// Points, the lit line, the glow, the mends and the day turning
/// over are all decided by the database. These classes only carry
/// the answer to the screen.
/// ============================================================
int _i(dynamic v, [int d = 0]) => v is num ? v.toInt() : d;

class HeartAction {
  const HeartAction({
    required this.key,
    required this.label,
    required this.points,
    required this.cap,
    required this.done,
  });

  final String key;
  final String label;
  final int points;
  final int cap;
  final int done;

  bool get complete => done >= cap;

  factory HeartAction.fromMap(Map<String, dynamic> m) => HeartAction(
    key: '${m['key'] ?? ''}',
    label: '${m['label'] ?? ''}',
    points: _i(m['points']),
    cap: _i(m['cap'], 1),
    done: _i(m['done']),
  );
}

class HeartDay {
  const HeartDay({required this.day, required this.lit, required this.points});

  final String day;
  final bool lit;
  final int points;

  factory HeartDay.fromMap(Map<String, dynamic> m) => HeartDay(
    day: '${m['day'] ?? ''}',
    lit: m['lit'] == true,
    points: _i(m['points']),
  );
}

class HeartState {
  const HeartState({
    required this.state,
    this.litPoints = 60,
    this.points = 0,
    this.lit = false,
    this.streak = 0,
    this.bestStreak = 0,
    this.totalLit = 0,
    this.mends = 0,
    this.mendMax = 2,
    this.mendEvery = 7,
    this.mendProgress = 0,
    this.mendedToday = false,
    this.mendedN = 0,
    this.atRisk = false,
    this.tierName,
    this.tierIdx = 0,
    this.nextTierName,
    this.nextTierDays,
    this.actions = const <HeartAction>[],
    this.week = const <HeartDay>[],
    this.nextDayAt,
    this.justLit = false,
  });

  /// 'open', 'closed' or 'signed_out'.
  final String state;
  final int litPoints;
  final int points;
  final bool lit;
  final int streak;
  final int bestStreak;
  final int totalLit;
  final int mends;
  final int mendMax;
  final int mendEvery;
  final int mendProgress;
  final bool mendedToday;
  final int mendedN;
  final bool atRisk;
  final String? tierName;
  final int tierIdx;
  final String? nextTierName;
  final int? nextTierDays;
  final List<HeartAction> actions;
  final List<HeartDay> week;
  final DateTime? nextDayAt;
  final bool justLit;

  bool get isOpen => state == 'open';

  /// How full the heart is, 0 to 1.
  double get fill =>
      lit ? 1.0 : (litPoints <= 0 ? 0.0 : (points / litPoints).clamp(0.0, 1.0));

  HeartAction? action(String key) {
    for (final HeartAction a in actions) {
      if (a.key == key) return a;
    }
    return null;
  }

  factory HeartState.fromMap(Map<String, dynamic> m) {
    List<T> list<T>(dynamic v, T Function(Map<String, dynamic>) f) {
      if (v is! List) return <T>[];
      return v
          .map((dynamic e) => f(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    return HeartState(
      state: '${m['state'] ?? 'closed'}',
      litPoints: _i(m['lit_points'], 60),
      points: _i(m['points']),
      lit: m['lit'] == true,
      streak: _i(m['streak']),
      bestStreak: _i(m['best_streak']),
      totalLit: _i(m['total_lit']),
      mends: _i(m['mends']),
      mendMax: _i(m['mend_max'], 2),
      mendEvery: _i(m['mend_every'], 7),
      mendProgress: _i(m['mend_progress']),
      mendedToday: m['mended_today'] == true,
      mendedN: _i(m['mended_n']),
      atRisk: m['at_risk'] == true,
      tierName: m['tier_name'] as String?,
      tierIdx: _i(m['tier_idx']),
      nextTierName: m['next_tier_name'] as String?,
      nextTierDays: m['next_tier_days'] == null
          ? null
          : _i(m['next_tier_days']),
      actions: list<HeartAction>(m['actions'], HeartAction.fromMap),
      week: list<HeartDay>(m['week'], HeartDay.fromMap),
      nextDayAt: m['next_day_at'] == null
          ? null
          : DateTime.tryParse('${m['next_day_at']}')?.toLocal(),
      justLit: m['just_lit'] == true,
    );
  }
}

// END OF FILE - lib/models/heart_models.dart
