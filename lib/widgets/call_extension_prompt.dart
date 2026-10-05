import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/live_service.dart';
import '../services/razorpay_service.dart';
import '../theme/ivory_theme.dart';

/// ============================================================
/// IVORY - MORE TIME, MID-CALL
///
/// Only for members who PAID for this wish call (plan members
/// calling on their minutes are never asked for money). About
/// five minutes before the session's end, if the house has
/// offered an extension price, the member sees one quiet card:
/// the price, and a way to pay. Paying adds the time.
/// ============================================================
class CallExtensionPrompt {
  CallExtensionPrompt._();

  /// Called from the call screen's clock. Cheap: it only opens a
  /// row when an unpaid offer exists near the end.
  static Future<void> tick(
    BuildContext context, {
    required int callId,
    required Duration elapsed,
    required VoidCallback onShown,
  }) async {
    if (AuthService.instance.isAdminCached) return;
    final call = await LiveService.instance.fetchCall(callId);
    if (call == null) return;
    if (call.priceInr <= 0) return; // included minutes: no charge
    final int? price = call.extensionPrice;
    if (price == null || price <= 0 || call.extensionPaid) return;
    final Duration left = Duration(minutes: call.minutes) - elapsed;
    if (left > const Duration(minutes: 5)) return;
    if (!context.mounted) return;
    onShown();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ExtensionSheet(callId: callId, price: price),
    );
  }
}

class _ExtensionSheet extends StatefulWidget {
  const _ExtensionSheet({required this.callId, required this.price});

  final int callId;
  final int price;

  @override
  State<_ExtensionSheet> createState() => _ExtensionSheetState();
}

class _ExtensionSheetState extends State<_ExtensionSheet> {
  String _mode = 'upi';
  bool _sent = false;
  String? _error;
  final TextEditingController _utr = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final String m = await RazorpayService.instance.fetchMode();
    if (mounted) setState(() => _mode = m);
  }

  Future<void> _submitUpi() async {
    final String utr = _utr.text.trim();
    if (utr.length < 6) {
      setState(() => _error = 'Please enter the UPI reference (UTR).');
      return;
    }
    try {
      await LiveService.instance.submitExtensionPayment(widget.callId, utr);
      if (!mounted) return;
      setState(() => _sent = true);
    } catch (e) {
      if (!mounted) return;
      setState(() =>
          _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  void dispose() {
    _utr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      decoration: const BoxDecoration(
        gradient: IvoryColors.pageGradient,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const IvoryEyebrow('A little more time?',
              icon: Icons.hourglass_bottom_rounded),
          const SizedBox(height: 10),
          Text(
            'Your session ends in about five minutes.',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Ivory has offered you more time for Rs.${widget.price}. '
            'Pay now and the conversation simply continues.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          if (_sent)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: IvoryTheme.card(),
              child: const Text(
                'Thank you. Your extension is being confirmed - your '
                'time will not be cut while it verifies.',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
            )
          else if (_mode == 'razorpay')
            RazorpayPayPanel(
              purpose: 'call_extension',
              callRequestId: widget.callId,
              label: 'More time with Ivory',
              onUnlocked: () {
                if (mounted) setState(() => _sent = true);
              },
            )
          else ...<Widget>[
            TextField(
              controller: _utr,
              decoration: const InputDecoration(
                labelText: 'UPI reference (UTR) after paying',
              ),
            ),
            const SizedBox(height: 14),
            IvoryGradientButton(
              label: 'SEND FOR CONFIRMING',
              icon: Icons.verified_outlined,
              onPressed: _submitUpi,
            ),
          ],
          if (_error != null) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: const TextStyle(
                  fontSize: 12.5, color: IvoryColors.burgundy),
            ),
          ],
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('NOT NOW'),
            ),
          ),
        ],
      ),
    );
  }
}

// END OF FILE - lib/widgets/call_extension_prompt.dart
