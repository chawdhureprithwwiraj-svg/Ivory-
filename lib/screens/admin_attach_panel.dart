import 'dart:io';

import 'package:flutter/material.dart';

import '../models/media_ref.dart';
import '../services/admin_service.dart';
import '../services/vault_service.dart';
import 'vault_manager.dart';
import '../theme/ivory_theme.dart';
import '../widgets/admin_bits.dart';
import '../widgets/admin_post_chips.dart';

/// ============================================================
/// ADMIN STUDIO - THE MEDIA ATTACH PANEL
///
/// Picking files, the Vault queue for big videos, the link field
/// and the cover row. The composer reads the panel's state when
/// it publishes, so a gigabyte film never leaves this panel's
/// care until publish day.
/// ============================================================
class AdminAttachPanel extends StatefulWidget {
  const AdminAttachPanel({
    super.key,
    required this.type,
    required this.busy,
    required this.onToast,
  });

  final String type;
  final bool busy;
  final void Function(String message, {bool bad}) onToast;

  @override
  State<AdminAttachPanel> createState() => AdminAttachPanelState();
}

class AdminAttachPanelState extends State<AdminAttachPanel> {
  /// SPRINT 24d - THE LIFECYCLE PROBE.
  /// The chip vanishes on publish while the title survives, which means
  /// this panel's state was emptied without _reset() running. Only two
  /// things can do that: clearForType(), or this State being destroyed
  /// and rebuilt. These three counters tell us which, in one tap.
  /// They cost nothing and come out once the cause is known.
  static int inits = 0;
  static int disposes = 0;
  static int clears = 0;

  static String get probe => 'init $inits / dispose $disposes / clear $clears';

  PickedMedia? picked;
  String? uploadedUrl;
  PickedMedia? thumb;
  String? uploadedThumbUrl;

  /// A video too big for Supabase waits here for the Vault ride.
  String? vaultPath;
  String? vaultName;
  int vaultSize = 0;
  String? vaultUsed;

  final TextEditingController link = TextEditingController();

  bool get hasLink => link.text.trim().isNotEmpty;

  void setUploadedUrl(String? v) => setState(() => uploadedUrl = v);
  void setUploadedThumbUrl(String? v) =>
      setState(() => uploadedThumbUrl = v);

  @override
  void initState() {
    super.initState();
    inits++;
  }

  void clearForType() {
    clears++;
    setState(() {
      picked = null;
      uploadedUrl = null;
      vaultPath = null;
      vaultName = null;
      vaultSize = 0;
      vaultUsed = null;
    });
  }

  void reset() {
    link.clear();
    setState(() {
      thumb = null;
      uploadedThumbUrl = null;
    });
    clearForType();
  }

