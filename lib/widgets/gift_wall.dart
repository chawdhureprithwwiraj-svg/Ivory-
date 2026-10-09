import 'package:flutter/material.dart';

import '../models/live_models.dart';
import '../services/gift_service.dart';
import '../services/live_service.dart';
import '../theme/ivory_theme.dart';

/// ============================================================
/// IVORY - THE WALL. WHO GIFTED ON THIS POST.
///
/// Names on the post, in order of generosity, with the largest
/// gift standing at the top.
///
/// ------------------------------------------------------------
/// WHY THIS IS SOCIAL PROOF AND NOT A DARK PATTERN
/// ------------------------------------------------------------
/// The pull here is real and it is allowed to be: a member
/// sees another member's name, in gold, above their own, and
/// wants to be there. That is the oldest and most honest
/// mechanism there is.
///
/// What makes it honest is that EVERY NAME ON THIS WALL IS A
/// REAL PERSON WHO REALLY PAID. `post_gifters` returns
/// CONFIRMED sends only. Nothing here is seeded, padded,
/// rounded up or invented, and there is no counter saying how
/// many people are "looking right now".
///
/// This is not caution for its own sake. India's Guidelines
/// for the Prevention and Regulation of Dark Patterns, 2023,
/// are mandatory, and their very first named pattern is False
/// Urgency - whose official illustration is "falsely showing
/// high popularity of a product". A manufactured number here
/// would be the textbook case. A true one is not.
///
/// **SO THE RULE FOR ANYONE WHO TOUCHES THIS FILE: you may
/// make the wall more beautiful, larger, louder or more
/// tempting. You may never make it say anything that is not
/// literally true.**
///
/// ------------------------------------------------------------
/// THE EMPTY STATE IS THE MOST VALUABLE STATE
/// ------------------------------------------------------------
/// A post with no gifts yet does not hide the wall - it offers
/// the thing nobody can ever have twice: being FIRST. That is
/// a true statement, it costs nothing, and it is the strongest
/// line on the whole surface.
/// ============================================================

/// Bumped after a gift is sent so every wall on screen looks
/// again. Same shape as the post-refresh contract in
/// `content_revision.dart` - a screen listens, and removes its
/// listener in dispose.
final ValueNotifier<int> giftWallRevision = ValueNotifier<int>(0);

class GiftWall extends StatefulWidget {
  const GiftWall({super.key, required this.postId});

  final int postId;

  @override
  State<GiftWall> createState() => _GiftWallState();
}

