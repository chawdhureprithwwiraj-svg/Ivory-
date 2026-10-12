import 'dart:math' as math;

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';

import '../models/live_guest_models.dart';
import '../theme/ivory_theme.dart';

/// Ivory stays full-screen; up to five speakers share a draggable, snap-to-place
/// dock above the chat. Camera-off guests remain named audio tiles.
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
    required this.guestDockAnchor,
    required this.canMoveGuestDock,
    required this.onGuestDockAnchorChanged,
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
  final LiveGuestDockAnchor guestDockAnchor;
  final bool canMoveGuestDock;
  final ValueChanged<LiveGuestDockAnchor> onGuestDockAnchorChanged;

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
            child: _GuestDock(
              guests: speakers,
              anchor: guestDockAnchor,
              canMove: canMoveGuestDock,
              onAnchorChanged: onGuestDockAnchorChanged,
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

class _GuestDock extends StatefulWidget {
  const _GuestDock({
    required this.guests,
    required this.anchor,
    required this.canMove,
    required this.onAnchorChanged,
    required this.tileBuilder,
  });

  final List<LiveGuestParticipant> guests;
  final LiveGuestDockAnchor anchor;
  final bool canMove;
  final ValueChanged<LiveGuestDockAnchor> onAnchorChanged;
  final Widget Function(LiveGuestParticipant guest, double height) tileBuilder;

  @override
  State<_GuestDock> createState() => _GuestDockState();
}

class _GuestDockState extends State<_GuestDock> {
  Offset _dragOffset = Offset.zero;

  @override
  void didUpdateWidget(covariant _GuestDock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.anchor != widget.anchor) _dragOffset = Offset.zero;
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData metrics = MediaQuery.of(context);
    final bool typing = metrics.viewInsets.bottom > 80;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double screenWidth = constraints.maxWidth;
        final double screenHeight = constraints.maxHeight;
        final int count = widget.guests.length;
        final double gap = count > 1 ? 6 : 0;
        final double tileWidth =
            ((screenWidth - 36 - gap * (count - 1)) / count)
                .clamp(44.0, 104.0)
                .toDouble();
        final double wantedHeight =
            (tileWidth * 1.35).clamp(68.0, 154.0).toDouble();
        final double chatHeight =
            (screenHeight * (typing ? 0.48 : 0.39))
                .clamp(0.0, typing ? 420.0 : 340.0)
                .toDouble();
        final double bottomInset =
            chatHeight + 86 + metrics.padding.bottom + 8;
        final double topInset = (metrics.padding.top + 104)
            .clamp(104.0, 220.0)
            .toDouble();
        final double safeLeft =
            math.max(12.0, metrics.padding.left + 8).toDouble();
        final double safeRight =
            math.max(12.0, metrics.padding.right + 8).toDouble();
        final double handleHeight = 16;
        final double availableHeight =
            (screenHeight - topInset - bottomInset - handleHeight)
                .clamp(52.0, 180.0)
                .toDouble();
        final double tileHeight =
            math.min(wantedHeight, availableHeight).toDouble();
        final double dockHeight = handleHeight + tileHeight;
        final double dockWidth = count * tileWidth + gap * (count - 1);
        final double maxLeft = math.max(
          safeLeft,
          screenWidth - dockWidth - safeRight,
        ).toDouble();
        final double bottomTop = math.max(
          topInset,
          screenHeight - bottomInset - dockHeight,
        ).toDouble();
        final double baseLeft = widget.anchor.isLeft
            ? safeLeft
            : widget.anchor.isRight
                ? maxLeft
                : ((screenWidth - dockWidth) / 2)
                    .clamp(safeLeft, maxLeft)
                    .toDouble();
        final double baseTop = widget.anchor.isTop ? topInset : bottomTop;
        final double left = (baseLeft + _dragOffset.dx)
            .clamp(safeLeft, maxLeft)
            .toDouble();
        final double top = (baseTop + _dragOffset.dy)
            .clamp(topInset, bottomTop)
            .toDouble();
        final List<Widget> tiles = <Widget>[];
        for (int index = 0; index < count; index++) {
          final LiveGuestParticipant guest = widget.guests[index];
          tiles.add(
            Padding(
              key: ValueKey<String>(
                guest.userId.isEmpty
                    ? 'guest-${guest.requestId}'
                    : guest.userId,
              ),
              padding: EdgeInsets.only(left: index == 0 ? 0 : gap),
              child: SizedBox(
                width: tileWidth,
                height: tileHeight,
                child: widget.tileBuilder(guest, tileHeight),
              ),
            ),
          );
        }
        final Widget dock = Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              height: handleHeight,
              child: widget.canMove
                  ? Icon(
                      Icons.drag_indicator,
                      size: 20,
                      color: IvoryColors.cream.withValues(alpha: 0.82),
                    )
                  : const SizedBox.shrink(),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: tiles,
            ),
          ],
        );
        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Positioned(
              left: left,
              top: top,
              width: dockWidth,
              height: dockHeight,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanUpdate: widget.canMove
                    ? (DragUpdateDetails details) {
                        final double nextLeft = (left + details.delta.dx)
                            .clamp(safeLeft, maxLeft)
                            .toDouble();
                        final double nextTop = (top + details.delta.dy)
                            .clamp(topInset, bottomTop)
                            .toDouble();
                        setState(() {
                          _dragOffset = Offset(
                            nextLeft - baseLeft,
                            nextTop - baseTop,
                          );
                        });
                      }
                    : null,
                onPanEnd: widget.canMove
                    ? (_) {
                        final double centerY = top + dockHeight / 2;
                        final bool snapTop =
                            centerY < (topInset + bottomTop) / 2;
                        final double horizontal = maxLeft <= safeLeft
                            ? 0.5
                            : (left - safeLeft) / (maxLeft - safeLeft);
                        final LiveGuestDockAnchor snapped = snapTop
                            ? (horizontal < 0.5
                                ? LiveGuestDockAnchor.topLeft
                                : LiveGuestDockAnchor.topRight)
                            : horizontal < 0.34
                                ? LiveGuestDockAnchor.aboveChatLeft
                                : horizontal > 0.66
                                    ? LiveGuestDockAnchor.aboveChatRight
                                    : LiveGuestDockAnchor.aboveChatCenter;
                        setState(() => _dragOffset = Offset.zero);
                        widget.onAnchorChanged(snapped);
                      }
                    : null,
                onPanCancel: widget.canMove
                    ? () => setState(() => _dragOffset = Offset.zero)
                    : null,
                child: dock,
              ),
            ),
          ],
        );
      },
    );
  }
}

// END OF FILE - lib/widgets/live_broadcast_stage.dart
