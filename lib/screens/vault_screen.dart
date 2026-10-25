import 'dart:async';

import 'package:flutter/material.dart';

import '../core/ivory_errors.dart';
import '../models/vault_models.dart';
import '../services/ten_day_vault_service.dart';
import '../theme/ivory_theme.dart';
import '../widgets/gold_burst.dart';
import '../widgets/gold_button.dart';
import '../widgets/gold_fx.dart';
import '../widgets/gold_fx3d.dart';
import '../widgets/gold_sound.dart';
import '../widgets/lane_law.dart';
import '../widgets/sound_bank.dart';
import '../widgets/vault_sky.dart';
import 'golden_result.dart';
import 'vault_ceremony.dart';
import 'vault_question_view.dart';
import 'vault_review.dart';
import 'vault_scenes.dart';

/// ============================================================
/// IVORY - THE TEN-DAY VAULT: THE SCREEN
///
/// Rules (the database enforces all of them; this screen only
/// shows them): one question a day, a real clock, every answer
/// sealed, and nothing revealed until the last key turns.
///
/// Flow: intro (first day only) -> day title -> the question ->
/// key turned -> (days later) ... -> the opening of the vault ->
/// result. Pops with 'spend' when the member taps SPEND MY GOLD.
/// ============================================================

enum _Stage {
  loading,
  intro,
  title,
  opening,
  question,
  sealed,
  ceremony,
  result,
  error,
}

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  final TenDayVaultService _svc = TenDayVaultService.instance;
  _Stage _stage = _Stage.loading;
  VaultState? _vs;
  VaultQuestion? _q;
  VaultResult? _res;
  bool _fresh = false;
  bool _newRun = false;
  String _err = '';

  @override
  void initState() {
    super.initState();
    GoldSound.instance.load();
    // CC.214: the ten-day vault has a voice at last - the recording that
    // slept in assets/premium. It obeys this screen's own sound toggle.
    if (GoldSound.instance.on.value) {
      unawaited(SoundBank.instance.play('vault', volume: 0.85));
    }
    // CC.215: the vault's close button owns the top lane while open.
    LaneLaw.topBusy.value = true;
    _boot();
  }

  @override
  void dispose() {
    LaneLaw.topBusy.value = false;
    SoundBank.instance.stop('vault');
    GoldSound.instance.release();
    super.dispose();
  }

  void _fail(Object e) {
    if (!mounted) return;
    setState(() {
      _err = houseMessage(e);
      _stage = _Stage.error;
    });
  }

  Future<void> _boot() async {
    try {
      final VaultState vs = await _svc.homeState();
      if (!mounted) return;
      _vs = vs;
      switch (vs.phase) {
        case VaultPhase.ready:
          setState(() => _stage = _Stage.intro);
        case VaultPhase.open:
          if (vs.inProgress) {
            await _openKey();
          } else {
            setState(() {
              _newRun = false;
              _stage = _Stage.title;
            });
          }
        case VaultPhase.sealed:
          setState(() {
            _fresh = false;
            _stage = _Stage.sealed;
          });
        case VaultPhase.ceremony:
          await _loadResult();
        default:
          setState(() {
            _err = switch (vs.phase) {
              VaultPhase.resting =>
                'Your vault has opened. A new one begins when the wait is '
                    'over, and the Home card will tell you.',
              VaultPhase.locked =>
                'The Ten-Day Vault is closed to you while your membership is '
                    'running. The Home card will tell you when it opens again.',
              _ => 'The Ten-Day Vault is not open for you right now.',
            };
            _stage = _Stage.error;
          });
      }
    } catch (e) {
      _fail(e);
    }
  }

  void _begin() {
    setState(() {
      _newRun = true;
      _stage = _Stage.title;
    });
  }

  /// Called when the day title has finished: only now does the clock start.
  Future<void> _afterTitle() async {
    if (!mounted) return;
    setState(() => _stage = _Stage.opening);
    try {
      final VaultQuestion q = _newRun
          ? await _svc.start()
          : await _svc.openKey();
      if (!mounted) return;
      setState(() {
        _q = q;
        _stage = _Stage.question;
      });
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> _openKey() async {
    final VaultQuestion q = await _svc.openKey();
    if (!mounted) return;
    setState(() {
      _q = q;
      _stage = _Stage.question;
    });
  }

  Future<VaultSealed> _submit(int choice) {
    final VaultQuestion q = _q!;
    return _svc.answer(
      runId: q.runId,
      questionId: q.questionId,
      choice: choice,
    );
  }

  Future<void> _sealedIn(VaultSealed s) async {
    if (!mounted) return;
    try {
      if (s.finished) {
        await _loadResult();
        return;
      }
      final VaultState vs = await _svc.homeState();
      if (!mounted) return;
      setState(() {
        _vs = vs;
        _fresh = true;
        _stage = _Stage.sealed;
      });
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> _loadResult() async {
    final VaultResult r = await _svc.result();
    if (!mounted) return;
    setState(() {
      _res = r;
      _stage = _Stage.ceremony;
    });
  }

  Future<void> _ceremonyDone() async {
    final VaultResult? r = _res;
    if (r == null || !mounted) return;
    _svc.markSeen(r.runId);
    setState(() => _stage = _Stage.result);
  }

  bool get _locked => _stage == _Stage.opening || _stage == _Stage.question;

  Future<void> _confirmLeave() async {
    final bool rehearsal = _vs?.rehearsal ?? false;
    final bool? leave = await showDialog<bool>(
      context: context,
      builder: (BuildContext c) => AlertDialog(
        title: const Text('Leave today\u2019s key?'),
        content: Text(
          rehearsal
              ? 'This is an admin rehearsal. Leaving costs nothing.'
              : 'The clock keeps running. If time runs out, today\u2019s '
                    'answer counts as missed, but your vault goes on. '
                    'You can come back from the Home card until then.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('STAY'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('LEAVE'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.of(context).pop();
  }

  Widget _reviewButton() => GoldButton(
    label: 'SEE MY ANSWERS',
    icon: Icons.menu_book_rounded,
    ghost: true,
    onTap: () {
      final VaultResult? r = _res;
      if (r == null) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext _) => VaultReviewScreen(result: r),
        ),
      );
    },
  );

  Widget _body() {
    switch (_stage) {
      case _Stage.loading:
      case _Stage.opening:
        return const Center(
          child: CircularProgressIndicator(color: IvoryColors.burgundy),
        );
      case _Stage.intro:
        return VaultIntro(
          s: _vs!,
          busy: false,
          onStart: _begin,
          onClose: () => Navigator.of(context).pop(),
        );
      case _Stage.title:
        final VaultState vs = _vs!;
        return VaultDayTitle(
          key: ValueKey<bool>(_newRun),
          day: _newRun ? 1 : vs.dayNo,
          days: vs.days,
          onDone: _afterTitle,
        );
      case _Stage.question:
        final VaultQuestion q = _q!;
        return VaultQuestionView(
          key: ValueKey<int>(q.questionId),
          q: q,
          totalSeconds: _vs?.questionSeconds ?? 30,
          submit: _submit,
          onSealed: _sealedIn,
        );
      case _Stage.sealed:
        return VaultSealedScene(
          s: _vs!,
          animate: _fresh,
          onClose: () => Navigator.of(context).pop(),
        );
      case _Stage.ceremony:
        return VaultCeremony(result: _res!, onDone: _ceremonyDone);
      case _Stage.result:
        return GoldenResult(
          summary: _res!.toSummary(),
          creditHours: _vs?.creditHours ?? 6,
          shareName: 'The Ten-Day Vault',
          waitLine:
              'No gold this time. A new vault begins when the wait is over, '
              'and we will tell you.',
          extra: _reviewButton(),
          onSpend: () => Navigator.of(context).pop('spend'),
          onClose: () => Navigator.of(context).pop(),
        );
      case _Stage.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const GoldCoin(size: 64),
                const SizedBox(height: 18),
                Text(
                  _err,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: vaultInk,
                    fontFamily: IvoryTheme.displayFont,
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 22),
                VaultWell(
                  radius: 34,
                  child: GoldButton(
                    label: 'BACK TO HOME',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    // The sunrise by day; the burgundy night for the opening of the vault
    // and the result, which are built for it.
    final bool dark = _stage == _Stage.ceremony || _stage == _Stage.result;
    final Color ink = dark ? GoldTones.light : IvoryColors.burgundy;
    return PopScope(
      canPop: !_locked,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        backgroundColor: dark ? IvoryColors.burgundy : const Color(0xFFFFB347),
        body: VaultSky(
          dark: dark,
          child: SafeArea(
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        IconButton(
                          icon: Icon(Icons.close, color: ink),
                          onPressed: _locked
                              ? _confirmLeave
                              : () => Navigator.of(context).pop(),
                        ),
                        const Spacer(),
                        ValueListenableBuilder<bool>(
                          valueListenable: GoldSound.instance.on,
                          builder: (BuildContext context, bool on, Widget? _) =>
                              IconButton(
                                tooltip: on ? 'Sound on' : 'Sound off',
                                icon: Icon(
                                  on
                                      ? Icons.volume_up_rounded
                                      : Icons.volume_off_rounded,
                                  color: ink,
                                ),
                                onPressed: () => GoldSound.instance.setOn(!on),
                              ),
                        ),
                      ],
                    ),
                    Expanded(child: _body()),
                  ],
                ),
              ),
        ),
      ),
    );
  }
}

// END OF FILE - lib/screens/vault_screen.dart
