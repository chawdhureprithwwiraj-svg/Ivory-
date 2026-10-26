import 'dart:async';
import 'package:flutter/material.dart';

import '../services/wheel_service.dart';
import 'wheel_fx.dart';
import 'wheel_medallion.dart';
import 'wheel_room.dart';

/// The Wheel of Fans host — wraps the signed-in shell. It carries the
/// floating medallion on every member screen, refreshes the wheel truth
/// every half minute, and once per Gilded Hour per opening of the app
/// presents the ceremony: the owner's film, the burst, the wheel falling
/// from the heaven of the screen. Never a gate: every surface of it can
/// be closed or skipped.
class WheelHost extends StatefulWidget {
  const WheelHost({super.key, required this.child});
  final Widget child;

  @override
  State<WheelHost> createState() => _WheelHostState();
}

class _WheelHostState extends State<WheelHost> {
  Map<String, dynamic> _s = <String, dynamic>{};
  Timer? _t;
  static String _ceremonyKey = '';
  bool _roomOpen = false;

  @override
  void initState() {
    super.initState();
    WofSound.preload();
    _refresh();
    _t = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
  }

  Future<void> _refresh() async {
    final Map<String, dynamic> m = await WheelService.instance.state();
    if (!mounted) return;
    setState(() => _s = m);
    final bool open = m['open'] == true;
    final String key = '${DateTime.now().toIso8601String().substring(0, 10)}'
        '|${m['window']}';
    if (open && _ceremonyKey != key && !_roomOpen) {
      _ceremonyKey = key;
      _openRoom(ceremony: true);
    }
  }

  void _openRoom({bool ceremony = false}) {
    if (_roomOpen || !mounted) return;
    _roomOpen = true;
    Navigator.push<void>(context, WheelRoom.route(ceremony: ceremony))
        .whenComplete(() {
      _roomOpen = false;
      _refresh();
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool open = _s['open'] == true;
    final bool admin = _s['is_admin'] == true;
    return Stack(
      children: <Widget>[
        widget.child,
        if (!admin)
          Positioned(
            right: 14,
            bottom: 92,
            child: WheelMedallion(
              open: open,
              onTap: () => _openRoom(ceremony: false),
            ),
          ),
      ],
    );
  }
}

// END OF FILE - lib/widgets/wheel_host.dart
