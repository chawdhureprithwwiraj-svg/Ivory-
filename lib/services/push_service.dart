import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'notification_service.dart';

/// Called by Android when a push arrives while Ivory is closed.
/// It must be a top-level function.
@pragma('vm:entry-point')
Future<void> ivoryBackgroundMessageHandler(RemoteMessage message) async {
  // Android already draws the tray notification for us. Nothing to do here -
  // the handler only has to exist so the isolate starts cleanly.
}

/// Device push.
///
/// Every piece of this is optional at runtime: if Firebase was never set up,
/// or the member declines the permission, the app carries on exactly as it
/// did in Sprint 3 with the in-app Sanctuary Inbox.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  bool _ready = false;
  String? _token;
  StreamSubscription<String>? _refreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;

  /// Set by main() once Firebase.initializeApp has succeeded.
  static bool firebaseAvailable = false;

  String? get token => _token;
  bool get isReady => _ready;

  /// Initialise Firebase itself. Safe to call when google-services.json was
  /// never added - it simply reports false and the app runs without push.
  static Future<bool> initFirebase() async {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(ivoryBackgroundMessageHandler);
      firebaseAvailable = true;
      return true;
    } catch (e) {
      debugPrint('Ivory: push not available ($e)');
      firebaseAvailable = false;
      return false;
    }
  }

  /// TRUE WHEN THE MEMBER SAID NO TO NOTIFICATIONS.
  ///
  /// Until now that answer was written to the debug log and
  /// nowhere else, so a member could sit for a week wondering
  /// why Ivory never told them their session was confirmed.
  /// The Profile page watches this and explains it.
  static final ValueNotifier<bool> refused = ValueNotifier<bool>(false);

  /// Ask for permission, collect the token, store it against this member.
  /// Call it after sign-in.
  Future<void> start() async {
    if (!firebaseAvailable || _ready) return;
    final String? uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    try {
      final FirebaseMessaging fm = FirebaseMessaging.instance;

      final NotificationSettings settings = await fm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('Ivory: member declined notifications');
        refused.value = true;
        return;
      }
      refused.value = false;

      final String? t = await fm.getToken();
      if (t == null) return;
      _token = t;
      await _save(t);

      _refreshSub?.cancel();
      _refreshSub = fm.onTokenRefresh.listen((String fresh) {
        _token = fresh;
        _save(fresh);
      });

      // A push that lands while Ivory is open should quietly refresh the
      // inbox badge rather than interrupt the reader.
      _foregroundSub?.cancel();
      _foregroundSub =
          FirebaseMessaging.onMessage.listen((RemoteMessage m) async {
        await NotificationService.instance.refreshUnread();
      });

      _ready = true;
    } catch (e) {
      debugPrint('Ivory: could not start push ($e)');
    }
  }

  Future<void> _save(String token) async {
    try {
      await Supabase.instance.client.rpc(
        'register_device_token',
        params: <String, dynamic>{
          'token_in': token,
          'platform_in': defaultTargetPlatform == TargetPlatform.iOS
              ? 'ios'
              : 'android',
          'device_name_in': null,
        },
      );
    } catch (e) {
      debugPrint('Ivory: could not register the device token ($e)');
    }
  }

  /// Called on sign-out so this phone stops receiving another
  /// member's notifications.
  Future<void> stop() async {
    _refreshSub?.cancel();
    _foregroundSub?.cancel();
    _refreshSub = null;
    _foregroundSub = null;
    _ready = false;

    final String? t = _token;
    _token = null;
    if (t == null) return;
    try {
      await Supabase.instance.client.rpc(
        'forget_device_token',
        params: <String, dynamic>{'token_in': t},
      );
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {
      // Signing out must never fail because of push housekeeping.
    }
  }
}

// END OF FILE - lib/services/push_service.dart
