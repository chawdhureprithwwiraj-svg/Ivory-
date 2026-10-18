/// ============================================================
/// IVORY - THE IVORY LADDER: WHAT THE DATABASE TELLS THE APP
///
/// Climb points, the rung, every Mark and its progress, the stars and
/// the streak milestones are all worked out by the database. These
/// classes only carry the answer to the screen.
/// ============================================================
int _li(dynamic v, [int d = 0]) => v is num ? v.toInt() : d;

DateTime? _lt(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse('$v')?.toLocal();
}

class LadderRung {
  const LadderRung({required this.n, required this.name, required this.min});

  final int n;
  final String name;
  final int min;

  factory LadderRung.fromMap(Map<String, dynamic> m) => LadderRung(
    n: _li(m['n'], 1),
    name: '${m['name'] ?? ''}',
    min: _li(m['min']),
  );
}

class MarkItem {
  const MarkItem({
    required this.key,
    required this.name,
    required this.blurb,
    required this.rarity,
    required this.glyph,
    required this.target,
    required this.have,
    required this.earned,
    required this.at,
    required this.isNew,
  });

  final String key;
  final String name;
  final String blurb;
  final String rarity;
  final String glyph;
  final int target;
  final int have;
  final bool earned;
  final DateTime? at;
  final bool isNew;

  /// 0 common .. 4 legendary.
  int get rarityIndex {
    const List<String> order = <String>[
      'common',
      'uncommon',
      'rare',
      'epic',
      'legendary',
    ];
    final int i = order.indexOf(rarity);
    return i < 0 ? 0 : i;
  }

  double get fraction =>
      target <= 0 ? 0 : (have / target).clamp(0.0, 1.0).toDouble();

  factory MarkItem.fromMap(Map<String, dynamic> m) => MarkItem(
    key: '${m['key']}',
    name: '${m['name'] ?? ''}',
    blurb: '${m['blurb'] ?? ''}',
    rarity: '${m['rarity'] ?? 'common'}',
    glyph: '${m['glyph'] ?? 'spark'}',
    target: _li(m['target'], 1),
    have: _li(m['have']),
    earned: m['earned'] == true,
    at: _lt(m['at']),
    isNew: m['new'] == true,
  );
}

class LadderMilestone {
  const LadderMilestone({
    required this.kind,
    required this.days,
    required this.isNew,
  });

  /// 'glow' (the heart) or 'peal' (the bells).
  final String kind;
  final int days;
  final bool isNew;

  String get label => kind == 'glow' ? 'glow' : 'Peal';

  factory LadderMilestone.fromMap(Map<String, dynamic> m) => LadderMilestone(
    kind: '${m['kind']}',
    days: _li(m['days']),
    isNew: m['new'] == true,
  );
}

class LadderState {
  const LadderState({
    required this.enabled,
    this.points = 0,
    this.litDays = 0,
    this.stars = 0,
    this.markPoints = 3,
    this.marksEarned = 0,
    this.marksTotal = 0,
    this.rung = const LadderRung(n: 1, name: 'Pearl', min: 0),
    this.next,
    this.rungUp = false,
    this.rungs = const <LadderRung>[],
    this.marks = const <MarkItem>[],
    this.newMarks = const <String>[],
    this.glowNow = 0,
    this.glowBest = 0,
    this.pealNow = 0,
    this.pealBest = 0,
    this.milestoneDays = const <int>[],
    this.milestones = const <LadderMilestone>[],
  });

  final bool enabled;
  final int points;
  final int litDays;
  final int stars;
  final int markPoints;
  final int marksEarned;
  final int marksTotal;
  final LadderRung rung;
  final LadderRung? next;
  final bool rungUp;
  final List<LadderRung> rungs;
  final List<MarkItem> marks;
  final List<String> newMarks;
  final int glowNow;
  final int glowBest;
  final int pealNow;
  final int pealBest;
  final List<int> milestoneDays;
  final List<LadderMilestone> milestones;

  /// Points still needed for the next rung (0 at the top).
  int get need => next == null ? 0 : next!.min - points;

