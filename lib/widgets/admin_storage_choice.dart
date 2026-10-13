import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';

/// A visible, explicit provider selector for post media. Draft images can
/// only use private B2; public R2 is offered only for published images.
class AdminStorageChoice extends StatelessWidget {
  const AdminStorageChoice({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.image = false,
    this.allowPublicR2 = true,
    this.enabled = true,
  });

  final String title;
  final String? value;
  final ValueChanged<String> onChanged;
  final bool image;
  final bool allowPublicR2;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final List<MapEntry<String, String>> options = image
        ? <MapEntry<String, String>>[
            const MapEntry<String, String>('b2', 'B2 - private (default)'),
            if (allowPublicR2)
              const MapEntry<String, String>(
                'r2',
                'R2 - public to anyone with the link',
              ),
          ]
        : <MapEntry<String, String>>[
            const MapEntry<String, String>('r2', 'R2 - private'),
            const MapEntry<String, String>('b2', 'B2 - private'),
          ];
    final String? selectedValue =
        image && !allowPublicR2 ? 'b2' : value;
    final String helper = image
        ? (allowPublicR2
              ? 'B2 stays private by default. R2 images are public to anyone with the URL.'
              : 'Draft photos and covers stay private in B2. Public R2 is unavailable until the post is published.')
        : 'Choose R2 or B2 for this upload. Both are private; frequent B2 downloads can exceed its free allowance.';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: IvoryColors.plum,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: options.map((MapEntry<String, String> option) {
              final bool selected = selectedValue == option.key;
              return ChoiceChip(
                label: Text(
                  option.value,
                  style: TextStyle(
                    color: IvoryColors.burgundy,
                    fontSize: 11.5,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
                selected: selected,
                showCheckmark: true,
                checkmarkColor: IvoryColors.burgundy,
                selectedColor: IvoryColors.gold,
                backgroundColor: IvoryColors.surface,
                side: BorderSide(
                  color: selected ? IvoryColors.gold : IvoryColors.hairlineStrong,
                ),
                onSelected: enabled
                    ? (bool tapped) {
                        if (tapped) onChanged(option.key);
                      }
                    : null,
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
          Text(
            helper,
            style: TextStyle(
              color: IvoryColors.textFaint,
              fontSize: 11.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// END OF FILE - lib/widgets/admin_storage_choice.dart
