part of 'live_screen.dart';

extension _LiveScreenGuests on _LiveScreenState {
  bool get _guestActive => _guestJoined && _guestRequest != null;

  void _waitForHostVideo() {
    _startupTimer?.cancel();
    _startupTimer = Timer(const Duration(seconds: 15), () {
      if (!mounted || _liveActivationStarted || _liveActivated) return;
      unawaited(_failHostStartup(
        'Your camera did not start, so the broadcast was not opened. '
        'Check camera access and try again.',
      ));
    });
  }

  Future<void> _activateHostBroadcast() async {
    if (!mounted ||
        widget.mode != LiveMode.host ||
        !_hostJoinedAgora ||
        _liveActivationStarted ||
        _liveActivated ||
        _hostStartupFailed) {
      return;
    }
    _liveActivationStarted = true;
    _startupTimer?.cancel();
    setState(() => _status = 'Opening your broadcast...');
    try {
      final DateTime started = await LiveService.instance
          .activateLiveStart(widget.sessionId)
          .timeout(const Duration(seconds: 20));
      if (_hostStartupFailed) return;
      _liveActivated = true;
      if (!mounted) return;
      setState(() => _status = 'You are on air');
      _clk.startAt(started);
      _startClock();
    } catch (e) {
      await _failHostStartup(houseMessage(e));
    }
  }

