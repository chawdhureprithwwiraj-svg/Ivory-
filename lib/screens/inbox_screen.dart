import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/ivory_notification.dart';
import '../core/ivory_errors.dart';
import '../services/notification_service.dart';
import '../theme/ivory_theme.dart';
import '../widgets/inbox_notification_tile.dart';
import '../widgets/report_sheet.dart';

int? _callIdFromActionUrl(String? value) {
  if (value == null) return null;
  final Uri? uri = Uri.tryParse(value.trim());
  if (uri == null || uri.scheme != 'ivory' || uri.host != 'call') return null;
  if (uri.pathSegments.length != 1) return null;
  final int? id = int.tryParse(uri.pathSegments.single);
  return id != null && id > 0 ? id : null;
}

bool _isInternalCallLink(String? value) {
  final Uri? uri = value == null ? null : Uri.tryParse(value.trim());
  return uri != null && uri.scheme == 'ivory' && uri.host == 'call';
}

/// Sanctuary Inbox - announcements, new drops, wish updates.
class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key, this.onOpenTab, this.onOpenCall});

  /// Lets a notification jump to another tab, e.g. 'feed' or 'wish'.
  final void Function(String tab)? onOpenTab;

  /// Opens the exact call named by its private `ivory://call/<id>` link.
  final void Function(int callId)? onOpenCall;

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  List<IvoryNotification> _items = <IvoryNotification>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    // The bell was counting arrivals the list never showed.
    NotificationService.instance.revision.addListener(_quietReload);
  }

  @override
  void dispose() {
    NotificationService.instance.revision.removeListener(_quietReload);
    super.dispose();
  }

  /// Reload without the spinner. Something new has landed; it should
  /// simply appear, the way a letter appears on a mat.
  void _quietReload() {
    if (mounted) _load(quiet: true);
  }

  Future<void> _load({bool quiet = false}) async {
    setState(() {
      _loading = !quiet;
      _error = null;
    });
    try {
      final List<IvoryNotification> items =
          await NotificationService.instance.fetch();
      await NotificationService.instance.refreshUnread();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = houseMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _open(IvoryNotification n) async {
    if (!n.isRead) {
      await NotificationService.instance.markRead(n.id);
      await _load();
    }
    if (!mounted) return;

    // An attachment always wins: a picture, a recording, a video or a
    // link travels with the message and opens straight away.
    final String? url = n.actionUrl;
    if (url != null && url.trim().isNotEmpty) {
      final Uri? uri = Uri.tryParse(url.trim());
      if (_isInternalCallLink(url)) {
        final int? callId = _callIdFromActionUrl(url);
        if (callId != null && widget.onOpenCall != null) {
          widget.onOpenCall!(callId);
          return;
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open that session.')),
        );
        return;
      }
      if (uri != null) {
        final bool ok =
            await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (ok) return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open that attachment.')),
      );
      return;
    }

    final String? tab = n.actionTab;
    if (tab != null && widget.onOpenTab != null) {
      widget.onOpenTab!(tab);
    }
  }

  @override
  Widget build(BuildContext context) {
    final int unread = _items.where((IvoryNotification n) => !n.isRead).length;
    final Set<int> replaced = supersededOffers(_items);
    final List<IvoryNotification> pinned = _items
        .where((IvoryNotification n) =>
            n.isPriorityNotice && !n.isRead && !replaced.contains(n.id))
        .toList();
    final Set<int> pinnedIds =
        pinned.map((IvoryNotification n) => n.id).toSet();
    final List<IvoryNotification> displayItems = <IvoryNotification>[
      ...pinned,
      ..._items.where((IvoryNotification n) => !pinnedIds.contains(n.id)),
    ];

    return Container(
      decoration: const BoxDecoration(gradient: IvoryColors.pageGradient),
      child: RefreshIndicator(
        color: IvoryColors.burgundy,
        backgroundColor: IvoryColors.surface,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 36),
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Sanctuary Inbox',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'New drops, wish updates and word from Ivory.',
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.4,
                          color: IvoryColors.textSoft,
                        ),
                      ),
                    ],
                  ),
                ),
                if (unread > 0)
                  TextButton(
                    onPressed: () async {
                      await NotificationService.instance.markAllRead();
                      await _load();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: IvoryColors.burgundy,
                    ),
                    child: const Text('Mark all read'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 70),
                child: Center(
                  child: CircularProgressIndicator(color: IvoryColors.burgundy),
                ),
              )
            else if (_error != null)
              _Empty(
                icon: Icons.cloud_off,
                title: 'Inbox unavailable',
                body: _error!,
              )
            else if (_items.isEmpty)
              const _Empty(
                icon: Icons.notifications_none,
                title: 'Nothing yet',
                body:
                    'When a new story, voice note or poll arrives, you will '
                    'find it here first.',
              )
            else
              ...displayItems.map(
                (IvoryNotification n) => InboxNotificationTile(
                  item: n,
                  priority: pinnedIds.contains(n.id),
                  // An older offer of more time cannot still be
                  // the live one. See supersededOffers.
                  superseded: replaced.contains(n.id),
                  showAttachment: n.actionUrl != null &&
                      n.actionUrl!.trim().isNotEmpty &&
                      !_isInternalCallLink(n.actionUrl),
                  onTap: () => _open(n),
                  onLongPress: () => showReportSheet(
                    context,
                    preset: 'content',
                    onOpenTab: widget.onOpenTab,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 54, horizontal: 10),
      child: Column(
        children: <Widget>[
          Icon(icon, size: 46, color: IvoryColors.amber),
          const SizedBox(height: 14),
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: IvoryColors.textSoft,
            ),
          ),
        ],
      ),
    );
  }
}

// END OF FILE - lib/screens/inbox_screen.dart
