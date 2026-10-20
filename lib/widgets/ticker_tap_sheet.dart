import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../services/cheer_service.dart';
import '../services/ticker_service.dart';
import 'ticker_cheer_burst.dart';
import 'ticker_palettes.dart';
import 'ticker_ribbon.dart';
import 'ticker_sound.dart';

/// The moments a member can cheer. Private sessions, new posts, live
/// announcements and the house's own notes have no cheer.
const Set<String> kTickerCheerKinds = <String>{
  'mark',
  'treasure',
  'treasure_gift',
  'rung',
  'fullday',
  'bellset',
  'pledge',
  'glow',
  'peal',
  'knockoff10',
  'gift',
  'gift_live',
  'welcome',
};

/// ============================================================
/// IVORY - THE TAP SHEET (Cheers)
///
/// Touching a ribbon freezes it where it is and opens this small sheet
/// in the ribbon's own colour. It shows the same ribbon, four cheer
/// symbols (one tap sends one) and OPEN IT, which goes where the ribbon
/// used to go. Every message appears INSIDE the sheet. Closing the
/// sheet lets the ribbon carry on from the same spot.
/// ============================================================
class TickerTapSheet {
  TickerTapSheet._();

  static bool _open = false;

  /// Opens the sheet. Returns false only if it could not be opened, so
  /// the caller can fall back to the old tap.
  static bool show(TickerShow s) {
    final BuildContext? ctx = TickerNav.state?.overlay?.context;
    if (ctx == null) return false;
    if (_open) return true;
    _open = true;
    TickerService.instance.paused.value = true;
    TickerSound.instance.play('tap');
    showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (BuildContext _) => _CheerSheet(show: s),
    ).whenComplete(() {
      _open = false;
      TickerService.instance.paused.value = false;
    });
    return true;
  }
}

class _CheerSheet extends StatefulWidget {
  const _CheerSheet({required this.show});

  final TickerShow show;

  @override
  State<_CheerSheet> createState() => _CheerSheetState();
}

class _CheerSheetState extends State<_CheerSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _b = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  String _style = 'sparkle';
  bool _busy = false;
  bool _done = false;
  String _msg = '';

  @override
  void dispose() {
    _b.dispose();
    super.dispose();
  }

  String _words(String status) {
    switch (status) {
      case 'sent':
        return 'Cheer sent. They will be told in a little while.'.tr;
      case 'already':
        return 'You have already cheered this one.'.tr;
      case 'cap':
        return 'You have used all your cheers for today. They return tomorrow.'
            .tr;
      case 'self':
        return 'This one is yours, so it cannot be cheered. Everyone else can send you a cheer.'
            .tr;
      case 'closed':
        return 'This member is not taking cheers at the moment.'.tr;
      case 'gone':
        return 'This moment has already moved on. Wait for the next ribbon.'
            .tr;
      case 'off':
        return 'Cheers are resting right now.'.tr;
      default:
        return 'That did not go through. Please try again in a moment.'.tr;
    }
  }

  Future<void> _cheer(String style) async {
    if (_busy || _done) return;
    final String? to = widget.show.event.actor;
    if (to == null) return;
    setState(() {
      _busy = true;
      _style = style;
      _msg = '';
    });
    final String status = await CheerService.instance.send(
      widget.show.event.id,
      to,
      style,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _done = status != 'bad';
      _msg = _words(status);
    });
    if (status == 'sent') {
      HapticFeedback.lightImpact();
      TickerSound.instance.play('cheer');
      _b.forward(from: 0);
    }
  }

  Widget _chip(List<Object> st, TickerPalette p) {
    final String key = st[0] as String;
    final bool picked = _style == key && (_busy || _done);
    final bool dim = _done && !picked;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _cheer(key),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: dim ? 0.4 : 1,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AnimatedScale(
                duration: const Duration(milliseconds: 250),
                scale: picked ? 1.12 : 1,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.35, -0.4),
                      colors: <Color>[p.light, p.mid, p.base],
                      stops: const <double>[0, 0.55, 1],
                    ),
                    border: Border.all(
                      color: p.trim.withValues(alpha: picked ? 1 : 0.8),
                      width: picked ? 2.6 : 1.6,
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: p.deep.withValues(alpha: 0.55),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    st[2] as IconData,
                    size: 28,
                    color: kTickerCream,
                    shadows: <Shadow>[
                      Shadow(
                        color: p.deep.withValues(alpha: 0.8),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                (st[1] as String).tr,
                style: TextStyle(
                  color: kTickerCream,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.3,
                  shadows: <Shadow>[
                    Shadow(color: p.deep.withValues(alpha: 0.8), blurRadius: 3),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TickerPalette p =
        kTickerPalettes[widget.show.palette % kTickerPalettes.length];
    final double bottom = MediaQuery.of(context).padding.bottom;
    final TextStyle soft = TextStyle(
      color: kTickerCream,
      height: 1.35,
      shadows: <Shadow>[Shadow(color: p.deep.withValues(alpha: 0.7), blurRadius: 3)],
    );
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[p.base, p.deep],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        border: Border(
          top: BorderSide(color: p.trim.withValues(alpha: 0.85), width: 1.6),
        ),
      ),
      padding: EdgeInsets.fromLTRB(18, 10, 18, 18 + bottom),
      child: Stack(
        children: <Widget>[
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: kTickerCream.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TickerPill(
                show: widget.show,
                t: const AlwaysStoppedAnimation<double>(0.3),
              ),
              const SizedBox(height: 18),
              Text(
                'SEND A CHEER'.tr,
                textAlign: TextAlign.center,
                style: soft.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'A little warmth, with no words. One cheer for each ribbon.'.tr,
                textAlign: TextAlign.center,
                style: soft.copyWith(fontSize: 12.5),
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  for (final List<Object> st in kCheerStyles) _chip(st, p),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                child: _msg.isEmpty
                    ? const SizedBox(height: 14)
                    : Padding(
                        padding: const EdgeInsets.only(top: 14, bottom: 2),
                        child: Text(
                          _msg,
                          textAlign: TextAlign.center,
                          style: soft.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  TickerService.instance.openPlace(widget.show);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: kTickerCream,
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  side: BorderSide(color: kTickerCream.withValues(alpha: 0.85)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: Text(
                  'OPEN IT'.tr,
                  style: const TextStyle(
                    color: kTickerCream,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: CheerBurstPainter(_b, _style, p)),
            ),
          ),
        ],
      ),
    );
  }
}

// END OF FILE - lib/widgets/ticker_tap_sheet.dart
