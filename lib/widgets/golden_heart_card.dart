import 'dart:async';

import 'package:flutter/material.dart';

import '../models/heart_models.dart';
import '../screens/heart_sheet.dart';
import '../services/heart_service.dart';
import '../theme/ivory_theme.dart';
import 'gold_fx.dart';
import 'heart_sound.dart';
import 'orbit_heart.dart';

/// ============================================================
/// IVORY - THE GOLDEN HEART ON HOME
///
/// A crystal heart of gold with a ring of fine golden dust circling
/// it like the rings of Saturn. It brightens and grows more crystal
/// as the member's glow grows. A soft fall of golden dust comes every
/// ten seconds, with one very pure, very soft sound (the member can
/// switch the sound off on the Profile Showcase card). Touch it to
/// open the Golden Heart. If the house closes the heart, this card
/// simply is not there.
/// ============================================================
class GoldenHeartCard extends StatefulWidget {
  const GoldenHeartCard({super.key});

  @override
  State<GoldenHeartCard> createState() => _GoldenHeartCardState();
}

class _GoldenHeartCardState extends State<GoldenHeartCard> {
  Timer? _rain;

  @override
  void initState() {
    super.initState();
    HeartService.instance.refreshQuietly();
    HeartSound.instance.load();
    // The ring's dust falls in a ten-second rhythm; the chime follows it.
    _rain = Timer.periodic(const Duration(seconds: 10), (Timer _) => _chime());
  }

  @override
  void dispose() {
    _rain?.cancel();
    super.dispose();
  }

  // Only while this card is really on the screen the member is looking at.
  void _chime() {
    if (!mounted) return;
    if (ModalRoute.of(context)?.isCurrent != true) return;
    // A tab that is not showing has its tickers switched off.
    if (!TickerMode.of(context)) return;
    final RenderObject? ro = context.findRenderObject();
    if (ro is! RenderBox || !ro.attached || !ro.hasSize) return;
    final double top = ro.localToGlobal(Offset.zero).dy;
    final double screen = MediaQuery.of(context).size.height;
    if (top + ro.size.height * 0.5 < 0 || top + ro.size.height * 0.5 > screen) {
      return;
    }
    HeartSound.instance.play('rain', volume: 0.45);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<HeartState?>(
      valueListenable: HeartService.instance.state,
      builder: (BuildContext context, HeartState? s, Widget? _) {
        if (s != null && !s.isOpen) return const SizedBox.shrink();
        final int streak = s?.streak ?? 0;
        final bool lit = s?.lit ?? false;
        final String status = s == null
            ? 'Waking your heart...'
            : (lit
                  ? "Today's heart is lit."
                  : '${s.points} of ${s.litPoints} to light today\'s heart.');
        return GestureDetector(
          onTap: () => showHeartSheet(context),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color(0xFF7A1F33),
                  Color(0xFF5C1222),
                  Color(0xFF4A0E17),
                ],
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: IvoryColors.hairlineStrong, width: 1.2),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: IvoryColors.burgundy.withValues(alpha: 0.28),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const SizedBox(height: 14),
                  const Text(
                    'YOUR GOLDEN HEART',
                    style: TextStyle(
                      color: IvoryColors.cream,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                    ),
                  ),
                  OrbitHeart(
                    fill: s?.fill ?? 0,
                    tier: s?.tierIdx ?? 0,
                    lit: lit,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      GoldShimmerText(
                        '$streak',
                        style: const TextStyle(
                          fontFamily: IvoryTheme.displayFont,
                          fontSize: 44,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                        ),
                        extrude: 2,
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          streak == 1 ? 'DAY OF GLOW' : 'DAYS OF GLOW',
                          style: const TextStyle(
                            color: IvoryColors.cream,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  GoldShimmerText(
                    streak > 0
                        ? (s?.tierName ?? '').toUpperCase()
                        : 'NO GLOW YET',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: IvoryTheme.displayFont,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Text(
                      status,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: IvoryColors.cream,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// END OF FILE - lib/widgets/golden_heart_card.dart
