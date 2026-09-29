import 'package:flutter/material.dart';

import '../services/admin_service.dart';
import '../services/notification_service.dart';
import '../theme/ivory_theme.dart';
import '../widgets/admin_bits.dart';

/// ADMIN STUDIO - BROADCAST
///
/// A message that lands in the Sanctuary Inbox, lights up the bell and
/// arrives on every member's phone within the minute. A photo, voice
/// note, video, file or link can travel with it.
class AdminBroadcastTab extends StatefulWidget {
  const AdminBroadcastTab({super.key});

  @override
  State<AdminBroadcastTab> createState() => _AdminBroadcastTabState();
}

class _AdminBroadcastTabState extends State<AdminBroadcastTab> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _title = TextEditingController();
  final TextEditingController _body = TextEditingController();
  final TextEditingController _linkCtrl = TextEditingController();

  String _audience = 'all';
  String _kind = 'system';
  int _tierLevel = 1;
  String? _personId;
  String _personName = '';

  PickedMedia? _file;
  String? _fileUrl;

  bool _sending = false;
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

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  // -------------------------------------------------------- attachments

  Future<void> _attach(String what) async {
    try {
      PickedMedia? m;
      if (what == 'image') {
        m = await AdminService.instance.pickImage();
      } else if (what == 'video') {
        m = await AdminService.instance.pickVideo();
      } else if (what == 'audio') {
        m = await AdminService.instance.pickFile(audioOnly: true);
      } else {
        m = await AdminService.instance.pickFile();
      }
      if (m == null) return;
      if (m.size > 48 * 1024 * 1024) {
        _snack('That file is ${m.sizeLabel}. Keep it under about 48 MB, '
            'or host it and paste the link instead.');
        return;
      }
      setState(() {
        _file = m;
        _fileUrl = null;
        _linkCtrl.clear();
        if (what == 'image') _kind = 'image';
        if (what == 'audio') _kind = 'audio';
        if (what == 'video') _kind = 'video';
      });
    } catch (e) {
      _snack('Could not open that file: $e');
    }
  }

  // --------------------------------------------------------------- send

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    if (_audience == 'user' && _personId == null) {
      _snack('Choose who this is for first.');
      return;
    }

    setState(() {
      _sending = true;
      _status = '';
    });
    try {
      String? url = _fileUrl;
      if (_file != null && url == null) {
        setState(() => _status = 'Uploading ${_file!.sizeLabel}...');
        url =
            await AdminService.instance.upload(_file!, folder: 'broadcast');
        _fileUrl = url;
      }
      url ??= _linkCtrl.text.trim().isEmpty ? null : _linkCtrl.text.trim();

      setState(() => _status = 'Sending...');
      await NotificationService.instance.send(
        title: _title.text.trim(),
        body: _body.text.trim(),
        audience: _audience,
        kind: _kind,
        tierLevel: _audience == 'tier' ? _tierLevel : 0,
        userId: _audience == 'user' ? _personId : null,
        actionTab: 'feed',
        actionUrl: url,
      );
      if (!mounted) return;
      _title.clear();
      _body.clear();
      _linkCtrl.clear();
      setState(() {
        _file = null;
        _fileUrl = null;
      });
      _snack('Sent. It is in their inbox and on their phone.');
    } catch (e) {
      _snack('Could not send: $e');
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
          _status = '';
        });
      }
    }
  }

  // ------------------------------------------------------- person picker

  Future<void> _pickPerson() async {
    final TextEditingController search = TextEditingController();
    List<Map<String, dynamic>> people =
        await NotificationService.instance.searchPeople('');
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: IvoryColors.surface,
      builder: (BuildContext sheet) => StatefulBuilder(
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
                        '${p['role'] == 'admin' ? ' \u00b7 admin' : ''}',
                        style: TextStyle(
                            color: IvoryColors.textFaint, fontSize: 12),
                      ),
                      onTap: () {
                        setState(() {
                          _personId = id;
                          _personName = (p['display_name'] as String?) ??
                              'that member';
                        });
                        Navigator.of(sheet).pop();
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

  // -------------------------------------------------------------- build

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
            'and arrives on their phone within the minute. Attach a '
            'picture, a voice note, a video or a link and it travels with '
            'the message.',
            style: TextStyle(
                fontSize: 13, height: 1.45, color: IvoryColors.textSoft),
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
          const AdminLabel('WHO SEES IT'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _audienceChip('Everyone', 'all', Icons.groups_outlined),
              _audienceChip('A tier and above', 'tier', Icons.lock_outline),
              _audienceChip('One member', 'user', Icons.person_outline),
            ],
          ),
          if (_audience == 'tier') _tierStepper(),
          if (_audience == 'user') ...<Widget>[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: AdminButton(
                label: _personId == null
                    ? 'CHOOSE A MEMBER'
                    : _personName.toUpperCase(),
                icon: Icons.person_search,
                onPressed: _pickPerson,
              ),
            ),
          ],
          const SizedBox(height: 18),
          const AdminLabel('ATTACH SOMETHING (OPTIONAL)'),
          const SizedBox(height: 10),
          _attachPanel(),
          const SizedBox(height: 18),
          const AdminLabel('STYLE'),
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

  Widget _audienceChip(String label, String value, IconData icon) =>
      AdminSelectChip(
        label: label,
        icon: icon,
        selected: _audience == value,
        onTap: () => setState(() => _audience = value),
      );

  Widget _tierStepper() => Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Row(
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
      );

  Widget _attachPanel() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: IvoryTheme.card(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (_file != null) ...<Widget>[
            AdminPickedFileCard(
              media: _file!,
              uploaded: _fileUrl != null,
              icon: Icons.attachment,
              onRemove: () => setState(() {
                _file = null;
                _fileUrl = null;
              }),
            ),
            const SizedBox(height: 10),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              AdminButton(
                label: 'Photo',
                icon: Icons.image_outlined,
                strong: false,
                onPressed: _sending ? null : () => _attach('image'),
              ),
              AdminButton(
                label: 'Voice note',
                icon: Icons.mic_none,
                strong: false,
                onPressed: _sending ? null : () => _attach('audio'),
              ),
              AdminButton(
                label: 'Video',
                icon: Icons.videocam_outlined,
                strong: false,
                onPressed: _sending ? null : () => _attach('video'),
              ),
              AdminButton(
                label: 'Any file',
                icon: Icons.attach_file,
                strong: false,
                onPressed: _sending ? null : () => _attach('file'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _linkCtrl,
            keyboardType: TextInputType.url,
            enabled: _file == null,
            decoration: InputDecoration(
              labelText: _file == null
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
}

// END OF FILE - lib/screens/admin_broadcast_tab.dart
