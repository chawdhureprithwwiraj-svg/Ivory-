import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/live_models.dart';
import '../models/payment.dart';
import '../services/gift_service.dart';
import '../services/live_service.dart';
import '../services/payment_service.dart';
import '../services/razorpay_service.dart';
import '../theme/ivory_insets.dart';
import '../theme/ivory_theme.dart';
import 'gift_moment.dart';

/// ============================================================
/// IVORY - SENDING A GIFT
///
/// The gift appears on her screen the instant it is sent. In UPI
/// mode the member finishes in their UPI app and pastes the
/// reference; in Razorpay mode the panel takes over and the gift
/// turns gold the moment payment verifies. Either way, the Gift
/// Moment plays the second the gift is sent.
/// ============================================================

void showGiftSheet(BuildContext context, {int? sessionId, int? postId}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => GiftSheet(sessionId: sessionId, postId: postId),
  );
}

class GiftSheet extends StatefulWidget {
  const GiftSheet({super.key, this.sessionId, this.postId});

  final int? sessionId;
  final int? postId;

  @override
  State<GiftSheet> createState() => _GiftSheetState();
}

class _GiftSheetState extends State<GiftSheet> {
  final TextEditingController _note = TextEditingController();
  final TextEditingController _utr = TextEditingController();

  /// 'post' when the sheet was opened from a post, 'live' in
  /// the room. There is no third case - the sheet is only ever
  /// opened with one of the two ids.
  String get _surface => widget.postId != null ? 'post' : 'live';

  List<Gift> _gifts = <Gift>[];
  PaymentSettings? _settings;
  Gift? _chosen;
  int? _sendId;
  String _mode = 'upi';

  bool _loading = true;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _note.dispose();
    _utr.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      // TWO WORLDS, AND THE SHEET MUST NOT MIX THEM.
      // A gift sent under a post asks for the post nine; a gift
      // sent in the live room asks for the live nine.
      final List<Gift> g =
          await LiveService.instance.gifts(surface: _surface);
      final PaymentSettings s = await PaymentService.instance.fetchSettings();
      final String m = await RazorpayService.instance.fetchMode();
      if (!mounted) return;
      setState(() {
        _gifts = g;
        _settings = s;
        _mode = m;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  /// Sends it. The gift is already on her screen - and the Gift
  /// Moment is already playing - before any payment step begins.
  Future<void> _send() async {
    final Gift? g = _chosen;
    if (g == null || _busy) return;

    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final int id = await LiveService.instance.sendGift(
        giftId: g.id,
        sessionId: widget.sessionId,
        postId: widget.postId,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      );
      if (!mounted) return;
      GiftMoment.show(context, emoji: g.emoji, name: g.name, from: 'from you');
      setState(() => _sendId = id);

      if (_mode != 'razorpay') {
        final PaymentSettings? s = _settings;
        if (s != null && s.isConfigured) {
          final Uri uri = s.intentUri(
            amountInr: g.priceInr,
            note: 'Ivory - ${g.name}',
          );
          try {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } catch (_) {
            if (mounted) {
              setState(() => _message =
                  'No UPI app opened. Pay ${s.upiId} manually, then paste '
                  'the reference below.');
            }
          }
        }
      }
      if (mounted) setState(() => _busy = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _attach() async {
    final int? id = _sendId;
    final String utr = _utr.text.trim();
    if (id == null) return;
    if (utr.length < 8) {
      setState(() => _message = 'Paste the reference number your UPI app '
          'showed you.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await LiveService.instance.attachGiftUtr(id, utr);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: ivorySheetFoot(context),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
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
              const SizedBox(height: 18),
              if (_sendId != null && _mode == 'razorpay')
                ..._payStep()
              else if (_sendId != null)
                ..._confirmStep(context)
              else
                ..._chooseStep(context),
              if (_message != null) ...<Widget>[
                const SizedBox(height: 14),
                Text(
                  _message!,
                  style: TextStyle(
                    fontSize: 12.8,
                    height: 1.45,
                    color: IvoryColors.plum,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _payStep() => <Widget>[
        Center(
          child: Text(_chosen?.emoji ?? '\u{1F48C}',
              style: const TextStyle(fontSize: 46)),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text('It is on her screen',
              style: Theme.of(context).textTheme.headlineMedium),
        ),
        const SizedBox(height: 14),
        RazorpayPayPanel(
          purpose: 'gift',
          giftSendId: _sendId,
          label: _chosen?.name ?? 'A gift',
        ),
      ];

  List<Widget> _chooseStep(BuildContext context) => <Widget>[
        Text(_surface == 'post' ? 'Tell me what it did' : 'Send me something',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(
          _surface == 'post'
              ? 'Some things a comment cannot carry. Pick the one '
                  'that is true and I will know exactly what you meant.'
              : 'It appears on my screen straight away.',
          style: TextStyle(fontSize: 13, color: IvoryColors.textSoft),
        ),
        const SizedBox(height: 16),
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(22),
              child: CircularProgressIndicator(color: IvoryColors.amber),
            ),
          )
        else
          ..._gifts.map(_giftRow),
        const SizedBox(height: 12),
        TextField(
          controller: _note,
          maxLength: 120,
          decoration: const InputDecoration(
            counterText: '',
            labelText: 'A line with it (optional)',
          ),
        ),
        const SizedBox(height: 14),
        IvoryGradientButton(
          label: _chosen == null
              ? 'CHOOSE ONE'
              : (_busy
                  ? 'SENDING...'
                  : 'SEND ${_chosen!.emoji}  Rs.${_chosen!.priceInr}'),
          icon: Icons.favorite_rounded,
          onPressed: (_chosen == null || _busy) ? null : _send,
        ),
      ];

  List<Widget> _confirmStep(BuildContext context) => <Widget>[
        Center(
          child: Text(
            _chosen?.emoji ?? '\u{1F90D}',
            style: const TextStyle(fontSize: 46),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text('It is on her screen',
              style: Theme.of(context).textTheme.headlineMedium),
        ),
        const SizedBox(height: 8),
        Text(
          'Finish the payment in your UPI app, then paste the reference '
          'here so it can be confirmed.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.5,
            height: 1.5,
            color: IvoryColors.textSoft,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _utr,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'The 12-digit reference number',
          ),
        ),
        const SizedBox(height: 14),
        IvoryGradientButton(
          label: _busy ? 'SENDING...' : 'I HAVE PAID',
          icon: Icons.verified_rounded,
          onPressed: _busy ? null : _attach,
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('I will send the reference later'),
          ),
        ),
      ];

  Widget _giftRow(Gift g) {
    final bool on = _chosen?.id == g.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _chosen = g),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: on ? IvoryColors.surfaceWarm : IvoryColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: on ? IvoryColors.gold : IvoryColors.hairlineStrong,
              width: on ? 1.8 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              Text(g.emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      g.name,
                      style: const TextStyle(
                        color: IvoryColors.burgundy,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (g.line != null)
                      Text(
                        g.line!,
                        style: TextStyle(
                          fontSize: 12.3,
                          fontStyle: FontStyle.italic,
                          color: IvoryColors.textSoft,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                'Rs.${g.priceInr}',
                style: const TextStyle(
                  color: IvoryColors.plum,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// END OF FILE - lib/widgets/gift_sheet.dart
