import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../screens/language_screen.dart';
import '../theme/ivory_theme.dart';

void _openLanguages(BuildContext context) {
  Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => const LanguageScreen(change: true),
    ),
  );
}

/// The "App language" row in Profile: shows the language now in use and
/// opens the same picker as the first-open screen.
class ProfileLanguageRow extends StatelessWidget {
  const ProfileLanguageRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openLanguages(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: IvoryTheme.card(radius: 18),
            child: Row(
              children: <Widget>[
                const Icon(Icons.translate, size: 20, color: IvoryColors.plum),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    'App language'.tr,
                    style: const TextStyle(
                      color: IvoryColors.plum,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  L10n.instance.info.native,
                  style: const TextStyle(
                    color: IvoryColors.plum,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: IvoryColors.plum),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A small language button for the sign-in screen, so a member who
/// picked the wrong language can change it before signing in.
class LanguageChip extends StatelessWidget {
  const LanguageChip({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => _openLanguages(context),
      icon: const Icon(Icons.translate, size: 16, color: IvoryColors.plum),
      label: Text(
        L10n.instance.info.native,
        style: const TextStyle(
          color: IvoryColors.plum,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// END OF FILE - lib/widgets/language_row.dart
