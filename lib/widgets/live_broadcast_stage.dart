import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';

import '../models/live_guest_models.dart';
import '../services/live_guest_tile_service.dart';
import '../theme/ivory_theme.dart';
import 'live_guest_tile_layer.dart';
import 'premium_badge.dart';

/// Ivory stays full-screen; up to five speakers each float in their own
/// window, which Ivory places individually. Camera-off guests remain named
/// audio tiles.
class LiveBroadcastStage extends StatelessWidget {
  const LiveBroadcastStage({
    super.key,
    required this.engine,
    required this.channel,
    required this.isHost,
    required this.isGuest,
    required this.hostUid,
    required this.remoteUids,
    required this.remoteVideoUids,
    required this.hostVideoEnabled,
    required this.guestVideoEnabled,
    required this.selfRequestId,
    required this.guests,
    required this.tilePositions,
    required this.canMoveTiles,
    required this.onTileMoved,
  });

  final RtcEngine engine;
  final String channel;
  final bool isHost;
  final bool isGuest;
  final int hostUid;
  final Set<int> remoteUids;
  final Set<int> remoteVideoUids;
  final bool hostVideoEnabled;
  final bool guestVideoEnabled;
  final int? selfRequestId;
  final List<LiveGuestParticipant> guests;
  final Map<String, LiveGuestTilePosition> tilePositions;
  final bool canMoveTiles;
  final void Function(String memberId, LiveGuestTilePosition position)
      onTileMoved;

  @override
  Widget build(BuildContext context) {
    final bool hostPicture = isHost
        ? hostVideoEnabled
        : hostUid != 0 &&
            hostVideoEnabled &&
            remoteVideoUids.contains(hostUid);
    final List<LiveGuestParticipant> speakers = guests.take(5).toList();
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        if (hostPicture)
          Positioned.fill(
            child: isHost ? _localVideo() : _remoteVideo(hostUid),
          )
        else
          Positioned.fill(child: _hostAudioPlaceholder()),
        if (speakers.isNotEmpty)
          Positioned.fill(
            child: LiveGuestTileLayer(
              guests: speakers,
              positions: tilePositions,
              canMove: canMoveTiles,
              onMoved: onTileMoved,
              tileBuilder: _guestTile,
            ),
          ),
      ],
    );
  }

  Widget _guestTile(LiveGuestParticipant guest, double height) {
    final bool self = isGuest && guest.requestId == selfRequestId;
    final bool hasVideo = guest.videoEnabled &&
        (self ? guestVideoEnabled : remoteUids.contains(guest.agoraUid));
    return ClipRRect(
      key: ValueKey<String>(
        guest.userId.isEmpty ? 'guest-${guest.requestId}' : guest.userId,
      ),
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            if (hasVideo)
              self ? _localVideo() : _remoteVideo(guest.agoraUid)
            else
              _audioTile(guest),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                color: IvoryColors.burgundy.withValues(alpha: 0.72),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        guest.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: IvoryColors.cream,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (guest.hasActivePaidTier) ...<Widget>[
                      const SizedBox(width: 3),
                      PremiumBadge.emblem(
                        tierName: guest.tierName ?? '',
                        level: guest.tierLevel,
                        size: 13,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _audioTile(LiveGuestParticipant guest) => DecoratedBox(
        decoration: const BoxDecoration(gradient: IvoryColors.goldGradient),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.mic_rounded,
                  color: IvoryColors.burgundy, size: 21),
              const SizedBox(height: 2),
              Text(
                guest.mediaKind == 'audio' ? 'AUDIO' : 'CAMERA OFF',
                style: const TextStyle(
                  color: IvoryColors.burgundy,
                  fontSize: 7.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _hostAudioPlaceholder() => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[IvoryColors.plum, IvoryColors.burgundy],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.mic_rounded,
                size: 42,
                color: IvoryColors.cream.withValues(alpha: 0.9),
              ),
              const SizedBox(height: 8),
              const Text(
                'IVORY IS SPEAKING',
                style: TextStyle(
                  color: IvoryColors.cream,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _localVideo() => AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: engine,
          canvas: const VideoCanvas(
            uid: 0,
            renderMode: RenderModeType.renderModeHidden,
          ),
        ),
      );

  Widget _remoteVideo(int uid) => AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: engine,
          canvas: VideoCanvas(
            uid: uid,
            renderMode: RenderModeType.renderModeHidden,
          ),
          connection: RtcConnection(channelId: channel),
        ),
      );
}

// END OF FILE - lib/widgets/live_broadcast_stage.dart
