import 'dart:math' as math;
import 'dart:typed_data';

/// A defensive copy of one Agora I420 capture frame. The observer's native
/// buffers can be reused as soon as its callback returns, so the screen copies
/// each plane before handing it to this processor.
class CapturedI420Frame {
  const CapturedI420Frame({
    required this.y,
    required this.u,
    required this.v,
    required this.width,
    required this.height,
    required this.yStride,
    required this.uStride,
    required this.vStride,
    required this.rotationDegrees,
  });

  final Uint8List y;
  final Uint8List u;
  final Uint8List v;
  final int width;
  final int height;
  final int yStride;
  final int uStride;
  final int vStride;
  final int rotationDegrees;
}

/// Small, non-persistent tuning values for the isolated Android prototype.
/// They are not connected to broadcast or call controls yet.
class AdminBeautyTuning {
  const AdminBeautyTuning({
    this.smoothing = 0.25,
    this.brightening = 0,
    this.slimming = 0,
  });

  final double smoothing;
  final double brightening;
  final double slimming;

  AdminBeautyTuning copyWith({
    double? smoothing,
    double? brightening,
    double? slimming,
  }) =>
      AdminBeautyTuning(
        smoothing: _unit(smoothing ?? this.smoothing),
        brightening: _unit(brightening ?? this.brightening),
        slimming: _unit(slimming ?? this.slimming),
      );

  static double _unit(double value) => value.clamp(0.0, 1.0).toDouble();
}

/// Coordinates are in the upright processed-frame pixel space. Protected
/// contours keep smoothing/brightening away from eyes, brows, lips and nose.
class AdminBeautyFaceGeometry {
  const AdminBeautyFaceGeometry({
    required this.oval,
    this.protectedContours = const <List<Offset>>[],
  });

  final List<Offset> oval;
  final List<List<Offset>> protectedContours;
}

/// One processed RGBA frame. The exact same buffer is painted in the private
/// preview and passed to Agora's custom video-track adapter.
class ProcessedBeautyFrame {
  const ProcessedBeautyFrame({
    required this.rgba,
    required this.width,
    required this.height,
    required this.rotationDegrees,
    required this.timestampMilliseconds,
  });

  final Uint8List rgba;
  final int width;
  final int height;
  final int rotationDegrees;
  final int timestampMilliseconds;
}

/// CPU-side prototype processor. Effects are bounded by the face-oval mesh;
/// frames with missing or invalid landmarks are passed through unchanged.
class AdminBeautyFrameProcessor {
  const AdminBeautyFrameProcessor();

  /// Packs padded I420 planes into the tightly-packed NV21 byte layout ML Kit
  /// accepts on Android. All Agora row strides are honored.
  Uint8List i420ToNv21(CapturedI420Frame frame) {
    _validateI420(frame);
    final int width = frame.width;
    final int height = frame.height;
    final int ySize = width * height;
    final Uint8List output = Uint8List(ySize + ySize ~/ 2);

    for (int row = 0; row < height; row++) {
      final int inputStart = row * frame.yStride;
      final int outputStart = row * width;
      output.setRange(
        outputStart,
        outputStart + width,
        frame.y,
        inputStart,
      );
    }

    final int chromaWidth = width ~/ 2;
    final int chromaHeight = height ~/ 2;
    for (int row = 0; row < chromaHeight; row++) {
      for (int column = 0; column < chromaWidth; column++) {
        final int uIndex = row * frame.uStride + column;
        final int vIndex = row * frame.vStride + column;
        final int outputIndex = ySize + row * width + column * 2;
        output[outputIndex] = frame.v[vIndex];
        output[outputIndex + 1] = frame.u[uIndex];
      }
    }
    return output;
  }

  /// Converts padded I420 planes into tightly packed RGBA pixels.
  Uint8List i420ToRgba(CapturedI420Frame frame) {
    _validateI420(frame);
    final int width = frame.width;
    final int height = frame.height;
    final Uint8List output = Uint8List(width * height * 4);
    for (int y = 0; y < height; y++) {
      final int yRow = y * frame.yStride;
      final int chromaRow = (y >> 1);
      final int uRow = chromaRow * frame.uStride;
      final int vRow = chromaRow * frame.vStride;
      for (int x = 0; x < width; x++) {
        final int yi = yRow + x;
        final int ui = uRow + (x >> 1);
        final int vi = vRow + (x >> 1);
        _writeRgba(output, (y * width + x) * 4, frame.y[yi], frame.u[ui], frame.v[vi]);
      }
    }
    return output;
  }

  void _validateI420(CapturedI420Frame frame) {
    final int width = frame.width;
    final int height = frame.height;
    if (width < 2 || height < 2 || width.isOdd || height.isOdd) {
      throw const FormatException('I420 frame must have even dimensions.');
    }
    final int chromaWidth = width ~/ 2;
    final int chromaHeight = height ~/ 2;
    if (frame.yStride < width ||
        frame.uStride < chromaWidth ||
        frame.vStride < chromaWidth ||
        frame.y.length < (height - 1) * frame.yStride + width ||
        frame.u.length < (chromaHeight - 1) * frame.uStride + chromaWidth ||
        frame.v.length < (chromaHeight - 1) * frame.vStride + chromaWidth) {
      throw const FormatException('Agora I420 plane stride is invalid.');
    }
    _validateRotation(frame.rotationDegrees);
  }

