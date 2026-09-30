import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/wish.dart';
import '../screens/live_screen.dart';
import '../services/live_service.dart';
import '../theme/ivory_theme.dart';

/// ============================================================
/// IVORY - BOOKING A 1:1 SESSION
///
/// The everyday heart of the app: one member, one session, audio or
/// video. Three ways in, and this sheet works out which applies:
///
///   included   - the member's tier carries an allowance, so the
///                session costs nothing and is metered in minutes
///   as a wish  - anyone may buy one outright; a paid session never
///                touches the allowance
///   waiting    - a session already requested, or confirmed and
///                ready to join
///
/// Times are picked on your Cal.com page. The call itself always
/// happens inside Ivory.
/// ============================================================
class CallWishSheet extends StatefulWidget {
  const CallWishSheet({
    super.key,
    required this.category,
    this.onOpenTab,
  });

  final WishCategory category;

  /// Sends the member to the Premium tab to renew, upgrade or change
  /// tier - the other way out when the minutes have gone.
  final void Function(String tab)? onOpenTab;

  @override
  State<CallWishSheet> createState() => _CallWishSheetState();
}

class _CallWishSheetState extends State<CallWishSheet> {
  CallBalance _balance = CallBalance.none;
  BookingLink? _link;
  List<CallRequest> _mine = <CallRequest>[];
  bool _loading = true;
  bool _busy = false;
  String? _message;

