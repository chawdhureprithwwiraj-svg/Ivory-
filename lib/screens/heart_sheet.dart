import 'package:flutter/material.dart';

import '../core/ivory_errors.dart';
import '../models/heart_models.dart';
import '../services/heart_service.dart';
import '../theme/ivory_theme.dart';
import '../widgets/gold_burst.dart';
import '../widgets/gold_button.dart';
import '../widgets/gold_fx.dart';
import '../widgets/gold_fx3d.dart';
import '../widgets/gold_light.dart';
import '../widgets/gold_sound.dart';
import '../widgets/lane_law.dart';
import '../widgets/flame_heart.dart';
import '../widgets/gif_flame_heart.dart';
import '../widgets/heart_score.dart';
import '../widgets/heart_sound.dart';
import 'heart_parts.dart';
import 'treasures_sheet.dart';

/// Opens the member's Golden Heart.
Future<void> showHeartSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: IvoryColors.burgundy.withValues(alpha: 0.34),
    builder: (BuildContext _) => const HeartSheet(),
  );
}

/// ============================================================
/// IVORY - YOUR GOLDEN HEART
///
/// A large glass heart that fills with gold as the day's points
/// arrive, the glow (lit days in a row) and what it has earned, what
/// today can still add, the mends that protect the glow, and the
/// last seven days. It can never be bought: it fills only from what
/// a member does. All numbers come from the database.
/// ============================================================
class HeartSheet extends StatefulWidget {
  const HeartSheet({super.key});

  @override
  State<HeartSheet> createState() => _HeartSheetState();
}

