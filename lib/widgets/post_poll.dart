import 'package:flutter/material.dart';

import '../models/ivory_post.dart';
import '../services/auth_service.dart';
import '../services/content_service.dart';
import '../theme/ivory_theme.dart';
import 'poll_bars.dart';

/// ============================================================
/// IVORY - THE POLL, IN FULL
///
/// SPRINT 24g. The voting logic below is unchanged and still
/// trusted: it loads the options, remembers the member's answer,
/// and keeps the honest split - members see percentages only,
/// the house sees exact counts and every name. Only the
/// appearance was rebuilt, into the badge-question-bars shape
/// of a YouTube or Facebook community poll.
/// ============================================================
String _clean(String title) => title.replaceFirst('[SAMPLE] ', '');

class PollBody extends StatefulWidget {
  const PollBody({super.key, required this.post});

  final IvoryPost post;

  @override
  State<PollBody> createState() => _PollBodyState();
}

class _PollBodyState extends State<PollBody> {
  List<PollOption> _options = <PollOption>[];
  Map<int, List<String>> _voters = <int, List<String>>{};
  int? _myVote;
  bool _loading = true;

  /// Members see only percentages. The house sees the counts and
  /// exactly who voted for what.
  final bool _house = AuthService.instance.isAdminCached;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final List<PollOption> o =
        await ContentService.instance.fetchPollOptions(widget.post.id);
    final int? mine = await ContentService.instance.myVote(widget.post.id);
    final Map<int, List<String>> voters =
        AuthService.instance.isAdminCached
            ? await ContentService.instance.fetchPollVoters(widget.post.id)
            : <int, List<String>>{};
    if (!mounted) return;
    setState(() {
      _options = o;
      _myVote = mine;
      _voters = voters;
      _loading = false;
    });
  }

  Future<void> _vote(int optionId) async {
    setState(() => _myVote = optionId);
    await ContentService.instance
        .castVote(postId: widget.post.id, optionId: optionId);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    // The house always sees the standing. A member sees nothing
    // until they have answered, so early numbers cannot nudge them.
    final bool revealed = _house || _myVote != null;

    final PollMaths m = PollMaths.of(<int, int>{
      for (final PollOption o in _options) o.id: o.votes,
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const PollBadge(),
        const SizedBox(height: 13),

        // The question is the headline. It is the whole point of
        // the card, so it is set like one.
        Text(
          _clean(widget.post.title),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        if (widget.post.summary != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(widget.post.summary!,
              style: Theme.of(context).textTheme.bodyMedium),
        ],
        const SizedBox(height: 6),
        Text(
          _house
              ? m.tally
              : (_myVote != null
                  ? 'You answered'
                  : 'Tap an option - nobody sees your name'),
          style: TextStyle(
              fontSize: 12.5, color: IvoryColors.textFaint),
        ),
        const SizedBox(height: 15),

        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(30),
              child: CircularProgressIndicator(color: IvoryColors.amber),
            ),
          )
        else ...<Widget>[
          ..._options.map((PollOption o) {
            final int pct = m.percents[o.id] ?? 0;
            final List<String> voters = _voters[o.id] ?? <String>[];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                PollOptionBar(
                  label: o.label,
                  percent: pct,
                  revealed: revealed,
                  votes: _house ? o.votes : null,
                  mine: _myVote == o.id,
                  lead: revealed && m.total > 0 && pct == m.best,
                  onTap: () => _vote(o.id),
                ),
                if (_house && voters.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10, left: 4),
                    child: Text(
                      'Voted: ${voters.join(', ')}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontStyle: FontStyle.italic,
                        color: IvoryColors.textFaint,
                      ),
                    ),
                  ),
              ],
            );
          }),
          const SizedBox(height: 4),
          if (revealed && !_house) PollTally(text: m.tally),
          if (_house)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: IvoryColors.success.withValues(alpha: 0.12),
                border: Border.all(
                  color: IvoryColors.success.withValues(alpha: 0.4),
                ),
              ),
              child: const Text(
                'Only you see this. Exact counts, and the name behind '
                'every vote. Members see percentages alone.',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  color: Color(0xFF4C6637),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

// END OF FILE - lib/widgets/post_poll.dart
