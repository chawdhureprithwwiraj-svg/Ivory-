import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import '../theme/ivory_theme.dart';
import 'gift_mark.dart';


/// The video stage. A broadcast fills the room behind its chat;
/// a call keeps the full portrait stage. The camera is cropped
/// to cover the frame, never stretched and never onto black.
class LiveVideoStage {
  LiveVideoStage._();

  /// HER OWN PICTURE WHILE SHE IS BROADCASTING.
  ///
  /// A broadcast audience never publishes, so the host has no
  /// remote picture and never will. Her stage is her own camera
  /// and depends on nobody else being in the room.
  static Widget? hostSelf({
    required RtcEngine engine,
    required String channel,
    bool fill = true,
  }) {
    return build(
      engine: engine,
      selfView: true,
      remoteUid: null,
      channel: channel,
      portrait: false,
      pipSelf: false,
      fill: fill,
    );
  }

  static Widget _pip({
    required Widget video,
    required VoidCallback? onTap,
    Widget? badge,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Positioned.fill(child: video),
          if (badge != null)
            Positioned(
              left: 5,
              bottom: 5,
              child: badge,
            ),
          if (onTap != null)
            Tooltip(
              message: 'Tap to swap the large and small video views',
              child: Semantics(
                button: true,
                label: 'Swap large and small video views',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    splashColor: Colors.white24,
                    highlightColor: Colors.white10,
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        margin: const EdgeInsets.all(6),
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.62),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.swap_horiz_rounded,
                          color: Colors.white,
                          size: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static Widget? build({
    required RtcEngine engine,
    required bool selfView,
    required int? remoteUid,
    required String channel,
    Widget? selfBadge,
    Widget? remoteBadge,
    required bool portrait,
    required bool pipSelf,
    bool pipRemote = false,
    VoidCallback? onTapPipSelf,
    VoidCallback? onTapPipRemote,
    bool fill = false,
  }) {
    // FILL THE FRAME, DO NOT FLOAT INSIDE IT.
    //
    // Agora's default fits the whole camera picture inside the
    // box, so a landscape phone held upright produced a thin
    // strip of face with a large empty panel underneath - the
    // face ended up smaller than the little corner preview.
    // "Hidden" crops the edges instead, which is what every
    // video call does and what the stage was shaped for.
    const RenderModeType videoRenderMode = RenderModeType.renderModeHidden;

    final Widget? video = selfView
        ? AgoraVideoView(
            controller: VideoViewController(
              rtcEngine: engine,
              canvas: const VideoCanvas(uid: 0, renderMode: videoRenderMode),
            ),
          )
        : (remoteUid == null
            ? null
            : AgoraVideoView(
                controller: VideoViewController.remote(
                  rtcEngine: engine,
                  canvas: VideoCanvas(
                    uid: remoteUid,
                    renderMode: videoRenderMode,
                  ),
                  connection: RtcConnection(channelId: channel),
                ),
              ));
    if (video == null) return null;

    // FULL BLEED IN A BROADCAST ROOM.
    //
    // The 4:5 box was right when the picture sat above the
    // conversation in a column. It is wrong now that the words
    // float ON the picture: a fixed shape inside a tall area
    // left her stranded in a small square with dead space all
    // round it, which is exactly what she photographed. In a
    // room the picture takes EVERYTHING and the words lie over
    // it. Elsewhere the old shape is kept.
    final Widget framed = ClipRRect(
      borderRadius: BorderRadius.circular(fill ? 0 : 20),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Container(color: IvoryColors.surfaceWarm),
          // Native Agora surfaces do not always honor loose Stack
          // constraints on every handset; make the fill explicit.
          Positioned.fill(child: video),
          if (selfView && selfBadge != null)
            Positioned(left: 10, top: 10, child: selfBadge),
          if (!selfView && !pipRemote && remoteBadge != null)
            Positioned(left: 10, top: 10, child: remoteBadge),
          if (pipSelf)
            Positioned(
              right: 10,
              top: 10,
              width: 96,
              height: 96 * 16 / 9,
              child: _pip(
                video: AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: engine,
                    canvas: const VideoCanvas(
                      uid: 0,
                      renderMode: videoRenderMode,
                    ),
                  ),
                ),
                onTap: onTapPipSelf,
                badge: selfBadge,
              ),
            ),
          if (pipRemote && remoteUid != null)
            Positioned(
              right: 10,
              top: 10,
              width: 96,
              height: 96 * 16 / 9,
              child: _pip(
                video: AgoraVideoView(
                  controller: VideoViewController.remote(
                    rtcEngine: engine,
                    canvas: VideoCanvas(
                      uid: remoteUid,
                      renderMode: videoRenderMode,
                    ),
                    connection: RtcConnection(channelId: channel),
                  ),
                ),
                onTap: onTapPipRemote,
                badge: remoteBadge,
              ),
            ),
        ],
      ),
    );

    if (fill) return SizedBox.expand(child: framed);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: AspectRatio(
        aspectRatio: portrait ? 9 / 16 : 4 / 5,
        child: framed,
      ),
    );
  }
}

// END OF FILE - lib/widgets/live_video_stage.dart
