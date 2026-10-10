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
      case 'membership':
        return 'while this membership lasts';
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
    this.windowEnd,
    this.createdAt,
    this.extensionPrice,
    this.extensionPaid = false,
    this.joinedMember = false,
    this.startedAt,
  });

  final int id;
  final String kind;
  final int minutes;
  final String status;
  final int priceInr;
  final String? note;
  final DateTime? requestedFor;
  final DateTime? windowEnd;
  final DateTime? createdAt;
  final int? extensionPrice;
  final bool extensionPaid;

  /// Whether this member has ever entered this session. The host
  /// opening an active call must not make a first-time member a
  /// "rejoiner"; Postgres sets this only when the member joins.
  final bool joinedMember;

  /// The one moment the two of you were first connected, as
  /// the database stamped it. Both handsets subtract from this,
  /// so leaving and coming back cannot put them out of step.
  final DateTime? startedAt;

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
        windowEnd: DateTime.tryParse((m['window_end'] as String?) ?? ''),
        createdAt: DateTime.tryParse((m['created_at'] as String?) ?? ''),
        extensionPrice: (m['extension_price'] as num?)?.toInt(),
        extensionPaid: (m['extension_paid'] as bool?) ?? false,
        joinedMember: (m['joined_member'] as bool?) ?? false,
        startedAt: DateTime.tryParse((m['started_at'] as String?) ?? ''),
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
    this.extensionPrice,
    this.extensionPaid = false,
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
  final int? extensionPrice;
  final bool extensionPaid;

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
        extensionPrice: (m['extension_price'] as num?)?.toInt(),
        extensionPaid: (m['extension_paid'] as bool?) ?? false,
      );
}



/// ============================================================
/// WHAT THE ROOM LOOKS LIKE FROM OUTSIDE
///
/// The administrator always sees the true number of devices in the
/// channel - that is an operational fact and must be honest.
///
/// Members see a room that fills up the way a room does: it starts
/// around a hundred, climbs quickly in the first half hour, then
/// settles as it approaches six hundred. Every device computes the
/// same figure from the session id and how long the broadcast has
/// been running, so two members sitting together see the same thing,
/// and it never jumps backwards.
/// ============================================================
int ivoryAudienceCount({
  required int sessionId,
  DateTime? startedAt,
  int realCount = 0,
}) {
  final DateTime start = startedAt ?? DateTime.now();
  final double minutes =
      DateTime.now().difference(start).inSeconds / 60.0;
  if (minutes < 0) return 103;

  int h = (sessionId * 2654435761) & 0x7FFFFFFF;
  h ^= h >> 13;
  h = (h * 1274126177) & 0x7FFFFFFF;
  h ^= h >> 16;

  // Where this particular night starts and where it is heading.
  final int floor = 103 + h % 40;
  final int ceiling = 470 + (h >> 7) % 121;

  // Fast at first, flattening out - a curve, never a straight line.
  final double fill = 1 - _exp(-minutes / 34.0);

  // A gentle sway so it does not look like a formula.
  final double sway =
      6 * _sin(minutes / 7.0 + (h % 100) / 15.0).abs();

  final int v = (floor + (ceiling - floor) * fill + sway).round();

  // The honest number is a floor: a room can never show fewer
  // people than are genuinely in it.
  return v < realCount ? realCount : v;
}

double _exp(double x) {
  // Small series, plenty for our range, and no dart:math import
  // needed in a model file.
  double sum = 1, term = 1;
  for (int i = 1; i < 18; i++) {
    term *= x / i;
    sum += term;
  }
  return sum;
}

double _sin(double x) {
  const double tau = 6.283185307179586;
  double t = x % tau;
  if (t > 3.141592653589793) t -= tau;
  double sum = t, term = t;
  for (int i = 1; i < 9; i++) {
    term *= -t * t / ((2 * i) * (2 * i + 1));
    sum += term;
  }
  return sum;
}

/// One item in the gift catalogue. Editable in the database, so a
/// rose can become a candle without a rebuild.
class Gift {
  const Gift({
    required this.id,
    required this.name,
    required this.emoji,
    required this.priceInr,
    this.line,
  });

