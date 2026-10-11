import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';

import '../models/live_guest_models.dart';
import '../theme/ivory_theme.dart';

/// Ivory stays full-screen; up to five speakers scale into a bottom row.
/// Camera-off guests remain named audio tiles instead of black surfaces.
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

  @override
  Widget build(BuildContext context) {
    final bool hostPicture = isHost
        ? hostVideoEnabled
        : hostUid != 0 &&
            hostVideoEnabled &&
            remoteVideoUids.contains(hostUid);
    final List<LiveGuestParticipant> speakers = guests.take(5).toList();
    final MediaQueryData metrics = MediaQuery.of(context);
    final bool typing = metrics.viewInsets.bottom > 80;
    final double chatHeight = (metrics.size.height * (typing ? 0.48 : 0.39))
        .clamp(0.0, typing ? 420.0 : 340.0)
        .toDouble();
    final double guestBottom =
        chatHeight + 86 + metrics.padding.bottom + 8;
    final int count = speakers.length;
    final double gap = count > 1 ? 6 : 0;
    final double width = count == 0
        ? 0
        : ((metrics.size.width - 24 - gap * (count - 1)) / count)
            .clamp(48.0, 160.0)
            .toDouble();
    final double wantedHeight = (width * 1.35).clamp(72.0, 190.0).toDouble();
    final double availableHeight =
        (metrics.size.height - guestBottom - metrics.padding.top - 108)
            .clamp(56.0, 190.0)
            .toDouble();
    final double tileHeight =
        wantedHeight < availableHeight ? wantedHeight : availableHeight;
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
        if (speakers.isNotEmpty)
          Positioned(
            left: 12,
            right: 12,
            bottom: guestBottom,
            height: tileHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List<Widget>.generate(
                count,
                (int index) => Padding(
                  padding: EdgeInsets.only(left: index == 0 ? 0 : gap),
                  child: SizedBox(
                    width: width,
                    height: tileHeight,
                    child: _guestTile(speakers[index], tileHeight),
                  ),
                ),
              ),
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
