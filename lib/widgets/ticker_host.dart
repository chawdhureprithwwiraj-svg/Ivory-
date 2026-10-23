import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import '../services/ticker_service.dart';
import 'dream_banner.dart';
import 'dream_house.dart';
import 'golden_gate.dart';
import 'ivory_footer.dart';
import 'lane_law.dart';
import 'sound_bank.dart';
import 'ticker_ribbon.dart';
import 'ticker_sound.dart';

/// ============================================================
/// IVORY - THE TICKER'S LANE (one place, over every screen)
///
/// `main.dart` wraps the whole app once, so no screen has to know the
/// ticker exists. The ribbon is drawn ABOVE the navigator, so it shows
/// on every screen without exception: the live room, video and voice
/// calls, broadcasts, full-screen films, the Bells, the Ladder, posts,
/// sheets and dialogs.
///
/// CC.195 - TWO HEARTBEATS, ONE LANE LAW:
/// * House (TickerService) and dream (DreamEngine) breaths share
///   this lane; CC.196 adds the sign-out gate and the beat watchdog.
/// * A ribbon picks its lane the moment it starts - TOP on everyday
///   screens and live video and broadcasts, BOTTOM on live audio and
///   whenever the top lane is owned - and never jumps mid-flight.
/// * Ribbons never overlap: one crosses at a time; a late arrival
///   waits in a single slot (a waiting house ribbon is never pushed
///   out by a dream); when the lane clears, one catch-up pair may
///   follow back to back, then the normal breath resumes.
/// * Dream ribbons wear the royal banner sealed YOUR DREAM HOUSE,
///   ring a celesta outside live rooms, stay silent inside calls and
///   broadcasts, and bloom into petals when cheered. A member sees
///   the burgundy honesty card once, before her first dream ribbon.
///
/// It crosses in ONE continuous, steady motion from the left edge to
/// beyond the right edge. The only times it is not there: before
/// sign-in, or if the member switched ribbons off.
///
/// While a live room, call or full-screen film is on, the ribbon is
/// look-only: taps pass straight through it. On every other screen a
/// tap opens it (house) or blooms it (dream).
/// ============================================================
class IvoryTicker {
  IvoryTicker._();

  /// How wide the ribbon is, as a share of the screen width.
  static const double widthShare = 0.85;

  /// For `MaterialApp.builder`: the footer wrap plus the lane above it.
  static Widget wrap(BuildContext context, Widget? child) {
    return _ClickCatcher(
      child: Stack(
        children: <Widget>[
          Positioned.fill(child: IvoryFooter.wrap(context, child)),
          const _TickerLane(),
          const GoldenGate(),
        ],
      ),
    );
  }
}

/// Gets the owner's recordings ready a few seconds after the app opens.
class _ClickCatcher extends StatefulWidget {
  const _ClickCatcher({required this.child});

  final Widget child;

  @override
  State<_ClickCatcher> createState() => _ClickCatcherState();
}

class _ClickCatcherState extends State<_ClickCatcher> {
  Timer? _warm;

  @override
  void initState() {
    super.initState();
    unawaited(SoundBank.instance.load());
    _warm = Timer(const Duration(milliseconds: 4000), () {
      unawaited(SoundBank.instance.warm());
    });
  }

