import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/ivory_errors.dart';
import '../models/live_models.dart';
import '../models/agora_ticket.dart';
import '../models/live_guest_models.dart';
import '../services/live_guest_service.dart';
import '../services/live_guest_room_state.dart';
import '../services/auth_service.dart';
import '../services/live_service.dart';

import '../theme/ivory_theme.dart';
import '../widgets/house_consent.dart';
import '../widgets/gift_sheet.dart';
import '../widgets/gift_moment.dart';
import '../widgets/live_chat.dart';
import '../widgets/live_room_body.dart';
import '../widgets/call_time_watch.dart';
import '../widgets/live_controls.dart';
import '../widgets/live_stage_bits.dart';
import '../widgets/live_broadcast_stage.dart';
import '../widgets/live_guest_consent.dart';
import '../widgets/live_guest_room_action.dart';

part 'live_screen_guest_part.dart';

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
/// Broadcast video is full-bleed and cover-cropped; chat and controls
/// float above it. One-to-one calls retain their inset layout.
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
    this.startedAt,
    this.guestPriceInr = 0,
    this.guestRequestsOpen = true,
    this.hostVideoEnabled = true,
  });

  final int sessionId;
  final String title;
  final LiveMode mode;

  /// False for an audio-only call: no camera is ever opened.
  final bool videoEnabled;
  final String? subtitle;

  /// When the broadcast opened, as the database stamped it.
  /// Handed to every handset so every clock agrees. Null on a
  /// session, which counts from connection instead.
  final DateTime? startedAt;
  final int guestPriceInr;
  final bool guestRequestsOpen;
  final bool hostVideoEnabled;

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
  final Set<int> _remoteUids = <int>{};
  LiveGuestRoomState? _guestState;
  LiveGuestRequest? _guestRequest;
  bool _guestJoined = false;
  bool _joiningGuest = false;
  bool _micOn = true;
  bool _camOn = true;
  bool _frontCamera = true;

  /// True once the session has passed the length it was booked
  /// for. It changes what is written on the screen and nothing
  /// else - the call carries on exactly as before.
  bool _timeUp = false;

  /// Counts from one shared moment, not from this handset's
  /// own arrival, so both screens agree. See RoomClock.
  final RoomClock _clk = RoomClock();
  Timer? _timer;

  /// The other side has left the room, but the room is open.
  bool _remoteLeft = false;

  /// Set once, so leaving twice cannot write the clock twice.
  bool _wroteExit = false;

  /// Loudspeaker on an audio call. Starts on, which is how it has
  /// always behaved; the button is there to put it to the ear.
  bool _speaker = true;

  bool get _isOwner => AuthService.instance.isAdminCached;

  bool get _publishes =>
      widget.mode == LiveMode.host || widget.mode == LiveMode.call || _guestJoined;

  /// WHOSE SIDE OF THE ROOM THIS IS.
  ///
  /// A one-to-one session runs the SAME screen in the SAME mode
  /// on both handsets, so the mode alone cannot tell the two
  /// people apart. Asking the mode was why Ivory's own phone
  /// announced "Ivory stepped out" when it was the member who
  /// had gone - she was reading her own name back at herself.
  /// The only honest answer is who is signed in.
  bool get _hostVoice => widget.mode == LiveMode.host || _isOwner;

  /// The name to put in those words: on Ivory's phone the title
  /// bar is already carrying the member's name.
  String? get _otherName =>
      widget.mode == LiveMode.call ? widget.title : null;

  String get _callMemberName {
    final String name = (_isOwner
            ? widget.title
            : (AuthService.instance.cachedProfile?.displayName ?? ''))
        .trim();
    return name.isEmpty || name == 'Anonymous Reader' ? 'friend' : name;
  }

  @override
  void initState() {
    super.initState();
    _camOn = widget.mode == LiveMode.host ? widget.hostVideoEnabled : true;
    if (widget.mode != LiveMode.call) {
      _guestState = LiveGuestRoomState(widget.sessionId)
        ..addListener(_onGuestRoomChanged);
      unawaited(_guestState!.start());
    }
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
    // She is the one broadcasting; she is not in her own
    // audience. Everyone else is recorded as having been here,
    // so the record can say "you were there" truthfully
    // instead of guessing from who happened to type.
    if (widget.mode != LiveMode.host) {
      LiveService.instance.enterLive(widget.sessionId);
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
        _clk.prior = await LiveService.instance.callEnter(widget.sessionId);
      } catch (e) {
        if (!mounted) return;
        setState(() => _error = houseMessage(e));
        return;
      }
    }
    try {
      // 1. Permissions. Audio-only never asks for the camera.
      setState(() => _status = 'Checking permissions...');
      final String? refused = await RoomEntry.permissions(
          publishes: _publishes, video: widget.videoEnabled);
      if (refused != null) {
        setState(() => _error = refused);
        return;
      }

      // 2. The signed ticket. Every entitlement check happens here.
      setState(() => _status = 'Opening the room...');
      // Both the ticket and the connection now have an end to
      // the waiting. See RoomEntry.ticket - this sentence used
      // to be able to stay on screen for ever.
      final AgoraTicket ticket = await RoomEntry.ticket(
        isCall: widget.mode == LiveMode.call,
        id: widget.sessionId,
      );
      _ticket = ticket;

      // The ticket is what stamps the session as begun, so the
      // one true moment exists from here on. Ask for it before
      // the camera opens. See RoomClock.anchorFromDatabase.
      if (widget.mode == LiveMode.call) {
        await _clk.anchorFromDatabase(widget.sessionId);
      }

      // 3. The engine. Brought up in RoomEntry so this file
      // stays under the paste ceiling.
      final RtcEngine engine = await RoomEntry.engine(
        appId: ticket.appId,
        isCall: widget.mode == LiveMode.call,
      );
      _engine = engine;

      engine.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection _, int __) {
          if (!mounted) return;
          setState(() {
            _joined = true;
            _status = widget.mode == LiveMode.host
                ? 'You are on air'
                : 'Waiting for the stream...';
            // A broadcast counts from when it opened - the one
            // moment every handset is handed. See RoomClock.
            if (widget.mode != LiveMode.call) {
              _clk.startAt(widget.startedAt ?? DateTime.now());
            }
          });
          _startClock();
          if (_joiningGuest) _markGuestConnected();
        },
        onUserJoined: (RtcConnection _, int uid, int __) {
          if (!mounted) return;
          setState(() {
            if (widget.mode == LiveMode.call) {
              _remoteUid = uid;
              _remoteLeft = false;
              _status = '';
              _clk.startAt(DateTime.now());
            } else {
              _remoteUids.add(uid);
              if (uid == _ticket?.hostUid) {
                _remoteUid = uid;
                _remoteLeft = false;
                _status = '';
              }
            }
          });
        },
        onUserOffline: (RtcConnection _, int uid, UserOfflineReasonType __) {
          if (!mounted) return;
          setState(() {
            _remoteUids.remove(uid);
            if (_remoteUid == uid) _remoteUid = null;
            if (widget.mode == LiveMode.call) {
              _remoteLeft = true;
              _status =
                  PresenceWords.steppedOutNote(_hostVoice, _otherName);
            } else if (uid == _ticket?.hostUid) {
              _remoteLeft = widget.mode == LiveMode.watch;
              _status = widget.mode == LiveMode.host
                  ? 'You are on air'
                  : 'The stream has paused.';
            }
          });
        },
        onTokenPrivilegeWillExpire: (RtcConnection _, String __) {
          if (_guestJoined) unawaited(_renewGuestToken());
        },
        onError: (ErrorCodeType code, String msg) {
          if (!mounted) return;
          setState(() => _error = 'Connection problem ($msg).');
        },
      ));

      await RoomEntry.ready(
        engine: engine,
        video: widget.videoEnabled,
        publishes: _publishes,
      );
      if (widget.mode == LiveMode.host && !widget.hostVideoEnabled) {
        await engine.muteLocalVideoStream(true);
      }

      await RoomEntry.connect(engine.joinChannel(
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
          autoSubscribeVideo: widget.mode != LiveMode.call || widget.videoEnabled,
        ),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = houseMessage(e));
    }
  }

  void _startClock() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      _extTick++;
      if (widget.mode != LiveMode.call || !_joined) return;
      RoomDuties.tick(
        context: context,
        tick: _extTick,
        callId: widget.sessionId,
        total: _clk.total,
        visit: _clk.visit,
        timeUpKnown: _timeUp,
        offerShown: _extShown,
        connected: _remoteUid != null,
        onTimeUp: () {
          if (mounted) setState(() => _timeUp = true);
        },
        onOfferShown: () => _extShown = true,
      );
    });
  }

  Future<void> _leave() async {
    _timer?.cancel();
    final RtcEngine? e = _engine;
    _engine = null;
    final LiveGuestRequest? guest = _guestRequest;
    if (guest != null) unawaited(LiveGuestService.instance.leave(guest.id));
    await RoomExit.leaveRoom(
      engine: e,
      sessionId: widget.sessionId,
      watching: widget.mode == LiveMode.watch,
      writeExit: _claimExit(),
      total: _clk.total,
    );
  }

  /// True once, for whichever path gets there first, so the
  /// count can never be written twice.
  bool _claimExit() {
    if (widget.mode != LiveMode.call || _wroteExit) return false;
    _wroteExit = true;
    return true;
  }

  @override
  void dispose() {
    final RealtimeChannel? sc = _statusChannel;
    if (sc != null) LiveService.instance.stopWatching(sc);
    _guestState?.removeListener(_onGuestRoomChanged);
    _guestState?.dispose();
    _leave();
    super.dispose();
  }

  /// Everything this session has used, including earlier visits.

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool did, _) {
        if (did) _leave();
      },
      child: Scaffold(
        backgroundColor: IvoryColors.burgundy,
        body: LiveScreenFrame(
          isCall: widget.mode == LiveMode.call,
          owner: _isOwner,
          timeUp: _timeUp,
          ended: _ended,
          callId: widget.sessionId,
          child: _room(context),
        ),
      ),
    );
  }

  Widget _room(BuildContext context) {
    // HOW the room is arranged now lives in `live_room_body.dart`.
    // This file was twenty bytes under the ceiling, and the fix
    // for the letterbox chat was a layout change - so the layout
    // was lifted out whole rather than squeezed in here.
    return LiveRoomBody(
      bar: _bar(context),
      stage: _stage(),
      controls: _controls(),
      action: _roomAction(),
      isCall: widget.mode == LiveMode.call,
      chat: (_joined && _error == null && !_ended)
          ? LiveChat(
              sessionId: widget.sessionId,
              onGift: (String emoji, String label, String? from) =>
                  GiftMoment.show(context,
                      emoji: emoji, name: label, from: from),
            )
          : null,
    );
  }

  // ---------------------------------------------------------------
  Widget _bar(BuildContext context) {
    // ONCE IT IS OVER, IT IS OVER. The clock used to keep
    // counting underneath the words "the broadcast has ended".
    return LiveTopBar.forRoom(
      title: widget.title,
      clock: _clk.text,
      live: _joined && _error == null && !_ended && _clk.running,
      isCall: widget.mode == LiveMode.call,
      hosting: widget.mode == LiveMode.host,
      watching: widget.mode == LiveMode.watch,
      onGift: () => showGiftSheet(context, sessionId: widget.sessionId),
      onClose: () => Navigator.of(context).maybePop(),
    );
  }

  Future<void> _endSession() async {
    final String? problem = await RoomExit.endSession(
      context,
      sessionId: widget.sessionId,
      claimExit: _claimExit,
      total: _clk.total,
    );
    if (!mounted || RoomExit.keptOpen(problem)) return;
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    Navigator.of(context).pop();
  }


}

// END OF FILE - lib/screens/live_screen.dart
