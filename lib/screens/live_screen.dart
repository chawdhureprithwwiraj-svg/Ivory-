import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/live_service.dart';
import '../theme/ivory_theme.dart';

/// ============================================================
/// IVORY - THE LIVE ROOM
///
/// One screen, three jobs:
///   watching a broadcast   (audience, receives only)
///   hosting a broadcast    (publisher, camera + mic)
///   a one-on-one call      (both sides publish)
///
/// Nothing here decides who may be in the room. The ticket arrives
/// already signed by the Edge Function, which only signs it after
/// Postgres has approved the member. If the token is wrong, Agora
/// itself refuses the join - there is no second door.
///
/// Portrait first, like the rest of Ivory: the stage is 9:16 and a
/// landscape camera is letterboxed onto cream, never stretched.
/// ============================================================

enum LiveMode { watch, host, call }

class LiveScreen extends StatefulWidget {
  const LiveScreen({
    super.key,
    required this.sessionId,
    required this.title,
    this.mode = LiveMode.watch,
    this.videoEnabled = true,
    this.subtitle,
  });

  final int sessionId;
  final String title;
  final LiveMode mode;

  /// False for an audio-only call: no camera is ever opened.
  final bool videoEnabled;
  final String? subtitle;

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  RtcEngine? _engine;
  AgoraTicket? _ticket;

  String _status = 'Connecting you...';
  String? _error;
  bool _joined = false;
  int? _remoteUid;
  bool _micOn = true;
  bool _camOn = true;
  bool _frontCamera = true;

  Duration _elapsed = Duration.zero;
  Timer? _timer;

