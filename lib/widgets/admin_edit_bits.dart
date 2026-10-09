import 'package:flutter/material.dart';

import '../screens/vault_manager.dart';
import '../theme/ivory_theme.dart';
import 'admin_bits.dart';

/// ============================================================
/// THE TWO NOTICES AT THE TOP OF THE EDIT PAGE.
///
/// Lifted out of admin_edit_post.dart, which had grown past the
/// size that can be pasted reliably on a phone. Nothing about
/// them changed in the move.
///
/// They are static because they describe the post, not the
/// editing of it - they read nothing that can change while the
/// page is open.
/// ============================================================
class AdminEditBits {
  const AdminEditBits._();

  /// What kind of post this is, and that it cannot change.
  static Widget typeNotice(String type) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: IvoryTheme.card(),
      child: Row(
        children: <Widget>[
          const Icon(Icons.lock_outline, size: 18, color: IvoryColors.plum),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'This is a ${typeWord(type)}. The kind of post cannot be '
              'changed - everything else can.',
              style: const TextStyle(
                fontSize: 13,
                color: IvoryColors.burgundy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String typeWord(String type) {
    switch (type) {
      case 'audio':
        return 'voice note';
      case 'video':
        return 'film';
      case 'image':
        return 'photograph';
      case 'poll':
        return 'poll';
      default:
        return 'written story';
    }
  }

  /// What is attached right now, and the plain truth about what
  /// happens to it if she replaces it.
  /// Whether a file is already attached, and what replacing
  /// it would mean.
  static Widget currentFile(String? mediaRef, {required bool busy}) {
    final bool has = mediaRef != null && mediaRef.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: IvoryTheme.card(highlighted: has),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const AdminLabel('THE FILE ON IT NOW'),
          const SizedBox(height: 8),
          Text(
            has
                ? 'This post already carries a file. Attach something '
                    'below only if you want to replace it. Leave the '
                    'panel alone and the file stays exactly as it is.'
                : 'Nothing is attached to this post. You can add '
                    'something below.',
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: IvoryColors.burgundy,
            ),
          ),
          if (has) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              'If you do replace it, the old file is NOT deleted - '
              'nothing ever leaves the Vault without you saying so. It '
              'will keep taking up room until you clear it yourself.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.5,
                color: IvoryColors.textSoft,
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: AdminButton(
                label: 'MANAGE VAULT',
                icon: Icons.folder_open_outlined,
                strong: false,
                onPressed:
                    busy ? null : () => VaultManager.open(context),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// END OF FILE - lib/widgets/admin_edit_bits.dart
