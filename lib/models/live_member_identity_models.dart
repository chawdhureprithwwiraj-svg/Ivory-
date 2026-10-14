/// A line of chat during a broadcast. The only way a viewer takes
/// part: nobody but the host ever gets a microphone.
class LiveMessage {
  const LiveMessage({
    required this.id,
    required this.body,
    required this.isHost,
    this.memberId,
    this.createdAt,
    this.senderName,
    this.senderAvatarPath,
    this.senderAvatarUrl,
    this.senderHasActivePaidTier = false,
    this.senderTierName,
    this.senderTierLevel = 0,
    this.senderMembershipResolved = false,
  });

  final int id;
  final String body;
  final bool isHost;
  final String? memberId;
  final DateTime? createdAt;
  final String? senderName;
  final String? senderAvatarPath;
  final String? senderAvatarUrl;
  final bool senderHasActivePaidTier;
  final String? senderTierName;
  final int senderTierLevel;
  final bool senderMembershipResolved;

  LiveMessage withPremiumTier({
    required bool resolved,
    String? tierName,
    int tierLevel = 0,
  }) =>
      LiveMessage(
        id: id,
        body: body,
        isHost: isHost,
        memberId: memberId,
        createdAt: createdAt,
        senderName: senderName,
        senderAvatarPath: senderAvatarPath,
        senderAvatarUrl: senderAvatarUrl,
        senderHasActivePaidTier: resolved && tierLevel > 0,
        senderTierName: resolved && tierLevel > 0 ? tierName : null,
        senderTierLevel: resolved ? tierLevel : 0,
        senderMembershipResolved: resolved,
      );

  LiveMessage withSenderAvatarUrl(String? value) => LiveMessage(
        id: id,
        body: body,
        isHost: isHost,
        memberId: memberId,
        createdAt: createdAt,
        senderName: senderName,
        senderAvatarPath: senderAvatarPath,
        senderAvatarUrl: value,
        senderHasActivePaidTier: senderHasActivePaidTier,
        senderTierName: senderTierName,
        senderTierLevel: senderTierLevel,
        senderMembershipResolved: senderMembershipResolved,
      );

  factory LiveMessage.fromDb(Map<String, dynamic> m) => LiveMessage(
        id: ((m['id'] as num?) ?? 0).toInt(),
        body: (m['body'] as String?) ?? '',
        isHost: (m['is_host'] as bool?) ?? false,
        memberId: m['member_id'] as String?,
        createdAt: DateTime.tryParse((m['created_at'] as String?) ?? ''),
        senderName: m['sender_name'] as String?,
        senderAvatarPath: m['sender_avatar_path'] as String?,
        senderHasActivePaidTier:
            (m['sender_has_active_paid_tier'] as bool?) ?? false,
      );
}

/// ONE NAME ON THE WALL OF A POST.
/// Returned by the confirmed-gift RPC; it carries only public identity,
/// current paid-tier label and the confirmed gift details.
class PostGifter {
  const PostGifter({
    required this.sender,
    required this.giftName,
    required this.emoji,
    required this.amountInr,
    this.note,
    this.avatarPath,
    this.avatarUrl,
    this.hasActivePaidTier = false,
    this.tierName,
    this.tierLevel = 0,
  });

  final String sender;
  final String giftName;
  final String emoji;
  final int amountInr;
  final String? avatarPath;
  final String? avatarUrl;
  final bool hasActivePaidTier;
  final String? tierName;
  final int tierLevel;
  final String? note;

  PostGifter withAvatarUrl(String? value) => PostGifter(
        sender: sender,
        giftName: giftName,
        emoji: emoji,
        amountInr: amountInr,
        note: note,
        avatarPath: avatarPath,
        avatarUrl: value,
        hasActivePaidTier: hasActivePaidTier,
        tierName: tierName,
        tierLevel: tierLevel,
      );

  factory PostGifter.fromDb(Map<String, dynamic> m) => PostGifter(
        sender: (m['sender'] as String?) ?? 'A member',
        giftName: (m['gift_name'] as String?) ?? 'A gift',
        emoji: (m['emoji'] as String?) ?? '',
        amountInr: ((m['amount_inr'] as num?) ?? 0).toInt(),
        note: m['note'] as String?,
        avatarPath: m['sender_avatar_path'] as String?,
        hasActivePaidTier:
            (m['sender_has_active_paid_tier'] as bool?) ?? false,
        tierName: m['sender_tier_name'] as String?,
        tierLevel: ((m['sender_tier_level'] as num?) ?? 0).toInt(),
      );
}

// END OF FILE - lib/models/live_member_identity_models.dart