  bool get _publishes =>
      widget.mode == LiveMode.host || widget.mode == LiveMode.call;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    try {
      // 1. Permissions. Audio-only never asks for the camera.
      final List<Permission> needed = <Permission>[
        if (_publishes) Permission.microphone,
        if (_publishes && widget.videoEnabled) Permission.camera,
      ];
      if (needed.isNotEmpty) {
        setState(() => _status = 'Checking permissions...');
        final Map<Permission, PermissionStatus> granted =
            await needed.request();
        final bool ok =
            granted.values.every((PermissionStatus s) => s.isGranted);
        if (!ok) {
          setState(() => _error =
              'Ivory needs the microphone'
              '${widget.videoEnabled ? ' and camera' : ''} to take part. '
              'You can allow it in Settings and come back.');
          return;
        }
      }

      // 2. The signed ticket. Every entitlement check happens here.
      setState(() => _status = 'Opening the room...');
      final AgoraTicket ticket = widget.mode == LiveMode.call
          ? await LiveService.instance.joinCall(widget.sessionId)
          : await LiveService.instance.joinLive(widget.sessionId);
      _ticket = ticket;

      // 3. The engine.
      final RtcEngine engine = createAgoraRtcEngine();
      await engine.initialize(RtcEngineContext(
        appId: ticket.appId,
        channelProfile: widget.mode == LiveMode.call
            ? ChannelProfileType.channelProfileCommunication
            : ChannelProfileType.channelProfileLiveBroadcasting,
      ));
      _engine = engine;

      engine.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection _, int __) {
          if (!mounted) return;
          setState(() {
            _joined = true;
            _status = widget.mode == LiveMode.host
                ? 'You are on air'
                : 'Waiting for the stream...';
          });
          _startClock();
        },
        onUserJoined: (RtcConnection _, int uid, int __) {
          if (!mounted) return;
          setState(() {
            _remoteUid = uid;
            _status = '';
          });
        },
        onUserOffline: (RtcConnection _, int uid, UserOfflineReasonType __) {
          if (!mounted) return;
          setState(() {
            if (_remoteUid == uid) _remoteUid = null;
            _status = widget.mode == LiveMode.host
                ? 'You are on air'
                : 'The stream has paused.';
          });
        },
        onError: (ErrorCodeType code, String msg) {
          if (!mounted) return;
          setState(() => _error = 'Connection problem ($msg).');
        },
      ));

      await engine.enableAudio();
      if (widget.videoEnabled) {
        await engine.enableVideo();
      }

      if (_publishes) {
        await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
        if (widget.videoEnabled) await engine.startPreview();
      } else {
        await engine.setClientRole(role: ClientRoleType.clientRoleAudience);
      }

      await engine.joinChannel(
        token: ticket.token,
        channelId: ticket.channel,
        uid: ticket.uid,
        options: ChannelMediaOptions(
          clientRoleType: _publishes
              ? ClientRoleType.clientRoleBroadcaster
              : ClientRoleType.clientRoleAudience,
          publishMicrophoneTrack: _publishes,
          publishCameraTrack: _publishes && widget.videoEnabled,
          autoSubscribeAudio: true,
          autoSubscribeVideo: widget.videoEnabled,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _startClock() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  Future<void> _leave() async {
    _timer?.cancel();
    final RtcEngine? e = _engine;
    _engine = null;
    if (e != null) {
      try {
        await e.leaveChannel();
        await e.release();
      } catch (_) {}
    }
    if (widget.mode == LiveMode.watch) {
      await LiveService.instance.leaveLive(widget.sessionId);
    }
    if (widget.mode == LiveMode.call) {
      await LiveService.instance.endCall(widget.sessionId);
    }
  }

  @override
  void dispose() {
    _leave();
    super.dispose();
  }

  String get _clock {
    final int m = _elapsed.inMinutes;
    final String s = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool did, _) {
        if (did) _leave();
      },
      child: Scaffold(
        backgroundColor: IvoryColors.burgundy,
        body: SafeArea(
          child: Column(
            children: <Widget>[
              _bar(context),
              Expanded(child: Center(child: _stage())),
              _controls(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  Widget _bar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      child: Row(
        children: <Widget>[
          if (_joined && _error == null) ...<Widget>[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                gradient: IvoryColors.goldGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.mode == LiveMode.call ? _clock : 'LIVE  $_clock',
                style: const TextStyle(
                  color: IvoryColors.burgundy,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: IvoryColors.ivory,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close_rounded, color: IvoryColors.ivory),
          ),
        ],
      ),
    );
  }

  Widget _stage() {
    if (_error != null) return _message(_error!, isError: true);

    final RtcEngine? engine = _engine;
    if (engine == null || !_joined) return _message(_status);

    // Audio only: a warm panel, not a black rectangle.
    if (!widget.videoEnabled) {
      return _audioStage();
    }

    // Watching: the host's feed. Hosting: your own camera.
    final Widget? video = widget.mode == LiveMode.host
        ? AgoraVideoView(
            controller: VideoViewController(
              rtcEngine: engine,
              canvas: const VideoCanvas(uid: 0),
            ),
          )
        : (_remoteUid == null
            ? null
            : AgoraVideoView(
                controller: VideoViewController.remote(
                  rtcEngine: engine,
                  canvas: VideoCanvas(uid: _remoteUid),
                  connection:
                      RtcConnection(channelId: _ticket?.channel ?? ''),
                ),
              ));

    if (video == null) return _message(_status);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: AspectRatio(
        aspectRatio: 9 / 16,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Container(color: IvoryColors.surfaceWarm),
              video,
              // In a call, your own camera sits in the corner.
              if (widget.mode == LiveMode.call && _camOn)
                Positioned(
                  right: 10,
                  top: 10,
                  width: 96,
                  height: 96 * 16 / 9,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AgoraVideoView(
                      controller: VideoViewController(
                        rtcEngine: engine,
                        canvas: const VideoCanvas(uid: 0),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _audioStage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              gradient: IvoryColors.goldGradient,
              shape: BoxShape.circle,
              boxShadow: IvoryTheme.softShadow(blur: 26, y: 10),
            ),
            child: const Icon(Icons.graphic_eq_rounded,
                color: IvoryColors.burgundy, size: 58),
          ),
          const SizedBox(height: 22),
          Text(
            _remoteUid == null ? 'Connecting...' : 'Connected',
            style: const TextStyle(
              color: IvoryColors.ivory,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (widget.subtitle != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              widget.subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: IvoryColors.cream.withValues(alpha: 0.8),
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _message(String text, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (!isError)
            const CircularProgressIndicator(
                color: IvoryColors.gold, strokeWidth: 2.4)
          else
            const Icon(Icons.info_outline_rounded,
                color: IvoryColors.gold, size: 40),
          const SizedBox(height: 18),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: IvoryColors.cream.withValues(alpha: 0.92),
              fontSize: 14.5,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _controls() {
    if (_error != null || !_joined) {
      return const SizedBox(height: 28);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (_publishes)
            _round(
              icon: _micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
              active: _micOn,
              onTap: () async {
                setState(() => _micOn = !_micOn);
                await _engine?.muteLocalAudioStream(!_micOn);
              },
            ),
          if (_publishes && widget.videoEnabled) ...<Widget>[
            const SizedBox(width: 14),
            _round(
              icon: _camOn
                  ? Icons.videocam_rounded
                  : Icons.videocam_off_rounded,
              active: _camOn,
              onTap: () async {
                setState(() => _camOn = !_camOn);
                await _engine?.muteLocalVideoStream(!_camOn);
              },
            ),
            const SizedBox(width: 14),
            _round(
              icon: Icons.cameraswitch_rounded,
              active: true,
              onTap: () async {
                setState(() => _frontCamera = !_frontCamera);
                await _engine?.switchCamera();
              },
            ),
          ],
          const SizedBox(width: 14),
          _round(
            icon: Icons.call_end_rounded,
            active: true,
            danger: true,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }

  Widget _round({
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          gradient: danger ? null : IvoryColors.goldGradient,
          color: danger ? IvoryColors.plum : null,
          shape: BoxShape.circle,
          border: Border.all(
            color: active ? IvoryColors.gold : IvoryColors.cream,
            width: active ? 0 : 1.4,
          ),
        ),
        child: Icon(
          icon,
          color: danger ? IvoryColors.cream : IvoryColors.burgundy,
          size: 25,
        ),
      ),
    );
  }
}

// END OF FILE - lib/screens/live_screen.dart
