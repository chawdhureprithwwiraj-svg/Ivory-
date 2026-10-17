/// ============================================================
/// IVORY - THE GOLDEN KNOCK-OFF: what the house tells the app.
///
/// Every number here arrives from the database. The app never
/// scores an answer, never draws a rupee and never decides when
/// gold fades - it only draws what it is told.
/// ============================================================

enum GoldenPhase {
  signedOut,
  closed,
  ready,
  playing,
  gold,
  cooling,
  dust,
  paid,
}

int _i(dynamic v) => ((v as num?) ?? 0).toInt();

DateTime? _dt(dynamic v) => DateTime.tryParse((v as String?) ?? '');

/// How far the house clock is from this phone's clock, so a
/// countdown is honest even when the phone's time is wrong.
Duration _skew(dynamic serverNow) {
  final DateTime? s = _dt(serverNow);
  return s == null ? Duration.zero : s.difference(DateTime.now());
}

class GoldenState {
  const GoldenState({
    required this.phase,
    this.rehearsal = false,
    this.creditId = 0,
    this.creditInr = 0,
    this.reserved = false,
    this.expiresAt,
    this.nextOpenAt,
    this.seals = 0,
    this.sealTotal = 10,
    this.maxPerAnswer = 100,
    this.maxBonus = 0,
    this.typicalMin = 0,
    this.typicalMax = 0,
    this.cooldownDays = 20,
    this.creditHours = 6,
    this.questionSeconds = 30,
    this.position = 1,
    this.total = 10,
    this.runningInr = 0,
    this.lastScore = 0,
    this.lastInr = 0,
    this.skew = Duration.zero,
  });

  final GoldenPhase phase;
  final bool rehearsal;
  final int creditId;
  final int creditInr;
  final bool reserved;
  final DateTime? expiresAt;
  final DateTime? nextOpenAt;
  final int seals;
  final int sealTotal;
  final int maxPerAnswer;
  final int maxBonus;
  final int typicalMin;
  final int typicalMax;
  final int cooldownDays;
  final int creditHours;
  final int questionSeconds;
  final int position;
  final int total;
  final int runningInr;
  final int lastScore;
  final int lastInr;
  final Duration skew;

  DateTime get now => DateTime.now().add(skew);

  Duration get untilExpiry =>
      expiresAt == null ? Duration.zero : expiresAt!.difference(now);

  Duration get untilOpen =>
      nextOpenAt == null ? Duration.zero : nextOpenAt!.difference(now);

  factory GoldenState.fromMap(Map<String, dynamic> m) {
    final String s = (m['state'] as String?) ?? 'signed_out';
    final GoldenPhase p = switch (s) {
      'closed' => GoldenPhase.closed,
      'ready' => GoldenPhase.ready,
      'playing' => GoldenPhase.playing,
      'gold' => GoldenPhase.gold,
      'cooling' => GoldenPhase.cooling,
      'dust' => GoldenPhase.dust,
      'paid' => GoldenPhase.paid,
      _ => GoldenPhase.signedOut,
    };
    return GoldenState(
      phase: p,
      rehearsal: m['rehearsal'] == true,
      creditId: _i(m['credit_id']),
      creditInr: _i(m['credit_inr']),
      reserved: m['reserved'] == true,
      expiresAt: _dt(m['expires_at']),
      nextOpenAt: _dt(m['next_open_at']),
      seals: _i(m['seals']),
      sealTotal: _i(m['seal_total']) == 0 ? 10 : _i(m['seal_total']),
      maxPerAnswer: _i(m['max_per_answer']),
      maxBonus: _i(m['max_bonus']),
      typicalMin: _i(m['typical_min']),
      typicalMax: _i(m['typical_max']),
      cooldownDays: _i(m['cooldown_days']),
      creditHours: _i(m['credit_hours']),
      questionSeconds: _i(m['question_seconds']) == 0
          ? 30
          : _i(m['question_seconds']),
      position: _i(m['position']),
      total: _i(m['total']) == 0 ? 10 : _i(m['total']),
      runningInr: _i(m['running_inr']),
      lastScore: _i(m['last_score']),
      lastInr: _i(m['last_inr']),
      skew: _skew(m['server_now']),
    );
  }
}

class GoldenQuestion {
  const GoldenQuestion({
    required this.attemptId,
    required this.position,
    required this.total,
    required this.questionId,
    required this.text,
    required this.options,
    required this.secondsLeft,
    required this.runningInr,
  });

  final int attemptId;
  final int position;
  final int total;
  final int questionId;
  final String text;
  final List<String> options;
  final int secondsLeft;
  final int runningInr;