  Future<void> _failHostStartup(String message) async {
    if (_hostStartupFailed || _liveActivated) return;
    _hostStartupFailed = true;
    _startupTimer?.cancel();
    await LiveService.instance.abortLiveStart(widget.sessionId);
    final RtcEngine? engine = _engine;
    try {
      await engine?.muteLocalAudioStream(true);
      await engine?.muteLocalVideoStream(true);
      await engine?.leaveChannel();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _joined = false;
      _error = message;
      _status = 'Broadcast setup did not finish.';
    });
  }

  bool get _localVideoEnabled => _guestActive
      ? _guestRequest?.mediaKind == 'video'
      : widget.videoEnabled;

  void _onGuestRoomChanged() {
    if (!mounted) return;
    setState(() {
      if (widget.mode == LiveMode.host) {
        _camOn = _guestState?.hostVideoEnabled ?? widget.hostVideoEnabled;
      }
    });
    if (widget.mode == LiveMode.host && _joined) {
      unawaited(
        _engine?.muteLocalVideoStream(!(_guestState?.hostVideoEnabled ?? true)) ??
            Future<void>.value(),
      );
    }
  }

  Widget? _roomAction() {
    if (widget.mode == LiveMode.call ||
        !_joined ||
        _error != null ||
        _ended) {
      return null;
    }
    return LiveGuestRoomAction(
      sessionId: widget.sessionId,
      title: widget.title,
      isHost: widget.mode == LiveMode.host,
      guestPriceInr: widget.guestPriceInr,
      requestsOpen: widget.guestRequestsOpen,
      onJoin: _joinGuest,
      onRemoved: () {
        if (_guestActive) unawaited(_returnToAudience());
      },
    );
  }

  Widget _stage() {
    if (_ended) {
      final String message = widget.mode == LiveMode.call
          ? 'The session has ended. See you again in your next session, '
              '$_callMemberName.'
          : "The session has ended. Make sure you don't miss my next Live 😊";
      return LiveEndedNotice(message);
    }
    if (_error != null) return LiveNotice(_error!, isError: true);
    final RtcEngine? engine = _engine;
    if (engine == null || !_joined) return LiveNotice(_status);
    if (widget.mode != LiveMode.call) return _broadcastStage(engine);

    final PresenceWords words = PresenceWords.of(
      host: _hostVoice,
      present: _remoteUid != null,
      left: _remoteLeft,
      subtitle: widget.subtitle,
      name: _otherName,
    );
    if (!widget.videoEnabled) {
      return LiveAudioStage(
        heading: words.heading,
        subtitle: words.note,
        pulse: _remoteUid != null,
      );
    }
    if (_remoteUid == null) {
      return LiveAudioStage(heading: words.heading, subtitle: words.note);
    }
    final Widget? video = LiveVideoStage.build(
      engine: engine,
      selfView: false,
      remoteUid: _remoteUid,
      channel: _ticket?.channel ?? '',
      portrait: true,
      pipSelf: _camOn,
      fill: false,
    );
    return video ?? LiveNotice(_status);
  }

  Widget _broadcastStage(RtcEngine engine) => LiveBroadcastStage(
        engine: engine,
        channel: _ticket?.channel ?? '',
        isHost: widget.mode == LiveMode.host,
        isGuest: _guestActive,
        hostUid: _ticket?.hostUid ?? 0,
        remoteUids: _remoteUids,
        remoteVideoUids: _remoteVideoUids,
        hostVideoEnabled:
            _guestState?.hostVideoEnabled ?? widget.hostVideoEnabled,
        guestVideoEnabled: _camOn,
        selfRequestId: _guestRequest?.id,
        guests: _guestState?.participants ?? <LiveGuestParticipant>[],
      );

  Widget _controls() => LiveControls(
        visible: _error == null && _joined && !_ended,
        publishes: _publishes,
        videoEnabled: _localVideoEnabled,
        micOn: _micOn,
        speakerOn: _speaker,
        camOn: _camOn,
        isCall: widget.mode == LiveMode.call || _guestActive,
        isOwner: _isOwner,
        callId: widget.sessionId,
        premium: widget.subtitle?.toLowerCase().contains('premium') ?? false,
        onToggleMic: () async {
          setState(() => _micOn = !_micOn);
          await _engine?.muteLocalAudioStream(!_micOn);
        },
        onToggleSpeaker: () async {
          setState(() => _speaker = !_speaker);
          await _engine?.setEnableSpeakerphone(_speaker);
        },
        onToggleCam: _toggleRoomCamera,
        onSwitchCamera: () async {
          setState(() => _frontCamera = !_frontCamera);
          await _engine?.switchCamera();
        },
        onLeave: () => _guestActive
            ? _leaveGuest()
            : Navigator.of(context).maybePop(),
        onEnd: _endSession,
      );

  Future<void> _joinGuest(LiveGuestRequest request) async {
    if (!_joined || _guestActive || _joiningGuest || _engine == null) return;
    final bool video = request.mediaKind == 'video';
    final bool consented = await askLiveGuestConsent(
      context,
      title: widget.title,
      video: video,
    );
    if (!consented || !mounted) return;
    final String? refused =
        await RoomEntry.permissions(publishes: true, video: video);
    if (refused != null) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(refused)));
      }
      return;
    }

    bool leftViewer = false;
    setState(() {
      _guestRequest = request;
      _joiningGuest = true;
      _error = null;
    });
    try {
      final AgoraTicket ticket = await LiveService.instance
          .joinLiveGuest(widget.sessionId, request.id)
          .timeout(const Duration(seconds: 20));
      if (!mounted) {
        await LiveGuestService.instance.leave(request.id);
        return;
      }
      final RtcEngine engine = _engine!;
      await engine.leaveChannel();
      leftViewer = true;
      await engine.enableAudio();
      await engine.muteLocalAudioStream(false);
      _micOn = true;
      await engine.enableVideo();
      await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      if (video) {
        await engine.startPreview();
      } else {
        await engine.stopPreview();
      }
      _ticket = ticket;
      _remoteUid = null;
      _remoteUids.clear();
      _remoteVideoUids.clear();
      _camOn = video;
      await RoomEntry.connect(engine.joinChannel(
        token: ticket.token,
        channelId: ticket.channel,
        uid: ticket.uid,
        options: ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishMicrophoneTrack: true,
          publishCameraTrack: video,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
        ),
      ));
    } catch (e) {
      await LiveGuestService.instance.leave(request.id);
      if (leftViewer && mounted) {
        await _returnToAudience(message: houseMessage(e));
      } else if (mounted) {
        setState(() {
          _guestRequest = null;
          _joiningGuest = false;
          _error = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(houseMessage(e))),
        );
      }
    }
  }

  void _markGuestConnected() {
    final LiveGuestRequest? request = _guestRequest;
    if (request == null || !_joiningGuest) return;
    setState(() {
      _joiningGuest = false;
      _guestJoined = true;
      _joined = true;
      _status = 'You are live with Ivory';
    });
    unawaited(_markGuestPresence(request));
  }

  Future<void> _markGuestPresence(LiveGuestRequest request) async {
    try {
      await LiveGuestService.instance.markJoined(request.id);
    } catch (e) {
      if (mounted) {
        await _returnToAudience(message: houseMessage(e));
      }
    }
  }

  Future<void> _renewGuestToken() async {
    final LiveGuestRequest? request = _guestRequest;
    final RtcEngine? engine = _engine;
    if (!_guestActive || request == null || engine == null) return;
    try {
      final AgoraTicket ticket = await LiveService.instance
          .joinLiveGuest(widget.sessionId, request.id);
      if (!mounted || _guestRequest?.id != request.id) return;
      await engine.renewToken(ticket.token);
      _ticket = ticket;
    } catch (e) {
      if (mounted) {
        await _returnToAudience(message: houseMessage(e));
      }
    }
  }

  Future<void> _toggleRoomCamera() async {
    final bool enabled = !_camOn;
    final RtcEngine? engine = _engine;
    setState(() => _camOn = enabled);
    try {
      await engine?.muteLocalVideoStream(!enabled);
      if (widget.mode == LiveMode.host) {
        await _guestState?.setHostVideo(enabled);
      } else if (_guestActive && _guestRequest != null) {
        await LiveGuestService.instance.setVideo(_guestRequest!.id, enabled);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _camOn = !enabled);
      await engine?.muteLocalVideoStream(enabled);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(houseMessage(e))),
      );
      return;
    }
    if (widget.mode == LiveMode.host &&
        !enabled &&
        _hostJoinedAgora &&
        !_liveActivationStarted &&
        !_liveActivated) {
      await _activateHostBroadcast();
    }
  }

  Future<void> _leaveGuest() => _returnToAudience();

  Future<void> _returnToAudience({String? message}) async {
    final RtcEngine? engine = _engine;
    final LiveGuestRequest? request = _guestRequest;
    if (engine == null) return;
    try {
      await engine.leaveChannel();
      if (request != null) await LiveGuestService.instance.leave(request.id);
      await engine.stopPreview();
      final AgoraTicket ticket = await LiveService.instance.joinLive(widget.sessionId);
      await engine.setClientRole(role: ClientRoleType.clientRoleAudience);
      _ticket = ticket;
      _guestRequest = null;
      _guestJoined = false;
      _joiningGuest = false;
      _remoteUid = null;
      _remoteUids.clear();
      _remoteVideoUids.clear();
      _camOn = true;
      await RoomEntry.connect(engine.joinChannel(
        token: ticket.token,
        channelId: ticket.channel,
        uid: ticket.uid,
        options: ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleAudience,
          publishMicrophoneTrack: false,
          publishCameraTrack: false,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
        ),
      ));
      if (!mounted) return;
      setState(() {
        _error = null;
        _status = 'Back in the audience';
      });
      if (message != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (mounted) setState(() => _error = houseMessage(e));
    }
  }
}

// END OF FILE - lib/screens/live_screen_guest_part.dart
