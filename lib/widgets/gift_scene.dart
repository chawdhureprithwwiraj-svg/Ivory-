import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';
import 'gift_gold.dart';
import 'gift_scenes_a.dart';
import 'gift_scenes_b.dart';
import 'gift_scenes_c.dart';

/// ============================================================
/// IVORY - PLAYING A POST GIFT
///
/// One fifteen-second clock, one painter per gift, and the gold
/// layer drawn over the top of whichever scene is running.
///
/// WHY A FALLBACK EXISTS, AND WHY IT IS NOT A STUB
///
/// The nine scenes are being drawn in batches of three so that
/// each batch can be judged on a real phone before the next is
/// started. A gift whose scene has not been drawn yet still has
/// to look finished today - so it shows its emblem on the same
/// warm tile, with the same gold dust lifting through it and the
/// same burst on its own beat. Nothing looks broken, nothing
/// says "coming soon", and the member never learns that some
/// gifts are further along than others.
///
/// When a batch lands, its gifts simply stop using the fallback.
/// ============================================================

typedef GiftPainter = void Function(Canvas canvas, Size size, double t);

/// ALL NINE ARE NOW DRAWN. The fallback below stays anyway -
/// if she ever renames a gift or adds a tenth, that gift keeps
/// its tile, its dust and its burst instead of appearing
/// broken. A set this size will be edited one day.
const Map<String, GiftPainter> _drawn = <String, GiftPainter>{
  'A Second Look': paintSecondLook,
  'Again, Please': paintAgainPlease,
  'Goosebumps': paintGoosebumps,
  'Carried All Day': paintCarriedAllDay,
  'A Round of Applause': paintApplause,
  'Up All Night': paintUpAllNight,
  'Front Row': paintFrontRow,
  'Crown of the Day': paintCrownOfTheDay,
  'One I Will Not Forget': paintNotForget,
};

/// True when this gift has its own drawn scene.
bool giftIsDrawn(String name) => _drawn.containsKey(name);

class GiftScene extends StatefulWidget {
  const GiftScene({
    super.key,
    required this.name,
    required this.emoji,
    this.size = 46,
  });

  final String name;
  final String emoji;
  final double size;

  @override
  State<GiftScene> createState() => _GiftSceneState();
}

class _GiftSceneState extends State<GiftScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    // Fifteen seconds for every gift in the set, with no
    // exceptions. One duration is what makes nine separate
    // scenes feel like one collection.
    duration: const Duration(seconds: 15),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final GoldBeat beat =
        kGoldBeats[widget.name] ?? const GoldBeat(0.5, 1.0);
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.size * 0.26),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[IvoryColors.cream, IvoryColors.surfaceWarm],
            ),
            border: Border.all(
              color: IvoryColors.amber.withValues(alpha: 0.7),
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              if (!giftIsDrawn(widget.name))
                Center(
                  child: Text(
                    widget.emoji,
                    style: TextStyle(fontSize: widget.size * 0.46),
                  ),
                ),
              AnimatedBuilder(
                animation: _c,
                builder: (BuildContext context, Widget? child) =>
                    CustomPaint(
                  painter: _ScenePainter(
                    painter: _drawn[widget.name],
                    beat: beat,
                    t: _c.value,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScenePainter extends CustomPainter {
  const _ScenePainter({
    required this.painter,
    required this.beat,
    required this.t,
  });

  final GiftPainter? painter;
  final GoldBeat beat;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final GiftPainter? p = painter;
    if (p != null) {
      canvas.save();
      canvas.clipRect(Offset.zero & size);
      p(canvas, size, t);
      canvas.restore();
    }
    // The gold goes over everything, drawn or not.
    paintGoldLayer(canvas, size, t, beat);
  }

  @override
  bool shouldRepaint(_ScenePainter old) => old.t != t;
}

// END OF FILE - lib/widgets/gift_scene.dart
