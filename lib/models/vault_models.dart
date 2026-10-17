import 'quiz_models.dart';

/// ============================================================
/// IVORY - THE TEN-DAY VAULT: what the house tells the app.
///
/// Every number here arrives from the database. The app never
/// scores an answer, never decides which day it is and never
/// learns a right answer before the last key is turned: until
/// then the database simply does not send it.
/// ============================================================

enum VaultPhase {
  signedOut,
  closed,
  locked,
  ready,
  open,
  sealed,
  ceremony,
  resting,
}

int _n(dynamic v) => ((v as num?) ?? 0).toInt();

DateTime? _when(dynamic v) => DateTime.tryParse((v as String?) ?? '');

Duration _drift(dynamic serverNow) {
  final DateTime? s = _when(serverNow);
  return s == null ? Duration.zero : s.difference(DateTime.now());
}

const List<String> _words = <String>[
  '',
  'ONE',
  'TWO',
  'THREE',
  'FOUR',
  'FIVE',
  'SIX',
  'SEVEN',
  'EIGHT',
  'NINE',
  'TEN',
  'ELEVEN',
  'TWELVE',
  'THIRTEEN',
  'FOURTEEN',
  'FIFTEEN',
  'SIXTEEN',
  'SEVENTEEN',
  'EIGHTEEN',
  'NINETEEN',
  'TWENTY',
];

/// 10 -> "TEN". Beyond twenty the plain number is used.
String vaultWord(int n) => n >= 1 && n < _words.length ? _words[n] : '$n';

/// 4 -> "4 AM", 16 -> "4 PM".
String vaultHour(int h) {
  if (h == 0) return '12 AM';
  if (h < 12) return '$h AM';
  if (h == 12) return '12 PM';
  return '${h - 12} PM';
}

const List<String> _months = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// "6 Nov", in the phone's own time zone.
String vaultDate(DateTime d) {
  final DateTime l = d.toLocal();
  return '${l.day} ${_months[l.month - 1]}';
}

class VaultState {
  const VaultState({
    required this.phase,
    this.rehearsal = false,
    this.days = 10,
    this.gapHours = 6,
    this.creditHours = 6,
    this.questionSeconds = 30,
    this.renewDays = 10,
    this.dayStartHour = 4,
    this.runsDone = 0,
    this.maxPerAnswer = 100,
    this.maxBonus = 0,
    this.runId = 0,
    this.dayNo = 1,
    this.answered = 0,
    this.inProgress = false,
    this.nextOpensAt,
    this.nextStartAt,
    this.unlockAt,
    this.lastStatus = '',
    this.lastReason = '',
    this.lastAnswered = 0,
    this.skew = Duration.zero,
  });

  final VaultPhase phase;
  final bool rehearsal;
  final int days;
  final int gapHours;
  final int creditHours;
  final int questionSeconds;
  final int renewDays;
  final int dayStartHour;
  final int runsDone;
  final int maxPerAnswer;
  final int maxBonus;
  final int runId;
  final int dayNo;
  final int answered;
  final bool inProgress;
  final DateTime? nextOpensAt;
  final DateTime? nextStartAt;
  final DateTime? unlockAt;
  final String lastStatus;
  final String lastReason;
  final int lastAnswered;
  final Duration skew;

  DateTime get now => DateTime.now().add(skew);

  Duration get untilNextDay =>
      nextOpensAt == null ? Duration.zero : nextOpensAt!.difference(now);

  Duration get untilNextRun =>
      nextStartAt == null ? Duration.zero : nextStartAt!.difference(now);

  factory VaultState.fromMap(Map<String, dynamic> m) {
    final String s = (m['state'] as String?) ?? 'signed_out';
    final VaultPhase p = switch (s) {
      'closed' => VaultPhase.closed,
      'locked' => VaultPhase.locked,
      'ready' => VaultPhase.ready,
      'open' => VaultPhase.open,
      'sealed' => VaultPhase.sealed,
      'ceremony' => VaultPhase.ceremony,
      'resting' => VaultPhase.resting,
      _ => VaultPhase.signedOut,
    };
    return VaultState(
      phase: p,
      rehearsal: m['rehearsal'] == true,
      days: _n(m['days']) == 0 ? 10 : _n(m['days']),
      gapHours: _n(m['gap_hours']),
      creditHours: _n(m['credit_hours']),
      questionSeconds: _n(m['question_seconds']) == 0
          ? 30
          : _n(m['question_seconds']),
      renewDays: _n(m['renew_days']),
      dayStartHour: _n(m['day_start_hour']),
      runsDone: _n(m['runs_done']),
      maxPerAnswer: _n(m['max_per_answer']),
      maxBonus: _n(m['max_bonus']),
      runId: _n(m['run_id']),
      dayNo: _n(m['day_no']) == 0 ? 1 : _n(m['day_no']),
      answered: _n(m['answered']),
      inProgress: m['in_progress'] == true,
      nextOpensAt: _when(m['next_opens_at']),
      nextStartAt: _when(m['next_start_at']),
      unlockAt: _when(m['unlock_at']),
      lastStatus: (m['last_status'] as String?) ?? '',
      lastReason: (m['last_reason'] as String?) ?? '',
      lastAnswered: _n(m['last_answered']),
      skew: _drift(m['server_now']),
    );
  }
}

