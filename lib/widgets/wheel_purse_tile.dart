import 'package:flutter/material.dart';

import '../services/wheel_service.dart';

/// The Fortune Purse standing at the bill.
///
/// The house laws, painted small: the purse appears only when it holds
/// something; the toggle appears only when the price is GREATER than the
/// purse; one instrument per bill - while a code or a Golden Knock-off is
/// on the order, or the rail is Razorpay (which prices itself), the purse
/// rests and says why. The whole purse spends, once, when the order
/// completes - never before, never partly.
class WheelPurseTile extends StatefulWidget {
  const WheelPurseTile({
    super.key,
    required this.priceInr,
    this.blocked = false,
    required this.onChanged,
  });

  final int priceInr;
  final bool blocked;
  final void Function(bool use, int purse) onChanged;

  @override
  State<WheelPurseTile> createState() => _WheelPurseTileState();
}

class _WheelPurseTileState extends State<WheelPurseTile> {
  int _purse = 0;
  bool _on = false;
  String _close = '';

  @override
  void initState() {
    super.initState();
    WheelService.instance.state().then((Map<String, dynamic> m) {
      if (!mounted) return;
      setState(() {
        _purse = (m['purse'] is int) ? m['purse'] as int : 0;
        _close = (m['cycle_closes_at'] ?? '').toString();
      });
    });
  }

  bool get _ok => _purse > 0 && widget.priceInr > _purse && !widget.blocked;

  String get _line {
    if (_purse == 0) {
      return 'Your Fortune Purse is empty today - spin in a Gilded Hour '
          'and it fills.';
    }
    if (widget.blocked) {
      return 'One instrument per bill - the purse rests while a code, a '
          'Knock-off or the Razorpay rail is on this order.';
    }
    if (widget.priceInr <= _purse) {
      return 'The purse only pays where the price is greater than it - '
          'this order is cheaper than your fortune.';
    }
    if (_on) {
      return 'The whole ₹$_purse spends once, when this order completes. '
          'Cycle closes $_close.';
    }
    return '₹$_purse gathered · spends whole, on this order, if you wish.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x14E7B14C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x40E7B14C)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'FORTUNE PURSE',
                  style: TextStyle(
                      color: Color(0xFF8A5E1C),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.6),
                ),
                const SizedBox(height: 4),
                Text(_line,
                    style: const TextStyle(
                        color: Color(0xFF3A2318), fontSize: 12.5, height: 1.4)),
              ],
            ),
          ),
          if (_ok)
            Switch(
              value: _on,
              activeColor: const Color(0xFFE7B14C),
              onChanged: (bool v) {
                setState(() => _on = v);
                widget.onChanged(v, _purse);
              },
            ),
        ],
      ),
    );
  }
}

// END OF FILE - lib/widgets/wheel_purse_tile.dart
