import 'package:flutter/material.dart';

import '../core/ivory_errors.dart';
import '../models/folio_entry.dart';
import '../models/live_models.dart';
import '../services/private_folio_service.dart';
import '../theme/ivory_theme.dart';
import 'call_sheet_bits.dart';

class PrivateFolioEntryEditor extends StatefulWidget {
  const PrivateFolioEntryEditor({
    super.key,
    this.entry,
    this.calls = const <CallRequest>[],
  });

  final FolioEntry? entry;
  final List<CallRequest> calls;

  @override
  State<PrivateFolioEntryEditor> createState() =>
      _PrivateFolioEntryEditorState();
}

class _PrivateFolioEntryEditorState extends State<PrivateFolioEntryEditor> {
  static const List<String> _availableTags = <String>[
    'Remember', 'Write later', 'Read later', 'Next call', 'Inspiration',
  ];
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _body;
  late final TextEditingController _url;
  late FolioKind _kind;
  int? _callId;
  List<String> _tags = <String>[];
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final FolioEntry? entry = widget.entry;
    _kind = entry?.kind ?? FolioKind.note;
    _title = TextEditingController(text: entry?.title ?? '');
    _body = TextEditingController(text: entry?.body ?? '');
    _url = TextEditingController(text: entry?.url ?? '');
    _callId = entry?.relatedCallId;
    _tags = List<String>.of(entry?.tags ?? const <String>[]);
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _url.dispose();
    super.dispose();
  }

  String? _validateUrl(String? raw) {
    if (_kind != FolioKind.link) return null;
    final Uri? uri = Uri.tryParse((raw ?? '').trim());
    if (uri == null ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty) {
      return 'Use a complete http or https link.';
    }
    return null;
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_form.currentState!.validate()) return;
    if (_kind != FolioKind.link &&
        _title.text.trim().isEmpty &&
        _body.text.trim().isEmpty) {
      setState(() => _error = 'Add a title or a few words before saving.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await PrivateFolioService.instance.save(
        id: widget.entry?.id,
        kind: _kind,
        title: _title.text,
        body: _body.text,
        url: _kind == FolioKind.link ? _url.text : null,
        relatedCallId: _kind == FolioKind.callNote ? _callId : null,
        tags: _tags,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e is PrivateFolioLimitException
              ? e.message
              : houseMessage(e);
        });
      }
    }
  }

  List<CallRequest> get _datedCalls => widget.calls
      .where((CallRequest call) => call.requestedFor != null)
      .toList()
    ..sort((CallRequest a, CallRequest b) =>
        a.requestedFor!.compareTo(b.requestedFor!));

  @override
  Widget build(BuildContext context) {
    final double bottom = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 14, 20, bottom + 20),
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: IvoryColors.hairlineStrong,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.entry == null ? 'KEEP SOMETHING' : 'EDIT THIS PAGE',
                  style: const TextStyle(
                    color: IvoryColors.burgundy,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Up to 100 pages. Your notes and links share a 1 MiB total allowance.',
                  style: TextStyle(
                    color: IvoryColors.textSoft,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<FolioKind>(
                  value: _kind,
                  decoration: const InputDecoration(labelText: 'Keep as'),
                  items: FolioKind.values
                      .map((FolioKind kind) => DropdownMenuItem<FolioKind>(
                            value: kind,
                            child: Text(kind.label),
                          ))
                      .toList(),
                  onChanged: _saving
                      ? null
                      : (FolioKind? value) {
                          if (value != null) setState(() => _kind = value);
                        },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _title,
                  maxLength: 140,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'A name you will recognize later',
                  ),
                ),
                if (_kind == FolioKind.link) ...<Widget>[
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _url,
                    maxLength: 2048,
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Link',
                      hintText: 'https://…',
                    ),
                    validator: _validateUrl,
                  ),
                ],
                if (_kind == FolioKind.callNote) ...<Widget>[
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    value: _datedCalls.any((CallRequest c) => c.id == _callId)
                        ? _callId
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Link to one of your calls (optional)',
                    ),
                    hint: const Text('No call linked'),
                    items: <DropdownMenuItem<int>>[
                      for (final CallRequest c in _datedCalls)
                        DropdownMenuItem<int>(
                          value: c.id,
                          child: Text(
                            '${c.isVideo ? 'Video' : 'Voice'} · '
                            '${ivoryWhen(c.requestedFor!)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (_callId != null &&
                          !_datedCalls.any((CallRequest c) => c.id == _callId))
                        DropdownMenuItem<int>(
                          value: _callId,
                          child: const Text('Earlier session'),
                        ),
                    ],
                    onChanged: _saving
                        ? null
                        : (int? value) => setState(() => _callId = value),
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 10),
                TextFormField(
                  controller: _body,
                  maxLength: 8000,
                  minLines: 3,
                  maxLines: 7,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: _kind == FolioKind.draft
                        ? 'Your draft'
                        : (_kind == FolioKind.callNote
                            ? 'A private thought for this call'
                            : 'Your words'),
                    hintText: 'Nothing here is sent or shared for you.',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  'SHELF LABELS · OPTIONAL',
                  style: TextStyle(
                    color: IvoryColors.textFaint,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  children: _availableTags.map((String tag) {
                    final bool selected = _tags.contains(tag);
                    return FilterChip(
                      label: Text(tag),
                      selected: selected,
                      onSelected: _saving
                          ? null
                          : (bool value) {
                              setState(() {
                                if (value && _tags.length < 5) {
                                  _tags.add(tag);
                                } else {
                                  _tags.remove(tag);
                                }
                              });
                            },
                      selectedColor: IvoryColors.gold,
                      labelStyle: TextStyle(
                        color: selected
                            ? IvoryColors.burgundy
                            : IvoryColors.plum,
                        fontSize: 11,
                      ),
                      side: BorderSide(color: IvoryColors.hairline),
                    );
                  }).toList(),
                ),
                if (_error != null) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: IvoryColors.danger,
                      fontSize: 12.5,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.bookmark_add_outlined),
                  label: Text(_saving ? 'SAVING…' : 'KEEP IN MY FOLIO'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// END OF FILE - lib/widgets/private_folio_entry_editor.dart
