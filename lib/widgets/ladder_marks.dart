import 'package:flutter/material.dart';

import '../models/ladder_models.dart';
import '../models/reward_models.dart';
import '../services/crest_service.dart';
import '../services/ladder_service.dart';
import '../services/reward_service.dart';
import 'bell_sound.dart';
import 'ladder_paint.dart';
import 'mark_sheet.dart';

/// ============================================================
/// IVORY - THE MARKS BOOK
///
/// Every Mark in one book: earned ones shine in their rarity colour,
/// locked ones show how far the member has come. Marks are earned by
/// doing what Ivory is for; they are never sold. Tapping one tells its
/// story and, if locked, exactly what is left to do.
/// ============================================================
class MarksBook extends StatefulWidget {
  const MarksBook({super.key, required this.marks, required this.shine});

  final List<MarkItem> marks;
  final Animation<double> shine;

  @override
  State<MarksBook> createState() => _MarksBookState();
}

class _MarksBookState extends State<MarksBook> {
  int _filter = 0; // 0 all, 1 earned, 2 still to earn

  @override
  void initState() {
    super.initState();
    CrestService.instance.refreshQuietly();
    RewardService.instance.refreshQuietly();
    CrestService.instance.mine.addListener(_pinsMoved);
  }

  void _pinsMoved() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    CrestService.instance.mine.removeListener(_pinsMoved);
    super.dispose();
  }

  List<MarkItem> get _shown {
    final List<MarkItem> l = widget.marks.where((MarkItem m) {
      if (_filter == 1) return m.earned;
      if (_filter == 2) return !m.earned;
      return true;
    }).toList();
    if (_filter == 0) {
      // Earned first (newest first), then the closest to being earned.
      l.sort((MarkItem a, MarkItem b) {
        if (a.earned != b.earned) return a.earned ? -1 : 1;
        if (a.earned) {
          final DateTime ta = a.at ?? DateTime(2000);
          final DateTime tb = b.at ?? DateTime(2000);
          return tb.compareTo(ta);
        }
        return b.fraction.compareTo(a.fraction);
      });
    }
    return l;
  }

  void _detail(MarkItem m) {
    BellSound.instance.play('tap');
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: LadderTones.teal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext c) => MarkSheet(mark: m, shine: widget.shine),
    );
  }

  /// The nearest treasure still ahead that is earned by collecting Marks.
  Widget _nextTreasure() {
    return ValueListenableBuilder<RewardState?>(
      valueListenable: RewardService.instance.state,
      builder: (BuildContext _, RewardState? r, Widget? __) {
        if (r == null) return const SizedBox.shrink();
        final List<RewardItem> ahead = r.locked
            .where((RewardItem e) => e.trigger == 'marks_earned')
            .toList()
          ..sort((RewardItem a, RewardItem b) => a.target.compareTo(b.target));
        if (ahead.isEmpty) return const SizedBox.shrink();
        final RewardItem n = ahead.first;
        final String off = n.prize == null ? '' : n.prize!.offText;
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: LadderTones.tealDeep.withValues(alpha: 0.7),
            border: Border.all(color: LadderTones.mint.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'NEXT MARKS TREASURE',
                style: TextStyle(
                  color: LadderTones.mint,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  fontSize: 10.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                off.isEmpty
                    ? 'Collect ${n.target} Marks to earn "${n.name}".'
                    : 'Collect ${n.target} Marks to earn "${n.name}" and a '
                        'one-time $off on a membership.',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: n.ratio,
                  minHeight: 7,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    LadderTones.mint,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${n.progress} of ${n.target} Marks',
                style: const TextStyle(color: LadderTones.pearl, fontSize: 11.5),
              ),
            ],
          ),
        );
      },
    );
  }

  /// What the five colours mean.
  Widget _legend() {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: <Widget>[
        for (int i = 0; i < 5; i++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: LadderTones.rarity[i],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                LadderTones.rarityName[i],
                style: const TextStyle(
                  color: LadderTones.mist,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _chip(int i, String t) {
    final bool on = _filter == i;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _filter = i),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: on
                ? LadderTones.mint
                : LadderTones.tealDeep.withValues(alpha: 0.6),
            border: Border.all(
              color: on ? LadderTones.mint : LadderTones.mist.withValues(alpha: 0.4),
            ),
          ),
          child: Text(
            t,
            style: TextStyle(
              color: on ? LadderTones.teal : LadderTones.pearl,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<MarkItem> list = _shown;
    final int mp = LadderService.instance.state.value?.markPoints ?? 3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Every Mark you earn adds +$mp climb points and can be pinned to '
          'your Showcase on your Profile. Marks are earned, never sold.',
          style: const TextStyle(
            color: LadderTones.pearl,
            height: 1.45,
            fontSize: 12.5,
          ),
        ),
        const SizedBox(height: 12),
        _nextTreasure(),
        Wrap(
          runSpacing: 8,
          children: <Widget>[_chip(0, 'All'), _chip(1, 'Earned'), _chip(2, 'To earn')],
        ),
        const SizedBox(height: 10),
        _legend(),
        const SizedBox(height: 14),
        if (list.isEmpty)
          const Padding(
            padding: EdgeInsets.all(18),
            child: Text(
              'Nothing here yet. Your first Mark is one small step away.',
              style: TextStyle(color: LadderTones.pearl),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              mainAxisExtent: 122,
            ),
            itemBuilder: (BuildContext c, int i) {
              final MarkItem m = list[i];
              return GestureDetector(
                onTap: () => _detail(m),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  children: <Widget>[
                    Stack(
                      clipBehavior: Clip.none,
                      children: <Widget>[
                        MarkMedallion(
                          glyph: m.glyph,
                          rarity: m.rarityIndex,
                          earned: m.earned,
                          fraction: m.fraction,
                          shine: widget.shine,
                          size: 62,
                          label: m.target > 1 ? '${m.target}' : '',
                        ),
                        if (m.earned &&
                            (CrestService.instance.mine.value?.pins
                                    .contains(m.key) ??
                                false))
                          const Positioned(
                            left: -2,
                            top: -2,
                            child: Icon(
                              Icons.push_pin,
                              size: 16,
                              color: LadderTones.mint,
                            ),
                          ),
                        if (m.isNew)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: LadderTones.rose,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      m.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: m.earned
                            ? Colors.white
                            : LadderTones.pearl.withValues(alpha: 0.85),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

// END OF FILE - lib/widgets/ladder_marks.dart
