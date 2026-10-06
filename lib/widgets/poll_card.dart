import 'package:flutter/material.dart';

import '../models/ivory_post.dart';
import '../services/auth_service.dart';
import '../services/content_service.dart';
import '../theme/ivory_theme.dart';
import 'poll_bars.dart';

/// ============================================================
/// IVORY - THE POLL, IN THE FEED
///
/// SPRINT 24i. Until now a poll landed in the home feed as an
/// ordinary post card: a blank 52-pixel gap where the artwork
/// would be, a title, and nothing a member could recognise as a
/// question. It was unvotable and, frankly, looked broken.
///
/// This renders the poll properly, and lets a member answer
/// without leaving the feed - the way YouTube and Facebook do
/// it. Appearance comes from poll_bars.dart, shared with the
/// detail sheet, so the two can never disagree.
/// ============================================================

/// A poll shows at most this many options in the feed. Anything
/// longer would push the next post off the screen; the rest are
/// one tap away in the detail sheet.
const int _maxInFeed = 4;

class PollCard extends StatefulWidget {
  const PollCard({
    super.key,
    required this.post,
    required this.onTap,
  });

  final IvoryPost post;
  final VoidCallback onTap;

  @override
  State<PollCard> createState() => _PollCardState();
}

class _PollCardState extends State<PollCard> {
  List<PollOption> _options = <PollOption>[];
  int? _myVote;
  bool _loading = true;
  bool _failed = false;

  final bool _house = AuthService.instance.isAdminCached;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final List<PollOption> o =
          await ContentService.instance.fetchPollOptions(widget.post.id);
      final int? mine =
          await ContentService.instance.myVote(widget.post.id);
      if (!mounted) return;
      setState(() {
        _options = o;
        _myVote = mine;
        _loading = false;
        _failed = false;
      });
    } catch (_) {
      // A poll that cannot load its options must still look like a
      // poll, not like an empty card. Never show the raw error.
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  Future<void> _vote(int optionId) async {
    setState(() => _myVote = optionId);
    try {
      await ContentService.instance
          .castVote(postId: widget.post.id, optionId: optionId);
    } catch (_) {
      // Swallow it here; _load() below restores the true standing.
    }
    await _load();
  }

  /// In the composer the headline field is called "The question, in
  /// one line" and is saved as the summary. So the question is the
  /// summary when there is one, and the title otherwise.
  String get _question {
    final String? s = widget.post.summary;
    if (s != null && s.trim().isNotEmpty) return s.trim();
    return widget.post.title.replaceFirst('[SAMPLE] ', '');
  }

  @override
  Widget build(BuildContext context) {
    final bool locked = widget.post.isLocked;
    final bool revealed = !locked && (_house || _myVote != null);

    final PollMaths m = PollMaths.of(<int, int>{
      for (final PollOption o in _options) o.id: o.votes,
    });

    final List<PollOption> shown = _options.length > _maxInFeed
        ? _options.sublist(0, _maxInFeed)
        : _options;
    final int hidden = _options.length - shown.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: IvoryTheme.card(radius: 22),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const PollBadge(),
            const SizedBox(height: 12),

            // The question is the headline. That alone is most of
            // what makes this read as a poll and not as a post.
            Text(
              _question,
              style: const TextStyle(
                fontFamily: IvoryTheme.displayFont,
                color: IvoryColors.burgundy,
                fontSize: 18,
                height: 1.3,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),

            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: IvoryColors.amber),
                  ),
                ),
              )
            else if (_failed)
              _quiet('This poll could not be loaded just now.')
            else if (_options.isEmpty)
              _quiet('No options were added to this poll.')
            else if (locked)
              _quiet('Unlock this post to answer.')
            else ...<Widget>[
              ...shown.map((PollOption o) {
                final int pct = m.percents[o.id] ?? 0;
                return PollOptionBar(
                  label: o.label,
                  percent: pct,
                  revealed: revealed,
                  votes: _house ? o.votes : null,
                  mine: _myVote == o.id,
                  lead: revealed && m.total > 0 && pct == m.best,
                  compact: true,
                  onTap: () => _vote(o.id),
                );
              }),
              if (hidden > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 6),
                  child: Text(
                    hidden == 1
                        ? '1 more option - tap to see it'
                        : '$hidden more options - tap to see them',
                    style: TextStyle(
                      fontSize: 12,
                      color: IvoryColors.textFaint,
                    ),
                  ),
                ),
            ],

            const SizedBox(height: 4),
            Divider(color: IvoryColors.hairline, height: 1),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: PollTally(
                    text: revealed
                        ? m.tally
                        : (locked
                            ? widget.post.relativeTime
                            : 'Tap an option - nobody sees your name'),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          'Open',
                          style: TextStyle(
                            color: IvoryColors.plum,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(width: 3),
                        Icon(Icons.arrow_forward,
                            size: 15, color: IvoryColors.plum),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quiet(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Text(
          text,
          style: TextStyle(fontSize: 13, color: IvoryColors.textSoft),
        ),
      );
}

// END OF FILE - lib/widgets/poll_card.dart