  /// How far between this rung and the next, 0..1.
  double get climb {
    if (next == null) return 1;
    final int span = next!.min - rung.min;
    if (span <= 0) return 1;
    return ((points - rung.min) / span).clamp(0.0, 1.0).toDouble();
  }

  bool get hasNews =>
      newMarks.isNotEmpty || rungUp || milestones.any((m) => m.isNew);

  List<MarkItem> get newMarkItems =>
      marks.where((MarkItem m) => newMarks.contains(m.key)).toList();

  List<LadderMilestone> get newMilestones =>
      milestones.where((LadderMilestone m) => m.isNew).toList();

  bool hasMilestone(String kind, int days) => milestones.any(
    (LadderMilestone m) => m.kind == kind && m.days == days,
  );

  factory LadderState.fromMap(Map<String, dynamic> m) {
    if (m['enabled'] == false) return const LadderState(enabled: false);
    List<T> list<T>(dynamic v, T Function(Map<String, dynamic>) f) => v is List
        ? v.map((dynamic e) => f(Map<String, dynamic>.from(e as Map))).toList()
        : <T>[];
    final Map<String, dynamic> glow = m['glow'] is Map
        ? Map<String, dynamic>.from(m['glow'] as Map)
        : <String, dynamic>{};
    final Map<String, dynamic> peal = m['peal'] is Map
        ? Map<String, dynamic>.from(m['peal'] as Map)
        : <String, dynamic>{};
    return LadderState(
      enabled: true,
      points: _li(m['points']),
      litDays: _li(m['lit_days']),
      stars: _li(m['stars']),
      markPoints: _li(m['mark_points'], 3),
      marksEarned: _li(m['marks_earned']),
      marksTotal: _li(m['marks_total']),
      rung: m['rung'] is Map
          ? LadderRung.fromMap(Map<String, dynamic>.from(m['rung'] as Map))
          : const LadderRung(n: 1, name: 'Pearl', min: 0),
      next: m['next'] is Map
          ? LadderRung.fromMap(Map<String, dynamic>.from(m['next'] as Map))
          : null,
      rungUp: m['rung_up'] == true,
      rungs: list<LadderRung>(m['rungs'], LadderRung.fromMap),
      marks: list<MarkItem>(m['marks'], MarkItem.fromMap),
      newMarks: m['new_marks'] is List
          ? (m['new_marks'] as List).map((dynamic e) => '$e').toList()
          : <String>[],
      glowNow: _li(glow['now']),
      glowBest: _li(glow['best']),
      pealNow: _li(peal['now']),
      pealBest: _li(peal['best']),
      milestoneDays: m['milestone_days'] is List
          ? (m['milestone_days'] as List).map((dynamic e) => _li(e)).toList()
          : <int>[],
      milestones: list<LadderMilestone>(
        m['milestones'],
        LadderMilestone.fromMap,
      ),
    );
  }
}

class LadderDay {
  const LadderDay({required this.day, required this.lit, required this.full});

  final int day;
  final bool lit;
  final bool full;
}

class LadderMonth {
  const LadderMonth({
    required this.year,
    required this.month,
    required this.firstWeekday,
    required this.today,
    required this.days,
  });

  final int year;
  final int month;

  /// 1 = Monday .. 7 = Sunday.
  final int firstWeekday;

  /// The member's "today" key (YYYY-MM-DD) from the database.
  final String today;
  final List<LadderDay> days;

  factory LadderMonth.fromMap(Map<String, dynamic> m) => LadderMonth(
    year: _li(m['year']),
    month: _li(m['month']),
    firstWeekday: _li(m['first_weekday'], 1),
    today: '${m['today'] ?? ''}'.split('T').first,
    days: m['days'] is List
        ? (m['days'] as List).map((dynamic e) {
            final Map<String, dynamic> d = Map<String, dynamic>.from(e as Map);
            return LadderDay(
              day: _li(d['day']),
              lit: d['lit'] == true,
              full: d['full'] == true,
            );
          }).toList()
        : <LadderDay>[],
  );
}

// END OF FILE - lib/models/ladder_models.dart
