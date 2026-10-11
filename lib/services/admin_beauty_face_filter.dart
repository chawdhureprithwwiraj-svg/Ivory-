import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Offset;

import 'admin_beauty_frame_processor.dart';

/// Applies cosmetic pixel effects only inside validated face-oval geometry.
/// This is a small CPU prototype, not targeted blemish removal.
class AdminBeautyFaceFilter {
  const AdminBeautyFaceFilter();

  /// Missing, tiny, invalid or out-of-frame geometry is passed through.
  /// The maximum horizontal face-shape warp is intentionally subtle (5%).
  Uint8List applyToRgba({
    required Uint8List rgba,
    required int width,
    required int height,
    required AdminBeautyFaceGeometry? face,
    required AdminBeautyTuning tuning,
  }) {
    if (width < 2 || height < 2 || rgba.length != width * height * 4) {
      throw const FormatException('RGBA buffer dimensions do not match.');
    }
    if (face == null || face.oval.length < 3) return rgba;
    if (tuning.smoothing <= 0 &&
        tuning.brightening <= 0 &&
        tuning.slimming <= 0) {
      return rgba;
    }
    if (!_validPolygon(face.oval, width, height)) return rgba;

    final List<List<_Span>> faceRows =
        _scanlines(face.oval, width: width, height: height);
    if (!_hasUsefulArea(faceRows)) return rgba;

    final List<List<List<_Span>>> protectedRows = <List<List<_Span>>>[];
    for (final List<Offset> contour in face.protectedContours) {
      if (contour.length < 3 || !_validPolygon(contour, width, height)) continue;
      protectedRows.add(
        _scanlines(_expand(contour, 1.22), width: width, height: height),
      );
    }

    final Uint8List faceMask = Uint8List(width * height);
    final Uint8List skinMask = Uint8List(width * height);
    final List<_Span?> rowBounds = List<_Span?>.filled(height, null);
    int top = height;
    int bottom = -1;

    for (int y = 0; y < height; y++) {
      final List<_Span> row = faceRows[y];
      if (row.isEmpty) continue;
      int left = width;
      int right = -1;
      for (final _Span span in row) {
        left = math.min(left, span.left).toInt();
        right = math.max(right, span.right).toInt();
        for (int x = span.left; x <= span.right; x++) {
          final int pixel = y * width + x;
          faceMask[pixel] = 1;
          bool protectedFeature = false;
          for (final List<List<_Span>> contourRows in protectedRows) {
            if (_contains(contourRows[y], x)) {
              protectedFeature = true;
              break;
            }
          }
          if (!protectedFeature) skinMask[pixel] = 1;
        }
      }
      rowBounds[y] = _Span(left, right);
      top = math.min(top, y).toInt();
      bottom = math.max(bottom, y).toInt();
    }
    if (bottom <= top) return rgba;

    final Uint8List? blurred = tuning.smoothing > 0
        ? _boxBlur3x3(rgba, width: width, height: height)
        : null;
    final Uint8List output = Uint8List.fromList(rgba);
    final double brightFactor = 1 + 0.10 * tuning.brightening;
    final double faceHeight = (bottom - top).toDouble();

    for (int y = top; y <= bottom; y++) {
      final _Span? bounds = rowBounds[y];
      if (bounds == null) continue;
      final double vertical = (y - top) / faceHeight;
      final double jawZone = _smoothStep(0.30, 0.48, vertical) *
          (1 - _smoothStep(0.84, 0.98, vertical));
      final double center = (bounds.left + bounds.right) / 2;
      final double pinch = 0.05 * tuning.slimming * jawZone;
      for (int x = bounds.left; x <= bounds.right; x++) {
        final int pixel = y * width + x;
        if (faceMask[pixel] == 0) continue;
        final int srcX = (center + (x - center) * (1 + pinch))
            .round()
            .clamp(bounds.left, bounds.right)
            .toInt();
        final int srcIndex = (y * width + srcX) * 4;
        final int dstIndex = pixel * 4;
        double red = rgba[srcIndex].toDouble();
        double green = rgba[srcIndex + 1].toDouble();
        double blue = rgba[srcIndex + 2].toDouble();

        if (skinMask[pixel] != 0) {
          final int edgeDistance =
              math.min(x - bounds.left, bounds.right - x).toInt();
          final double feather = (edgeDistance / 3).clamp(0.0, 1.0).toDouble();
          final double blend = 0.30 * tuning.smoothing * feather;
          if (blurred != null && blend > 0) {
            red = _mix(red, blurred[srcIndex].toDouble(), blend);
            green = _mix(green, blurred[srcIndex + 1].toDouble(), blend);
            blue = _mix(blue, blurred[srcIndex + 2].toDouble(), blend);
          }
          red *= brightFactor;
          green *= brightFactor;
          blue *= brightFactor;
        }
        output[dstIndex] = red.round().clamp(0, 255).toInt();
        output[dstIndex + 1] = green.round().clamp(0, 255).toInt();
        output[dstIndex + 2] = blue.round().clamp(0, 255).toInt();
        output[dstIndex + 3] = rgba[srcIndex + 3];
      }
    }
    return output;
  }

