import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:google_mlkit_face_mesh_detection/google_mlkit_face_mesh_detection.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/agora_config.dart';
import 'admin_beauty_controls_sheet.dart';
import 'admin_live_beauty_preview_shell.dart';
import '../services/admin_beauty_agora_frame_sink.dart';
import '../services/admin_beauty_face_filter.dart';
import '../services/admin_beauty_frame_processor.dart';
import '../services/auth_service.dart';

/// Isolated Android-only camera prototype. It never joins a room.
/// Agora supplies the camera frames; the raw-frame observer is used only as a
/// capture input. Processed pixels go through a separate Agora custom track.
/// The preview and custom-track adapter receive the same processed RGBA frame.
class AdminLiveBeautyPreview extends StatefulWidget {
  const AdminLiveBeautyPreview({super.key});

  @override
  State<AdminLiveBeautyPreview> createState() =>
      _AdminLiveBeautyPreviewState();
}

class _AdminLiveBeautyPreviewState extends State<AdminLiveBeautyPreview>
    with WidgetsBindingObserver {
  final AdminBeautyFrameProcessor _processor =
      const AdminBeautyFrameProcessor();
  final AdminBeautyFaceFilter _faceFilter = const AdminBeautyFaceFilter();
  final Stopwatch _monotonic = Stopwatch()..start();

  RtcEngine? _engine;
  VideoFrameObserver? _observer;
  FaceMeshDetector? _detector;
  AdminBeautyAgoraFrameSink? _frameSink;
  ui.Image? _previewImage;
  AdminBeautyTuning _tuning = const AdminBeautyTuning();
  List<Offset> _faceOval = <Offset>[];
  int _width = 0;
  int _height = 0;
  int _imageVersion = 0;
  int _fpsFrameCount = 0;
  DateTime? _lastAcceptedFrame;
  DateTime _fpsWindowStart = DateTime.now();
  double _fps = 0;
  int _processingMilliseconds = 0;
  String _status = 'Preparing the private on-device preview...';
  String _sourceStatus = 'Preparing Agora custom video source...';
  bool _showMesh = false;
  bool _cameraReady = false;
  bool _previewRunning = false;
  bool _frontCamera = true;
  bool _starting = false;
  bool _processing = false;
  bool _closing = false;
  bool _frameSinkFailed = false;
  bool _frameSinkNoteShown = false;
  Future<void>? _releaseTask;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_startPrototype());
  }

  Future<void> _startPrototype() async {
    if (_starting || _closing) return;
    _starting = true;
    RtcEngine? engine;
    try {
      if (!AuthService.instance.isAdminCached) {
        _setStatus('This private camera prototype is for Ivory only.');
        return;
      }
      if (defaultTargetPlatform != TargetPlatform.android) {
        _setStatus('The on-device face-mesh prototype currently supports Android only.');
        return;
      }
      if (!AgoraConfig.isConfigured) {
        _setStatus('Live video is not configured on this build.');
        return;
      }

      final PermissionStatus permission = await Permission.camera.request();
      if (!mounted || _closing) return;
      if (!permission.isGranted) {
        _setStatus('Allow camera access to test the private preview.');
        return;
      }

      _detector = FaceMeshDetector(option: FaceMeshDetectorOptions.faceMesh);
      engine = createAgoraRtcEngine();
      await engine.initialize(RtcEngineContext(
        appId: AgoraConfig.appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));
      _engine = engine;
      if (!mounted || _closing) return;
      await engine.enableVideo();
      if (!mounted || _closing) return;

      try {
        _frameSink = await AdminBeautyAgoraFrameSink.attach(engine);
        _sourceStatus = 'Agora custom track ready · not joined to a room';
      } catch (_) {
        _frameSinkFailed = true;
        _sourceStatus = 'Agora custom track unavailable · local preview still works';
      }
      if (!mounted || _closing) return;

      final VideoFrameObserver observer = VideoFrameObserver(
        onCaptureVideoFrame: _onCaptureVideoFrame,
      );
      _observer = observer;
      engine.getMediaEngine().registerVideoFrameObserver(observer);
      await engine.startPreview();
      if (!mounted || _closing) return;
      _previewRunning = true;
      setState(() {
        _cameraReady = true;
        _status = 'Hold your face in view; the mesh is still locking on.';
      });
    } catch (_) {
      if (engine != null && identical(engine, _engine)) {
        await _releaseResources();
      } else if (engine != null) {
        try {
          await engine.release();
        } catch (_) {}
      }
      await _releaseResources();
      if (mounted && !_closing) {
        setState(() {
          _cameraReady = false;
          _status = 'The private camera preview could not be started. Check camera access.';
        });
      }
    } finally {
      _starting = false;
    }
  }

  void _setStatus(String value) {
    if (mounted && !_closing) setState(() => _status = value);
  }

  void _onCaptureVideoFrame(VideoSourceType sourceType, VideoFrame videoFrame) {
    if (_closing ||
        !_cameraReady ||
        _processing ||
        (sourceType != VideoSourceType.videoSourceCameraPrimary &&
            sourceType != VideoSourceType.videoSourceCamera)) {
      return;
    }
    final DateTime now = DateTime.now();
    final DateTime? previous = _lastAcceptedFrame;
    if (previous != null &&
        now.difference(previous) < const Duration(milliseconds: 80)) {
      return;
    }

    final int? width = videoFrame.width;
    final int? height = videoFrame.height;
    final Uint8List? y = videoFrame.yBuffer;
    final Uint8List? u = videoFrame.uBuffer;
    final Uint8List? v = videoFrame.vBuffer;
    if (width == null ||
        height == null ||
        y == null ||
        u == null ||
        v == null ||
        width < 2 ||
        height < 2) {
      return;
    }
    final int yStride = videoFrame.yStride ?? width;
    final int uStride = videoFrame.uStride ?? width ~/ 2;
    final int vStride = videoFrame.vStride ?? width ~/ 2;
    final int rotation = videoFrame.rotation ?? 0;
    try {
      final CapturedI420Frame copy = CapturedI420Frame(
        y: Uint8List.fromList(y),
        u: Uint8List.fromList(u),
        v: Uint8List.fromList(v),
        width: width,
        height: height,
        yStride: yStride,
        uStride: uStride,
        vStride: vStride,
        rotationDegrees: rotation,
      );
      _lastAcceptedFrame = now;
      _processing = true;
      unawaited(_processCapturedFrame(copy));
    } catch (_) {
      // Invalid/unexpected capture data is ignored; no effect is applied.
    }
  }

  Future<void> _processCapturedFrame(CapturedI420Frame captured) async {
    final Stopwatch processingClock = Stopwatch()..start();
    final int rotation = captured.rotationDegrees;
    final int uprightWidth = (rotation == 90 || rotation == 270)
        ? captured.height
        : captured.width;
    final int uprightHeight = (rotation == 90 || rotation == 270)
        ? captured.width
        : captured.height;
    try {
      final Uint8List packedNv21 = _processor.i420ToNv21(captured);
      final Uint8List uprightNv21 = _processor.rotateNv21(
        packedNv21,
        width: captured.width,
        height: captured.height,
        clockwiseDegrees: rotation,
      );
      final InputImage input = InputImage.fromBytes(
        bytes: uprightNv21,
        metadata: InputImageMetadata(
          size: Size(uprightWidth.toDouble(), uprightHeight.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow: uprightWidth,
        ),
      );
      final FaceMeshDetector? detector = _detector;
      if (detector == null) return;
      final List<FaceMesh> meshes = await detector.processImage(input);
      if (_closing || !mounted) return;
      final FaceMesh? mesh = _largestMesh(meshes);
      final AdminBeautyFaceGeometry? geometry = _geometryFor(mesh);
      final Uint8List rgba = _processor.i420ToRgba(captured);
      final Uint8List uprightRgba = _processor.rotateRgba(
        rgba,
        width: captured.width,
        height: captured.height,
        clockwiseDegrees: rotation,
      );
      final Uint8List output = _faceFilter.applyToRgba(
        rgba: uprightRgba,
        width: uprightWidth,
        height: uprightHeight,
        face: geometry,
        tuning: _tuning,
      );
      final ProcessedBeautyFrame frame = ProcessedBeautyFrame(
        rgba: output,
        width: uprightWidth,
        height: uprightHeight,
        rotationDegrees: 0,
        timestampMilliseconds: _monotonic.elapsedMilliseconds,
      );

      _width = uprightWidth;
      _height = uprightHeight;
      _faceOval = geometry?.oval ?? <Offset>[];
      _queuePreviewFrame(frame);
      await _pushToUnjoinedCustomTrack(frame);
      _updateFps(DateTime.now());
      _processingMilliseconds = processingClock.elapsedMilliseconds;
      if (mounted && !_closing) {
        setState(() {
          _status = geometry == null
              ? 'No face mesh · face-only effects are paused.'
              : 'Face mesh found · effects stay inside Ivory’s face area.';
        });
      }
    } catch (_) {
      // Fail closed: preserve the upright raw pixels and never run face
      // effects without a valid face mesh.
      try {
        final Uint8List rgba = _processor.i420ToRgba(captured);
        final Uint8List uprightRgba = _processor.rotateRgba(
          rgba,
          width: captured.width,
          height: captured.height,
          clockwiseDegrees: rotation,
        );
        final ProcessedBeautyFrame passthrough = ProcessedBeautyFrame(
          rgba: uprightRgba,
          width: uprightWidth,
          height: uprightHeight,
          rotationDegrees: 0,
          timestampMilliseconds: _monotonic.elapsedMilliseconds,
        );
        _width = uprightWidth;
        _height = uprightHeight;
        _faceOval = <Offset>[];
        _queuePreviewFrame(passthrough);
      } catch (_) {}
      if (mounted && !_closing) {
        setState(() => _status =
            'Mesh or frame processing paused · showing the raw camera fallback.');
      }
    } finally {
      _processing = false;
    }
  }

  FaceMesh? _largestMesh(List<FaceMesh> meshes) {
    if (meshes.isEmpty) return null;
    return meshes.reduce((FaceMesh a, FaceMesh b) {
      final double areaA = a.boundingBox.width * a.boundingBox.height;
      final double areaB = b.boundingBox.width * b.boundingBox.height;
      return areaA >= areaB ? a : b;
    });
  }

  AdminBeautyFaceGeometry? _geometryFor(FaceMesh? mesh) {
    if (mesh == null) return null;
    List<Offset> points(FaceMeshContourType type) =>
        (mesh.contours[type] ?? const <FaceMeshPoint>[])
            .map((FaceMeshPoint point) => Offset(point.x, point.y))
            .toList(growable: false);

    final List<Offset> oval = points(FaceMeshContourType.faceOval);
    if (oval.length < 3) return null;
    final List<List<Offset>> protected = <List<Offset>>[
      points(FaceMeshContourType.leftEye),
      points(FaceMeshContourType.rightEye),
      points(FaceMeshContourType.leftEyebrowTop),
      points(FaceMeshContourType.leftEyebrowBottom),
      points(FaceMeshContourType.rightEyebrowTop),
      points(FaceMeshContourType.rightEyebrowBottom),
      points(FaceMeshContourType.upperLipTop),
      points(FaceMeshContourType.upperLipBottom),
      points(FaceMeshContourType.lowerLipTop),
      points(FaceMeshContourType.lowerLipBottom),
      points(FaceMeshContourType.noseBridge),
    ].where((List<Offset> contour) => contour.length >= 3).toList();
    return AdminBeautyFaceGeometry(oval: oval, protectedContours: protected);
  }

  Future<void> _pushToUnjoinedCustomTrack(ProcessedBeautyFrame frame) async {
    final AdminBeautyAgoraFrameSink? sink = _frameSink;
    if (sink == null || _frameSinkFailed) return;
    try {
      // This private screen has no channel, so this cannot publish to anyone.
      // The preview and sink both consume these exact processed RGBA bytes.
      await sink.push(frame);
    } catch (_) {
      _frameSinkFailed = true;
      if (mounted && !_closing && !_frameSinkNoteShown) {
        _frameSinkNoteShown = true;
        setState(() => _sourceStatus =
            'Agora custom-frame probe unavailable · local preview continues');
      }
    }
  }

  void _queuePreviewFrame(ProcessedBeautyFrame frame) {
    final int version = ++_imageVersion;
    ui.decodeImageFromPixels(
      frame.rgba,
      frame.width,
      frame.height,
      ui.PixelFormat.rgba8888,
      (ui.Image image) {
        if (!mounted || _closing || version != _imageVersion) {
          image.dispose();
          return;
        }
        final ui.Image? previous = _previewImage;
        setState(() => _previewImage = image);
        if (previous != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
        }
      },
      rowBytes: frame.width * 4,
    );
  }

  void _updateFps(DateTime now) {
    _fpsFrameCount++;
    final Duration elapsed = now.difference(_fpsWindowStart);
    if (elapsed >= const Duration(seconds: 1)) {
      _fps = _fpsFrameCount / elapsed.inMilliseconds * 1000;
      _fpsFrameCount = 0;
      _fpsWindowStart = now;
    }
  }

  Future<void> _switchCamera() async {
    final RtcEngine? engine = _engine;
    if (engine == null || !_cameraReady || _closing) return;
    try {
      await engine.switchCamera();
      if (mounted) {
        setState(() {
          _frontCamera = !_frontCamera;
          _faceOval = <Offset>[];
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('The other camera could not be opened.')),
        );
      }
    }
  }

  Future<void> _openBeautyControls() async {
    if (!_cameraReady || _closing) return;
    await showAdminBeautyControlsSheet(
      context: context,
      initialTuning: _tuning,
      onChanged: (AdminBeautyTuning tuning) {
        if (mounted && !_closing) setState(() => _tuning = tuning);
      },
    );
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
      _previewRunning = true;
    } catch (_) {}
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
    final VideoFrameObserver? observer = _observer;
    _observer = null;
    if (engine != null) {
      try {
        await engine.stopPreview();
      } catch (_) {}
      if (observer != null) {
        try {
          engine.getMediaEngine().unregisterVideoFrameObserver(observer);
        } catch (_) {}
      }
    }
    final AdminBeautyAgoraFrameSink? sink = _frameSink;
    _frameSink = null;
    try {
      await sink?.dispose();
    } catch (_) {}
    if (engine != null) {
      try {
        await engine.release();
      } catch (_) {}
    }
    final FaceMeshDetector? detector = _detector;
    _detector = null;
    try {
      await detector?.close();
    } catch (_) {}
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    await _releaseResources();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _closing = true;
    WidgetsBinding.instance.removeObserver(this);
    final ui.Image? image = _previewImage;
    _previewImage = null;
    image?.dispose();
    unawaited(_releaseResources());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, _) {
          if (!didPop) unawaited(_close());
        },
        child: AdminBeautyPreviewShell(
          engine: _engine,
          image: _previewImage,
          width: _width,
          height: _height,
          frontCamera: _frontCamera,
          cameraReady: _cameraReady,
          showMesh: _showMesh,
          faceOval: _faceOval,
          fps: _fps,
          processingMilliseconds: _processingMilliseconds,
          status: _status,
          sourceStatus: _sourceStatus,
          onClose: () => unawaited(_close()),
          onSwitchCamera: () => unawaited(_switchCamera()),
          onAdjustLook: () => unawaited(_openBeautyControls()),
          onToggleMesh: () => setState(() => _showMesh = !_showMesh),
        ),
      );
}

// END OF FILE - lib/screens/admin_live_beauty_preview.dart
