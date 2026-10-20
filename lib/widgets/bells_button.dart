import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/bell_models.dart';
import '../screens/bells_screen.dart';
import '../services/bell_push_open.dart';
import '../services/bells_service.dart';
import 'bell_paint.dart';
import 'bell_sound.dart';
import 'sound_bank.dart';

/// ============================================================
/// IVORY - THE DOORBELL IN THE TOP BAR
///
/// One small bell that tells the member where the day stands.
///  - A bell is open and not yet rung: it wiggles and its colour
///    cycles through coral, mint, tangerine and sky, with a badge
///    counting the open bells still waiting.
///  - The open bell has been rung: it settles into one calm colour.
///  - All the bells for today are rung: a soft mint glow.
/// If the house closes the doorbell, the icon quietly disappears.
/// ============================================================
class BellsButton extends StatefulWidget {
  const BellsButton({super.key, required this.onOpenTab});

  final void Function(String tab) onOpenTab;

  @override
  State<BellsButton> createState() => _BellsButtonState();
}

class _BellsButtonState extends State<BellsButton>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4000),
  )..repeat();
  Timer? _tick;
  Timer? _preload;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    BellsService.instance.start();
    BellsService.instance.refreshQuietly();
    _preload = Timer(const Duration(seconds: 4), BellSound.instance.load);
    // Tapping a bell reminder on the phone opens the doorbell.
    BellPushOpen.listen(() {
      if (mounted && !_opening) _open();
    });
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      final DateTime? n = BellsService.instance.state.value?.nextOpenAt;
      if (n != null && !n.isAfter(DateTime.now())) {
        BellsService.instance.refreshQuietly();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) BellsService.instance.refreshQuietly();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tick?.cancel();
    _preload?.cancel();
    BellPushOpen.stop();
    _loop.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    _opening = true;
    SoundBank.instance.play('bells').then((bool ok) {
      if (!ok) BellSound.instance.play('door');
    });
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BellsScreen(onOpenTab: widget.onOpenTab),
      ),
    );
    _opening = false;
    SoundBank.instance.stop('bells');
    BellsService.instance.refreshQuietly();
  }

  /// Open bells that have not been rung yet.
  int _waiting(BellsState s) {
    int n = 0;
    for (final BellItem b in s.bells) {
      if (b.isOpen && !b.rung) n++;
    }
    return n;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<BellsState?>(
      valueListenable: BellsService.instance.state,
      builder: (BuildContext context, BellsState? s, Widget? _) {
        if (s != null && !s.enabled) return const SizedBox.shrink();
        final int waiting = s == null ? 0 : _waiting(s);
        final bool pending = waiting > 0;
        final bool done = s != null && s.allRung;
        return Semantics(
          button: true,
          label: 'Ring My Doorbell',
          child: InkResponse(
            radius: 26,
            onTap: _open,
            child: SizedBox(
              width: 46,
              height: 48,
              child: AnimatedBuilder(
                animation: _loop,
                builder: (BuildContext _, Widget? __) {
                  final double t = _loop.value;
                  final Color c = pending
                      ? _cycle(t)
                      : done
                      ? BellTones.noon
                      : BellTones.pearl;
                  final double swing = pending
                      ? math.sin(t * math.pi * 2 * 5) *
                            0.22 *
                            (t < 0.35 ? 1 - t / 0.35 : 0)
                      : 0;
                  return Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      if (s != null)
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            value: s.need == 0 ? 0 : s.rungN / s.need,
                            strokeWidth: 2,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.18,
                            ),
                            valueColor: AlwaysStoppedAnimation<Color>(c),
                          ),
                        ),
                      BellShape(
                        color: c,
                        width: 25,
                        glow: pending ? 0.7 : (done ? 0.5 : 0.15),
                        swing: swing,
                        dim: !pending && !done,
                      ),
                      if (pending)
                        Positioned(
                          right: 1,
                          top: 3,
                          child: Container(
                            constraints: const BoxConstraints(minWidth: 16),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: BellTones.dawn,
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                            child: Text(
                              '$waiting',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                height: 1.15,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  /// A smooth walk through the four bell colours.
  Color _cycle(double t) {
    final double p = t * 4;
    final int i = p.floor() % 4;
    return BellTones.mix(BellTones.of(i), BellTones.of(i + 1), p - p.floor());
  }
}

// END OF FILE - lib/widgets/bells_button.dart
