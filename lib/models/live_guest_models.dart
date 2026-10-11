import 'package:flutter/foundation.dart';

/// A paid request by a member to publish audio/video inside an existing
/// broadcast. Payment and host approval are separate gates.
@immutable
class LiveGuestRequest {
  const LiveGuestRequest({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.displayName,
    required this.mediaKind,
    required this.status,
    required this.feeInr,
    required this.creditToApplyInr,
    required this.createdAt,
    this.joinedAt,
    this.amountDueInr = 0,
    this.creditAppliedInr = 0,
    this.cashPaidInr = 0,
    this.videoEnabled = false,
  });

  final int id;
  final int sessionId;
  final String userId;
  final String displayName;
  final String mediaKind;
  final String status;
  final int feeInr;
  final int creditToApplyInr;
  final int amountDueInr;
  final int creditAppliedInr;
  final int cashPaidInr;
  final bool videoEnabled;
  final DateTime? createdAt;
  final DateTime? joinedAt;

  bool get isApproved => status == 'approved';
  bool get isActive => status == 'active' || status == 'joining';
  bool get isWaiting => status == 'waiting_host';

  factory LiveGuestRequest.fromMap(Map<String, dynamic> m) =>
      LiveGuestRequest(
        id: (m['id'] as num).toInt(),
        sessionId: (m['session_id'] as num).toInt(),
        userId: (m['user_id'] as String?) ?? '',
        displayName: (m['display_name'] as String?) ?? 'A member',
        mediaKind: (m['media_kind'] as String?) ?? 'video',
        status: (m['status'] as String?) ?? 'awaiting_payment',
        feeInr: ((m['fee_inr'] as num?) ?? 0).toInt(),
        creditToApplyInr: ((m['credit_to_apply_inr'] as num?) ?? 0).toInt(),
        amountDueInr: ((m['amount_due_inr'] as num?) ?? 0).toInt(),
        creditAppliedInr: ((m['credit_applied_inr'] as num?) ?? 0).toInt(),
        cashPaidInr: ((m['cash_paid_inr'] as num?) ?? 0).toInt(),
        videoEnabled: (m['video_enabled'] as bool?) ?? false,
        createdAt: DateTime.tryParse((m['created_at'] as String?) ?? ''),
        joinedAt: DateTime.tryParse((m['joined_at'] as String?) ?? ''),
      );
}

/// A currently approved speaker, exposed only to members entitled to view
/// this broadcast. It deliberately contains no payment/order fields.
@immutable
class LiveGuestParticipant {
  const LiveGuestParticipant({
    required this.requestId,
    required this.userId,
    required this.displayName,
    required this.mediaKind,
    required this.videoEnabled,
    required this.status,
  });

  final int requestId;
  final String userId;
  final String displayName;
  final String mediaKind;
  final bool videoEnabled;
  final String status;

  int get agoraUid => liveAgoraUid(userId);

  factory LiveGuestParticipant.fromMap(Map<String, dynamic> m) =>
      LiveGuestParticipant(
        requestId: (m['request_id'] as num).toInt(),
        userId: (m['user_id'] as String?) ?? '',
        displayName: (m['display_name'] as String?) ?? 'A member',
        mediaKind: (m['media_kind'] as String?) ?? 'video',
        videoEnabled: (m['video_enabled'] as bool?) ?? false,
        status: (m['status'] as String?) ?? 'joining',
      );
}

@immutable
class LiveGuestCheckout {
  const LiveGuestCheckout({
    required this.requestId,
    required this.feeInr,
    this.creditBalanceInr = 0,
    required this.creditToApplyInr,
    required this.amountDueInr,
    required this.status,
  });

  final int requestId;
  final int feeInr;
  final int creditBalanceInr;
  final int creditToApplyInr;
  final int amountDueInr;
  final String status;

  factory LiveGuestCheckout.fromRequest(LiveGuestRequest request) =>
      LiveGuestCheckout(
        requestId: request.id,
        feeInr: request.feeInr,
        creditToApplyInr: request.creditToApplyInr,
        amountDueInr: request.amountDueInr,
        status: request.status,
      );

  factory LiveGuestCheckout.fromMap(Map<String, dynamic> m) =>
      LiveGuestCheckout(
        requestId: (m['request_id'] as num).toInt(),
        feeInr: ((m['fee_inr'] as num?) ?? 0).toInt(),
        creditBalanceInr: ((m['credit_balance_inr'] as num?) ?? 0).toInt(),
        creditToApplyInr: ((m['credit_to_apply_inr'] as num?) ?? 0).toInt(),
        amountDueInr: ((m['amount_due_inr'] as num?) ?? 0).toInt(),
        status: (m['status'] as String?) ?? 'awaiting_payment',
      );
}

/// Keep in sync with the stable participant UID in supabase/functions/agora-token.
int liveAgoraUid(String value) {
  int hash = 2166136261;
  for (final int unit in value.codeUnits) {
    hash ^= unit;
    hash = (hash * 16777619) & 0xFFFFFFFF;
  }
  return hash == 0 ? 1 : hash;
}

// END OF FILE - lib/models/live_guest_models.dart
