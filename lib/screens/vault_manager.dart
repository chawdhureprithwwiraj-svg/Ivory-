import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/ivory_errors.dart';
import '../services/b2_media_service.dart';
import '../services/vault_service.dart';
import '../theme/ivory_theme.dart';

/// ============================================================
/// IVORY - THE TWO VAULTS (CC.233)
///
/// The house looks inside BOTH of its storage houses at once, side by
/// side. R2 (the Cloudflare Vault) lists its own bucket through the
/// r2-vault edge, with weights and its own delete tap per row - every
/// delete still asks again before it goes, exactly as before. B2 (the
/// private Backblaze) lists everything the house references in it -
/// every post's media and cover, the wheel's voice and image banks -
/// through the media_vault_b2 hand, with the measured weight where the
/// house knows it (the wheel, since CC.232) and 'unmeasured' where it
/// never did (posts, which were never weighed). Two totals crown the
/// sheet: R2 against its 9 GB safety cap, B2 against Backblaze's own
/// allowance. Nothing is ever removed automatically.
///
/// SPRINT 24b - THE SPINNER THAT NEVER STOPPED: every failure lands,
/// the reason is shown in the house's own words, per side, and each
/// side carries its own way back in without closing the sheet.
/// ============================================================
class VaultManager {
  VaultManager._();

  static Future<void> open(BuildContext context,
      {VoidCallback? onChanged}) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ManagerSheet(onChanged: onChanged),
    );
  }
}

class _ManagerSheet extends StatefulWidget {
  const _ManagerSheet({this.onChanged});

  final VoidCallback? onChanged;

  @override
  State<_ManagerSheet> createState() => _ManagerSheetState();
}

class _ManagerSheetState extends State<_ManagerSheet> {
  bool _loading = true;
  int _used = 0;
  final int _cap = 9 * 1024 * 1024 * 1024;
  List<VaultItem> _items = <VaultItem>[];

  /// Set only when the R2 door actually jammed. Null means all is well.
  String? _error;

  /// The B2 side: referenced inventory and its own jam reason.
  List<Map<String, dynamic>> _b2 = <Map<String, dynamic>>[];
  int? _b2used;
  String? _b2error;

