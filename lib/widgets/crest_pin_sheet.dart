import 'package:flutter/material.dart';

import '../core/ivory_errors.dart';
import '../models/ladder_models.dart';
import '../services/crest_service.dart';
import 'ladder_paint.dart';

/// The sheet for choosing up to three Marks to pin. Any message the
/// member needs is written INSIDE the sheet.
class CrestPinSheet extends StatefulWidget {
  const CrestPinSheet({
    required this.earned,
    required this.start,
    required this.shine,
  });

  final List<MarkItem> earned;
  final List<String> start;
  final Animation<double> shine;

  @override
  State<CrestPinSheet> createState() => CrestPinSheetState();
}

class CrestPinSheetState extends State<CrestPinSheet> {
  late final List<String> _sel = widget.start
      .where((String k) => widget.earned.any((MarkItem m) => m.key == k))
      .toList();
  bool _busy = false;
  String? _msg;

  void _flip(MarkItem m) {
    setState(() {
      _msg = null;
      if (_sel.contains(m.key)) {
        _sel.remove(m.key);
      } else if (_sel.length >= 3) {
        _msg = 'Three is the most. Tap a pinned Mark to unpin it first.';
      } else {
        _sel.add(m.key);
      }
    });
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _msg = null;
    });
    try {
      await CrestService.instance.save(pins: List<String>.of(_sel));
      if (mounted) Navigator.of(context).pop();
      return;
    } catch (e) {
      _msg = houseMessage(e);
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final double h = MediaQuery.sizeOf(context).height;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: h * 0.82),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'PIN UP TO THREE MARKS',
              style: TextStyle(
                color: LadderTones.mint,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.4,
                fontSize: 11.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${_sel.length} of 3 pinned. They sit on your Showcase.',
              style: const TextStyle(color: LadderTones.pearl, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 12,
                  children: <Widget>[
                    for (final MarkItem m in widget.earned)
                      GestureDetector(
                        onTap: () => _flip(m),
                        child: SizedBox(
                          width: 84,
                          child: Column(
                            children: <Widget>[
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _sel.contains(m.key)
                                        ? LadderTones.mint
                                        : Colors.transparent,
                                    width: 2.5,
                                  ),
                                ),
                                child: MarkMedallion(
                                  glyph: m.glyph,
                                  rarity: m.rarityIndex,
                                  earned: true,
                                  fraction: 1,
                                  shine: widget.shine,
                                  size: 62,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                m.name,
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (_msg != null) ...<Widget>[
              const SizedBox(height: 10),
              Text(
                _msg!,
                style: const TextStyle(
                  color: LadderTones.sun,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ],
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _busy ? null : _save,
              child: Container(
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: LadderTones.mint,
                ),
                child: Text(
                  _busy ? 'SAVING...' : 'SAVE MY SHOWCASE',
                  style: const TextStyle(
                    color: LadderTones.teal,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.6,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens the pin sheet for the member's earned Marks.
Future<void> showCrestPinSheet(
  BuildContext context, {
  required List<MarkItem> earned,
  required Animation<double> shine,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: LadderTones.teal,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (BuildContext c) => CrestPinSheet(
      earned: earned,
      start: CrestService.instance.mine.value?.pins ?? const <String>[],
      shine: shine,
    ),
  );
}

// END OF FILE - lib/widgets/crest_pin_sheet.dart