  /// Rotates a tightly packed NV21 frame clockwise into upright pixel space.
  Uint8List rotateNv21(
    Uint8List source, {
    required int width,
    required int height,
    required int clockwiseDegrees,
  }) {
    _validateRotation(clockwiseDegrees);
    if (source.length != width * height * 3 ~/ 2 ||
        width.isOdd ||
        height.isOdd) {
      throw const FormatException('NV21 buffer dimensions do not match.');
    }
    if (clockwiseDegrees == 0) return source;
    final bool quarterTurn = clockwiseDegrees == 90 || clockwiseDegrees == 270;
    final int outWidth = quarterTurn ? height : width;
    final int outHeight = quarterTurn ? width : height;
    final int ySize = width * height;
    final Uint8List output = Uint8List(source.length);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int outX;
        final int outY;
        switch (clockwiseDegrees) {
          case 90:
            outX = height - 1 - y;
            outY = x;
            break;
          case 180:
            outX = width - 1 - x;
            outY = height - 1 - y;
            break;
          case 270:
            outX = y;
            outY = width - 1 - x;
            break;
          default:
            outX = x;
            outY = y;
            break;
        }
        output[outY * outWidth + outX] = source[y * width + x];
      }
    }

    final int chromaWidth = width ~/ 2;
    final int chromaHeight = height ~/ 2;
    final int outChromaWidth = outWidth ~/ 2;
    for (int y = 0; y < chromaHeight; y++) {
      for (int x = 0; x < chromaWidth; x++) {
        final int outX;
        final int outY;
        switch (clockwiseDegrees) {
          case 90:
            outX = chromaHeight - 1 - y;
            outY = x;
            break;
          case 180:
            outX = chromaWidth - 1 - x;
            outY = chromaHeight - 1 - y;
            break;
          case 270:
            outX = y;
            outY = chromaWidth - 1 - x;
            break;
          default:
            outX = x;
            outY = y;
            break;
        }
        final int sourceIndex = ySize + (y * chromaWidth + x) * 2;
        final int outputIndex = outY * outChromaWidth * 2 + outX * 2;
        final int outputChromaStart = outWidth * outHeight;
        output[outputChromaStart + outputIndex] = source[sourceIndex];
        output[outputChromaStart + outputIndex + 1] = source[sourceIndex + 1];
      }
    }
    return output;
  }

  /// Rotates tightly packed RGBA pixels clockwise into upright pixel space.
  Uint8List rotateRgba(
    Uint8List source, {
    required int width,
    required int height,
    required int clockwiseDegrees,
  }) {
    _validateRotation(clockwiseDegrees);
    if (source.length != width * height * 4) {
      throw const FormatException('RGBA buffer dimensions do not match.');
    }
    if (clockwiseDegrees == 0) return source;
    final bool quarterTurn = clockwiseDegrees == 90 || clockwiseDegrees == 270;
    final int outWidth = quarterTurn ? height : width;
    final int outHeight = quarterTurn ? width : height;
    final Uint8List output = Uint8List(source.length);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int outX;
        final int outY;
        switch (clockwiseDegrees) {
          case 90:
            outX = height - 1 - y;
            outY = x;
            break;
          case 180:
            outX = width - 1 - x;
            outY = height - 1 - y;
            break;
          case 270:
            outX = y;
            outY = width - 1 - x;
            break;
          default:
            outX = x;
            outY = y;
            break;
        }
        final int sourceIndex = (y * width + x) * 4;
        final int outputIndex = (outY * outWidth + outX) * 4;
        output[outputIndex] = source[sourceIndex];
        output[outputIndex + 1] = source[sourceIndex + 1];
        output[outputIndex + 2] = source[sourceIndex + 2];
        output[outputIndex + 3] = source[sourceIndex + 3];
      }
    }
    return output;
  }

  void _validateRotation(int degrees) {
    if (degrees != 0 && degrees != 90 && degrees != 180 && degrees != 270) {
      throw FormatException('Unsupported rotation: $degrees degrees.');
    }
  }

  void _writeRgba(Uint8List out, int index, int y, int u, int v) {
    final int c = math.max(0, y - 16).toInt();
    final int d = u - 128;
    final int e = v - 128;
    out[index] = ((298 * c + 409 * e + 128) >> 8).clamp(0, 255).toInt();
    out[index + 1] = ((298 * c - 100 * d - 208 * e + 128) >> 8)
        .clamp(0, 255)
        .toInt();
    out[index + 2] = ((298 * c + 516 * d + 128) >> 8).clamp(0, 255).toInt();
    out[index + 3] = 255;
  }

}

// END OF FILE - lib/services/admin_beauty_frame_processor.dart
