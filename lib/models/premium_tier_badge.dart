/// The public, minimal tier identity attached to an active paid member.
/// No payment, email, or private profile information is carried here.
class PremiumTierBadge {
  const PremiumTierBadge({
    required this.tierName,
    required this.tierLevel,
    this.memberId,
  });

  final String? memberId;
  final String tierName;
  final int tierLevel;

  bool get isActivePaid => tierLevel > 0;
  String get displayLabel => premiumTierLabel(tierName, tierLevel);

  factory PremiumTierBadge.fromMap(Map<String, dynamic> row) =>
      PremiumTierBadge(
        memberId: row['member_id'] as String?,
        tierName: (row['tier_name'] as String?) ?? '',
        tierLevel: ((row['tier_level'] as num?) ?? 0).toInt(),
      );
}

/// Preserve the configured tier name, while making the VIP number agree
/// with the authoritative tier level. Names remain editable in Supabase.
String premiumTierLabel(String tierName, int level) {
  final String name = tierName.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (level <= 0) return name;
  final RegExp vipNumber = RegExp(r'\bVIP\s*\d+\b', caseSensitive: false);
  if (vipNumber.hasMatch(name)) {
    return name.replaceAllMapped(vipNumber, (_) => 'VIP$level');
  }
  return name.isEmpty ? 'VIP$level' : '$name VIP$level';
}

// END OF FILE - lib/models/premium_tier_badge.dart
