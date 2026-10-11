import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';

import '../models/live_guest_models.dart';
import '../theme/ivory_theme.dart';

/// Portrait broadcast layout: Ivory remains the main picture; up to five
/// approved speakers appear in a narrow rail. Camera-off guests stay visible
/// as named audio tiles instead of black video surfaces.
class LiveBroadcastStage extends StatelessWidget {
  const LiveBroadcastStage({
    super.key,
    required this.engine,
    required this.channel,
    required this.isHost,
    required this.isGuest,
    required this.hostUid,
    required this.remoteUids,
    required this.hostVideoEnabled,
    required this.guestVideoEnabled,
    required this.selfRequestId,
    required this.guests,
  });

  final RtcEngine engine;
  final String channel;
  final bool isHost;
  final bool isGuest;
  final int hostUid;
  final Set<int> remoteUids;
  final bool hostVideoEnabled;
  final bool guestVideoEnabled;
  final int? selfRequestId;
  final List<LiveGuestParticipant> guests;

  @override
  Widget build(BuildContext context) {
    final bool hostPicture = isHost
        ? hostVideoEnabled
        : hostUid != 0 && hostVideoEnabled && remoteUids.contains(hostUid);
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        if (hostPicture)
          Positioned.fill(
            child: isHost
                ? _localVideo()
                : _remoteVideo(hostUid),
          )
        else
          Positioned.fill(child: _hostAudioPlaceholder()),
        if (guests.isNotEmpty)
          Positioned(
            top: 68,
            right: 8,
            bottom: 286,
            width: 90,
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: guests.length > 5 ? 5 : guests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 7),
              itemBuilder: (BuildContext context, int index) =>
                  _guestTile(guests[index]),
            ),
          ),
      ],
    );
  }

  Widget _guestTile(LiveGuestParticipant guest) {
    final bool self = isGuest && guest.requestId == selfRequestId;
    final bool hasVideo = guest.videoEnabled &&
        (self ? guestVideoEnabled : remoteUids.contains(guest.agoraUid));
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 78,
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
