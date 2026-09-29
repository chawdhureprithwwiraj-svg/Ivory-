import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/ivory_notification.dart';
import '../services/notification_service.dart';
import '../theme/ivory_theme.dart';

/// Sanctuary Inbox - announcements, new drops, wish updates.
class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key, this.onOpenTab});

  /// Lets a notification jump to another tab, e.g. 'feed' or 'wish'.
  final void Function(String tab)? onOpenTab;

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
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
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
        _error = e.toString();
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
              ..._items.map(
                (IvoryNotification n) => _NotificationTile(
                  item: n,
                  onTap: () => _open(n),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});

  final IvoryNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool unread = !item.isRead;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(15, 15, 15, 15),
            decoration: IvoryTheme.card(highlighted: unread, radius: 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: unread ? IvoryColors.goldGradient : null,
                    color:
                        unread ? null : IvoryColors.surfaceWarm,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, size: 20, color: IvoryColors.burgundy),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                color: IvoryColors.burgundy,
                                fontSize: 15,
                                fontWeight: unread
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                          if (unread)
                            Container(
                              width: 9,
                              height: 9,
                              decoration: const BoxDecoration(
                                color: IvoryColors.amber,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.body,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.45,
                          color: IvoryColors.textSoft,
                        ),
                      ),
                      if (item.actionUrl != null &&
                          item.actionUrl!.trim().isNotEmpty) ...<Widget>[
                        const SizedBox(height: 10),
                        _Attachment(url: item.actionUrl!.trim()),
                      ],
                      const SizedBox(height: 7),
                      Text(
                        item.whenLabel,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: IvoryColors.textFaint,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// What an attachment looks like inside a message: pictures show
/// themselves, everything else becomes a gold "open" strip.
class _Attachment extends StatelessWidget {
  const _Attachment({required this.url});

  final String url;

  bool get _isImage {
    final String u = url.toLowerCase().split('?').first;
    return u.endsWith('.jpg') ||
        u.endsWith('.jpeg') ||
        u.endsWith('.png') ||
        u.endsWith('.webp') ||
        u.endsWith('.gif');
  }

  bool get _isAudio {
    final String u = url.toLowerCase().split('?').first;
    return u.endsWith('.mp3') ||
        u.endsWith('.m4a') ||
        u.endsWith('.aac') ||
        u.endsWith('.wav') ||
        u.endsWith('.ogg') ||
        u.endsWith('.opus');
  }

  bool get _isVideo {
    final String u = url.toLowerCase().split('?').first;
    return u.endsWith('.mp4') || u.endsWith('.mov') || u.endsWith('.webm');
  }

  @override
  Widget build(BuildContext context) {
    if (_isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: IvoryColors.hairline),
          ),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            height: 168,
            width: double.infinity,
            errorBuilder: (BuildContext c, Object e, StackTrace? st) =>
                _strip(Icons.image_outlined, 'Open the picture'),
            loadingBuilder: (BuildContext c, Widget child,
                ImageChunkEvent? p) {
              if (p == null) return child;
              return Container(
                height: 168,
                alignment: Alignment.center,
                color: IvoryColors.surfaceWarm,
                child: const CircularProgressIndicator(
                    color: IvoryColors.amber, strokeWidth: 2),
              );
            },
          ),
        ),
      );
    }
    if (_isAudio) return _strip(Icons.play_circle_fill, 'Play the recording');
    if (_isVideo) return _strip(Icons.movie_outlined, 'Watch the video');
    return _strip(Icons.open_in_new, 'Open the attachment');
  }

  Widget _strip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: <Color>[Color(0xFFFFFCF2), Color(0xFFFDF1DC)],
          ),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: IvoryColors.hairlineStrong),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 18, color: IvoryColors.plum),
            const SizedBox(width: 9),
            Text(
              label,
              style: const TextStyle(
                color: IvoryColors.burgundy,
                fontSize: 12.8,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right,
                size: 18, color: IvoryColors.plum),
          ],
        ),
      );
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
