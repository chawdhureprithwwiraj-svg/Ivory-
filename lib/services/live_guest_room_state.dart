import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/live_guest_models.dart';
import 'live_guest_service.dart';

class LiveGuestRoomState extends ChangeNotifier {
  LiveGuestRoomState(this.sessionId);

  final int sessionId;
  List<LiveGuestParticipant> participants = <LiveGuestParticipant>[];
  bool hostVideoEnabled = true;
  LiveGuestDockAnchor guestDockAnchor =
      LiveGuestDockAnchor.aboveChatCenter;
  RealtimeChannel? _presence;
  RealtimeChannel? _settings;
  bool _dead = false;
  int _dockRevision = 0;
  Future<void> _dockWrites = Future<void>.value();

  Future<void> start() async {
    _presence = LiveGuestService.instance.watchParticipants(sessionId, refresh);
    _settings = LiveGuestService.instance.watchSettings(sessionId, refresh);
    await refresh();
  }

  Future<void> refresh() async {
    try {
      final List<LiveGuestParticipant> rows =
          await LiveGuestService.instance.participants(sessionId);
      final bool video =
          await LiveGuestService.instance.hostVideoEnabled(sessionId);
      final LiveGuestDockAnchor anchor =
          await LiveGuestService.instance.guestDockAnchor(sessionId);
      if (_dead) return;
      participants = rows;
      hostVideoEnabled = video;
      guestDockAnchor = anchor;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setHostVideo(bool enabled) async {
    hostVideoEnabled = enabled;
    notifyListeners();
    await LiveGuestService.instance.setHostVideo(sessionId, enabled);
    await refresh();
  }

  Future<void> setGuestDockAnchor(LiveGuestDockAnchor anchor) async {
    if (_dead || guestDockAnchor == anchor) return;
    final LiveGuestDockAnchor previous = guestDockAnchor;
    guestDockAnchor = anchor;
    final int revision = ++_dockRevision;
    notifyListeners();

    _dockWrites = _dockWrites
        .catchError((Object _) {})
        .then<void>((_) =>
            LiveGuestService.instance.setGuestDockAnchor(sessionId, anchor));
    try {
      await _dockWrites;
    } catch (_) {
      if (!_dead && revision == _dockRevision) {
        guestDockAnchor = previous;
        notifyListeners();
      }
      rethrow;
    }
  }

  @override
  void dispose() {
    _dead = true;
    final RealtimeChannel? p = _presence;
    final RealtimeChannel? s = _settings;
    if (p != null) unawaited(LiveGuestService.instance.stopWatching(p));
    if (s != null) unawaited(LiveGuestService.instance.stopWatching(s));
    super.dispose();
  }
}

// END OF FILE - lib/services/live_guest_room_state.dart
