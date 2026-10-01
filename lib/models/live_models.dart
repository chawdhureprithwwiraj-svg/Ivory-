/// ============================================================
/// IVORY - LIVE AND CALL MODELS
///
/// Split out of live_service.dart so neither file grows past a
/// comfortable paste. Nothing here talks to the network: these are
/// just the shapes the database rows arrive in.
/// ============================================================

// =====================================================================
// MODELS
// =====================================================================

/// A broadcast as a member is allowed to see it: everything except the
/// channel name, which only ever arrives with a token.
class LiveSession {
  const LiveSession({
    required this.id,
    required this.title,
    this.subtitle,
    this.coverUrl,
    this.access = 'tier',
    this.minTier = 0,
    this.priceInr = 0,
    this.status = 'scheduled',
    this.scheduledAt,
    this.startedAt,
    this.viewerCount = 0,
    this.tierName,
    this.isEntitled = false,
  });

  final int id;
  final String title;
  final String? subtitle;
  final String? coverUrl;
  final String access;
  final int minTier;
  final int priceInr;
  final String status;
  final DateTime? scheduledAt;
  final DateTime? startedAt;
  final int viewerCount;
  final String? tierName;
  final bool isEntitled;

  bool get isLive => status == 'live';
  bool get isPayPerView => access == 'ppv';

  String get gateLabel {
    if (isEntitled) return 'Join now';
    if (isPayPerView) return 'Unlock for Rs.$priceInr';
    return tierName == null ? 'Members only' : '$tierName and above';
  }

  factory LiveSession.fromDb(Map<String, dynamic> m) => LiveSession(
        id: (m['id'] as num).toInt(),
        title: (m['title'] as String?) ?? 'Live',
        subtitle: m['subtitle'] as String?,
        coverUrl: m['cover_url'] as String?,
        access: (m['access'] as String?) ?? 'tier',
        minTier: ((m['min_tier'] as num?) ?? 0).toInt(),
        priceInr: ((m['price_inr'] as num?) ?? 0).toInt(),
        status: (m['status'] as String?) ?? 'scheduled',
        scheduledAt: DateTime.tryParse((m['scheduled_at'] as String?) ?? ''),
        startedAt: DateTime.tryParse((m['started_at'] as String?) ?? ''),
        viewerCount: ((m['viewer_count'] as num?) ?? 0).toInt(),
        tierName: m['tier_name'] as String?,
        isEntitled: (m['is_entitled'] as bool?) ?? false,
      );
}

/// Everything Agora needs to let this device into this room, once.
class AgoraTicket {
  const AgoraTicket({
    required this.appId,
    required this.channel,
    required this.token,
    required this.uid,
    required this.isPublisher,
  });

  final String appId;
  final String channel;
  final String token;
  final int uid;
  final bool isPublisher;
}

/// "78 of 120 minutes left, renews on 1 Nov."
class CallBalance {
  const CallBalance({
    required this.kind,
    required this.allowed,
    required this.used,
    required this.remaining,
    required this.period,
    this.resetsAt,
    this.tierLevel = 0,
    this.noShows = 0,
    this.cycleStart,
  });

  final String kind;
  final int allowed;
  final int used;
  final int remaining;
  final String period;
  final DateTime? resetsAt;
  final int tierLevel;

  /// Missed sessions already on record in this cycle. Two are
  /// forgiven; the third costs its minutes.
  final int noShows;

  /// The cycle runs from the day this member's paid tier began -
  /// never from the first of the month.
  final DateTime? cycleStart;

  bool get isIncluded => allowed > 0;
  double get fraction => allowed == 0 ? 0 : (used / allowed).clamp(0.0, 1.0);

  /// The cycle is counted from the member's own joining date, so the
  /// wording never implies a calendar month.
  String get periodLabel {
    switch (period) {
      case 'day':
        return 'in this 24 hours';
      case 'week':
        return 'in this 7-day cycle';
      case 'year':
        return 'in this year';
      default:
        return 'in this 30-day cycle';
    }
  }

  static const CallBalance none = CallBalance(
    kind: 'video',
    allowed: 0,
    used: 0,
    remaining: 0,
    period: 'month',
  );

