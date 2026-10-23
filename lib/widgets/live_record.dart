import 'package:flutter/material.dart';

import '../models/live_night.dart';
import '../services/live_service.dart';
import '../theme/ivory_theme.dart';
import 'ivory_sheen.dart';

/// ============================================================
/// IVORY - EVERY TIME I HAVE BEEN LIVE.
///
/// The permanent record of her broadcasts, below the home hero.
/// GOLD IS ON AIR NOW, EMERALD IS THE RECORD: warm for happening,
/// cool for finished and kept. Never reverse it.
/// The title is hers: "Every time I have been LIVE".
///
/// NOTHING HERE IS INVENTED. Real minutes, real attendance. Where
/// Ivory does not know (nights before attendance was recorded) it
/// says nothing rather than guessing.
///
/// CC.176: the original card made richer: deep emerald, a metal
/// gold frame, a lit top edge and shaded base, jewel bars. The one
/// gentle light (IvorySheen) is the only movement.
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
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final List<LiveNight> r = await LiveService.instance.liveRecord(limit: 15);
      if (!mounted) return;
      setState(() {
        _nights = r;
        _failed = false;
        _done = true;
      });
    } catch (_) {
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
    // Never broadcast yet: say nothing at all.
    if (_nights.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x6B06503A), blurRadius: 22, offset: Offset(0, 10)),
          BoxShadow(color: Color(0x59B9801F), blurRadius: 5, offset: Offset(0, 2)),
        ],
      ),
      child: IvorySheen(
      child: (double t) => CustomPaint(
        painter: _RecordSkin(t),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(19, 18, 17, 17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _heading(),
              const SizedBox(height: 11),
              _rhythm(),
              const SizedBox(height: 13),
              ..._nights.take(_expanded ? 15 : 1).map(_entry),
              if (_expanded) ...<Widget>[
                const SizedBox(height: 11),
                Text(
                  'Only the last 15 live broadcasting sessions are listed here.',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.4,
                    fontStyle: FontStyle.italic,
                    color: IvoryColors.emeraldWash.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      ),
    );
  }

  // ---- the heading, summary and expand/collapse control ----
  Widget _heading() {
    final int counted = _nights.where((LiveNight n) => n.tracked).length;
    final int attended =
        _nights.where((LiveNight n) => n.tracked && n.youWereThere).length;
    final int totalMinutes = _nights.fold<int>(
        0, (int a, LiveNight n) => a + (n.minutes ?? 0));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text.rich(
                TextSpan(
                  children: <InlineSpan>[
                    TextSpan(
                      text: 'Every time I have been ',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.35,
                        color: const Color(0xFFF6D77C),
                        shadows: const <Shadow>[
                          Shadow(color: Color(0xB3023222), offset: Offset(0, 1), blurRadius: 2),
                        ],
                      ),
                    ),
                    TextSpan(
                      text: 'LIVE',
                      style: TextStyle(
                        fontFamily: IvoryTheme.displayFont,
                        fontSize: 18.5,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 1.4,
                        color: IvoryColors.cream,
                        shadows: <Shadow>[
                          const Shadow(color: Color(0xFFC99A32), offset: Offset(0, 1)),
                          const Shadow(color: Color(0xCC023222), offset: Offset(0, 2), blurRadius: 6),
                          const Shadow(color: Color(0x80F6D77C), blurRadius: 14),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Text(
                <String>[
                  '${_nights.length} ${_nights.length == 1 ? 'session' : 'sessions'}',
                  if (totalMinutes > 0) _span(totalMinutes),
                  if (counted > 0)
                    'you were there for $attended ${attended == 1 ? 'session' : 'sessions'}',
                ].join('  \u00B7  '),
                style: TextStyle(
                  fontSize: 12.4,
                  height: 1.4,
                  color: const Color(0xFFD9F5E6),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => setState(() => _expanded = !_expanded),
          tooltip: _expanded ? 'Show fewer sessions' : 'Show more sessions',
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          icon: Icon(
            _expanded
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            size: 26,
            color: const Color(0xFFF6D77C),
            shadows: const <Shadow>[
              Shadow(color: Color(0xCC023222), offset: Offset(0, 1), blurRadius: 2),
            ],
          ),
        ),
      ],
    );
  }

  // ---- fifteen sessions, as a rhythm (height = real length) ----
  Widget _rhythm() {
    final List<LiveNight> strip = _nights.take(15).toList().reversed.toList();
    int longest = 1;
    for (final LiveNight n in strip) {
      if ((n.minutes ?? 0) > longest) longest = n.minutes ?? 1;
    }
    return SizedBox(
      height: 38,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          for (final LiveNight n in strip)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 3),
                child: _bar(n, 9 + 29 * ((n.minutes ?? 0) / longest)),
              ),
            ),
        ],
      ),
    );
  }

  /// One polished column: lit from the left, a bright top edge,
  /// a shaded foot and a little shadow on the card. Gold only for a
  /// night the member was there.
  Widget _bar(LiveNight n, double h) {
    final bool gold = n.tracked && n.youWereThere;
    // CC.200: cream-pearl bars on the green card - they read at a
    // glance now; gold stays reserved for a night the member was in.
    final List<Color> c = gold
        ? const <Color>[Color(0xFFFFF0B0), Color(0xFFEBC050), Color(0xFFC99532)]
        : n.tracked
            ? const <Color>[Color(0xFFFDFAF0), Color(0xFFEFE6CC), Color(0xFFD2C096)]
            : const <Color>[Color(0x8CFDFAF0), Color(0x8CEFE6CC), Color(0x8CD2C096)];
    return Container(
      height: h,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(3.5),
          bottom: Radius.circular(1.5),
        ),
        gradient: LinearGradient(colors: c),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(n.tracked ? 0x80022818 : 0x40022818),
            offset: const Offset(0, 3),
            blurRadius: 4,
          ),
        ],
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          height: 1.8,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
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
            width: 7,
            height: 7,
            margin: const EdgeInsets.only(top: 5, right: 9),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.4),
                colors: n.tracked && n.youWereThere
                    ? const <Color>[Color(0xFFFFF6CC), Color(0xFFE3B54A)]
                    : const <Color>[Color(0xFFD9FFEB), Color(0xFF4BBE8B)],
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Color(n.tracked && n.youWereThere ? 0xB3F6D77C : 0xB382F0BE),
                  blurRadius: 5,
                ),
              ],
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
                // No attendance data means no sentence about it.
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
                          ? const Color(0xFFF6D77C)
                          : const Color(0xFFBDE5CF),
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

