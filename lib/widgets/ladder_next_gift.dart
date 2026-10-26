import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/ladder_service.dart';
import 'ladder_paint.dart';

/// ============================================================
/// IVORY - THE NEXT LADDER GIFT
///
/// One card on the Ladder screen: the nearest discount gift still
/// ahead of the member ("Climb to Task and earn 15% off a membership,
/// 18 points to go"). It only reads; the gift itself is made by the
/// treasures when the rung is reached. If there is no gift ahead, or
/// anything fails, the card simply is not there. The numbers come from
/// the house's own treasures, so they change when the house changes
/// them.
/// ============================================================
class LadderNextGift extends StatefulWidget {
  const LadderNextGift({super.key, this.preset});

  /// For tests: the answer to show without asking the database.
  final Map<String, dynamic>? preset;

  @override
  State<LadderNextGift> createState() => _LadderNextGiftState();
}

class _LadderNextGiftState extends State<LadderNextGift> {
  Map<String, dynamic>? _g;
  int _last = -1;
  bool _asked = false;

  @override
  void initState() {
    super.initState();
    if (widget.preset != null) {
      _g = widget.preset;
      return;
    }
    _ask();
    // The Ladder is asked again whenever the heart or the bells move.
    LadderService.instance.state.addListener(_ask);
  }

  @override
  void dispose() {
    if (widget.preset == null) {
      LadderService.instance.state.removeListener(_ask);
    }
    super.dispose();
  }

  Future<void> _ask() async {
    try {
      final dynamic r =
          await Supabase.instance.client.rpc('ladder_next_gift');
      if (!mounted) return;
      final Map<String, dynamic> m =
          r is Map ? Map<String, dynamic>.from(r) : <String, dynamic>{};
      final bool next = m['state'] == 'next';
      final int rungNo = (m['rung'] as num?)?.toInt() ?? 0;
      final int toGo = (m['points_needed'] as num?)?.toInt() ?? 0;
      final int key = next ? rungNo * 100000 + toGo : -1;
      if (key == _last) return;
      _last = key;
      setState(() => _g = next ? m : null);
    } catch (_) {
      // Quiet: the card just stays as it is.
    } finally {
      _asked = true;
    }
  }

  String _what(Map<String, dynamic> g) {
    final int v = (g['value'] as num?)?.toInt() ?? 0;
    return g['kind'] == 'percent' ? '$v% off' : '\u20B9$v off';
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? g = _g;
    if (g == null) {
      // CC.214: a reserved slot of the same shell. While the ladder is
      // still asking - or has nothing to show - the page keeps this
      // space, so a scroll never jumps when the answer arrives late.
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              LadderTones.tealMid.withValues(alpha: 0.85),
              LadderTones.tealDeep.withValues(alpha: 0.9),
            ],
          ),
          border: Border.all(color: LadderTones.mint.withValues(alpha: 0.22)),
        ),
        child: SizedBox(
          height: 120,
          child: Center(
            child: Text(
              _asked
                  ? 'No gift waiting right now. The next one is being woven.'
                  : 'The ladder is looking ahead to your next gift.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: LadderTones.pearl.withValues(alpha: 0.9),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ),
      );
    }
    final String rung = '${g['rung_name'] ?? ''}';
    final int need = (g['points_needed'] as num?)?.toInt() ?? 0;
    final int days = (g['days'] as num?)?.toInt() ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            LadderTones.tealMid.withValues(alpha: 0.85),
            LadderTones.tealDeep.withValues(alpha: 0.9),
          ],
        ),
        border: Border.all(color: LadderTones.mint.withValues(alpha: 0.22)),
      ),
      child: SizedBox(
        // CC.216: one exact height for asking, empty and full alike -
        // the last place the ladder could change height under a thumb.
        height: 120,
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: LadderTones.mint.withValues(alpha: 0.16),
              border: Border.all(
                color: LadderTones.mint.withValues(alpha: 0.5),
              ),
            ),
            child: const Icon(
              Icons.card_giftcard,
              color: LadderTones.mint,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text(
                  'YOUR NEXT GIFT',
                  style: TextStyle(
                    color: LadderTones.mint,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.6,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Climb to $rung and earn ${_what(g)} a membership.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${need == 1 ? '1 point' : '$need points'} to go. '
                  'It comes as a personal code'
                  '${days > 0 ? ' that lasts $days days' : ''}, for a '
                  'membership bought separately.',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: LadderTones.pearl,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
        ),
    );
  }
}

// END OF FILE - lib/widgets/ladder_next_gift.dart
