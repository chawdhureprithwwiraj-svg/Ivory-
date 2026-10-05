import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/payment.dart';
import '../services/content_service.dart';
import '../services/payment_service.dart';
import '../services/razorpay_service.dart';
import '../theme/ivory_theme.dart';

/// ============================================================
/// IVORY - A SEAT FOR ONE NIGHT
///
/// The pay-per-view door into a live session. Same rails as
/// everything else: UPI intent plus reference in UPI mode, the
/// Razorpay panel when the house runs cards. The pass opens the
/// moment the payment is verified.
/// ============================================================
class LivePassSheet extends StatefulWidget {
  const LivePassSheet({
    super.key,
    required this.sessionId,
    required this.title,
    required this.priceInr,
  });

  final int sessionId;
  final String title;
  final int priceInr;

  @override
  State<LivePassSheet> createState() => _LivePassSheetState();
}

class _LivePassSheetState extends State<LivePassSheet> {
  final TextEditingController _utr = TextEditingController();

  PaymentSettings? _settings;
  bool _loading = true;
  bool _sending = false;
  String? _message;
  bool _done = false;
  String _mode = 'upi';

  @override
  void initState() {
    super.initState();
    RazorpayService.instance.fetchMode().then((String m) {
      if (mounted) setState(() => _mode = m);
    });
    _load();
  }

  @override
  void dispose() {
    _utr.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final PaymentSettings s = await PaymentService.instance.fetchSettings();
      if (!mounted) return;
      setState(() {
        _settings = s;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _message = 'Could not load the payment details. Try again shortly.';
      });
    }
  }

  Future<void> _pay() async {
    final PaymentSettings? s = _settings;
    if (s == null) return;
    final Uri uri = s.intentUri(
      amountInr: widget.priceInr,
      note: 'Ivory - ${widget.title}',
    );
    bool opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened && mounted) {
      setState(() => _message =
          'No UPI app opened. Copy the id below and pay from GPay, '
          'PhonePe, Paytm or your bank app.');
    }
  }

  Future<void> _copy() async {
    final String id = _settings?.upiId ?? '';
    if (id.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: id));
    if (mounted) setState(() => _message = 'UPI id copied.');
  }

  Future<void> _submit() async {
    final String utr = _utr.text.trim();
    if (utr.length < 8) {
      setState(() => _message =
          'Enter the 12-digit reference number your UPI app showed you.');
      return;
    }
    setState(() {
      _sending = true;
      _message = null;
    });
    try {
      await ContentService.instance.submitLivePassPayment(
        sessionId: widget.sessionId,
        utr: utr,
      );
      if (!mounted) return;
      setState(() {
        _sending = false;
        _done = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _message = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final PaymentSettings? s = _settings;
    final bool ready = s?.isConfigured ?? false;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
        decoration: const BoxDecoration(
          color: IvoryColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: IvoryColors.gold,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_done) ...<Widget>[
                const Center(
                    child: Text('🎟️', style: TextStyle(fontSize: 44))),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    'Your pass is on its way.',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'It opens the moment the house verifies it.',
                    style:
                        TextStyle(fontSize: 13, color: IvoryColors.textSoft),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('CLOSE'),
                ),
              ] else if (_mode == 'razorpay') ...<Widget>[
                RazorpayPayPanel(
                  purpose: 'live_pass',
                  sessionId: widget.sessionId,
                  label: widget.title,
                ),
              ] else ...<Widget>[
                Center(
                  child: Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'Rs.${widget.priceInr} - one seat, one night.',
                    style:
                        TextStyle(fontSize: 13, color: IvoryColors.textSoft),
                  ),
                ),
                const SizedBox(height: 18),
                if (!ready)
                  const Text(
                      'The house has not set its UPI details yet.',
                      textAlign: TextAlign.center)
                else ...<Widget>[
                  InkWell(
                    onTap: _copy,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: IvoryColors.surfaceWarm,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: IvoryColors.hairline),
                      ),
                      child: Row(
                        children: <Widget>[
                          const Icon(Icons.copy_rounded, size: 17),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(s?.upiId ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700))),
                          const Text('tap to copy',
                              style: TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _pay,
                    icon: const Icon(Icons.launch_rounded, size: 17),
                    label: Text('OPEN MY UPI APP - RS.${widget.priceInr}'),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _utr,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'UPI reference number',
                      hintText: 'The 12-digit number after you paid',
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_message != null) ...<Widget>[
                    Text(_message!,
                        style: TextStyle(
                            fontSize: 12.5, color: IvoryColors.plum)),
                    const SizedBox(height: 8),
                  ],
                  IvoryGradientButton(
                    label: _sending ? 'SENDING...' : 'I HAVE PAID',
                    icon: Icons.verified_outlined,
                    busy: _sending,
                    onPressed: _sending ? null : _submit,
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// END OF FILE - lib/widgets/live_pass_sheet.dart
