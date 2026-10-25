import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/ivory_errors.dart';
import '../models/ivory_post.dart';
import '../services/early_service.dart';
import '../theme/ivory_theme.dart';
import '../widgets/lane_law.dart';
import '../widgets/early_door_view.dart';
import '../widgets/post_actions.dart';

/// Opens the Early Door sheet: the door, what it gives this member,
/// what each rung gives, and what is waiting.
Future<void> showEarlyDoorSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _EarlyDoorSheet(),
  );
}

const Color _wash = IvoryColors.emeraldWash;

BoxDecoration _sheetBack() => const BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[IvoryColors.emeraldMid, IvoryColors.emerald],
  ),
  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
);

class _EarlyDoorSheet extends StatefulWidget {
  const _EarlyDoorSheet();

  @override
  State<_EarlyDoorSheet> createState() => _EarlyDoorSheetState();
}

class _EarlyDoorSheetState extends State<_EarlyDoorSheet> {
  Timer? _tick;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    EarlyService.instance.state.addListener(_changed);
    EarlyService.instance.refresh(force: true);
    // CC.215: while the early door is open the ribbon lane waits, so
    // the new back arrow is never covered mid-crossing.
    LaneLaw.topBusy.value = true;
    _tick = Timer.periodic(const Duration(seconds: 20), (Timer _) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    LaneLaw.topBusy.value = false;
    EarlyService.instance.state.removeListener(_changed);
    _tick?.cancel();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  void _say(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _push(bool on) async {
    setState(() => _busy = true);
    try {
      await EarlyService.instance.setPush(on);
    } catch (e) {
      _say(houseMessage(e));
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _read(EarlyPost p) async {
    if (!p.canOpen) {
      _say('This opens for you ${earlyCountdown(p.opensAt)}, on '
          '${earlyClock(p.opensAt)}. Everyone has it ${earlyCountdown(p.publicAt)}.');
      return;
    }
    try {
      final List<dynamic> rows = await Supabase.instance.client
          .from('post_previews')
          .select()
          .eq('id', p.id)
          .limit(1);
      if (rows.isEmpty || !mounted) return;
      final IvoryPost post = IvoryPost.fromPreview(
        Map<String, dynamic>.from(rows.first as Map),
      );
      await PostActions.open(context, post);
    } catch (e) {
      _say(houseMessage(e));
    }
  }

  Widget _chip(String label, String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: _wash.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: _wash.withValues(alpha: 0.7),
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: _wash,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );

  Widget _heading(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 22, 2, 10),
    child: Text(
      t,
      style: TextStyle(
        color: _wash.withValues(alpha: 0.8),
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 2.4,
      ),
    ),
  );

  IconData _icon(String type) {
    switch (type) {
      case 'video':
        return Icons.movie_outlined;
      case 'audio':
        return Icons.graphic_eq_rounded;
      case 'image':
        return Icons.photo_outlined;
      case 'poll':
        return Icons.how_to_vote_outlined;
      default:
        return Icons.auto_stories_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final EarlyState? s = EarlyService.instance.state.value;
    final double bottom = MediaQuery.of(context).viewPadding.bottom;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (BuildContext ctx, ScrollController sc) {
        return Container(
          decoration: _sheetBack(),
          child: s == null
              ? const Center(
                  child: CircularProgressIndicator(color: _wash),
                )
              : ListView(
                  controller: sc,
                  padding: EdgeInsets.fromLTRB(18, 14, 18, 28 + bottom),
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        IconButton(
                          tooltip: 'Back',
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(Icons.arrow_back,
                              color: _wash, size: 22),
                        ),
                        Expanded(
                          child: Center(
                            child: Container(
                              width: 42,
                              height: 4,
                              decoration: BoxDecoration(
                                color: _wash.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: EarlyDoorView(
                        openness: earlyOpenness(s.hours),
                        width: 124,
                        height: 154,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      s.isOpen ? 'Your door is open' : 'Your door is shut',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _wash,
                        fontFamily: IvoryTheme.displayFont,
                        fontStyle: FontStyle.italic,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _story(s),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _wash.withValues(alpha: 0.9),
                        fontSize: 13.5,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: <Widget>[
                        _chip('Your rung', s.rungName.isEmpty ? '-' : s.rungName),
                        _chip(
                          'Reads ahead',
                          s.hours >= 100000
                              ? 'Always first'
                              : (s.hours > 0 ? earlyHoursText(s.hours) : 'None yet'),
                        ),
                        _chip(
                          'Golden Heart',
                          s.warm
                              ? 'Lit lately'
                              : 'Quiet for ${s.warmDays}+ days',
                        ),
                        _chip('Read early', '${s.reads}'),
                      ],
                    ),
                    if (s.posts.isNotEmpty) ...<Widget>[
                      _heading('WAITING FOR YOU'),
                      ...s.posts.map(_postTile),
                    ],
                    _heading('WHAT EACH RUNG GIVES YOU'),
                    ...s.windows.map((EarlyWindow w) => _rungRow(s, w)),
                    if (s.callExtraDays > 0) ...<Widget>[
                      _heading('CALLS'),
                      Text(
                        'While your door is open you can book a call '
                        '${s.callExtraDays} days further ahead than everyone else.',
                        style: TextStyle(
                          color: _wash.withValues(alpha: 0.9),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                    _heading('NOTIFICATIONS'),
                    Container(
                      decoration: BoxDecoration(
                        color: _wash.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SwitchListTile(
                        activeThumbColor: _wash,
                        activeTrackColor: IvoryColors.emeraldLight,
                        title: const Text(
                          'Tell me when an early story opens',
                          style: TextStyle(
                            color: _wash,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        value: s.pushOn,
                        onChanged: _busy ? null : _push,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'The door is earned by showing up, never bought. Paid '
                      'members read early stories at once.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _wash.withValues(alpha: 0.65),
                        fontSize: 11.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  String _story(EarlyState s) {
    if (s.paid && s.hours >= 100000) {
      return 'As a paid member you read every early story the moment it is '
          'shared. The light in the doorway is yours.';
    }
    if (s.isOpen) {
      return 'New stories reach you ${earlyHoursText(s.hours)} before '
          'everyone else. Keep your Golden Heart lit every few days and the '
          'door stays open.';
    }
    if (s.rungHours > 0 && !s.warm) {
      return 'Your heart has been quiet for a while. Light it today and the '
          'door opens ${earlyHoursText(s.rungHours)} early.';
    }
    final EarlyWindow? next = s.nextWindow;
    if (next != null) {
      return 'Climb to ${next.name} on the Ivory Ladder and the door opens '
          '${earlyHoursText(next.hours)} early.';
    }
    return 'Keep your Golden Heart lit and climb the Ivory Ladder to open the '
        'door.';
  }

  Widget _postTile(EarlyPost p) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Material(
      color: _wash.withValues(alpha: p.canOpen ? 0.2 : 0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _read(p),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              Icon(_icon(p.type), color: _wash, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      p.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _wash,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      p.canOpen
                          ? 'Yours now. Everyone has it ${earlyCountdown(p.publicAt)}.'
                          : 'Opens for you ${earlyCountdown(p.opensAt)}.',
                      style: TextStyle(
                        color: _wash.withValues(alpha: 0.82),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                p.canOpen ? Icons.arrow_forward_ios_rounded : Icons.lock_clock,
                color: _wash.withValues(alpha: 0.8),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _rungRow(EarlyState s, EarlyWindow w) {
    final bool reached = w.rung <= s.rung;
    final bool here = w.rung == s.rung;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: _wash.withValues(alpha: here ? 0.22 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: here
            ? Border.all(color: _wash.withValues(alpha: 0.8))
            : null,
      ),
      child: Row(
        children: <Widget>[
          Icon(
            reached ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 18,
            color: _wash.withValues(alpha: reached ? 1 : 0.5),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              here ? '${w.name}  (you are here)' : w.name,
              style: TextStyle(
                color: _wash.withValues(alpha: reached ? 1 : 0.75),
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            w.hours > 0 ? '${earlyHoursText(w.hours)} early' : 'no early reading',
            style: TextStyle(
              color: _wash.withValues(alpha: reached ? 0.95 : 0.65),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// END OF FILE - lib/screens/early_door_sheet.dart
