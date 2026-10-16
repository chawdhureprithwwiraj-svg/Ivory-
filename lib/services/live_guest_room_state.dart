import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/live_guest_models.dart';
import 'live_guest_service.dart';
import 'live_guest_tile_service.dart';

class LiveGuestRoomState extends ChangeNotifier {
  LiveGuestRoomState(this.sessionId);

  final int sessionId;
  List<LiveGuestParticipant> participants = <LiveGuestParticipant>[];
  bool hostVideoEnabled = true;
  LiveGuestDockAnchor guestDockAnchor =
      LiveGuestDockAnchor.aboveChatCenter;
  Map<String, LiveGuestTilePosition> tilePositions =
      <String, LiveGuestTilePosition>{};
  final Map<String, LiveGuestTilePosition> _pendingTiles =
      <String, LiveGuestTilePosition>{};
  final Map<String, Future<void>> _tileWrites = <String, Future<void>>{};
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
      final Map<String, LiveGuestTilePosition>? tiles =
          await LiveGuestTileService.instance.positions(sessionId);
      if (_dead) return;
      participants = rows;
      hostVideoEnabled = video;
      guestDockAnchor = anchor;
      if (tiles != null) {
        // A spot Ivory has just set stays where she put it until the
        // database has caught up, so a window never jumps back.
        _pendingTiles.removeWhere(
          (String id, LiveGuestTilePosition p) => tiles[id] == p,
        );
        tilePositions = <String, LiveGuestTilePosition>{
          ...tiles,
          ..._pendingTiles,
        };
      }
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

  /// Moves ONE co-host window. Other windows are never touched.
  Future<void> setTilePosition(
    String memberId,
    LiveGuestTilePosition position,
  ) async {
    if (_dead || memberId.isEmpty) return;
    final LiveGuestTilePosition? previous = tilePositions[memberId];
    _pendingTiles[memberId] = position;
    tilePositions = <String, LiveGuestTilePosition>{
      ...tilePositions,
      memberId: position,
    };
    notifyListeners();

    final Future<void> before = _tileWrites[memberId] ?? Future<void>.value();
    final Future<void> write = before.catchError((Object _) {}).then<void>(
          (_) => LiveGuestTileService.instance
              .setPosition(sessionId, memberId, position),
        );
    _tileWrites[memberId] = write;
    try {
      await write;
    } catch (_) {
      if (!_dead && _pendingTiles[memberId] == position) {
        _pendingTiles.remove(memberId);
        final Map<String, LiveGuestTilePosition> back =
            <String, LiveGuestTilePosition>{...tilePositions};
        if (previous == null) {
          back.remove(memberId);
        } else {
          back[memberId] = previous;
        }
        tilePositions = back;
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
