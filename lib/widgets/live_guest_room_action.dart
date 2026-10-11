import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/live_guest_models.dart';
import '../services/live_guest_service.dart';
import '../theme/ivory_theme.dart';
import 'live_guest_entry_sheet.dart';
import 'live_guest_host_sheet.dart';

class LiveGuestRoomAction extends StatefulWidget {
  const LiveGuestRoomAction({
    super.key,
    required this.sessionId,
    required this.title,
    required this.isHost,
    required this.guestPriceInr,
    required this.requestsOpen,
    required this.onJoin,
    required this.onRemoved,
  });

  final int sessionId;
  final String title;
  final bool isHost;
  final int guestPriceInr;
  final bool requestsOpen;
  final ValueChanged<LiveGuestRequest> onJoin;
  final VoidCallback onRemoved;

  @override
  State<LiveGuestRoomAction> createState() => _LiveGuestRoomActionState();
}

class _LiveGuestRoomActionState extends State<LiveGuestRoomAction> {
  LiveGuestRequest? _mine;
  int _occupied = 0;
  int _pending = 0;
  bool _requestsOpen = true;
  bool _loading = true;
  bool _removedNotified = false;
  RealtimeChannel? _requestsChannel;
  RealtimeChannel? _settingsChannel;

  @override
  void initState() {
    super.initState();
    _requestsOpen = widget.requestsOpen;
    _load();
    _requestsChannel = LiveGuestService.instance
        .watchRequests(widget.sessionId, _load);
    if (!widget.isHost) {
      _settingsChannel = LiveGuestService.instance
          .watchSettings(widget.sessionId, _load);
    }
  }

  @override
  void didUpdateWidget(covariant LiveGuestRoomAction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.requestsOpen != widget.requestsOpen) {
      _requestsOpen = widget.requestsOpen;
    }
  }

  @override
  void dispose() {
    final RealtimeChannel? requests = _requestsChannel;
    final RealtimeChannel? settings = _settingsChannel;
    if (requests != null) LiveGuestService.instance.stopWatching(requests);
    if (settings != null) LiveGuestService.instance.stopWatching(settings);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      if (widget.isHost) {
        final List<LiveGuestRequest> rows =
            await LiveGuestService.instance.requestsForHost(widget.sessionId);
        final bool open = await LiveGuestService.instance
            .guestRequestsOpen(widget.sessionId);
        if (!mounted) return;
        setState(() {
          _requestsOpen = open;
          _occupied = rows
              .where((LiveGuestRequest r) =>
                  r.status == 'approved' ||
                  r.status == 'joining' ||
                  r.status == 'active')
              .length;
          _pending = rows.where((LiveGuestRequest r) => r.isWaiting).length;
          _loading = false;
        });
      } else {
        final LiveGuestRequest? r =
            await LiveGuestService.instance.myRequest(widget.sessionId);
        final bool open =
            await LiveGuestService.instance.guestRequestsOpen(widget.sessionId);
        if (!mounted) return;
        setState(() {
          _mine = r;
          _requestsOpen = open;
          _loading = false;
        });
        if (r?.status == 'removed' && !_removedNotified) {
          _removedNotified = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) widget.onRemoved();
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open() async {
    if (widget.isHost) {
      await showLiveGuestHostSheet(
        context,
        sessionId: widget.sessionId,
        guestPriceInr: widget.guestPriceInr,
        requestsOpen: _requestsOpen,
      );
      await _load();
      return;
    }
    final LiveGuestRequest? request = _mine;
    if (request != null &&
        request.status == 'cancelled' &&
        (request.creditAppliedInr > 0 || request.cashPaidInr > 0)) {
      return;
    }
    if (request != null &&
        (request.isApproved ||
            (request.status == 'left' && request.joinedAt == null))) {
      widget.onJoin(request);
      return;
    }
    if (request == null ||
        request.status == 'payment_rejected' ||
        request.status == 'cancelled' ||
        (request.status == 'left' && request.joinedAt != null)) {
      await showLiveGuestEntrySheet(
        context,
        sessionId: widget.sessionId,
        title: widget.title,
        feeInr: widget.guestPriceInr,
      );
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isHost) {
      return _pill(
        label: _pending > 0
            ? 'GUEST REQUESTS $_pending · $_occupied/5'
            : 'GUESTS $_occupied/5',
        icon: _pending > 0
            ? Icons.notifications_active_rounded
            : Icons.groups_rounded,
        onTap: _open,
      );
    }
    if (_loading || widget.guestPriceInr <= 0) return const SizedBox.shrink();
    final LiveGuestRequest? r = _mine;
    final bool hasCredit = r != null &&
        (r.creditAppliedInr > 0 || r.cashPaidInr > 0);
    if (r?.status == 'cancelled' && hasCredit) {
      return _pill(
        label: 'CREDIT SAVED FOR A FUTURE LIVE',
        icon: Icons.account_balance_wallet_outlined,
      );
    }
    if (r == null ||
        r.status == 'payment_rejected' ||
        r.status == 'cancelled') {
      if (!_requestsOpen) return const SizedBox.shrink();
      return _pill(
        label: r == null
            ? 'REQUEST TO JOIN · ₹${widget.guestPriceInr}'
            : 'TRY GUEST REQUEST AGAIN',
        icon: Icons.videocam_rounded,
        onTap: _open,
      );
    }
    if (r.status == 'left' && r.joinedAt != null) {
      if (!_requestsOpen) return const SizedBox.shrink();
      return _pill(
        label: 'REQUEST ANOTHER GUEST PLACE · ₹${widget.guestPriceInr}',
        icon: Icons.videocam_rounded,
        onTap: _open,
      );
    }
    if (r.status == 'approved' || r.status == 'left') {
      return _pill(
        label: r.status == 'left' ? 'REJOIN AS GUEST' : 'JOIN AS GUEST',
        icon: Icons.sensors_rounded,
        onTap: _open,
      );
    }
    final String label = switch (r.status) {
      'awaiting_payment' => 'PAYMENT NOT FINISHED',
      'payment_review' => 'UPI PAYMENT IN REVIEW',
      'waiting_host' => 'PAID · WAITING FOR IVORY',
      'active' => 'YOU ARE LIVE',
      'declined' => 'CREDIT SAVED FOR A FUTURE LIVE',
      'expired' => hasCredit
          ? 'CREDIT SAVED FOR A FUTURE LIVE'
          : 'GUEST REQUEST CLOSED',
      'removed' => r.joinedAt == null && hasCredit
          ? 'CREDIT SAVED FOR A FUTURE LIVE'
          : 'GUEST PLACE ENDED',
      _ => 'GUEST REQUEST IN PROGRESS',
    };
    return _pill(label: label, icon: Icons.hourglass_top_rounded);
  }

  Widget _pill({
    required String label,
    required IconData icon,
    VoidCallback? onTap,
  }) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Material(
            color: IvoryColors.burgundy.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(22),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(icon, color: IvoryColors.gold, size: 15),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: const TextStyle(
                        color: IvoryColors.cream,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

// END OF FILE - lib/widgets/live_guest_room_action.dart
