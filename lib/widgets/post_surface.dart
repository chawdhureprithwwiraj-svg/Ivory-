import 'dart:math' as math;
// FlutterView is a dart:ui type. material.dart does not re-export it,
// so annotating View.of(context) without this fails the build with
// "'FlutterView' isn't a type".
import 'dart:ui' show FlutterView;

import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';

/// HOW A POST ARRIVES ON SCREEN.
///
/// Two manners, chosen by what is inside.
///
/// READING AND LISTENING - a story, a voice note, a poll - rises as a
/// sheet over the feed. The feed staying faintly visible underneath is
/// the point: it says "you have not left, flick down and you are back".
/// But it opens at 94% and snaps to the very top, where its corners go
/// square and it stops being a card and becomes a page. The old sheet
/// stopped at 96% and could never reach the top, so it always looked
/// like it had got stuck on the way up.
///
/// WATCHING AND LOOKING - a film, a photograph - takes the whole
/// screen at once. A film is the thing itself, not an attachment to a
/// page, and a strip of feed around the edge only cheapens it.
class IvoryPostSurface {
  IvoryPostSurface._();

  /// [immersive] true for film and photograph, false for everything
  /// that is read or listened to.
  static void show(
    BuildContext context,
    Widget child, {
    bool immersive = false,
  }) {
    if (immersive) {
      Navigator.of(context).push<void>(
        PageRouteBuilder<void>(
          opaque: false,
          barrierColor: IvoryColors.burgundy.withValues(alpha: 0.28),
          transitionDuration: const Duration(milliseconds: 260),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          pageBuilder: (_, __, ___) => _FullPage(child: child),
          transitionsBuilder: (_, Animation<double> a, __, Widget c) {
            return FadeTransition(
              opacity: a,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.06),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: a, curve: Curves.easeOutCubic),
                ),
                child: c,
              ),
            );
          },
        ),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      // Left false on purpose. The sheet has to be able to cover the
      // whole screen; the status bar is cleared by padding inside, so
      // nothing ever hides under the clock or the camera cutout.
      useSafeArea: false,
      barrierColor: IvoryColors.burgundy.withValues(alpha: 0.24),
      // READ THE WINDOW, NOT THE WIDGET TREE. Three builds were spent
      // here. `MediaQuery.of(context).padding.top` is zeroed twice
      // over - main_shell wraps the app in a SafeArea, and
      // useSafeArea:false strips it again - and `viewPadding` came
      // back zero as well. `View.of(context)` is the physical window
      // and no ancestor widget can touch it. The floor is a guard,
      // not a measurement: if the window ever reports nothing, the
      // handle still cannot land on the clock.
      builder: (_) => _RisingSheet(
        topInset: _statusBarHeight(context),
        child: child,
      ),
    );
  }
}

/// Height of the status bar and camera cutout, in logical pixels,
/// taken straight from the window. Deliberately bypasses MediaQuery:
/// every inherited route to this number has already been stripped by
/// the time a post sheet asks for it.
double _statusBarHeight(BuildContext context) {
  final FlutterView view = View.of(context);
  final double fromWindow = view.padding.top / view.devicePixelRatio;
  final double fromTree = MediaQuery.of(context).viewPadding.top;
  return math.max(math.max(fromWindow, fromTree), 24);
}

// =====================================================================
// The sheet that can actually reach the top
// =====================================================================
class _RisingSheet extends StatefulWidget {
  const _RisingSheet({required this.child, required this.topInset});

  final Widget child;

  /// Physical height of the status bar and cutout, taken from
  /// `viewPadding` at the call site. See the note there - `padding` is
  /// zeroed twice over before it reaches this widget.
  final double topInset;

  @override
  State<_RisingSheet> createState() => _RisingSheetState();
}

