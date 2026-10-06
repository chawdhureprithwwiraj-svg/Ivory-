import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';

/// ============================================================
/// IVORY - THE POLL, THE WAY A POLL SHOULD LOOK
///
/// SPRINT 24g. One home for the poll's appearance, used by both
/// the home-feed card and the post detail sheet, so the two can
/// never drift apart.
///
/// The shape is the one every member already knows from YouTube
/// and Facebook: the option's words on the left, its percentage
/// on the right, and a coloured bar lying behind both, running
/// from the left edge out to exactly that percentage. The
/// longest bar is the winner - no arithmetic required.
///
/// Only the colours are ours. Where YouTube uses grey and
/// Facebook uses blue, Ivory uses amber and gold. Nothing here
/// is black, grey or charcoal; the darkest tone is burgundy.
/// ============================================================

/// The deep end of the bar, where it starts at the left edge.
const Color _fillStart = Color(0xFFE8B978);

/// The pale end, where it fades out before its gold stop line.
const Color _fillEnd = Color(0xFFF2DCA8);

/// The front runner is poured a shade deeper so it reads first.
const Color _leadStart = IvoryColors.amber;
const Color _leadEnd = Color(0xFFEFC97E);

/// The little gold capsule that says, unmistakably, POLL.
class PollBadge extends StatelessWidget {
  const PollBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(
          colors: <Color>[IvoryColors.gold, IvoryColors.amber],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.how_to_vote_rounded,
              size: 13, color: IvoryColors.burgundy),
          SizedBox(width: 5),
          Text(
            'POLL',
            style: TextStyle(
              color: IvoryColors.burgundy,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// One option: a tappable row with the result painted behind it.
class PollOptionBar extends StatelessWidget {
  const PollOptionBar({
    super.key,
    required this.label,
    required this.percent,
    required this.revealed,
    this.votes,
    this.mine = false,
    this.lead = false,
    this.compact = false,
    this.onTap,
  });

  /// The option's own words.
  final String label;

  /// 0 to 100. Only drawn once [revealed] is true.
  final int percent;

  /// Before a member votes there is no bar and no number - showing
  /// early results would nudge the answer.
  final bool revealed;

  /// The exact count. The house passes this; members never do.
  final int? votes;

  /// This is the option the member themselves chose.
  final bool mine;

  /// This option is currently in front.
  final bool lead;

  /// Tighter spacing for the home-feed card.
  final bool compact;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(13);

    // The bar may be zero wide. A zero-width box with a right-hand
    // border would still paint a stray gold line against the left
    // edge, so the stop line only appears once there is a bar.
    final double factor = revealed ? (percent.clamp(0, 100)) / 100.0 : 0.0;
    final bool hasBar = factor > 0.004;

    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 7 : 9),
      child: Material(
        color: IvoryColors.surface,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: mine
                    ? IvoryColors.plum
                    : IvoryColors.gold.withValues(alpha: 0.5),
                width: mine ? 2 : 1.3,
              ),
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: Stack(
                children: <Widget>[
                  // ---- the result, lying behind the words ----
                  // Full height of the row, anchored to the left edge,
                  // its width the vote share and nothing else.
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedFractionallySizedBox(
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutCubic,
                        widthFactor: factor,
                        heightFactor: 1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: lead
                                  ? const <Color>[_leadStart, _leadEnd]
                                  : const <Color>[_fillStart, _fillEnd],
                            ),
                            border: hasBar
                                ? const Border(
                                    right: BorderSide(
                                      color: IvoryColors.gold,
                                      width: 2.5,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ---- the words, always on top of the bar ----
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 13 : 15,
                      vertical: compact ? 11 : 14,
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            label,
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              color: IvoryColors.burgundy,
                              fontSize: compact ? 13.5 : 14.5,
                              height: 1.3,
                              fontWeight: (mine || lead)
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                        if (mine) ...<Widget>[
                          const SizedBox(width: 7),
                          const Text(
                            'YOUR ANSWER',
                            style: TextStyle(
                              color: IvoryColors.plum,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                        if (revealed) ...<Widget>[
                          const SizedBox(width: 10),
                          Text(
                            votes == null ? '$percent%' : '$votes \u00b7 $percent%',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: IvoryColors.plum,
                              fontSize: compact ? 13 : 14,
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
        ),
      ),
    );
  }
}

/// The quiet line under the options.
class PollTally extends StatelessWidget {
  const PollTally({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: IvoryColors.gold,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: IvoryColors.textFaint,
            ),
          ),
        ),
      ],
    );
  }
}

/// Turns raw counts into the percentages and the front runner.
/// Kept here so the card and the sheet can never disagree.
class PollMaths {
  const PollMaths(this.total, this.percents, this.best);

  final int total;
  final Map<int, int> percents;
  final int best;

  factory PollMaths.of(Map<int, int> votesByOptionId) {
    int total = 0;
    votesByOptionId.forEach((int _, int v) => total += v);
    final Map<int, int> pct = <int, int>{};
    int best = 0;
    votesByOptionId.forEach((int id, int v) {
      final int p = total == 0 ? 0 : (v * 100 / total).round();
      pct[id] = p;
      if (p > best) best = p;
    });
    return PollMaths(total, pct, best);
  }

  String get tally => total == 1
      ? '1 member has answered'
      : '$total members have answered';
}

// END OF FILE - lib/widgets/poll_bars.dart
