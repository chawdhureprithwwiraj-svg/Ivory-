import 'package:flutter/material.dart';

/// Small, explicit provider control for post media. It never offers public
/// R2 image storage while a post is a draft.
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
    final List<DropdownMenuItem<String>> options = image
        ? <DropdownMenuItem<String>>[
            const DropdownMenuItem<String>(
              value: 'b2',
              child: Text('B2 - private (default)'),
            ),
            if (allowPublicR2)
              const DropdownMenuItem<String>(
                value: 'r2',
                child: Text('R2 - public to anyone with the link'),
              ),
          ]
        : <DropdownMenuItem<String>>[
            const DropdownMenuItem<String>(
              value: 'r2',
              child: Text('R2 - private'),
            ),
            const DropdownMenuItem<String>(
              value: 'b2',
              child: Text('B2 - private'),
            ),
          ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: image && !allowPublicR2 ? 'b2' : value,
        decoration: InputDecoration(
          labelText: title,
          hintText: image ? null : 'Choose R2 or B2',
          helperText: image
              ? (allowPublicR2
                    ? 'B2 stays private. R2 images are public to anyone with the URL.'
                    : 'Draft photos and covers stay private in B2. R2 is available when live.')
              : 'Choose one for this upload. Both are private; frequent B2 downloads can exceed its free allowance.',
          helperMaxLines: 2,
          isDense: true,
        ),
        items: options,
        onChanged: enabled
            ? (String? next) {
                if (next != null) onChanged(next);
              }
            : null,
      ),
    );
  }
}

// END OF FILE - lib/widgets/admin_storage_choice.dart
