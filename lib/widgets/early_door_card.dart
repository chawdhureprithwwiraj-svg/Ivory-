import 'dart:async';

import 'package:flutter/material.dart';

import '../screens/early_door_sheet.dart';
import '../services/early_service.dart';
import '../services/heart_service.dart';
import '../theme/ivory_theme.dart';
import 'amethyst_door.dart';
import 'dawn_house.dart';
import 'early_door_view.dart';
import 'jewel_plate.dart';
import 'sound_bank.dart';

/// ============================================================
/// IVORY - THE EARLY DOOR, ON THE HOME SCREEN (CC.230)
///
/// The royal-amethyst jewel card, awakened: a breathing seam of dawn
/// light along its top edge (quickening in the creak window, 06:07 to
/// 06:37 IST, when the headline becomes the creak itself and the Dawn
/// Note shows one line), a vitals row (streak, footsteps before the
/// world, stories held), and - for forever members - one line about
/// tonight's jury. It disappears when the house switches the Early
/// Door off, and it is quiet when the database cannot be reached.
/// Tapping it opens the Early Door sheet, with your own recording.
/// ============================================================
class EarlyDoorCard extends StatefulWidget {
  const EarlyDoorCard({super.key});

  @override
  State<EarlyDoorCard> createState() => _EarlyDoorCardState();
}

