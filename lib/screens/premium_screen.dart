import 'package:flutter/material.dart';

import '../models/payment.dart';
import '../services/content_service.dart';
import '../services/payment_service.dart';
import '../theme/ivory_theme.dart';
import 'checkout_screen.dart';

/// Membership tiers, rendered entirely from the database.
/// Three tiers, four, five - the app simply draws whatever rows are
/// active, in level order. Nothing here hardcodes a count or a price.
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  List<Map<String, dynamic>> _tiers = <Map<String, dynamic>>[];
  Membership? _membership;
  IvoryPayment? _pending;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await PaymentService.instance.expireOld();
      final List<Map<String, dynamic>> tiers =
          await ContentService.instance.fetchTiers();
      final Membership? m = await PaymentService.instance.fetchMembership();
      final List<IvoryPayment> mine =
          await PaymentService.instance.fetchMyPayments();
      IvoryPayment? pending;
      for (final IvoryPayment pay in mine) {
        if (pay.isPending) {
          pending = pay;
          break;
        }
      }
      if (!mounted) return;
      setState(() {
        _tiers = tiers;
        _membership = m;
        _pending = pending;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: IvoryColors.pageGradient),
      child: RefreshIndicator(
        color: IvoryColors.burgundy,
        backgroundColor: IvoryColors.surface,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 40),
          children: <Widget>[
            const Center(
              child: Text(
                'PRIVATE MEMBERSHIP',
                style: TextStyle(
                  color: IvoryColors.plum,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                'Choose your Ivory tier',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge ??
                    Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 10),
            _invitation(),
            const SizedBox(height: 22),
            if (_membership != null) _membershipCard(_membership!),
            if (_pending != null) _pendingCard(_pending!),
            _freeCard(),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 50),
                child: Center(
                  child: CircularProgressIndicator(color: IvoryColors.burgundy),
                ),
              )
            else if (_error != null)
              Text(_error!,
                  style:
                      const TextStyle(color: IvoryColors.danger, fontSize: 13))
            else
              ..._tiers.map(_tierCard),
            const SizedBox(height: 10),
            Text(
              'Pay from any UPI app, send the 12-digit UTR, and your tier '
              'unlocks the moment the payment is verified. Each reference '
              'number can be used only once.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.5,
                color: IvoryColors.textFaint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkout({
    required int tierId,
    required String name,
    required int price,
    required int days,
  }) async {
    final bool? changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => CheckoutScreen(
          tierId: tierId,
          tierName: name,
          priceInr: price,
          durationDays: days,
        ),
      ),
    );
    if (changed == true) await _load();
  }

  /// The invitation that replaces the old one-line subtitle: the
  /// masterstroke, set in the house serif, with the crown line raised
  /// onto its own gold-ruled plate.
  Widget _invitation() {
    return Column(
      children: <Widget>[
        Text(
          'Take the masterstroke to get connected to me directly.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: IvoryTheme.displayFont,
            fontSize: 15.5,
            height: 1.55,
            fontStyle: FontStyle.italic,
            color: IvoryColors.burgundy.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: <Color>[Color(0xFFFFFCF2), Color(0xFFFDF1DC)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: IvoryColors.gold.withValues(alpha: 0.85),
              width: 1.3,
            ),
            boxShadow: IvoryTheme.softShadow(blur: 14, y: 5),
          ),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: IvoryColors.textSoft,
              ),
              children: <InlineSpan>[
                const TextSpan(text: 'Be the '),
                TextSpan(
                  text: 'First to read, first to hear \u{1F451}',
                  style: const TextStyle(
                    fontFamily: IvoryTheme.displayFont,
                    fontSize: 17,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: IvoryColors.burgundy,
                  ),
                ),
                const TextSpan(
                  text: ' \u2014 select your plan and upgrade your '
                      'membership.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _membershipCard(Membership m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
            'YOUR MEMBERSHIP',
            style: TextStyle(
              color: IvoryColors.gold,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            m.tierName,
            style: const TextStyle(
              fontFamily: IvoryTheme.displayFont,
              color: IvoryColors.cream,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            m.daysLeft > 0
                ? '${m.daysLeft} days remaining. Everything at this level is open to you.'
                : 'Renewing today keeps your access unbroken.',
            style: TextStyle(
              color: IvoryColors.cream.withValues(alpha: 0.82),
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pendingCard(IvoryPayment p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: IvoryTheme.card(highlighted: true, radius: 20),
      child: Row(
        children: <Widget>[
          const Icon(Icons.hourglass_top_rounded,
              color: IvoryColors.plum, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Pending verification',
                  style: TextStyle(
                    color: IvoryColors.burgundy,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${p.amountInr} for ${p.tierName ?? 'a membership'} · UTR ${p.utr}',
                  style: TextStyle(
                    color: IvoryColors.textSoft,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _freeCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: IvoryTheme.card(),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: IvoryColors.amber.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.door_front_door_outlined,
                color: IvoryColors.burgundy, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Free Guest',
                  style: TextStyle(
                    color: IvoryColors.burgundy,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  (_membership?.tierLevel ?? 0) > 0
                      ? 'The open feed, polls and teasers.'
                      : 'The open feed, polls and teasers. You are '
                          'here now.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: IvoryColors.textSoft,
                  ),
                ),
              ],
            ),
          ),
          const Text(
            '₹0',
            style: TextStyle(
              color: IvoryColors.plum,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tierCard(Map<String, dynamic> t) {
    final int level = ((t['level'] as num?) ?? 0).toInt();
    final int price = ((t['price_inr'] as num?) ?? 0).toInt();
    final int days = ((t['duration_days'] as num?) ?? 30).toInt();
    final String name = (t['name'] as String?) ?? 'Tier $level';
    final String? description = t['description'] as String?;
    final bool isTop = _tiers.isNotEmpty && t == _tiers.last;
    final bool owned =
        _membership != null && _membership!.tierLevel >= level;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: IvoryTheme.card(highlighted: isTop, radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: IvoryColors.amber.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                      color: IvoryColors.amber.withValues(alpha: 0.6)),
                ),
                child: Text(
                  'TIER $level',
                  style: const TextStyle(
                    color: IvoryColors.plum,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.3,
                  ),
                ),
              ),
              const Spacer(),
              if (isTop)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: IvoryColors.goldGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'THE INNERMOST CIRCLE',
                    style: TextStyle(
                      color: IvoryColors.burgundy,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            name,
            style: const TextStyle(
              fontFamily: IvoryTheme.displayFont,
              color: IvoryColors.burgundy,
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text(
                '₹$price',
                style: const TextStyle(
                  color: IvoryColors.plum,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                days == 30 ? '/ month' : '/ $days days',
                style: TextStyle(
                  color: IvoryColors.textFaint,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          if (description != null && description.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                color: IvoryColors.textSoft,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 18),
          IvoryGradientButton(
            label: owned ? 'RENEW FOR $days MORE DAYS' : 'UNLOCK THIS TIER',
            icon: owned ? Icons.autorenew : Icons.lock_open,
            onPressed: _pending != null
                ? null
                : () => _checkout(
                      tierId: ((t['id'] as num?) ?? 0).toInt(),
                      name: name,
                      price: price,
                      days: days,
                    ),
          ),
          if (_pending != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              'A payment is already being verified.',
              style: TextStyle(color: IvoryColors.textFaint, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

// END OF FILE - lib/screens/premium_screen.dart