class _HeartSheetState extends State<HeartSheet>
    with WidgetsBindingObserver {
  HeartState? _s = HeartService.instance.state.value;
  bool _busy = false;
  String? _err;
  int _celebrate = 0;

  @override
  void initState() {
    super.initState();
    GoldSound.instance.load();
    WidgetsBinding.instance.addObserver(this);
    // CC.215: the ribbon lane borrows the top of the screen while a
    // ribbon crosses. While the heart is open the lane waits, so the
    // back arrow at the top-left is always the thing your thumb meets.
    LaneLaw.topBusy.value = true;
    // The owner's two recordings: the rush and heartbeat once, then the
    // heartbeat for as long as the member stays here. If the recordings
    // are not in the app, the older soft opening sound is used.
    bool openSounded = false;
    void soundTheOpen() {
      if (openSounded) return;
      openSounded = true;
      HeartSound.instance.load().then((_) {
        if (mounted) HeartSound.instance.play('open', volume: 1.0);
      });
    }

    HeartScore.instance.start().then((bool played) {
      if (played || !mounted) return;
      soundTheOpen();
    });
    // CC.241: if the owner's two recordings hesitate on the wire (a
    // slow first fetch in the browser), the house's own opening sound
    // speaks at four hundred milliseconds, so no member ever watches
    // a silent heart.
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      if (mounted) soundTheOpen();
    });
    _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      HeartScore.instance.resume();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      HeartScore.instance.pause();
    }
  }

  @override
  void dispose() {
    LaneLaw.topBusy.value = false;
    WidgetsBinding.instance.removeObserver(this);
    HeartScore.instance.stop();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final HeartState s = await HeartService.instance.refresh();
      if (!mounted) return;
      setState(() {
        _s = s;
        _err = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _err = houseMessage(e));
    }
  }

  Future<void> _greet() async {
    setState(() => _busy = true);
    try {
      final HeartState s = await HeartService.instance.greet();
      if (!mounted) return;
      if (s.justLit) {
        if (!HeartSound.instance.play('kindle', volume: 0.95)) {
          GoldSound.instance.big('golden');
        }
      } else {
        GoldSound.instance.big('correct');
      }
      setState(() {
        _s = s;
        _busy = false;
        _err = null;
        if (s.justLit) _celebrate++;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _err = houseMessage(e);
      });
    }
  }

  String _clock(DateTime? t) {
    if (t == null) return 'the next morning';
    final int h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final String m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.hour < 12 ? 'AM' : 'PM'}';
  }

  @override
  Widget build(BuildContext context) {
    final HeartState? s = _s;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.94,
      ),
      decoration: BoxDecoration(
        gradient: IvoryColors.pageGradient,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: IvoryColors.hairlineStrong),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(height: 10),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: IvoryColors.hairlineStrong,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Flexible(
              child: s == null
                  ? _waiting()
                  : !s.isOpen
                  ? _closed()
                  : _body(s),
            ),
          ],
        ),
      ),
    );
  }

  Widget _waiting() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 60),
      child: _err == null
          ? const Center(
              child: CircularProgressIndicator(color: IvoryColors.burgundy),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  _err!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: IvoryColors.burgundy),
                ),
                const SizedBox(height: 16),
                GoldButton(label: 'TRY AGAIN', onTap: _load),
              ],
            ),
    );
  }

  Widget _closed() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 60, 24, 60),
      child: Text(
        'The Golden Heart is resting for now.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: IvoryColors.burgundy,
          fontFamily: IvoryTheme.displayFont,
          fontSize: 20,
        ),
      ),
    );
  }

  Widget _stage(HeartState s) {
    final bool began = s.streak > 0;
    return GoldTilt(
      radius: 26,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 18),
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
        ),
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            // Sparkles drift around the heart only, never across the words.
            const Positioned.fill(
              child: FractionallySizedBox(
                alignment: Alignment.topCenter,
                heightFactor: 0.72,
                child: SparkleField(count: 14, seed: 3),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    // CC.239: the painted heart holds the stage from
                    // the first frame; the gif fades in over it once
                    // decoded. No more empty burgundy room.
                    FlameHeart(
                      fill: s.fill,
                      tier: s.tierIdx,
                      lit: s.lit,
                      celebrate: _celebrate,
                      height: 420,
                    ),
                    GifFlameHeart(
                      fill: s.fill,
                      tier: s.tierIdx,
                      lit: s.lit,
                      celebrate: _celebrate,
                      height: 420,
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    GoldShimmerText(
                      '${s.streak}',
                      style: const TextStyle(
                        fontFamily: IvoryTheme.displayFont,
                        fontSize: 50,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                      ),
                      extrude: 2,
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Text(
                        s.streak == 1 ? 'DAY OF GLOW' : 'DAYS OF GLOW',
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
                const SizedBox(height: 6),
                GoldShimmerText(
                  began ? (s.tierName ?? '').toUpperCase() : 'NO GLOW YET',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: IvoryTheme.displayFont,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
            if (_celebrate > 0) ...<Widget>[
              Positioned.fill(
                child: IgnorePointer(
                  child: GoldFlash(key: ValueKey<int>(_celebrate)),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: GoldShockwave(
                    key: ValueKey<int>(_celebrate),
                    origin: const Alignment(0, -0.2),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CoinBurst(
                    key: ValueKey<int>(_celebrate),
                    big: true,
                    origin: const Alignment(0, -0.2),
                  ),
                ),
              ),
            ],
            // CC.217: painted LAST so it is hit-tested FIRST. The heart
            // visual above carries its own tap-gesture across the whole
            // top of the sheet; an arrow painted beneath it was swallowed
            // by that gesture every single time - which is why the back
            // arrow never answered, in any build, until now.
            Positioned(
              top: 2,
              left: 2,
              child: IconButton(
                tooltip: 'Back',
                onPressed: () =>
                    Navigator.of(context, rootNavigator: true).pop(),
                icon: const Icon(Icons.arrow_back,
                    color: IvoryColors.cream, size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(HeartState s) {
    final HeartAction? greet = s.action('greet');
    final bool canGreet = greet != null && !greet.complete;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Center(
            child: Text(
              'YOUR GOLDEN HEART',
              style: TextStyle(
                color: IvoryColors.plum,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _stage(s),
          const SizedBox(height: 16),
          if (s.mendedToday)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: IvoryTheme.card(highlighted: true, radius: 14),
              child: Text(
                'A mend carried your glow across '
                '${s.mendedN == 1 ? 'a day you missed' : '${s.mendedN} days you missed'}. '
                'Your glow is safe.',
                style: const TextStyle(
                  color: IvoryColors.burgundy,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
            ),
          Text(
            s.lit
                ? "Today's heart is lit. It rests until ${_clock(s.nextDayAt)} and wakes fresh."
                : '${s.points} of ${s.litPoints} to light today\'s heart.'
                      '${s.atRisk ? ' Your ${s.streak}-day glow is waiting for it.' : ''}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: IvoryColors.burgundy,
              fontFamily: IvoryTheme.displayFont,
              fontSize: 16.5,
              height: 1.4,
            ),
          ),
          if (_err != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                _err!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: IvoryColors.danger, fontSize: 13),
              ),
            ),
          if (canGreet) ...<Widget>[
            const SizedBox(height: 16),
            GoldButton(
              label: 'GREET YOUR HEART  +${greet.points}',
              icon: Icons.favorite,
              busy: _busy,
              onTap: _busy ? null : _greet,
            ),
          ],
          const SizedBox(height: 16),
          HeartTreasuresRow(onTap: () => showTreasuresSheet(context)),
          HeartSection(
            "TODAY'S GOLD",
            Column(
              children: <Widget>[
                for (final HeartAction a in s.actions) HeartActionRow(a),
                Text(
                  'Some of these appear only when there is a live, a poll or a vault key.',
                  style: TextStyle(
                    color: IvoryColors.textFaint,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
            delayMs: 120,
          ),
          HeartSection('THE NEXT GLOW', HeartNext(s), delayMs: 200),
          HeartSection('MENDS', HeartMends(s), delayMs: 280),
          if (s.week.isNotEmpty)
            HeartSection(
              'THE LAST SEVEN DAYS',
              HeartWeek(s.week),
              delayMs: 360,
            ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              'Best glow ${s.bestStreak} ${s.bestStreak == 1 ? 'day' : 'days'}'
              '  \u00B7  ${s.totalLit} lit ${s.totalLit == 1 ? 'day' : 'days'} in all',
              style: TextStyle(color: IvoryColors.textFaint, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

// END OF FILE - lib/screens/heart_sheet.dart
