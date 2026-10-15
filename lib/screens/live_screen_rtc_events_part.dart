part of 'live_screen.dart';

extension _LiveScreenRtcEvents on _LiveScreenState {
  void _registerRtcEvents(RtcEngine engine) {
    engine.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (RtcConnection _, int __) {
        if (!mounted) return;
        if (widget.mode == LiveMode.host) _hostJoinedAgora = true;
        setState(() {
          _joined = true;
          _status = widget.mode == LiveMode.host
              ? (_camOn ? 'Starting your video...' : 'Opening your broadcast...')
              : 'Waiting for the stream...';
          if (widget.mode == LiveMode.watch) {
            _clk.startAt(widget.startedAt ?? DateTime.now());
          }
        });
        if (widget.mode == LiveMode.host) {
          if (!_camOn || _hostVideoPublished) {
            unawaited(_activateHostBroadcast());
          } else {
            _waitForHostVideo();
          }
        } else {
          _startClock();
        }
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
        if (widget.mode == LiveMode.call) {
          AudioCallBeatMeter.instance.clearRemote();
        }
        setState(() {
          _remoteUids.remove(uid);
          _remoteVideoUids.remove(uid);
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
      onFirstLocalVideoFramePublished: (RtcConnection _, int __) {
        _hostVideoPublished = true;
        if (widget.mode == LiveMode.host && _hostJoinedAgora) {
          unawaited(_activateHostBroadcast());
        }
      },
      onRemoteVideoStateChanged: (
        RtcConnection _,
        int uid,
        RemoteVideoState state,
        RemoteVideoStateReason __,
        int ___,
      ) {
        if (!mounted) return;
        setState(() {
          if (state == RemoteVideoState.remoteVideoStateStarting ||
              state == RemoteVideoState.remoteVideoStateDecoding ||
              state == RemoteVideoState.remoteVideoStateFrozen) {
            _remoteVideoUids.add(uid);
          } else {
            _remoteVideoUids.remove(uid);
          }
        });
      },
      onFirstRemoteVideoFrame: (
        RtcConnection _,
        int uid,
        int __,
        int ___,
        int ____,
      ) {
        if (!mounted) return;
        setState(() => _remoteVideoUids.add(uid));
      },
      onAudioVolumeIndication: (
        RtcConnection _,
        List<AudioVolumeInfo> speakers,
        int speakerNumber,
        int __,
      ) {
        AudioCallBeatMeter.instance.update(
          speakers,
          speakerNumber,
          localMuted: !_micOn,
        );
      },
      onTokenPrivilegeWillExpire: (RtcConnection _, String __) {
        if (_guestJoined) unawaited(_renewGuestToken());
      },
      onError: (ErrorCodeType code, String msg) {
        if (!mounted) return;
        final String problem = 'Connection problem ($msg).';
        if (widget.mode == LiveMode.host && !_liveActivated) {
          unawaited(_failHostStartup(problem));
        } else {
          setState(() => _error = problem);
        }
      },
    ));
  }
}

// END OF FILE - lib/screens/live_screen_rtc_events_part.dart
