/// ============================================================
/// IVORY - RING MY DOORBELL: WHAT THE DATABASE TELLS THE APP
///
/// Which bells have opened, which are rung, the Peal and tonight's
/// line are all decided by the database. These classes only carry the
/// answer to the screen.
/// ============================================================
int _bi(dynamic v, [int d = 0]) => v is num ? v.toInt() : d;

DateTime? _bt(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse('$v')?.toLocal();
}

class BellItem {
  const BellItem({
    required this.key,
    required this.label,
    required this.hour,
    required this.opensAt,
    required this.isOpen,
    required this.rung,
    required this.unseen,
    required this.done,
    required this.isLine,
  });

  final String key;
  final String label;
  final int hour;
  final DateTime? opensAt;
  final bool isOpen;
  final bool rung;
  final bool unseen;
  final bool done;
  final bool isLine;

  /// '6 AM', '12 PM' ... for the label under the bell.
  String get timeLabel {
    final int x = hour % 12 == 0 ? 12 : hour % 12;
    return '$x ${hour < 12 ? 'AM' : 'PM'}';
  }

  factory BellItem.fromMap(Map<String, dynamic> m) => BellItem(
    key: '${m['key'] ?? ''}',
    label: '${m['label'] ?? ''}',
    hour: _bi(m['hour']),
    opensAt: _bt(m['opens_at']),
    isOpen: m['is_open'] == true,
    rung: m['rung'] == true,
    unseen: m['unseen'] == true,
    done: m['done'] == true,
    isLine: m['is_line'] == true,
  );
}

/// One bell set, as the house reports it for this member.
class BellSet {
  const BellSet({
    required this.key,
    required this.name,
    required this.min,
    required this.owned,
    required this.stars,
    required this.remaining,
  });

  final String key;
  final String name;

  /// Full Days (in a round) that earn it.
  final int min;
  final bool owned;

  /// How many times it has been earned again after the first.
  final int stars;

  /// Full Days still to go this round (0 when reached).
  final int remaining;

  factory BellSet.fromMap(Map<String, dynamic> m) => BellSet(
    key: '${m['key'] ?? ''}',
    name: '${m['name'] ?? ''}',
    min: _bi(m['min']),
    owned: m['owned'] == true,
    stars: _bi(m['stars']),
    remaining: _bi(m['remaining']),
  );
}

/// A pledge that is going.
class BellPledge {
  const BellPledge({required this.len, required this.got});

  final int len;
  final int got;

  int get left => len - got < 0 ? 0 : len - got;
}

/// How the last pledge ended, until the member has seen it.
class PledgeResult {
  const PledgeResult({
    required this.kept,
    required this.len,
    required this.got,
  });

  final bool kept;
  final int len;
  final int got;
}

class BellsState {
  const BellsState({
    this.enabled = true,
    this.bells = const <BellItem>[],
    this.need = 4,
    this.rungN = 0,
    this.waitingN = 0,
    this.full = false,
    this.fullUnseen = false,
    this.peal = 0,
    this.bestPeal = 0,
    this.fullDays = 0,
    this.line,
    this.nextOpenAt,
    this.ringPoints = 20,
    this.sets = const <BellSet>[],
    this.wear = 'jewel',
    this.newSets = const <String>[],
    this.round = 1,
    this.cycle = 1,
    this.pledge,
    this.pledgeResult,
    this.pledgeLens = const <int>[],
    this.pledgesKept = 0,
  });

  final bool enabled;
  final List<BellItem> bells;
  final int need;
  final int rungN;
  final int waitingN;
  final bool full;
  final bool fullUnseen;
  final int peal;
  final int bestPeal;
  final int fullDays;
  final String? line;
  final DateTime? nextOpenAt;
  final int ringPoints;
  final List<BellSet> sets;

  /// The set the bells are wearing.
  final String wear;

  /// Sets earned (or earned again) since the member last saw the ceremony.
  final List<String> newSets;

  /// Which round of the sets the member is in (1, 2, ...).
  final int round;

  /// How many Full Days one round lasts.
  final int cycle;
  final BellPledge? pledge;
  final PledgeResult? pledgeResult;
  final List<int> pledgeLens;
  final int pledgesKept;

  BellSet? setByKey(String k) {
    for (final BellSet x in sets) {
      if (x.key == k) return x;
    }
    return null;
  }

  /// True when there is a ceremony the member has not seen yet.
  bool get hasCeremony =>
      hasUnseen || newSets.isNotEmpty || pledgeResult != null;

  bool get allRung => need > 0 && rungN >= need;

  bool get hasUnseen => bells.any((BellItem b) => b.unseen) || fullUnseen;

  BellItem? byKey(String k) {
    for (final BellItem b in bells) {
      if (b.key == k) return b;
    }
    return null;
  }

  factory BellsState.fromMap(Map<String, dynamic> m) {
    final dynamic raw = m['bells'];
    final List<BellItem> items = raw is List
        ? raw
              .whereType<Map>()
              .map((Map e) => BellItem.fromMap(Map<String, dynamic>.from(e)))
              .toList()
        : <BellItem>[];
    final dynamic ln = m['line'];
    final dynamic pl = m['pledge'];
    final dynamic pr = m['pledge_result'];
    return BellsState(
      enabled: m['enabled'] != false,
      bells: items,
      need: _bi(m['need'], 4),
      rungN: _bi(m['rung_n']),
      waitingN: _bi(m['waiting_n']),
      full: m['full'] == true,
      fullUnseen: m['full_unseen'] == true,
      peal: _bi(m['peal']),
      bestPeal: _bi(m['best_peal']),
      fullDays: _bi(m['full_days']),
      line: ln is String && ln.trim().isNotEmpty ? ln : null,
      nextOpenAt: _bt(m['next_open_at']),
      ringPoints: _bi(m['ring_points'], 20),
      sets: m['sets'] is List
          ? (m['sets'] as List)
                .whereType<Map>()
                .map((Map e) => BellSet.fromMap(Map<String, dynamic>.from(e)))
                .toList()
          : <BellSet>[],
      wear: '${m['wear'] ?? 'jewel'}',
      newSets: m['new_sets'] is List
          ? (m['new_sets'] as List).map((dynamic e) => '$e').toList()
          : <String>[],
      round: _bi(m['round'], 1),
      cycle: _bi(m['cycle'], 1),
      pledge: pl is Map
          ? BellPledge(len: _bi(pl['len']), got: _bi(pl['got']))
          : null,
      pledgeResult: pr is Map
          ? PledgeResult(
              kept: pr['result'] == 'kept',
              len: _bi(pr['len']),
              got: _bi(pr['got']),
            )
          : null,
      pledgeLens: m['pledge_lens'] is List
          ? (m['pledge_lens'] as List).map((dynamic e) => _bi(e)).toList()
          : <int>[],
      pledgesKept: _bi(m['pledges_kept']),
    );
  }
}

// END OF FILE - lib/models/bell_models.dart
