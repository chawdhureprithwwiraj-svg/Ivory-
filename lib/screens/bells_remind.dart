import 'package:flutter/material.dart';

import '../core/ivory_errors.dart';
import '../services/bells_service.dart';
import '../services/push_service.dart';

/// ============================================================
/// IVORY - BELL REMINDERS, THE MEMBER'S OWN SWITCH
///
/// A gentle phone reminder when a bell opens and is still waiting.
/// It is on by default and the member can turn it off here at any
/// time. If the house has switched reminders off, the row is not
/// shown (nothing shown may be untrue). If the phone itself has
/// notifications refused, the row says so honestly.
/// ============================================================
class BellsRemindRow extends StatefulWidget {
  const BellsRemindRow({super.key});

  @override
  State<BellsRemindRow> createState() => _BellsRemindRowState();
}

class _BellsRemindRowState extends State<BellsRemindRow> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    BellsService.instance.loadPush().catchError((_) {});
  }

  Future<void> _flip(bool v) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await BellsService.instance.setPush(v);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(houseMessage(e))));
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool?>(
      valueListenable: BellsService.instance.pushHouseOn,
      builder: (BuildContext _, bool? house, Widget? __) {
        if (house != true) return const SizedBox.shrink();
        return ValueListenableBuilder<bool>(
          valueListenable: BellsService.instance.pushOn,
          builder: (BuildContext _, bool on, Widget? __) =>
              ValueListenableBuilder<bool>(
                valueListenable: PushService.refused,
                builder: (BuildContext _, bool refused, Widget? __) => Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Icon(
                            on
                                ? Icons.notifications_active_rounded
                                : Icons.notifications_off_rounded,
                            color: const Color(0xFFBFF4FF),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Bell reminders',
                              style: TextStyle(
                                color: Color(0xFFE4DAFF),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Switch(
                            value: on,
                            activeThumbColor: const Color(0xFF4DF0A8),
                            onChanged: _busy ? null : _flip,
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 34),
                        child: Text(
                          refused
                              ? 'Notifications are switched off for Ivory on this phone, so no reminder can reach you. You can allow them in your phone settings.'
                              : on
                              ? 'A gentle reminder when a bell opens and is still waiting.'
                              : 'No reminders. The bells still wait for you.',
                          style: const TextStyle(
                            color: Color(0xFFCFC2F5),
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        );
      },
    );
  }
}

// END OF FILE - lib/screens/bells_remind.dart
