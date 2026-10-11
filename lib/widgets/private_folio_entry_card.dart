import 'package:flutter/material.dart';

import '../models/folio_entry.dart';
import '../theme/ivory_theme.dart';
import 'call_sheet_bits.dart';

class PrivateFolioEntryCard extends StatelessWidget {
  const PrivateFolioEntryCard({
    super.key,
    required this.entry,
    required this.onEdit,
    required this.onDelete,
    required this.onOpenLink,
  });

  final FolioEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onOpenLink;

  @override
  Widget build(BuildContext context) {
    final IconData icon = switch (entry.kind) {
      FolioKind.note => Icons.edit_note_rounded,
      FolioKind.draft => Icons.drafts_outlined,
      FolioKind.link => Icons.link_rounded,
      FolioKind.callNote => Icons.event_note_rounded,
    };
    final String preview = entry.kind == FolioKind.link
        ? (entry.body.isEmpty ? (entry.url ?? '') : entry.body)
        : entry.body;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: IvoryColors.surfaceWarm,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
        side: BorderSide(color: IvoryColors.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: IvoryColors.cream,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: IvoryColors.burgundy, size: 20),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    entry.kind.label.toUpperCase(),
                    style: TextStyle(
                      color: IvoryColors.amber,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.9,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    entry.title.isEmpty ? entry.kind.label : entry.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: IvoryColors.burgundy,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (preview.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      preview,
                      maxLines: entry.kind == FolioKind.link ? 1 : 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: IvoryColors.textSoft,
                        fontSize: 12.2,
                        height: 1.35,
                      ),
                    ),
                  ],
                  if (entry.updatedAt != null) ...<Widget>[
                    const SizedBox(height: 6),
                    Text(
                      'Kept ${ivoryWhen(entry.updatedAt!)}',
                      style: TextStyle(
                        color: IvoryColors.textFaint,
                        fontSize: 10,
                      ),
                    ),
                  ],
                  if (entry.tags.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 5,
                      runSpacing: 3,
                      children: entry.tags
                          .map((String tag) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: IvoryColors.cream,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  tag,
                                  style: const TextStyle(
                                    color: IvoryColors.plum,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                  if (entry.kind == FolioKind.link) ...<Widget>[
                    const SizedBox(height: 4),
                    TextButton.icon(
                      onPressed: onOpenLink,
                      icon: const Icon(Icons.open_in_new_rounded, size: 14),
                      label: const Text('OPEN SAVED LINK'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 28),
                        alignment: Alignment.centerLeft,
                        textStyle: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Folio page options',
              onSelected: (String action) {
                if (action == 'edit') onEdit();
                if (action == 'delete') onDelete();
                if (action == 'open' && entry.kind == FolioKind.link) {
                  onOpenLink();
                }
              },
              itemBuilder: (_) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                    value: 'edit', child: Text('Edit page')),
                if (entry.kind == FolioKind.link)
                  const PopupMenuItem<String>(
                      value: 'open', child: Text('Open link')),
                const PopupMenuItem<String>(
                    value: 'delete', child: Text('Delete page')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// END OF FILE - lib/widgets/private_folio_entry_card.dart