  factory CallBalance.fromDb(Map<String, dynamic> m) => CallBalance(
        kind: (m['kind'] as String?) ?? 'video',
        allowed: ((m['allowed'] as num?) ?? 0).toInt(),
        used: ((m['used'] as num?) ?? 0).toInt(),
        remaining: ((m['remaining'] as num?) ?? 0).toInt(),
        period: (m['period'] as String?) ?? 'month',
        resetsAt: DateTime.tryParse((m['resets_at'] as String?) ?? ''),
        tierLevel: ((m['tier_level'] as num?) ?? 0).toInt(),
        noShows: ((m['no_shows'] as num?) ?? 0).toInt(),
        cycleStart: DateTime.tryParse((m['cycle_start'] as String?) ?? ''),
      );
}

/// One requested or confirmed one-on-one session.
class CallRequest {
  const CallRequest({
    required this.id,
    required this.kind,
    required this.minutes,
    required this.status,
    this.priceInr = 0,
    this.note,
    this.requestedFor,
    this.createdAt,
  });

  final int id;
  final String kind;
  final int minutes;
  final String status;
  final int priceInr;
  final String? note;
  final DateTime? requestedFor;
  final DateTime? createdAt;

  bool get isVideo => kind == 'video';
  bool get canJoin => status == 'accepted' || status == 'active';

  String get statusLabel {
    switch (status) {
      case 'requested':
        return 'Waiting for confirmation';
      case 'accepted':
        return 'Confirmed';
      case 'active':
        return 'In progress';
      case 'completed':
        return 'Finished';
      case 'declined':
        return 'Not accepted';
      default:
        return 'Cancelled';
    }
  }

  factory CallRequest.fromDb(Map<String, dynamic> m) => CallRequest(
        id: (m['id'] as num).toInt(),
        kind: (m['kind'] as String?) ?? 'video',
        minutes: ((m['minutes'] as num?) ?? 15).toInt(),
        status: (m['status'] as String?) ?? 'requested',
        priceInr: ((m['price_inr'] as num?) ?? 0).toInt(),
        note: m['note'] as String?,
        requestedFor: DateTime.tryParse((m['requested_for'] as String?) ?? ''),
        createdAt: DateTime.tryParse((m['created_at'] as String?) ?? ''),
      );
}


/// One session as the administrator sees it, with the member's name
/// and email already joined on by the database.
class AdminCall {
  const AdminCall({
    required this.id,
    required this.kind,
    required this.minutes,
    required this.status,
    this.displayName = 'A member',
    this.memberEmail,
    this.priceInr = 0,
    this.note,
    this.requestedFor,
    this.charged = false,
    this.joinedMember = false,
    this.joinedHost = false,
  });

  final int id;
  final String kind;
  final int minutes;
  final String status;
  final String displayName;
  final String? memberEmail;
  final int priceInr;
  final String? note;
  final DateTime? requestedFor;
  final bool charged;
  final bool joinedMember;
  final bool joinedHost;

  factory AdminCall.fromDb(Map<String, dynamic> m) => AdminCall(
        id: (m['id'] as num).toInt(),
        kind: (m['kind'] as String?) ?? 'video',
        minutes: ((m['minutes'] as num?) ?? 30).toInt(),
        status: (m['status'] as String?) ?? 'requested',
        displayName: (m['display_name'] as String?) ?? 'A member',
        memberEmail: m['member_email'] as String?,
        priceInr: ((m['price_inr'] as num?) ?? 0).toInt(),
        note: m['note'] as String?,
        requestedFor:
            DateTime.tryParse((m['requested_for'] as String?) ?? ''),
        charged: (m['charged'] as bool?) ?? false,
        joinedMember: (m['joined_member'] as bool?) ?? false,
        joinedHost: (m['joined_host'] as bool?) ?? false,
      );
}

/// Where a member goes to pick a time slot. Provider-agnostic on
/// purpose: Cal.com today, anything with a URL tomorrow.
class BookingLink {
  const BookingLink({
    required this.kind,
    required this.provider,
    this.url,
    this.headline,
    this.note,
  });

  final String kind;
  final String provider;
  final String? url;
  final String? headline;
  final String? note;

  bool get isReady => url != null && url!.startsWith('http');

  factory BookingLink.fromDb(Map<String, dynamic> m) => BookingLink(
        kind: (m['kind'] as String?) ?? 'video',
        provider: (m['provider'] as String?) ?? 'cal_com',
        url: m['url'] as String?,
        headline: m['headline'] as String?,
        note: m['note'] as String?,
      );
}

// END OF FILE - lib/models/live_models.dart
