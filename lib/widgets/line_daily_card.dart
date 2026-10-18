import 'dart:async';

import 'package:flutter/material.dart';

import '../services/early_service.dart';
import '../services/line_service.dart';
import '../theme/ivory_theme.dart';

/// ============================================================
/// IVORY - THE LETTER OF THE DAY, ON THE HOME SCREEN
///
/// When Ivory shares a letter, with the writer's permission, every
/// member can read it with her reply for two days. No name is ever
/// shown. The card draws nothing when there is no letter today, when
/// the house has switched it off, or when it cannot be reached.
/// Tapping opens the whole letter and reply.
/// ============================================================
class LineDailyCard extends StatefulWidget {
  const LineDailyCard({super.key, this.preset});

  /// Shows this letter without asking the database (for previews and tests).
  final LineDaily? preset;

  @override
  State<LineDailyCard> createState() => _LineDailyCardState();
}

class _LineDailyCardState extends State<LineDailyCard>
    with WidgetsBindingObserver {
  LineDaily? _d;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.preset != null) {
      _d = widget.preset;
      return;
    }
    // Home stays alive inside the bottom tabs, so this card must look
    // again by itself: when the app comes back, and every two minutes.
    WidgetsBinding.instance.addObserver(this);
    _fetch(false);
    _timer = Timer.periodic(const Duration(minutes: 2), (Timer _) {
      _fetch(true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _fetch(true);
  }

  Future<void> _fetch(bool force) async {
    final LineDaily? d = await LineService.instance.dailyToday(force: force);
    if (!mounted) return;
    if (d?.id != _d?.id) setState(() => _d = d);
  }

  void _open(LineDaily d) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: IvoryColors.ivory,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (BuildContext ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (BuildContext c, ScrollController sc) => ListView(
          controller: sc,
          padding: EdgeInsets.fromLTRB(
            22,
            22,
            22,
            28 + MediaQuery.of(ctx).viewPadding.bottom,
          ),
          children: <Widget>[
            _label('LETTER OF THE DAY'),
            const SizedBox(height: 14),
            Text(
              d.letter,
              style: const TextStyle(
                color: IvoryColors.emerald,
                fontFamily: IvoryTheme.displayFont,
                fontSize: 17,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[IvoryColors.emeraldMid, IvoryColors.emerald],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'IVORY WROTE BACK',
                    style: TextStyle(
                      color: IvoryColors.emeraldWash.withValues(alpha: 0.75),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    d.reply,
                    style: const TextStyle(
                      color: IvoryColors.emeraldWash,
                      fontFamily: IvoryTheme.displayFont,
                      fontStyle: FontStyle.italic,
                      fontSize: 16.5,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Shared with the writer\u2019s permission. Their name is never '
              'shown.',
              style: TextStyle(
                color: IvoryColors.emerald.withValues(alpha: 0.75),
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Text(
    t,
    style: TextStyle(
      color: IvoryColors.emerald.withValues(alpha: 0.7),
      fontSize: 10.5,
      fontWeight: FontWeight.w800,
      letterSpacing: 2.4,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final LineDaily? d = _d;
    if (d == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: GestureDetector(
        onTap: () => _open(d),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[IvoryColors.surface, IvoryColors.surfaceWarm],
            ),
            border: Border.all(
              color: IvoryColors.emeraldLight.withValues(alpha: 0.5),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: IvoryColors.burgundy.withValues(alpha: 0.10),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(child: _label('LETTER OF THE DAY')),
                  Text(
                    earlyClock(d.publishedAt),
                    style: TextStyle(
                      color: IvoryColors.emerald.withValues(alpha: 0.55),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '\u201C${d.letter}\u201D',
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: IvoryColors.emerald,
                  fontFamily: IvoryTheme.displayFont,
                  fontStyle: FontStyle.italic,
                  fontSize: 16.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: IvoryColors.emeraldWash,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Ivory: ${d.reply}',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: IvoryColors.emerald,
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap to read it all. Shared with permission, never with a name.',
                style: TextStyle(
                  color: IvoryColors.emerald.withValues(alpha: 0.7),
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// END OF FILE - lib/widgets/line_daily_card.dart

