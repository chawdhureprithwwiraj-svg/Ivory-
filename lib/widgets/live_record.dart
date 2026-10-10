import 'package:flutter/material.dart';

import '../models/live_night.dart';
import '../services/live_service.dart';
import '../theme/ivory_theme.dart';
import 'ivory_sheen.dart';

/// ============================================================
/// IVORY - EVERY TIME I HAVE BEEN THERE.
///
/// The permanent record of her broadcasts, just below the home
/// hero and before the stories, where it is easy to find.
///
/// THE COLOUR CARRIES THE MEANING. **GOLD IS ON AIR NOW,
/// EMERALD IS THE RECORD.** Warm for happening, cool for
/// finished and kept. A member learns that in a second without
/// reading a word, and it must never be reversed.
///
/// THE TITLE IS HERS, WORD FOR WORD. "EVERY TIME I HAVE BEEN
/// THERE". **The phrase "night on air" is forbidden** - she
/// ruled it out explicitly.
///
/// NOTHING HERE IS INVENTED. Real minutes from the real start
/// and end. Real attendance, counted from people actually in
/// the room. And where Ivory does not know - every night before
/// this sprint existed, because attendance was never recorded -
/// **it says nothing at all rather than guessing.** A member who
/// watched in silence left no trace, and telling them they
/// missed a night they watched would be a lie.
/// ============================================================
class LiveRecord extends StatefulWidget {
  const LiveRecord({super.key});

  @override
  State<LiveRecord> createState() => _LiveRecordState();
}

class _LiveRecordState extends State<LiveRecord> {
  List<LiveNight> _nights = <LiveNight>[];
  bool _done = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final List<LiveNight> r = await LiveService.instance.liveRecord();
      if (!mounted) return;
      setState(() {
        _nights = r;
        _failed = false;
        _done = true;
      });
    } catch (_) {
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
    if (!_done) return const SizedBox.shrink();
    if (_failed) {
      return Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        decoration: BoxDecoration(
          color: IvoryColors.surfaceWarm,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: IvoryColors.gold.withValues(alpha: 0.7)),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Her broadcast record could not load just now.',
                style: TextStyle(
                  fontSize: 12.3,
                  fontStyle: FontStyle.italic,
                  color: IvoryColors.textSoft,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('RETRY'),
              style: TextButton.styleFrom(
                foregroundColor: IvoryColors.burgundy,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ],
        ),
      );
    }
    // She has never finished a broadcast yet. Say nothing at
    // all - an empty trophy case is worse than no trophy case.
    if (_nights.isEmpty) return const SizedBox.shrink();

    return IvorySheen(
      child: (double t) => CustomPaint(
        painter: _RecordSkin(t),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _heading(),
              const SizedBox(height: 11),
              _rhythm(),
              const SizedBox(height: 13),
              ..._nights.take(14).map(_entry),
            ],
          ),
        ),
      ),
    );
  }

  // ---- the heading, and the only summary line ----
  Widget _heading() {
    final int counted = _nights.where((LiveNight n) => n.tracked).length;
    final int attended =
        _nights.where((LiveNight n) => n.tracked && n.youWereThere).length;
    final int totalMinutes = _nights.fold<int>(
        0, (int a, LiveNight n) => a + (n.minutes ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'EVERY TIME I HAVE BEEN THERE',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.25,
            color: IvoryColors.gold,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          <String>[
            '${_nights.length} ${_nights.length == 1 ? 'night' : 'nights'}',
            if (totalMinutes > 0) _span(totalMinutes),
            // Only claimed where the nights were actually
            // recorded. Never a count over nights Ivory cannot
            // speak about.
            if (counted > 0) 'you were there for $attended',
          ].join('  \u00B7  '),
          style: TextStyle(
            fontSize: 12.4,
            height: 1.4,
            color: IvoryColors.emeraldWash.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  // ---- fourteen nights, as a rhythm ----
  //
  // Not a chart. A chart invites comparison and argument; this
  // is a pulse, and all it says is "here is how often, and how
  // long". Height is the real length of the night.
  Widget _rhythm() {
    final List<LiveNight> strip = _nights.take(14).toList().reversed.toList();
    int longest = 1;
    for (final LiveNight n in strip) {
      if ((n.minutes ?? 0) > longest) longest = n.minutes ?? 1;
    }
    return SizedBox(
      height: 34,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          for (final LiveNight n in strip)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 3),
                child: Container(
                  height: 9 + 25 * ((n.minutes ?? 0) / longest),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: n.tracked && n.youWereThere
                        ? IvoryColors.gold
                        : IvoryColors.emeraldLight
                            .withValues(alpha: n.tracked ? 0.85 : 0.38),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---- one night ----
  Widget _entry(LiveNight n) {
    final String when = n.startedAt == null
        ? ''
        : _date(n.startedAt!.toLocal());
    return Padding(
      padding: const EdgeInsets.only(top: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.only(top: 6, right: 9),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: n.tracked && n.youWereThere
                  ? IvoryColors.gold
                  : IvoryColors.emeraldLight.withValues(alpha: 0.7),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  <String>[
                    when,
                    if (n.minutes != null && n.minutes! > 0) _span(n.minutes!),
                  ].join('  \u00B7  '),
                  style: const TextStyle(
                    fontSize: 12.8,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                    color: IvoryColors.cream,
                  ),
                ),
                // THE ONE PLACE A LIE COULD CREEP IN.
                // No attendance data for this night means no
                // sentence about attendance. Not a guess, not a
                // hedge, not "probably" - silence.
                if (n.tracked)
                  Text(
                    n.youWereThere
                        ? 'You were there'
                        : 'You missed this one',
                    style: TextStyle(
                      fontSize: 11.8,
                      fontStyle: FontStyle.italic,
                      height: 1.35,
                      color: n.youWereThere
                          ? IvoryColors.gold.withValues(alpha: 0.95)
                          : IvoryColors.emeraldWash.withValues(alpha: 0.62),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _span(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final int h = minutes ~/ 60;
    final int m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  static const List<String> _months = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _date(DateTime d) {
    final int hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final String mm = d.minute.toString().padLeft(2, '0');
    final String ap = d.hour < 12 ? 'AM' : 'PM';
    return '${d.day} ${_months[d.month - 1]}, $hour12:$mm $ap';
  }
}

/// The emerald ground, its gold border, and the light that
/// crosses both.
///
/// The border is painted here rather than set as a `Border` so
/// that the sheen can run over the gold as well as the green -
/// a band of light that stopped dead at the frame would look
/// like a mistake.
class _RecordSkin extends CustomPainter {
  const _RecordSkin(this.travel);

  final double travel;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect r = Offset.zero & size;
    final RRect body = RRect.fromRectAndRadius(
      r.deflate(1.1),
      const Radius.circular(18),
    );
    canvas.saveLayer(r, Paint());

    canvas.drawRRect(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            IvoryColors.emeraldMid,
            IvoryColors.emerald,
          ],
        ).createShader(r),
    );

    // The gold frame. Two passes: a soft wide one that reads as
    // the glow of metal, then the hairline itself on top.
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.4
        ..color = IvoryColors.gold.withValues(alpha: 0.22),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            IvoryColors.gold,
            IvoryColors.amber,
            IvoryColors.gold,
          ],
        ).createShader(r),
    );

    // Gentler than the gift marks: this is a large calm panel,
    // and a big surface flashing as hard as a small button
    // would feel restless.
    paintIvorySheen(canvas, size, travel, strength: 0.3);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RecordSkin old) => old.travel != travel;
}

// END OF FILE - lib/widgets/live_record.dart
