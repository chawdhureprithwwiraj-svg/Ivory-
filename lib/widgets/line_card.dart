import 'package:flutter/material.dart';

import '../screens/line_screen.dart';
import '../services/line_service.dart';
import '../theme/ivory_theme.dart';
import 'line_seal.dart';

/// ============================================================
/// IVORY - THE PRIVATE LINE, ON THE HOME SCREEN
///
/// One paper card with a sealed envelope. It says, truthfully, what
/// the member can do right now: write, wait, read a reply, or send
/// the letter that was kept for them. It disappears when the house
/// has switched the Private Line off or the database cannot be
/// reached. Tapping it opens the Private Line.
/// ============================================================
class LineCard extends StatefulWidget {
  const LineCard({super.key, this.onOpenTab});

  final void Function(String tab)? onOpenTab;

  @override
  State<LineCard> createState() => _LineCardState();
}

class _LineCardState extends State<LineCard> {
  LineService get _svc => LineService.instance;

  @override
  void initState() {
    super.initState();
    _svc.state.addListener(_changed);
    _svc.draft.addListener(_changed);
    _svc.loadDraft();
    _svc.refresh();
  }

  @override
  void dispose() {
    _svc.state.removeListener(_changed);
    _svc.draft.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _open() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LineScreen(onOpenTab: widget.onOpenTab),
      ),
    );
    if (mounted) _svc.refresh(force: true);
  }

  (String, String) _words(LineState s) {
    final bool draft = _svc.draft.value.trim().isNotEmpty;
    if (s.unseen > 0) {
      return ('Ivory wrote back', 'Open the Private Line to read her reply.');
    }
    if (s.paid) {
      final LineLetter? open = s.openLetter;
      if (open != null) {
        String line;
        switch (open.status) {
          case 'held':
            line = 'Held for a quick look by the house, then it travels.';
            break;
          case 'read':
            line = 'Read by Ivory. She answers as many as she can.';
            break;
          default:
            line = lineQueueText(s);
        }
        return ('Your letter is with Ivory', line);
      }
      if (s.canSend) {
        return draft
            ? ('Your letter is waiting', 'It was kept for you. Seal it and send it to Ivory.')
            : ('Write to Ivory', 'Every letter is read. She answers as many as she can.');
      }
      return ('Your letters are resting', 'A new one frees up as the days pass.');
    }
    return draft
        ? ('Your letter is kept for you', 'Ivory has not seen it. It travels the moment you join.')
        : ('Write to Ivory', 'Part of a paid membership. Write your letter now; it travels the moment you join.');
  }

  @override
  Widget build(BuildContext context) {
    final LineState? s = _svc.state.value;
    if (s == null || s.whyNot == 'resting') return const SizedBox.shrink();
    final (String head, String line) = _words(s);
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: GestureDetector(
        onTap: _open,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[IvoryColors.surface, IvoryColors.surfaceWarm],
            ),
            border: Border.all(
              color: IvoryColors.emeraldLight.withValues(alpha: 0.5),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: IvoryColors.burgundy.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              const LineEnvelopeView(width: 84, height: 70),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                          'THE PRIVATE LINE',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: IvoryColors.emerald.withValues(alpha: 0.65),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.4,
                          ),
                        ),
                        ),
                        if (s.unseen > 0) ...<Widget>[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: IvoryColors.emerald,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              s.unseen == 1 ? 'NEW' : '${s.unseen} NEW',
                              style: const TextStyle(
                                color: IvoryColors.emeraldWash,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      head,
                      style: const TextStyle(
                        color: IvoryColors.emerald,
                        fontFamily: IvoryTheme.displayFont,
                        fontStyle: FontStyle.italic,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      line,
                      style: TextStyle(
                        color: IvoryColors.emerald.withValues(alpha: 0.85),
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                    if (s.answeredToday > 0) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        s.answeredToday == 1
                            ? 'Ivory answered 1 letter today.'
                            : 'Ivory answered ${s.answeredToday} letters today.',
                        style: const TextStyle(
                          color: IvoryColors.emeraldMid,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// END OF FILE - lib/widgets/line_card.dart
