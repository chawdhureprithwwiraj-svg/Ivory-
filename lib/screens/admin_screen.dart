import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';

import '../models/wish.dart';
import '../services/admin_service.dart';
import '../services/notification_service.dart';
import '../services/wish_service.dart';
import '../theme/ivory_theme.dart';
import 'admin_create_tab.dart';
import 'admin_payments_tab.dart';
import 'admin_tiers_tab.dart';

/// The mobile admin console: send push-style announcements and work
/// through incoming wishes. Every action is re-checked by the database,
/// so a non-admin who reaches this screen can do nothing.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 5, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ADMIN'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: IvoryColors.burgundy,
          unselectedLabelColor: IvoryColors.textFaint,
          indicatorColor: IvoryColors.amber,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            fontSize: 13,
          ),
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const <Widget>[
            Tab(text: 'CREATE'),
            Tab(text: 'BROADCAST'),
            Tab(text: 'TIERS'),
            Tab(text: 'WISHES'),
            Tab(text: 'PAYMENTS'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: IvoryColors.pageGradient),
        child: SafeArea(
          child: TabBarView(
            controller: _tabs,
            children: <Widget>[
              const AdminCreateTab(),
              const _BroadcastTab(),
              const AdminTiersTab(),
              const _WishTrackerTab(),
              const AdminPaymentsTab(),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// BROADCAST
// =====================================================================
class _BroadcastTab extends StatefulWidget {
  const _BroadcastTab();

  @override
  State<_BroadcastTab> createState() => _BroadcastTabState();
}

class _BroadcastTabState extends State<_BroadcastTab> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _title = TextEditingController();
  final TextEditingController _body = TextEditingController();

  String _audience = 'all';
  String _kind = 'system';
  int _tierLevel = 1;
  String? _userId;
  String _userName = '';
  bool _sending = false;

  /// An optional attachment: a file picked off the phone and uploaded to
  /// Supabase Storage, or a link typed straight in. Either way it ends up
  /// as the notification's action_url, and the Inbox shows it.
  PickedMedia? _attachment;
  String? _attachmentUrl;
  final TextEditingController _linkCtrl = TextEditingController();
  String _status = '';

  static const List<String> _kinds = <String>[
    'system',
    'story',
    'image',
    'audio',
    'video',
    'poll',
    'live',
    'wish',
    'payment',
  ];

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _linkCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPerson() async {
    final TextEditingController search = TextEditingController();
    List<Map<String, dynamic>> people =
        await NotificationService.instance.searchPeople('');
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: IvoryColors.surface,
      builder: (BuildContext sheetContext) => StatefulBuilder(
        builder: (BuildContext c, StateSetter setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 18,
            right: 18,
            top: 18,
            bottom: MediaQuery.of(c).viewInsets.bottom + 18,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: search,
                decoration: const InputDecoration(
                  labelText: 'Search by display name',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (String v) async {
                  final List<Map<String, dynamic>> r =
                      await NotificationService.instance.searchPeople(v);
                  setSheet(() => people = r);
                },
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 320,
                child: ListView.builder(
                  itemCount: people.length,
                  itemBuilder: (BuildContext _, int i) {
                    final Map<String, dynamic> p = people[i];
                    final String id = p['id'] as String;
                    return ListTile(
                      leading: const Icon(Icons.person_outline,
                          color: IvoryColors.plum),
                      title: Text(
                        (p['display_name'] as String?) ?? 'Anonymous',
                        style: const TextStyle(color: IvoryColors.burgundy),
                      ),
                      subtitle: Text(
                        'ID ${id.substring(0, 8).toUpperCase()}'
                        '${p['role'] == 'admin' ? ' · admin' : ''}',
                        style: TextStyle(
                          color: IvoryColors.textFaint,
                          fontSize: 12,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _userId = id;
                          _userName =
                              (p['display_name'] as String?) ?? 'that person';
                        });
                        Navigator.of(sheetContext).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _attach(String what) async {
    try {
      PickedMedia? m;
      switch (what) {
        case 'image':
          m = await AdminService.instance.pickImage();
          break;
        case 'video':
          m = await AdminService.instance.pickVideo();
          break;
        case 'audio':
          m = await AdminService.instance.pickFile(type: FileType.audio);
          break;
        default:
          m = await AdminService.instance.pickFile();
      }
      if (m == null) return;
      if (m.size > 48 * 1024 * 1024) {
        _snack('That file is ${m.sizeLabel}. Keep it under about 48 MB, '
            'or host it and paste the link instead.');
        return;
      }
      setState(() {
        _attachment = m;
        _attachmentUrl = null;
        _linkCtrl.clear();
        if (what == 'image') _kind = 'image';
        if (what == 'audio') _kind = 'audio';
        if (what == 'video') _kind = 'video';
      });
    } catch (e) {
      _snack('Could not open that file: $e');
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    if (_audience == 'user' && _userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose who this is for first.')),
      );
      return;
    }
    setState(() {
      _sending = true;
      _status = '';
    });
    try {
      // 1. upload the attachment, if there is one waiting
      String? url = _attachmentUrl;
      if (_attachment != null && url == null) {
        setState(() => _status = 'Uploading ${_attachment!.sizeLabel}...');
        url = await AdminService.instance
            .upload(_attachment!, folder: 'broadcast');
        _attachmentUrl = url;
      }
      url ??= _linkCtrl.text.trim().isEmpty ? null : _linkCtrl.text.trim();

      // 2. send it
      setState(() => _status = 'Sending...');
      await NotificationService.instance.send(
        title: _title.text.trim(),
        body: _body.text.trim(),
        audience: _audience,
        kind: _kind,
        tierLevel: _audience == 'tier' ? _tierLevel : 0,
        userId: _audience == 'user' ? _userId : null,
        actionTab: 'feed',
        actionUrl: url,
      );
      if (!mounted) return;
      _title.clear();
      _body.clear();
      _linkCtrl.clear();
      setState(() {
        _attachment = null;
        _attachmentUrl = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sent. It is in their inbox and on their phone.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not send: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
          _status = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 40),
        children: <Widget>[
          Text('Send an announcement',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(
            'It lands in the Sanctuary Inbox instantly, lights up the bell '
            'and arrives as a notification on their phone within the '
            'minute. Attach a picture, a voice note, a video or a link and '
            'it travels with the message.',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: IvoryColors.textSoft,
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Title'),
            validator: (String? v) =>
                (v == null || v.trim().length < 3) ? 'Add a title' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _body,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Message',
              alignLabelWithHint: true,
            ),
            validator: (String? v) =>
                (v == null || v.trim().length < 3) ? 'Add a message' : null,
          ),
          const SizedBox(height: 18),
          const Text('WHO SEES IT',
              style: TextStyle(
                color: IvoryColors.plum,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              )),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: <Widget>[
              _chip('Everyone', 'all'),
              _chip('A tier and above', 'tier'),
              _chip('One person', 'user'),
            ],
          ),
          if (_audience == 'tier') ...<Widget>[
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                const Text('Minimum tier level',
                    style: TextStyle(color: IvoryColors.burgundy)),
                const Spacer(),
                IconButton(
                  onPressed: () => setState(
                      () => _tierLevel = _tierLevel > 1 ? _tierLevel - 1 : 1),
                  icon: const Icon(Icons.remove_circle_outline,
                      color: IvoryColors.plum),
                ),
                Text('$_tierLevel',
                    style: const TextStyle(
                      color: IvoryColors.burgundy,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    )),
                IconButton(
                  onPressed: () => setState(() => _tierLevel += 1),
                  icon: const Icon(Icons.add_circle_outline,
                      color: IvoryColors.plum),
                ),
              ],
            ),
          ],
          if (_audience == 'user') ...<Widget>[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _pickPerson,
              icon: const Icon(Icons.person_search, size: 18),
              label: Text(_userId == null ? 'CHOOSE A PERSON' : _userName),
              style: OutlinedButton.styleFrom(
                foregroundColor: IvoryColors.burgundy,
                side: const BorderSide(color: IvoryColors.burgundy),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
          const SizedBox(height: 18),
          const Text('ATTACH SOMETHING (OPTIONAL)',
              style: TextStyle(
                color: IvoryColors.plum,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              )),
          const SizedBox(height: 10),
          _attachmentPanel(),
          const SizedBox(height: 18),
          const Text('STYLE',
              style: TextStyle(
                color: IvoryColors.plum,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              )),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _kinds
                .map((String k) => ChoiceChip(
                      label: Text(k),
                      selected: _kind == k,
                      showCheckmark: false,
                      labelStyle: const TextStyle(
                        color: IvoryColors.burgundy,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) => setState(() => _kind = k),
                    ))
                .toList(),
          ),
          const SizedBox(height: 24),
          IvoryGradientButton(
            label: _sending
                ? (_status.isEmpty ? 'SENDING...' : _status.toUpperCase())
                : 'SEND NOW',
            icon: Icons.campaign,
            busy: _sending,
            onPressed: _sending ? null : _send,
          ),
        ],
      ),
    );
  }

  Widget _attachmentPanel() {
    final PickedMedia? a = _attachment;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: IvoryTheme.card(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (a != null) ...<Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: IvoryColors.goldGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.attachment,
                      color: IvoryColors.burgundy, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        a.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: IvoryColors.burgundy,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                      Text(
                        _attachmentUrl == null
                            ? '${a.sizeLabel} \u00b7 will upload when you send'
                            : '${a.sizeLabel} \u00b7 uploaded',
                        style: TextStyle(
                            fontSize: 11.5, color: IvoryColors.textFaint),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() {
                    _attachment = null;
                    _attachmentUrl = null;
                  }),
                  icon: const Icon(Icons.close, color: IvoryColors.plum),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _attachButton('Photo', Icons.image_outlined, 'image'),
              _attachButton('Voice note', Icons.mic_none, 'audio'),
              _attachButton('Video', Icons.videocam_outlined, 'video'),
              _attachButton('Any file', Icons.attach_file, 'file'),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _linkCtrl,
            keyboardType: TextInputType.url,
            enabled: _attachment == null,
            decoration: InputDecoration(
              labelText: _attachment == null
                  ? 'or paste a link'
                  : 'remove the file to use a link',
              isDense: true,
              prefixIcon: const Icon(Icons.link, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _attachButton(String label, IconData icon, String what) {
    return OutlinedButton.icon(
      onPressed: _sending ? null : () => _attach(what),
      icon: Icon(icon, size: 17),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: IvoryColors.burgundy,
        side: BorderSide(color: IvoryColors.hairlineStrong),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _chip(String label, String value) => ChoiceChip(
        label: Text(label),
        selected: _audience == value,
        showCheckmark: false,
        labelStyle: const TextStyle(
          color: IvoryColors.burgundy,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        onSelected: (_) => setState(() => _audience = value),
      );
}

// =====================================================================
// WISH TRACKER
// =====================================================================
class _WishTrackerTab extends StatefulWidget {
  const _WishTrackerTab();

  @override
  State<_WishTrackerTab> createState() => _WishTrackerTabState();
}

class _WishTrackerTabState extends State<_WishTrackerTab> {
  List<Wish> _wishes = <Wish>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final List<Wish> w = await WishService.instance.fetchAllWishes();
      if (!mounted) return;
      setState(() {
        _wishes = w;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _edit(Wish w) async {
    final TextEditingController reply =
        TextEditingController(text: w.adminReply ?? '');
    final TextEditingController link =
        TextEditingController(text: w.deliveryUrl ?? '');
    String status = w.status;

    await showModalBottomSheet<void>(
      context: context,
      isScr
