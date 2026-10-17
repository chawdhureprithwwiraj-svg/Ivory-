import 'package:flutter/material.dart';

import '../models/heart_models.dart';
import '../screens/heart_sheet.dart';
import '../services/heart_service.dart';
import '../services/reward_service.dart';
import '../models/reward_models.dart';
import 'treasure_reveal.dart';
import '../theme/ivory_theme.dart';
import 'gold_fx.dart';
import 'heart_paint.dart';

/// ============================================================
/// IVORY - THE GOLDEN HEART IN THE TOP BAR
///
/// A small glass heart that fills with gold as the day goes. It
/// pulses until today's heart is lit, wears the glow number once a
/// glow has begun, and opens the heart sheet. If the house closes the
/// heart it quietly disappears.
/// ============================================================
class HeartButton extends StatefulWidget {
  const HeartButton({super.key});

  @override
  State<HeartButton> createState() => _HeartButtonState();
}

class _HeartButtonState extends State<HeartButton>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    HeartService.instance.state.addListener(_onHeart);
    RewardService.instance.state.addListener(_checkReveal);
    HeartService.instance.refreshQuietly();
  }

  // Whenever the heart changes (a day lit, an app resume) ask whether a
  // treasure has been earned.
  void _onHeart() => RewardService.instance.refreshQuietly();

  bool _revealing = false;

  // A treasure earned since the member last looked is shown once, and
  // only while the member is on the main screen (never over a story,
  // a call or a live).
  Future<void> _checkReveal() async {
    final RewardState? r = RewardService.instance.state.value;
    if (r == null || r.unseen == 0 || _revealing || !mounted) return;
    if (ModalRoute.of(context)?.isCurrent != true) return;
    final List<RewardItem> fresh = r.unseenItems;
    if (fresh.isEmpty) return;
    _revealing = true;
    await RewardService.instance.markSeen();
    if (!mounted) {
      _revealing = false;
      return;
    }
    await showTreasureReveal(context, fresh);
    _revealing = false;
    await RewardService.instance.refreshQuietly();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) {
      HeartService.instance.refreshQuietly();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    HeartService.instance.state.removeListener(_onHeart);
    RewardService.instance.state.removeListener(_checkReveal);
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<HeartState?>(
      valueListenable: HeartService.instance.state,
      builder: (BuildContext context, HeartState? s, Widget? _) {
        if (s != null && !s.isOpen) return const SizedBox.shrink();
        final bool unlit = s != null && !s.lit;
        final int streak = s?.streak ?? 0;
        return Semantics(
          button: true,
          label: 'Your Golden Heart',
          child: InkResponse(
            radius: 26,
            onTap: () => showHeartSheet(context),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (BuildContext _, Widget? child) => Transform.scale(
                      scale: unlit ? 1 + 0.09 * _pulse.value : 1,
                      child: child,
                    ),
                    child: HeartPaint(
                      size: 36,
                      compact: true,
                      fill: s?.fill ?? 0,
                      tier: s?.tierIdx ?? 0,
                    ),
                  ),
                  if (streak > 0)
                    Positioned(
                      right: 2,
                      bottom: 5,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 17),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: <Color>[GoldTones.shine, GoldTones.mid],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: IvoryColors.burgundy),
                        ),
                        child: Text(
                          '$streak',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: IvoryColors.burgundy,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// END OF FILE - lib/widgets/heart_button.dart