  @override
  void dispose() {
    _warm?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// One crossing ribbon: either a house message or a dreamed member.
class _Cross {
  _Cross.house(this.house) : dream = null;
  _Cross.dream(this.dream) : house = null;

  final TickerShow? house;
  final DreamShow? dream;

  bool get isDream => dream != null;
}

class _TickerLane extends StatefulWidget {
  const _TickerLane();

  @override
  State<_TickerLane> createState() => _TickerLaneState();
}

class _TickerLaneState extends State<_TickerLane>
    with TickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  late final AnimationController _b = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  _Cross? _cross;
  _Cross? _queued;
  Lane _lane = Lane.top;
  bool _cardOpen = false;
  bool _cardSeen = false;
  bool _cardChecked = false;
  Offset _burstAt = Offset.zero;
  Timer? _breath;
  Timer? _retry;
  MediaQueryData? _mq;
  late final Listenable _watch;

  static const String _cardKey = 'ivory_dream_card_seen';

  @override
  void initState() {
    super.initState();
    final TickerService s = TickerService.instance;
    _watch = Listenable.merge(<Listenable>[
      IvoryFooter.hiders,
      s.signedIn,
      s.showRibbons,
      s.current,
      DreamEngine.instance.current,
      LaneLaw.flags,
    ]);
    s.current.addListener(_onHouse);
    DreamEngine.instance.current.addListener(_onDream);
    LaneLaw.flags.addListener(_onFlags);
    s.paused.addListener(_onPause);
    s.signedIn.addListener(_onGate);
    s.showRibbons.addListener(_onGate);
    _c.addStatusListener(_onStatus);
    s.start();
    DreamEngine.instance.start();
    unawaited(_loadViewerName());
    unawaited(_loadCard());
  }

  @override
  void dispose() {
    TickerService.instance.current.removeListener(_onHouse);
    DreamEngine.instance.current.removeListener(_onDream);
    LaneLaw.flags.removeListener(_onFlags);
    TickerService.instance.paused.removeListener(_onPause);
    TickerService.instance.signedIn.removeListener(_onGate);
    TickerService.instance.showRibbons.removeListener(_onGate);
    TickerService.instance.blocked.value = false;
    _breath?.cancel();
    _retry?.cancel();
    _c.dispose();
    _b.dispose();
    super.dispose();
  }

  /// Sign-out or ribbons-off: every ribbon dies at once, dream included,
  /// and the dream sleeps until the member is back.
  void _onGate() {
    final TickerService s = TickerService.instance;
    if (!s.signedIn.value || !s.showRibbons.value) {
      _c.stop();
      _retry?.cancel();
      DreamEngine.instance.stop();
      if (_cross != null || _queued != null || _cardOpen) {
        setState(() {
          _cross = null;
          _queued = null;
          _cardOpen = false;
        });
      }
    } else {
      DreamEngine.instance.start();
    }
  }

  /// A beat that somehow never started gets offered again once.
  void _watchDream(DreamShow d) {
    Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      if (DreamEngine.instance.current.value != d) return;
      if (_cross?.dream == d || _queued?.dream == d || _cardOpen) return;
      _offer(_Cross.dream(d));
    });
  }

  Future<void> _loadViewerName() async {
    try {
      DreamHouse.instance.viewerName =
          (await AuthService.instance.loadProfile())?.displayName ?? '';
    } catch (_) {
      // No name, no guard: the bag simply deals as it is.
    }
  }

  Future<void> _loadCard() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      _cardSeen = p.getBool(_cardKey) ?? false;
    } catch (_) {
      _cardSeen = true; // Never trap a member behind a broken card.
    }
    if (!mounted) return;
    setState(() => _cardChecked = true);
    _drain();
  }

  // --------------- the queue: one slot, no overlaps ---------------

  void _onHouse() {
    final TickerShow? show = TickerService.instance.current.value;
    if (show == null) {
      _c.stop();
      if (mounted) setState(() => _cross = null);
      return;
    }
    if (_cross?.house == show) return;
    _offer(_Cross.house(show));
  }

  void _onDream() {
    final DreamShow? d = DreamEngine.instance.current.value;
    if (d == null) return;
    final TickerService s = TickerService.instance;
    // The house dreams only for a signed-in member who keeps ribbons.
    if (!s.signedIn.value || !s.showRibbons.value) return;
    if (_cross?.dream == d) return;
    _offer(_Cross.dream(d));
    _watchDream(d);
  }

  /// A ribbon wants to cross. If the lane is busy it waits in the one
  /// slot: a waiting house ribbon is never pushed out by a dream, but
  /// a newer arrival always replaces a waiting dream.
  void _offer(_Cross c) {
    if (_cross != null) {
      _mergeQueued(c);
      return;
    }
    _tryStart(c);
  }

  void _mergeQueued(_Cross c) {
    final _Cross? q = _queued;
    if (q == null || c.house != null || q.isDream) {
      setState(() => _queued = c);
    }
  }

  void _onFlags() {
    _retry?.cancel();
    _drain();
  }

  void _drain() {
    if (_cross != null || _cardOpen) return;
    final TickerService ts = TickerService.instance;
    if (!ts.signedIn.value || !ts.showRibbons.value) return;
    final _Cross? q = _queued;
    if (q == null) return;
    setState(() => _queued = null);
    _tryStart(q);
  }

  void _tryStart(_Cross c) {
    if (!mounted || _cross != null) {
      _mergeQueued(c);
      return;
    }
    final MediaQueryData mq = _mq ?? MediaQuery.of(context);
    final bool keyboard = mq.viewInsets.bottom > 80;
    final Lane? lane = LaneLaw.laneFor(LaneLaw.mode.value, keyboard);
    if (lane == null) {
      // Both lanes are owned right now: wait and re-check.
      setState(() => _queued = c);
      _retry?.cancel();
      _retry = Timer.periodic(const Duration(milliseconds: 1500), (_) {
        if (_cross == null) _drain();
      });
      return;
    }
    if (c.isDream && _cardChecked && !_cardSeen) {
      _cardSeen = true;
      unawaited(_saveCard());
      setState(() { _cardOpen = true; _queued = c; });
      return;
    }
    if (c.isDream && !_cardChecked) {
      setState(() => _queued = c); // the card is still loading
      return;
    }
    _retry?.cancel();
    _start(c, lane);
  }

  Future<void> _saveCard() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setBool(_cardKey, true);
    } catch (_) {
      // The card shows again next time; no harm done.
    }
  }

  void _start(_Cross c, Lane lane) {
    final int secs = c.house?.seconds ?? 10;
    _c.duration = Duration(seconds: secs);
    _c.value = 0;
    setState(() {
      _cross = c;
      _lane = lane;
    });
    // CC.199: inside a live room - audio call, video call or
    // broadcast - every crossing is seen and never heard, so the
    // voice in the room stays the only sound there. Outside, the
    // house band rings the moment it appears, not before.
    final bool silentRoom = LaneLaw.mode.value != LaneMode.everyday;
    if (!silentRoom && IvoryFooter.hiders.value == 0) {
      if (c.isDream) {
        unawaited(SoundBank.instance.playRotate('dream'));
      } else if (c.house != null) {
        TickerSound.instance.play(c.house!.event.grand ? 'grand' : 'soft');
      }
    }
    _c.forward();
  }

  /// Only the member's own touch (the cheer sheet) ever holds a ribbon.
  void _onPause() {
    if (TickerService.instance.paused.value) {
      _c.stop();
    } else if (_cross != null && _c.value < 1) {
      _c.forward();
    }
  }

  void _onStatus(AnimationStatus st) {
    if (st != AnimationStatus.completed) return;
    final _Cross? done = _cross;
    if (done?.house != null) TickerService.instance.finish(done!.house);
    setState(() => _cross = null);
    _breath?.cancel();
    // A short breath, then the waiting ribbon may follow back to back.
    _breath = Timer(const Duration(milliseconds: 1200), _drain);
  }

  void _dreamTap(Offset local) {
    setState(() => _burstAt = local);
    _b.forward(from: 0);
    unawaited(SoundBank.instance.playRotate('dream'));
    // A dream's cheer is counted nowhere: no ledger, no ladder, no
    // bell. Only petals, and the quiet knowing that a light was left.
  }

  void _closeCard() {
    setState(() => _cardOpen = false);
    _drain();
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mq = MediaQuery.of(context);
    _mq = mq;
    final TickerService s = TickerService.instance;
    return AnimatedBuilder(
      animation: _watch,
      builder: (BuildContext context, Widget? _) {
        final bool off = !s.signedIn.value || !s.showRibbons.value;
        final _Cross? cross = _cross;
        final bool lookOnly = IvoryFooter.hiders.value > 0;
        return Stack(
          children: <Widget>[
            if (!off && cross != null) _ribbon(context, mq, s, cross, lookOnly),
            if (_b.isAnimating || _b.value > 0) _petals(),
            if (_cardOpen)
              Positioned(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).padding.bottom + 24,
                child: DreamHonestyCard(onClose: _closeCard),
              ),
          ],
        );
      },
    );
  }

  Widget _ribbon(BuildContext context, MediaQueryData mq, TickerService s,
      _Cross cross, bool lookOnly) {
    final double top = mq.padding.top + 56 + LaneLaw.topChrome.value +
        s.settings.laneOffset;
    final double bottom = mq.padding.bottom + mq.viewInsets.bottom +
        LaneLaw.bottomGap(LaneLaw.mode.value);
    final Widget child = DefaultTextStyle(
      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
        decoration: TextDecoration.none,
      ),
      child: CustomSingleChildLayout(
        delegate: _CrossDelegate(_c),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: cross.isDream
              ? null
              : () => s.open(cross.house!),
          onTapDown: cross.isDream
              ? (TapDownDetails d) => _dreamTap(d.globalPosition)
              : null,
          child: cross.isDream
              ? DreamBanner(show: cross.dream!, t: _c)
              : TickerPill(show: cross.house!, t: _c),
        ),
      ),
    );
    return Positioned(
      top: _lane == Lane.top ? top : null,
      bottom: _lane == Lane.bottom ? bottom : null,
      left: 0,
      right: 0,
      height: 62,
      // Not a Material: a Material would catch every tap in the lane.
      child: IgnorePointer(ignoring: lookOnly, child: child),
    );
  }

  Widget _petals() {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(painter: DreamPetalPainter(_b, _burstAt)),
      ),
    );
  }
}

/// Where the ribbon is, moment by moment: one straight, even glide from
/// fully off the left edge to fully off the right edge.
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
