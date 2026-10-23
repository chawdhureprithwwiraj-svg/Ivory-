import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/reward_models.dart';
import '../screens/treasures_sheet.dart';
import '../services/reward_service.dart';
import '../theme/ivory_theme.dart';
import 'profile_crest_card.dart';
import 'sound_bank.dart';

/// ============================================================
/// IVORY - THE TREASURES DOORWAY (CC.193)
///
/// The row on the Profile that leads into the treasure room. It
/// no longer repeats the key that waits inside: it carries its
/// own emblem - THE RING OF KEYS - three cast gold keys hanging
/// on a gold ring over a velvet roundel with a rope rim. The bunch
/// sways like keys carried, a glint walks the rim, and the roundel
/// breathes a warm glow. While the rewards load, the row already
/// stands at its full height with a quiet roundel, so the scroll
/// can never jump.
/// ============================================================
class ProfileTreasuresCard extends StatefulWidget {
  const ProfileTreasuresCard({super.key});

  @override
  State<ProfileTreasuresCard> createState() => _ProfileTreasuresCardState();
}

class _ProfileTreasuresCardState extends State<ProfileTreasuresCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sway = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 6400))
    ..repeat();

  @override
  void initState() {
    super.initState();
    RewardService.instance.refreshQuietly();
  }

  @override
  void dispose() {
    _sway.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The Showcase sits above the treasures; it hides itself if the
    // Ladder is closed.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[const ProfileCrestCard(), _shelf()],
    );
  }

  Widget _shelf() {
    return ValueListenableBuilder<RewardState?>(
      valueListenable: RewardService.instance.state,
      builder: (BuildContext _, RewardState? r, Widget? __) {
        if (r == null) return _skeleton();
        if (r.total == 0) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              SoundBank.instance.play('treasure');
              showTreasuresSheet(context);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: IvoryTheme.card(radius: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Expanded(
                        child: IvoryEyebrow(
                          'Your treasures',
                          icon: Icons.auto_awesome,
                        ),
                      ),
                      Text(
                        '${r.earned.length} of ${r.total}',
                        style: const TextStyle(
                          color: IvoryColors.plum,
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: IvoryColors.plum),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      AnimatedBuilder(
                        animation: _sway,
                        builder: (BuildContext _, Widget? __) =>
                            CustomPaint(
                              size: const Size(64, 64),
                              painter: _RingPainter(_sway.value),
                            ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'The Ring of Keys',
                              style: TextStyle(
                                color: IvoryColors.burgundy,
                                fontFamily: IvoryTheme.displayFont,
                                fontWeight: FontWeight.w800,
                                fontSize: 15.5,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Every key you have earned hangs here. '
                              'Tap to walk among your treasures.',
                              style: TextStyle(
                                color: IvoryColors.textSoft,
                                fontSize: 12.5,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// The row at its full height before the rewards arrive, so the
  /// page below never moves.
  Widget _skeleton() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: IvoryTheme.card(radius: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Expanded(
                  child:
                      IvoryEyebrow('Your treasures', icon: Icons.auto_awesome),
                ),
                Text(
                  '...',
                  style: TextStyle(
                      color: IvoryColors.textFaint,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5),
                ),
                const Icon(Icons.chevron_right, color: IvoryColors.plum),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: <Color>[Color(0xFF7A2433), Color(0xFF47101A)],
                    ),
                    border: Border.all(
                        color: const Color(0xFFC9962C), width: 1.4),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'The Ring of Keys',
                        style: TextStyle(
                            color: IvoryColors.textFaint,
                            fontFamily: IvoryTheme.displayFont,
                            fontWeight: FontWeight.w800,
                            fontSize: 15.5),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Counting the keys you have earned...',
                        style: TextStyle(
                            color: IvoryColors.textFaint,
                            fontSize: 12.5,
                            height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The emblem itself: velvet roundel, rope rim, three cast keys on
/// a swaying ring, a glint walking the rim, a breathing glow.
class _RingPainter extends CustomPainter {
  _RingPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width;
    final double c = s / 2;
    final double b = 0.5 + 0.5 * math.sin(t * 2 * math.pi);
    // The breathing glow the roundel lends the card.
    final Rect glow = Rect.fromCircle(center: Offset(c, c), radius: c * 1.25);
    canvas.drawOval(
      glow,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            const Color(0xFFC9962C).withValues(alpha: 0.16 + 0.14 * b),
            const Color(0x00C9962C),
          ],
        ).createShader(glow),
    );
    // Velvet roundel.
    canvas.drawCircle(
      Offset(c, c),
      c - 1,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          colors: <Color>[
            const Color(0xFF8A2A3B),
            const Color(0xFF5C1220),
            const Color(0xFF400D16),
          ],
        ).createShader(Rect.fromCircle(center: Offset(c, c), radius: c - 1)),
    );
    // Rope rim: a gold circle with its twist ticks.
    canvas.drawCircle(
      Offset(c, c),
      c - 2.2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = const Color(0xFFE2B34C),
    );
    for (int i = 0; i < 28; i++) {
      final double a = i * 2 * math.pi / 28 + t * 0.6;
      final Offset p =
          Offset(c + (c - 2.2) * math.cos(a), c + (c - 2.2) * math.sin(a));
      canvas.drawCircle(p, 0.7, Paint()..color = const Color(0xFFF6DE9C));
    }
    // The bunch of keys sways as if carried.
    canvas.save();
    canvas.translate(c, c + s * 0.02);
    canvas.rotate(0.05 * math.sin(t * 2 * math.pi));
    // The ring they hang on.
    canvas.drawCircle(
      Offset(0, -s * 0.14),
      s * 0.09,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFFF6DE9C),
    );
    const List<double> ang = <double>[-0.42, 0.0, 0.42];
    for (int i = 0; i < 3; i++) {
      canvas.save();
      canvas.translate(0, -s * 0.07);
      canvas.rotate(ang[i]);
      _key(canvas, s * (i == 1 ? 0.46 : 0.40));
      canvas.restore();
    }
    canvas.restore();
    // A glint walking the rim.
    canvas.drawArc(
      Rect.fromCircle(center: Offset(c, c), radius: c - 2.2),
      t * 2 * math.pi,
      0.7,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFFFF6E2).withValues(alpha: 0.75),
    );
  }

  /// One cast gold key: bow, shaft, two teeth.
  void _key(Canvas canvas, double len) {
    final Paint gold = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          const Color(0xFFFFF0BE),
          const Color(0xFFE2B34C),
          const Color(0xFFB9861F),
        ],
      ).createShader(Rect.fromLTRB(-5, 0, 6, len));
    canvas.drawCircle(
      Offset(0, 4.5),
      4.2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..shader = gold.shader,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTRB(-1.5, 8, 1.5, len), const Radius.circular(1.5)),
      gold,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTRB(1.5, len - 7, 5.5, len - 4.6), const Radius.circular(1)),
      gold,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTRB(1.5, len - 3.4, 4.2, len - 1.2), const Radius.circular(1)),
      gold,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.t != t;
}

// END OF FILE - lib/widgets/profile_treasures_card.dart
