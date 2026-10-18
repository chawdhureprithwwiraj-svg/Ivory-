import 'package:flutter/material.dart';

import '../core/ivory_errors.dart';
import '../services/admin_service.dart';
import '../services/early_service.dart';
import '../services/line_house_service.dart';
import '../theme/ivory_theme.dart';

/// ============================================================
/// ADMIN STUDIO - ONE LETTER
///
/// Opening a letter marks it read (the member sees that). Here Ivory
/// writes back, optionally with a voice note, approves or declines a
/// held letter, mutes a member, and, if the member allowed it and a
/// written reply exists, shares the pair as the Letter of the Day.
/// Pops with true when anything changed, so the queue reloads.
/// ============================================================
class AdminLineLetterScreen extends StatefulWidget {
  const AdminLineLetterScreen({
    super.key,
    required this.id,
    this.preset,
    this.presetTemplates,
  });

  final int id;

  /// A letter to show without asking the database (previews and tests).
  final Map<String, dynamic>? preset;
  final List<Map<String, dynamic>>? presetTemplates;

  @override
  State<AdminLineLetterScreen> createState() => _AdminLineLetterScreenState();
}

class _AdminLineLetterScreenState extends State<AdminLineLetterScreen> {
  final LineHouseService _svc = LineHouseService.instance;
  final TextEditingController _reply = TextEditingController();
  Map<String, dynamic> _l = <String, dynamic>{};
  List<Map<String, dynamic>> _templates = <Map<String, dynamic>>[];
  PickedMedia? _voice;
  bool _loading = true;
  bool _busy = false;
  bool _changed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.preset != null) {
      _l = widget.preset!;
      _templates = widget.presetTemplates ?? <Map<String, dynamic>>[];
      _loading = false;
      return;
    }
    _load();
  }

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final Map<String, dynamic> l = await _svc.open(widget.id);
      List<Map<String, dynamic>> t = _templates;
      try {
        t = await _svc.templates();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _l = l;
        _templates = t;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = adminDetail(e);
        _loading = false;
      });
    }
  }

  void _say(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  String get _status => '${_l['status'] ?? ''}';

  Future<void> _run(Future<String> Function() job, {bool leave = false}) async {
    setState(() => _busy = true);
    try {
      final String m = await job();
      _changed = true;
      _say(m);
      if (leave && mounted) {
        Navigator.pop(context, true);
        return;
      }
      await _load();
    } catch (e) {
      _say(adminDetail(e));
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _pickVoice() async {
    try {
      final PickedMedia? m = await AdminService.instance.pickFile(audioOnly: true);
      if (m != null && mounted) setState(() => _voice = m);
    } catch (e) {
      _say(adminDetail(e));
    }
  }

  Future<void> _send() => _run(() async {
    String? path;
    final PickedMedia? v = _voice;
    if (v != null) path = await _svc.uploadVoice(widget.id, v);
    final String m = await _svc.reply(
      widget.id,
      _reply.text.trim(),
      audioPath: path,
    );
    return m;
  }, leave: true);

  Widget _card(Widget child, {Color? tint}) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: tint == null
        ? IvoryTheme.card()
        : IvoryTheme.card().copyWith(color: tint, gradient: null),
    child: child,
  );

  Widget _label(String t) => Text(
    t,
    style: const TextStyle(
      color: IvoryColors.plum,
      fontSize: 10.5,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.8,
    ),
  );

  Widget _who() {
    final String tier = '${_l['tier_name'] ?? 'tier'}';
    final int before = (_l['letters_before'] as num?)?.toInt() ?? 0;
    final bool muted = _l['muted'] == true;
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '${_l['name'] ?? 'Member'}',
            style: const TextStyle(
              color: IvoryColors.burgundy,
              fontFamily: IvoryTheme.displayFont,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$tier  \u00B7  Ladder rung ${_l['rung'] ?? 0}  \u00B7  '
            '$before ${before == 1 ? 'letter' : 'letters'} answered before',
            style: const TextStyle(color: IvoryColors.plum),
          ),
          const SizedBox(height: 4),
          Text(
            'Written ${earlyClock(DateTime.tryParse('${_l['created_at']}')?.toLocal() ?? DateTime.now())}',
            style: const TextStyle(color: IvoryColors.plum, fontSize: 12),
          ),
          if (muted)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'This member is muted.',
                style: TextStyle(
                  color: IvoryColors.danger,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              onPressed: _busy
                  ? null
                  : () => _run(
                      () => _svc.mute('${_l['user_id']}', !muted,
                          reason: muted ? null : 'Muted from the letter'),
                    ),
              child: Text(muted ? 'UNMUTE' : 'MUTE THIS MEMBER'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _held() => _card(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _label('HELD FOR A LOOK'),
        const SizedBox(height: 6),
        Text(
          'Held because of: ${_l['hold_reason'] ?? 'a safety rule'}. Send it on '
          'to your queue, or decline it (the member is told kindly, and it '
          'does not use up their letters).',
          style: const TextStyle(color: IvoryColors.plum),
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: IvoryColors.burgundy,
                ),
                onPressed: _busy
                    ? null
                    : () => _run(() => _svc.decide(widget.id, true), leave: true),
                child: const Text('SEND IT ON'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: _busy
                    ? null
                    : () => _run(() => _svc.decide(widget.id, false), leave: true),
                child: const Text('DECLINE'),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _writer() => _card(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _label('YOUR REPLY'),
        if (_templates.isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _templates
                .map(
                  (Map<String, dynamic> t) => ActionChip(
                    label: Text('${t['title']}'),
                    onPressed: () => setState(() {
                      final String cur = _reply.text.trim();
                      _reply.text =
                          cur.isEmpty ? '${t['body']}' : '$cur\n\n${t['body']}';
                    }),
                  ),
                )
                .toList(),
          ),
        ],
        const SizedBox(height: 8),
        TextField(
          controller: _reply,
          minLines: 5,
          maxLines: 12,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Write back. The member is told only that you replied; '
                'the words stay inside the Private Line.',
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            OutlinedButton.icon(
              onPressed: _busy ? null : _pickVoice,
              icon: const Icon(Icons.mic_none),
              label: Text(_voice == null ? 'ADD A VOICE NOTE' : 'CHANGE VOICE'),
            ),
            if (_voice != null) ...<Widget>[
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_voice!.name} (${_voice!.sizeLabel})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: IvoryColors.plum, fontSize: 12),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _voice = null),
                icon: const Icon(Icons.close, color: IvoryColors.plum),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: IvoryColors.burgundy,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _busy ? null : _send,
            child: Text(_busy ? 'SENDING...' : 'SEND REPLY'),
          ),
        ),
      ],
    ),
  );

  Widget _answered() {
    final String text = '${_l['reply_text'] ?? ''}'.trim();
    final bool share = _l['allow_share'] == true;
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _label('YOU ANSWERED'),
          const SizedBox(height: 6),
          Text(
            text.isEmpty
                ? (_l['reply_kind'] == 'voice' ? 'A voice note.' : '')
                : text,
            style: const TextStyle(color: IvoryColors.burgundy, height: 1.45),
          ),
          const SizedBox(height: 12),
          if (share && text.isNotEmpty) ...<Widget>[
            const Text(
              'This member allowed Ivory to share this as the Letter of the '
              'Day. Read the letter once more for any name or private detail '
              'before you share it.',
              style: TextStyle(color: IvoryColors.plum, fontSize: 12.5),
            ),
            const SizedBox(height: 8),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: IvoryColors.burgundy,
              ),
              onPressed: _busy ? null : () => _run(() => _svc.shareDaily(widget.id)),
              child: const Text('SHARE AS LETTER OF THE DAY'),
            ),
          ] else
            Text(
              share
                  ? 'Shared letters need a written reply; a voice note alone '
                      'cannot be shared.'
                  : 'The member did not allow this letter to be shared.',
              style: const TextStyle(color: IvoryColors.plum, fontSize: 12.5),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool did, Object? r) {
        if (!did) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        backgroundColor: IvoryColors.ivory,
        appBar: AppBar(title: const Text('LETTER')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: IvoryColors.burgundy),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                    children: <Widget>[
                      _who(),
                      _card(
                        Text(
                          '${_l['body'] ?? ''}',
                          style: const TextStyle(
                            color: IvoryColors.burgundy,
                            fontFamily: IvoryTheme.displayFont,
                            fontSize: 16.5,
                            height: 1.5,
                          ),
                        ),
                      ),
                      if (_status == 'held') _held(),
                      if (_status == 'read' || _status == 'waiting') _writer(),
                      if (_status == 'answered') _answered(),
                      if (_status == 'returned' || _status == 'declined')
                        _card(
                          const Text(
                            'This letter was returned or declined; nothing '
                            'more to do.',
                            style: TextStyle(color: IvoryColors.plum),
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }
}

// END OF FILE - lib/screens/admin_line_letter.dart
