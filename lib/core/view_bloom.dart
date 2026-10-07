/// ============================================================
/// HOW MANY PEOPLE A POST LOOKS LIKE IT REACHED
/// ============================================================
/// A brand new sanctuary shows "2 views" on every post, and that tells
/// a visiting member one thing very loudly: nobody is here. This file
/// gives each post a seeded audience that starts near 200 and grows,
/// slowly and unevenly, to somewhere between 2,300 and 3,000 over
/// about three weeks. Real views are added on top, so genuine reading
/// still counts for something.
///
/// WHAT MATTERS, IN ORDER
///
/// 1. **It can never go backwards.** The number is a pure calculation
///    from the post's id and the moment it was published - nothing is
///    stored, nothing is random at runtime. The same post on the same
///    hour gives the same answer on every phone, forever. A count that
///    dropped from 1,900 to 1,400 on a refresh would be noticed
///    instantly.
/// 2. **No two posts behave alike.** Each one gets its own ceiling,
///    its own pace, and its own day-to-day rhythm, all derived from
///    its id. A quiet post published three weeks ago can sit below a
///    popular one published last Tuesday - which is exactly what
///    happens with real posts, and is the single hardest thing to fake
///    by accident.
/// 3. **Nothing lands on a round number.** 1,847, not 1,800.
///
/// WHERE IT APPLIES
/// Films, voice notes, stories and photographs. **Polls never get
/// one** - their bars report real votes, and a seeded total would be
/// describing votes nobody cast.
///
/// **The Admin Library deliberately does not use this.** There you see
/// the true `view_count`, because you must never be misled about your
/// own reach by your own decoration.
library;

import '../models/ivory_post.dart';

/// Deterministic noise. Not cryptography - just a cheap, stable way to
/// turn (post id, salt) into a repeatable number. Integer maths only,
/// so an old phone does not feel it.
int _noise(int id, int salt) {
  int h = (id * 2654435761) ^ (salt * 40503 + 0x9E3779B9);
  h ^= (h >> 13);
  // Trimmed before the second multiply so the result can never run off
  // the end of a 64-bit integer. Overflow would still be deterministic,
  // but it would be deterministic in a way nobody could reason about.
  h &= 0x3FFFFFFF;
  h = (h * 1274126177) & 0x3FFFFFFF;
  h ^= (h >> 11);
  return h & 0x3FFFFFFF;
}

/// A stable fraction in 0.0 - 1.0 for this post and this salt.
double _frac(int id, int salt) => (_noise(id, salt) % 10000) / 10000.0;

/// The post's own ceiling: 2,300 - 2,950, and a **hard** maximum. The
/// post approaches it and never passes it, however old it gets.
/// Varying it is what stops a member scrolling a year of posts and
/// noticing they all stop at the same number.
int _ceilingFor(int id) => 2300 + _noise(id, 7) % 651;

/// How many days the climb takes: 15 - 19. Kept in a narrow band on
/// purpose - stretch it to 26 days and the daily movement thins out to
/// fifty or sixty, which reads as a dying post rather than a quiet one.
int _peakDaysFor(int id) => 15 + _noise(id, 13) % 5;

/// The climb stops a little short of the ceiling and the remainder is
/// left to the slow drift afterwards, so nothing ever slams into a
/// round stop.
const double _climbShare = 0.94;

/// Where it starts in its first hour, and where the first hour ends.
int _seedFor(int id) => 28 + _noise(id, 23) % 26; //  28 -  53
int _hourOneFor(int id) => 186 + _noise(id, 31) % 44; // 186 - 229

/// The weight of a single day. Real attention is lumpy: some days a
/// post is shared and jumps, most days it trickles. These weights are
/// normalised below, so their scale does not matter - only their
/// unevenness relative to each other does.
double _dayWeight(int id, int day) {
  final double base = 0.74 + _frac(id, 100 + day) * 0.70; // 0.74 - 1.44
  // The first two days run a little hotter, the way a real post does
  // while it is still near the top of the feed. Only a little: a big
  // opening spike forces every later day down to compensate, and a
  // long tail of tiny days is more obviously generated than a calm
  // start is.
  if (day <= 2) return base * 1.18;
  return base;
}

/// Results are cached per post per hour. A feed card rebuilds on every
/// scroll frame, and there is no reason to re-run the loop until the
/// hour actually changes.
final Map<int, int> _cache = <int, int>{};
int _cacheHour = -1;

/// The number to show a member for this post, real views included.
/// Returns null when nothing should be shown at all - polls, and posts
/// with no publish date.
int? viewBloom(IvoryPost post) {
  if (post.type == PostType.poll) return null;
  final DateTime? created = post.createdAt;
  if (created == null) return null;

  final DateTime now = DateTime.now();
  final int hoursTotal = now.difference(created).inHours;

  // A clock skew, or a post dated in the future, must not produce a
  // negative age and a nonsense number.
  if (hoursTotal < 0) return post.viewCount > 0 ? post.viewCount : null;

  final int hourKey = now.millisecondsSinceEpoch ~/ 3600000;
  if (hourKey != _cacheHour) {
    _cache.clear();
    _cacheHour = hourKey;
  }
  final int? hit = _cache[post.id];
  if (hit != null) return hit + post.viewCount;

  final int seeded = _seededAt(post.id, created, now);
  _cache[post.id] = seeded;
  return seeded + post.viewCount;
}

int _seededAt(int id, DateTime created, DateTime now) {
  final int ceiling = _ceilingFor(id);
  final int peakDays = _peakDaysFor(id);
  final int seed = _seedFor(id);
  final int hourOne = _hourOneFor(id);

  final int minutes = now.difference(created).inMinutes;

  // --- The first hour: climb from a standing start to about 200. ---
  if (minutes < 60) {
    final double t = minutes <= 0 ? 0.0 : minutes / 60.0;
    return seed + ((hourOne - seed) * t).round();
  }

  final double days = minutes / 1440.0;

  // --- Past the peak: a slow trickle into the last few percent. ---
  // A number frozen to the digit for months is its own kind of tell,
  // so it keeps moving - but it closes on the ceiling and stops there.
  // The ceiling is a promise: nothing ever shows more than this.
  if (days >= peakDays) {
    final int settled = (ceiling * _climbShare).round();
    final double over = days - peakDays;
    final double drift = 3.0 + _frac(id, 57) * 9.0; // 3 - 12 a day
    final int v = settled + (over * drift).round();
    return v > ceiling ? ceiling : v;
  }

  // --- The climb. Lay out every day's weight, then walk the days. ---
  double total = 0;
  for (int d = 1; d <= peakDays; d++) {
    total += _dayWeight(id, d);
  }

  final int room = (ceiling * _climbShare).round() - hourOne;
  final int wholeDays = days.floor();
  final double partDay = days - wholeDays;

  double done = 0;
  for (int d = 1; d <= wholeDays; d++) {
    done += _dayWeight(id, d);
  }
  // Today's share is folded in by the fraction of the day elapsed, so
  // the number creeps through the day instead of lurching at midnight.
  done += _dayWeight(id, wholeDays + 1) * partDay;

  return hourOne + (room * (done / total)).round();
}

// END OF FILE - lib/core/view_bloom.dart