class _EarlyDoorCardState extends State<EarlyDoorCard>
    with SingleTickerProviderStateMixin {
  Timer? _tick;
  Timer? _later;
  late final AnimationController _seam = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat(reverse: true);
  Map<String, dynamic> _d = <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    EarlyService.instance.state.addListener(_changed);
    HeartService.instance.state.addListener(_heartMoved);
    EarlyService.instance.refresh();
    _report();
    _tick = Timer.periodic(const Duration(seconds: 30), (Timer _) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    EarlyService.instance.state.removeListener(_changed);
    HeartService.instance.state.removeListener(_heartMoved);
    _tick?.cancel();
    _later?.cancel();
    _seam.dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _report() async {
    final Map<String, dynamic> m = await EarlyService.instance.dawnReport();
    if (mounted) setState(() => _d = m);
  }

  /// Lighting the heart can open the door: ask again, a little later.
  void _heartMoved() {
    _later?.cancel();
    _later = Timer(const Duration(milliseconds: 2500), () {
      EarlyService.instance.refresh(force: true);
      _report();
    });
  }

  Future<void> _open() async {
    // Your own Early Door recording (silent if it is missing).
    SoundBank.instance.play('early_door');
    await showEarlyDoorSheet(context);
    SoundBank.instance.stop('early_door');
  }

  int _i(String k) => (_d[k] is int)
      ? _d[k] as int
      : (_d[k] is num ? (_d[k] as num).toInt() : 0);

  String _headline(EarlyState s, bool creak) {
    if (creak) return 'The door creaked open at 06:07';
    if (s.isOpen) return 'Your door is open';
    if (s.rungHours > 0 && !s.warm) return 'Light your heart to open it';
    return 'The door is waiting';
  }

  String _line(EarlyState s, bool creak) {
    if (creak) {
      final String note = (_d['note'] ?? '').toString();
      if (note.isNotEmpty) return note;
    }
    if (s.paid && s.hours >= 100000) {
      return 'Every new story is yours the moment it is shared.';
    }
    if (s.isOpen) {
      return 'You read new stories ${earlyHoursText(s.hours)} before everyone.';
    }
    if (s.rungHours > 0 && !s.warm) {
      return 'Your heart has gone quiet. Light it today and your door opens '
          '${earlyHoursText(s.rungHours)} early.';
    }
    final EarlyWindow? next = s.nextWindow;
    if (next != null) {
      return 'Climb to ${next.name} and it opens '
          '${earlyHoursText(next.hours)} early.';
    }
    return 'Keep your heart lit and climb the Ivory Ladder.';
  }

  String? _vitals() {
    if (_d['ok'] != true) return null;
    final int streak = _i('streak');
    final int foot = _i('foot_today');
    final List<String> bits = <String>[];
    if (streak > 0) bits.add('$streak dawn${streak == 1 ? '' : 's'} deep');
    if (foot > 0) {
      bits.add('$foot footstep${foot == 1 ? '' : 's'} before the world today');
    }
    return bits.isEmpty ? null : bits.join(' · ');
  }

  String? _jury(EarlyState s) {
    if (_d['ok'] != true || s.paid) return null;
    final int seats = _i('seats_today');
    final int sup = _i('super_today');
    if (seats <= 0) return null;
    return 'Tonight the jury holds $seats seat${seats == 1 ? '' : 's'}'
        '${sup > 0 ? ', calling it a super hit' : ''}.';
  }

  String? _waiting(EarlyState s) {
    final List<EarlyPost> mine =
        s.posts.where((EarlyPost p) => p.canOpen).toList();
    if (mine.isNotEmpty) {
      final EarlyPost first = mine.first;
      return mine.length == 1
          ? 'Waiting for you: ${first.title}'
          : 'Waiting for you: ${mine.length} early stories';
    }
    if (s.posts.isNotEmpty) {
      final EarlyPost first = s.posts.first;
      return 'Next story opens for you ${earlyCountdown(first.opensAt)}';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final EarlyState? s = EarlyService.instance.state.value;
    if (s == null) return const SizedBox.shrink();
    final bool creak = dawnInCreak();
    final String? waiting = _waiting(s);
    final String? vitals = _vitals();
    final String? jury = _jury(s);
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: GestureDetector(
        onTap: _open,
        child: JewelPlate(
          colors: const <Color>[
            Color(0xFF8A3FD1),
            Color(0xFF6A25B0),
            Color(0xFF52198F),
            Color(0xFF6D28B5),
            Color(0xFF591C98),
          ],
          stops: const <double>[0, 0.3, 0.55, 0.8, 1],
          rim: const Color(0xFFFFE9A8),
          spark: const Color(0xFFFFF3C4),
          shade: const Color(0xFF3E1570),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // The seam of dawn light; it quickens in the creak window.
              AnimatedBuilder(
                animation: _seam,
                builder: (BuildContext context, Widget? child) {
                  final double t = _seam.value;
                  final double glow = creak ? 0.55 + 0.45 * t : 0.18 + 0.22 * t;
                  return Container(
                    height: 2.4,
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: LinearGradient(
                        colors: <Color>[
                          const Color(0xFFFFE9A8).withValues(alpha: glow * 0.4),
                          const Color(0xFFFFC46B).withValues(alpha: glow),
                          const Color(0xFFFF9A6B).withValues(alpha: glow * 0.7),
                          const Color(0xFFFFE9A8).withValues(alpha: glow * 0.4),
                        ],
                        stops: <double>[0, 0.35 + 0.3 * t, 0.7, 1],
                      ),
                    ),
                  );
                },
              ),
              Row(
                children: <Widget>[
                  AmethystDoor(openness: earlyOpenness(s.hours)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          creak ? 'THE DAWN DOOR' : 'THE EARLY DOOR',
                          style: TextStyle(
                            color: const Color(0xFFEBD6FF),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.4,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _headline(s, creak),
                          style: const TextStyle(
                            color: Color(0xFFFFF6FF),
                            shadows: <Shadow>[
                              Shadow(
                                color: Color(0x663E1570),
                                offset: Offset(0, 1.5),
                                blurRadius: 3,
                              ),
                            ],
                            fontFamily: IvoryTheme.displayFont,
                            fontSize: 20,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _line(s, creak),
                          maxLines: creak ? 3 : null,
                          style: TextStyle(
                            color: const Color(0xFFF3E6FF),
                            fontSize: 12.5,
                            height: 1.35,
                            fontStyle: creak ? FontStyle.italic : null,
                          ),
                        ),
                        if (vitals != null) ...<Widget>[
                          const SizedBox(height: 6),
                          Text(
                            vitals,
                            style: const TextStyle(
                              color: Color(0xCCFFE9A8),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                        if (jury != null) ...<Widget>[
                          const SizedBox(height: 4),
                          Text(
                            jury,
                            style: const TextStyle(
                              color: Color(0xBFE3C7FF),
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        if (waiting != null) ...<Widget>[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFFFF)
                                  .withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              waiting,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFFFF6FF),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// END OF FILE - lib/widgets/early_door_card.dart
