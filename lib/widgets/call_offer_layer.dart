import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/call_room_service.dart';
import 'call_more_time.dart';

/// Everything to do with an offer of more time arriving on the
/// member's screen: listening for it, deciding whether it is
/// real, and showing the card.
///
/// WHY THIS IS ITS OWN FILE
///
/// It used to live inside the call screen, which grew past the
/// size a phone can comfortably paste. It is also a whole
/// responsibility in its own right - the room should not have
/// to know how an offer travels.
///
/// WHY AN OFFER NOW HAS TO BE FRESH
///
/// The offer is a stamp on the session's row, and it stays there.
/// Realtime hands the WHOLE row to the listener on EVERY write -
/// entering the room, leaving it, finishing it. So a test that
/// only asked "is there a stamp" raised the same old card again
/// every single time either side moved. The card was not random;
/// it was an echo. Liveness is judged on AGE now, and each stamp
/// is allowed to raise a card exactly once.
class CallOfferLayer extends StatefulWidget {
  const CallOfferLayer({
    super.key,
    required this.callId,
    required this.ended,
  });

  final int callId;

  /// Once the session is over, nothing may be offered or shown.
  /// Asking for money after goodbye is the one thing the room
  /// must never do.
  final bool ended;

  @override
  State<CallOfferLayer> createState() => _CallOfferLayerState();
}

class _CallOfferLayerState extends State<CallOfferLayer> {
  CallOffer? _offer;
  DateTime? _lastAt;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _channel = CallRoomService.instance.watchOffer(widget.callId, _raise);
    CallRoomService.instance.currentOffer(widget.callId).then(
      (CallOffer? o) {
        if (o != null) _raise(o);
      },
    ).catchError((Object _) {
      // A missed first read is harmless - the next offer still
      // arrives over realtime.
    });
  }

  @override
  void didUpdateWidget(covariant CallOfferLayer old) {
    super.didUpdateWidget(old);
    if (widget.ended && _offer != null) {
      setState(() => _offer = null);
    }
  }

  @override
  void dispose() {
    final RealtimeChannel? c = _channel;
    if (c != null) CallRoomService.instance.stopWatching(c);
    super.dispose();
  }

  void _raise(CallOffer o) {
    if (!mounted || widget.ended || !o.isLive) return;
    final DateTime? at = o.offeredAt;
    if (at == null) return;

    // One card per stamp. A re-sent offer carries a new stamp, so
    // the house can still offer again as often as she likes.
    if (_lastAt != null && !at.isAfter(_lastAt!)) return;

    setState(() {
      _lastAt = at;
      _offer = o;
    });
  }

  @override
  Widget build(BuildContext context) {
    final CallOffer? o = _offer;
    if (o == null || widget.ended) return const SizedBox.shrink();
    return MoreTimeCard(
      callId: widget.callId,
      offer: o,
      onDismiss: () {
        if (mounted) setState(() => _offer = null);
      },
    );
  }
}

// END OF FILE - lib/widgets/call_offer_layer.dart
