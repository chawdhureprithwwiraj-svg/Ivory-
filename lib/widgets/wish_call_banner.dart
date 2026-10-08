import 'package:flutter/material.dart';

import '../models/live_models.dart';
import '../models/wish.dart';
import '../services/live_service.dart';
import '../services/wish_service.dart';
import '../theme/ivory_theme.dart';
import 'call_book_flow.dart';
import 'call_sheet_bits.dart';
import 'wish_guide.dart';

/// WHERE YOUR WISHES ARE.
///
/// A member who has paid should never have to wonder what is
/// happening. A notification is a moment; it is read once and
/// gone, and if it is missed there is nothing left to see. This
/// strip sits at the top of the Wish page and stays until the
/// thing it describes is finished.
///
/// It covers every wish, not only calls - a story being written, a
/// voice note, a letter, a surprise. Each one says plainly where it
/// has got to, and gives the member the one action that is theirs
/// to take, if there is one.
///
/// IT NEVER MENTIONS MINUTES OR MONEY. What a session includes
/// depends on the member's tier and on numbers the house may change
/// at any time. Repeating them here would be one more place to go
/// wrong, and it is not what the member needs at this moment. They
/// need to know what is waiting and what to do about it.
class WishCallBanner extends StatefulWidget {
  const WishCallBanner({super.key, this.onSomethingWaiting});

  /// Called with true the moment there is a card to show, so the
  /// page above can take the member to the top of the screen.
  /// Without it they sit where they left off and never see this.
  final void Function(bool waiting)? onSomethingWaiting;

  @override
  State<WishCallBanner> createState() => _WishCallBannerState();
}

class _WishCallBannerState extends State<WishCallBanner> {
  List<CallRequest> _calls = <CallRequest>[];
  List<Wish> _wishes = <Wish>[];
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final List<CallRequest> calls = await LiveService.instance.myCalls();
      final List<Wish> wishes = await WishService.instance.fetchMyWishes();
      if (!mounted) return;
      setState(() {
        _calls = calls
            .where((CallRequest c) =>
                c.status == 'accepted' || c.status == 'active')
            .toList();
        _wishes = wishes
            .where((Wish w) =>
                w.status == 'accepted' ||
                w.status == 'in_progress' ||
                w.status == 'delivered')
            .toList();
      });
      widget.onSomethingWaiting
          ?.call(_calls.isNotEmpty || _wishes.isNotEmpty);
    } catch (_) {
      // Quiet. The page below is perfectly usable, and the strip
      // comes back on the next pull-to-refresh.
    }
  }

  Future<void> _pick(CallRequest c) async {
    await bookCallSlot(
      context,
      c,
      // The cards below already say where everything stands, so a
      // success line would only repeat them. Only a refusal, which
      // nothing else on this page can show, is worth surfacing.
      say: (String m) {
        if (!mounted) return;
        final bool good = m.contains('tap JOIN') || m.contains('is set');
        setState(() => _message = good ? null : m);
      },
      reload: _load,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_calls.isEmpty && _wishes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            'WHERE YOUR WISHES ARE',
            style: TextStyle(
              fontSize: 11.5,
              letterSpacing: 1.3,
              fontWeight: FontWeight.w700,
              color: IvoryColors.textSoft,
            ),
          ),
        ),
        for (final CallRequest c in _calls) _callCard(context, c),
        for (final Wish w in _wishes) _wishCard(context, w),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _note(_message!),
          ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _note(String text) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: IvoryColors.surfaceWarm,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: IvoryColors.gold),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 13.5, color: IvoryColors.burgundy),
        ),
      );

  // ---------------------------------------------------------------
  Widget _callCard(BuildContext context, CallRequest c) {
    final bool needsTime = c.requestedFor == null;
    final String heading =
        needsTime ? 'Your session is agreed' : 'Your session is set';
    final String body = needsTime
        ? 'I have said yes. All that is left is for you to choose '
            'when - pick a day and a time that suits you.'
        : 'Agreed for ${ivoryWhen(c.requestedFor!)}. Open Ivory a '
            'little before and tap Join.';

    return _shell(
      context,
      icon: c.isVideo
          ? Icons.videocam_rounded
          : Icons.phone_in_talk_rounded,
      heading: heading,
      body: body,
      actionLabel: needsTime ? 'PICK YOUR TIME' : null,
      actionIcon: Icons.event_available_rounded,
      onAction: needsTime ? () => _pick(c) : null,
      // Once a time exists, the only thing left they could get
      // wrong is the arriving. So we spell the arriving out.
      extra: needsTime
          ? null
          : WishGuidePanel(
              title: 'What to do on the day',
              steps: sessionDaySteps(
                isVideo: c.isVideo,
                whenLabel: ivoryWhen(c.requestedFor!),
              ),
              closing: 'Nothing can go wrong here. If you are '
                  'early, late, or you lose the app for a '
                  'moment, just come back and tap JOIN again.',
            ),
    );
  }

  Widget _wishCard(BuildContext context, Wish w) {
    late final String heading;
    late final String body;

    switch (w.status) {
      case 'accepted':
        heading = 'I have said yes';
        body = '${w.categoryName} - it is on my list. I will start '
            'on it shortly, and you will find it here when it is '
            'ready.';
        break;
      case 'in_progress':
        heading = 'I am making it now';
        body = '${w.categoryName} - this one is in my hands at the '
            'moment. It will appear here the moment it is done.';
        break;
      default:
        heading = 'It is ready for you';
        body = '${w.categoryName} - made, and waiting. Open your '
            'wish to see it.';
    }

    return _shell(
      context,
      icon: w.status == 'delivered'
          ? Icons.redeem_rounded
          : Icons.auto_awesome_rounded,
      heading: heading,
      body: body,
      actionLabel: null,
      actionIcon: Icons.auto_awesome_rounded,
      onAction: null,
      extra: null,
    );
  }

  // ---------------------------------------------------------------
  Widget _shell(
    BuildContext context, {
    required IconData icon,
    required String heading,
    required String body,
    required String? actionLabel,
    required IconData actionIcon,
    required VoidCallback? onAction,
    Widget? extra,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
        decoration: BoxDecoration(
          color: IvoryColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: IvoryColors.gold, width: 1.4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: IvoryColors.gold,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, size: 20, color: IvoryColors.burgundy),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    heading,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: IvoryColors.burgundy),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              body,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: IvoryColors.textSoft,
              ),
            ),
            if (extra != null) ...<Widget>[
              const SizedBox(height: 14),
              extra,
            ],
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onAction,
                  icon: Icon(actionIcon, size: 18),
                  label: Text(actionLabel),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// END OF FILE - lib/widgets/wish_call_banner.dart