  IconData get typeIcon {
    switch (widget.type) {
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

  Future<void> pick({required bool thumbnail}) async {
    try {
      // Videos are picked by path first: a Vault film can be a
      // gigabyte and must never be read into memory.
      if (!thumbnail && widget.type == 'video') {
        final VaultPick? v = await AdminService.instance.pickVideoPath();
        if (v == null) return;
        if (v.size > 48 * 1024 * 1024) {
          setState(() {
            vaultPath = v.path;
            vaultName = v.name;
            vaultSize = v.size;
            picked = null;
            uploadedUrl = null;
          });
          final int? used = await VaultService.instance.usedBytes();
          if (used != null && mounted) {
            setState(() => vaultUsed =
                'Vault ${(used / (1024 * 1024 * 1024)).toStringAsFixed(1)} '
                'GB of 9 GB used - the app refuses any upload that '
                    'would cross the cap.');
          }
          widget.onToast('${v.sizeLabel} noted - this one rides in the Vault '
              'when you publish.');
          return;
        }
        setState(() {
          vaultPath = null;
          vaultName = null;
          vaultSize = 0;
          picked = PickedMedia(
              name: v.name, bytes: File(v.path).readAsBytesSync());
          uploadedUrl = null;
          link.clear();
        });
        return;
      }
      PickedMedia? m;
      if (thumbnail || widget.type == 'image') {
        m = await AdminService.instance.pickImage();
      } else if (widget.type == 'audio') {
        m = await AdminService.instance.pickFile(audioOnly: true);
      } else {
        m = await AdminService.instance.pickFile();
      }
      if (m == null) return;
      if (m.size > 48 * 1024 * 1024) {
        widget.onToast(
          'That file is ${m.sizeLabel}. Keep uploads under about 48 MB, or '
          'host it and paste the link instead.',
          bad: true,
        );
        return;
      }
      setState(() {
        if (thumbnail) {
          thumb = m;
          uploadedThumbUrl = null;
        } else {
          picked = m;
          uploadedUrl = null;
          link.clear();
        }
      });
    } catch (e) {
      widget.onToast('Could not open that file: $e', bad: true);
    }
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
            if (picked != null) ...<Widget>[
              AdminPickedFileCard(
                media: picked!,
                uploaded: uploadedUrl != null,
                icon: typeIcon,
                onRemove: () => setState(() {
                  picked = null;
                  uploadedUrl = null;
                }),
              ),
              const SizedBox(height: 10),
            ],
            SizedBox(
              width: double.infinity,
              child: AdminButton(
                label: (picked == null && vaultPath == null)
                    ? 'UPLOAD A FILE'
                    : 'REPLACE FILE',
                icon: Icons.upload_file,
                onPressed: widget.busy ? null : () => pick(thumbnail: false),
              ),
            ),
            if (vaultPath != null) ...<Widget>[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: IvoryColors.surfaceWarm,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: IvoryColors.gold, width: 1),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.cloud_upload_outlined,
                        size: 18, color: IvoryColors.burgundy),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${vaultName ?? 'video'} - '
                        '${AdminService.sizeLabel(vaultSize)} - rides in '
                            'the Vault (R2) when you publish.',
                        style: TextStyle(
                            fontSize: 12.5, color: IvoryColors.textSoft),
                      ),
                    ),
                  ],
                ),
              ),
              if (vaultUsed != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    vaultUsed!,
                    style: TextStyle(
                        fontSize: 11.5, color: IvoryColors.textFaint),
                  ),
                ),
            ],
            if (widget.type == 'video')
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: widget.busy
                      ? null
                      : () => VaultManager.open(context, onChanged: () async {
                            final int? u =
                                await VaultService.instance.usedBytes();
                            if (u != null && mounted) {
                              setState(() => vaultUsed =
                                  'Vault ${(u / (1024 * 1024 * 1024)).toStringAsFixed(1)} '
                                  'GB of 9 GB used - the app refuses any '
                                      'upload that would cross the cap.');
                            }
                          }),
                  icon: const Icon(Icons.folder_open_outlined, size: 17),
                  label: const Text('MANAGE VAULT'),
                  style: TextButton.styleFrom(
                      foregroundColor: IvoryColors.burgundy),
                ),
              ),
            const SizedBox(height: 12),
            const AdminOrLine('or point at a link'),
            const SizedBox(height: 8),
            TextFormField(
              controller: link,
              keyboardType: TextInputType.url,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'YouTube / Telegram / R2 / direct link',
                isDense: true,
              ),
            ),
            if (link.text.trim().isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                'Detected: '
                '${MediaRef.parse(link.text.trim()).source.label}',
                style: TextStyle(fontSize: 11.5, color: IvoryColors.success),
              ),
            ],
            const SizedBox(height: 12),
            Divider(color: IvoryColors.hairline),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    thumb == null
                        ? 'Cover image (optional)'
                        : '${thumb!.name} \u00b7 ${thumb!.sizeLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(fontSize: 12.8, color: IvoryColors.textSoft),
                  ),
                ),
                TextButton(
                  onPressed: widget.busy ? null : () => pick(thumbnail: true),
                  style: TextButton.styleFrom(
                      foregroundColor: IvoryColors.burgundy),
                  child: Text(thumb == null ? 'ADD' : 'CHANGE'),
                ),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  @override
  void dispose() {
    disposes++;
    link.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _mediaSection(),
    );
  }
}

// END OF FILE - lib/screens/admin_attach_panel.dart