  factory GoldenQuestion.fromMap(Map<String, dynamic> m) => GoldenQuestion(
    attemptId: _i(m['attempt_id']),
    position: _i(m['position']),
    total: _i(m['total']),
    questionId: _i(m['question_id']),
    text: (m['question'] as String?) ?? '',
    options: ((m['options'] as List<dynamic>?) ?? <dynamic>[])
        .map((dynamic o) => o.toString())
        .toList(),
    secondsLeft: _i(m['seconds_left']),
    runningInr: _i(m['running_inr']),
  );
}

class GoldenStart {
  const GoldenStart({
    required this.topicTitle,
    required this.tagline,
    required this.rehearsal,
    required this.resumed,
    required this.first,
  });

  final String topicTitle;
  final String tagline;
  final bool rehearsal;
  final bool resumed;
  final GoldenQuestion first;

  factory GoldenStart.fromMap(Map<String, dynamic> m) => GoldenStart(
    topicTitle: (m['topic_title'] as String?) ?? '',
    tagline: (m['topic_tagline'] as String?) ?? '',
    rehearsal: m['rehearsal'] == true,
    resumed: m['resumed'] == true,
    first: GoldenQuestion.fromMap(Map<String, dynamic>.from(m['next'] as Map)),
  );
}

class GoldenSummary {
  const GoldenSummary({
    required this.score,
    required this.questions,
    required this.answersInr,
    required this.bonusInr,
    required this.totalInr,
    required this.rehearsal,
    this.expiresAt,
    this.skew = Duration.zero,
  });

  final int score;
  final int questions;
  final int answersInr;
  final int bonusInr;
  final int totalInr;
  final bool rehearsal;
  final DateTime? expiresAt;
  final Duration skew;

  bool get perfect => questions > 0 && score == questions;

  Duration get untilExpiry => expiresAt == null
      ? Duration.zero
      : expiresAt!.difference(DateTime.now().add(skew));

  /// The title earned, from the score.
  String get rank {
    if (perfect) return 'IVORY SAGE';
    if (score >= 7) return 'STORYTELLER';
    if (score >= 4) return 'KEEPER';
    return 'THE CURIOUS';
  }

  factory GoldenSummary.fromMap(Map<String, dynamic> m) => GoldenSummary(
    score: _i(m['score']),
    questions: _i(m['questions']),
    answersInr: _i(m['answers_inr']),
    bonusInr: _i(m['bonus_inr']),
    totalInr: _i(m['total_inr']),
    rehearsal: m['rehearsal'] == true,
    expiresAt: _dt(m['expires_at']),
    skew: _skew(m['server_now']),
  );
}

class GoldenAnswer {
  const GoldenAnswer({
    required this.correct,
    required this.correctIdx,
    required this.fact,
    required this.amountInr,
    required this.golden,
    required this.runningInr,
    required this.finished,
    this.next,
    this.summary,
  });

  final bool correct;
  final int correctIdx;
  final String fact;
  final int amountInr;
  final bool golden;
  final int runningInr;
  final bool finished;
  final GoldenQuestion? next;
  final GoldenSummary? summary;

  factory GoldenAnswer.fromMap(Map<String, dynamic> m) {
    // A late answer comes back as a bare summary.
    if (m['late'] == true || !m.containsKey('correct')) {
      return GoldenAnswer(
        correct: false,
        correctIdx: -1,
        fact: '',
        amountInr: 0,
        golden: false,
        runningInr: 0,
        finished: true,
        summary: GoldenSummary.fromMap(m),
      );
    }
    final dynamic n = m['next'];
    final dynamic s = m['summary'];
    return GoldenAnswer(
      correct: m['correct'] == true,
      correctIdx: _i(m['correct_idx']),
      fact: (m['fact'] as String?) ?? '',
      amountInr: _i(m['amount_inr']),
      golden: m['golden'] == true,
      runningInr: _i(m['running_inr']),
      finished: m['finished'] == true,
      next: n is Map
          ? GoldenQuestion.fromMap(Map<String, dynamic>.from(n))
          : null,
      summary: s is Map
          ? GoldenSummary.fromMap(Map<String, dynamic>.from(s))
          : null,
    );
  }
}

/// A Golden Knock-off a member can spend right now.
class GoldenCredit {
  const GoldenCredit({
    required this.id,
    required this.amountInr,
    required this.expiresAt,
    this.skew = Duration.zero,
  });

  final int id;
  final int amountInr;
  final DateTime expiresAt;
  final Duration skew;

  Duration get untilExpiry => expiresAt.difference(DateTime.now().add(skew));

  static GoldenCredit? fromMap(Map<String, dynamic>? m) {
    if (m == null) return null;
    final DateTime? e = _dt(m['expires_at']);
    if (e == null) return null;
    return GoldenCredit(
      id: _i(m['credit_id']),
      amountInr: _i(m['amount_inr']),
      expiresAt: e,
      skew: _skew(m['server_now']),
    );
  }
}

// END OF FILE - lib/models/quiz_models.dart
