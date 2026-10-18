import 'package:flutter/material.dart';

import '../core/ivory_errors.dart';
import '../models/ladder_models.dart';
import '../services/ladder_service.dart';
import 'ladder_paint.dart';

/// ============================================================
/// IVORY - THE STREAK CALENDAR
///
/// One month of the member's own days. A lit heart day glows mint;
/// a Full Day carries a small star on top. Today has a ring. The
/// member can walk back through earlier months.
/// ============================================================
class LadderCalendar extends StatefulWidget {
  const LadderCalendar({super.key});

  @override
  State<LadderCalendar> createState() => _LadderCalendarState();
}

class _LadderCalendarState extends State<LadderCalendar> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  LadderMonth? _data;
  String? _error;
  bool _loading = true;

  static const List<String> _names = <String>[
    'January', 'February', 'March', 'April', 'May', 'June', 'July',
    'August', 'September', 'October', 'November', 'December',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final LadderMonth m = await LadderService.instance.calendar(
        _month.year,
        _month.month,
      );
      if (!mounted) return;
      setState(() {
        _data = m;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = houseMessage(e);
        _loading = false;
      });
    }
  }

  void _step(int by) {
    setState(() => _month = DateTime(_month.year, _month.month + by));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final bool atNow = _month.year == now.year && _month.month == now.month;
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            IconButton(
              onPressed: _loading ? null : () => _step(-1),
              icon: const Icon(Icons.chevron_left, color: LadderTones.pearl),
            ),
            Expanded(
              child: Text(
                '${_names[_month.month - 1]} ${_month.year}'.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: LadderTones.pearl,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  fontSize: 12.5,
                ),
              ),
            ),
            IconButton(
              onPressed: _loading || atNow ? null : () => _step(1),
              icon: Icon(
                Icons.chevron_right,
                color: atNow ? LadderTones.mist.withValues(alpha: 0.3) : LadderTones.pearl,
              ),
            ),
          ],
        ),
        Row(
          children: const <String>['M', 'T', 'W', 'T', 'F', 'S', 'S']
              .map(
                (String d) => Expanded(
                  child: Text(
                    d,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: LadderTones.mist.withValues(alpha: 0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 6),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              _error!,
              style: const TextStyle(color: LadderTones.pearl),
            ),
          )
        else if (_data == null)
          const SizedBox(
            height: 150,
            child: Center(
              child: CircularProgressIndicator(color: LadderTones.mint),
            ),
          )
        else
          _grid(_data!),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 14,
          runSpacing: 4,
          children: <Widget>[
            _key(LadderTones.mint, 'Heart lit'),
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.star_rounded, size: 15, color: LadderTones.rose),
                SizedBox(width: 4),
                Text(
                  'Full Day',
                  style: TextStyle(color: LadderTones.pearl, fontSize: 11.5),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _key(Color c, String t) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Container(
        width: 11,
        height: 11,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text(t, style: const TextStyle(color: LadderTones.pearl, fontSize: 11.5)),
    ],
  );

  Widget _grid(LadderMonth m) {
    final List<Widget> cells = <Widget>[];
    for (int i = 1; i < m.firstWeekday; i++) {
      cells.add(const SizedBox.shrink());
    }
    final String todayKey = m.today;
    for (final LadderDay d in m.days) {
      final String key =
          '${m.year.toString().padLeft(4, '0')}-${m.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final bool isToday = key == todayKey;
      cells.add(
        Padding(
          padding: const EdgeInsets.all(2.5),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: d.lit
                  ? LadderTones.mint.withValues(alpha: 0.9)
                  : LadderTones.tealDeep.withValues(alpha: 0.55),
              border: isToday
                  ? Border.all(color: Colors.white, width: 1.8)
                  : null,
              boxShadow: d.lit
                  ? <BoxShadow>[
                      BoxShadow(
                        color: LadderTones.mint.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: <Widget>[
                Text(
                  '${d.day}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: d.lit
                        ? LadderTones.teal
                        : LadderTones.mist.withValues(alpha: 0.8),
                  ),
                ),
                if (d.full)
                  const Positioned(
                    top: -5,
                    right: -4,
                    child: Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: LadderTones.rose,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }
    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: cells,
    );
  }
}

// END OF FILE - lib/widgets/ladder_calendar.dart
