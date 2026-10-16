import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/live_guest_models.dart';
import '../services/live_guest_tile_service.dart';
import '../theme/ivory_theme.dart';
import 'live_room_body.dart';

/// Every co-host window floats on its own. Ivory drags each one to the spot
/// she wants; it stays exactly there and every viewer sees the same spot.
/// Viewers cannot move anything. A window with no saved spot takes a tidy
/// default place, so five new co-hosts never pile on top of each other.
class LiveGuestTileLayer extends StatefulWidget {
  const LiveGuestTileLayer({
    super.key,
    required this.guests,
    required this.positions,
    required this.canMove,
    required this.onMoved,
    required this.tileBuilder,
  });

  final List<LiveGuestParticipant> guests;
  final Map<String, LiveGuestTilePosition> positions;
  final bool canMove;
  final void Function(String memberId, LiveGuestTilePosition position) onMoved;
  final Widget Function(LiveGuestParticipant guest, double height) tileBuilder;

  @override
  State<LiveGuestTileLayer> createState() => _LiveGuestTileLayerState();
}

class _LiveGuestTileLayerState extends State<LiveGuestTileLayer> {
  /// Default places, in the order co-hosts arrive: top-right, top-left,
  /// middle-right, middle-left, then low centre.
  static const List<LiveGuestTilePosition> _slots = <LiveGuestTilePosition>[
    LiveGuestTilePosition(x: 1, y: 0),
    LiveGuestTilePosition(x: 0, y: 0),
    LiveGuestTilePosition(x: 1, y: 0.5),
    LiveGuestTilePosition(x: 0, y: 0.5),
    LiveGuestTilePosition(x: 0.5, y: 1),
  ];
  static const double _handle = 16;

  String? _activeId;
  Offset _activeAt = Offset.zero;

  String _idOf(LiveGuestParticipant g) =>
      g.userId.isEmpty ? 'guest-${g.requestId}' : g.userId;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData metrics = MediaQuery.of(context);
    final bool typing = metrics.viewInsets.bottom > 80;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        final double w = box.maxWidth;
        final double h = box.maxHeight;
        final double tileW = (w * 0.26).clamp(72.0, 100.0).toDouble();
        final double wanted = (tileW * 1.34).clamp(96.0, 134.0).toDouble();
        final double chatH = LiveRoomMetrics.chatHeight(h, typing: typing);
        final double bottomInset = chatH + metrics.padding.bottom + 8;
        final double topInset =
            (metrics.padding.top + 104).clamp(104.0, 220.0).toDouble();
        final double available =
            (h - topInset - bottomInset - _handle).clamp(52.0, 180.0).toDouble();
        final double tileH = math.min(wanted, available).toDouble();
        final double dockH = _handle + tileH;
        final double safeLeft =
            math.max(12.0, metrics.padding.left + 8).toDouble();
        final double safeRight =
            math.max(12.0, metrics.padding.right + 8).toDouble();
        final double maxLeft =
            math.max(safeLeft, w - tileW - safeRight).toDouble();
        final double maxTop =
            math.max(topInset, h - bottomInset - dockH).toDouble();

        final List<Widget> tiles = <Widget>[];
        Widget? active;
        for (int i = 0; i < widget.guests.length; i++) {
          final LiveGuestParticipant g = widget.guests[i];
          final String id = _idOf(g);
          final LiveGuestTilePosition spot =
              widget.positions[g.userId] ?? _slots[i % _slots.length];
          final bool dragging = _activeId == id;
          final double left = dragging
              ? _activeAt.dx
              : safeLeft + spot.x * (maxLeft - safeLeft);
          final double top = dragging
              ? _activeAt.dy
              : topInset + spot.y * (maxTop - topInset);
          final Widget tile = Positioned(
            key: ValueKey<String>(id),
            left: left,
            top: top,
            width: tileW,
            height: dockH,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: widget.canMove
                  ? (DragStartDetails _) => setState(() {
                        _activeId = id;
                        _activeAt = Offset(left, top);
                      })
                  : null,
              onPanUpdate: widget.canMove
                  ? (DragUpdateDetails d) {
                      if (_activeId != id) return;
                      setState(() {
                        _activeAt = Offset(
                          (_activeAt.dx + d.delta.dx)
                              .clamp(safeLeft, maxLeft)
                              .toDouble(),
                          (_activeAt.dy + d.delta.dy)
                              .clamp(topInset, maxTop)
                              .toDouble(),
                        );
                      });
                    }
                  : null,
              onPanEnd: widget.canMove
                  ? (DragEndDetails _) {
                      if (_activeId != id) return;
                      final Offset at = _activeAt;
                      final double fx = maxLeft <= safeLeft
                          ? 0.5
                          : (at.dx - safeLeft) / (maxLeft - safeLeft);
                      final double fy = maxTop <= topInset
                          ? 0.5
                          : (at.dy - topInset) / (maxTop - topInset);
                      if (g.userId.isNotEmpty) {
                        widget.onMoved(
                            g.userId, LiveGuestTilePosition.rounded(fx, fy));
                      }
                      setState(() => _activeId = null);
                    }
                  : null,
              onPanCancel: widget.canMove
                  ? () => setState(() => _activeId = null)
                  : null,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SizedBox(
                    height: _handle,
                    child: widget.canMove
                        ? Icon(
                            Icons.drag_indicator,
                            size: 20,
                            color: IvoryColors.cream.withValues(alpha: 0.82),
                          )
                        : const SizedBox.shrink(),
                  ),
                  Container(
                    width: tileW,
                    height: tileH,
                    foregroundDecoration: dragging
                        ? BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: IvoryColors.gold,
                              width: 2,
                            ),
                          )
                        : null,
                    child: widget.tileBuilder(g, tileH),
                  ),
                ],
              ),
            ),
          );
          // The window being dragged is always drawn on top.
          if (dragging) {
            active = tile;
          } else {
            tiles.add(tile);
          }
        }
        if (active != null) tiles.add(active);
        return Stack(clipBehavior: Clip.none, children: tiles);
      },
    );
  }
}

// END OF FILE - lib/widgets/live_guest_tile_layer.dart
