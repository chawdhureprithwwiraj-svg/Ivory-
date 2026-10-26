import 'package:flutter/material.dart';

import '../services/line_service.dart';
import '../theme/ivory_theme.dart';

/// ============================================================
/// IVORY - THE LINE SHELVES (CC.219)
///
/// The three shelves that turn the Private Line into an economy a
/// Forever member can stand in: YOUR PLACE IN THE LINE (the queue
/// number and the devotion that moves it), YOUR THREE STAMPS (the
/// visible road to the Invitation), and THE SATURDAY EVENING LETTER
/// (the random weekly draw, its declaration, its cord and its
/// digest). Every number comes from the house's own SQL spine
/// (line_free_state / line_saturday_state); when the spine is not
/// there yet, the shelves simply do not appear. Paid members see
/// only the Saturday shelf - the front of the Line is theirs.
/// ============================================================
class LineShelves extends StatelessWidget {
  const LineShelves({
    super.key,
    required this.free,
    required this.draw,
    required this.daily,
    required this.onDraw,
    required this.onJoin,
  });

  final Map<String, dynamic>? free;
  final Map<String, dynamic>? draw;
  final LineDaily? daily;
  final VoidCallback onDraw;
  final VoidCallback onJoin;

  Widget _heading(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 22, 2, 10),
    child: Text(
      t,
      style: TextStyle(
        color: IvoryColors.emerald.withValues(alpha: 0.7),
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 2.4,
      ),
    ),
  );

  Widget _paper(Widget child) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[Color(0xFFFFF9E8), Color(0xFFFFFCF2), Color(0xFFF6EEDB)],
        stops: <double>[0, 0.3, 1],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0x73C9962C)),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: const Color(0xFFFFC464).withValues(alpha: 0.28),
          blurRadius: 34,
        ),
        BoxShadow(
          color: IvoryColors.burgundy.withValues(alpha: 0.08),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: child,
  );

  Widget _note(String t, {bool strong = false}) => Text(
    t,
    style: TextStyle(
      color: IvoryColors.emerald.withValues(alpha: strong ? 1 : 0.82),
      fontSize: 13.5,
      height: 1.45,
      fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
    ),
  );

  Widget _stampChip(String name, String have, bool done) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: IvoryColors.emerald.withValues(alpha: done ? 0.16 : 0.05),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: IvoryColors.emerald.withValues(alpha: done ? 0.7 : 0.25),
      ),
    ),
    child: Text(
      '$name  $have',
      style: TextStyle(
        color: IvoryColors.emerald.withValues(alpha: done ? 1 : 0.6),
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? f = free;
    final List<Widget> out = <Widget>[];
    if (f != null && f['position'] != null) {
      final int n(dynamic k) => (f[k] as num?)?.toInt() ?? 0;
      final int ahead = n('ahead');
      out.add(_heading('YOUR PLACE IN THE LINE'));
      out.add(_paper(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _note(
            'Your letter stands at number ${n('position')} in the Line. '
            '$ahead free ${ahead == 1 ? 'letter' : 'letters'} ahead of you; '
            'members hold the front, as they always do.',
            strong: true,
          ),
          const SizedBox(height: 8),
          _note(
            '${n('lit_n')} lit days, ${n('bell_n')} bell days and '
            '${n('wait_days')} days of patient waiting carry it. Every new '
            'lit day and bell day moves it up - and waiting itself moves it '
            'too, one step a week. Nobody can buy past you here.',
          ),
        ],
      )));
    }
    if (f != null && f['stamps'] != null) {
      final Map<String, dynamic> st = Map<String, dynamic>.from(
        f['stamps'] as Map? ?? <String, dynamic>{},
      );
      final bool invited = st['invited'] == true;
      out.add(_heading('YOUR THREE STAMPS'));
      out.add(_paper(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _note(
            'Three stamps stand between you and the Invitation - the house '
            'lowering the price of your first season:',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _stampChip('PRESENCE', '${st['lit_n'] ?? 0}/30',
                  st['presence'] == true),
              _stampChip('VOICE',
                  st['voice'] == true ? 'SEALED' : 'UNSEALED',
                  st['voice'] == true),
              _stampChip('RING', '${st['bell_n'] ?? 0}/7', st['ring'] == true),
            ],
          ),
          const SizedBox(height: 10),
          _note(
            invited
                ? 'The Invitation is ready: all three stamps gathered. The '
                    'house lowers your first season - its code meets you at '
                    'the memberships door.'
                : 'Presence: thirty lit days. Voice: one sealed letter. Ring: '
                    'seven bell days. Gather all three and the Invitation '
                    'arrives.',
            strong: invited,
          ),
          if (invited) ...<Widget>[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: IvoryColors.emerald,
                  side: const BorderSide(color: Color(0x99C9962C), width: 1.4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: const StadiumBorder(),
                ),
                onPressed: onJoin,
                child: const Text(
                  'SEE THE MEMBERSHIPS',
                  style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          _note(
            'Or skip the Line entirely: membership reads first, always - and '
            'more than one road lowers its price.',
          ),
        ],
      )));
    }
    final bool drawn = draw?['drawn'] == true;
    final bool canDraw = draw?['can_draw'] == true;
    final LineDaily? d = daily;
    out.add(_heading('THE SATURDAY EVENING LETTER'));
    out.add(_paper(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _note(
          "Every Saturday evening, one Forever member's sealed letter is "
          'drawn and answered - by luck alone. No hand picks it, not even '
          "Ivory's: any member present may pull the cord, and the shuffle "
          'chooses. Keep standing, keep trying - your turn is in the '
          'shuffle.',
        ),
        const SizedBox(height: 10),
        if (drawn)
          _note('Drawn this week. The chosen letter is with Ivory now.',
              strong: true)
        else if (canDraw)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: IvoryColors.emerald,
                side: const BorderSide(color: Color(0x99C9962C), width: 1.4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: const StadiumBorder(),
              ),
              onPressed: onDraw,
              child: const Text(
                "PULL THE CORD - DRAW THIS WEEK'S LETTER",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          )
        else
          _note('The cord waits until Saturday evening.'),
        if (d != null) ...<Widget>[
          const SizedBox(height: 12),
          _note('FROM THE LINE', strong: true),
          const SizedBox(height: 4),
          _note('\u201c${d.letter}\u201d'),
          const SizedBox(height: 6),
          _note('Ivory: \u201c${d.reply}\u201d'),
        ],
      ],
    )));
    return Column(children: out);
  }
}

// END OF FILE - lib/widgets/line_shelves.dart
