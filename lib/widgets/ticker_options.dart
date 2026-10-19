import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/cheer_service.dart';
import '../services/ticker_service.dart';
import 'ticker_sound.dart';

/// ============================================================
/// IVORY - TWO SMALL CHOICES FOR THE RIBBONS (on the Showcase card)
///
/// Both are kept on this phone only. Ribbons: show the slim ribbons
/// that glide across the top of the screen. Chimes: the soft little
/// sounds that come with them.
/// ============================================================
class TickerOptionsRows extends StatelessWidget {
  const TickerOptionsRows({
    super.key,
    required this.white,
    required this.soft,
    required this.track,
  });

  final Color white;
  final Color soft;
  final Color track;

  Widget _row(
    String title,
    String sub,
    ValueListenable<bool> v,
    ValueChanged<bool> on,
  ) {
    return ValueListenableBuilder<bool>(
      valueListenable: v,
      builder: (BuildContext context, bool value, Widget? _) {
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: TextStyle(
                        color: white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      style: TextStyle(color: soft, fontSize: 11.5, height: 1.35),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: on,
                activeThumbColor: white,
                activeTrackColor: track,
                inactiveThumbColor: soft,
                inactiveTrackColor: const Color(0x33FFFFFF),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _row(
          'Show ribbons on this phone',
          'Slim ribbons now and then celebrate what members have earned.',
          TickerService.instance.showRibbons,
          (bool v) => TickerService.instance.setRibbons(v),
        ),
        _row(
          'Soft chimes with the ribbons',
          'A tiny, gentle sound as a ribbon arrives.',
          TickerSound.instance.on,
          (bool v) => TickerSound.instance.setOn(v),
        ),
        // Only shown while the house has Cheers switched on.
        ValueListenableBuilder<bool>(
          valueListenable: TickerService.instance.cheersLive,
          builder: (BuildContext context, bool live, Widget? _) {
            if (!live) return const SizedBox.shrink();
            return _row(
              'Let members cheer my moments',
              'Other members can send a small wordless cheer when a ribbon celebrates something you earned.',
              CheerService.instance.accepts,
              (bool v) => CheerService.instance.setPref(v),
            );
          },
        ),
      ],
    );
  }
}

// END OF FILE - lib/widgets/ticker_options.dart
