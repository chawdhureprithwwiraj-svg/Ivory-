import 'package:flutter/material.dart';

import '../models/live_models.dart';
import '../models/wish.dart';
import '../services/wish_service.dart';
import '../services/razorpay_service.dart';
import '../theme/ivory_insets.dart';
import '../theme/ivory_theme.dart';
import '../widgets/wish_call_banner.dart';
import '../services/auth_service.dart';
import '../services/live_service.dart';
import '../widgets/wish_guide.dart';
import '../widgets/wish_status_card.dart';
import '../widgets/call_wish_sheet.dart';
import 'wish_form.dart';

/// Material icons the database is allowed to name, so wish categories
/// can pick their own look without a rebuild.
IconData wishIcon(String name) {
  const Map<String, IconData> icons = <String, IconData>{
    'auto_awesome': Icons.auto_awesome,
    'auto_stories': Icons.auto_stories,
    'graphic_eq': Icons.graphic_eq,
    'movie_creation': Icons.movie_creation,
    'drafts': Icons.drafts,
    'favorite': Icons.favorite,
    'nightlight': Icons.nightlight_round,
    'mic': Icons.mic,
    'photo_camera': Icons.photo_camera,
    'card_giftcard': Icons.card_giftcard,
    'edit_note': Icons.edit_note,
    'videocam': Icons.videocam,
  };
  return icons[name] ?? Icons.auto_awesome;
}

class WishScreen extends StatefulWidget {
  const WishScreen({super.key, this.onOpenTab});

  /// Lets the call sheet send a member to the Premium tab when their
  /// minutes have run out, or when they want to change tier.
  final void Function(String tab)? onOpenTab;

  @override
  State<WishScreen> createState() => _WishScreenState();
}

class _WishScreenState extends State<WishScreen> {
  List<WishCategory> _categories = <WishCategory>[];
  List<Wish> _mine = <Wish>[];
  bool _loading = true;
  String? _error;
  String _mode = 'upi';
  final Map<String, bool> _included = <String, bool>{};

  @override
  void initState() {
    super.initState();
    _load();
    RazorpayService.instance.fetchMode().then((String m) {
      if (mounted) setState(() => _mode = m);
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<WishCategory> cats =
          await WishService.instance.fetchCategories();
      final List<Wish> mine = await WishService.instance.fetchMyWishes();
      if (!mounted) return;
      for (final String kind in <String>['video', 'audio']) {
        try {
          final CallBalance b = await LiveService.instance.balance(kind);
          _included[kind] = b.isIncluded;
        } catch (_) {
          _included[kind] = false;
        }
      }
      if (!mounted) return;
      setState(() {
        _categories = cats;
        _mine = mine;
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

  final ScrollController _scroll = ScrollController();
  bool _waiting = false;
  bool _tookThemUp = false;
  bool _scrolledAway = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// A member reading about the audio session is a long way down
  /// this page. The app remembers where they were, so when Ivory
  /// says yes they come back to the middle of the page and never
  /// see the gold card sitting above them. So we take them up to
  /// it, once, the first time there is something to see.
  void _somethingWaiting(bool waiting) {
    if (!mounted) return;
    setState(() => _waiting = waiting);
    if (!waiting || _tookThemUp) return;
    _tookThemUp = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      if (_scroll.offset < 80) return;
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _toTop() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      0,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  int get _startingPrice => _categories.isEmpty
      ? 999
      : _categories
          .map((WishCategory c) => c.basePriceInr)
          .reduce((int a, int b) => a < b ? a : b);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: IvoryColors.pageGradient),
      child: RefreshIndicator(
        color: IvoryColors.burgundy,
        backgroundColor: IvoryColors.surface,
        onRefresh: _load,
        child: Stack(
          children: <Widget>[
            NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification n) {
                final bool away = _scroll.hasClients && _scroll.offset > 260;
                if (away != _scrolledAway) {
                  setState(() => _scrolledAway = away);
                }
                return false;
              },
              child: ListView(
          controller: _scroll,
          // Room at the foot for the navigation bar and the pill.
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
          children: <Widget>[
            // A member arriving from "Your call is confirmed" must
            // see the thing they were told about, not the same page
            // as always. This answers the question before it is
            // asked, and disappears once the time is chosen.
            // The house does not need her own instructions, and
            // her gold cards belong in the CALLS tab, not here.
            if (!AuthService.instance.isAdminCached) ...<Widget>[
              WishCallBanner(onSomethingWaiting: _somethingWaiting),
            ],
            _hero(),
            const SizedBox(height: 24),
            Text(
              'What would you like made?',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Every wish is virtual, personal, and made only for you.',
              style: TextStyle(
                fontSize: 13.5,
                color: IvoryColors.textSoft,
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 50),
                child: Center(
                  child: CircularProgressIndicator(color: IvoryColors.burgundy),
                ),
              )
            else if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: IvoryColors.danger, fontSize: 13),
              )
            else
              ..._categories.map(_categoryCard),
            if (_mine.isNotEmpty) ...<Widget>[
              const SizedBox(height: 28),
              Text(
                'Your wishes',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              ..._mine.map((Wish w) => wishStatusCard(w, mode: _mode)),
            ],
          ],
              ),
            ),
            // They may still be deep in the page when something
            // lands. This sits above everything and takes them
            // straight to it.
            if (_waiting && _scrolledAway)
              WaitingPill(onTap: _toTop),
          ],
        ),
      ),
    );
  }

