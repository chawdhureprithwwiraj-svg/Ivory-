import 'package:flutter/material.dart';
import '../models/wish.dart';
import '../screens/live_screen.dart';
import '../models/live_models.dart';
import '../services/live_service.dart';
import '../theme/ivory_theme.dart';
import 'call_sheet_bits.dart';
import 'call_allowance_card.dart';
import 'call_book_flow.dart';

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
      final List<CallRequest> all = await LiveService.instance.myCalls();
      if (!mounted) return;
      setState(() {
        _balance = b;
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
        _message = _cleanErr(e);
      });
    }
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
        _message = _cleanErr(e);
      });
    }
  }

  Future<void> _book(CallRequest c) => bookCallSlot(
        context,
        c,
        say: (String m) {
          if (mounted) setState(() => _message = m);
        },
        reload: _load,
      );

  Future<void> _join(CallRequest c) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => LiveScreen(
          sessionId: c.id,
          // The member is not calling a product, they are calling a
          // person. The house sees their name; they see hers.
          title: 'Ivory',
          subtitle: 'Together, here',
          mode: LiveMode.call,
          videoEnabled: c.isVideo,
        ),
      ),
    );
    _load();
  }

  // Times arrive from Postgres in UTC. ivoryWhen turns them into
  // the member's own clock - never show UTC to a member.
  String _when(DateTime d) => ivoryWhen(d);

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
              CallAllowanceCard(
                balance: _balance,
                kind: _kind,
                minutes: _minutes,
                priceInr: widget.category.basePriceInr,
              ),
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
                if (c.canJoin && c.requestedFor == null)
                  const Text(
                    'Confirmed - now pick your slot on the calendar.',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: IvoryColors.plum),
                  ),
                if (c.status == 'active')
                  Text(
                    'This session is still open. Tap REJOIN to go '
                    'straight back in - nothing is lost.',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: IvoryColors.plum),
                  )
                else if (c.canJoin && c.requestedFor != null)
                  Text(
                    c.windowEnd == null
                        ? 'Agreed for ${_when(c.requestedFor!)} - JOIN '
                            'wakes up a little before.'
                        : 'Window ${_when(c.requestedFor!)} to '
                            '${ivoryClock(c.windowEnd!)} - join any time '
                            'inside.',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: IvoryColors.plum),
                  ),
              ],
            ),
          ),
          if (c.canJoin && c.requestedFor == null)
            TextButton(
              onPressed: () => _book(c),
              child: const Text('BOOK TIME'),
            )
          else if (c.canJoin)
            TextButton(
              onPressed: () => _join(c),
              // A session already running means they were in it
              // and dropped out. JOIN reads like starting over
              // and makes people think they have lost it.
              child: Text(c.status == 'active' ? 'REJOIN' : 'JOIN'),
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
        // The three steps that used to sit here said the same
        // thing as the manual on the Profile page, in slightly
        // different words. One text, one place.
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

}



/// Postgres errors arrive wrapped in transport noise. Keep only the
/// sentence the house wrote.
String _cleanErr(Object e) {
  final String raw = e.toString();
  final RegExpMatch? m = RegExp(r'message: (.*), code:').firstMatch(raw);
  if (m != null) return m.group(1)!;
  return raw.replaceFirst('Exception: ', '');
}
// END OF FILE - lib/widgets/call_wish_sheet.dart
