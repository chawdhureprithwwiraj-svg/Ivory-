import 'package:flutter/material.dart';

import '../core/ivory_errors.dart';
import '../models/reward_models.dart';
import '../services/reward_service.dart';
import '../theme/ivory_theme.dart';
import '../widgets/gold_button.dart';
import '../widgets/gold_fx.dart';
import '../widgets/gold_fx3d.dart';
import '../widgets/reward_badge.dart';
import '../widgets/treasure_prize.dart';

/// Opens the member's treasures.
Future<void> showTreasuresSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: IvoryColors.burgundy.withValues(alpha: 0.34),
    builder: (BuildContext _) => const TreasuresSheet(),
  );
}

String treasureDate(DateTime? d) {
  if (d == null) return '';
  const List<String> mo = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${d.day} ${mo[d.month - 1]} ${d.year}';
}

/// ============================================================
/// IVORY - YOUR TREASURES
///
/// Badges and access keys earned through the Golden Heart and the
/// quizzes, and the ones still to win, each with its goal and how
/// far along the member is. A badge is a keepsake and never goes. An
/// access key may have an end date; once it has ended it is still
/// kept on the shelf. All of it is decided by the database.
/// ============================================================
class TreasuresSheet extends StatefulWidget {
  const TreasuresSheet({super.key});

  @override
  State<TreasuresSheet> createState() => _TreasuresSheetState();
}

class _TreasuresSheetState extends State<TreasuresSheet> {
  RewardState? _s = RewardService.instance.state.value;
  String? _err;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final RewardState s = await RewardService.instance.refresh();
      if (!mounted) return;
      setState(() {
        _s = s;
        _err = null;
      });
      if (s.unseen > 0) {
        await RewardService.instance.markSeen();
        await RewardService.instance.refreshQuietly();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _err = houseMessage(e));
    }
  }

  Widget _earned(RewardItem r) {
    String note;
    if (r.isAccess) {
      if (!r.active) {
        note = 'Access ended ${treasureDate(r.expiresAt)}';
      } else if (r.expiresAt != null) {
        note = 'Access until ${treasureDate(r.expiresAt)}';
      } else {
        note = 'Access with no end date';
      }
    } else {
      note = 'Earned ${treasureDate(r.earnedAt)}';
    }
    return _cell(
      highlighted: r.active,
      children: <Widget>[
        Opacity(
          opacity: r.active ? 1 : 0.55,
          child: RewardBadge(shape: r.shape, metal: r.metal, size: 92),
        ),
        const SizedBox(height: 6),
        Text(
          r.name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: IvoryColors.burgundy,
            fontFamily: IvoryTheme.displayFont,
            fontWeight: FontWeight.w800,
            fontSize: 15,
            height: 1.15,
          ),
        ),
        if (r.blurb.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              r.blurb,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: IvoryColors.textFaint,
                fontSize: 11.5,
                height: 1.35,
              ),
            ),
          ),
        const SizedBox(height: 6),
        Text(
          r.isAccess ? 'ACCESS \u00B7 $note' : note,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: GoldTones.deep,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
        if (r.prize?.code != null)
          TreasurePrizeLine(
            prize: r.prize!,
            untilText: treasureDate(r.prize!.validUntil),
          ),
      ],
    );
  }

  Widget _locked(RewardItem r) {
    return _cell(
      highlighted: false,
      children: <Widget>[
        Stack(
          alignment: Alignment.center,
          children: <Widget>[
            RewardBadge(shape: r.shape, metal: r.metal, size: 84, locked: true),
            const Icon(Icons.lock_outline, size: 22, color: IvoryColors.plum),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          r.name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: IvoryColors.burgundy,
            fontWeight: FontWeight.w800,
            fontSize: 14,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          rewardGoalText(r.trigger, r.target),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: IvoryColors.textFaint,
            fontSize: 11.5,
            height: 1.35,
          ),
        ),
        if (r.prize != null) TreasurePrizeHint(prize: r.prize!),
        if (r.target > 1) ...<Widget>[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: SizedBox(
              height: 7,
              child: Stack(
                children: <Widget>[
                  Container(color: IvoryColors.hairline),
                  FractionallySizedBox(
                    widthFactor: r.ratio.clamp(0.04, 1.0),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: <Color>[GoldTones.light, GoldTones.deep],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${r.progress} / ${r.target}',
            style: const TextStyle(
              color: IvoryColors.plum,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ],
    );
  }

  Widget _cell({required bool highlighted, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
      decoration: IvoryTheme.card(highlighted: highlighted, radius: 18),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  Widget _grid(List<Widget> cells) {
    return LayoutBuilder(
      builder: (BuildContext _, BoxConstraints c) {
        final double w = (c.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            for (int i = 0; i < cells.length; i++)
              SizedBox(
                width: w,
                child: GoldRise(delayMs: 60 * (i % 6), child: cells[i]),
              ),
          ],
        );
      },
    );
  }

  Widget _title(String t) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 10),
    child: Text(
      t,
      style: const TextStyle(
        color: IvoryColors.plum,
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 2.4,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final RewardState? s = _s;
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
                  ? Padding(
                      padding: const EdgeInsets.all(48),
                      child: _err == null
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: IvoryColors.burgundy,
                              ),
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(_err!, textAlign: TextAlign.center),
                                const SizedBox(height: 14),
                                GoldButton(label: 'TRY AGAIN', onTap: _load),
                              ],
                            ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Center(
                            child: Text(
                              'YOUR TREASURES',
                              style: TextStyle(
                                color: IvoryColors.plum,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              s.total == 0
                                  ? 'No treasures are waiting yet. Come back soon.'
                                  : '${s.earned.length} of ${s.total} earned',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: IvoryColors.burgundy,
                                fontFamily: IvoryTheme.displayFont,
                                fontSize: 17,
                              ),
                            ),
                          ),
                          if (s.earned.isNotEmpty) ...<Widget>[
                            _title('EARNED'),
                            _grid(s.earned.map(_earned).toList()),
                          ],
                          if (s.locked.isNotEmpty) ...<Widget>[
                            _title('STILL TO WIN'),
                            _grid(s.locked.map(_locked).toList()),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// END OF FILE - lib/screens/treasures_sheet.dart
