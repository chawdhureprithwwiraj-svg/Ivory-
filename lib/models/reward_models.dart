/// ============================================================
/// IVORY - THE REWARDS STUDIO: WHAT THE DATABASE TELLS THE APP
///
/// A treasure is a BADGE (a keepsake that stays for ever) or an
/// ACCESS key (a named permission, optionally for a number of
/// days). Whether a goal has been reached is decided only by the
/// database; these classes carry the answer to the screen.
/// ============================================================
int _i(dynamic v, [int d = 0]) => v is num ? v.toInt() : d;

const List<String> kRewardShapes = <String>[
  'medal',
  'shield',
  'crest',
  'star',
  'key',
  'crown',
  'heart',
  'laurel',
];

const List<String> kRewardMetals = <String>[
  'gold',
  'rose',
  'pearl',
  'emerald',
  'ruby',
];

/// The goals the house can choose from: database name, then the
/// words shown in Admin.
const Map<String, String> kRewardTriggers = <String, String>{
  'first_lit': 'Lights the heart for the first time',
  'glow_days': 'Reaches a glow of N lit days in a row',
  'total_lit': 'Lights the heart on N days in all',
  'vault_done': 'Opens N Ten-Day Vaults',
  'knockoff_perfect': 'Scores a perfect 10 in the Knock-off, N times',
  'bell_full_days': 'Rings all the bells (a Full Day) on N days in all',
  'bell_peal': 'Rings Full Days N days in a row (best run)',
  'bell_pledges': 'Keeps N bell pledges',
  'bell_rounds': 'Completes N rounds of the bell sets',
  'ladder_rung': 'Reaches rung N of the Ivory Ladder (a discount gift)',
  'marks_earned': 'Collects N Marks of the Ivory Ladder',
  'cheers_received': 'Is cheered by other members N times',
};

/// What a member reads as the goal.
String rewardGoalText(String trigger, int n) {
  switch (trigger) {
    case 'first_lit':
      return 'Light your Golden Heart for the first time';
    case 'glow_days':
      return 'Reach a glow of $n lit days in a row';
    case 'total_lit':
      return 'Light your heart on $n ${n == 1 ? 'day' : 'days'}';
    case 'vault_done':
      return n == 1 ? 'Open a Ten-Day Vault' : 'Open $n Ten-Day Vaults';
    case 'knockoff_perfect':
      return n == 1
          ? 'Score a perfect 10 out of 10 in the Golden Knock-off'
          : 'Score a perfect 10 out of 10 in the Golden Knock-off, $n times';
    case 'bell_full_days':
      return n == 1
          ? 'Ring all the bells on one day'
          : 'Ring all the bells on $n days';
    case 'bell_peal':
      return 'Ring all the bells $n days in a row';
    case 'bell_pledges':
      return n == 1 ? 'Keep a bell pledge' : 'Keep $n bell pledges';
    case 'bell_rounds':
      return n == 1
          ? 'Complete a round of the bell sets'
          : 'Complete $n rounds of the bell sets';
    case 'ladder_rung':
      return 'Climb to rung $n of the Ivory Ladder';
    case 'marks_earned':
      return n == 1 ? 'Earn a Mark on the Ivory Ladder' : 'Collect $n Marks on the Ivory Ladder';
    case 'cheers_received':
      return n == 1
          ? 'Receive a cheer from another member'
          : 'Receive $n cheers from other members';
    default:
      return '';
  }
}

/// What a treasure gives besides the keepsake: a discount code.
class RewardPrize {
  const RewardPrize({
    this.code,
    required this.kind,
    required this.value,
    this.maxOff,
    this.validUntil,
    this.used = false,
    this.ended = false,
    this.days,
  });

  /// The member's own code once the treasure is earned; null while locked.
  final String? code;
  final String kind;
  final int value;
  final int? maxOff;
  final DateTime? validUntil;
  final bool used;
  final bool ended;

  /// Days the code lasts once earned (shown while the treasure is locked).
  final int? days;

