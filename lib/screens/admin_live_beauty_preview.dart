import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/agora_config.dart';
import '../services/auth_service.dart';
import '../services/live_beauty_service.dart';
import '../theme/ivory_theme.dart';
import '../widgets/live_beauty_panel.dart';

/// Private local-camera preview; it never joins a channel or publishes video.
class AdminLiveBeautyPreview extends StatefulWidget {
  const AdminLiveBeautyPreview({super.key});

  @override
  State<AdminLiveBeautyPreview> createState() =>
      _AdminLiveBeautyPreviewState();
}

class _AdminLiveBeautyPreviewState extends State<AdminLiveBeautyPreview> {
  RtcEngine? _engine;
  Future<void>? _startTask;
  Future<void>? _releaseTask;
  RtcEngine? _releasedEngine;
  bool _ready = false;
  bool _frontCamera = true;
  bool _closing = false;
  String _status = 'Opening your camera preview...';

  @override
  void initState() {
    super.initState();
    _startTask = _startPreview();
    unawaited(_startTask!);
  }

  Future<void> _startPreview() async {
    if (!AuthService.instance.isAdminCached) {
      if (mounted) setState(() => _status = 'This preview is for Ivory only.');
      return;
    }
    if (!AgoraConfig.isConfigured) {
      if (mounted) setState(() => _status = 'Live video is not configured.');
      return;
    }
    final PermissionStatus camera = await Permission.camera.request();
    if (!mounted || _closing) return;
    if (!camera.isGranted) {
      if (mounted) {
        setState(() => _status = 'Allow camera access to preview your look.');
      }
      return;
    }

    final RtcEngine engine = createAgoraRtcEngine();
    try {
      await engine.initialize(RtcEngineContext(
        appId: AgoraConfig.appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));
      if (!mounted || _closing) {
        await _release(engine);
        return;
      }
      _engine = engine;
      await LiveBeautyService.instance.load();
      if (!mounted || _closing) return;
      await engine.enableVideo();
      if (!mounted || _closing) return;
      await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      if (!mounted || _closing) return;
      await engine.startPreview();
      if (!mounted || _closing) return;
      final String? note = await LiveBeautyService.instance.apply(engine);
      if (!mounted || _closing) return;
      setState(() {
        _ready = true;
        _status = note ?? '';
      });
    } catch (_) {
      await _release(engine);
      if (identical(_engine, engine)) _engine = null;
      if (!mounted || _closing) return;
      setState(() {
        _ready = false;
        _status = 'The camera preview could not be started. Check camera access.';
      });
    }
  }

  Future<void> _release(RtcEngine engine) {
    if (identical(_releasedEngine, engine)) {
      return _releaseTask ?? Future<void>.value();
    }
    _releasedEngine = engine;
    _releaseTask = _releaseNow(engine);
    return _releaseTask!;
  }

  Future<void> _releaseNow(RtcEngine engine) async {
    try {
      await engine.stopPreview();
    } catch (_) {}
    try {
      await engine.release();
    } catch (_) {}
  }

  Future<void> _releaseAfterStartup({bool updateUi = false}) async {
    final Future<void>? start = _startTask;
    if (start != null) {
      try {
        await start;
      } catch (_) {}
    }
    final RtcEngine? engine = _engine;
    if (engine == null) return;
    if (updateUi && mounted) {
      setState(() {
        _engine = null;
        _ready = false;
      });
    } else {
      _engine = null;
      _ready = false;
    }
    await _release(engine);
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    await _releaseAfterStartup(updateUi: true);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _switchCamera() async {
    final RtcEngine? engine = _engine;
    if (engine == null || !_ready) return;
    try {
      await engine.switchCamera();
      if (mounted) setState(() => _frontCamera = !_frontCamera);
    } catch (_) {}
  }

  Future<void> _openBeauty() async {
    final RtcEngine? engine = _engine;
    if (engine == null || !_ready) return;
    await showLiveBeautyPanel(context, engine);
  }

  @override
  void dispose() {
    _closing = true;
    unawaited(_releaseAfterStartup());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final RtcEngine? engine = _engine;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, _) {
        if (!didPop) unawaited(_close());
      },
      child: Scaffold(
        backgroundColor: IvoryColors.burgundy,
        body: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            if (_ready && engine != null)
              Positioned.fill(
                child: AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: engine,
                    canvas: const VideoCanvas(
                      uid: 0,
                      renderMode: RenderModeType.renderModeHidden,
                    ),
                  ),
                ),
              )
            else
              Container(color: IvoryColors.plum),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Color(0x99000000),
                    Color(0x00000000),
                    Color(0x00000000),
                    Color(0xCC260B18),
                  ],
                  stops: <double>[0, 0.24, 0.55, 1],
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
                          tooltip: 'Close preview',
                          onPressed: _close,
                          icon: const Icon(Icons.arrow_back_rounded,
                              color: IvoryColors.cream),
                        ),
                        const Expanded(
                          child: Text(
                            'PRIVATE CAMERA PREVIEW',
                            style: TextStyle(
                              color: IvoryColors.cream,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: _frontCamera ? 'Switch camera' : 'Use front camera',
                          onPressed: _ready ? _switchCamera : null,
                          icon: const Icon(Icons.cameraswitch_rounded,
                              color: IvoryColors.cream),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (!_ready || _status.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
                      child: Text(
                        _status,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: IvoryColors.cream,
                          fontSize: 13,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: IvoryColors.burgundy.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: IvoryColors.gold.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'YOUR CAMERA LOOK',
                          style: TextStyle(
                            color: IvoryColors.gold,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.3,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Preview the skin controls here before the broadcast. '
                          'Nothing is published until you go live.',
                          style: TextStyle(
                            color: IvoryColors.cream.withValues(alpha: 0.9),
                            fontSize: 12.5,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _ready ? _openBeauty : null,
                                icon: const Icon(
                                    Icons.face_retouching_natural_rounded),
                                label: const Text('BEAUTY'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: IvoryColors.cream,
                                  side: const BorderSide(
                                      color: IvoryColors.gold),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _close,
                                icon: const Icon(Icons.check_rounded),
                                label: const Text('DONE'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: IvoryColors.gold,
                                  foregroundColor: IvoryColors.burgundy,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
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
}

// END OF FILE - lib/screens/admin_live_beauty_preview.dart
