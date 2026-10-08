import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/call_room_service.dart';
import '../theme/ivory_theme.dart';
import 'call_extension_prompt.dart';

/// ============================================================
/// IVORY - MORE TIME, OFFERED BY HAND
///
/// Two halves of one moment.
///
/// THE HOUSE: a box on the call screen with a price and a
/// duration, and a SEND button. Not a timer, not a guess about
/// when the call ends - she decides, whenever she likes, as
/// often as she likes.
///
/// THE MEMBER: a card that slides over the call and holds for
/// THIRTY SECONDS. This matters most on an audio call, where
/// the phone may be at an ear or the app in the background, so
/// a handset notification is sent at the very same moment from
/// the database. Two paths, one offer - and the notification
/// stays in the tray after the card has gone.
/// ============================================================

/// The house's side. Price box, duration box, SEND.
Future<bool> showOfferMoreTime(
  BuildContext context, {
  required int callId,
  required bool premium,
}) async {
  final CallOffer d =
      await CallRoomService.instance.defaults(premium: premium);
  if (!context.mounted) return false;
  final bool? sent = await showDialog<bool>(
    context: context,
    builder: (BuildContext c) =>
        _OfferDialog(callId: callId, start: d),
  );
  return sent == true;
}

class _OfferDialog extends StatefulWidget {
  const _OfferDialog({required this.callId, required this.start});

  final int callId;
  final CallOffer start;

  @override
  State<_OfferDialog> createState() => _OfferDialogState();
}

class _OfferDialogState extends State<_OfferDialog> {
  late final TextEditingController _price =
      TextEditingController(text: widget.start.priceInr.toString());
  late final TextEditingController _mins =
      TextEditingController(text: widget.start.minutes.toString());
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _price.dispose();
    _mins.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final int price = int.tryParse(_price.text.trim()) ?? -1;
    final int mins = int.tryParse(_mins.text.trim()) ?? 0;
    if (price < 0) {
      setState(() => _error = 'Put a price in, even if it is 0.');
      return;
    }
    if (mins < 30 || mins > 120) {
      setState(() => _error = 'Choose between 30 and 120 minutes.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await CallRoomService.instance.offerExtension(
        callId: widget.callId,
        priceInr: price,
        minutes: mins,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
      return;
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: IvoryColors.surface,
      title: const Text('Offer more time'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'This appears on their screen straight away and their '
            'phone is notified at the same moment. You can send it '
            'again as often as you like. It stays on their screen '
            'for thirty seconds.',
            style: TextStyle(fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _price,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: const InputDecoration(
              labelText: 'Price in rupees',
              prefixText: 'Rs. ',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _mins,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: const InputDecoration(
              labelText: 'How many more minutes',
              helperText: 'Between 30 and 120',
            ),
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: const TextStyle(
                  fontSize: 12.5, color: IvoryColors.danger),
            ),
          ],
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _busy ? null : _send,
          child: Text(_busy ? 'SENDING...' : 'SEND'),
        ),
      ],
    );
  }
}

/// The member's side. Sits over the call and does not flinch.
class MoreTimeCard extends StatefulWidget {
  const MoreTimeCard({
    super.key,
    required this.callId,
    required this.offer,
    required this.onDismiss,
  });

  final int callId;
  final CallOffer offer;
  final VoidCallback onDismiss;

  @override
  State<MoreTimeCard> createState() => _MoreTimeCardState();
}

class _MoreTimeCardState extends State<MoreTimeCard> {
  Timer? _hold;

  /// Thirty seconds, as the owner specified. Long enough to be
  /// read and acted on while the phone is at an ear, short
  /// enough never to sit in the way of the conversation.
  int _left = 30;

  @override
  void initState() {
    super.initState();
    // It holds for thirty seconds, then steps aside quietly.
    // Nothing is lost if it does: the handset notification sent
    // at the same moment stays in her notification tray.
    _hold = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (!mounted) return;
      setState(() => _left -= 1);
      if (_left <= 0) {
        t.cancel();
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _hold?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CallOffer o = widget.offer;
    final bool free = o.priceInr <= 0;
    return Positioned(
      left: 14,
      right: 14,
      bottom: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          decoration: BoxDecoration(
            gradient: IvoryColors.pageGradient,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: IvoryColors.gold, width: 1.4),
            boxShadow: IvoryTheme.softShadow(blur: 30, y: 12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(Icons.hourglass_bottom_rounded,
                      color: IvoryColors.burgundy, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'A little more time?',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        color: IvoryColors.burgundy,
                      ),
                    ),
                  ),
                  Text(
                    '${_left}s',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: IvoryColors.burgundy.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                free
                    ? 'Ivory has offered you ${o.minutes} more minutes. '
                        'Nothing to pay.'
                    : 'Ivory has offered you ${o.minutes} more minutes '
                        'for Rs.${o.priceInr}. The conversation simply '
                        'carries on.',
                style: const TextStyle(fontSize: 13.5, height: 1.5),
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: IvoryGradientButton(
                      label: free ? 'THANK YOU' : 'YES, ADD THE TIME',
                      icon: Icons.favorite_rounded,
                      onPressed: () {
                        widget.onDismiss();
                        if (!free) {
                          CallExtensionPrompt.open(
                            context,
                            callId: widget.callId,
                            price: o.priceInr,
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: widget.onDismiss,
                    child: const Text('NOT NOW'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// END OF FILE - lib/widgets/call_more_time.dart
