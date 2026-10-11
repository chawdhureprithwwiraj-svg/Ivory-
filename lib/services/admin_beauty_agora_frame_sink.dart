import 'package:agora_rtc_engine/agora_rtc_engine.dart';

import 'admin_beauty_frame_processor.dart';

/// Adapter from the prototype's one processed RGBA buffer to Agora's custom
/// video track. The preview and publisher must receive the same frame object.
/// This class does not join a channel or start a transmission by itself.
class AdminBeautyAgoraFrameSink {
  AdminBeautyAgoraFrameSink._({
    required RtcEngine engine,
    required int videoTrackId,
  })  : _engine = engine,
        videoTrackId = videoTrackId;

  final RtcEngine _engine;
  final int videoTrackId;
  bool _disposed = false;

  static Future<AdminBeautyAgoraFrameSink> attach(RtcEngine engine) async {
    final int trackId = await engine.createCustomVideoTrack();
    if (trackId == 0xffffffff) {
      throw StateError('Agora did not create the custom video track.');
    }
    return AdminBeautyAgoraFrameSink._(
      engine: engine,
      videoTrackId: trackId,
    );
  }

  /// Pushes the processed RGBA bytes; dimensions/stride/rotation/timestamp
  /// travel with those exact bytes. A channel must separately publish this
  /// track using ChannelMediaOptions.publishCustomVideoTrack and its ID.
  Future<void> push(ProcessedBeautyFrame processed) async {
    if (_disposed) return;
    await _engine.getMediaEngine().pushVideoFrame(
      frame: ExternalVideoFrame(
        type: VideoBufferType.videoBufferRawData,
        format: VideoPixelFormat.videoPixelRgba,
        buffer: processed.rgba,
        stride: processed.width,
        height: processed.height,
        rotation: processed.rotationDegrees,
        timestamp: processed.timestampMilliseconds,
      ),
      videoTrackId: videoTrackId,
    );
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _engine.destroyCustomVideoTrack(videoTrackId);
  }
}

// END OF FILE - lib/services/admin_beauty_agora_frame_sink.dart
