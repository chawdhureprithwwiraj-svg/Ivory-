import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/media_ref.dart';
import '../services/admin_service.dart';
import '../theme/ivory_theme.dart';

/// ============================================================
/// ADMIN STUDIO - THE COMPOSER
///
/// Drop an audiobook, a voice note, a video, an image, a written story
/// or a poll into Ivory from the phone. Media can either be uploaded
/// straight into Supabase Storage or pointed at any provider by link -
/// YouTube, Telegram, Cloudflare R2, a plain https file - because the
/// post only ever stores a source plus an opaque reference.
///
/// Publishing writes the post AND fires the announcement and the device
/// push, because the database trigger does that for every new post.
/// ============================================================
class AdminCreateTab extends StatefulWidget {
  const AdminCreateTab({super.key});

  @override
  State<AdminCreateTab> createState() => _AdminCreateTabState();
}

class _AdminCreateTabState extends State<AdminCreateTab> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _title = TextEditingController();
  final TextEditingController _summary = TextEditingController();
  final TextEditingController _body = TextEditingController();
  final TextEditingController _link = TextEditingController();
  final TextEditingController _minutes = TextEditingController();
  final List<TextEditingController> _options = <TextEditingController>[
    TextEditingController(),
    TextEditingController(),
  ];

  /// blog | audio | video | image | poll
  String _type = 'blog';
  int _tier = 0;
  bool _publishNow = true;

  PickedMedia? _picked;
  String? _uploadedUrl;
  PickedMedia? _pickedThumb;
  String? _uploadedThumbUrl;

  bool _busy = false;
  String _busyLabel = '';

  List<Map<String, dynamic>> _tiers = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _library = <Map<String, dynamic>>[];
  bool _loadingLibrary = true;

  static const List<_TypeSpec> _types = <_TypeSpec>[
    _TypeSpec('blog', 'Story', Icons.auto_stories_outlined),
    _TypeSpec('audio', 'Audio', Icons.headphones_outlined),
    _TypeSpec('video', 'Video', Icons.play_circle_outline),
    _TypeSpec('image', 'Image', Icons.image_outlined),
    _TypeSpec('poll', 'Poll', Icons.how_to_vote_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _loadSideData();
  }

  @override
  void dispose() {
    _title.dispose();
    _summary.dispose();
    _body.dispose();
    _link.dispose();
    _minutes.dispose();
    for (final TextEditingController c in _options) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSideData() async {
    try {
      final List<Map<String, dynamic>> t =
          await AdminService.instance.fetchAllTiers();
      final List<Map<String, dynamic>> lib =
          await AdminService.instance.fetchLibrary();
      if (!mounted) return;
      setState(() {
        _tiers = t.where((Map<String, dynamic> e) => e['is_active'] == true)
            .toList();
        _library = lib;
        _loadingLibrary = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingLibrary = false);
    }
  }

  void _toast(String message, {bool bad = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: bad ? IvoryColors.danger : IvoryColors.plum,
      ),
    );
  }

  // ------------------------------------------------------------- picking

  Future<void> _pickForType({required bool thumbnail}) async {
    try {
      PickedMedia? m;
      if (thumbnail || _type == 'image') {
        m = await _chooseImageSource();
      } else if (_type == 'video') {
        m = await AdminService.instance.pickVideo();
      } else if (_type == 'audio') {
        m = await AdminService.instance.pickFile(type: FileType.audio);
      } else {
        m = await AdminService.instance.pickFile();
      }
      if (m == null) return;

      if (m.size > 48 * 1024 * 1024) {
        _toast(
          'That file is ${m.sizeLabel}. Keep uploads under about 48 MB - '
          'for anything larger, host it and paste the link instead.',
          bad: true,
        );
        return;
      }

      setState(() {
        if (thumbnail) {
          _pickedThumb = m;
          _uploadedThumbUrl = null;
        } else {
          _picked = m;
          _uploadedUrl = null;
          _link.clear();
        }
      });
    } catch (e) {
      _toast('Could not open that file: $e', bad: true);
    }
  }

  Future<PickedMedia?> _chooseImageSource() async {
    final bool? camera = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: IvoryColors.surface,
      builder: (BuildContext c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: IvoryColors.plum),
              title: const Text('Choose from gallery',
                  style: TextStyle(color: IvoryColors.burgundy)),
              onTap: () => Navigator.of(c).pop(false),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined,
                  color: IvoryColors.plum),
              title: const Text('Take a photo',
                  style: TextStyle(color: IvoryColors.burgundy)),
              onTap: () => Navigator.of(c).pop(true),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (camera == null) return null;
    return AdminService.instance.pickImage(fromCamera: camera);
  }

  // ----------------------------------------------------------- publishing

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;

    final bool needsMedia = _type == 'audio' || _type == 'video' ||
        _type == 'image';
    final bool hasLink = _link.text.trim().isNotEmpty;
    if (needsMedia && _picked == null && !hasLink) {
      _toast('Attach a file or paste a link first.', bad: true);
      return;
    }

    final List<String> pollOptions = _options
        .map((TextEditingController c) => c.text.trim())
        .where((String s) => s.isNotEmpty)
        .toList();
    if (_type == 'poll' && pollOptions.length < 2) {
      _toast('A poll needs at least two options.', bad: true);
      return;
    }

    setState(() {
      _busy = true;
      _busyLabel = 'Working...';
    });

    try {
      // 1. upload whatever is waiting
      String? mediaRef = _uploadedUrl;
      MediaSource mediaSource = MediaSource.none;

      if (_picked != null && mediaRef == null) {
        setState(() => _busyLabel = 'Uploading ${_picked!.sizeLabel}...');
        mediaRef = await AdminService.instance.upload(
          _picked!,
          folder: _type == 'image'
              ? 'images'
              : (_type == 'audio' ? 'audio' : 'video'),
        );
        _uploadedUrl = mediaRef;
      }
      if (mediaRef != null) {
        mediaSource = MediaSource.supabase;
      } else if (hasLink) {
        final MediaRef parsed = MediaRef.parse(_link.text.trim());
        mediaSource = parsed.source;
        mediaRef = parsed.ref;
      }

      String? thumbRef = _uploadedThumbUrl;
      MediaSource thumbSource = MediaSource.none;
      if (_pickedThumb != null && thumbRef == null) {
        setState(() => _busyLabel = 'Uploading the cover...');
        thumbRef = await AdminService.instance
            .upload(_pickedThumb!, folder: 'thumbs');
        _uploadedThumbUrl = thumbRef;
      }
      if (thumbRef != null) thumbSource = MediaSource.supabase;

      // 2. publish
      setState(() => _busyLabel = 'Publishing...');
      final int? mins = int.tryParse(_minutes.text.trim());

      await AdminService.instance.publishPost(
        type: _type,
        title: _title.text.trim(),
        summary: _summary.text,
        body: _body.text,
        mediaSource: mediaSource,
        mediaRef: mediaRef,
        thumbSource: thumbSource,
        thumbRef: thumbRef,
        tierRequired: _tier,
        durationSecs: mins == null ? null : mins * 60,
        pollOptions: _type == 'poll' ? pollOptions : null,
        isPublished: _publishNow,
      );

      if (!mounted) return;
      _reset();
      _toast(_publishNow
          ? 'Published. Every member has been notified.'
          : 'Saved as a draft. Nobody has been notified.');
      await _loadSideData();
    } catch (e) {
      _toast('Could not publish: $e', bad: true);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _busyLabel = '';
        });
      }
    }
  }

  void _reset() {
    _title.clear();
    _summary.clear();
    _body.clear();
    _link.clear();
    _minutes.clear();
    for (final TextEditingController c in _options) {
      c.clear();
    }
    setState(() {
      _picked = null;
      _uploadedUrl = null;
      _pickedThumb = null;
      _uploadedThumbUrl = null;
      _tier = 0;
      _publishNow = true;
    });
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final bool isPoll = _type == 'poll';
    final bool isStory = _type == 'blog';

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 40),
        children: <Widget>[
          Text('Publish to Ivory',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(
            'Anything you publish here appears in the feed at once, and '
            'every member receives the announcement and the device push '
            'automatically.',
            style: TextStyle(
                fontSize: 13, height: 1.45, color: IvoryColors.textSoft),
          ),
          const SizedBox(height: 20),

          _label('WHAT ARE YOU POSTING'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _types.map(_typeChip).toList(),
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
            controller: _summary,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: isPoll ? 'The question, in one line' : 'Short teaser',
              alignLabelWithHint: true,
            ),
          ),
          if (isStory) ...<Widget>[
            const SizedBox(height: 14),
            TextFormField(
              controller: _body,
              maxLines: 12,
              minLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'The story itself',
                alignLabelWithHint: true,
              ),
              validator: (String? v) => (_type == 'blog' &&
                      (v == null || v.trim().length < 20))
                  ? 'Write at least a paragraph'
                  : null,
            ),
          ],

          if (isPoll) ...<Widget>[
            const SizedBox(height: 20),
            _label('THE OPTIONS'),
            const SizedBox(height: 10),
            ..._options.asMap().entries.map(_optionRow),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(
                    () => _options.add(TextEditingController())),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('ADD ANOTHER OPTION'),
                style: TextButton.styleFrom(
                    foregroundColor: IvoryColors.burgundy),
              ),
            ),
          ] else ...<Widget>[
            const SizedBox(height: 20),
            _label('THE MEDIA'),
            const SizedBox(height: 10),
            _mediaPanel(),
          ],

          if (_type == 'audio' || _type == 'video') ...<Widget>[
            const SizedBox(height: 14),
            TextFormField(
              controller: _minutes,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Length in minutes (optional)',
              ),
            ),
          ],

          const SizedBox(height: 22),
          _label('WHO CAN OPEN IT'),
          const SizedBox(height: 10),
          _tierPicker(),

          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: IvoryTheme.card(radius: 18),
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              activeColor: IvoryColors.gold,
              value: _publishNow,
              onChanged: (bool v) => setState(() => _publishNow = v),
              title: const Text(
                'Publish immediately',
                style: TextStyle(
                  color: IvoryColors.burgundy,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                _publishNow
                    ? 'Goes live and notifies every member.'
                    : 'Saved quietly as a draft. You can publish it from '
                        'the library below.',
                style: TextStyle(fontSize: 12, color: IvoryColors.textFaint),
              ),
            ),
          ),

          const SizedBox(height: 22),
          IvoryGradientButton(
            label: _busy
                ? _busyLabel.toUpperCase()
                : (_publishNow ? 'PUBLISH NOW' : 'SAVE AS DRAFT'),
            icon: Icons.auto_awesome,
            busy: _busy,
            onPressed: _busy ? null : _publish,
          ),

          const SizedBox(height: 34),
          const IvoryEyebrow('The library', icon: Icons.inventory_2_outlined),
          const SizedBox(height: 12),
          if (_loadingLibrary)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: IvoryColors.amber),
              ),
            )
          else if (_library.isEmpty)
            Text('Nothing published yet.',
                style: TextStyle(color: IvoryColors.textFaint))
          else
            ..._library.map(_libraryRow),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ fragments

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          color: IvoryColors.plum,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
        ),
      );

  Widget _typeChip(_TypeSpec spec) {
    final bool on = _type == spec.value;
    return GestureDetector(
      onTap: () => setState(() {
        _type = spec.value;
        _picked = null;
        _uploadedUrl = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: on
              ? IvoryColors.goldGradient
              : const LinearGradient(
                  colors: <Color>[Color(0xFFFFFCF2), Color(0xFFFDF4E2)],
                ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: on ? IvoryColors.gold : IvoryColors.hairline,
            width: on ? 1.4 : 1,
          ),
          boxShadow: on ? IvoryTheme.softShadow(blur: 10, y: 4) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(spec.icon, size: 17, color: IvoryColors.burgundy),
            const SizedBox(width: 7),
            Text(
              spec.label,
              style: TextStyle(
                color: IvoryColors.burgundy,
                fontSize: 13,
                fontWeight: on ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionRow(MapEntry<int, TextEditingController> e) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextFormField(
              controller: e.value,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Option ${e.key + 1}',
                isDense: true,
              ),
            ),
          ),
          if (_options.length > 2)
            IconButton(
              onPressed: () => setState(() => _options.removeAt(e.key)),
              icon: const Icon(Icons.remove_circle_outline,
                  color: IvoryColors.plum),
            ),
        ],
      ),
    );
  }

  Widget _mediaPanel() {
    final PickedMedia? m = _picked;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: IvoryTheme.card(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (m != null) ...<Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: IvoryColors.goldGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _type == 'audio'
                        ? Icons.graphic_eq
                        : (_type == 'video'
                            ? Icons.movie_outlined
                            : Icons.image_outlined),
                    color: IvoryColors.burgundy,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        m.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: IvoryColors.burgundy,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                      Text(
                        _uploadedUrl == null
                            ? '${m.sizeLabel} · ready to upload'
                            : '${m.sizeLabel} · uploaded',
                        style: TextStyle(
                            fontSize: 11.5, color: IvoryColors.textFaint),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() {
                    _picked = null;
                    _uploadedUrl = null;
                  }),
                  icon: const Icon(Icons.close, color: IvoryColors.plum),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: <Widget>[
              Expanded(
                child: 
