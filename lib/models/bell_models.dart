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
    );
  }
}

// END OF FILE - lib/models/bell_models.dart