class _GiftWallState extends State<GiftWall> {
  List<PostGifter> _rows = <PostGifter>[];
  bool _done = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    giftWallRevision.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    giftWallRevision.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final List<PostGifter> r =
          await LiveService.instance.postGifters(widget.postId);
      if (!mounted) return;
      setState(() {
        _rows = r;
        _failed = false;
        _done = true;
      });
    } catch (_) {
      // THIS USED TO BE SILENT, AND THAT WAS A REAL FAULT.
      // It showed the friendly "be the first" card no matter
      // what had gone wrong, so a wall whose database function
      // was missing looked EXACTLY like a wall nobody had
      // gifted on. The owner had to notice and report it
      // herself before anyone could even ask which it was.
      //
      // A failure and an emptiness are not the same thing and
      // must never render the same way.
      if (!mounted) return;
      setState(() {
        _failed = true;
        _done = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Until the answer arrives, show nothing at all rather than
    // a spinner. A loading flicker under every post in the feed
    // would be worse than a moment of patience.
    if (!_done) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: _failed
          ? _unreachable()
          : (_rows.isEmpty ? _empty() : _wall()),
    );
  }

  /// We could not ask. Say so plainly and claim nothing about
  /// who has or has not gifted. A LINE, not a card - it states
  /// a fact and offers no decision.
  Widget _unreachable() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        'The names on this post could not be loaded just now.',
        style: TextStyle(
          fontSize: 12.3,
          fontStyle: FontStyle.italic,
          color: IvoryColors.textFaint,
        ),
      ),
    );
  }

  /// Nobody has gifted yet. The offer is to be first.
  Widget _empty() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: IvoryColors.surfaceWarm,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: IvoryColors.hairline),
      ),
      child: Row(
        children: <Widget>[
          const SizedBox(
            width: 20,
            height: 20,
            child: CustomPaint(painter: _CrownPainter(faded: true)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'No name on this one yet. The first is the only one '
              'nobody can take back.',
              style: TextStyle(
                fontSize: 12.3,
                height: 1.35,
                color: IvoryColors.textSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _wall() {
    final PostGifter top = _rows.first;
    final List<PostGifter> rest = _rows.skip(1).toList();
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[IvoryColors.cream, IvoryColors.surfaceWarm],
        ),
        border: Border.all(color: IvoryColors.gold, width: 1.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // The heading is a LINE, not a card. It states a fact.
          Row(
            children: <Widget>[
              Text(
                'GIFTED BY',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.3,
                  color: IvoryColors.gold.withValues(alpha: 0.95),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 1,
                  color: IvoryColors.gold.withValues(alpha: 0.35),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // THE TOP NAME. The whole point of the wall is that
          // one person is above everyone else, visibly, and
          // that the position is purchasable by anyone.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SizedBox(
                width: 26,
                height: 26,
                child: CustomPaint(painter: _CrownPainter()),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            top.sender,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              height: 1.15,
                              color: IvoryColors.burgundy,
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        // THE TITLE, BESIDE THE NAME.
                        //
                        // The crown says "someone is first"; it
                        // does not say WHAT first means. A
                        // stranger reading the post should not
                        // have to work it out. So the position
                        // is named, in gold, right beside the
                        // person holding it.
                        //
                        // IT APPEARS EVEN WHEN ONLY ONE PERSON
                        // HAS GIVEN. Being the only name is not
                        // a lesser thing - it is the whole of
                        // the wall - and a title that waits for
                        // a crowd would insult the first giver,
                        // who took the biggest risk of all.
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: <Color>[
                                IvoryColors.gold,
                                IvoryColors.amber,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'TOP GIFTER',
                            style: TextStyle(
                              fontSize: 8.6,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.9,
                              color: IvoryColors.burgundy,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${top.giftName}  \u00B7  Rs.${top.amountInr}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.8,
                        fontWeight: FontWeight.w700,
                        color: IvoryColors.plum.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // THE LINE THEY WROTE, AND ONLY THE TOP ONE'S.
          //
          // Twelve quotations would be a comment section, and
          // nobody asked for a comment section. ONE is a
          // dedication. It also gives the top of the wall a
          // reward that is not simply a larger number: the
          // person at the top is the one whose WORDS everybody
          // reads. That is a better reason to give than a
          // leaderboard.
          //
          // It is here at all only because she confirmed the
          // gift. The database will not hand over a line from
          // an unconfirmed send, and it returns null for one
          // she has taken down - so there is no such thing on
          // this wall as a line she has not seen first.
          if (top.note != null) ...<Widget>[
            const SizedBox(height: 11),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: IvoryColors.surface.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(12),
                border: Border(
                  left: BorderSide(color: IvoryColors.gold, width: 2.4),
                  top: BorderSide(color: IvoryColors.hairline),
                  right: BorderSide(color: IvoryColors.hairline),
                  bottom: BorderSide(color: IvoryColors.hairline),
                ),
              ),
              child: Text(
                '\u201C${top.note}\u201D',
                style: const TextStyle(
                  fontSize: 13.2,
                  height: 1.45,
                  fontStyle: FontStyle.italic,
                  color: IvoryColors.burgundy,
                ),
              ),
            ),
          ],

          if (rest.isNotEmpty) ...<Widget>[
            const SizedBox(height: 11),
            // Everyone else, in order, as gold chips. Being in
            // this row is pleasant. Being above it is better,
            // and that gap is the entire design.
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: rest.map(_chip).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(PostGifter g) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: IvoryColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: IvoryColors.gold.withValues(alpha: 0.55)),
      ),
      child: Text(
        '${g.sender}  \u00B7  Rs.${g.amountInr}',
        style: const TextStyle(
          fontSize: 11.3,
          fontWeight: FontWeight.w800,
          color: IvoryColors.plum,
        ),
      ),
    );
  }
}

/// A small drawn crown. Five points, a band, three gold studs.
/// Drawn rather than an emoji, for the same reason the gift
/// scenes are drawn: a borrowed picture in somebody else's
/// colours does not belong beside a paid name.
class _CrownPainter extends CustomPainter {
  const _CrownPainter({this.faded = false});

  final bool faded;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double a = faded ? 0.38 : 1.0;

    final Path p = Path()
      ..moveTo(w * 0.08, h * 0.74)
      ..lineTo(w * 0.08, h * 0.34)
      ..lineTo(w * 0.29, h * 0.54)
      ..lineTo(w * 0.50, h * 0.20)
      ..lineTo(w * 0.71, h * 0.54)
      ..lineTo(w * 0.92, h * 0.34)
      ..lineTo(w * 0.92, h * 0.74)
      ..close();

    canvas.drawPath(
      p,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            IvoryColors.amber.withValues(alpha: a),
            IvoryColors.gold.withValues(alpha: a),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.045
        ..color = IvoryColors.burgundy.withValues(alpha: 0.55 * a),
    );

    // The band.
    canvas.drawRect(
      Rect.fromLTWH(w * 0.08, h * 0.74, w * 0.84, h * 0.13),
      Paint()..color = IvoryColors.burgundy.withValues(alpha: 0.78 * a),
    );

    // Three studs along the band.
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(w * (0.27 + i * 0.23), h * 0.805),
        w * 0.045,
        Paint()..color = IvoryColors.cream.withValues(alpha: a),
      );
    }
  }

  @override
  bool shouldRepaint(_CrownPainter old) => old.faded != faded;
}

// END OF FILE - lib/widgets/gift_wall.dart