  Widget _hero() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
      decoration: BoxDecoration(
        gradient: IvoryColors.deepGradient,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: IvoryColors.gold, width: 1.4),
        boxShadow: IvoryTheme.softShadow(blur: 22, y: 10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  gradient: IvoryColors.goldGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome,
                    color: IvoryColors.burgundy, size: 24),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Text(
                  'THE WISH',
                  style: TextStyle(
                    color: IvoryColors.gold,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Just close your eyes\nand make a wish',
            style: TextStyle(
              fontFamily: IvoryTheme.displayFont,
              color: IvoryColors.cream,
              fontSize: 27,
              height: 1.22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Request anything from me — entirely virtual. A story with your '
            'name in it, a voice note meant only for you, a vignette shot to '
            'your brief. You describe it, I make it.',
            style: TextStyle(
              color: IvoryColors.cream.withValues(alpha: 0.84),
              fontSize: 14.5,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: IvoryColors.goldGradient,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  '₹$_startingPrice onwards',
                  style: const TextStyle(
                    color: IvoryColors.burgundy,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Online only · By appointment · Private',
                  style: TextStyle(
                    color: IvoryColors.cream.withValues(alpha: 0.7),
                    fontSize: 11.8,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _categoryCard(WishCategory c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openWishForm(c),
          child: Container(
            padding: EdgeInsets.all(c.highlight ? 18 : 16),
            // The two call wishes are the offer everything else
            // supports, so they wear the gold border and a warmer
            // fill rather than the plain card.
            decoration: c.highlight
                ? BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        Color(0xFFFFFCF2),
                        Color(0xFFFCEBCB),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: IvoryColors.gold, width: 1.6),
                    boxShadow: IvoryTheme.softShadow(blur: 16, y: 6),
                  )
                : IvoryTheme.card(),
            child: Row(
              children: <Widget>[
                Container(
                  width: c.highlight ? 56 : 50,
                  height: c.highlight ? 56 : 50,
                  decoration: BoxDecoration(
                    gradient: IvoryColors.goldGradient,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(wishIcon(c.icon),
                      color: IvoryColors.burgundy, size: 25),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (c.highlight) ...<Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: IvoryColors.burgundy,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            c.isVideoCall ? 'LIVE WITH ME' : 'MY VOICE, YOURS',
                            style: const TextStyle(
                              color: IvoryColors.cream,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 7),
                      ],
                      Text(
                        c.name,
                        style: TextStyle(
                          color: IvoryColors.burgundy,
                          fontSize: c.highlight ? 17 : 15.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (c.tagline != null) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(
                          c.tagline!,
                          style: c.highlight
                              // The two call wishes are the headline
                              // offer: gold serif italic, the same
                              // emphasis the Home hero uses.
                              ? const TextStyle(
                                  fontFamily: 'serif',
                                  fontSize: 14,
                                  height: 1.45,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w600,
                                  color: IvoryColors.plum,
                                )
                              : TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: IvoryColors.textSoft,
                                ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      // Quoting a price to somebody who has
                      // already paid for it is the quickest way
                      // to make them feel cheated.
                      if (c.isCall && (_included[c.callKind] ?? false))
                        Row(
                          children: <Widget>[
                            const Icon(Icons.verified_rounded,
                                size: 14, color: IvoryColors.amber),
                            const SizedBox(width: 6),
                            Text(
                              'Included with your membership',
                              style: const TextStyle(
                                color: IvoryColors.plum,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: <Widget>[
                            Text(
                              c.priceLabel,
                              style: const TextStyle(
                                color: IvoryColors.plum,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              c.isCall
                                  ? c.callLabel
                                  : '~${c.deliveryDays} days',
                              style: TextStyle(
                                fontSize: 12,
                                color: IvoryColors.textFaint,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: IvoryColors.plum),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openWishForm(WishCategory c) {
    // A call is not a written wish: it needs a time slot, a live
    // balance and a booking page, so it gets its own sheet.
    if (c.isCall) {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => CallWishSheet(
          category: c,
          onOpenTab: widget.onOpenTab,
        ),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: ivorySheetFoot(context),
        ),
        child: WishForm(
          category: c,
          onDone: () {
            Navigator.of(context).pop();
            _load();
          },
        ),
      ),
    );
  }
}

// END OF FILE - lib/screens/wish_screen.dart
