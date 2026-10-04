import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/media_ref.dart';
import '../services/admin_service.dart';
import '../theme/ivory_theme.dart';
import '../widgets/admin_bits.dart';
import '../widgets/admin_post_chips.dart';
import 'admin_library_list.dart';

/// ADMIN STUDIO - THE COMPOSER
///
/// Drop an audiobook, a voice note, a video, an image, a written story
/// or a poll into Ivory from the phone. Media is either uploaded into
/// Supabase Storage or pointed at any provider by link, because a post
/// only ever stores a source plus an opaque reference.
///
/// Publishing also fires the announcement and the device push, because
/// the database trigger does that for every new post.
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

  String _type = 'blog';
  int _tier = 0;

  /// Rupees to open this one post. Empty or 0 = not for sale.
  final TextEditingController _price = TextEditingController();

  /// A story born at the door wears this credit.
  final TextEditingController _doorCredit = TextEditingController();

  /// The tier that opens a priced post for free. Null = nobody.
  int? _freeFrom;
  bool _publishNow = true;

  PickedMedia? _picked;
  String? _uploadedUrl;
  PickedMedia? _thumb;
  String? _uploadedThumbUrl;

  bool _busy = false;
  String _busyLabel = '';
  int _libraryStamp = 0;

  List<Map<String, dynamic>> _tiers = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _loadTiers();
  }

  @override
  void dispose() {
    _price.dispose();
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

  Future<void> _loadTiers() async {
    try {
      final List<Map<String, dynamic>> t =
          await AdminService.instance.fetchAllTiers();
      if (!mounted) return;
      setState(() => _tiers = t
          .where((Map<String, dynamic> e) => e['is_active'] == true)
          .toList());
    } catch (_) {
      // The tier chips simply fall back to "Free for everyone".
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

  IconData get _typeIcon {
    switch (_type) {
      case 'audio':
        return Icons.headphones_outlined;
      case 'video':
        return Icons.play_circle_outline;
      case 'image':
        return Icons.image_outlined;
      case 'poll':
        return Icons.how_to_vote_outlined;
      default:
        return Icons.auto_stories_outlined;
    }
  }

  // ------------------------------------------------------------- picking

  Future<void> _pick({required bool thumbnail}) async {
    try {
      PickedMedia? m;
      if (thumbnail || _type == 'image') {
        m = await AdminService.instance.pickImage();
      } else if (_type == 'video') {
        m = await AdminService.instance.pickVideo();
      } else if (_type == 'audio') {
        m = await AdminService.instance.pickFile(audioOnly: true);
      } else {
        m = await AdminService.instance.pickFile();
      }
      if (m == null) return;
      if (m.size > 48 * 1024 * 1024) {
        _toast(
          'That file is ${m.sizeLabel}. Keep uploads under about 48 MB, or '
          'host it and paste the link instead.',
          bad: true,
        );
        return;
      }
      setState(() {
        if (thumbnail) {
          _thumb = m;
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

  // ---------------------------------------------------------- publishing

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;

    final bool needsMedia =
        _type == 'audio' || _type == 'video' || _type == 'image';
    final bool hasLink = _link.text.trim().isNotEmpty;
    if (needsMedia && _picked == null && !hasLink) {
      _toast('Attach a file or paste a link first.', bad: true);
      return;
    }

    final List<String> poll = _options
        .map((TextEditingController c) => c.text.trim())
        .where((String s) => s.isNotEmpty)
        .toList();
    if (_type == 'poll' && poll.length < 2) {
      _toast('A poll needs at least two options.', bad: true);
      return;
    }

    setState(() {
      _busy = true;
      _busyLabel = 'Working...';
    });

    try {
      String? mediaRef = _uploadedUrl;
      MediaSource mediaSource = MediaSource.none;

      if (_picked != null && mediaRef == null) {
        setState(() => _busyLabel = 'Uploading ${_picked!.sizeLabel}...');
        mediaRef = await AdminService.instance.upload(
          _picked!,
          folder: _type == 'image'
              ? 'images'
              : (_type == 'audio' ? 'audio' : 'video'),
          private: _type != 'image',
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
      if (_thumb != null && thumbRef == null) {
        setState(() => _busyLabel = 'Uploading the cover...');
        thumbRef =
            await AdminService.instance.upload(_thumb!, folder: 'thumbs');
        _uploadedThumbUrl = thumbRef;
      }
      if (thumbRef != null) thumbSource = MediaSource.supabase;

      setState(() => _busyLabel = 'Publishing...');
      final int? mins = int.tryParse(_minutes.text.trim());

      final int newId = await AdminService.instance.publishPost(
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
        pollOptions: _type == 'poll' ? poll : null,
        isPublished: _publishNow,
      );

      // The price is set straight after, so publish_post stays the
      // one function that creates a post.
      final String door = _doorCredit.text.trim();
      if (door.isNotEmpty) {
        await Supabase.instance.client
            .from('posts')
            .update(<String, dynamic>{'door_credit': door})
            .eq('id', newId);
      }

      final int price = int.tryParse(_price.text.trim()) ?? 0;
      if (price > 0) {
        await AdminService.instance.setPostPrice(
          postId: newId,
          priceInr: price,
          freeFromTier: _freeFrom,
        );
      }

      if (!mounted) return;
      _reset();
      _toast(_publishNow
          ? 'Published. Every member has been notified.'
          : 'Saved as a draft. Nobody has been notified.');
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
      _thumb = null;
      _uploadedThumbUrl = null;
      _tier = 0;
      _price.clear();
      _doorCredit.clear();
      _freeFrom = null;
      _publishNow = true;
      _libraryStamp++;
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
            'Anything published here appears in the feed at once, and every '
            'member gets the announcement and the phone notification.',
            style: TextStyle(
                fontSize: 13, height: 1.45, color: IvoryColors.textSoft),
          ),
          const SizedBox(height: 20),
          const AdminLabel('WHAT ARE YOU POSTING'),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: postTypeChips(
              selected: _type,
              onTap: (String v) => setState(() {
                _type = v;
                _picked = null;
                _uploadedUrl = null;
              }),
            )),
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
              minLines: 6,
              maxLines: 14,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'The story itself',
                alignLabelWithHint: true,
              ),
              validator: (String? v) =>
                  (_type == 'blog' && (v == null || v.trim().length < 20))
                      ? 'Write at least a paragraph'
                      : null,
            ),
          ],
          if (isPoll) ..._pollSection() else ..._mediaSection(),
          if (_type == 'audio' || _type == 'video') ...<Widget>[
            const SizedBox(height: 14),
            TextFormField(
              controller: _minutes,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Length in minutes (optional)'),
            ),
          ],
          const SizedBox(height: 22),
          const AdminLabel('WHO CAN OPEN IT'),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: postTierChips(
            selected: _tier,
            tiers: _tiers,
            onTap: (int v) => setState(() => _tier = v),
          )),
          const SizedBox(height: 22),
          const AdminLabel('OR SELL IT ON ITS OWN'),
          const SizedBox(height: 6),
          Text(
            'Give it a price and everyone sees a lock - free members and '
            'paying members alike - until they buy it or reach the tier '
            'you choose below. Leave it empty to use the tier rule above.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: IvoryColors.textFaint,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _price,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Price in rupees (optional)',
              hintText: 'e.g. 299',
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _doorCredit,
            maxLength: 40,
            decoration: const InputDecoration(
              counterText: '',
              labelText: 'Story door credit (optional)',
              hintText: 'Stamps "FROM THE STORY DOOR - story by ..."',
            ),
          ),
          if ((int.tryParse(_price.text.trim()) ?? 0) > 0) ...<Widget>[
            const SizedBox(height: 14),
            const AdminLabel('WHO GETS IT WITHOUT PAYING'),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: postFreeFromChips(
              selected: _freeFrom,
              tiers: _tiers,
              onTap: (int? v) => setState(() => _freeFrom = v),
            )),
          ],
          const SizedBox(height: 18),
          _publishSwitch(),
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
          AdminLibraryList(refreshStamp: _libraryStamp),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ fragments

  /// Which tiers skip the price. "Nobody" means every member pays,
  /// however much they already subscribe for.

  List<Widget> _pollSection() {
    final List<Widget> rows = <Widget>[
      const SizedBox(height: 20),
      const AdminLabel('THE OPTIONS'),
      const SizedBox(height: 10),
    ];
    for (int i = 0; i < _options.length; i++) {
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: <Widget>[
            Expanded(
              child: TextFormField(
                controller: _options[i],
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Option ${i + 1}',
                  isDense: true,
                ),
              ),
            ),
            if (_options.length > 2)
              IconButton(
                onPressed: () => setState(() => _options.removeAt(i)),
                icon: const Icon(Icons.remove_circle_outline,
                    color: IvoryColors.plum),
              ),
          ],
        ),
      ));
    }
    rows.add(Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () =>
            setState(() => _options.add(TextEditingController())),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('ADD ANOTHER OPTION'),
        style: TextButton.styleFrom(foregroundColor: IvoryColors.burgundy),
      ),
    ));
    return rows;
  }

  List<Widget> _mediaSection() {
    return <Widget>[
      const SizedBox(height: 20),
      const AdminLabel('THE MEDIA'),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: IvoryTheme.card(radius: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (_picked != null) ...<Widget>[
              AdminPickedFileCard(
                media: _picked!,
                uploaded: _uploadedUrl != null,
                icon: _typeIcon,
                onRemove: () => setState(() {
                  _picked = null;
                  _uploadedUrl = null;
                }),
              ),
              const SizedBox(height: 10),
            ],
            SizedBox(
              width: double.infinity,
              child: AdminButton(
                label: _picked == null ? 'UPLOAD A FILE' : 'REPLACE FILE',
                icon: Icons.upload_file,
                onPressed: _busy ? null : () => _pick(thumbnail: false),
              ),
            ),
            const SizedBox(height: 12),
            const AdminOrLine('or point at a link'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _link,
              keyboardType: TextInputType.url,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'YouTube / Telegram / R2 / direct link',
                isDense: true,
              ),
            ),
            if (_link.text.trim().isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                'Detected: '
                '${MediaRef.parse(_link.text.trim()).source.label}',
                style: TextStyle(fontSize: 11.5, color: IvoryColors.success),
              ),
            ],
            const SizedBox(height: 12),
            Divider(color: IvoryColors.hairline),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    _thumb == null
                        ? 'Cover image (optional)'
                        : '${_thumb!.name} \u00b7 ${_thumb!.sizeLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(fontSize: 12.8, color: IvoryColors.textSoft),
                  ),
                ),
                TextButton(
                  onPressed: _busy ? null : () => _pick(thumbnail: true),
                  style: TextButton.styleFrom(
                      foregroundColor: IvoryColors.burgundy),
                  child: Text(_thumb == null ? 'ADD' : 'CHANGE'),
                ),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  Widget _publishSwitch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
              : 'Saved as a draft. Publish it later from the library.',
          style: TextStyle(fontSize: 12, color: IvoryColors.textFaint),
        ),
      ),
    );
  }
}

// END OF FILE - lib/screens/admin_create_tab.dart