  bool _validPolygon(List<Offset> points, int width, int height) {
    if (points.length < 3) return false;
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = -double.infinity;
    double maxY = -double.infinity;
    for (final Offset point in points) {
      if (!point.dx.isFinite || !point.dy.isFinite) return false;
      if (point.dx < 0 || point.dy < 0 || point.dx >= width || point.dy >= height) {
        return false;
      }
      minX = math.min(minX, point.dx).toDouble();
      minY = math.min(minY, point.dy).toDouble();
      maxX = math.max(maxX, point.dx).toDouble();
      maxY = math.max(maxY, point.dy).toDouble();
    }
    final double boxWidth = maxX - minX;
    final double boxHeight = maxY - minY;
    return boxWidth >= width * 0.08 &&
        boxHeight >= height * 0.08 &&
        boxWidth <= width * 0.96 &&
        boxHeight <= height * 0.96;
  }

  bool _hasUsefulArea(List<List<_Span>> rows) {
    int count = 0;
    for (final List<_Span> row in rows) {
      for (final _Span span in row) {
        count += span.right - span.left + 1;
      }
    }
    return count >= 400;
  }

  List<Offset> _expand(List<Offset> points, double scale) {
    double cx = 0;
    double cy = 0;
    for (final Offset point in points) {
      cx += point.dx;
      cy += point.dy;
    }
    cx /= points.length;
    cy /= points.length;
    return points
        .map((Offset point) => Offset(
              cx + (point.dx - cx) * scale,
              cy + (point.dy - cy) * scale,
            ))
        .toList(growable: false);
  }

  List<List<_Span>> _scanlines(
    List<Offset> polygon, {
    required int width,
    required int height,
  }) {
    final List<List<_Span>> rows =
        List<List<_Span>>.generate(height, (_) => <_Span>[]);
    for (int y = 0; y < height; y++) {
      final double scanY = y + 0.5;
      final List<double> cuts = <double>[];
      for (int i = 0; i < polygon.length; i++) {
        final Offset a = polygon[i];
        final Offset b = polygon[(i + 1) % polygon.length];
        if ((a.dy <= scanY && b.dy > scanY) ||
            (b.dy <= scanY && a.dy > scanY)) {
          cuts.add(a.dx + (scanY - a.dy) * (b.dx - a.dx) / (b.dy - a.dy));
        }
      }
      cuts.sort();
      for (int i = 0; i + 1 < cuts.length; i += 2) {
        final int left =
            (cuts[i] - 0.5).ceil().clamp(0, width - 1).toInt();
        final int right =
            (cuts[i + 1] - 0.5).floor().clamp(0, width - 1).toInt();
        if (right >= left) rows[y].add(_Span(left, right));
      }
    }
    return rows;
  }

  bool _contains(List<_Span> spans, int x) =>
      spans.any((_Span span) => x >= span.left && x <= span.right);

  Uint8List _boxBlur3x3(
    Uint8List source, {
    required int width,
    required int height,
  }) {
    final Uint8List output = Uint8List(source.length);
    for (int y = 0; y < height; y++) {
      final int minY = math.max(0, y - 1).toInt();
      final int maxY = math.min(height - 1, y + 1).toInt();
      for (int x = 0; x < width; x++) {
        final int minX = math.max(0, x - 1).toInt();
        final int maxX = math.min(width - 1, x + 1).toInt();
        int red = 0, green = 0, blue = 0, count = 0;
        for (int yy = minY; yy <= maxY; yy++) {
          for (int xx = minX; xx <= maxX; xx++) {
            final int i = (yy * width + xx) * 4;
            red += source[i];
            green += source[i + 1];
            blue += source[i + 2];
            count++;
          }
        }
        final int i = (y * width + x) * 4;
        output[i] = red ~/ count;
        output[i + 1] = green ~/ count;
        output[i + 2] = blue ~/ count;
        output[i + 3] = source[i + 3];
      }
    }
    return output;
  }

  double _smoothStep(double edge0, double edge1, double value) {
    final double t = ((value - edge0) / (edge1 - edge0))
        .clamp(0.0, 1.0)
        .toDouble();
    return t * t * (3 - 2 * t);
  }

  double _mix(double a, double b, double t) => a + (b - a) * t;
}

class _Span {
  const _Span(this.left, this.right);

  final int left;
  final int right;
}

// END OF FILE - lib/services/admin_beauty_face_filter.dart
