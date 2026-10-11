import 'package:flutter/material.dart';

import '../models/live_models.dart';
import '../services/live_service.dart';
import '../theme/ivory_theme.dart';
import 'call_sheet_bits.dart';

/// The Profile shortcut changes its name when there is a real booked call.
/// Tapping either state opens Wish; Wish itself brings active call cards to
/// the top, while an empty call schedule leaves the member with their wishes.
class ProfileWishShortcut extends StatefulWidget {
  const ProfileWishShortcut({
    super.key,
    required this.onOpenWish,
    this.onOpenScheduledCall,
  });

  final VoidCallback onOpenWish;
  final ValueChanged<int>? onOpenScheduledCall;

  @override
  State<ProfileWishShortcut> createState() => _ProfileWishShortcutState();
}

class _ProfileWishShortcutState extends State<ProfileWishShortcut> {
  List<CallRequest> _scheduled = <CallRequest>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final List<CallRequest> calls = await LiveService.instance.myCalls();
      const Set<String> finished = <String>{
        'done',
        'completed',
        'ended',
        'cancelled',
        'canceled',
        'declined',
        'rejected',
        'missed',
        'expired',
      };
      final List<CallRequest> upcoming = calls
          .where((CallRequest call) =>
              call.requestedFor != null &&
              !finished.contains(call.status.toLowerCase()))
          .toList()
        ..sort((CallRequest a, CallRequest b) =>
            a.requestedFor!.compareTo(b.requestedFor!));
      if (mounted) setState(() => _scheduled = upcoming);
    } catch (_) {
      // Keep the regular wishes route available if the call list is offline.
    }
  }

  @override
  Widget build(BuildContext context) {
    final CallRequest? next = _scheduled.isEmpty ? null : _scheduled.first;
    final String title = next == null ? 'Your wishes' : 'Your next session';
    final String subtitle = next == null
        ? 'Requests and personal wishes you have sent.'
        : '${next.isVideo ? 'Video' : 'Voice'} call · '
            '${ivoryWhen(next.requestedFor!)}'
            '${_scheduled.length > 1 ? ' · +${_scheduled.length - 1} more' : ''}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            final int? id = next?.id;
            final ValueChanged<int>? openCall = widget.onOpenScheduledCall;
            if (id != null && openCall != null) {
              openCall(id);
            } else {
              widget.onOpenWish();
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: next == null ? IvoryColors.surface : IvoryColors.surfaceWarm,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: next == null ? IvoryColors.hairline : IvoryColors.gold,
                width: next == null ? 1 : 1.3,
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: next == null
                        ? null
                        : IvoryColors.goldGradient,
                    color: next == null ? IvoryColors.cream : null,
                  ),
                  child: Icon(
                    next == null
                        ? Icons.auto_awesome_rounded
                        : (next.isVideo
                            ? Icons.videocam_rounded
                            : Icons.phone_in_talk_rounded),
                    color: IvoryColors.burgundy,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (next != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            'BOOKED WITH IVORY',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: IvoryColors.amber,
                            ),
                          ),
                        ),
                      Text(
                        title,
                        style: const TextStyle(
                          color: IvoryColors.burgundy,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: IvoryColors.textSoft,
                          fontSize: 12.1,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: IvoryColors.plum),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// END OF FILE - lib/widgets/profile_wish_shortcut.dart