/// The card, cut like an emerald in a metal frame.
///
/// Gold metal frame, emerald face lit from the top left, two soft
/// facets, a bright top edge, a shaded base, a fine inner gold line,
/// then the one gentle light.
class _RecordSkin extends CustomPainter {
  const _RecordSkin(this.travel);

  final double travel;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect r = Offset.zero & size;
    final RRect frame = RRect.fromRectAndRadius(
      r.deflate(0.5),
      const Radius.circular(20),
    );
    final RRect face = RRect.fromRectAndRadius(
      r.deflate(3),
      const Radius.circular(17.5),
    );
    canvas.saveLayer(r, Paint());

    canvas.drawRRect(
      frame,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFFFEDAA),
            Color(0xFFD9A73B),
            Color(0xFFFFF2BE),
            Color(0xFFB9801F),
            Color(0xFFF2CB68),
          ],
          stops: <double>[0, 0.28, 0.5, 0.75, 1],
        ).createShader(r),
    );

    canvas.save();
    canvas.clipRRect(face);
    canvas.drawRect(
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF10855C),
            Color(0xFF0A6446),
            Color(0xFF07503A),
          ],
          stops: <double>[0, 0.42, 1],
        ).createShader(r),
    );
    canvas.drawRect(
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.7, -1.15),
          radius: 1.1,
          colors: <Color>[Color(0x6182F0BE), Color(0x0082F0BE)],
        ).createShader(r),
    );
    final double w = size.width;
    final double h = size.height;
    canvas.drawPath(
      Path()..moveTo(0, 0)..lineTo(w * 0.62, 0)..lineTo(w * 0.34, h)..lineTo(0, h)..close(),
      Paint()..color = const Color(0x14FFFFFF),
    );
    canvas.drawPath(
      Path()..moveTo(w * 0.78, 0)..lineTo(w, 0)..lineTo(w, h)..lineTo(w * 0.52, h)..close(),
      Paint()..color = const Color(0x5E023222),
    );
    canvas.drawRect(
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0x00023222), Color(0x00023222), Color(0x8C03321F)],
          stops: <double>[0, 0.55, 1],
        ).createShader(r),
    );
    canvas.restore();

    canvas.drawRRect(
      face.deflate(0.6),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xB0BEFFE1), Color(0x00BEFFE1)],
          stops: <double>[0, 0.4],
        ).createShader(r),
    );
    canvas.drawRRect(
      face.deflate(4),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0x61FFDE82),
    );

    paintIvorySheen(canvas, size, travel, strength: 0.3);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RecordSkin old) => old.travel != travel;
}

// END OF FILE - lib/widgets/live_record.dart
