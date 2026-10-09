import 'package:flutter/material.dart';

import '../core/ivory_errors.dart';
import '../models/media_ref.dart';
import '../services/admin_service.dart';
import '../services/vault_service.dart';
import '../theme/ivory_theme.dart';
import '../widgets/admin_bits.dart';
import '../widgets/admin_edit_bits.dart';
import '../widgets/admin_post_chips.dart';
import 'admin_attach_panel.dart';
import 'admin_publish_media.dart';
import 'vault_manager.dart';

/// ADMIN STUDIO - CHANGING A POST THAT IS ALREADY OUT.
///
/// One form, not two. This screen deliberately reuses the composer's
/// own pieces - AdminAttachPanel, the chip rows, resolvePublishMedia -
/// so a change to how a post is attached or priced lands in both
/// places at once. A parallel editor would drift within a month.
///
/// THE FIVE RULES, all enforced here or in update_post:
///  1. An edit never notifies. update_post never inserts, and the
///     published trigger only fires on a real draft -> live flip.
///  2. Same post id always. Views, votes, purchases and the Firstlist
///     place all survive.
///  3. The replaced file is never deleted - house rule. The screen
///     says so out loud and offers the Vault.
///  4. The post type cannot change; it would break detail routing.
///  5. Poll options are not editable here. They need a vote check
///     against poll_votes first - a later block.
class AdminEditPost extends StatefulWidget {
  const AdminEditPost({super.key, required this.postId});

  final int postId;

  /// Returns true when something was actually saved, so the caller
  /// can reload its list.
  static Future<bool> open(BuildContext context, int postId) async {
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AdminEditPost(postId: postId),
      ),
    );
    return saved ?? false;
  }

  @override
  State<AdminEditPost> createState() => _AdminEditPostState();
}

