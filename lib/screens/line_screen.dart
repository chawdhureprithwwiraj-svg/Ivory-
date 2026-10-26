import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/discount_models.dart';
import '../services/code_service.dart';
import '../services/line_service.dart';
import '../theme/ivory_theme.dart';
import '../widgets/candle_room.dart';
import '../widgets/line_letter_card.dart';
import '../widgets/line_seal.dart';
import '../widgets/line_shelves.dart';

/// ============================================================
/// IVORY - THE PRIVATE LINE
///
/// Paid members write a letter, seal it and send it; Ivory answers
/// as many as she can. A member who has not joined may write too:
/// the letter is kept on this phone and says so plainly. Nothing is
/// ever shown as sent, read or answered unless it truly is.
/// ============================================================
class LineScreen extends StatefulWidget {
  const LineScreen({super.key, this.onOpenTab});

  /// Opens a bottom tab by key (Home passes its own).
  final void Function(String tab)? onOpenTab;

  @override
  State<LineScreen> createState() => _LineScreenState();
}

class _LineScreenState extends State<LineScreen>
    with SingleTickerProviderStateMixin {
  // One heartbeat: flames and room-light read this controller.
  late final AnimationController _flick = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2600))
    ..repeat();
  final TextEditingController _text = TextEditingController();
  final FocusNode _focus = FocusNode();
  Timer? _saver;
  Timer? _seen;
  bool _busy = false;
  bool _hadDraft = false;
  bool _share = false;
  PrizeCode? _prize;
  Map<String, dynamic>? _free;
  Map<String, dynamic>? _draw;
  LineDaily? _daily;

  LineService get _svc => LineService.instance;

  @override
  void initState() {
    super.initState();
    _svc.state.addListener(_changed);
    _svc.loadDraft().then((_) {
      if (mounted && _text.text.isEmpty) {
        _text.text = _svc.draft.value;
        _hadDraft = _text.text.trim().isNotEmpty;
        setState(() {});
      }
    });
    _svc.refresh(force: true).then((LineState? s) {
      if (s == null || !mounted) return;
      if (!s.paid) _loadPrize();
      _svc.freeState().then((Map<String, dynamic>? m) {
        if (mounted) setState(() => _free = m);
      });
      _svc.saturdayState().then((Map<String, dynamic>? m) {
        if (mounted) setState(() => _draw = m);
      });
      _svc.dailyToday().then((LineDaily? d) {
        if (mounted) setState(() => _daily = d);
      });
      // Replies the member is looking at now count as seen.
      _seen = Timer(const Duration(milliseconds: 1500), () {
        for (final LineLetter l in s.letters) {
          if (l.status == 'answered' && !l.seen) _svc.replySeen(l.id);
        }
      });
    });
  }

  @override
  void dispose() {
    _svc.state.removeListener(_changed);
    _saver?.cancel();
    _seen?.cancel();
    final String t = _text.text;
    if (t.trim().isNotEmpty && t != _svc.draft.value) _svc.saveDraft(t);
    _flick.dispose();
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _loadPrize() async {
    final List<PrizeCode> p = await CodeService.instance.myPrizes();
    if (mounted && p.isNotEmpty) setState(() => _prize = p.first);
  }

  void _say(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  void _typed(String _) {
    _saver?.cancel();
    _saver = Timer(const Duration(milliseconds: 600), () {
      _svc.saveDraft(_text.text);
    });
    setState(() {});
  }

  /// CC.219 - a Forever member seals straight into the Line.
  Future<void> _sendFree() async {
    final String body = _text.text.trim();
    if (body.length < 3 || _busy) return;
    _focus.unfocus();
    setState(() => _busy = true);
    final LineSendResult r = await _svc.queueJoin(body, share: _share);
    if (!mounted) return;
    if (r.ok) {
      _text.clear();
      await playLineSendAnimation(context);
    }
    if (!mounted) return;
    setState(() => _busy = false);
    _say(r.message);
    _svc.freeState(force: true).then((Map<String, dynamic>? m) {
      if (mounted) setState(() => _free = m);
    });
  }

  Future<void> _send() async {
    final String body = _text.text.trim();
    if (body.length < 3 || _busy) return;
    _focus.unfocus();
    setState(() => _busy = true);
    final LineSendResult r = await _svc.send(body, share: _share);
    if (!mounted) return;
    if (r.ok) {
      _text.clear();
      await playLineSendAnimation(context);
    }
    if (!mounted) return;
    setState(() => _busy = false);
    _say(r.message);
  }

  Future<void> _delete(LineLetter l) async {
    final bool? yes = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Delete this letter?'),
        content: const Text(
          'Its words are erased for good. If it is still waiting, it leaves '
          'the queue.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('KEEP IT'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    if (yes == true) {
      final bool ok = await _svc.delete(l.id);
      _say(ok ? 'Deleted.' : 'That did not go through. Please try again.');
    }
  }

  void _toMemberships() {
    final void Function(String)? go = widget.onOpenTab;
    Navigator.of(context).pop();
    if (go != null) go('premium');
  }

  Widget _heading(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 22, 2, 10),
    child: Text(
      t,
      style: TextStyle(
        color: IvoryColors.emerald.withValues(alpha: 0.7),
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 2.4,
      ),
    ),
  );

  Widget _paper(Widget child) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[Color(0xFFFFF9E8), Color(0xFFFFFCF2), Color(0xFFF6EEDB)],
        stops: <double>[0, 0.3, 1],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0x73C9962C)),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: const Color(0xFFFFC464).withValues(alpha: 0.28),
          blurRadius: 34,
        ),
        BoxShadow(
          color: IvoryColors.burgundy.withValues(alpha: 0.08),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: child,
  );

  Widget _note(String t, {bool strong = false}) => Text(
    t,
    style: TextStyle(
      color: IvoryColors.emerald.withValues(alpha: strong ? 1 : 0.82),
      fontSize: 13.5,
      height: 1.45,
      fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
    ),
  );

  Widget _composer(LineState s) {
    final int len = _text.text.trim().length;
    final bool paidCan = s.paid && s.canSend;
    return _paper(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextField(
            controller: _text,
            focusNode: _focus,
            minLines: 6,
            maxLines: 12,
            maxLength: s.maxChars,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            onChanged: _typed,
            textCapitalization: TextCapitalization.sentences,
            cursorColor: IvoryColors.emerald,
            style: const TextStyle(
              color: IvoryColors.emerald,
              fontFamily: IvoryTheme.displayFont,
              fontSize: 16,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText: 'Dear Ivory,',
              hintStyle: TextStyle(
                color: IvoryColors.emerald.withValues(alpha: 0.4),
                fontFamily: IvoryTheme.displayFont,
                fontStyle: FontStyle.italic,
                fontSize: 16,
              ),
              border: InputBorder.none,
              counterStyle: TextStyle(
                color: IvoryColors.emerald.withValues(alpha: 0.6),
                fontSize: 11.5,
              ),
            ),
          ),
          Material(
            type: MaterialType.transparency,
            child: CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: IvoryColors.emerald,
            side: const BorderSide(color: IvoryColors.emeraldMid, width: 2),
            checkColor: IvoryColors.emeraldWash,
            value: _share,
            onChanged: (bool? v) => setState(() => _share = v == true),
            title: _note(
              paidCan
                  ? 'Ivory may share this letter and her reply as the Letter '
                      'of the Day, without my name.'
                  : 'Ivory may share this letter and her reply as a Saturday '
                      'Evening Letter, without my name.',
            ),
          ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: IvoryColors.emerald,
                foregroundColor: const Color(0xFFF6DE9C),
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Color(0xB3C9962C), width: 1.4),
                shape: const StadiumBorder(),
                shadowColor: const Color(0x55FFC464),
                elevation: 3,
              ),
              onPressed: len < 3 || _busy ? null : (paidCan ? _send : _sendFree),
              icon: const Icon(Icons.mail_outline),
              label: Text(
                paidCan ? 'SEAL AND SEND' : 'SEAL INTO THE LINE',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
            ),
          ),
          if (!paidCan) ...<Widget>[
            const SizedBox(height: 10),
            _note(
              'Kept on this phone until you seal it. Sealed letters stand in '
              'the Line even before you join - membership simply carries '
              'yours to the front.',
            ),
          ],
        ],
      ),
    );
  }

  Widget _intro(LineState s) {
    final String line;
    if (!s.paid) {
      line = 'Seal a letter into the Line today. It stands in the queue even '
          'before you join - and membership carries it to the front, where '
          'every letter is answered.';
    } else {
      line = 'Every letter is read. Ivory answers as many as she can, in her '
          'own time.';
    }
    return _paper(
      Row(
        children: <Widget>[
          const LineEnvelopeView(width: 86, height: 72),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Write to Ivory',
                  style: TextStyle(
                    color: IvoryColors.emerald,
                    fontFamily: IvoryTheme.displayFont,
                    fontStyle: FontStyle.italic,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                _note(line),
                if (s.answeredToday > 0) ...<Widget>[
                  const SizedBox(height: 8),
                  _note(
                    s.answeredToday == 1
                        ? 'Ivory answered 1 letter today.'
                        : 'Ivory answered ${s.answeredToday} letters today.',
                    strong: true,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _join(LineState s) {
    final PrizeCode? p = _prize;
    return _paper(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _note(
            'Join a membership and your letter is sent to Ivory the moment you '
            'are in.',
            strong: true,
          ),
          if (p != null) ...<Widget>[
            const SizedBox(height: 8),
            _note(
              'A discount is waiting for you: ${p.offText}. It is applied at '
              'checkout.',
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: IvoryColors.emerald,
                side: const BorderSide(color: Color(0x99C9962C), width: 1.4),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: const StadiumBorder(),
              ),
              onPressed: _toMemberships,
              child: const Text(
                'SEE THE MEMBERSHIPS',
                style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// CC.219 - pull the Saturday evening cord, then refresh the shelves.
  Future<void> _drawNow() async {
    final String? m = await _svc.saturdayDraw();
    if (m != null) _say(m);
    final Map<String, dynamic>? d = await _svc.saturdayState(force: true);
    final LineDaily? dd = await _svc.dailyToday(force: true);
    if (mounted) {
      setState(() {
        _draw = d;
        _daily = dd;
      });
    }
  }

  String _blocked(LineState s) {
    switch (s.whyNot) {
      case 'resting':
        return 'The Private Line is resting for your account right now.';
      case 'open':
        return 'Your letter is with Ivory. When she answers, you can write again.';
      case 'used':
        return 'You have used your ${s.allowance == 1 ? 'letter' : '${s.allowance} letters'} '
            'for these ${s.windowDays} days. A new one frees up as the days '
            'pass.';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final LineState? s = _svc.state.value;
    return Scaffold(
      backgroundColor: IvoryColors.ivory,
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('THE PRIVATE LINE'),
        ),
        backgroundColor: IvoryColors.ivory,
        foregroundColor: IvoryColors.emerald,
        elevation: 0,
      ),
      body: s == null
          ? const Center(
              child: CircularProgressIndicator(color: IvoryColors.emerald),
            )
          : Stack(
              children: <Widget>[
                ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                6,
                16,
                30 + MediaQuery.of(context).viewPadding.bottom,
              ),
              children: <Widget>[
                CandleRoomOpening(flick: _flick),
                _intro(s),
                const SizedBox(height: 14),
                if (s.paid && s.canSend && _hadDraft) ...<Widget>[
                  _paper(
                    _note(
                      'Your letter was kept for you. Read it once more, then '
                      'seal and send it.',
                      strong: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                if (!s.paid || s.canSend) _composer(s),
                if (s.paid && !s.canSend && _blocked(s).isNotEmpty)
                  _paper(_note(_blocked(s), strong: true)),
                if (s.paid && s.canSend && s.allowance > 0) ...<Widget>[
                  const SizedBox(height: 10),
                  Center(
                    child: _note(
                      '${s.left} of ${s.allowance} '
                      '${s.allowance == 1 ? 'letter' : 'letters'} left in these '
                      '${s.windowDays} days',
                    ),
                  ),
                ],
                LineShelves(
                  free: _free,
                  paid: s.paid,
                  draw: _draw,
                  daily: _daily,
                  onDraw: _drawNow,
                  onJoin: _toMemberships,
                ),
                if (!s.paid) ...<Widget>[
                  const SizedBox(height: 14),
                  _join(s),
                ],
                if (s.letters.isNotEmpty) ...<Widget>[
                  _heading('YOUR LETTERS'),
                  ...s.letters.map(
                    (LineLetter l) => LineLetterCard(
                      letter: l,
                      state: s,
                      onDelete: () => _delete(l),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Center(
                  child: _note(
                    'Only you and Ivory can read your letters, unless you allow a '
                    'letter to be shared without your name. Delete any letter '
                    'and its words are erased.',
                  ),
                ),
              ],
            ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _flick,
                      builder: (BuildContext c, Widget? w) => CustomPaint(painter: CandleRoomLight(_flick.value)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// END OF FILE - lib/screens/line_screen.dart
