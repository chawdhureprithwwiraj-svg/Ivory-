import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/ivory_errors.dart';
import '../models/discount_models.dart';
import '../services/code_service.dart';
import '../theme/ivory_theme.dart';
import 'gold_fx.dart';

/// ============================================================
/// IVORY - YOUR SAVINGS AT CHECKOUT
///
/// One saving per payment, never two: either the Golden Knock-off
/// the member brought to checkout, or a discount code (typed, or one
/// of the member's own one-time codes from a treasure). The phone only
/// asks; the house works out the price and checks it again when the
/// order is made.
/// ============================================================
class CheckoutSavings extends StatefulWidget {
  const CheckoutSavings({
    super.key,
    required this.tierId,
    required this.creditInr,
    required this.onChanged,
  });

  final int tierId;

  /// Rupees of a Golden Knock-off attached to this checkout; 0 if none.
  final int creditInr;

  /// Tells the checkout which saving is in force: a code quote, or null,
  /// and whether the Golden Knock-off is being spent.
  final void Function(CodeQuote? quote, bool useCredit) onChanged;

  @override
  State<CheckoutSavings> createState() => _CheckoutSavingsState();
}

class _CheckoutSavingsState extends State<CheckoutSavings>
    with AutomaticKeepAliveClientMixin {
  // Kept alive so scrolling the checkout never forgets the saving in force.
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _ctl = TextEditingController();
  late bool _useCredit = widget.creditInr > 0;
  CodeQuote? _quote;
  List<PrizeCode> _prizes = <PrizeCode>[];
  bool _open = false;
  bool _busy = false;
  String? _err;

  @override
  void initState() {
    super.initState();
    _loadPrizes();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  // The member's own codes: with no Knock-off attached, the best one is
  // put in place at once (and can be removed).
  Future<void> _loadPrizes() async {
    final List<PrizeCode> p = await CodeService.instance.myPrizes();
    if (!mounted || p.isEmpty) return;
    setState(() {
      _prizes = p;
      _open = true;
    });
    if (widget.creditInr > 0) return;
    CodeQuote? best;
    for (final PrizeCode c in p) {
      try {
        final CodeQuote q = await CodeService.instance.quote(
          widget.tierId,
          c.code,
        );
        if (best == null || q.offInr > best.offInr) best = q;
      } catch (_) {}
    }
    if (!mounted || best == null || _quote != null) return;
    _set(best, false);
  }

  void _set(CodeQuote? q, bool credit) {
    setState(() {
      _quote = q;
      _useCredit = credit;
      _err = null;
    });
    widget.onChanged(q, credit);
  }

  Future<void> _apply(String raw) async {
    final String code = raw.trim();
    if (code.isEmpty) return;
    setState(() {
      _busy = true;
      _err = null;
    });
    try {
      final CodeQuote q = await CodeService.instance.quote(widget.tierId, code);
      if (!mounted) return;
      _ctl.clear();
      setState(() => _busy = false);
      _set(q, false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _err = houseMessage(e);
      });
    }
  }

  Widget _choice(String text, bool on, VoidCallback tap) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: tap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: on
                ? IvoryColors.gold.withValues(alpha: 0.3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: on ? GoldTones.deep : IvoryColors.hairlineStrong,
              width: on ? 1.6 : 1,
            ),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: IvoryColors.burgundy,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
              height: 1.25,
            ),
          ),
        ),
      ),
    );
  }

  Widget _applied(CodeQuote q) {
    return Row(
      children: <Widget>[
        const Icon(Icons.check_circle, color: IvoryColors.success, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '${q.code} \u00B7 \u20B9${q.offInr} off',
            style: const TextStyle(
              color: IvoryColors.burgundy,
              fontWeight: FontWeight.w800,
              fontSize: 14.5,
            ),
          ),
        ),
        TextButton(
          onPressed: () => _set(null, false),
          child: const Text('REMOVE'),
        ),
      ],
    );
  }

  Widget _entry() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _ctl,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_-]')),
                  LengthLimitingTextInputFormatter(24),
                ],
                decoration: const InputDecoration(
                  hintText: 'Enter your code',
                  isDense: true,
                ),
                onSubmitted: _apply,
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: IvoryColors.burgundy,
              ),
              onPressed: _busy ? null : () => _apply(_ctl.text),
              child: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('APPLY'),
            ),
          ],
        ),
        if (_prizes.isNotEmpty) ...<Widget>[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: <Widget>[
              for (final PrizeCode p in _prizes)
                ActionChip(
                  avatar: const Icon(Icons.auto_awesome, size: 16),
                  label: Text('${p.code} \u00B7 ${p.offText}'),
                  onPressed: _busy ? null : () => _apply(p.code),
                ),
            ],
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bool hasCredit = widget.creditInr > 0;
    final bool codeMode = !_useCredit;
    if (!hasCredit && !_open && _quote == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => setState(() => _open = true),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: IvoryTheme.card(radius: 18),
            child: const Row(
              children: <Widget>[
                Icon(Icons.local_offer_outlined, color: IvoryColors.plum),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'HAVE A DISCOUNT CODE?',
                    style: TextStyle(
                      color: IvoryColors.burgundy,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                      fontSize: 12.5,
                    ),
                  ),
                ),
                Icon(Icons.expand_more, color: IvoryColors.plum),
              ],
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: IvoryTheme.card(radius: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const IvoryEyebrow('Your saving', icon: Icons.local_offer_outlined),
            const SizedBox(height: 12),
            if (hasCredit) ...<Widget>[
              Row(
                children: <Widget>[
                  _choice(
                    'Golden Knock-off\n\u2212\u20B9${widget.creditInr}',
                    _useCredit,
                    () => _set(null, true),
                  ),
                  const SizedBox(width: 10),
                  _choice(
                    'A discount code\ninstead',
                    codeMode,
                    () => _set(null, false),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (codeMode)
              if (_quote != null) _applied(_quote!) else _entry(),
            if (_err != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _err!,
                  style: const TextStyle(
                    color: IvoryColors.danger,
                    fontSize: 12.5,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              hasCredit
                  ? 'One saving for each payment: your Golden Knock-off or a code, not both.'
                  : 'One code for each payment.',
              style: TextStyle(color: IvoryColors.textFaint, fontSize: 11.5),
            ),
          ],
        ),
      ),
    );
  }
}

// END OF FILE - lib/widgets/checkout_savings.dart