  final int id;
  final String name;
  final String emoji;
  final int priceInr;
  final String? line;

  factory Gift.fromDb(Map<String, dynamic> m) => Gift(
        id: (m['id'] as num).toInt(),
        name: (m['name'] as String?) ?? 'A gift',
        emoji: (m['emoji'] as String?) ?? '\u{1F90D}',
        priceInr: ((m['price_inr'] as num?) ?? 0).toInt(),
        line: m['line'] as String?,
      );
}

/// A gift that was actually sent. Pending until the reference is
/// verified, then it turns gold.
class GiftSend {
  const GiftSend({
    required this.id,
    required this.name,
    required this.emoji,
    required this.amountInr,
    required this.status,
    this.sender,
    this.email,
    this.note,
    this.utr,
    this.createdAt,
  });

  final int id;
  final String name;
  final String emoji;
  final int amountInr;
  final String status;
  final String? sender;
  final String? email;
  final String? note;
  final String? utr;
  final DateTime? createdAt;

  bool get isConfirmed => status == 'confirmed';
  bool get isPending => status == 'pending';

  factory GiftSend.fromDb(Map<String, dynamic> m) => GiftSend(
        id: (m['id'] as num).toInt(),
        name: (m['name'] as String?) ?? 'A gift',
        emoji: (m['emoji'] as String?) ?? '\u{1F90D}',
        amountInr: ((m['amount_inr'] as num?) ?? 0).toInt(),
        status: (m['status'] as String?) ?? 'pending',
        sender: m['sender'] as String?,
        email: m['email'] as String?,
        note: m['note'] as String?,
        utr: m['utr'] as String?,
        createdAt: DateTime.tryParse((m['created_at'] as String?) ?? ''),
      );
}

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
  });

  final int id;
  final String body;
  final bool isHost;
  final String? memberId;
  final DateTime? createdAt;
  final String? senderName;

  factory LiveMessage.fromDb(Map<String, dynamic> m) => LiveMessage(
        id: ((m['id'] as num?) ?? 0).toInt(),
        body: (m['body'] as String?) ?? '',
        isHost: (m['is_host'] as bool?) ?? false,
        memberId: m['member_id'] as String?,
        createdAt: DateTime.tryParse((m['created_at'] as String?) ?? ''),
        senderName: m['sender_name'] as String?,
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
        // cal.com was removed in block B. Booking happens
        // inside Ivory now, so the only honest default is
        // the house itself.
        provider: (m['provider'] as String?) ?? 'ivory',
        url: m['url'] as String?,
        headline: m['headline'] as String?,
        note: m['note'] as String?,
      );
}

/// ONE NAME ON THE WALL OF A POST.
///
/// Returned by `post_gifters`, which gives back CONFIRMED
/// sends only - so every one of these is a real member who
/// really paid. See `lib/widgets/gift_wall.dart` for why that
/// matters and must never be loosened.
class PostGifter {
  const PostGifter({
    required this.sender,
    required this.giftName,
    required this.emoji,
    required this.amountInr,
    this.note,
  });

  final String sender;
  final String giftName;
  final String emoji;
  final int amountInr;

  /// The line they wrote with it, or null. Null covers BOTH
  /// "they wrote nothing" and "she took it down" - the wall
  /// treats those the same, because a removed line must leave
  /// no trace that there was ever a line to remove.
  final String? note;

  factory PostGifter.fromDb(Map<String, dynamic> m) => PostGifter(
        sender: (m['sender'] as String?) ?? 'A member',
        giftName: (m['gift_name'] as String?) ?? 'A gift',
        emoji: (m['emoji'] as String?) ?? '',
        amountInr: ((m['amount_inr'] as num?) ?? 0).toInt(),
        note: (m['note'] as String?),
      );
}

/// Two facts about a gift send that `list_gift_sends` does not
/// return: whether it sits under a post, and whether she has
/// taken its line down.
class GiftNoteFlag {
  const GiftNoteFlag({this.postId, this.hidden = false});

  final int? postId;
  final bool hidden;
}

// END OF FILE - lib/models/live_models.dart
