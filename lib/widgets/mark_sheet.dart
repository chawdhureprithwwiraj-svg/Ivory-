import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../core/ivory_errors.dart';
import '../models/ladder_models.dart';
import '../services/crest_service.dart';
import '../services/ladder_service.dart';
import 'ladder_paint.dart';

/// ============================================================
/// IVORY - ONE MARK, ITS STORY AND WHAT IT GIVES
///
/// Shown when a member taps a Mark in the Marks Book. It says how
/// rare the Mark is, what it asks, and what it gives: the climb points
/// it adds to the Ivory Ladder. An earned Mark can be pinned to the
/// member's Showcase (three at most) or shared. Every message is
/// written INSIDE this sheet, never on the page behind it.
/// ============================================================
class MarkSheet extends StatefulWidget {
  const MarkSheet({super.key, required this.mark, required this.shine});

  final MarkItem mark;
  final Animation<double> shine;

  @override
  State<MarkSheet> createState() => _MarkSheetState();
}

class _MarkSheetState extends State<MarkSheet> {
  bool _busy = false;
  String? _msg;

  bool get _pinned =>
      CrestService.instance.mine.value?.pins.contains(widget.mark.key) ??
      false;

  Future<void> _togglePin() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _msg = null;
    });
    try {
      if (CrestService.instance.mine.value == null) {
        await CrestService.instance.refreshQuietly();
      }
      final CrestMine? cur = CrestService.instance.mine.value;
      if (cur == null) {
        _msg = 'Your Showcase could not be reached just now. Please try again.';
      } else {
        final List<String> pins = List<String>.of(cur.pins);
        if (pins.contains(widget.mark.key)) {
          pins.remove(widget.mark.key);
          await CrestService.instance.save(pins: pins);
          _msg = 'Unpinned from your Showcase.';
        } else if (pins.length >= 3) {
          _msg = 'Your Showcase holds three Marks. Unpin one first, on your '
              'Profile.';
        } else {
          pins.add(widget.mark.key);
          await CrestService.instance.save(pins: pins);
          _msg = 'Pinned. It now sits on your Showcase.';
        }
      }
    } catch (e) {
      _msg = houseMessage(e);
    }
    if (mounted) setState(() => _busy = false);
  }

  void _share() {
    final MarkItem m = widget.mark;
    Share.share(
      'I earned the "${m.name}" Mark on Ivory. ${m.blurb} '
      'Every story leaves a mark.',
    );
  }

  Widget _button(String t, IconData icon, VoidCallback? onTap, bool solid) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(23),
            color: solid ? LadderTones.mint : Colors.transparent,
            border: Border.all(color: LadderTones.mint),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  icon,
                  size: 17,
                  color: solid ? LadderTones.teal : LadderTones.mint,
                ),
                const SizedBox(width: 6),
                Text(
                  t,
                  style: TextStyle(
                    color: solid ? LadderTones.teal : LadderTones.mint,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final MarkItem m = widget.mark;
    final Color tone = LadderTones.rarity[m.rarityIndex];
    final int mp = LadderService.instance.state.value?.markPoints ?? 3;
    return SingleChildScrollView(
      child: Padding(
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
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: LadderTones.tealDeep.withValues(alpha: 0.7),
              ),
              child: Text(
                m.earned
                    ? 'Gave you +$mp climb points on the Ivory Ladder.'
                    : 'Earn it for +$mp climb points on the Ivory Ladder.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: LadderTones.pearl,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ),
            if (m.earned) ...<Widget>[
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  _button(
                    _pinned ? 'UNPIN' : 'PIN TO SHOWCASE',
                    Icons.push_pin_outlined,
                    _busy ? null : _togglePin,
                    !_pinned,
                  ),
                  const SizedBox(width: 10),
                  _button('SHARE', Icons.ios_share, _share, false),
                ],
              ),
            ],
            if (_msg != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                _msg!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: LadderTones.sun,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// END OF FILE - lib/widgets/mark_sheet.dart
