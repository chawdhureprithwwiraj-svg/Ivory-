import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/ivory_errors.dart';
import '../models/bell_models.dart';
import '../models/heart_models.dart';
import '../services/bells_service.dart';
import '../services/heart_service.dart';
import '../widgets/bell_paint.dart';
import '../widgets/bell_sound.dart';
import '../widgets/bells_stage.dart';
import '../widgets/ladder_ceremony.dart';
import 'bells_panels.dart';
import 'bells_pledge.dart';
import 'bells_remind.dart';
import 'bells_sets_sheet.dart';

/// ============================================================
/// IVORY - RING MY DOORBELL (the daily check-in)
///
/// Four bells a day. Dawn rings when you greet your heart, Noon when
/// you read a story, Dusk when you join in, Night when you open
/// Ivory's closing line. Each one adds to the Golden Heart; all four
/// make a Full Day. The database decides when a bell opens and what
/// has rung; this screen only shows it, and plays each new ring with
/// a swing, a chime and ribbons of light.
/// ============================================================
class BellsScreen extends StatefulWidget {
  const BellsScreen({super.key, required this.onOpenTab});

  final void Function(String tab) onOpenTab;

  @override
  State<BellsScreen> createState() => _BellsScreenState();
}

class _BellsScreenState extends State<BellsScreen> {
  final GlobalKey<BellsStageState> _stage = GlobalKey<BellsStageState>();
  final Set<String> _shown = <String>{};
  bool _fullShown = false;
  String _setsShown = '';
  bool _resultShown = false;
  bool _playing = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    BellsService.instance.start();
    BellsService.instance.state.addListener(_onState);
    BellSound.instance.load();
    HeartService.instance.refreshQuietly();
    _first();
  }

  @override
  void dispose() {
    BellsService.instance.state.removeListener(_onState);
    super.dispose();
  }

  Future<void> _first() async {
    try {
      await BellsService.instance.refresh();
      if (mounted) setState(() => _error = null);
    } catch (e) {
      if (mounted) setState(() => _error = houseMessage(e));
    }
    unawaited(_play());
  }

  void _onState() {
    if (!mounted) return;
    setState(() {});
    unawaited(_play());
  }

  /// Shows what has newly rung, one bell at a time.
  Future<void> _play() async {
    if (_playing) return;
    _playing = true;
    try {
      final BellsState? s = BellsService.instance.state.value;
      if (s == null || !mounted) return;
      for (final BellItem b in s.bells) {
        if (b.rung && !b.unseen) _shown.add(b.key);
      }
      if (s.full && !s.fullUnseen) _fullShown = true;
      if (mounted) setState(() {});
      final List<BellItem> fresh = s.bells
          .where((BellItem b) => b.rung && b.unseen && !_shown.contains(b.key))
          .toList();
      for (final BellItem b in fresh) {
        await Future<void>.delayed(const Duration(milliseconds: 650));
        if (!mounted) return;
        _stage.currentState?.ringBell(b.key);
        setState(() => _shown.add(b.key));
        await Future<void>.delayed(const Duration(milliseconds: 1300));
      }
      if (s.fullUnseen && !_fullShown) {
        await Future<void>.delayed(const Duration(milliseconds: 900));
        if (!mounted) return;
        _stage.currentState?.playFull();
        setState(() => _fullShown = true);
        await Future<void>.delayed(const Duration(milliseconds: 2500));
        if (!mounted) return;
        // The star for this Full Day (its number is the lifetime count).
        await showFullDayStar(context, s.fullDays);
        if (!mounted) return;
      }
      // A set earned today, then how a pledge ended.
      final String setsKey = s.newSets.join(',');
      if (s.newSets.isNotEmpty && setsKey != _setsShown && mounted) {
        _setsShown = setsKey;
        await Future<void>.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        final bool wear = await showSetUnlock(context, s);
        if (wear && mounted) {
          try {
            await BellsService.instance.wear(s.newSets.last);
          } catch (e) {
            if (mounted) _say(houseMessage(e));
          }
        }
      }
      final PledgeResult? pr = s.pledgeResult;
      if (pr != null && !_resultShown && mounted) {
        _resultShown = true;
        await Future<void>.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        await showPledgeResult(context, pr);
      }
      if (fresh.isNotEmpty ||
          s.fullUnseen ||
          s.newSets.isNotEmpty ||
          pr != null) {
        await BellsService.instance.markSeen();
      }
    } finally {
      _playing = false;
    }
  }

  void _say(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _orb(String key) async {
    if (_busy) return;
    final BellsState? s = BellsService.instance.state.value;
    final BellItem? it = s?.byKey(key);
    BellSound.instance.play('tap');
    switch (key) {
      case 'dawn':
        final HeartState? h = HeartService.instance.state.value;
        final bool greeted = h?.action('greet')?.complete ?? false;
        if (!greeted) {
          setState(() => _busy = true);
          try {
            await HeartService.instance.greet();
            await BellsService.instance.refresh();
          } catch (e) {
            if (mounted) _say(houseMessage(e));
          }
          if (mounted) setState(() => _busy = false);
        } else if (it != null && !it.isOpen) {
          _say('Dawn rings at ${it.timeLabel}. Your greeting is remembered.');
        }
        break;
      case 'noon':
        if (it != null && it.done && !it.isOpen) {
          _say('Noon rings at ${it.timeLabel}. Your reading is remembered.');
        } else {
          _goTo('home');
        }
        break;
      case 'dusk':
        if (it != null && it.done && !it.isOpen) {
          _say('Dusk rings at ${it.timeLabel}. What you did is remembered.');
        } else {
          await _duskSheet();
        }
        break;
      case 'night':
        if (it == null || !it.isOpen) {
          _say(
            "Ivory's line for tonight opens at ${it?.timeLabel ?? 'night'}.",
          );
          return;
        }
        setState(() => _busy = true);
        try {
          await BellsService.instance.openLine();
          BellSound.instance.play('line');
        } catch (e) {
          if (mounted) _say(houseMessage(e));
        }
        if (mounted) setState(() => _busy = false);
        break;
    }
  }

  Future<void> _pickPledge(int n) async {
    if (_busy) return;
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext c) => AlertDialog(
        backgroundColor: const Color(0xFF2A0E72),
        title: Text(
          'Pledge $n Full Days?',
          style: const TextStyle(color: Colors.white),
        ),
        content: const Text(
          'You promise yourself to ring all the bells every day, in a row. '
          'It is free and nothing is at stake. A heart mend carries a '
          'missed day. If it ends, you can begin another at once.',
          style: TextStyle(color: Color(0xFFE4DAFF), height: 1.45),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text(
              'NOT NOW',
              style: TextStyle(color: Color(0xFFCFC2F5)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text(
              'I PLEDGE',
              style: TextStyle(
                color: Color(0xFF4DF0A8),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await BellsService.instance.pledge(n);
      BellSound.instance.play('ring2');
    } catch (e) {
      if (mounted) _say(houseMessage(e));
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _releasePledge() async {
    if (_busy) return;
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext c) => AlertDialog(
        backgroundColor: const Color(0xFF2A0E72),
        title: const Text(
          'Let go of this pledge?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'It ends quietly, with no message and nothing lost. Pledges you '
          'have kept stay counted, and you can begin another whenever you '
          'like.',
          style: TextStyle(color: Color(0xFFE4DAFF), height: 1.45),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text(
              'KEEP IT',
              style: TextStyle(
                color: Color(0xFF4DF0A8),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text(
              'LET GO',
              style: TextStyle(color: Color(0xFFCFC2F5)),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await BellsService.instance.releasePledge();
    } catch (e) {
      if (mounted) _say(houseMessage(e));
    }
    if (mounted) setState(() => _busy = false);
  }

  void _goTo(String tab) {
    Navigator.of(context).pop();
    widget.onOpenTab(tab);
  }

  Future<void> _duskSheet() async {
    final String? pick = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF2A0E72),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext c) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'JOIN IN TO RING DUSK',
              style: TextStyle(
                color: Color(0xFFBFF4FF),
                fontWeight: FontWeight.w800,
                letterSpacing: 2.4,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Turn a Ten-Day Vault key, vote in a poll, join a live, or '
              'read a second story. A wish or a gift counts too.',
              style: TextStyle(color: Color(0xFFE4DAFF), height: 1.45),
            ),
            const SizedBox(height: 16),
            _sheetButton(c, 'Go to Home', 'home', BellTones.dusk),
            const SizedBox(height: 10),
            _sheetButton(c, 'Make a wish', 'wish', BellTones.dawn),
          ],
        ),
      ),
    );
    if (pick != null && mounted) _goTo(pick);
  }

  Widget _sheetButton(BuildContext c, String t, String tab, Color col) {
    return GestureDetector(
      onTap: () => Navigator.of(c).pop(tab),
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: LinearGradient(
            colors: <Color>[col, BellTones.mix(col, BellTones.amethyst, 0.5)],
          ),
        ),
        child: Text(
          t,
          style: const TextStyle(
            color: BellTones.deep,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final BellsState? s = BellsService.instance.state.value;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
      backgroundColor: const Color(0xFF1A0A5C),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFF1A0A5C),
              Color(0xFF2A0E72),
              Color(0xFF17114F),
            ],
            stops: <double>[0, 0.45, 1],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 36),
            children: <Widget>[
              _header(),
              if (_error != null) _errorBox(),
              ValueListenableBuilder<HeartState?>(
                valueListenable: HeartService.instance.state,
                builder: (BuildContext _, HeartState? h, Widget? __) =>
                    BellsStage(
                      key: const ValueKey<String>('bells-stage'),
                      state: s,
                      heart: h,
                      shown: _shown,
                      fullShown: _fullShown,
                      onOrb: _orb,
                    ),
              ),
              if (s != null) ...<Widget>[
                BellsPledgeCard(
                  state: s,
                  busy: _busy,
                  onPick: _pickPledge,
                  onRelease: _releasePledge,
                ),
                BellsSetsRow(state: s, onTap: () => showBellSets(context)),
              ],
              if (s?.line != null) BellsLineCard(line: s!.line!),
              BellsHowBox(state: s),
              if (s != null) BellsCountsBox(state: s),
              const BellsSoundRow(),
              const BellsRemindRow(),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _header() {
    return SizedBox(
      height: 52,
      child: Row(
        children: <Widget>[
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
          ),
          // (The page title is already drawn on the arch below.)
        ],
      ),
    );
  }

  Widget _errorBox() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(color: Color(0xFFFFD0DC)),
            ),
          ),
          TextButton(
            onPressed: _first,
            child: const Text(
              'Try again',
              style: TextStyle(color: Color(0xFFBFF4FF)),
            ),
          ),
        ],
      ),
    );
  }
}

// END OF FILE - lib/screens/bells_screen.dart
