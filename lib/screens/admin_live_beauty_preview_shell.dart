import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';

/// Presentational shell for the isolated owner-only beauty spike.
class AdminBeautyPreviewShell extends StatelessWidget {
  const AdminBeautyPreviewShell({
    super.key,
    required this.engine,
    required this.image,
    required this.width,
    required this.height,
    required this.frontCamera,
    required this.cameraReady,
    required this.showMesh,
    required this.faceOval,
    required this.fps,
    required this.processingMilliseconds,
    required this.status,
    required this.sourceStatus,
    required this.onClose,
    required this.onSwitchCamera,
    required this.onAdjustLook,
    required this.onToggleMesh,
  });

  final RtcEngine? engine;
  final ui.Image? image;
  final int width;
  final int height;
  final bool frontCamera;
  final bool cameraReady;
  final bool showMesh;
  final List<Offset> faceOval;
  final double fps;
  final int processingMilliseconds;
  final String status;
  final String sourceStatus;
  final VoidCallback onClose;
  final VoidCallback onSwitchCamera;
  final VoidCallback onAdjustLook;
  final VoidCallback onToggleMesh;

  @override
  Widget build(BuildContext context) {
    final bool haveFrame = image != null && width > 0 && height > 0;
    return Scaffold(
      backgroundColor: IvoryColors.burgundy,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (cameraReady && engine != null)
            Positioned.fill(
              child: AgoraVideoView(
                controller: VideoViewController(
                  rtcEngine: engine!,
                  canvas: const VideoCanvas(
                    uid: 0,
                    renderMode: RenderModeType.renderModeHidden,
                  ),
                ),
              ),
            )
          else
            Container(color: IvoryColors.plum),
          if (haveFrame)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: Transform.scale(
                  scaleX: frontCamera ? -1 : 1,
                  child: SizedBox(
                    width: width.toDouble(),
                    height: height.toDouble(),
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        RawImage(image: image, fit: BoxFit.fill),
                        if (showMesh && faceOval.length >= 3)
                          CustomPaint(
                            painter: _FaceMeshOutlinePainter(
                              points: faceOval,
                              imageWidth: width.toDouble(),
                              imageHeight: height.toDouble(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
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
                        onPressed: onClose,
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: IvoryColors.cream),
                      ),
                      const Expanded(
                        child: Text(
                          'ON-DEVICE BEAUTY SPIKE',
                          style: TextStyle(
                            color: IvoryColors.cream,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: frontCamera
                            ? 'Switch to rear camera'
                            : 'Switch to front camera',
                        onPressed: cameraReady ? onSwitchCamera : null,
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
                    color: IvoryColors.burgundy.withValues(alpha: 0.91),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: IvoryColors.gold.withValues(alpha: 0.55),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.face_retouching_natural_rounded,
                            color: IvoryColors.gold,
                            size: 18,
                          ),
                          const SizedBox(width: 7),
                          const Expanded(
                            child: Text(
                              'PRIVATE · ANDROID ONLY',
                              style: TextStyle(
                                color: IvoryColors.gold,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          Text(
                            '${fps.toStringAsFixed(1)} fps',
                            style: const TextStyle(
                              color: IvoryColors.cream,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        status,
                        style: TextStyle(
                          color: IvoryColors.cream.withValues(alpha: 0.95),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'No room joined · nothing is transmitted. '
                        'Frame processing: ${processingMilliseconds} ms · '
                        '${width}×$height',
                        style: TextStyle(
                          color: IvoryColors.cream.withValues(alpha: 0.72),
                          fontSize: 10.5,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        sourceStatus,
                        style: TextStyle(
                          color: IvoryColors.gold.withValues(alpha: 0.95),
                          fontSize: 10.5,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: cameraReady ? onAdjustLook : null,
                              icon: const Icon(Icons.tune_rounded, size: 18),
                              label: const Text('ADJUST LOOK'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: IvoryColors.cream,
                                side: const BorderSide(color: IvoryColors.gold),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: cameraReady ? onToggleMesh : null,
                              icon: Icon(
                                showMesh
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                size: 18,
                              ),
                              label: Text(showMesh ? 'HIDE MESH' : 'SHOW MESH'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: IvoryColors.cream,
                                side: const BorderSide(color: IvoryColors.gold),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        'Prototype only: ML Kit face mesh, face-bounded pixel '
                        'filters, and the Agora custom-frame adapter. Live/call '
                        'publishing stays on the existing source until handset checks pass.',
                        style: TextStyle(
                          color: IvoryColors.cream.withValues(alpha: 0.68),
                          fontSize: 10,
                          height: 1.35,
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
    );
  }
}

class _FaceMeshOutlinePainter extends CustomPainter {
  const _FaceMeshOutlinePainter({
    required this.points,
    required this.imageWidth,
    required this.imageHeight,
  });

  final List<Offset> points;
  final double imageWidth;
  final double imageHeight;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 3 || imageWidth <= 0 || imageHeight <= 0) return;
    final Path path = Path();
    for (int i = 0; i < points.length; i++) {
      final Offset point = Offset(
        points[i].dx / imageWidth * size.width,
        points[i].dy / imageHeight * size.height,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..color = IvoryColors.gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, size.width / 240).toDouble(),
    );
  }

  @override
  bool shouldRepaint(covariant _FaceMeshOutlinePainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.imageWidth != imageWidth ||
      oldDelegate.imageHeight != imageHeight;
}

// END OF FILE - lib/screens/admin_live_beauty_preview_shell.dart
