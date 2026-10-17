import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/ivory_theme.dart';

/// The slim line of small print at the very bottom of every screen.
///
/// It is added ONCE, around the whole app (see `main.dart`), so no screen
/// has to remember it. It sits below the bottom menu and below the phone's
/// own navigation bar, and the screen above it simply gets that much less
/// height.
///
/// Where it stays out of the way:
///   * while the keyboard is open (typing keeps its full room);
///   * on screens wrapped in [IvoryFooterHide]: the live room, calls, and
///     full-screen films and photographs.
class IvoryFooter {
  IvoryFooter._();

  /// The wording. Kept here, in one place.
  static const String line =
      "This platform is maintained by 'Infinity'. All rights reserved 2026";

  /// How tall the strip is, above the phone's own navigation bar.
  static const double height = 24;

  /// How many screens currently ask the footer to step aside.
  static final ValueNotifier<int> hiders = ValueNotifier<int>(0);

  /// For `MaterialApp.builder`.
  static Widget wrap(BuildContext context, Widget? child) =>
      _FooterHost(child: child ?? const SizedBox.shrink());
}

class _FooterHost extends StatelessWidget {
  const _FooterHost({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mq = MediaQuery.of(context);
    final bool typing = mq.viewInsets.bottom > 0;
    return ValueListenableBuilder<int>(
      valueListenable: IvoryFooter.hiders,
      builder: (BuildContext context, int hidden, Widget? _) {
        final bool show = hidden == 0 && !typing;
        // The footer takes over the phone's bottom edge, so the screen
        // above must not reserve that edge a second time.
        final MediaQueryData inner = show
            ? mq.copyWith(
                padding: mq.padding.copyWith(bottom: 0),
                viewPadding: mq.viewPadding.copyWith(bottom: 0),
              )
            : mq;
        return Column(
          children: <Widget>[
            Expanded(
              child: MediaQuery(data: inner, child: child),
            ),
            show
                ? _FooterStrip(bottomInset: mq.padding.bottom)
                : const SizedBox.shrink(),
          ],
        );
      },
    );
  }
}

class _FooterStrip extends StatelessWidget {
  const _FooterStrip({required this.bottomInset});

  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    // No coloured band: only burgundy small print. The strip is painted
    // in the same warm cream as the bottom of the page (the last colour
    // of the page gradient) so it can never show the phone's bare
    // background behind the words.
    return Container(
      width: double.infinity,
      height: IvoryFooter.height + bottomInset,
      padding: EdgeInsets.fromLTRB(12, 0, 12, bottomInset),
      color: IvoryColors.pageGradient.colors.last,
      alignment: Alignment.center,
      child: MediaQuery.withNoTextScaling(
        child: Semantics(
          label: IvoryFooter.line,
          excludeSemantics: true,
          child: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              IvoryFooter.line,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                color: IvoryColors.burgundy,
                fontSize: 11,
                height: 1.2,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Wrap a screen in this to make the footer step aside while it is open.
/// It steps back in by itself when the screen closes.
class IvoryFooterHide extends StatefulWidget {
  const IvoryFooterHide({super.key, required this.child});

  final Widget child;

  @override
  State<IvoryFooterHide> createState() => _IvoryFooterHideState();
}

class _IvoryFooterHideState extends State<IvoryFooterHide> {
  bool _counted = false;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    // Changed after the frame, never in the middle of building one.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_closed) return;
      _counted = true;
      IvoryFooter.hiders.value = IvoryFooter.hiders.value + 1;
    });
  }

  @override
  void dispose() {
    _closed = true;
    if (_counted) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        final int now = IvoryFooter.hiders.value;
        IvoryFooter.hiders.value = now > 0 ? now - 1 : 0;
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// END OF FILE - lib/widgets/ivory_footer.dart
