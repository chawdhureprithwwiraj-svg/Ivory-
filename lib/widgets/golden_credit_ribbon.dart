import 'dart:async';

import 'package:flutter/material.dart';

import '../models/quiz_models.dart';
import '../screens/main_shell.dart';
import '../services/quiz_service.dart';
import '../theme/ivory_theme.dart';
import 'gold_burst.dart';
import 'gold_fx.dart';

/// ============================================================
/// IVORY - THE GOLDEN KNOCK-OFF, WHERE IT IS SPENT
///
/// The membership screen and the checkout both need to know one
/// thing: does this member hold gold right now, and for how long?
/// One small store answers it for both, so they can never disagree.
/// The database re-checks everything at payment time; this only
/// decides what to draw.
/// ============================================================
class GoldenCreditStore {
  GoldenCreditStore._();
  static final GoldenCreditStore instance = GoldenCreditStore._();

  final ValueNotifier<GoldenCredit?> credit = ValueNotifier<GoldenCredit?>(
    null,
  );

  Future<void> refresh() async {
    final GoldenCredit? c = await QuizService.instance.myCredit();
    credit.value = c;
  }

  /// True while credit [id] still has more than [need] left. The checkout
  /// asks this before it sends a member off to pay, so a discount can never
  /// run out between paying and sending the reference number.
  bool hasTime(int id, Duration need) {
    final GoldenCredit? c = credit.value;
    return c != null && c.id == id && c.untilExpiry > need;
  }

  /// The credit that can lower [price], or null (a tier priced at or
  /// below the gold cannot use it: a membership is never free).
  GoldenCredit? usableFor(int price) {
    final GoldenCredit? c = credit.value;
    if (c == null || c.untilExpiry <= Duration.zero) return null;
    return price > c.amountInr ? c : null;
  }
}

/// The gold ribbon across the top of the membership screen.
class GoldenCreditRibbon extends StatefulWidget {
  const GoldenCreditRibbon({super.key});

  @override
  State<GoldenCreditRibbon> createState() => _GoldenCreditRibbonState();
}

class _GoldenCreditRibbonState extends State<GoldenCreditRibbon> {
  final GoldenCreditStore _store = GoldenCreditStore.instance;
  Timer? _tick;
  int _n = 0;

  @override
  void initState() {
    super.initState();
    _store.credit.value = null;
    _store.credit.addListener(_changed);
    MainShell.arrivalTick.addListener(_arrived);
    _store.refresh();
    _tick = Timer.periodic(const Duration(seconds: 1), (Timer _) {
      _n++;
      if (_n % 20 == 0) _store.refresh();
      final GoldenCredit? c = _store.credit.value;
      if (c != null && c.untilExpiry <= Duration.zero) {
        _store.credit.value = null;
      } else if (c != null && mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _store.credit.removeListener(_changed);
    MainShell.arrivalTick.removeListener(_arrived);
    _tick?.cancel();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  void _arrived() {
    if (MainShell.arrivals.value == 'premium') _store.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final GoldenCredit? c = _store.credit.value;
    if (c == null) return const SizedBox.shrink();
    final Duration left = c.untilExpiry;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: GoldenFrame(
        radius: 22,
        padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
        child: Row(
          children: <Widget>[
            const GoldCoin(size: 52),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'YOUR GOLDEN KNOCK-OFF',
                    style: TextStyle(
                      color: GoldTones.light,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  GoldShimmerText(
                    '\u20B9${c.amountInr} OFF',
                    style: const TextStyle(
                      fontFamily: IvoryTheme.displayFont,
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Turns to dust in ${goldCountdown(left, seconds: true)}. '
                    'Choose a tier priced above \u20B9${c.amountInr}.',
                    style: TextStyle(
                      color: IvoryColors.cream.withValues(alpha: 0.82),
                      fontSize: 12.2,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The price line of a tier card. Plain when no gold applies; the old
/// price struck through and the new one in gold when it does.
class GoldenPriceRow extends StatelessWidget {
  const GoldenPriceRow({super.key, required this.price});

  final int price;

  @override
  Widget build(BuildContext context) {
    const TextStyle plain = TextStyle(
      color: IvoryColors.plum,
      fontSize: 28,
      fontWeight: FontWeight.w800,
    );
    return ValueListenableBuilder<GoldenCredit?>(
      valueListenable: GoldenCreditStore.instance.credit,
      builder: (BuildContext context, GoldenCredit? _, Widget? child) {
        final GoldenCredit? c = GoldenCreditStore.instance.usableFor(price);
        if (c == null) return Text('\u20B9$price', style: plain);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: <Widget>[
            Text(
              '\u20B9$price',
              style: TextStyle(
                color: IvoryColors.textFaint,
                fontSize: 17,
                decoration: TextDecoration.lineThrough,
                decorationColor: IvoryColors.plum,
              ),
            ),
            const SizedBox(width: 8),
            GoldShimmerText(
              '\u20B9${price - c.amountInr}',
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: IvoryColors.plum,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A line on the checkout: the gold being spent on this order, with
/// the time it has left, because the payment must be sent before then.
class GoldenOrderNote extends StatefulWidget {
  const GoldenOrderNote({super.key, required this.creditInr});

  final int creditInr;

  @override
  State<GoldenOrderNote> createState() => _GoldenOrderNoteState();
}

class _GoldenOrderNoteState extends State<GoldenOrderNote> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (Timer _) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.creditInr <= 0) return const SizedBox.shrink();
    final GoldenCredit? c = GoldenCreditStore.instance.credit.value;
    final String ends = c == null
        ? ''
        : ' Ends in ${goldCountdown(c.untilExpiry, seconds: true)}, '
              'so pay and send your reference number before then.';
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: IvoryColors.goldGradient,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.auto_awesome,
              size: 18,
              color: IvoryColors.burgundy,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Golden Knock-off applied: \u20B9${widget.creditInr} off this order.$ends',
              style: const TextStyle(
                color: IvoryColors.burgundy,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// END OF FILE - lib/widgets/golden_credit_ribbon.dart