/// Today's key: one question, no answer inside.
class VaultQuestion {
  const VaultQuestion({
    required this.runId,
    required this.dayNo,
    required this.days,
    required this.questionId,
    required this.text,
    required this.options,
    required this.secondsLeft,
    required this.tagline,
    required this.rehearsal,
  });

  final int runId;
  final int dayNo;
  final int days;
  final int questionId;
  final String text;
  final List<String> options;
  final int secondsLeft;
  final String tagline;
  final bool rehearsal;

  factory VaultQuestion.fromMap(Map<String, dynamic> m) => VaultQuestion(
    runId: _n(m['run_id']),
    dayNo: _n(m['day_no']),
    days: _n(m['days']),
    questionId: _n(m['question_id']),
    text: (m['question'] as String?) ?? '',
    options: ((m['options'] as List<dynamic>?) ?? <dynamic>[])
        .map((dynamic o) => o.toString())
        .toList(),
    secondsLeft: _n(m['seconds_left']),
    tagline: (m['tagline'] as String?) ?? '',
    rehearsal: m['rehearsal'] == true,
  );
}

/// The answer to one day: sealed. It says only that the key turned.
class VaultSealed {
  const VaultSealed({
    required this.finished,
    required this.runId,
    required this.days,
    required this.answered,
  });

  final bool finished;
  final int runId;
  final int days;
  final int answered;

  factory VaultSealed.fromMap(Map<String, dynamic> m) => VaultSealed(
    finished: m['finished'] == true,
    runId: _n(m['run_id']),
    days: _n(m['days']),
    answered: _n(m['answered']),
  );
}

/// One day of the opened vault.
class VaultDay {
  const VaultDay({
    required this.day,
    required this.question,
    required this.options,
    required this.chosen,
    required this.correctIdx,
    required this.correct,
    required this.amountInr,
    required this.golden,
    required this.fact,
  });

  final int day;
  final String question;
  final List<String> options;
  final int chosen;
  final int correctIdx;
  final bool correct;
  final int amountInr;
  final bool golden;
  final String fact;

  factory VaultDay.fromMap(Map<String, dynamic> m) => VaultDay(
    day: _n(m['day']),
    question: (m['question'] as String?) ?? '',
    options: ((m['options'] as List<dynamic>?) ?? <dynamic>[])
        .map((dynamic o) => o.toString())
        .toList(),
    chosen: _n(m['chosen']),
    correctIdx: _n(m['correct_idx']),
    correct: m['correct'] == true,
    amountInr: _n(m['amount_inr']),
    golden: m['golden'] == true,
    fact: (m['fact'] as String?) ?? '',
  );
}

/// The whole vault, opened on the last day.
class VaultResult {
  const VaultResult({
    required this.runId,
    required this.score,
    required this.days,
    required this.answersInr,
    required this.bonusInr,
    required this.totalInr,
    required this.rehearsal,
    required this.review,
    this.expiresAt,
    this.skew = Duration.zero,
  });

  final int runId;
  final int score;
  final int days;
  final int answersInr;
  final int bonusInr;
  final int totalInr;
  final bool rehearsal;
  final List<VaultDay> review;
  final DateTime? expiresAt;
  final Duration skew;

  /// The same shape the Golden Knock-off result screen already draws.
  GoldenSummary toSummary() => GoldenSummary(
    score: score,
    questions: days,
    answersInr: answersInr,
    bonusInr: bonusInr,
    totalInr: totalInr,
    rehearsal: rehearsal,
    expiresAt: expiresAt,
    skew: skew,
  );

  factory VaultResult.fromMap(Map<String, dynamic> m) => VaultResult(
    runId: _n(m['run_id']),
    score: _n(m['score']),
    days: _n(m['days']),
    answersInr: _n(m['answers_inr']),
    bonusInr: _n(m['bonus_inr']),
    totalInr: _n(m['total_inr']),
    rehearsal: m['rehearsal'] == true,
    expiresAt: _when(m['expires_at']),
    skew: _drift(m['server_now']),
    review: ((m['review'] as List<dynamic>?) ?? <dynamic>[])
        .map(
          (dynamic d) => VaultDay.fromMap(Map<String, dynamic>.from(d as Map)),
        )
        .toList(),
  );
}

// END OF FILE - lib/models/vault_models.dart
