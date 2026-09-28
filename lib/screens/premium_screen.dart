import 'package:flutter/material.dart';

import '../services/content_service.dart';
import '../theme/ivory_theme.dart';

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
      final List<Map<String, dynamic>> tiers =
          await ContentService.instance.fetchTiers();
      if (!mounted) return;
      setState(() {
        _tiers = tiers;
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
            Center(
              child: Text(
                'From weekly written stories to the innermost circle. '
                'Cancel whenever you like.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  color: IvoryColors.textSoft,
                ),
              ),
            ),
            const SizedBox(height: 22),
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
              'Payment by UPI arrives in the next sprint: you will pay from '
              'any UPI app, send the 12-digit UTR, and your tier unlocks the '
              'moment it is approved.',
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
                  'The open feed, polls and teasers. You are here now.',
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
                    'MOST INTIMATE',
                    style: TextStyle(
                      color: IvoryColors.burgundy,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
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
            label: 'UNLOCK THIS TIER',
            icon: Icons.lock_open,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'UPI checkout for $name arrives in the next sprint.',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
