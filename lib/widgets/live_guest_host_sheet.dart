import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/live_guest_models.dart';
import '../services/live_guest_service.dart';
import '../theme/ivory_theme.dart';

Future<void> showLiveGuestHostSheet(
  BuildContext context, {
  required int sessionId,
  required int guestPriceInr,
  required bool requestsOpen,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => LiveGuestHostSheet(
      sessionId: sessionId,
      guestPriceInr: guestPriceInr,
      requestsOpen: requestsOpen,
    ),
  );
}

class LiveGuestHostSheet extends StatefulWidget {
  const LiveGuestHostSheet({
    super.key,
    required this.sessionId,
    required this.guestPriceInr,
    required this.requestsOpen,
  });

  final int sessionId;
  final int guestPriceInr;
  final bool requestsOpen;

  @override
  State<LiveGuestHostSheet> createState() => _LiveGuestHostSheetState();
}

class _LiveGuestHostSheetState extends State<LiveGuestHostSheet> {
  List<LiveGuestRequest> _requests = <LiveGuestRequest>[];
  bool _open = true;
  bool _loading = true;
  int? _busyId;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _open = widget.requestsOpen;
    _load();
    _channel = LiveGuestService.instance.watchRequests(widget.sessionId, _load);
  }

  @override
  void dispose() {
    final RealtimeChannel? c = _channel;
    if (c != null) LiveGuestService.instance.stopWatching(c);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final List<LiveGuestRequest> rows =
          await LiveGuestService.instance.requestsForHost(widget.sessionId);
      final bool open = await LiveGuestService.instance
          .guestRequestsOpen(widget.sessionId);
      if (!mounted) return;
      setState(() {
        _open = open;
        _requests = rows;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle(bool value) async {
    setState(() => _open = value);
    try {
      await LiveGuestService.instance.setRequestsOpen(widget.sessionId, value);
    } catch (_) {
      if (mounted) setState(() => _open = !value);
    }
  }

  Future<void> _respond(LiveGuestRequest request, bool approve) async {
    setState(() => _busyId = request.id);
    try {
      await LiveGuestService.instance.respond(request.id, approve: approve);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _remove(LiveGuestRequest request) async {
    setState(() => _busyId = request.id);
    try {
      await LiveGuestService.instance.remove(request.id);
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('That guest could not be removed.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final int occupied = _requests
        .where((LiveGuestRequest r) =>
            r.status == 'approved' || r.status == 'joining' || r.status == 'active')
        .length;
    return SafeArea(
      top: false,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.78,
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
        decoration: const BoxDecoration(
          color: IvoryColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: <Widget>[
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: IvoryColors.gold,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Guest speakers · $occupied/5 places',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              activeColor: IvoryColors.burgundy,
              title: Text(_open ? 'Requests are open' : 'Requests are closed'),
              subtitle: Text(widget.guestPriceInr > 0
                  ? 'Closing stops new paid requests.'
                  : 'Guest places are off because the fee is zero.'),
              value: _open && widget.guestPriceInr > 0,
              onChanged: widget.guestPriceInr > 0 ? _toggle : null,
            ),
            const Divider(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _requests.isEmpty
                      ? Center(
                          child: Text(
                            'No paid guest requests yet.',
                            style: TextStyle(color: IvoryColors.textSoft),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _requests.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (BuildContext context, int index) =>
                              _requestCard(_requests[index]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _requestCard(LiveGuestRequest r) {
    final bool waiting = r.status == 'waiting_host';
    final bool occupies = r.status == 'approved' ||
        r.status == 'joining' || r.status == 'active' || r.status == 'left';
    final bool busy = _busyId == r.id;
    final String mode = r.mediaKind == 'audio' ? 'AUDIO ONLY' : 'VIDEO';
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: IvoryTheme.card(highlighted: waiting),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.person_rounded,
                  color: IvoryColors.amber, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  r.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text('₹${r.feeInr}',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 3),
          Text('$mode · ${r.status.replaceAll('_', ' ').toUpperCase()}',
              style: TextStyle(fontSize: 11.5, color: IvoryColors.textSoft)),
          if (waiting) ...<Widget>[
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: IvoryGradientButton(
                    label: busy ? 'PLEASE WAIT' : 'APPROVE',
                    icon: Icons.check_rounded,
                    busy: busy,
                    onPressed: busy ? null : () => _respond(r, true),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: busy ? null : () => _respond(r, false),
                  child: const Text('DECLINE'),
                ),
              ],
            ),
          ] else if (occupies) ...<Widget>[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: busy ? null : () => _remove(r),
                icon: const Icon(Icons.person_remove_alt_1_rounded, size: 17),
                label: const Text('REMOVE'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// END OF FILE - lib/widgets/live_guest_host_sheet.dart
