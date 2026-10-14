import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/live_member_identity_models.dart';
import '../models/premium_tier_badge.dart';

/// Reads only the small, public tier label needed for Ivory's member marks.
/// Database functions restrict the live result to entitled room viewers and
/// the call result to the administrator; no email or payment data is returned.
class MemberBadgeService {
  MemberBadgeService._();
  static final MemberBadgeService instance = MemberBadgeService._();

  SupabaseClient get _db => Supabase.instance.client;

  /// Current paid tiers for members visible in this broadcast. A null result
  /// means the optional database function is not available or the request failed.
  Future<Map<String, PremiumTierBadge>?> forLiveSession(int sessionId) async {
    try {
      final dynamic result = await _db.rpc<dynamic>(
        'live_member_badges',
        params: <String, dynamic>{'session_id_in': sessionId},
      );
      if (result is! List) return <String, PremiumTierBadge>{};
      final Map<String, PremiumTierBadge> badges =
          <String, PremiumTierBadge>{};
      for (final dynamic value in result) {
        final PremiumTierBadge badge =
            PremiumTierBadge.fromMap(Map<String, dynamic>.from(value as Map));
        final String? id = badge.memberId;
        if (id != null && id.isNotEmpty && badge.isActivePaid) {
          badges[id] = badge;
        }
      }
      return badges;
    } catch (_) {
      return null;
    }
  }

  Future<List<LiveMessage>> resolveLiveMessages(
    int sessionId,
    List<LiveMessage> messages,
  ) async {
    final Map<String, PremiumTierBadge>? badges =
        await forLiveSession(sessionId);
    if (badges == null) {
      return messages
          .map((LiveMessage m) => m.withPremiumTier(resolved: false))
          .toList();
    }
    return messages.map((LiveMessage m) {
      final PremiumTierBadge? badge =
          m.memberId == null ? null : badges[m.memberId];
      return m.withPremiumTier(
        resolved: true,
        tierName: badge?.tierName,
        tierLevel: badge?.tierLevel ?? 0,
      );
    }).toList();
  }

  /// Current signed-in member's own tier, from the existing self-only view.
  Future<PremiumTierBadge?> forCurrentMember() async {
    try {
      final List<dynamic> rows = await _db
          .from('my_membership')
          .select('tier_name,tier_level')
          .order('tier_level', ascending: false)
          .limit(1);
      if (rows.isEmpty) return null;
      final Map<String, dynamic> row =
          Map<String, dynamic>.from(rows.first as Map);
      return PremiumTierBadge(
        memberId: _db.auth.currentUser?.id,
        tierName: (row['tier_name'] as String?) ?? '',
        tierLevel: ((row['tier_level'] as num?) ?? 0).toInt(),
      );
    } catch (_) {
      return null;
    }
  }

  /// The administrator-only current tier of the member whose call is open.
  Future<PremiumTierBadge?> forAdminCall(int callId) async {
    try {
      final dynamic result = await _db.rpc<dynamic>(
        'admin_call_member_badge',
        params: <String, dynamic>{'call_id_in': callId},
      );
      final dynamic row = result is List
          ? (result.isEmpty ? null : result.first)
          : result;
      if (row is! Map) return null;
      final PremiumTierBadge badge =
          PremiumTierBadge.fromMap(Map<String, dynamic>.from(row));
      return badge.isActivePaid ? badge : null;
    } catch (_) {
      // A missing badge must never stop an otherwise valid call from opening.
      return null;
    }
  }
}

// END OF FILE - lib/services/member_badge_service.dart
