import 'reward_models.dart';

/// What the house says a code takes off a membership. The database
/// works the numbers out; the phone only shows them.
class CodeQuote {
  const CodeQuote({
    required this.codeId,
    required this.code,
    required this.kind,
    required this.value,
    required this.listInr,
    required this.offInr,
    required this.payInr,
    this.label = '',
  });

  final int codeId;
  final String code;
  final String label;
  final String kind;
  final int value;
  final int listInr;
  final int offInr;
  final int payInr;

  factory CodeQuote.fromMap(Map<String, dynamic> m) => CodeQuote(
    codeId: (m['code_id'] as num).toInt(),
    code: '${m['code']}',
    label: '${m['label'] ?? ''}',
    kind: '${m['kind'] ?? 'fixed'}',
    value: ((m['value'] as num?) ?? 0).toInt(),
    listInr: ((m['list_inr'] as num?) ?? 0).toInt(),
    offInr: ((m['off_inr'] as num?) ?? 0).toInt(),
    payInr: ((m['pay_inr'] as num?) ?? 0).toInt(),
  );
}

/// One of the member's own one-time codes (earned with a treasure).
class PrizeCode {
  const PrizeCode({
    required this.code,
    required this.kind,
    required this.value,
    this.maxOff,
    this.validUntil,
  });

  final String code;
  final String kind;
  final int value;
  final int? maxOff;
  final DateTime? validUntil;

  String get offText => discountOffText(kind, value, maxOff);

  factory PrizeCode.fromMap(Map<String, dynamic> m) => PrizeCode(
    code: '${m['code']}',
    kind: '${m['kind'] ?? 'fixed'}',
    value: ((m['value'] as num?) ?? 0).toInt(),
    maxOff: m['max_off_inr'] == null ? null : (m['max_off_inr'] as num).toInt(),
    validUntil: m['valid_until'] == null
        ? null
        : DateTime.tryParse('${m['valid_until']}')?.toLocal(),
  );
}

// END OF FILE - lib/models/discount_models.dart