  /// "₹150 off" or "25% off (up to ₹300)".
  String get offText => discountOffText(kind, value, maxOff);

  factory RewardPrize.fromMap(Map<String, dynamic> m) => RewardPrize(
    code: m['code'] == null ? null : '${m['code']}',
    kind: '${m['kind'] ?? 'fixed'}',
    value: _i(m['value']),
    maxOff: m['max_off_inr'] == null ? null : _i(m['max_off_inr']),
    validUntil: m['valid_until'] == null
        ? null
        : DateTime.tryParse('${m['valid_until']}')?.toLocal(),
    used: m['used'] == true,
    ended: m['ended'] == true,
    days: m['days'] == null ? null : _i(m['days']),
  );
}

/// How a discount reads to a member.
String discountOffText(String kind, int value, int? maxOff) {
  if (kind == 'percent') {
    return maxOff == null ? '$value% off' : '$value% off (up to \u20B9$maxOff)';
  }
  return '\u20B9$value off';
}

class RewardItem {
  const RewardItem({
    required this.id,
    required this.kind,
    required this.name,
    required this.blurb,
    required this.shape,
    required this.metal,
    this.earnedAt,
    this.expiresAt,
    this.active = true,
    this.seen = true,
    this.trigger = '',
    this.target = 1,
    this.progress = 0,
    this.validDays,
    this.prize,
  });

  final int id;

  /// 'badge' or 'access'.
  final String kind;
  final String name;
  final String blurb;
  final String shape;
  final String metal;
  final DateTime? earnedAt;
  final DateTime? expiresAt;

  /// False once an access key has run out (the treasure is still kept).
  final bool active;
  final bool seen;
  final String trigger;
  final int target;
  final int progress;
  final int? validDays;
  final RewardPrize? prize;

  bool get isAccess => kind == 'access';
  bool get earned => earnedAt != null;
  double get ratio => target <= 0 ? 0 : (progress / target).clamp(0.0, 1.0);

  factory RewardItem.fromMap(Map<String, dynamic> m) => RewardItem(
    id: _i(m['id']),
    kind: '${m['kind'] ?? 'badge'}',
    name: '${m['name'] ?? ''}',
    blurb: '${m['blurb'] ?? ''}',
    shape: '${m['shape'] ?? 'medal'}',
    metal: '${m['metal'] ?? 'gold'}',
    earnedAt: m['earned_at'] == null
        ? null
        : DateTime.tryParse('${m['earned_at']}')?.toLocal(),
    expiresAt: m['expires_at'] == null
        ? null
        : DateTime.tryParse('${m['expires_at']}')?.toLocal(),
    active: m['active'] != false,
    seen: m['seen'] != false,
    trigger: '${m['trigger'] ?? ''}',
    target: _i(m['target'], 1),
    progress: _i(m['progress']),
    validDays: m['valid_days'] == null ? null : _i(m['valid_days']),
    prize: m['prize'] is Map
        ? RewardPrize.fromMap(Map<String, dynamic>.from(m['prize'] as Map))
        : null,
  );
}

class RewardState {
  const RewardState({
    this.earned = const <RewardItem>[],
    this.locked = const <RewardItem>[],
    this.unseen = 0,
  });

  final List<RewardItem> earned;
  final List<RewardItem> locked;
  final int unseen;

  List<RewardItem> get unseenItems =>
      earned.where((RewardItem e) => !e.seen).toList();

  int get total => earned.length + locked.length;

  factory RewardState.fromMap(Map<String, dynamic> m) {
    List<RewardItem> list(dynamic v) {
      if (v is! List) return <RewardItem>[];
      return v
          .map(
            (dynamic e) =>
                RewardItem.fromMap(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    }

    if (m['state'] != 'open') return const RewardState();
    return RewardState(
      earned: list(m['earned']),
      locked: list(m['locked']),
      unseen: _i(m['unseen']),
    );
  }
}

// END OF FILE - lib/models/reward_models.dart
