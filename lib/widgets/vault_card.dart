import 'dart:async';

import 'package:flutter/material.dart';

import '../models/vault_models.dart';
import '../screens/vault_screen.dart';
import '../services/ten_day_vault_service.dart';
import '../theme/ivory_theme.dart';
import 'gold_burst.dart';
import 'gold_button.dart';
import 'gold_fx.dart';
import 'gold_fx3d.dart';
import 'gold_teaser.dart';
import 'vault_keys.dart';

/// ============================================================
/// IVORY - THE TEN-DAY VAULT, ON THE HOME SCREEN
///
/// One card, many faces. The database says which face a member
/// sees (ready, open, sealed, ceremony, resting, locked, closed);
/// this widget only paints it and keeps the countdown honest with
/// the house clock. It never shows a score or a right answer: the
/// database does not send them before the last key is turned.
/// ============================================================
class VaultCard extends StatefulWidget {
  const VaultCard({super.key, this.onOpenTab});

  /// Opens a bottom tab by key (the Home screen passes its own).
  final void Function(String tab)? onOpenTab;

  @override
  State<VaultCard> createState() => _VaultCardState();
}

class _VaultCardState extends State<VaultCard> with WidgetsBindingObserver {
  VaultState? _s;
  bool _failed = false;
  bool _reloading = false;
  DateTime _lastLoad = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _tick = Timer.periodic(const Duration(seconds: 1), (Timer _) => _onTick());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tick?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    if (_reloading) return;
    _reloading = true;
    _lastLoad = DateTime.now();
    try {
      final VaultState s = await TenDayVaultService.instance.homeState();
      if (!mounted) return;
      setState(() {
        _s = s;
        _failed = false;
      });
    } catch (_) {
      if (mounted && _s == null) setState(() => _failed = true);
    } finally {
      _reloading = false;
    }
  }

  void _onTick() {
    final VaultState? s = _s;
    if (!mounted || s == null) return;
    final bool dayWait =
        s.phase == VaultPhase.sealed || s.phase == VaultPhase.open;
    final bool runWait = s.phase == VaultPhase.resting;
    final bool stale =
        DateTime.now().difference(_lastLoad) > const Duration(seconds: 6);
    if (stale &&
        ((dayWait && s.untilNextDay <= Duration.zero) ||
            (runWait && s.untilNextRun <= Duration.zero))) {
      _load();
    }
    if (dayWait || runWait) setState(() {});
  }

  Future<void> _open() async {
    final String? r = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (BuildContext _) => const VaultScreen(),
      ),
    );
    await _load();
    if (r == 'spend') widget.onOpenTab?.call('premium');
  }

  static const TextStyle _kicker = TextStyle(
    color: GoldTones.light,
    fontSize: 10.5,
    fontWeight: FontWeight.w800,
    letterSpacing: 2.2,
  );

  static TextStyle _lead() => const TextStyle(
    color: IvoryColors.cream,
    fontFamily: IvoryTheme.displayFont,
    fontSize: 17,
    height: 1.32,
    fontStyle: FontStyle.italic,
  );

  static TextStyle _fine() => TextStyle(
    color: IvoryColors.cream.withValues(alpha: 0.78),
    fontSize: 12.5,
    height: 1.4,
  );

  Widget _head(VaultState? s, bool calm) {
    final int days = s?.days ?? 10;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'ONE KEY A DAY FOR ${vaultWord(days)} DAYS',
          style: _kicker.copyWith(letterSpacing: 1.8),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: GoldShimmerText(
                'THE ${vaultWord(days)}-DAY\nVAULT',
                extrude: calm ? 0 : 3,
                style: const TextStyle(
                  fontFamily: IvoryTheme.displayFont,
                  fontSize: 31,
                  height: 1.04,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 10),
            calm
                ? const Opacity(opacity: 0.55, child: VaultEmblem(size: 50))
                : const SizedBox(
                    width: 70,
                    height: 70,
                    child: Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        OverflowBox(
                          maxWidth: 170,
                          maxHeight: 170,
                          child: GoldRays(size: 170, opacity: 0.4),
                        ),
                        VaultEmblem(size: 62),
                      ],
                    ),
                  ),
          ],
        ),
      ],
    );
  }

  Widget _pulse(String text) => Row(
    children: <Widget>[
      const GoldPulseDot(size: 7),
      const SizedBox(width: 2),
      GoldBeat(
        child: Text(
          text,
          style: _kicker.copyWith(
            fontSize: 12.5,
            letterSpacing: 2.2,
            color: GoldTones.shine,
            shadows: <Shadow>[
              Shadow(
                color: GoldTones.mid.withValues(alpha: 0.9),
                blurRadius: 10,
              ),
            ],
          ),
        ),
      ),
    ],
  );

  String _gold(VaultState s) =>
      'Same gold as the Golden Knock-off: up to \u20B9${s.maxPerAnswer} off '
      'for every correct answer'
      '${s.maxBonus > 0 ? ', and a perfect ${s.days} out of ${s.days} adds a bonus of up to \u20B9${s.maxBonus}' : ''}. '
      'You get ${s.creditHours} hours to spend it.';

  Widget _ready(VaultState s) {
    String note = '';
    if (s.lastReason == 'membership') {
      note = 'Your last vault ended when you took a membership.';
    } else if (s.lastStatus == 'broken') {
      note =
          'Your last vault closed after ${s.lastAnswered} '
          '${s.lastAnswered == 1 ? 'key' : 'keys'}. Every vault starts '
          'again from Day 1.';
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _pulse(s.rehearsal ? 'ADMIN REHEARSAL' : 'YOUR VAULT IS WAITING'),
        const SizedBox(height: 2),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 46),
          child: GoldTeaser(
            style: _lead(),
            lines: <String>[
              'One question a day. Every answer stays sealed.',
              'Day 1 is gentle. Day ${s.days} is a different story.',
              'Turn all ${vaultWord(s.days).toLowerCase()} keys and the whole vault opens.',
            ],
          ),
        ),
        const SizedBox(height: 14),
        VaultKeyRow(total: s.days, turned: 0, today: true),
        const SizedBox(height: 10),
        Text(
          'Nothing is revealed until the last key turns: not your score, '
          'not a single right answer. Miss a day and the vault starts over.',
          style: _fine(),
        ),
        const SizedBox(height: 6),
        Text(_gold(s), style: _fine()),
        if (note.isNotEmpty) ...<Widget>[
          const SizedBox(height: 6),
          Text(note, style: _fine().copyWith(fontStyle: FontStyle.italic)),
        ],
        const SizedBox(height: 16),
        GoldButton(
          label: s.rehearsal ? 'REHEARSE THE VAULT' : 'BEGIN DAY 1',
          icon: Icons.vpn_key_rounded,
          onTap: _open,
        ),
        if (s.rehearsal)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Admin rehearsal: nothing is won and nothing is locked.',
              style: _fine(),
            ),
          ),
      ],
    );
  }

  Widget _openDay(VaultState s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _pulse('DAY ${s.dayNo} OF ${s.days}: YOUR KEY IS WAITING'),
        const SizedBox(height: 10),
        VaultKeyRow(total: s.days, turned: s.answered, today: true),
        const SizedBox(height: 10),
        Text(
          s.inProgress
              ? 'Your question is open and its clock is running.'
              : "Today's key closes in ${goldCountdown(s.untilNextDay)}. "
                    'Miss it and the vault starts over.',
          style: s.inProgress ? _lead() : _fine().copyWith(fontSize: 14),
        ),
        const SizedBox(height: 14),
        GoldButton(
          label: s.inProgress ? 'BACK TO MY QUESTION' : "TURN TODAY'S KEY",
          icon: Icons.vpn_key_rounded,
          onTap: _open,
        ),
      ],
    );
  }

  Widget _sealed(VaultState s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Day ${s.answered} is sealed. Well turned.', style: _lead()),
        const SizedBox(height: 10),
        VaultKeyRow(total: s.days, turned: s.answered),
        const SizedBox(height: 12),
        Text('DAY ${s.answered + 1} OPENS IN', style: _kicker),
        const SizedBox(height: 4),
        Text(
          goldCountdown(s.untilNextDay),
          style: const TextStyle(
            color: GoldTones.light,
            fontFamily: IvoryTheme.displayFont,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Your answers stay sealed until Day ${s.days}. Each day turns over '
          'at ${vaultHour(s.dayStartHour)}, and we will remind you.',
          style: _fine(),
        ),
      ],
    );
  }

  Widget _ceremony(VaultState s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _pulse('EVERY KEY IS TURNED'),
        const SizedBox(height: 8),
        VaultKeyRow(total: s.days, turned: s.days),
        const SizedBox(height: 10),
        Text('Your vault is ready to open.', style: _lead()),
        const SizedBox(height: 14),
        GoldButton(
          label: 'OPEN THE VAULT',
          icon: Icons.auto_awesome,
          onTap: _open,
        ),
      ],
    );
  }

  Widget _resting(VaultState s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Your vault has opened.', style: _lead()),
        const SizedBox(height: 12),
        Text('A NEW VAULT BEGINS IN', style: _kicker),
        const SizedBox(height: 4),
        Text(
          goldCountdown(s.untilNextRun),
          style: const TextStyle(
            color: GoldTones.light,
            fontFamily: IvoryTheme.displayFont,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Your gold, if you won any, is yours to spend for ${s.creditHours} '
          'hours after the vault opened. We will tell you the moment the '
          'next vault is ready.',
          style: _fine(),
        ),
      ],
    );
  }

  Widget _quiet(String line) => Padding(
    padding: const EdgeInsets.only(top: 2),
    child: Text(line, style: _fine().copyWith(fontSize: 14)),
  );

  String _lockedLine(VaultState s) {
    if (s.unlockAt == null) {
      return 'Your membership has no end date, so the Ten-Day Vault stays '
          'closed for you.';
    }
    return 'Your membership is running. The Ten-Day Vault opens again when '
        'it has ${s.renewDays} days left, on ${vaultDate(s.unlockAt!)}.';
  }

  @override
  Widget build(BuildContext context) {
    final VaultState? s = _s;
    if (s != null && s.phase == VaultPhase.signedOut) {
      return const SizedBox.shrink();
    }
    final bool calm =
        s == null ||
        s.phase == VaultPhase.closed ||
        s.phase == VaultPhase.locked ||
        s.phase == VaultPhase.resting;
    Widget body;
    if (s == null) {
      body = _failed
          ? GestureDetector(
              onTap: () {
                setState(() => _failed = false);
                _load();
              },
              child: _quiet('Tap to open The Ten-Day Vault.'),
            )
          : const Padding(
              padding: EdgeInsets.only(top: 6),
              child: SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: GoldTones.mid,
                ),
              ),
            );
    } else {
      body = switch (s.phase) {
        VaultPhase.ready => _ready(s),
        VaultPhase.open => _openDay(s),
        VaultPhase.sealed => _sealed(s),
        VaultPhase.ceremony => _ceremony(s),
        VaultPhase.resting => _resting(s),
        VaultPhase.locked => _quiet(_lockedLine(s)),
        VaultPhase.closed => _quiet(
          'The Ten-Day Vault is resting. Please come back soon.',
        ),
        VaultPhase.signedOut => const SizedBox.shrink(),
      };
    }
    return SizedBox(
      width: double.infinity,
      child: GoldTilt(
        lean: calm ? 0.05 : 0.1,
        sway: calm ? 0.3 : 1,
        child: GoldenFrame(
          calm: calm,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _head(s, calm),
              const SizedBox(height: 14),
              AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: SizedBox(width: double.infinity, child: body),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// END OF FILE - lib/widgets/vault_card.dart
