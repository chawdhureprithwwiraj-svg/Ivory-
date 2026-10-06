import 'package:flutter/material.dart';

import '../models/ivory_post.dart';
import '../services/auth_service.dart';
import '../services/content_service.dart';
import '../theme/ivory_theme.dart';

/// ============================================================
/// IVORY - THE POLL, PLAIN AND HONEST
///
/// Text, options, percentages. Members see only the percentage;
/// the house sees the counts and exactly who voted for what.
/// ============================================================
String _clean(String title) => title.replaceFirst('[SAMPLE] ', '');

class PollBody extends StatefulWidget {
  const PollBody({required this.post});

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
    final int total =
        _options.fold<int>(0, (int s, PollOption o) => s + o.votes);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const IvoryEyebrow('Your vote counts', icon: Icons.how_to_vote),
        const SizedBox(height: 10),
        Text(_clean(widget.post.title),
            style: Theme.of(context).textTheme.headlineMedium),
        if (widget.post.summary != null) ...<Widget>[
          const SizedBox(height: 9),
          Text(widget.post.summary!,
              style: Theme.of(context).textTheme.bodyMedium),
        ],
        const SizedBox(height: 22),
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(30),
              child: CircularProgressIndicator(color: IvoryColors.amber),
            ),
          )
        else
          ..._options.map((PollOption o) {
            final bool mine = _myVote == o.id;
            final int pct =
                total == 0 ? 0 : (o.votes * 100 / total).round();
            final List<String> voters = _voters[o.id] ?? <String>[];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _vote(o.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: mine
                          ? IvoryColors.gold
                          : IvoryColors.hairlineStrong,
                      width: mine ? 1.6 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            mine ? '\u2713  ' : '\u2022  ',
                            style: const TextStyle(
                              color: IvoryColors.burgundy,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              o.label,
                              style: TextStyle(
                                color: mine
                                    ? IvoryColors.burgundy
                                    : IvoryColors.textSoft,
                                fontSize: 14.5,
                                fontWeight:
                                    mine ? FontWeight.w800 : FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _house ? '${o.votes}  \u00b7  $pct%' : '$pct%',
                            style: const TextStyle(
                              color: IvoryColors.burgundy,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      if (_house && voters.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6, left: 22),
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
                  ),
                ),
              ),
            );
          }),
        if (_house) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            total == 1 ? '1 vote' : '$total votes',
            style: TextStyle(fontSize: 12.5, color: IvoryColors.textFaint),
          ),
        ],
      ],
    );
  }
}


// END OF FILE - lib/widgets/post_poll.dart
