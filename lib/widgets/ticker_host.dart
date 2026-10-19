import 'package:flutter/material.dart';

import '../services/ticker_service.dart';
import 'ivory_footer.dart';
import 'ticker_ribbon.dart';

/// ============================================================
/// IVORY - THE TICKER'S LANE (one place, over every screen)
///
/// `main.dart` wraps the whole app once, so no screen has to know the
/// ticker exists. The ribbon is drawn ABOVE the navigator, so it shows
/// on every screen without exception: the live room, video and voice
/// calls, broadcasts, full-screen films, the Bells, the Ladder, posts,
/// sheets and dialogs, and while the keyboard is open.
///
/// It crosses in ONE continuous, steady motion from the left edge to
/// beyond the right edge. It never pauses, lingers or slows down. The
/// only times it is not there: before sign-in, or if the member
/// switched ribbons off.
///
/// While a live room, call or full-screen film is on, the ribbon is
/// look-only: taps pass straight through it, so a stray touch can never
/// close a call or pop a room. On every other screen a tap opens it.
/// ============================================================
class IvoryTicker {
  IvoryTicker._();

  /// How wide the ribbon is, as a share of the screen width. 0.85 leaves
  /// 15% of the screen free (about 7.5% each side). Change this ONE
  /// number to make the ribbon longer or shorter.
  static const double widthShare = 0.85;

  /// For `MaterialApp.builder`: the footer wrap plus the lane above it.
  static Widget wrap(BuildContext context, Widget? child) {
    return Stack(
      children: <Widget>[
        Positioned.fill(child: IvoryFooter.wrap(context, child)),
        const _TickerLane(),
      ],
    );
  }
}

class _TickerLane extends StatefulWidget {
  const _TickerLane();

  @override
  State<_TickerLane> createState() => _TickerLaneState();
}

class _TickerLaneState extends State<_TickerLane>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  TickerShow? _show;
  late final Listenable _watch;

  @override
  void initState() {
    super.initState();
    final TickerService s = TickerService.instance;
    _watch = Listenable.merge(<Listenable>[
      IvoryFooter.hiders,
      s.signedIn,
      s.showRibbons,
      s.current,
    ]);
    s.current.addListener(_onShow);
    _c.addStatusListener(_onStatus);
    s.start();
  }

  @override
  void dispose() {
    TickerService.instance.current.removeListener(_onShow);
    TickerService.instance.blocked.value = false;
    _c.dispose();
    super.dispose();
  }

  void _onShow() {
    final TickerShow? s = TickerService.instance.current.value;
    if (identical(s, _show)) return;
    if (s == null) {
      _c.stop();
      if (mounted) setState(() => _show = null);
      return;
    }
    _c.duration = Duration(seconds: s.seconds);
    _c.value = 0;
    if (mounted) setState(() => _show = s);
    _c.forward();
  }

  void _onStatus(AnimationStatus st) {
    if (st == AnimationStatus.completed) {
      final TickerShow? done = _show;
      TickerService.instance.finish(done);
      if (mounted) setState(() => _show = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mq = MediaQuery.of(context);
    final TickerService s = TickerService.instance;
    return AnimatedBuilder(
      animation: _watch,
      builder: (BuildContext context, Widget? _) {
        final bool off = !s.signedIn.value || !s.showRibbons.value;
        final TickerShow? show = _show;
        if (off || show == null) return const SizedBox.shrink();
        // Live room, calls and full-screen films: look only.
        final bool lookOnly = IvoryFooter.hiders.value > 0;
        final double top = mq.padding.top + 56 + s.settings.laneOffset;
        return Positioned(
          top: top,
          left: 0,
          right: 0,
          height: 62,
          // Not a Material: a Material would catch every tap in the lane.
          child: IgnorePointer(
            ignoring: lookOnly,
            child: DefaultTextStyle(
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                decoration: TextDecoration.none,
              ),
              child: CustomSingleChildLayout(
                delegate: _CrossDelegate(_c),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => s.open(show),
                  child: TickerPill(show: show, t: _c),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Where the ribbon is, moment by moment: one straight, even glide from
/// fully off the left edge to fully off the right edge. No easing, no
/// holding, no drift. The crossing time is the admin's "Crossing takes".
class _CrossDelegate extends SingleChildLayoutDelegate {
  _CrossDelegate(this.t) : super(relayout: t);

  final Animation<double> t;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints c) =>
      BoxConstraints.tightFor(width: c.maxWidth * IvoryTicker.widthShare);

  @override
  Offset getPositionForChild(Size size, Size child) {
    final double s = size.width;
    final double w = child.width;
    final double start = -w - 4;
    final double end = s + 4;
    return Offset(start + (end - start) * t.value, 4);
  }

  @override
  bool shouldRelayout(covariant _CrossDelegate old) => old.t != t;
}

// END OF FILE - lib/widgets/ticker_host.dart