class _RisingSheetState extends State<_RisingSheet> {
  /// Where the sheet sits, 0 to 1 of the screen. Kept in state only so
  /// the corners and the status bar gap can respond to it.
  ///
  /// It now OPENS full. Asking the owner to drag a post upwards before
  /// she could see it was the wrong instinct - a tap means open, and
  /// nothing should stand between the tap and the thing itself. The
  /// sheet survives only so it can still be thrown downwards to leave.
  double _extent = 1;

  static const double _rest = 0.62;

  /// How far down the content a member has read, 0 to 1, or -1 when
  /// the post is too short to be worth a progress line. Held in a
  /// notifier rather than state on purpose: scrolling a long story
  /// fires on every frame, and rebuilding the whole sheet each time
  /// would stutter on a 4 GB phone. Only the hairline listens.
  final ValueNotifier<double> _read = ValueNotifier<double>(-1);

  /// Below this there is no real scrolling, so a progress line would
  /// be noise rather than help.
  static const double _worthTracking = 600;

  @override
  void dispose() {
    _read.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification n) {
    final ScrollMetrics m = n.metrics;
    if (!m.hasContentDimensions || m.maxScrollExtent < _worthTracking) {
      _read.value = -1;
    } else {
      _read.value = (m.pixels / m.maxScrollExtent).clamp(0.0, 1.0);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final double topInset = widget.topInset;

    // Over the last tenth the card becomes a page: corners run 28 -> 0
    // and the status bar gap opens underneath them.
    final double t = ((_extent - 0.9) / 0.1).clamp(0.0, 1.0);
    final double radius = 28 * (1 - t);

    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (DraggableScrollableNotification n) {
        if ((n.extent - _extent).abs() > 0.004) {
          setState(() => _extent = n.extent);
        }
        return false;
      },
      child: DraggableScrollableSheet(
        initialChildSize: 1,
        minChildSize: _rest,
        maxChildSize: 1,
        snap: true,
        snapSizes: const <double>[_rest, 1],
        expand: false,
        builder: (BuildContext c, ScrollController sc) {
          return Container(
            decoration: BoxDecoration(
              gradient: IvoryColors.pageGradient,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(radius)),
            ),
            child: Column(
              children: <Widget>[
                // Clears the clock and the camera cutout, and only
                // once the sheet is actually up there.
                // Plus a little air, so the eyebrow never sits
                // flush against the clock.
                SizedBox(height: (topInset + 6) * t),

                // width: infinity matters. Column centres its
                // children by default, so without it this box shrinks
                // to the 44px handle and `right: 6` puts the cross in
                // the middle of the handle instead of the screen edge.
                SizedBox(
                  height: 28,
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      Container(
                        width: 44,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: IvoryColors.hairlineStrong,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      // Always there. A way out must never be
                      // something you have to discover.
                      Positioned(
                        right: 6,
                        child: IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.close_rounded,
                              size: 22, color: IvoryColors.plum),
                          onPressed: () => Navigator.of(c).maybePop(),
                        ),
                      ),
                    ],
                  ),
                ),

                // How far through a long piece you are. Appears only
                // when there is enough to scroll, so a short post
                // never carries a line that would always read full.
                ValueListenableBuilder<double>(
                  valueListenable: _read,
                  builder: (BuildContext ctx, double v, Widget? kid) {
                    if (v < 0) return const SizedBox(height: 2);
                    return SizedBox(
                      height: 2,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: v == 0 ? 0.0001 : v,
                          child: Container(color: IvoryColors.gold),
                        ),
                      ),
                    );
                  },
                ),

                Expanded(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: _onScroll,
                    child: SingleChildScrollView(
                      controller: sc,
                      padding: const EdgeInsets.fromLTRB(22, 4, 22, 40),
                      child: widget.child,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// =====================================================================
// Film and photograph - the whole screen
// =====================================================================
class _FullPage extends StatelessWidget {
  const _FullPage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: IvoryColors.pageGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: IvoryColors.burgundy),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 40),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// END OF FILE - lib/widgets/post_surface.dart
