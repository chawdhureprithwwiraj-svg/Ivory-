import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/ivory_notification.dart';

/// The inbox. Keeps a live unread count that the bottom bar badge and
/// the app bar bell both listen to, and refreshes itself the moment a
/// new notification is inserted in Supabase (realtime).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  SupabaseClient get _db => Supabase.instance.client;

  /// Rebuilds any widget wrapped in a ValueListenableBuilder.
  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  RealtimeChannel? _channel;

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
          callback: (PostgresChangePayload _) => refreshUnread(),
        )
        .subscribe();
  }

  Future<void> stop() async {
    await _channel?.unsubscribe();
    _channel = null;
    unreadCount.value = 0;
  }

  Future<void> refreshUnread() async {
    try {
      final dynamic n = await _db.rpc('unread_notification_count');
      unreadCount.value = (n as num?)?.toInt() ?? 0;
    } catch (_) {
      // Offline or not signed in yet - leave the badge as it was.
    }
  }

  Future<List<IvoryNotification>> fetch({int limit = 60}) async {
    final List<dynamic> rows = await _db
        .from('my_notifications')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);
    return rows
        .map((dynamic r) =>
            IvoryNotification.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> markRead(int id) async {
    await _db.rpc('mark_notification_read',
        params: <String, dynamic>{'notification_id_in': id});
    await refreshUnread();
  }

  Future<void> markAllRead() async {
    await _db.rpc('mark_all_notifications_read');
    await refreshUnread();
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
    final List<dynamic> rows = await q.order('display_name', ascending: true).limit(40);
    return rows.cast<Map<String, dynamic>>();
  }
}

// END OF FILE - lib/services/notification_service.dart
