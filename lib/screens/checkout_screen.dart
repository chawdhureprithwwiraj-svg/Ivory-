import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/payment.dart';
import '../services/payment_service.dart';
import '../services/razorpay_service.dart';
import '../theme/ivory_theme.dart';

/// The UPI checkout.
///
/// Pay in any UPI app -> come back -> enter the reference number ->
/// Pending Verification. Nothing unlocks until an admin approves, and the
/// database refuses a reference number that has been used before, so a
/// screenshot borrowed from a friend gets nobody anywhere.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.tierId,
    required this.tierName,
    required this.priceInr,
    this.durationDays = 30,
  });

  final int tierId;
  final String tierName;
  final int priceInr;
  final int durationDays;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _utr = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  PaymentSettings? _settings;
  IvoryPayment? _pending;
  File? _proof;
  bool _loading = true;
  String _mode = 'upi';
  bool _submitting = false;
  bool _done = false;
  String? _error;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
    RazorpayService.instance.fetchMode().then((String m) {
      if (mounted) setState(() => _mode = m);
    });
  }

  @override
  void dispose() {
    _utr.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final PaymentSettings s = await PaymentService.instance.fetchSettings();
      final List<IvoryPayment> mine =
          await PaymentService.instance.fetchMyPayments();
      IvoryPayment? pending;
      for (final IvoryPayment p in mine) {
        if (p.isPending) {
          pending = p;
          break;
        }
      }
      if (!mounted) return;
      setState(() {
        _settings = s;
        _pending = pending;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Could not load payment details. Pull down to retry.';
        _loading = false;
      });
    }
  }

  String get _note =>
      '${_settings?.noteTemplate ?? 'Ivory'} - ${widget.tierName}';

  Future<void> _payInUpiApp() async {
    final PaymentSettings? s = _settings;
    if (s == null) return;
    final Uri uri = s.intentUri(amountInr: widget.priceInr, note: _note);
    bool opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened && mounted) {
      _snack(
        'No UPI app opened. Copy the UPI id below and pay from GPay, PhonePe, '
        'Paytm or your bank app.',
      );
    }
  }

  Future<void> _copyUpi() async {
    final String id = _settings?.upiId ?? '';
    if (id.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: id));
    if (mounted) _snack('UPI id copied.');
  }

  Future<void> _pickProof() async {
    try {
      final XFile? x = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1400,
      );
      if (x == null) return;
      setState(() => _proof = File(x.path));
    } catch (_) {
      _snack('Could not open your gallery. The screenshot is optional.');
    }
  }

  Future<void> _submit() async {
    final String utr = _utr.text.trim();
    if (utr.length < 8) {
      setState(() => _error =
          'Enter the 12-digit UTR or reference number from your receipt.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      String? path;
      if (_proof != null) {
        path = await PaymentService.instance.uploadProof(_proof!);
      }
      await PaymentService.instance.submit(
        tierId: widget.tierId,
        utr: utr,
        screenshotPath: path,
      );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _done = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = PaymentService.friendly(e);
      });
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        titleTextStyle: const TextStyle(
          fontFamily: IvoryTheme.displayFont,
          color: IvoryColors.burgundy,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: IvoryColors.pageGradient),
        child: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: IvoryColors.burgundy))
              : RefreshIndicator(
                  color: IvoryColors.burgundy,
                  backgroundColor: IvoryColors.surface,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
                    children: <Widget>[
                      if (_loadError != null) _message(_loadError!),
                      _orderCard(),
                      const SizedBox(height: 16),
                      if (_done)
                        _submittedCard()
                      else if (_pending != null)
                        _pendingCard(_pending!)
                      else if (_mode == 'razorpay')
                        RazorpayPayPanel(
                          purpose: 'subscription',
                          tierId: widget.tierId,
                          label: widget.tierName,
                        )
                      else ...<Widget>[
                        _stepOne(),
                        const SizedBox(height: 16),
                        _stepTwo(),
                      ],
                      const SizedBox(height: 18),
                      _safetyNote(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- pieces

  Widget _message(String text) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: IvoryTheme.card(),
        child: Text(
          text,
          style: const TextStyle(color: IvoryColors.danger, fontSize: 13),
        ),
      );

  Widget _orderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: IvoryColors.deepGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: IvoryTheme.softShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'YOU ARE UNLOCKING',
            style: TextStyle(
              color: IvoryColors.gold,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.tierName,
            style: const TextStyle(
              fontFamily: IvoryTheme.displayFont,
              color: IvoryColors.cream,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text(
                '₹${widget.priceInr}',
                style: const TextStyle(
                  color: IvoryColors.gold,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.durationDays == 30
                    ? 'for 30 days'
                    : 'for ${widget.durationDays} days',
                style: TextStyle(
                  color: IvoryColors.cream.withValues(alpha: 0.75),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepOne() {
    final PaymentSettings? s = _settings;
    final bool configured = s?.isConfigured ?? false;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: IvoryTheme.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const IvoryEyebrow('Step 1'),
          const SizedBox(height: 10),
          const Text(
            'Pay by UPI',
            style: TextStyle(
              fontFamily: IvoryTheme.displayFont,
              color: IvoryColors.burgundy,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            s?.instructions ??
                'Pay with any UPI app, then come back with the reference number.',
            style: TextStyle(
              color: IvoryColors.textSoft,
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: IvoryColors.surfaceWarm,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: IvoryColors.hairlineStrong),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'UPI ID',
                        style: TextStyle(
                          color: IvoryColors.textFaint,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        configured ? s!.upiId : 'Not set up yet',
                        style: const TextStyle(
                          color: IvoryColors.burgundy,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: configured ? _copyUpi : null,
                  icon: const Icon(Icons.copy_rounded,
                      color: IvoryColors.plum, size: 20),
                  tooltip: 'Copy UPI id',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (configured)
            IvoryGradientButton(
              label: 'PAY ₹${widget.priceInr} IN YOUR UPI APP',
              icon: Icons.account_balance_wallet_outlined,
              onPressed: _payInUpiApp,
            )
          else
            Text(
              'The UPI id has not been set yet. Please try again shortly.',
              style: const TextStyle(
                color: IvoryColors.danger,
                fontSize: 13,
              ),
            ),
        ],
      ),
    );
  }

  Widget _stepTwo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: IvoryTheme.card(highlighted: true, radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const IvoryEyebrow('Step 2'),
          const SizedBox(height: 10),
          const Text(
            'Confirm your payment',
            style: TextStyle(
              fontFamily: IvoryTheme.displayFont,
              color: IvoryColors.burgundy,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Open your payment receipt and copy the UTR / transaction '
            'reference number. It is usually 12 digits.',
            style: TextStyle(
              color: IvoryColors.textSoft,
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _utr,
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.characters,
            maxLength: 23,
            style: const TextStyle(
              color: IvoryColors.burgundy,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
            decoration: const InputDecoration(
              labelText: 'UTR / reference number',
              hintText: '123456789012',
              counterText: '',
              prefixIcon: Icon(Icons.receipt_long_outlined,
                  color: IvoryColors.plum, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickProof,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: IvoryColors.surfaceWarm,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: IvoryColors.hairlineStrong),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    _proof == null
                        ? Icons.add_photo_alternate_outlined
                        : Icons.check_circle,
                    color: _proof == null
                        ? IvoryColors.plum
                        : IvoryColors.success,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _proof == null
                          ? 'Attach the receipt screenshot (optional)'
                          : 'Screenshot attached',
                      style: TextStyle(
                        color: _proof == null
                            ? IvoryColors.textSoft
                            : IvoryColors.burgundy,
                        fontSize: 13.5,
                        fontWeight:
                            _proof == null ? FontWeight.w500 : FontWeight.w700,
                      ),
                    ),
                  ),
                  if (_proof != null)
                    TextButton(
                      onPressed: () => setState(() => _proof = null),
                      child: const Text('Remove'),
                    ),
                ],
              ),
            ),
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(
                color: IvoryColors.danger,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 16),
          IvoryGradientButton(
            label: 'SUBMIT FOR VERIFICATION',
            icon: Icons.verified_outlined,
            busy: _submitting,
            onPressed: _submitting ? null : _submit,
          ),
        ],
      ),
    );
  }

  Widget _submittedCard() => _statusCard(
        icon: Icons.hourglass_top_rounded,
        title: 'Pending verification',
        body: 'Thank you. Your payment is with us now. You will get a '
            'notification the moment ${widget.tierName} is unlocked - '
            'usually within a few hours.',
        action: 'BACK TO MEMBERSHIPS',
      );

  Widget _pendingCard(IvoryPayment p) => _statusCard(
        icon: Icons.hourglass_top_rounded,
        title: 'A payment is already being checked',
        body: '₹${p.amountInr} for ${p.tierName ?? 'a membership'} '
            '(UTR ${p.utr}) is still pending verification. Please wait for '
            'that one to be settled before sending another.',
        action: 'GO BACK',
      );

  Widget _statusCard({
    required IconData icon,
    required String title,
    required String body,
    required String action,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: IvoryTheme.card(highlighted: true, radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: IvoryColors.goldGradient,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: IvoryColors.burgundy, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: IvoryTheme.displayFont,
                    color: IvoryColors.burgundy,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            body,
            style: TextStyle(
              color: IvoryColors.textSoft,
              fontSize: 14,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 18),
          IvoryGradientButton(
            label: action,
            icon: Icons.arrow_back,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
  }

  Widget _safetyNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IvoryColors.surfaceWarm,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: IvoryColors.hairline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.shield_outlined, color: IvoryColors.plum, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Each reference number can be used exactly once, and every '
              'payment is verified by hand before anything unlocks. We never '
              'ask for your PIN, OTP or card details.',
              style: TextStyle(
                color: IvoryColors.textFaint,
                fontSize: 12.5,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// END OF FILE - lib/screens/checkout_screen.dart