class _AdminEditPostState extends State<AdminEditPost> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _summary = TextEditingController();
  final TextEditingController _body = TextEditingController();
  final TextEditingController _minutes = TextEditingController();
  final TextEditingController _price = TextEditingController();
  final TextEditingController _doorCredit = TextEditingController();

  final GlobalKey<AdminAttachPanelState> _attach =
      GlobalKey<AdminAttachPanelState>();

  String _type = 'blog';
  Set<int> _who = <int>{};
  int? _freeFrom;
  bool _live = true;

  /// What the post is pointing at right now. Kept so that leaving the
  /// attach panel untouched means KEEPING the existing file, rather
  /// than silently clearing it.
  String _mediaSource = 'none';
  String? _mediaRef;
  String _thumbSource = 'none';
  String? _thumbRef;

  List<Map<String, dynamic>> _tiers = <Map<String, dynamic>>[];

  bool _loading = true;
  String? _loadError;
  bool _busy = false;
  String _busyLabel = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    _summary.dispose();
    _body.dispose();
    _minutes.dispose();
    _price.dispose();
    _doorCredit.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------------
  // Loading
  // ------------------------------------------------------------------
  /// A failed load must be LOUD. update_post writes every field it is
  /// given, so a half-filled form would quietly erase the fields it
  /// never managed to read. The form is not shown at all unless the
  /// post arrived whole.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final List<Map<String, dynamic>> tiers =
          await AdminService.instance.fetchAllTiers();
      final Map<String, dynamic> p =
          await AdminService.instance.fetchPostForEdit(widget.postId);

      _type = (p['type'] as String?) ?? 'blog';
      _title.text = (p['title'] as String?) ?? '';
      _summary.text = (p['summary'] as String?) ?? '';
      _body.text = (p['body'] as String?) ?? '';
      _doorCredit.text = (p['door_credit'] as String?) ?? '';

      final int? secs = p['duration_secs'] as int?;
      _minutes.text = secs == null ? '' : (secs ~/ 60).toString();

      final int price = (p['price_inr'] as int?) ?? 0;
      _price.text = price > 0 ? price.toString() : '';
      _freeFrom = p['free_from_tier'] as int?;

      _live = (p['is_published'] as bool?) ?? true;

      _mediaSource = (p['media_source'] as String?) ?? 'none';
      _mediaRef = p['media_ref'] as String?;
      _thumbSource = (p['thumb_source'] as String?) ?? 'none';
      _thumbRef = p['thumb_ref'] as String?;

      final List<dynamic>? allowed = p['allowed_tiers'] as List<dynamic>?;
      _who = allowed == null
          ? <int>{}
          : allowed.map((dynamic e) => e as int).toSet();

      if (!mounted) return;
      setState(() {
        _tiers = tiers;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = adminDetail(e);
      });
    }
  }

  void _toast(String message, {bool bad = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: bad ? IvoryColors.danger : IvoryColors.plum,
          duration: Duration(seconds: bad ? 12 : 4),
        ),
      );
  }

  // ------------------------------------------------------------------
  // Saving
  // ------------------------------------------------------------------
  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      _toast('A title is required.', bad: true);
      return;
    }

    final AdminAttachPanelState? at = _attach.currentState;
    final bool hasLink = at?.hasLink ?? false;

    setState(() {
      _busy = true;
      _busyLabel = 'Working...';
    });

    try {
      // Only uploads something if she actually attached something.
      // With an untouched panel this comes back empty, and the post
      // keeps the file it already had.
      final ResolvedMedia fresh = await resolvePublishMedia(
        type: _type,
        at: at,
        hasLink: hasLink,
        onStatus: (String label) {
          if (mounted) setState(() => _busyLabel = label);
        },
      );

      final bool replacedMedia = fresh.ref != null;
      final bool replacedCover = fresh.thumbRef != null;

      setState(() => _busyLabel = 'Saving...');
      final int? mins = int.tryParse(_minutes.text.trim());

      await AdminService.instance.updatePost(
        postId: widget.postId,
        title: _title.text.trim(),
        summary: _summary.text,
        body: _body.text,
        mediaSource: replacedMedia
            ? fresh.source
            : MediaSource.fromDb(_mediaSource),
        mediaRef: replacedMedia ? fresh.ref : _mediaRef,
        thumbSource: replacedCover
            ? fresh.thumbSource
            : MediaSource.fromDb(_thumbSource),
        thumbRef: replacedCover ? fresh.thumbRef : _thumbRef,
        tierRequired:
            _who.isEmpty ? 9 : _who.reduce((int a, int b) => a < b ? a : b),
        durationSecs: mins == null ? null : mins * 60,
        allowedTiers: (List<int>.from(_who)..sort()).toList(),
        doorCredit: _doorCredit.text.trim(),
        isPublished: _live,
      );

      // Money stays behind its own call, exactly as the composer does
      // it, so there is still only one place that sets a price.
      await AdminService.instance.setPostPrice(
        postId: widget.postId,
        priceInr: int.tryParse(_price.text.trim()) ?? 0,
        freeFromTier: _freeFrom,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
      _toast(replacedMedia
          ? 'Saved. Nobody was notified. The file you replaced is '
              'still in the Vault.'
          : 'Saved. Nobody was notified.');
    } on VaultFullError catch (e) {
      _toast('The Vault is at its 9 GB safety cap '
          '(${e.usedGb.toStringAsFixed(1)} GB used). Choose what may '
          'leave it - nothing goes without your approval.',
          bad: true);
      await VaultManager.open(context);
    } catch (e) {
      _toast('Could not save: ${adminDetail(e)}', bad: true);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _busyLabel = '';
        });
      }
    }
  }

  // ------------------------------------------------------------------
  // Screen
  // ------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('EDIT POST'),
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: IvoryColors.pageGradient),
        child: SafeArea(child: _inner()),
      ),
    );
  }

  Widget _inner() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'This post could not be opened, so it has not been '
              'changed.\n\n$_loadError',
              textAlign: TextAlign.center,
              style: const TextStyle(color: IvoryColors.burgundy),
            ),
            const SizedBox(height: 18),
            AdminButton(
              label: 'TRY AGAIN',
              icon: Icons.refresh,
              onPressed: _load,
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
      children: <Widget>[
        AdminEditBits.typeNotice(_type),
        const SizedBox(height: 16),
        TextField(
          controller: _title,
          decoration: const InputDecoration(labelText: 'Title'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _summary,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Short teaser'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _body,
          maxLines: 14,
          minLines: 6,
          decoration: const InputDecoration(
            labelText: 'The story itself',
            alignLabelWithHint: true,
          ),
        ),
        if (_type == 'audio' || _type == 'video') ...<Widget>[
          const SizedBox(height: 14),
          TextField(
            controller: _minutes,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'How many minutes long (optional)',
            ),
          ),
        ],
        const SizedBox(height: 20),
        AdminEditBits.currentFile(context, _mediaRef, busy: _busy),
        const SizedBox(height: 10),
        AdminAttachPanel(
          key: _attach,
          type: _type,
          busy: _busy,
          onToast: _toast,
        ),
        const SizedBox(height: 20),
        const AdminLabel('WHO CAN OPEN IT'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: audienceMixChips(
            who: _who,
            tiers: _tiers,
            onChange: (Set<int> s) => setState(() => _who = s),
          ),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _price,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Price in rupees (optional)',
            hintText: 'Leave empty to use the tier rule above',
          ),
        ),
        if ((int.tryParse(_price.text.trim()) ?? 0) > 0) ...<Widget>[
          const SizedBox(height: 12),
          const AdminLabel('OPENS FREE FROM'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: postFreeFromChips(
              selected: _freeFrom,
              tiers: _tiers,
              onTap: (int? v) => setState(() => _freeFrom = v),
            ),
          ),
        ],
        const SizedBox(height: 14),
        TextField(
          controller: _doorCredit,
          maxLength: 40,
          decoration: const InputDecoration(
            counterText: '',
            labelText: 'Story door credit (optional)',
          ),
        ),
        const SizedBox(height: 6),
        _liveSwitch(),
        const SizedBox(height: 18),
        _saveButton(),
        const SizedBox(height: 14),
        _reassurance(),
      ],
    );
  }

  /// The type is shown so she can see what she is editing, and locked
  /// so it cannot be changed. Changing it would send the post down a
  /// different detail route and strand whatever is attached to it.
  Widget _liveSwitch() {
    return SwitchListTile(
      value: _live,
      onChanged: _busy ? null : (bool v) => setState(() => _live = v),
      activeColor: IvoryColors.gold,
      contentPadding: EdgeInsets.zero,
      title: Text(
        _live ? 'Live' : 'Hidden - a draft',
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: IvoryColors.burgundy,
        ),
      ),
      subtitle: Text(
        _live
            ? 'Members can see it. Saving changes does not notify '
                'anybody again.'
            : 'Only you can see it. Turning this on will announce it '
                'to every member, because it has never been live.',
        style: TextStyle(fontSize: 12.5, color: IvoryColors.textSoft),
      ),
    );
  }

  Widget _saveButton() {
    return SizedBox(
      height: 54,
      child: FilledButton.icon(
        onPressed: _busy ? null : _save,
        icon: const Icon(Icons.check_rounded),
        label: Text(_busy ? _busyLabel : 'SAVE CHANGES'),
        style: FilledButton.styleFrom(
          backgroundColor: IvoryColors.gold,
          foregroundColor: IvoryColors.burgundy,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _reassurance() {
    return Text(
      _type == 'poll'
          ? 'Saving keeps the same post, so its votes, views and its '
              'place on Ivory\'s Firstlist are all kept. The poll '
              'options themselves cannot be changed here - that would '
              'rewrite what people already voted for.'
          : 'Saving keeps the same post, so its views, any purchases '
              'and its place on Ivory\'s Firstlist are all kept. No '
              'member is notified.',
      style: TextStyle(
        fontSize: 12.5,
        height: 1.55,
        color: IvoryColors.textSoft,
      ),
    );
  }
}

// END OF FILE - lib/screens/admin_edit_post.dart
