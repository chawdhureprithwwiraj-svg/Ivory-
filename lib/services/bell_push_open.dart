import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'push_service.dart';

/// ============================================================
/// IVORY - TAPPING A BELL REMINDER OPENS THE DOORBELL
///
/// A bell reminder is a phone notification whose data says
/// `action_tab: bells`. When the member taps it (Ivory closed, or
/// in the background), [onOpen] is called once so the doorbell can
/// open. Every part is optional: with no Firebase, or any error,
/// this quietly does nothing and Ivory works as before.
/// ============================================================
class BellPushOpen {
  BellPushOpen._();

  static StreamSubscription<RemoteMessage>? _sub;
  static bool _coldChecked = false;

  static bool _isBells(RemoteMessage? m) =>
      m != null && '${m.data['action_tab']}' == 'bells';

  /// Starts listening. [onOpen] runs when a bell reminder is tapped.
  static Future<void> listen(VoidCallback onOpen) async {
    if (!PushService.firebaseAvailable) return;
    try {
      await _sub?.cancel();
      _sub = FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage m) {
        if (_isBells(m)) onOpen();
      });
      if (!_coldChecked) {
        _coldChecked = true;
        final RemoteMessage? first = await FirebaseMessaging.instance
            .getInitialMessage();
        if (_isBells(first)) onOpen();
      }
    } catch (e) {
      debugPrint('Ivory: bell reminder tap not available ($e)');
    }
  }

  static Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }
}

// END OF FILE - lib/services/bell_push_open.dart
