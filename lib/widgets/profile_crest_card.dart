import 'package:flutter/material.dart';

import '../core/ivory_errors.dart';
import '../models/bell_models.dart';
import '../models/ladder_models.dart';
import '../screens/bells_sets_sheet.dart';
import '../screens/ladder_screen.dart';
import '../services/bells_service.dart';
import '../services/crest_service.dart';
import '../services/ladder_service.dart';
import 'bell_looks.dart';
import 'bell_paint.dart';
import 'crest_pin_sheet.dart';
import 'crest_ring.dart';
import 'ladder_paint.dart';

/// ============================================================
/// IVORY - YOUR SHOWCASE (on the Profile screen)
///
/// Everything a member has earned, in one royal card: a ring in the
/// colours of the bell set their bells wear, their rung on the Ivory
/// Ladder with the climb to the next, the set they are wearing, and up
/// to three Marks they chose to pin. A small switch decides whether
/// other members see a tag with their rung and bells beside their name
/// in live chat; it is ON until the member switches it off. Nothing
/// here is for sale. If the Ladder is closed the card is not there.
/// ============================================================
class ProfileCrestCard extends StatefulWidget {
  const ProfileCrestCard({super.key});

  @override
  State<ProfileCrestCard> createState() => _ProfileCrestCardState();
}

