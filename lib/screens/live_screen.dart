import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/ivory_errors.dart';
import '../models/live_models.dart';
import '../services/auth_service.dart';
import '../services/live_service.dart';

import '../theme/ivory_theme.dart';
import '../widgets/house_consent.dart';
import '../widgets/gift_sheet.dart';
import '../widgets/gift_moment.dart';
import '../widgets/call_extension_prompt.dart';
import '../widgets/live_chat.dart';
import '../widgets/live_stage_bits.dart';
import '../widgets/call_owner_controls.dart';
import '../widgets/call_offer_layer.dart';

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
  bool _extShown = false;
  int _extTick = 0;
  bool _ended = false;
  RealtimeChannel? _statusChannel;
  int? _remoteUid;
  bool _micOn = true;
  bool _camOn = true;
  bool _frontCamera = true;

  Duration _elapsed = Duration.zero;
  Timer? _timer;

  /// Seconds this session had already used before this visit.
  /// A mistap, an incoming phone call or a lost signal must not
  /// hand anybody free minutes, nor steal paid ones.
  int _spent = 0;

  /// The other side has left the room, but the room is open.
  bool _remoteLeft = false;

  /// Set once, so leaving twice cannot write the clock twice.
  bool _wroteExit = false;

  /// Loudspeaker on an audio call. Starts on, which is how it has
  /// always behaved; the button is there to put it to the ear.
  bool _speaker = true;

  bool get _isOwner => AuthService.instance.isAdminCached;

  static const String _roomOpenNote =
      'They have stepped out. The room is still open - stay here '
      'and they can come straight back.';

  bool get _publishes =>
      widget.mode == LiveMode.host || widget.mode == LiveMode.call;

  @override
  void initState() {
    super.initState();
    if (widget.mode == LiveMode.call) {
      // A call lives in call_requests, not live_sessions. Watching
      // the wrong table is what left a member on a frozen frame.
      _statusChannel = LiveService.instance.watchCall(
        widget.sessionId,
        (String st, bool ended) {
          if ((ended || st == 'done' || st == 'completed') &&
              mounted &&
              !_ended) {
            setState(() => _ended = true);
            Future<void>.delayed(const Duration(seconds: 4), () {
              if (mounted) Navigator.of(context).pop();
            });
          }
        },
      );
      _boot();
      return;
    }
    _statusChannel = LiveService.instance.watchStatus(
      widget.sessionId,
      (String st) {
        if (st == 'ended' &&
            widget.mode != LiveMode.host &&
            mounted &&
            !_ended) {
          setState(() => _ended = true);
          Future<void>.delayed(const Duration(seconds: 4), () {
            if (mounted) Navigator.of(context).pop();
          });
        }
      },
    );
    _boot();
  }

  Future<void> _boot() async {
    // A call begins with the house promise, never with a camera.
    if (widget.mode == LiveMode.call) {
      final bool ok = await askBetweenUs(context);
      if (!ok) {
        if (mounted) Navigator.of(context).pop();
        return;
      }
      try {
        _spent = await LiveService.instance.callEnter(widget.sessionId);
      } catch (e) {
        if (!mounted) return;
        setState(() => _error = houseMessage(e));
        return;
      }
    }
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
            _remoteLeft = false;
            _status = '';
          });
        },
        onUserOffline: (RtcConnection _, int uid, UserOfflineReasonType __) {
          if (!mounted) return;
          setState(() {
            if (_remoteUid == uid) _remoteUid = null;
            if (widget.mode == LiveMode.call) {
              _remoteLeft = true;
              _status = _roomOpenNote;
            } else {
              _status = widget.mode == LiveMode.host
                  ? 'You are on air'
                  : 'The stream has paused.';
            }
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
      setState(() => _error = houseMessage(e));
    }
  }

  void _startClock() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed += const Duration(seconds: 1));
      _extTick++;
      if (widget.mode == LiveMode.call && !_extShown && _joined &&
          _remoteUid != null && _extTick % 15 == 0) {
        CallExtensionPrompt.tick(context, callId: widget.sessionId,
            elapsed: _elapsed, onShown: () => _extShown = true);
      }
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
    // LEAVING IS NOT ENDING. A mistap, a lost signal or a phone
    // call coming in must never destroy minutes that were paid
    // for. The session closes only when the minutes are gone or
    // the owner taps END SESSION.
    if (widget.mode == LiveMode.call && !_wroteExit) {
      _wroteExit = true;
      await LiveService.instance
          .callExit(widget.sessionId, _total.inSeconds);
    }
  }

  @override
  void dispose() {
    final RealtimeChannel? sc = _statusChannel;
    if (sc != null) LiveService.instance.stopWatching(sc);
    _leave();
    super.dispose();
  }

  /// Everything this session has used, including earlier visits.
  Duration get _total => _elapsed + Duration(seconds: _spent);

  String get _clock {
    final int m = _total.inMinutes;
    final String s = (_total.inSeconds % 60).toString().padLeft(2, '0');
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
          child: Stack(
            children: <Widget>[
              _room(context),
              if (widget.mode == LiveMode.call && !_isOwner)
                CallOfferLayer(
                  callId: widget.sessionId,
                  ended: _ended,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _room(BuildContext context) {
    return Column(
            children: <Widget>[
              _bar(context),
              // A broadcast gives the stage the top half and the
              // members' words the rest. A 1:1 call has no chat -
              // you are already talking.
              if (widget.mode == LiveMode.call)
                Expanded(child: Center(child: _stage()))
              else ...<Widget>[
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _stage(),
                ),
                if (_joined && _error == null)
                  Expanded(
                    child: LiveChat(
                      sessionId: widget.sessionId,
                      onGift: (String emoji, String label, String? from) =>
                          GiftMoment.show(context,
                              emoji: emoji, name: label, from: from),
                    ),
                  )
                else
                  const Expanded(child: SizedBox.shrink()),
              ],
              _controls(),
            ],
          );
  }

  // ---------------------------------------------------------------
  Widget _bar(BuildContext context) {
    final bool live = _joined && _error == null;
    return LiveTopBar(
      title: widget.title,
      clock: _clock,
      showClock: live,
      clockPrefix: widget.mode == LiveMode.call ? '' : 'LIVE  ',
      note: widget.mode == LiveMode.host && _joined
          ? 'Only you see this count'
          : null,
      // Gifts belong to a broadcast, where the room is watching
      // together. In a one-to-one session they were only ever
      // decoration, and they did nothing when tapped.
      onGift: live && widget.mode == LiveMode.watch
          ? () => showGiftSheet(context, sessionId: widget.sessionId)
          : null,
      onClose: () => Navigator.of(context).maybePop(),
    );
  }

  /// END SESSION. The only thing in Ivory that truly closes a
  /// call. Always asks first, because it cannot be undone.
  Future<void> _endSession() async {
    final bool sure = await confirmEndSession(context);
    if (!sure || !mounted) return;
    try {
      if (widget.mode == LiveMode.call && !_wroteExit) {
        _wroteExit = true;
        await LiveService.instance
            .callExit(widget.sessionId, _total.inSeconds);
      }
      await LiveService.instance.callFinish(widget.sessionId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = houseMessage(e));
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  Widget _stage() {
    if (_ended)
      return LiveNotice(widget.mode == LiveMode.call
          ? 'The session has ended. Thank you for your time.'
          : 'The broadcast has ended. Thank you for being here.');
    if (_error != null) return LiveNotice(_error!, isError: true);

    final RtcEngine? engine = _engine;
    if (engine == null || !_joined) return LiveNotice(_status);

    // Audio only: a warm panel, not a black rectangle.
    if (!widget.videoEnabled) {
      return LiveAudioStage(
        heading: _remoteUid == null
            ? (_remoteLeft ? 'They stepped out' : 'Connecting...')
            : 'Connected',
        subtitle: _remoteLeft ? _roomOpenNote : widget.subtitle,
      );
    }

    final Widget? video = LiveVideoStage.build(
      engine: engine,
      selfView: widget.mode == LiveMode.host,
      remoteUid: _remoteUid,
      channel: _ticket?.channel ?? '',
      portrait: widget.mode == LiveMode.call,
      pipSelf: widget.mode == LiveMode.call && _camOn,
    );
    return video ?? LiveNotice(_status);
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
            LiveRoundButton(
              icon: _micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
              active: _micOn,
              onTap: () async {
                setState(() => _micOn = !_micOn);
                await _engine?.muteLocalAudioStream(!_micOn);
              },
            ),
          // An audio session is held against the ear or across a
          // room, and nothing on screen let them choose. A video
          // call is already loudspeaker by its nature.
          if (_publishes && !widget.videoEnabled) ...<Widget>[
            const SizedBox(width: 14),
            LiveRoundButton(
              icon: _speaker
                  ? Icons.volume_up_rounded
                  : Icons.hearing_rounded,
              active: _speaker,
              onTap: () async {
                setState(() => _speaker = !_speaker);
                await _engine?.setEnableSpeakerphone(_speaker);
              },
            ),
          ],
          if (_publishes && widget.videoEnabled) ...<Widget>[
            const SizedBox(width: 14),
            LiveRoundButton(
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
            LiveRoundButton(
              icon: Icons.cameraswitch_rounded,
              active: true,
              onTap: () async {
                setState(() => _frontCamera = !_frontCamera);
                await _engine?.switchCamera();
              },
            ),
          ],
          const SizedBox(width: 14),
          LiveRoundButton(
            icon: Icons.call_end_rounded,
            active: true,
            danger: true,
            label: widget.mode == LiveMode.call ? 'LEAVE' : null,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          if (widget.mode == LiveMode.call && _isOwner)
            CallOwnerControls(
              callId: widget.sessionId,
              premium: widget.subtitle
                      ?.toLowerCase()
                      .contains('premium') ??
                  false,
              onEnd: _endSession,
            ),
        ],
      ),
    );
  }

}

// END OF FILE - lib/screens/live_screen.dart
