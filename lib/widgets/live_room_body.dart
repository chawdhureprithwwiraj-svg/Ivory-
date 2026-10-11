import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/ivory_theme.dart';
import 'call_offer_layer.dart';
import 'live_stage_bits.dart';

/// The broadcast picture fills the room; its controls and chat float above it.
class LiveRoomBody extends StatelessWidget {
  const LiveRoomBody({
    super.key,
    required this.bar,
    required this.stage,
    required this.controls,
    this.chat,
    this.isCall = false,
  });

  final Widget bar;
  final Widget stage;
  final Widget controls;
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
        final double fraction = typing ? 0.48 : 0.39;
        final double cap = typing ? 420 : 340;
        final double chatHeight =
            (box.maxHeight * fraction).clamp(0.0, cap).toDouble();
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Positioned.fill(child: stage),
            SafeArea(
              child: Column(
                children: <Widget>[
                  bar,
                  const Spacer(),
                  if (chat != null)
                    SizedBox(height: chatHeight, child: chat),
                  controls,
                ],
              ),
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
