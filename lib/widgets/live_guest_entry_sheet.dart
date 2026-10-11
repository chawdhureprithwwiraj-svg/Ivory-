import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/live_guest_models.dart';
import '../models/payment.dart';
import '../services/live_guest_service.dart';
import '../services/payment_service.dart';
import '../services/razorpay_service.dart';
import '../theme/ivory_theme.dart';
import '../theme/ivory_insets.dart';

Future<void> showLiveGuestEntrySheet(
  BuildContext context, {
  required int sessionId,
  required String title,
  required int feeInr,
  LiveGuestCheckout? resumeCheckout,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (_) => LiveGuestEntrySheet(
      sessionId: sessionId,
      title: title,
      feeInr: feeInr,
      resumeCheckout: resumeCheckout,
    ),
  );
}

class LiveGuestEntrySheet extends StatefulWidget {
  const LiveGuestEntrySheet({
    super.key,
    required this.sessionId,
    required this.title,
    required this.feeInr,
    this.resumeCheckout,
  });

  final int sessionId;
  final String title;
  final int feeInr;
  final LiveGuestCheckout? resumeCheckout;

  @override
  State<LiveGuestEntrySheet> createState() => _LiveGuestEntrySheetState();
}

class _LiveGuestEntrySheetState extends State<LiveGuestEntrySheet> {
  final TextEditingController _utr = TextEditingController();
  LiveGuestCheckout? _checkout;
  PaymentSettings? _settings;
  String _mode = 'upi';
  String _mediaKind = 'video';
  bool _loading = true;
  bool _busy = false;
  bool _submitted = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _checkout = widget.resumeCheckout;
    _loadPaymentMode();
  }

  @override
  void dispose() {
    _utr.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentMode() async {
    try {
      final String mode = await RazorpayService.instance.fetchMode();
      final PaymentSettings? settings = mode == 'razorpay'
          ? null
          : await PaymentService.instance.fetchSettings();
      if (!mounted) return;
      setState(() {
        _mode = mode;
        _settings = settings;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _message = 'Payment details could not be loaded. Please retry.';
      });
    }
  }

  Future<void> _startRequest() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final LiveGuestCheckout checkout =
          await LiveGuestService.instance.startRequest(
        sessionId: widget.sessionId,
        mediaKind: _mediaKind,
      );
      if (!mounted) return;
      setState(() {
        _checkout = checkout;
        _busy = false;
        _submitted = checkout.amountDueInr == 0;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _openUpi() async {
    final PaymentSettings? s = _settings;
    final LiveGuestCheckout? c = _checkout;
    if (s == null || c == null || !s.isConfigured) return;
    final Uri uri = s.intentUri(
      amountInr: c.amountDueInr,
      note: 'Ivory guest place - ${widget.title}',
    );
    try {
      final bool opened =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        setState(() => _message =
            'No UPI app opened. Copy the UPI id below and pay from your app.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _message =
            'No UPI app opened. Copy the UPI id below and pay from your app.');
      }
    }
  }

  Future<void> _copyUpi() async {
    final String upi = _settings?.upiId ?? '';
    if (upi.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: upi));
    if (mounted) setState(() => _message = 'UPI id copied.');
  }

  Future<void> _submitUpi() async {
    final LiveGuestCheckout? c = _checkout;
    final String utr = _utr.text.trim();
    if (c == null) return;
    if (utr.length < 8) {
      setState(() => _message = 'Enter the UPI reference number from your app.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await LiveGuestService.instance.submitUpiPayment(
        requestId: c.requestId,
        utr: utr,
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _submitted = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _close() async {
    final LiveGuestCheckout? c = _checkout;
    if (c != null && !_submitted) {
      try {
        await LiveGuestService.instance.cancelRequest(c.requestId);
      } catch (_) {}
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final LiveGuestCheckout? c = _checkout;
    final bool readyToRequest = c == null;
    final bool canUseUpi = _settings?.isConfigured ?? false;
    return Padding(
      padding: EdgeInsets.only(bottom: ivorySheetFoot(context)),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: IvoryColors.gold,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Join Ivory on camera or audio',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                '${widget.title} · ₹${c?.feeInr ?? widget.feeInr} '
                    'for one guest connection',
                textAlign: TextAlign.center,
                style: TextStyle(color: IvoryColors.textSoft, fontSize: 13),
              ),
              const SizedBox(height: 14),
              if (readyToRequest) ...<Widget>[
                _mediaChoice(),
                const SizedBox(height: 12),
                const Text(
                  'This one-time fee is separate from your viewing access, '
                  'which you still need. After payment is verified, Ivory '
                  'reviews your request. If approved, tap JOIN to choose your '
                  'camera and microphone before you go live.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, height: 1.45),
                ),
                const SizedBox(height: 14),
                if (_loading)
                  const Center(child: CircularProgressIndicator())
                else if (_message != null) ...<Widget>[
                  Text(_message!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: IvoryColors.danger)),
                  const SizedBox(height: 8),
                ],
                IvoryGradientButton(
                  label: _busy ? 'OPENING YOUR REQUEST...' : 'CONTINUE',
                  icon: Icons.videocam_rounded,
                  busy: _busy,
                  onPressed: _loading || _busy ? null : _startRequest,
                ),
              ] else if (_submitted) ...<Widget>[
                const Icon(Icons.hourglass_top_rounded,
                    size: 36, color: IvoryColors.amber),
                const SizedBox(height: 8),
                Text(
                  c.amountDueInr == 0
                      ? 'Your guest request is with Ivory.'
                      : (_mode == 'upi'
                          ? 'Your payment is waiting for verification.'
                          : 'Your payment is confirmed; your request is with Ivory.'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                if (c.creditToApplyInr > 0) ...<Widget>[
                  const SizedBox(height: 6),
                  Text('₹${c.creditToApplyInr} guest credit applied.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: IvoryColors.textSoft, fontSize: 12.5)),
                ],
                if (_mode == 'upi' && c.amountDueInr > 0) ...<Widget>[
                  const SizedBox(height: 6),
                  const Text(
                    'Your request appears in Ivory’s guest queue after she '
                    'verifies the UPI reference.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, height: 1.4),
                  ),
                ],
                const SizedBox(height: 16),
                OutlinedButton(onPressed: _close, child: const Text('CLOSE')),
              ] else if (_loading) ...<Widget>[
                const Center(child: CircularProgressIndicator()),
              ] else ...<Widget>[
                Text(
                  c.creditToApplyInr > 0
                      ? '₹${c.creditToApplyInr} guest credit applied · '
                          '₹${c.amountDueInr} remains'
                      : 'Payment due: ₹${c.amountDueInr}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                if (_mode == 'razorpay')
                  RazorpayPayPanel(
                    purpose: 'live_guest_slot',
                    liveGuestRequestId: c.requestId,
                    label: 'Live guest place · ${widget.title}',
                    onUnlocked: () {
                      if (mounted) setState(() => _submitted = true);
                    },
                  )
                else ...<Widget>[
                  if (!canUseUpi)
                    const Text(
                      'The house has not set UPI details yet.',
                      textAlign: TextAlign.center,
                    )
                  else ...<Widget>[
                    InkWell(
                      onTap: _copyUpi,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: IvoryColors.surfaceWarm,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: IvoryColors.hairline),
                        ),
                        child: Row(
                          children: <Widget>[
                            const Icon(Icons.copy_rounded, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_settings?.upiId ?? '')),
                            const Text('tap to copy',
                                style: TextStyle(fontSize: 10.5)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _openUpi,
                      icon: const Icon(Icons.launch_rounded, size: 16),
                      label: Text('OPEN UPI APP · ₹${c.amountDueInr}'),
                    ),
                    TextField(
                      controller: _utr,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'UPI reference number',
                        hintText: 'From the payment receipt',
                      ),
                    ),
                    const SizedBox(height: 10),
                    IvoryGradientButton(
                      label: _busy ? 'SENDING...' : 'I HAVE PAID',
                      icon: Icons.verified_outlined,
                      busy: _busy,
                      onPressed: _busy ? null : _submitUpi,
                    ),
                  ],
                  if (_message != null) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(_message!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: IvoryColors.danger)),
                  ],
                ],
                const SizedBox(height: 8),
                TextButton(onPressed: _close, child: const Text('CANCEL')),
              ],
              const SizedBox(height: 8),
              const Text(
                'You will be shown live to members watching the broadcast. '
                'Your camera and microphone stay off until you tap JOIN.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mediaChoice() => Column(
        children: <Widget>[
          _choice('video', 'VIDEO', Icons.videocam_rounded,
              'Camera and microphone'),
          _choice('audio', 'AUDIO ONLY', Icons.mic_rounded,
              'Your microphone; camera stays off'),
        ],
      );

  Widget _choice(String value, String title, IconData icon, String subtitle) =>
      RadioListTile<String>(
        value: value,
        groupValue: _mediaKind,
        onChanged: (String? v) {
          if (v != null) setState(() => _mediaKind = v);
        },
        activeColor: IvoryColors.burgundy,
        title: Text(title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11.5)),
        secondary: Icon(icon, color: IvoryColors.amber),
        contentPadding: EdgeInsets.zero,
        dense: true,
      );
}

// END OF FILE - lib/widgets/live_guest_entry_sheet.dart
