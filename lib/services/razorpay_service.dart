import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/ivory_theme.dart';

/// ============================================================
/// IVORY - RAZORPAY, PARALLEL TO UPI
///
/// The app reads payment_settings.mode live. When the house is in
/// 'razorpay' mode the screens embed RazorpayPayPanel; in 'upi'
/// mode they keep the old form, untouched. The secret key never
/// touches this file - orders and verification happen in the two
/// Edge Functions.
/// ============================================================

class RazorpayService {
  RazorpayService._();
  static final RazorpayService instance = RazorpayService._();

  /// 'upi' or 'razorpay', straight from the house switch.
  Future<String> fetchMode() async {
    try {
      final dynamic row = await Supabase.instance.client
          .from('payment_settings')
          .select('mode')
          .eq('id', 1)
          .maybeSingle();
      return (row?['mode'] as String?) ?? 'upi';
    } catch (_) {
      return 'upi';
    }
  }
}

class RazorpayPayPanel extends StatefulWidget {
  const RazorpayPayPanel({
    super.key,
    required this.purpose,
    this.tierId,
    this.postId,
    this.customRequestId,
    this.giftSendId,
    this.sessionId,
    this.onUnlocked,
    required this.label,
  });

  final String purpose;
  final int? tierId;
  final int? postId;
  final int? customRequestId;
  final int? giftSendId;
  final int? sessionId;
  final VoidCallback? onUnlocked;
  final String label;

  @override
  State<RazorpayPayPanel> createState() => _RazorpayPayPanelState();
}

class _RazorpayPayPanelState extends State<RazorpayPayPanel> {
  final Razorpay _rzp = Razorpay();
  bool _busy = false;
  bool _done = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _rzp.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onSuccess);
    _rzp.on(Razorpay.EVENT_PAYMENT_ERROR, _onError);
    _rzp.on(Razorpay.EVENT_EXTERNAL_WALLET, _onWallet);
  }

  @override
  void dispose() {
    _rzp.clear();
    super.dispose();
  }

  void _onWallet(dynamic _) {
    if (mounted) {
      setState(() => _error = 'Finish the payment in the app that opened, '
          'then come back.');
    }
  }

  void _onError(PaymentFailureResponse res) {
    if (!mounted) return;
    setState(() {
      _busy = false;
      // A dismissed sheet is not a failure worth a red line.
      _error = (res.code == 0)
          ? null
          : (res.message?.isNotEmpty == true
              ? res.message
              : 'The payment did not finish. Nothing was taken.');
    });
  }

  Future<void> _onSuccess(PaymentSuccessResponse res) async {
    try {
      final dynamic fr = await Supabase.instance.client.functions.invoke(
        'rzp-verify-unlock',
        method: HttpMethod.post,
        body: <String, dynamic>{
          'razorpay_order_id': res.orderId,
          'razorpay_payment_id': res.paymentId,
          'razorpay_signature': res.signature,
        },
      );
      final Map<String, dynamic> data =
          Map<String, dynamic>.from(fr.data as Map);
      if (!mounted) return;
      if (fr.status == 200 && data['ok'] == true) {
        setState(() {
          _busy = false;
          _done = true;
        });
        widget.onUnlocked?.call();
      } else {
        setState(() {
          _busy = false;
          _error = (data['error'] as String?) ??
              'Verification hiccup - write to the house with your receipt.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Verification hiccup - write to the house with your '
              'receipt.';
        });
      }
    }
  }

  Future<void> _pay() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final dynamic fr = await Supabase.instance.client.functions.invoke(
        'rzp-create-order',
        method: HttpMethod.post,
        body: <String, dynamic>{
          'purpose': widget.purpose,
          'tier_id': widget.tierId,
          'post_id': widget.postId,
          'custom_request_id': widget.customRequestId,
          'gift_send_id': widget.giftSendId,
          'live_session_id': widget.sessionId,
        },
      );
      if (fr.status != 200) {
        final Map<String, dynamic> data =
            Map<String, dynamic>.from((fr.data ?? <String, dynamic>{}) as Map);
        if (mounted) {
          setState(() {
            _busy = false;
            _error = (data['error'] as String?) ?? 'The door jammed - try once more.';
          });
        }
        return;
      }
      final Map<String, dynamic> d =
          Map<String, dynamic>.from(fr.data as Map);
      final Map<String, dynamic> options = <String, dynamic>{
        'key': d['key_id'],
        'amount': d['amount_paise'],
        'order_id': d['order_id'],
        'name': 'Ivory',
        'description': widget.label,
        'theme': <String, dynamic>{'color': '#4A0E17'},
      };
      _rzp.open(options);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'The door jammed - try once more.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_done) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: IvoryTheme.card(),
        child: Column(
          children: <Widget>[
            const Icon(Icons.verified_outlined,
                size: 34, color: IvoryColors.success),
            const SizedBox(height: 8),
            Text(
              'It is yours now.',
              style: TextStyle(
                fontFamily: IvoryTheme.displayFont,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: IvoryColors.burgundy,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'The house has your payment. Everything is open.',
              style: TextStyle(color: IvoryColors.textSoft, fontSize: 13),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: IvoryTheme.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Pay with UPI, cards or netbanking - it unlocks the moment '
            'the payment lands.',
            style: TextStyle(color: IvoryColors.textSoft, fontSize: 13),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: IvoryGradientButton(
              label: 'PAY SECURELY',
              icon: Icons.lock_outline,
              busy: _busy,
              onPressed: _busy ? null : _pay,
            ),
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: IvoryColors.danger, fontSize: 12.5),
            ),
          ],
        ],
      ),
    );
  }
}

// END OF FILE - lib/services/razorpay_service.dart
