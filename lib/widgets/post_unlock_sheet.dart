import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/ivory_post.dart';
import '../models/payment.dart';
import '../services/content_service.dart';
import '../services/payment_service.dart';
import '../services/razorpay_service.dart';
import '../theme/ivory_theme.dart';

/// ============================================================
/// IVORY - BUYING ONE POST
///
/// A membership is a relationship. This is a single door: pay once,
/// and that one piece is yours for good, whatever tier you are on
/// and whatever happens to your membership later.
///
/// Same UPI flow the tiers use - pay in your own app, bring back
/// the reference, and it opens the moment it is verified.
/// ============================================================
class PostUnlockSheet extends StatefulWidget {
  const PostUnlockSheet({super.key, required this.post});

  final IvoryPost post;

  @override
  State<PostUnlockSheet> createState() => _PostUnlockSheetState();
}

class _PostUnlockSheetState extends State<PostUnlockSheet> {
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
      amountInr: widget.post.priceInr,
      note: 'Ivory - ${widget.post.title}',
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
      await ContentService.instance.submitPostPayment(
        postId: widget.post.id,
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
    final IvoryPost p = widget.post;
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
              if (_done)
                ..._thanks(context)
              else if (_mode == 'razorpay') ...<Widget>[
                RazorpayPayPanel(
                  purpose: 'post_unlock',
                  postId: p.id,
                  label: p.title,
                ),
              ] else
                ..._form(context, p, ready),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _thanks(BuildContext context) => <Widget>[
        Center(
          child: Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              gradient: IvoryColors.goldGradient,
              shape: BoxShape.circle,
              boxShadow: IvoryTheme.softShadow(blur: 16, y: 6),
            ),
            child: const Icon(Icons.check_rounded,
                color: IvoryColors.burgundy, size: 32),
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: Text('Sent for checking',
              style: Theme.of(context).textTheme.headlineMedium),
        ),
        const SizedBox(height: 10),
        Text(
          'I verify these myself, usually within a few hours. The moment '
          'it clears, this opens for you and stays open for good.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.55,
            color: IvoryColors.textSoft,
          ),
        ),
        const SizedBox(height: 22),
        IvoryGradientButton(
          label: 'CLOSE',
          icon: Icons.favorite_rounded,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ];

  List<Widget> _form(BuildContext context, IvoryPost p, bool ready) =>
      <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: IvoryColors.goldGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.lock_open_rounded,
                  color: IvoryColors.burgundy, size: 25),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Open this one',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 2),
                  Text(
                    p.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: IvoryColors.textSoft,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: IvoryTheme.card(highlighted: true),
          child: Row(
            children: <Widget>[
              Text(
                'Rs.${p.priceInr}',
                style: const TextStyle(
                  color: IvoryColors.burgundy,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Paid once. Yours for good, whatever happens to your '
                  'membership.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: IvoryColors.textSoft,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: IvoryColors.amber),
            ),
          )
        else if (!ready)
          Text(
            'Payments are not switched on yet. Please try again a little '
            'later.',
            style: TextStyle(fontSize: 13.5, color: IvoryColors.textSoft),
          )
        else ...<Widget>[
          IvoryGradientButton(
            label: 'PAY Rs.${p.priceInr} IN YOUR UPI APP',
            icon: Icons.account_balance_wallet_rounded,
            onPressed: _pay,
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: _copy,
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: Text(_settings?.upiId ?? ''),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _utr,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'The 12-digit reference number',
              hintText: 'Your UPI app shows it after paying',
            ),
          ),
          const SizedBox(height: 14),
          IvoryGradientButton(
            label: _sending ? 'SENDING...' : 'I HAVE PAID',
            icon: Icons.verified_rounded,
            onPressed: _sending ? null : _submit,
          ),
        ],
        if (_message != null) ...<Widget>[
          const SizedBox(height: 14),
          Text(
            _message!,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: IvoryColors.plum,
            ),
          ),
        ],
      ];
}

// END OF FILE - lib/widgets/post_unlock_sheet.dart
