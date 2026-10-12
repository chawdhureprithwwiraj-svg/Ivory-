import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/agora_config.dart';
import '../services/auth_service.dart';
import '../services/live_beauty_service.dart';
import '../theme/ivory_theme.dart';
import '../widgets/live_beauty_panel.dart';

/// Ivory-only local camera check before Go Live. It never joins a room,
/// requests a token, publishes a track, or records anything.
class AdminLiveBeautyPreview extends StatefulWidget {
  const AdminLiveBeautyPreview({super.key});

  @override
  State<AdminLiveBeautyPreview> createState() =>
      _AdminLiveBeautyPreviewState();
}

class _AdminLiveBeautyPreviewState extends State<AdminLiveBeautyPreview>
    with WidgetsBindingObserver {
  RtcEngine? _engine;
  Future<void>? _startTask;
  Future<void>? _releaseTask;
  bool _starting = false;
  bool _cameraReady = false;
  bool _previewRunning = false;
  bool _frontCamera = true;
  bool _closing = false;
  String _status = 'Preparing a private camera preview...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTask = _startPreview();
  }

  void _setStatus(String value) {
    if (mounted && !_closing) setState(() => _status = value);
  }

  Future<void> _startPreview() async {
    if (_starting || _closing) return;
    _starting = true;
    try {
      if (!AuthService.instance.isAdminCached) {
        _setStatus('This private camera preview is for Ivory only.');
        return;
      }
      if (defaultTargetPlatform != TargetPlatform.android) {
        _setStatus('The private camera preview currently supports Android.');
        return;
      }
      if (!AgoraConfig.isConfigured) {
        _setStatus('Live video is not configured on this build.');
        return;
      }

      final PermissionStatus permission = await Permission.camera.request();
      if (!mounted || _closing) return;
      if (!permission.isGranted) {
        _setStatus('Allow camera access to preview your look.');
        return;
      }

      await LiveBeautyService.instance.load();
      if (!mounted || _closing) return;
      final RtcEngine engine = createAgoraRtcEngine();
      _engine = engine;
      await engine.initialize(RtcEngineContext(
        appId: AgoraConfig.appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));
      if (!mounted || _closing) return;
      await engine.enableVideo();
      if (!mounted || _closing) return;

      final String? note = await LiveBeautyService.instance.apply(engine);
      if (!mounted || _closing) return;
      await engine.startPreview();
      if (!mounted || _closing) return;
      _previewRunning = true;
      setState(() {
        _cameraReady = true;
        _status = 'Your private preview is ready. You are not live.';
      });
      if (note != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _closing) return;
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(note)));
        });
      }
    } catch (_) {
      await _releaseResources();
      _setStatus('The private camera preview could not start. Check camera access.');
    } finally {
      _starting = false;
    }
  }

  Future<void> _openBeautyControls() async {
    final RtcEngine? engine = _engine;
    if (engine == null || !_cameraReady || _closing) return;
    await showLiveBeautyPanel(context, engine);
  }

  Future<void> _switchCamera() async {
    final RtcEngine? engine = _engine;
    if (engine == null || !_cameraReady || _closing) return;
    try {
      await engine.switchCamera();
      if (mounted && !_closing) {
        setState(() => _frontCamera = !_frontCamera);
      }
    } catch (_) {
      if (mounted && !_closing) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('The other camera could not be opened.')),
        );
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_cameraReady || _closing) return;
    if (state == AppLifecycleState.resumed) {
      unawaited(_resumePreview());
    } else {
      unawaited(_pausePreview());
    }
  }

  Future<void> _resumePreview() async {
    final RtcEngine? engine = _engine;
    if (engine == null || _previewRunning || _closing) return;
    try {
      await engine.startPreview();
      if (!_closing) _previewRunning = true;
    } catch (_) {
      _setStatus('Camera preview paused. Close and reopen it to try again.');
    }
  }

  Future<void> _pausePreview() async {
    final RtcEngine? engine = _engine;
    if (engine == null || !_previewRunning) return;
    _previewRunning = false;
    try {
      await engine.stopPreview();
    } catch (_) {}
  }

  Future<void> _releaseResources() =>
      _releaseTask ??= _releaseResourcesNow();

  Future<void> _releaseResourcesNow() async {
    final RtcEngine? engine = _engine;
    _engine = null;
    _cameraReady = false;
    _previewRunning = false;
    if (engine == null) return;
    try {
      await engine.stopPreview();
    } catch (_) {}
    try {
      await engine.release();
    } catch (_) {}
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    await (_startTask ?? Future<void>.value());
    await _releaseResources();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _closing = true;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_releaseResources());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, _) {
          if (!didPop) unawaited(_close());
        },
        child: Scaffold(
          backgroundColor: IvoryColors.burgundy,
          body: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              if (_cameraReady && _engine != null)
                Positioned.fill(
                  child: AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: _engine!,
                      canvas: const VideoCanvas(
                        uid: 0,
                        renderMode: RenderModeType.renderModeHidden,
                      ),
                    ),
                  ),
                )
              else
                const ColoredBox(color: IvoryColors.plum),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Color(0x994A0E17),
                      Color(0x00000000),
                      Color(0x00000000),
                      Color(0xDD260B18),
                    ],
                    stops: <double>[0, 0.25, 0.52, 1],
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
                      child: Row(
                        children: <Widget>[
                          IconButton(
                            tooltip: 'Close private preview',
                            onPressed: () => unawaited(_close()),
                            icon: const Icon(Icons.arrow_back_rounded,
                                color: IvoryColors.cream),
                          ),
                          const Expanded(
                            child: Text(
                              'PRIVATE PRE-LIVE PREVIEW',
                              style: TextStyle(
                                color: IvoryColors.cream,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: _frontCamera
                                ? 'Switch to rear camera'
                                : 'Switch to front camera',
                            onPressed: _cameraReady
                                ? () => unawaited(_switchCamera())
                                : null,
                            icon: const Icon(Icons.cameraswitch_rounded,
                                color: IvoryColors.cream),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: IvoryColors.burgundy.withValues(alpha: 0.93),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: IvoryColors.gold.withValues(alpha: 0.55),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Row(
                            children: <Widget>[
                              Icon(
                                Icons.face_retouching_natural_rounded,
                                color: IvoryColors.gold,
                                size: 18,
                              ),
                              SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  'IVORY ONLY · CAMERA STAYS LOCAL',
                                  style: TextStyle(
                                    color: IvoryColors.gold,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _status,
                            style: TextStyle(
                              color: IvoryColors.cream.withValues(alpha: 0.95),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'No room joined, no token requested, no broadcast '
                            'started. These are the same simple beauty controls '
                            'used in your host broadcast.',
                            style: TextStyle(
                              color: IvoryColors.cream.withValues(alpha: 0.72),
                              fontSize: 10.5,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _cameraReady
                                  ? () => unawaited(_openBeautyControls())
                                  : null,
                              icon: const Icon(Icons.tune_rounded, size: 18),
                              label: const Text('ADJUST BEAUTY'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: IvoryColors.gold,
                                foregroundColor: IvoryColors.burgundy,
                                disabledBackgroundColor:
                                    IvoryColors.surfaceWarm,
                                disabledForegroundColor: IvoryColors.textFaint,
                                side: const BorderSide(
                                    color: IvoryColors.amber, width: 1.2),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'No face-shape or eye-colour effects are included.',
                            style: TextStyle(
                              color: IvoryColors.cream,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

// END OF FILE - lib/screens/admin_live_beauty_preview.dart
