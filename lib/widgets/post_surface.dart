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
      // The inset is measured HERE, outside the sheet, and carried
      // in. Flutter strips the top padding from the MediaQuery it
      // hands the builder when useSafeArea is false, so asking for it
      // in there returns 0 and the content runs under the clock.
      builder: (_) => _RisingSheet(
        topInset: MediaQuery.of(context).padding.top,
        child: child,
      ),
    );
  }
}

// =====================================================================
// The sheet that can actually reach the top
// =====================================================================
class _RisingSheet extends StatefulWidget {
  const _RisingSheet({required this.child, required this.topInset});

  final Widget child;

  /// Height of the status bar, measured outside this sheet. See the
  /// note at the call site: it cannot be read from in here.
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
                SizedBox(height: topInset * t),

                SizedBox(
                  height: 28,
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

                Expanded(
                  child: SingleChildScrollView(
                    controller: sc,
                    padding: const EdgeInsets.fromLTRB(22, 4, 22, 40),
                    child: widget.child,
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
