import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/ivory_theme.dart';
import 'call_offer_layer.dart';
import 'live_stage_bits.dart';

/// How tall the live chat is. ONE place, shared by the room layout and by the
/// co-host windows (which must stay clear of the chat). The chat sits at the
/// very bottom of the screen and takes about 30% of its height; while the
/// keyboard is open it is allowed to grow so that typing stays comfortable.
class LiveRoomMetrics {
  LiveRoomMetrics._();

  static double chatHeight(double screenHeight, {required bool typing}) {
    final double fraction = typing ? 0.48 : 0.30;
    final double cap = typing ? 420 : 300;
    return (screenHeight * fraction).clamp(0.0, cap).toDouble();
  }
}

/// The broadcast picture fills the room; its controls and chat float above it.
class LiveRoomBody extends StatelessWidget {
  const LiveRoomBody({
    super.key,
    required this.bar,
    required this.stage,
    required this.controls,
    this.action,
    this.chat,
    this.isCall = false,
  });

  final Widget bar;
  final Widget stage;
  final Widget controls;
  final Widget? action;
  final Widget? chat;
  final bool isCall;

  @override
  Widget build(BuildContext context) {
    if (isCall) {
      return Column(
        children: <Widget>[
          bar,
          Expanded(child: Center(child: stage)),
          controls,
        ],
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        final bool typing = MediaQuery.of(context).viewInsets.bottom > 80;
        final double chatHeight =
            LiveRoomMetrics.chatHeight(box.maxHeight, typing: typing);
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Positioned.fill(child: stage),
            SafeArea(
              child: Column(
                children: <Widget>[
                  bar,
                  if (action != null) action!,
                  const Spacer(),
                  if (chat != null)
                    SizedBox(height: chatHeight, child: chat),
                ],
              ),
            ),
            // The few speaker buttons float just above the chat, at the
            // right edge, so the chat itself can sit at the very bottom.
            Positioned(
              right: 10,
              bottom: MediaQuery.of(context).padding.bottom +
                  (chat != null ? chatHeight : 0) +
                  6,
              child: controls,
            ),
          ],
        );
      },
    );
  }
}

/// Keeps the call layout inset, but lets a broadcast video extend edge to edge.
class LiveScreenFrame extends StatefulWidget {
  const LiveScreenFrame({
    super.key,
    required this.child,
    required this.isCall,
    required this.owner,
    required this.timeUp,
    required this.ended,
    required this.callId,
  });

  final Widget child;
  final bool isCall;
  final bool owner;
  final bool timeUp;
  final bool ended;
  final int callId;

  @override
  State<LiveScreenFrame> createState() => _LiveScreenFrameState();
}

class _LiveScreenFrameState extends State<LiveScreenFrame> {
  @override
  void initState() {
    super.initState();
    if (!widget.isCall) {
      unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget room = Stack(
      fit: StackFit.expand,
      children: <Widget>[
        widget.child,
        if (widget.timeUp && !widget.ended)
          Align(
            alignment: Alignment.topCenter,
            child: TimeUpBar(owner: widget.owner),
          ),
        if (widget.isCall && !widget.owner)
          CallOfferLayer(callId: widget.callId, ended: widget.ended),
      ],
    );
    if (widget.isCall) return SafeArea(child: room);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
        systemStatusBarContrastEnforced: false,
        systemNavigationBarContrastEnforced: false,
      ),
      child: room,
    );
  }
}

// END OF FILE - lib/widgets/live_room_body.dart
