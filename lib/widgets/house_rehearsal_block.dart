import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/bells_service.dart';
import '../services/crest_service.dart';
import '../services/heart_service.dart';
import '../services/ladder_service.dart';
import '../services/reward_service.dart';

/// ============================================================
/// IVORY - THE HOUSE IS NOT A MEMBER (on the Admin's Showcase card)
///
/// The Admin account may open every member screen to see how it
/// looks, but nothing it does there is kept. This block replaces the
/// "show my name to other members" switch (which has no meaning for
/// the house) and explains it in plain words. A night-time sweep
/// clears the account's own bells, heart, ladder, Marks, treasures,
/// personal codes and cheers; the button clears them right now.
/// Members never see this block and are never affected by it.
/// ============================================================
class HouseRehearsalBlock extends StatefulWidget {
  const HouseRehearsalBlock({
    super.key,
    required this.white,
    required this.soft,
    required this.track,
  });

  final Color white;
  final Color soft;
  final Color track;

  @override
  State<HouseRehearsalBlock> createState() => _HouseRehearsalBlockState();
}

class _HouseRehearsalBlockState extends State<HouseRehearsalBlock> {
  bool _auto = true;
  bool _busy = false;
  String? _note;

  SupabaseClient get _db => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final dynamic r = await _db.rpc('house_rehearsal_get');
      if (r is bool && mounted) setState(() => _auto = r);
    } catch (_) {}
  }

  Future<void> _setAuto(bool v) async {
    final bool before = _auto;
    setState(() => _auto = v);
    try {
      final dynamic r = await _db.rpc(
        'house_rehearsal_set',
        params: <String, dynamic>{'on_in': v},
      );
      if (r is bool && mounted) setState(() => _auto = r);
    } catch (_) {
      if (mounted) {
        setState(() {
          _auto = before;
          _note = 'That did not go through. Please try again.';
        });
      }
    }
  }

  Future<void> _clear() async {
    final bool? yes = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Clear your rehearsal?'),
        content: const Text(
          'This clears what this Admin account has earned while trying '
          'things out: bells, heart days, ladder points, Marks, treasures '
          'and cheers. Members are not affected at all.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear it'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    setState(() {
      _busy = true;
      _note = null;
    });
    String say;
    try {
      await _db.rpc('house_rehearsal_reset');
      HeartService.instance.refreshQuietly();
      LadderService.instance.refreshQuietly();
      BellsService.instance.refreshQuietly();
      RewardService.instance.refreshQuietly();
      CrestService.instance.refreshQuietly();
      say = 'Cleared. Every screen starts fresh for you.';
    } catch (_) {
      say = 'That did not go through. Please try again.';
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _note = say;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'REHEARSAL - YOU ARE THE HOUSE',
          style: TextStyle(
            color: widget.white,
            fontWeight: FontWeight.w900,
            fontSize: 11,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'The bells, the Heart, the Ladder, Marks and treasures are here so '
          'you can see exactly how members see them. Nothing you do here is '
          'shown to members, counted, or earned for real. A cheer from you '
          'plays but sends nothing.',
          style: TextStyle(color: widget.soft, fontSize: 11.5, height: 1.35),
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Clear my rehearsal every night',
                    style: TextStyle(
                      color: widget.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'At 4:10 AM India time what this account earned is '
                    'cleared, so nothing builds up.',
                    style: TextStyle(
                      color: widget.soft,
                      fontSize: 11.5,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _auto,
              onChanged: _busy ? null : _setAuto,
              activeThumbColor: widget.white,
              activeTrackColor: widget.track,
              inactiveThumbColor: widget.soft,
              inactiveTrackColor: const Color(0x33FFFFFF),
            ),
          ],
        ),
        const SizedBox(height: 6),
        OutlinedButton.icon(
          onPressed: _busy ? null : _clear,
          icon: Icon(Icons.refresh_rounded, color: widget.white, size: 18),
          label: Text(
            _busy ? 'CLEARING...' : 'CLEAR MY REHEARSAL NOW',
            style: TextStyle(
              color: widget.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
          style: OutlinedButton.styleFrom(
            // CC.197: the app theme fills outlined buttons cream, which
            // swallowed this button's white words on the purple card.
            backgroundColor: const Color(0x00000000),
            foregroundColor: widget.white,
            side: BorderSide(color: widget.white.withValues(alpha: 0.6)),
          ),
        ),
        if (_note != null) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            _note!,
            style: TextStyle(color: widget.soft, fontSize: 11.5),
          ),
        ],
      ],
    );
  }
}

// END OF FILE - lib/widgets/house_rehearsal_block.dart