class _ProfileCrestCardState extends State<ProfileCrestCard>
    with SingleTickerProviderStateMixin {
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _lilac = Color(0xFFCFC2F5);
  static const Color _pale = Color(0xFFF3ECFF);

  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  )..repeat();

  bool _saving = false;
  String? _note;

  @override
  void initState() {
    super.initState();
    LadderService.instance.start();
    if (LadderService.instance.state.value == null) {
      LadderService.instance.refreshQuietly();
    }
    if (BellsService.instance.state.value == null) {
      BellsService.instance.refreshQuietly();
    }
    CrestService.instance.refreshQuietly();
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  Future<void> _toggleShow(bool v) async {
    setState(() {
      _saving = true;
      _note = null;
    });
    try {
      await CrestService.instance.save(show: v);
    } catch (e) {
      _note = houseMessage(e);
    }
    if (mounted) setState(() => _saving = false);
  }

  void _openLadder() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const LadderScreen()),
    );
  }

  void _pick(LadderState s) {
    final List<MarkItem> earned = s.marks
        .where((MarkItem m) => m.earned)
        .toList();
    if (earned.isEmpty) {
      setState(
        () => _note = 'Earn your first Mark and you can pin it here.',
      );
      return;
    }
    setState(() => _note = null);
    showCrestPinSheet(context, earned: earned, shine: _loop);
  }

  Widget _label(String t) => Text(
    t,
    style: const TextStyle(
      color: _lilac,
      fontWeight: FontWeight.w800,
      letterSpacing: 2.2,
      fontSize: 10.5,
    ),
  );

  Widget _chip(String t, {VoidCallback? onTap, IconData? icon}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: const Color(0x26FFFFFF),
          border: Border.all(color: const Color(0x40FFFFFF)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 14, color: _pale),
              const SizedBox(width: 6),
            ],
            Text(
              t,
              style: const TextStyle(
                color: _pale,
                fontWeight: FontWeight.w800,
                fontSize: 11.5,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _slot(MarkItem? m, LadderState s) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => _pick(s),
        child: SizedBox(
          width: 60,
          height: 60,
          child: m == null
              ? Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0x14FFFFFF),
                    border: Border.all(color: const Color(0x59FFFFFF)),
                  ),
                  child: const Icon(Icons.add, color: _lilac, size: 22),
                )
              : MarkMedallion(
                  glyph: m.glyph,
                  rarity: m.rarityIndex,
                  earned: true,
                  fraction: 1,
                  shine: _loop,
                  size: 60,
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[
        LadderService.instance.state,
        BellsService.instance.state,
        CrestService.instance.mine,
      ]),
      builder: (BuildContext c, Widget? _) {
        final LadderState? s = LadderService.instance.state.value;
        if (s == null || !s.enabled) return const SizedBox.shrink();
        final BellsState? b = BellsService.instance.state.value;
        final bool bellsOn = b != null && b.enabled;
        final BellLook look = BellLook.of(b != null && b.enabled ? b.wear : null);
        final CrestMine? mine = CrestService.instance.mine.value;
        final List<MarkItem> pinned = <MarkItem>[];
        for (final String k in mine?.pins ?? const <String>[]) {
          for (final MarkItem m in s.marks) {
            if (m.key == k && m.earned) pinned.add(m);
          }
        }
        final String setName = b == null
            ? ''
            : (b.setByKey(b.wear)?.name ?? 'Jewel');
        final String ofTxt = s.rungs.isEmpty ? '' : ' of ${s.rungs.length}';
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[Color(0xFF4A0E17), Color(0xFF2A0E72)],
              ),
              border: Border.all(color: const Color(0x59FFE9A8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _label('YOUR SHOWCASE'),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    GestureDetector(
                      onTap: _openLadder,
                      child: SizedBox(
                        width: 92,
                        height: 92,
                        child: Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            AnimatedBuilder(
                              animation: _loop,
                              builder: (BuildContext c2, Widget? _) =>
                                  CustomPaint(
                                    size: const Size(92, 92),
                                    painter: CrestRingPainter(
                                      colors: look.colors,
                                      fraction: s.climb,
                                      t: _loop.value,
                                    ),
                                  ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
                                  '${s.rung.n}',
                                  style: const TextStyle(
                                    fontFamily: 'serif',
                                    color: _white,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'RUNG',
                                  style: TextStyle(
                                    color: _lilac,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.6,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: GestureDetector(
                        onTap: _openLadder,
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              s.rung.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'serif',
                                color: _white,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Rung ${s.rung.n}$ofTxt  \u00B7  ${s.points} climb points',
                              style: const TextStyle(
                                color: _lilac,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 9),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: Container(
                                height: 8,
                                color: const Color(0x26FFFFFF),
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: s.climb.clamp(0.04, 1.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: look.colors,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              s.next == null
                                  ? 'You stand on the top rung.'
                                  : '${s.need} more points to ${s.next!.name}',
                              style: const TextStyle(
                                color: _pale,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (bellsOn) ...<Widget>[
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () => showBellSets(context),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: const Color(0x1AFFFFFF),
                      ),
                      child: Row(
                        children: <Widget>[
                          for (final Color col in look.colors)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: BellShape(
                                color: col,
                                width: 26,
                                glow: 0.55,
                              ),
                            ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Wearing $setName',
                                  style: const TextStyle(
                                    color: _white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.5,
                                  ),
                                ),
                                const Text(
                                  'Tap to change your bells',
                                  style: TextStyle(color: _lilac, fontSize: 11.5),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: _lilac),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                _label('PINNED MARKS'),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    for (int i = 0; i < 3; i++)
                      _slot(i < pinned.length ? pinned[i] : null, s),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _note ??
                      (s.marksEarned == 0
                          ? 'Earn your first Mark and you can pin it here.'
                          : 'Tap a slot to pin up to three Marks you are proud of.'),
                  style: const TextStyle(color: _lilac, fontSize: 11.5),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _chip(
                      '${s.marksEarned} of ${s.marksTotal} Marks',
                      icon: Icons.verified_outlined,
                      onTap: _openLadder,
                    ),
                    _chip(
                      'Open the Ladder',
                      icon: Icons.stairs_outlined,
                      onTap: _openLadder,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(color: Color(0x33FFFFFF), height: 1),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Show beside my name in live chat',
                            style: TextStyle(
                              color: _white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Other members see a small tag with your rung and '
                            'bell colours. Switch it off any time.',
                            style: TextStyle(
                              color: _lilac,
                              fontSize: 11.5,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: mine?.showOthers ?? true,
                      onChanged: _saving ? null : _toggleShow,
                      activeThumbColor: _white,
                      activeTrackColor: LadderTones.mint,
                      inactiveThumbColor: _lilac,
                      inactiveTrackColor: const Color(0x33FFFFFF),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// END OF FILE - lib/widgets/profile_crest_card.dart
