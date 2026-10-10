import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/live_models.dart';
import '../models/wish.dart';
import '../services/live_service.dart';
import '../services/wish_service.dart';
import '../theme/ivory_theme.dart';
import 'call_book_flow.dart';
import 'call_sheet_bits.dart';
import 'wish_call_breath.dart';
import 'sessions_panel.dart';

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
/// WHAT THIS WIDGET SHOWS DEPENDS ON WHERE IT IS PUT.
///
/// **CARD = DECISION. LINE = FACT.** A session still waiting for
/// the member to choose a time is a DECISION, and decisions go
/// above everything, because nothing else on the page matters
/// until it is made. A session already settled is a FACT - there
/// is nothing to do but turn up - and a fact should be a quiet
/// line further down, not a block of gold shouting at somebody
/// who has already done everything asked of them.
enum WishBannerPart {
  /// Things still needing the member to act. Goes at the top.
  decisions,

  /// Sessions already settled. A thin line under the hero.
  settled,
}

class WishCallBanner extends StatefulWidget {
  const WishCallBanner({
    super.key,
    this.onSomethingWaiting,
    this.part = WishBannerPart.decisions,
    this.targetCallId,
    this.pulseKey = 0,
  });

  /// Which half of the strip this copy is responsible for.
  final WishBannerPart part;

  /// The one call identified by the member's notification, if any.
  final int? targetCallId;

  /// Changes on each arrival so a repeated notice restarts the glow.
  final int pulseKey;

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
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant WishCallBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulseKey != oldWidget.pulseKey ||
        widget.targetCallId != oldWidget.targetCallId) {
      _load();
    }
  }

  Future<void> _load() async {
    final int generation = ++_loadGeneration;
    try {
      List<CallRequest> calls = await LiveService.instance.myCalls();
      final int? targetId = widget.targetCallId;
      if (targetId != null) {
        final int found = calls.indexWhere((CallRequest c) => c.id == targetId);
        if (found >= 0) {
          final CallRequest target = calls.removeAt(found);
          calls.insert(0, target);
        } else {
          try {
            final dynamic row = await Supabase.instance.client
                .from('call_requests')
                .select()
                .eq('id', targetId)
                .maybeSingle();
            if (row is Map<String, dynamic>) {
              calls = <CallRequest>[CallRequest.fromDb(row), ...calls];
            }
          } catch (_) {
            // Keep visible rows if the exact refresh is temporarily offline.
          }
        }
      }
      final List<Wish> wishes = await WishService.instance.fetchMyWishes();
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        // LIST BY WHAT IS FINISHED, NOT BY WHAT IS NAMED.
        //
        // This used to admit only 'accepted' and 'active'. The
        // moment a member picked a time the status moved on -
        // to 'confirmed' or 'scheduled' - and the session
        // DISAPPEARED from the Wish page altogether, while
        // still showing correctly inside its own call sheet.
        // That is exactly what she photographed.
        //
        // Naming every live status was the mistake. There is
        // one short list of ways a session can be OVER, and it
        // cannot grow by accident; anything not on it is still
        // ahead of the member and belongs on this page.
        _calls = calls
            .where((CallRequest c) => !const <String>{
                  'done',
                  'completed',
                  'ended',
                  'cancelled',
                  'canceled',
                  'declined',
                  'rejected',
                  'missed',
                  'expired',
                }.contains(c.status))
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
      // Quiet. A newer arrival may already have started a better read.
      if (!mounted || generation != _loadGeneration) return;
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

  /// A settled session: she has said yes AND a time is fixed.
  bool _isSettled(CallRequest c) => c.requestedFor != null;

  @override
  Widget build(BuildContext context) {
    if (widget.part == WishBannerPart.settled) {
      final List<CallRequest> settled = _calls.where(_isSettled).toList();
      if (settled.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final CallRequest c in settled)
            WishCallBreath(
              on: false,
              pulseKey: widget.pulseKey,
              child: _settled(
                  context,
                  c.isVideo
                      ? Icons.videocam_rounded
                      : Icons.phone_in_talk_rounded,
                  c),
            ),
        ],
      );
    }

    final List<CallRequest> todo =
        _calls.where((CallRequest c) => !_isSettled(c)).toList();
    if (todo.isEmpty && _wishes.isEmpty) {
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
        for (final CallRequest c in todo)
          WishCallBreath(
            on: widget.targetCallId != null &&
                c.id == widget.targetCallId &&
                c.requestedFor == null,
            pulseKey: widget.pulseKey,
            child: _callCard(context, c),
          ),
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
  /// A session that still needs a time is the only thing on
  /// this page that asks something of the member, so it is the
  /// only one that gets a full card. Once a time is set there is
  /// nothing to do but turn up, and a page-filling card saying
  /// "nothing to do" is the worst use of a screen there is - so
  /// it shrinks to one line.
  Widget _callCard(BuildContext context, CallRequest c) {
    final IconData icon =
        c.isVideo ? Icons.videocam_rounded : Icons.phone_in_talk_rounded;

    if (c.requestedFor != null) {
      return _settled(context, icon, c);
    }

    return _shell(
      context,
      icon: icon,
      heading: c.isVideo
          ? 'Your video session is agreed'
          : 'Your audio session is agreed',
      body: 'I have said yes. All that is left is for you to '
          'choose when - pick a day and a time that suits you.',
      actionLabel: 'PICK YOUR TIME',
      actionIcon: Icons.event_available_rounded,
      onAction: () => _pick(c),
      extra: null,
    );
  }

  /// ONE THIN LINE: what it is, when it is, and the way to the
  /// instructions.
  ///
  /// Deliberately slight. A member who has chosen, paid and
  /// picked a time has done everything asked of them, and a
  /// heavy gold block at the top of the page would be the app
  /// shouting an instruction at somebody who is already
  /// obedient. It now sits under the hero where the eye lands
  /// anyway, taking a third of the room it used to, and it
  /// stays there until the session is over.
  ///
  /// IT IS A DOOR, NOT AN EXPLANATION. It says only what is
  /// booked and when. The instructions themselves live in one
  /// place - `SessionGuideSheet` - and this is simply a way in.
  Widget _settled(BuildContext context, IconData icon, CallRequest c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: () => SessionGuideSheet.open(context),
        child: Container(
          padding: const EdgeInsets.fromLTRB(11, 8, 9, 8),
          decoration: BoxDecoration(
            color: IvoryColors.surfaceWarm,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
                color: IvoryColors.gold.withValues(alpha: 0.75), width: 1),
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 14, color: IvoryColors.amber),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${c.isVideo ? 'Video call' : 'Audio call'}'
                  '  \u00B7  ${ivoryWhen(c.requestedFor!)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: IvoryColors.burgundy,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'WHAT TO DO',
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w800,
                  color: IvoryColors.plum.withValues(alpha: 0.85),
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 15, color: IvoryColors.plum),
            ],
          ),
        ),
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
