import 'dart:async';

import 'package:flutter/material.dart';

import '../screens/early_door_sheet.dart';
import '../services/early_service.dart';
import '../services/heart_service.dart';
import '../theme/ivory_theme.dart';
import 'early_door_view.dart';

/// ============================================================
/// IVORY - THE EARLY DOOR, ON THE HOME SCREEN
///
/// One emerald card with the door on the left. It says, in plain
/// words, whether the member's door is open, how far ahead it lets
/// them read, and what is waiting. It disappears completely when the
/// house has switched the Early Door off, and it is quiet when the
/// database cannot be reached. Tapping it opens the Early Door sheet.
/// ============================================================
class EarlyDoorCard extends StatefulWidget {
  const EarlyDoorCard({super.key});

  @override
  State<EarlyDoorCard> createState() => _EarlyDoorCardState();
}

class _EarlyDoorCardState extends State<EarlyDoorCard> {
  Timer? _tick;
  Timer? _later;

  @override
  void initState() {
    super.initState();
    EarlyService.instance.state.addListener(_changed);
    HeartService.instance.state.addListener(_heartMoved);
    EarlyService.instance.refresh();
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
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  /// Lighting the heart can open the door: ask again, a little later.
  void _heartMoved() {
    _later?.cancel();
    _later = Timer(const Duration(milliseconds: 2500), () {
      EarlyService.instance.refresh(force: true);
    });
  }

  String _headline(EarlyState s) {
    if (s.isOpen) return 'Your door is open';
    if (s.rungHours > 0 && !s.warm) return 'Light your heart to open it';
    return 'The door is waiting';
  }

  String _line(EarlyState s) {
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
    final String? waiting = _waiting(s);
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: GestureDetector(
        onTap: () => showEarlyDoorSheet(context),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                IvoryColors.emeraldMid,
                IvoryColors.emerald,
              ],
            ),
            border: Border.all(
              color: IvoryColors.emeraldLight.withValues(alpha: 0.7),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: IvoryColors.emerald.withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              EarlyDoorView(openness: earlyOpenness(s.hours)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'THE EARLY DOOR',
                      style: TextStyle(
                        color: IvoryColors.emeraldWash.withValues(alpha: 0.78),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.4,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _headline(s),
                      style: const TextStyle(
                        color: IvoryColors.emeraldWash,
                        fontFamily: IvoryTheme.displayFont,
                        fontSize: 20,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _line(s),
                      style: TextStyle(
                        color: IvoryColors.emeraldWash.withValues(alpha: 0.9),
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                    if (waiting != null) ...<Widget>[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: IvoryColors.emeraldWash.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          waiting,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: IvoryColors.emeraldWash,
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
        ),
      ),
    );
  }
}

// END OF FILE - lib/widgets/early_door_card.dart
