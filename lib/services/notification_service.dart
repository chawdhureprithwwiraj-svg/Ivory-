import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/ivory_notification.dart';

/// The single source of truth for the Sanctuary Inbox. It keeps
/// the total unread count live, flags unread system notices for
/// special treatment, and announces new system notices to the
/// signed-in shell without creating a second notification feed.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  SupabaseClient get _db => Supabase.instance.client;

  /// Total unread notices for the bottom Inbox badge.
  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  /// Whether any unread system notice needs priority treatment.
  final ValueNotifier<bool> hasUnreadPriorityNotice = ValueNotifier<bool>(false);

  /// A just-arrived system notice for the ten-second in-app banner.
  /// Dismissing the banner does not mark the Inbox row as read.
  final ValueNotifier<IvoryNotification?> latestPriorityArrival =
      ValueNotifier<IvoryNotification?>(null);

  /// Bumped whenever the inbox itself changes. Screens showing
  /// notifications should listen and quietly reload, then remove
  /// their listener in dispose.
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  RealtimeChannel? _channel;
  Timer? _arrivalTimer;

  /// Call once after sign-in.
  Future<void> start() async {
    await refreshUnread();
    _channel?.unsubscribe();
    _channel = _db
        .channel('public:notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          callback: (PostgresChangePayload payload) async {
            await refreshUnread();

            final Map<String, dynamic> inserted = payload.newRecord;
            final int? id = (inserted['id'] as num?)?.toInt();
            if (inserted['kind'] == 'system' && id != null) {
              // Resolve through the recipient-facing view. This avoids
              // showing a banner for a notice this member cannot receive.
              try {
                final List<dynamic> visible = await _db
                    .from('my_notifications')
                    .select()
                    .eq('id', id)
                    .limit(1);
                if (visible.isNotEmpty) {
                  final IvoryNotification notice = IvoryNotification.fromMap(
                    visible.first as Map<String, dynamic>,
                  );
                  if (!notice.isRead) _showPriorityArrival(notice);
                }
              } catch (_) {
                // The Inbox row remains the durable record if the preview
                // cannot be loaded right now.
              }
            }

            revision.value = revision.value + 1;
          },
        )
        .subscribe();
  }

  void _showPriorityArrival(IvoryNotification notice) {
    _arrivalTimer?.cancel();
    latestPriorityArrival.value = notice;
    _arrivalTimer = Timer(const Duration(seconds: 10), dismissPriorityArrival);
  }

  Future<void> stop() async {
    _arrivalTimer?.cancel();
    _arrivalTimer = null;
    await _channel?.unsubscribe();
    _channel = null;
    unreadCount.value = 0;
    hasUnreadPriorityNotice.value = false;
    latestPriorityArrival.value = null;
  }

  Future<void> refreshUnread() async {
    try {
      final dynamic n = await _db.rpc('unread_notification_count');
      unreadCount.value = (n as num?)?.toInt() ?? 0;
    } catch (_) {
      // Offline or not signed in yet - leave the badge as it was.
    }

    try {
      final List<dynamic> priority = await _db
          .from('my_notifications')
          .select('id')
          .eq('kind', 'system')
          .eq('is_read', false)
          .limit(1);
      hasUnreadPriorityNotice.value = priority.isNotEmpty;
    } catch (_) {
      // Keep the last known priority indicator if the network is down.
    }
  }

  /// Recent messages plus every unread system notice, so an unread
  /// priority note does not fall out of the pinned section merely
  /// because newer routine messages arrived.
  Future<List<IvoryNotification>> fetch({int limit = 60}) async {
    final List<dynamic> recentRows = await _db
        .from('my_notifications')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);

    final List<dynamic> priorityRows = <dynamic>[];
    const int pageSize = 200;
    int offset = 0;
    try {
      while (true) {
        final List<dynamic> page = await _db
            .from('my_notifications')
            .select()
            .eq('kind', 'system')
            .eq('is_read', false)
            .order('created_at', ascending: false)
            .range(offset, offset + pageSize - 1);
        priorityRows.addAll(page);
        if (page.length < pageSize) break;
        offset += pageSize;
      }
    } catch (_) {
      // Keep the recent Inbox page usable if the extra pinned-query fails.
    }

    final Map<int, IvoryNotification> byId = <int, IvoryNotification>{};
    for (final dynamic row in <dynamic>[...recentRows, ...priorityRows]) {
      final IvoryNotification item =
          IvoryNotification.fromMap(row as Map<String, dynamic>);
      byId[item.id] = item;
    }

    final List<IvoryNotification> items = byId.values.toList();
    items.sort((IvoryNotification a, IvoryNotification b) {
      final bool aPinned = a.isPriorityNotice && !a.isRead;
      final bool bPinned = b.isPriorityNotice && !b.isRead;
      if (aPinned != bPinned) return aPinned ? -1 : 1;
      final DateTime aAt = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime bAt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bAt.compareTo(aAt);
    });
    return items;
  }

  /// Close only the transient arrival banner; the Inbox item remains unread.
  void dismissPriorityArrival() {
    _arrivalTimer?.cancel();
    _arrivalTimer = null;
    latestPriorityArrival.value = null;
  }

  Future<void> markRead(int id) async {
    await _db.rpc('mark_notification_read',
        params: <String, dynamic>{'notification_id_in': id});
    await refreshUnread();
    if (latestPriorityArrival.value?.id == id) dismissPriorityArrival();
  }

  Future<void> markAllRead() async {
    await _db.rpc('mark_all_notifications_read');
    await refreshUnread();
    dismissPriorityArrival();
  }

  // ---------------- admin ----------------

  /// Sends to everyone, to one tier and above, or to a single person.
  /// The database refuses this call for anyone who is not an admin.
  Future<void> send({
    required String title,
    required String body,
    String audience = 'all',
    String kind = 'system',
    int tierLevel = 0,
    String? userId,
    List<int>? tiers,
    String? actionTab,
    String? actionUrl,
  }) async {
    await _db.rpc('send_notification', params: <String, dynamic>{
      'title_in': title,
      'body_in': body,
      'audience_in': audience,
      'kind_in': kind,
      'tier_level_in': tierLevel,
      'user_id_in': userId,
      'tiers_in': tiers,
      'post_id_in': null,
      'action_tab_in': actionTab,
      'action_url_in': actionUrl,
    });
    await refreshUnread();
  }

  /// Everyone who can receive a personal message, for the admin picker.
  Future<List<Map<String, dynamic>>> searchPeople(String query) async {
    dynamic q = _db.from('profiles').select('id, display_name, role');
    if (query.trim().isNotEmpty) {
      q = q.ilike('display_name', '%${query.trim()}%');
    }
    final List<dynamic> rows =
        await q.order('display_name', ascending: true).limit(40);
    return rows.cast<Map<String, dynamic>>();
  }
}

// END OF FILE - lib/services/notification_service.dart
