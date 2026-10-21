import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';

/// ============================================================
/// IVORY - THE POLL, THE WAY A POLL SHOULD LOOK
///
/// One home for the poll's appearance, used by the home-feed card and
/// the post sheet so the two never drift apart: the option's words on
/// the left, its percentage on the right, a coloured bar behind both.
/// CC.175 polish: glassy bars with a lit gold stop line, a count-up
/// that matches the bar, a star and slow sheen on the leader, a glowing
/// tick and YOUR ANSWER line on the member's choice, and a ring on every
/// option until the member answers. Voting and numbers are unchanged.
/// Nothing here is black or grey; the darkest tone is burgundy.
/// ============================================================

/// The deep end of the bar, where it starts at the left edge.
const Color _fillStart = Color(0xFF6B1527);

/// The lighter wine the bar fades towards before its gold stop line.
const Color _fillEnd = Color(0xFF96344A);

/// The option in front sits deeper, so the lead reads at a glance.
const Color _leadStart = IvoryColors.burgundy;
const Color _leadEnd = Color(0xFF72203A);

/// Words printed over the filled part of the bar. Burgundy on burgundy
/// is invisible, so everything inside the fill is painted again in
/// ivory and clipped to exactly the bar's edge.
const Color _onFill = IvoryColors.ivory;
const Color _onFillSoft = IvoryColors.gold;

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
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: IvoryColors.amber.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.how_to_vote_rounded, size: 13, color: IvoryColors.burgundy),
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
class PollOptionBar extends StatefulWidget {
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
  State<PollOptionBar> createState() => _PollOptionBarState();
}

class _PollOptionBarState extends State<PollOptionBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sheen = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  );
  bool _down = false;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(PollOptionBar old) {
    super.didUpdateWidget(old);
    _sync();
  }

  /// The slow sheen runs only on the option in front, once results show.
  void _sync() {
    final bool want = widget.lead && widget.revealed;
    if (want && !_sheen.isAnimating) {
      _sheen.repeat();
    } else if (!want && _sheen.isAnimating) {
      _sheen.stop();
    }
  }

  @override
  void dispose() {
    _sheen.dispose();
    super.dispose();
  }

  Widget _mark(Color accent) {
    if (!widget.revealed) {
      return Padding(
        padding: const EdgeInsets.only(right: 11),
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: accent.withValues(alpha: 0.55), width: 1.7),
          ),
        ),
      );
    }
    if (widget.mine) {
      return Padding(
        padding: const EdgeInsets.only(right: 9),
        child: Icon(Icons.check_circle_rounded, size: 19, color: accent),
      );
    }
    return const SizedBox.shrink();
  }

  /// One row of words. Drawn twice: once in burgundy for the cream
  /// part of the bar, once in ivory for the filled part. Both use the
  /// identical layout, so the two copies line up glyph for glyph and
  /// the colour appears to change exactly at the bar's edge. [f] is how
  /// far the bar has filled, so the number counts up with it.
  Widget _words(Color ink, Color accent, double f) {
    final bool compact = widget.compact;
    final int shown = widget.revealed
        ? (f * 100).round().clamp(0, 100).toInt()
        : 0;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 13 : 15,
        vertical: compact ? 11 : 14,
      ),
      child: Row(
        children: <Widget>[
          _mark(accent),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  widget.label,
                  textAlign: TextAlign.left,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ink,
                    fontSize: compact ? 13.5 : 14.5,
                    height: 1.3,
                    fontWeight: (widget.mine || widget.lead)
                        ? FontWeight.w800
                        : FontWeight.w600,
                  ),
                ),
                if (widget.mine) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    'YOUR ANSWER',
                    style: TextStyle(
                      color: accent,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (widget.revealed) ...<Widget>[
            const SizedBox(width: 10),
            if (widget.lead) ...<Widget>[
              Icon(Icons.star_rounded, size: 15, color: accent),
              const SizedBox(width: 3),
            ],
            Text(
              widget.votes == null
                  ? '$shown%'
                  : '${widget.votes} \u00b7 $shown%',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: accent,
                fontSize: compact ? 13 : 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// The filled part: wine glass with a gloss, a sheen (the leader only)
  /// and a lit gold stop line.
  Widget _fill() {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.lead
                  ? const <Color>[_leadStart, _leadEnd]
                  : const <Color>[_fillStart, _fillEnd],
            ),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Color(0x40FFFFFF),
                Color(0x0DFFFFFF),
                Color(0x00FFFFFF),
              ],
              stops: <double>[0, 0.5, 1],
            ),
          ),
        ),
        if (widget.lead)
          AnimatedBuilder(
            animation: _sheen,
            builder: (BuildContext c, Widget? _) {
              final double p = (_sheen.value / 0.55).clamp(0.0, 1.0).toDouble();
              return Align(
                alignment: Alignment(-1.9 + 3.8 * p, 0),
                child: const FractionallySizedBox(
                  widthFactor: 0.22,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[
                          Color(0x00FFFFFF),
                          Color(0x4DFFFFFF),
                          Color(0x00FFFFFF),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: 2.5,
            height: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: IvoryColors.gold,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: IvoryColors.gold.withValues(alpha: 0.75),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(13);
    final double factor = widget.revealed
        ? (widget.percent.clamp(0, 100)) / 100.0
        : 0.0;

    return Padding(
      padding: EdgeInsets.only(bottom: widget.compact ? 7 : 9),
      child: AnimatedScale(
        scale: _down ? 0.985 : 1,
        duration: const Duration(milliseconds: 110),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: <BoxShadow>[
              widget.mine
                  ? BoxShadow(
                      color: IvoryColors.amber.withValues(alpha: 0.4),
                      blurRadius: 12,
                    )
                  : BoxShadow(
                      color: IvoryColors.burgundy.withValues(alpha: 0.07),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
            ],
          ),
          child: Material(
            color: IvoryColors.surface,
            borderRadius: radius,
            child: InkWell(
              borderRadius: radius,
              onTap: widget.onTap,
              onHighlightChanged: (bool v) {
                if (mounted) setState(() => _down = v);
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(
                    // Plum on a burgundy bar would vanish, so the member's
                    // own answer is ringed in amber instead.
                    color: widget.mine
                        ? IvoryColors.amber
                        : IvoryColors.gold.withValues(alpha: 0.5),
                    width: widget.mine ? 2.2 : 1.3,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: radius,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: factor),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (BuildContext c, double f, Widget? _) {
                      final bool hasBar = f > 0.004;
                      return Stack(
                        children: <Widget>[
                          if (hasBar)
                            Positioned.fill(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: f,
                                  heightFactor: 1,
                                  child: _fill(),
                                ),
                              ),
                            ),
                          _words(IvoryColors.burgundy, IvoryColors.plum, f),
                          if (hasBar)
                            Positioned.fill(
                              child: ClipRect(
                                clipper: _LeftFraction(f),
                                child: _words(_onFill, _onFillSoft, f),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Keeps only the left-hand [fraction] of the row, so the ivory copy of
/// the words shows exactly where the wine does and nowhere else.
class _LeftFraction extends CustomClipper<Rect> {
  const _LeftFraction(this.fraction);

  final double fraction;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * fraction, size.height);

  @override
  bool shouldReclip(_LeftFraction old) => old.fraction != fraction;
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
          decoration: BoxDecoration(
            color: IvoryColors.gold,
            shape: BoxShape.circle,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: IvoryColors.gold.withValues(alpha: 0.6),
                blurRadius: 5,
              ),
            ],
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
