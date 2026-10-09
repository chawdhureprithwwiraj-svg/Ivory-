import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';

/// ============================================================
/// IVORY - THE TWO GIFT SETS. READ THIS BEFORE TOUCHING GIFTS.
///
/// THIS FILE IS THE ONLY PLACE EITHER SET IS DEFINED. If you
/// are adding a screen, a label, a colour or a rule about
/// gifts, it goes here and the screen reads it from here. The
/// moment a second file writes the string 'post' or decides
/// its own colour for a tag, the two sets begin to drift, and
/// drift is how the first version of this feature went wrong.
///
/// ------------------------------------------------------------
/// THERE ARE EXACTLY TWO SETS, AND THEY ARE NOT
/// INTERCHANGEABLE.
/// ------------------------------------------------------------
///
/// GiftSurface.live - A LIVE GIFT IS SOMETHING IVORY DOES.
///   Sent while she is on air and she is present to receive
///   it. "Dance for me." "Sing something." It is a request
///   made of a person who is in the room, and it is answered
///   in the moment.
///   Carried on `gift_sends.session_id`.
///
/// GiftSurface.post - A POST GIFT DESCRIBES WHAT THE POST DID
/// TO THE MEMBER.
///   She is not there. Nobody can perform anything. So a post
///   gift never asks for an act - it reports an effect.
///   "Goosebumps." "Up All Night."
///   Carried on `gift_sends.post_id`.
///
/// ------------------------------------------------------------
/// THE TEST EVERY POST GIFT MUST PASS (the owner's own rule).
/// ------------------------------------------------------------
/// A post can be ANY medium - a film, a photograph, a makeup
/// video, a voice note, a song, a blog, a story. So a post
/// gift must never describe the medium.
///
///   Could this name sit under a lipstick swatch AND under a
///   short film without being odd?
///
/// If not, it is not a post gift. The first attempt at this
/// set failed exactly here: it assumed storytelling, and every
/// name fell apart against a photograph.
///
/// ------------------------------------------------------------
/// THE WORDS. THEY MAY NEVER CROSS.
/// ------------------------------------------------------------
/// live -> "ON AIR", "FOR THE ROOM"     (gold)
/// post -> "ON A POST", "FOR THIS POST" (plum)
///
/// And neither may borrow the SESSION vocabulary. A CALL is a
/// third thing entirely - two people, video or audio, with
/// timers, waiting, rejoining, extensions and minutes - and
/// A CALL HAS NO GIFTS AT ALL. If you find yourself writing
/// "session" near a gift, you have taken a wrong turn.
///
/// ------------------------------------------------------------
/// WHAT IS SHARED, AND WHAT IS DELIBERATELY NOT.
/// ------------------------------------------------------------
/// SHARED, and must stay shared - there is ONE send path:
///   `send_gift`, `attach_gift_utr`, `confirm_gift`, the UPI
///   reference, the amount, the pending/confirmed states and
///   the owner's received list. A gift is a gift once money is
///   involved. Never fork the payment path.
///
/// NOT SHARED, and must stay separate:
///   - the catalogue: `gifts.surface` is 'live' or 'post', and
///     `LiveService.gifts(surface:)` returns ONE set, never
///     both;
///   - the artwork: post gifts play fifteen-second drawn
///     scenes, live gifts show a plain emblem, because the
///     live set was never designed to be animated;
///   - the public wall: ONLY post gifts show the gifter's
///     name on the post. A live gift is already seen by
///     everyone in the room as it happens.
///
/// ------------------------------------------------------------
/// IF YOU ARE ADDING A THIRD SURFACE
/// ------------------------------------------------------------
/// Add it here, add its value to the `gifts.surface` check
/// constraint in SQL, and the whole app follows. Do not add it
/// by writing a new string somewhere.
/// ============================================================
enum GiftSurface {
  live,
  post;

  /// The value stored in `gifts.surface` and the only string
  /// that should ever be compared against the database.
  String get db => this == GiftSurface.post ? 'post' : 'live';

  /// A send belongs to a post if it carries a post id. This is
  /// the single rule for working out which set you are in -
  /// never re-derive it from anything else.
  static GiftSurface of({int? postId}) =>
      postId != null ? GiftSurface.post : GiftSurface.live;

  static GiftSurface fromDb(String? v) =>
      v == 'post' ? GiftSurface.post : GiftSurface.live;

  bool get isPost => this == GiftSurface.post;

  /// What the member sees above the catalogue.
  String get memberTag => isPost ? 'FOR THIS POST' : 'FOR THE ROOM';

  /// What Ivory sees beside a gift she has received.
  String get ownerTag => isPost ? 'ON A POST' : 'ON AIR';

  String get heading => isPost ? 'Tell me what it did' : 'Send me something';

  String get blurb => isPost
      ? 'These nine are different to the ones in the room. Each is '
          'something this post did to you. Pick the one that is true '
          'and I will know what you meant.'
      : 'These nine are things I do, here, while I am on air. It '
          'appears on my screen straight away.';

  /// Gold for the room, plum for a post. Used by every tag in
  /// the app so the colours can never disagree.
  Color get ink => isPost ? IvoryColors.plum : IvoryColors.burgundy;

  Color get edge =>
      isPost ? IvoryColors.plum.withValues(alpha: 0.45) : IvoryColors.gold;

  Color get wash => isPost
      ? IvoryColors.plum.withValues(alpha: 0.10)
      : IvoryColors.gold.withValues(alpha: 0.18);
}

/// The tag itself, built once. Both the member's sheet and the
/// owner's received list draw it from here, so they cannot
/// drift apart.
class GiftSurfaceTag extends StatelessWidget {
  const GiftSurfaceTag({
    super.key,
    required this.surface,
    this.owner = false,
  });

  final GiftSurface surface;

  /// True in Ivory's own list, false on the member's sheet.
  final bool owner;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: owner ? 7 : 8,
        vertical: owner ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: surface.wash,
        borderRadius: BorderRadius.circular(owner ? 7 : 8),
        border: Border.all(color: surface.edge),
      ),
      child: Text(
        owner ? surface.ownerTag : surface.memberTag,
        style: TextStyle(
          fontSize: owner ? 9.5 : 10,
          fontWeight: FontWeight.w900,
          letterSpacing: owner ? 0.7 : 0.8,
          color: surface.ink,
        ),
      ),
    );
  }
}

// END OF FILE - lib/models/gift_surface.dart
