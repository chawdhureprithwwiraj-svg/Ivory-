import 'package:flutter/material.dart';

import '../core/ivory_errors.dart';
import '../services/vault_service.dart';
import '../theme/ivory_theme.dart';

/// ============================================================
/// IVORY - THE VAULT MANAGER
///
/// The house looks inside the Vault and decides, by hand, what may
/// leave it. Nothing is ever removed automatically: every row has
/// its own delete tap, and every delete asks again before it goes.
/// Rows a story still points at warn that the story will lose its
/// film (the post quietly retires to text-only).
///
/// SPRINT 24b - THE SPINNER THAT NEVER STOPPED.
/// The old _load() had no catch. When the edge function threw, the
/// line that turned the spinner off was never reached, so a broken
/// Vault span forever and read "0.0 GB of 9.0 GB used" - which
/// looked like an empty Vault and was in fact a locked door.
/// Now: every failure lands, the reason is shown in the house's own
/// words, and there is a way back in without closing the sheet.
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

  /// Set only when the door actually jammed. Null means all is well.
  String? _error;

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
    });
    try {
      final List<VaultItem> items = await VaultService.instance.items();
      if (!mounted) return;
      items.sort((VaultItem a, VaultItem b) =>
          b.modified.compareTo(a.modified));
      setState(() {
        _items = items;
        _used = items.fold<int>(0, (int n, VaultItem i) => n + i.size);
        _loading = false;
      });
    } on VaultFullError catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'The Vault is at its safety cap '
            '(${e.usedGb.toStringAsFixed(1)} GB of 9 GB). Choose what may '
            'leave it below.';
      });
    } on VaultError catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.detail;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = adminDetail(e);
      });
    }
  }

  String _gb(int bytes) => (bytes / (1024 * 1024 * 1024)).toStringAsFixed(1);

  Future<void> _remove(VaultItem item) async {
    final bool referenced = item.postId != null;
    final bool? sure = await showDialog<bool>(
      context: context,
      builder: (BuildContext d) => AlertDialog(
        backgroundColor: IvoryColors.surface,
        title: Text(
          referenced ? 'This story uses this file' : 'Remove from the Vault?',
          style: const TextStyle(color: IvoryColors.burgundy),
        ),
        content: Text(
          referenced
              ? '"${item.postTitle}" plays from this file. If you remove '
                  'it, that story quietly becomes text-only until you '
                  'attach a new link. Back it up first - nothing is '
                  'ever removed without you saying so.'
              : 'Nothing points at this file any more. Remove it and '
                  '${item.sizeLabel} comes back to the Vault. This '
                  'cannot be undone - back it up first if it matters.',
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const IvoryEyebrow('The Vault', icon: Icons.cloud_outlined),
          const SizedBox(height: 8),
          Text(
            // A jammed door must never claim the Vault is empty.
            jammed && _items.isEmpty
                ? 'The Vault did not answer'
                : '${_gb(_used)} GB of ${_gb(_cap)} GB used',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _loading ? null : (jammed && _items.isEmpty ? 0 : pct),
              minHeight: 6,
              color: jammed ? IvoryColors.danger : IvoryColors.gold,
              backgroundColor: IvoryColors.hairlineStrong,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Nothing here is ever deleted on its own. You choose, '
            'you approve, then it goes.',
            style: TextStyle(fontSize: 11.5, color: IvoryColors.textFaint),
          ),
          const SizedBox(height: 14),
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
                : _items.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(26),
                          child: Text(
                            jammed
                                ? 'Nothing can be listed until the door opens.'
                                : 'The Vault is empty.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: IvoryColors.textSoft),
                          ),
                        ),
                      )
                    : ListView(
                        shrinkWrap: true,
                        children: <Widget>[
                          for (final VaultItem i in _items) _row(i),
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
            children: <Widget>[
              const Icon(Icons.lock_outline,
                  size: 17, color: IvoryColors.danger),
              const SizedBox(width: 8),
              Text(
                'The Vault door did not open',
                style: const TextStyle(
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
          const Icon(Icons.movie_outlined,
              size: 19, color: IvoryColors.burgundy),
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
