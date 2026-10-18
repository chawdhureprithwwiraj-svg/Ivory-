import 'package:flutter/material.dart';

import '../services/early_service.dart';
import '../services/line_service.dart';
import '../theme/ivory_theme.dart';
import 'line_voice_player.dart';

/// One letter on paper, with its honest status and Ivory's reply under it.
/// Nothing is shown as "read" or "answered" unless the database says so.
class LineLetterCard extends StatelessWidget {
  const LineLetterCard({
    super.key,
    required this.letter,
    required this.state,
    required this.onDelete,
  });

  final LineLetter letter;
  final LineState state;
  final VoidCallback onDelete;

  static const Color _ink = IvoryColors.emerald;

  String _statusWords() {
    switch (letter.status) {
      case 'held':
        return 'Held for a quick look by the house, then it travels.';
      case 'waiting':
        return lineQueueText(state);
      case 'read':
        return letter.readAt == null
            ? 'Read by Ivory.'
            : 'Read by Ivory on ${earlyClock(letter.readAt!)}.';
      case 'answered':
        return 'Ivory wrote back.';
      case 'returned':
        return 'This one came back. Ivory could not reach it in time. It does '
            'not count against your letters.';
      case 'declined':
        return 'This letter was not sent.';
      default:
        return '';
    }
  }

  IconData _icon() {
    switch (letter.status) {
      case 'answered':
        return Icons.mark_email_read_outlined;
      case 'read':
        return Icons.drafts_outlined;
      case 'returned':
      case 'declined':
        return Icons.undo_rounded;
      default:
        return Icons.hourglass_empty_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool answered = letter.status == 'answered';
    final bool hasText = (letter.replyText ?? '').trim().isNotEmpty;
    final String? voice = letter.replyKind == 'voice' &&
            (letter.replyAudioUrl ?? '').isNotEmpty
        ? letter.replyAudioUrl
        : null;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: IvoryColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: IvoryColors.emeraldLight.withValues(alpha: 0.35),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: IvoryColors.burgundy.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 6, 0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    earlyClock(letter.createdAt),
                    style: TextStyle(
                      color: _ink.withValues(alpha: 0.65),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_horiz, color: _ink.withValues(alpha: 0.7)),
                  onSelected: (String v) {
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (BuildContext c) => const <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Delete this letter'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Text(
              letter.body,
              style: const TextStyle(
                color: _ink,
                fontFamily: IvoryTheme.displayFont,
                fontSize: 15,
                height: 1.45,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: IvoryColors.emeraldWash,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(_icon(), size: 17, color: IvoryColors.emeraldMid),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _statusWords(),
                    style: const TextStyle(
                      color: IvoryColors.emerald,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (answered && (hasText || voice != null))
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[IvoryColors.emeraldMid, IvoryColors.emerald],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    letter.answeredAt == null
                        ? 'IVORY WROTE BACK'
                        : 'IVORY WROTE BACK \u00B7 ${earlyClock(letter.answeredAt!).toUpperCase()}',
                    style: TextStyle(
                      color: IvoryColors.emeraldWash.withValues(alpha: 0.75),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (voice != null) ...<Widget>[
                    LineVoicePlayer(path: voice),
                    if (hasText) const SizedBox(height: 12),
                  ],
                  if (hasText)
                    Text(
                    letter.replyText!,
                    style: const TextStyle(
                      color: IvoryColors.emeraldWash,
                      fontFamily: IvoryTheme.displayFont,
                      fontStyle: FontStyle.italic,
                      fontSize: 15.5,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// END OF FILE - lib/widgets/line_letter_card.dart