  /// True while a delete is in flight, so the sheet cannot be
  /// double-tapped into two removals at once.
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _b2error = null;
    });
    // R2 side - its own bucket, its own edge, its own jams.
    try {
      final List<VaultItem> items = await VaultService.instance.items();
      if (!mounted) return;
      items.sort((VaultItem a, VaultItem b) =>
          b.modified.compareTo(a.modified));
      setState(() {
        _items = items;
        _used = items.fold<int>(0, (int n, VaultItem i) => n + i.size);
      });
    } on VaultFullError catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Shared R2 storage is at its safety cap '
            '(${e.usedGb.toStringAsFixed(1)} GB of 9 GB). Choose what may '
            'leave it below.';
      });
    } on VaultError catch (e) {
      if (!mounted) return;
      setState(() => _error = e.detail);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = adminDetail(e));
    }
    // B2 side - what the house references in private Backblaze.
    try {
      final dynamic r = await Supabase.instance.client
          .rpc('media_vault_b2', params: <String, dynamic>{});
      final Map<String, dynamic> m =
          r is Map ? Map<String, dynamic>.from(r) : <String, dynamic>{};
      final List<dynamic> rows =
          (m['rows'] is List) ? m['rows'] as List<dynamic> : <dynamic>[];
      final int? used = await B2MediaService.instance.usedBytes();
      if (!mounted) return;
      setState(() {
        _b2 = rows
            .where((dynamic e) => e is Map)
            .map((dynamic e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _b2used = used;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _b2error = adminDetail(e);
        _loading = false;
      });
    }
    if (mounted) setState(() => _loading = false);
  }

  String _gb(int bytes) => (bytes / (1024 * 1024 * 1024)).toStringAsFixed(1);

  String _fmt(num b) {
    if (b < 1024) return '${b.round()} B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(0)} KB';
    if (b < 1024 * 1024 * 1024) return '${(b / 1024 / 1024).toStringAsFixed(1)} MB';
    return '${(b / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }

  String _tail(String ref) {
    final int i = ref.lastIndexOf('/');
    return i >= 0 && i < ref.length - 1 ? ref.substring(i + 1) : ref;
  }

  Future<void> _remove(VaultItem item) async {
    final bool referenced = item.postId != null;
    final bool? sure = await showDialog<bool>(
      context: context,
      builder: (BuildContext d) => AlertDialog(
        backgroundColor: IvoryColors.surface,
        title: Text(
          referenced
              ? (item.isPublicImage
                  ? 'This post uses this image'
                  : 'This story uses this file')
              : (item.isPublicImage
                  ? 'Remove this published image?'
                  : 'Remove from the Vault?'),
          style: const TextStyle(color: IvoryColors.burgundy),
        ),
        content: Text(
          referenced
              ? (item.isCoverImage
                  ? '"${item.postTitle}" uses this cover. Removing it clears '
                      'the cover; the post stays in place. '
                  : item.isPublicImage
                      ? '"${item.postTitle}" uses this photo. Removing it '
                          'clears the photo; the rest of the post stays in place. '
                      : '"${item.postTitle}" plays from this file. Removing '
                          'it removes the story media until a new file is attached. ')
                  + 'Back it up first - nothing is ever removed without you saying so.'
              : 'Nothing points at this ${item.isPublicImage ? 'image' : 'file'} '
                  'any more. Remove it and ${item.sizeLabel} comes back to '
                  'the shared R2 storage budget. This cannot be undone - back '
                  'it up first if it matters.',
          style: TextStyle(fontSize: 13.5, color: IvoryColors.textSoft),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text('KEEP IT'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(d, true),
            child: const Text('REMOVE'),
          ),
        ],
      ),
    );
    if (sure != true) return;

    setState(() => _working = true);
    try {
      await VaultService.instance.remove(item.key);
      widget.onChanged?.call();
      if (!mounted) return;
      setState(() => _working = false);
      await _load();
    } on VaultError catch (e) {
      if (!mounted) return;
      setState(() {
        _working = false;
        _error = e.detail;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _working = false;
        _error = adminDetail(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double pct = (_used / _cap).clamp(0.0, 1.0);
    final bool jammed = _error != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 26),
      decoration: const BoxDecoration(
        gradient: IvoryColors.pageGradient,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: DefaultTabController(
        length: 2,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const IvoryEyebrow('The two vaults',
                icon: Icons.domain_verification_outlined),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        jammed && _items.isEmpty
                            ? 'R2 did not answer'
                            : 'R2 · ${_gb(_used)} of ${_gb(_cap)} GB',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _loading
                              ? null
                              : (jammed && _items.isEmpty ? 0 : pct),
                          minHeight: 6,
                          color: jammed ? IvoryColors.danger : IvoryColors.gold,
                          backgroundColor: IvoryColors.hairlineStrong,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _b2used == null
                            ? 'B2 · waiting'
                            : 'B2 · ${_gb(_b2used!)} GB',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'no house cap - Backblaze\u2019s own allowance',
                        style:
                            TextStyle(fontSize: 11, color: IvoryColors.textFaint),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TabBar(
              labelColor: IvoryColors.burgundy,
              unselectedLabelColor: IvoryColors.textFaint,
              indicatorColor: IvoryColors.gold,
              tabs: <Widget>[
                Tab(text: 'R2 VAULT (${_items.length})'),
                Tab(text: 'B2 VAULT (${_b2.length})'),
              ],
            ),
            const SizedBox(height: 10),
            if (jammed) _errorPanel(),
            Flexible(
              child: _loading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(26),
                        child: CircularProgressIndicator(
                            color: IvoryColors.amber),
                      ),
                    )
                  : TabBarView(
                      children: <Widget>[_r2Pane(), _b2Pane()],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _r2Pane() {
    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Text(
            _error != null
                ? 'Nothing can be listed until the door opens.'
                : 'The R2 Vault is empty.',
            textAlign: TextAlign.center,
            style: TextStyle(color: IvoryColors.textSoft),
          ),
        ),
      );
    }
    return ListView(
      shrinkWrap: true,
      children: <Widget>[for (final VaultItem i in _items) _row(i)],
    );
  }

  Widget _b2Pane() {
    if (_b2error != null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: IvoryColors.surfaceWarm,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: IvoryColors.danger.withValues(alpha: .45)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('The B2 ledger did not open',
                style: TextStyle(
                    color: IvoryColors.danger,
                    fontWeight: FontWeight.w800,
                    fontSize: 13)),
            const SizedBox(height: 6),
            SelectableText(_b2error!,
                style: TextStyle(fontSize: 12.5, color: IvoryColors.textSoft)),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _working ? null : _load,
                icon: const Icon(Icons.refresh, size: 17),
                label: const Text('TRY AGAIN'),
                style:
                    TextButton.styleFrom(foregroundColor: IvoryColors.burgundy),
              ),
            ),
          ],
        ),
      );
    }
    if (_b2.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Text('Nothing of the house sits in private B2 yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: IvoryColors.textSoft)),
        ),
      );
    }
    return ListView(
      shrinkWrap: true,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            'Everything below is referenced by the house - a post, a cover, '
            'the wheel. Cull them from their own rooms; the B2 house keeps '
            'no orphans by itself.',
            style: TextStyle(fontSize: 11.5, color: IvoryColors.textFaint),
          ),
        ),
        for (final Map<String, dynamic> r in _b2) _b2row(r),
      ],
    );
  }

  Widget _b2row(Map<String, dynamic> r) {
    final String ref = (r['ref'] ?? '').toString();
    final num? b = (r['bytes'] is num) ? r['bytes'] as num : null;
    final String kind = (r['kind'] ?? '').toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: IvoryTheme.card(radius: 14),
      child: Row(
        children: <Widget>[
          Icon(
            kind.contains('voice')
                ? Icons.graphic_eq_outlined
                : kind.contains('image') || kind.contains('cover')
                    ? Icons.image_outlined
                    : Icons.movie_outlined,
            size: 19,
            color: IvoryColors.burgundy,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  (r['owner'] ?? '').toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: IvoryColors.burgundy,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '$kind · ${_tail(ref)} · '
                  '${b != null ? _fmt(b) : 'unmeasured'}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: IvoryColors.textFaint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The house is told exactly what jammed, and given the way back.
  Widget _errorPanel() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: IvoryColors.surfaceWarm,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: IvoryColors.danger.withValues(alpha: .45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: const <Widget>[
              Icon(Icons.lock_outline, size: 17, color: IvoryColors.danger),
              SizedBox(width: 8),
              Text(
                'The R2 Vault door did not open',
                style: TextStyle(
                  color: IvoryColors.danger,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          SelectableText(
            _error!,
            style: TextStyle(fontSize: 12.5, color: IvoryColors.textSoft),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _loading || _working ? null : _load,
              icon: const Icon(Icons.refresh, size: 17),
              label: const Text('TRY AGAIN'),
              style:
                  TextButton.styleFrom(foregroundColor: IvoryColors.burgundy),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(VaultItem i) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: IvoryTheme.card(radius: 14),
      child: Row(
        children: <Widget>[
          Icon(
            i.isPublicImage ? Icons.image_outlined : Icons.movie_outlined,
            size: 19,
            color: IvoryColors.burgundy,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  i.postTitle ?? 'Not tied to a story',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: IvoryColors.burgundy,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${i.isCoverImage ? 'Cover' : i.isPublicImage ? 'Photo' : 'Vault file'} · '
                  '${i.sizeLabel}  -  '
                  '${i.modified.isEmpty ? '' : i.modified.substring(0, 10)}',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: IvoryColors.textFaint,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove (asks first)',
            icon: const Icon(Icons.delete_outline, size: 20),
            color: IvoryColors.danger,
            onPressed: _working ? null : () => _remove(i),
          ),
        ],
      ),
    );
  }
}

// END OF FILE - lib/screens/vault_manager.dart
