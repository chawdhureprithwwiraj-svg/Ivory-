import 'package:flutter/material.dart';

import '../services/ticker_service.dart';
import 'ivory_footer.dart';
import 'ticker_ribbon.dart';

/// ============================================================
/// IVORY - THE TICKER'S LANE (one place, under every screen)
///
/// `main.dart` wraps the whole app once, so no screen has to know the
/// ticker exists. The ribbon glides in from the left, lingers and
/// drifts a little in the middle of the screen, then glides out to the
/// right, one unbroken crossing that does not care which screen the
/// member moves to. It steps aside (and waits where it is) while the
/// keyboard is open or a screen has asked for quiet (the live room,
/// calls, full-screen films and photographs), and it is not there at
/// all before sign-in or if the member switched ribbons off.
/// ============================================================
class IvoryTicker {
  IvoryTicker._();

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
  bool _hidden = false;
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
    if (!_hidden) _c.forward();
  }

  void _onStatus(AnimationStatus st) {
    if (st == AnimationStatus.completed) {
      final TickerShow? done = _show;
      TickerService.instance.finish(done);
      if (mounted) setState(() => _show = null);
    }
  }

  void _setHidden(bool h) {
    if (!mounted || h == _hidden) return;
    _hidden = h;
    TickerService.instance.blocked.value = h;
    if (h) {
      _c.stop();
    } else if (_show != null && _c.value < 1) {
      _c.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mq = MediaQuery.of(context);
    final bool keyboard = mq.viewInsets.bottom > 0;
    final TickerService s = TickerService.instance;
    return AnimatedBuilder(
      animation: _watch,
      builder: (BuildContext context, Widget? _) {
        final bool hide =
            keyboard ||
            IvoryFooter.hiders.value > 0 ||
            !s.signedIn.value ||
            !s.showRibbons.value;
        WidgetsBinding.instance.addPostFrameCallback((Duration _) {
          _setHidden(hide);
        });
        final TickerShow? show = _show;
        if (hide || show == null) return const SizedBox.shrink();
        final double top = mq.padding.top + 56 + s.settings.laneOffset;
        return Positioned(
          top: top,
          left: 0,
          right: 0,
          height: 62,
          // Not a Material: a Material would catch every tap in the lane.
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
        );
      },
    );
  }
}

/// Where the ribbon is, moment by moment: a glide in that slows to a
/// stop (20%), a slow drift of 32 px while it lingers (60%), and a
/// glide out to the right that speeds up as it goes (20%).
class _CrossDelegate extends SingleChildLayoutDelegate {
  _CrossDelegate(this.t) : super(relayout: t);

  final Animation<double> t;

  static const Cubic _in = Cubic(0.15, 0.7, 0.3, 1.0);

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints c) =>
      BoxConstraints(maxWidth: c.maxWidth * 0.86);

  @override
  Offset getPositionForChild(Size size, Size child) {
    final double s = size.width;
    final double w = child.width;
    final double start = -w - 8;
    final double mid = (s - w) / 2;
    final double end = s + 8;
    final double v = t.value;
    double x;
    if (v < 0.2) {
      x = start + ((mid - 16) - start) * _in.transform(v / 0.2);
    } else if (v < 0.8) {
      x = (mid - 16) + 32 * ((v - 0.2) / 0.6);
    } else {
      x = (mid + 16) + (end - (mid + 16)) * Curves.easeIn.transform((v - 0.8) / 0.2);
    }
    return Offset(x, 4);
  }

  @override
  bool shouldRelayout(covariant _CrossDelegate old) => old.t != t;
}

// END OF FILE - lib/widgets/ticker_host.dart
