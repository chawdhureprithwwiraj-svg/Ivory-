import 'package:flutter/material.dart';

import '../models/ladder_models.dart';
import 'bell_sound.dart';
import 'ladder_paint.dart';

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
    final Color tone = LadderTones.rarity[m.rarityIndex];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: LadderTones.teal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext c) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            MarkMedallion(
              glyph: m.glyph,
              rarity: m.rarityIndex,
              earned: m.earned,
              fraction: m.fraction,
              shine: widget.shine,
              size: 104,
              label: m.target > 1 ? '${m.target}' : '',
            ),
            const SizedBox(height: 12),
            Text(
              LadderTones.rarityName[m.rarityIndex],
              style: TextStyle(
                color: tone,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.6,
                fontSize: 11.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              m.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              m.blurb,
              textAlign: TextAlign.center,
              style: const TextStyle(color: LadderTones.pearl, height: 1.45),
            ),
            const SizedBox(height: 14),
            if (m.earned)
              Text(
                m.at == null
                    ? 'Earned'
                    : 'Earned on ${m.at!.day}/${m.at!.month}/${m.at!.year}',
                style: TextStyle(color: tone, fontWeight: FontWeight.w700),
              )
            else ...<Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: m.fraction,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(tone),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${m.have} of ${m.target}',
                style: const TextStyle(
                  color: LadderTones.pearl,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          runSpacing: 8,
          children: <Widget>[_chip(0, 'All'), _chip(1, 'Earned'), _chip(2, 'To earn')],
        ),
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