  String get _kind => widget.category.callKind ?? 'video';
  int get _minutes => widget.category.minutes ?? 30;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final CallBalance b = await LiveService.instance.balance(_kind);
      final BookingLink? l = await LiveService.instance.bookingLink(_kind);
      final List<CallRequest> all = await LiveService.instance.myCalls();
      if (!mounted) return;
      setState(() {
        _balance = b;
        _link = l;
        _mine = all
            .where((CallRequest c) =>
                c.kind == _kind &&
                (c.status == 'requested' ||
                    c.status == 'accepted' ||
                    c.status == 'active'))
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _message = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _openBooking() async {
    final String? url = _link?.url;
    if (url == null) {
      setState(() => _message =
          'The booking page is not published yet. Ask again shortly.');
      return;
    }
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _request({required bool paid}) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await LiveService.instance.requestCall(
        kind: _kind,
        minutes: _minutes,
        priceInr: paid ? widget.category.basePriceInr : 0,
        note: paid
            ? 'Wish: ${widget.category.name}'
            : 'Included with membership',
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = 'Asked. Now pick a time that suits you both.';
      });
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _join(CallRequest c) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => LiveScreen(
          sessionId: c.id,
          title: widget.category.name,
          subtitle: '${c.minutes} minutes with me',
          mode: LiveMode.call,
          videoEnabled: c.isVideo,
        ),
      ),
    );
    _load();
  }

  String _dmy(DateTime d) {
    const List<String> m = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (BuildContext context, ScrollController sc) => Container(
        decoration: const BoxDecoration(
          color: IvoryColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: ListView(
          controller: sc,
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 34),
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
            _header(context),
            const SizedBox(height: 20),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(28),
                  child: CircularProgressIndicator(color: IvoryColors.amber),
                ),
              )
            else ...<Widget>[
              _allowanceCard(),
              const SizedBox(height: 16),
              if (_mine.isNotEmpty) ...<Widget>[
                _sectionLabel('Your sessions'),
                ..._mine.map(_callRow),
                const SizedBox(height: 14),
              ],
              _steps(),
              if (_message != null) ...<Widget>[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: IvoryColors.surfaceWarm,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: IvoryColors.gold, width: 1),
                  ),
                  child: Text(
                    _message!,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.5,
                      color: IvoryColors.textSoft,
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  Widget _header(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: IvoryColors.goldGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _kind == 'video' ? Icons.videocam_rounded : Icons.call_rounded,
                color: IvoryColors.burgundy,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                widget.category.name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ],
        ),
        if (widget.category.tagline != null) ...<Widget>[
          const SizedBox(height: 14),
          Text(
            widget.category.tagline!,
            style: const TextStyle(
              fontFamily: 'serif',
              fontSize: 16,
              height: 1.5,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
              color: IvoryColors.plum,
            ),
          ),
        ],
      ],
    );
  }

  Widget _allowanceCard() {
    final bool included = _balance.isIncluded;
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: IvoryTheme.card(highlighted: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          IvoryEyebrow(
            included ? 'Included with your membership' : 'Available as a wish',
            icon: included ? Icons.verified_rounded : Icons.auto_awesome,
          ),
          const SizedBox(height: 12),
          if (included) ...<Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  '${_balance.remaining}',
                  style: const TextStyle(
                    color: IvoryColors.burgundy,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 7),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'of ${_balance.allowed} minutes left ${_balance.periodLabel}',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: IvoryColors.textSoft,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: 1 - _balance.fraction,
                minHeight: 8,
                backgroundColor: IvoryColors.hairlineStrong,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(IvoryColors.gold),
              ),
            ),
            if (_balance.resetsAt != null) ...<Widget>[
              const SizedBox(height: 9),
              Text(
                'Your cycle renews on ${_dmy(_balance.resetsAt!)} - counted '
                'from the day you joined this tier, not the calendar month. '
                'Minutes do not carry over.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: IvoryColors.textFaint,
                ),
              ),
            ],
            if (_balance.noShows > 0) ...<Widget>[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: IvoryColors.surfaceWarm,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: IvoryColors.amber, width: 1),
                ),
                child: Text(
                  _balance.noShows == 1
                      ? 'One session was missed this cycle. Missing a second '
                          'is still free - after that, a missed session uses '
                          'its minutes.'
                      : 'Two sessions have been missed this cycle. The next '
                          'one that is missed will use its minutes.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: IvoryColors.textSoft,
                  ),
                ),
              ),
            ],
          ] else
            Text(
              'Your tier does not carry ${_kind == 'video' ? 'video' : 'audio'} '
              'minutes yet. You can still have this session by making it a '
              'wish - Rs.${widget.category.basePriceInr} for $_minutes minutes.',
              style: TextStyle(
                fontSize: 13.5,
                height: 1.55,
                color: IvoryColors.textSoft,
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            color: IvoryColors.plum,
            fontSize: 11.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.3,
          ),
        ),
      );

  Widget _callRow(CallRequest c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: IvoryTheme.card(),
      child: Row(
        children: <Widget>[
          Icon(
            c.canJoin ? Icons.check_circle_rounded : Icons.schedule_rounded,
            color: c.canJoin ? IvoryColors.gold : IvoryColors.textFaint,
            size: 21,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  c.statusLabel,
                  style: const TextStyle(
                    color: IvoryColors.burgundy,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${c.minutes} minutes'
                  '${c.priceInr > 0 ? ' - Rs.${c.priceInr}' : ' - included'}',
                  style: TextStyle(fontSize: 12.5, color: IvoryColors.textSoft),
                ),
              ],
            ),
          ),
          if (c.canJoin)
            TextButton(
              onPressed: () => _join(c),
              child: const Text('JOIN'),
            ),
        ],
      ),
    );
  }

  Widget _steps() {
    final bool included = _balance.isIncluded;
    final bool canAskFree = included && _balance.remaining >= _minutes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _sectionLabel('How it works'),
        _step(1, 'Ask for the session', 'I am told straight away and confirm '
            'it from my side.'),
        _step(2, 'Pick a time', 'My calendar opens with only the hours I am '
            'genuinely free.'),
        _step(3, 'Come back to Ivory', 'At that time, open this sheet and tap '
            'JOIN. The call happens here, never on another app.'),
        const SizedBox(height: 18),
        if (canAskFree)
          IvoryGradientButton(
            label: _busy ? 'ASKING...' : 'ASK FOR THIS SESSION',
            icon: Icons.favorite_rounded,
            onPressed: _busy ? null : () => _request(paid: false),
          )
        else
          IvoryGradientButton(
            label: _busy
                ? 'ASKING...'
                : 'MAKE THIS A WISH - RS.${widget.category.basePriceInr}',
            icon: Icons.auto_awesome,
            onPressed: _busy ? null : () => _request(paid: true),
          ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _openBooking,
          icon: const Icon(Icons.event_available_rounded, size: 19),
          label: Text(_link?.headline ?? 'Pick a time'),
        ),
        if (!canAskFree) ...<Widget>[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onOpenTab?.call('premium');
            },
            icon: const Icon(Icons.diamond_outlined, size: 19),
            label: Text(
              included
                  ? 'Renew, upgrade or change my tier'
                  : 'See the tiers that include calls',
            ),
          ),
        ],
        if (included && !canAskFree) ...<Widget>[
          const SizedBox(height: 12),
          Text(
            'Only ${_balance.remaining} minutes are left ${_balance.periodLabel}, '
            'and this session needs $_minutes. You can still make it a wish, '
            'which does not touch your allowance.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color: IvoryColors.textFaint,
            ),
          ),
        ],
      ],
    );
  }

  Widget _step(int n, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: IvoryColors.surfaceWarm,
              shape: BoxShape.circle,
              border: Border.all(color: IvoryColors.gold, width: 1.2),
            ),
            child: Center(
              child: Text(
                '$n',
                style: const TextStyle(
                  color: IvoryColors.burgundy,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    color: IvoryColors.burgundy,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 12.8,
                    height: 1.45,
                    color: IvoryColors.textSoft,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// END OF FILE - lib/widgets/call_wish_sheet.dart
