import 'package:flutter/material.dart';

import '../services/admin_service.dart';
import '../theme/ivory_theme.dart';

/// ============================================================
/// SMALL PARTS SHARED BY THE ADMIN STUDIO
///
/// Kept in their own file so no single admin screen grows long
/// enough to be truncated while pasting on a phone.
/// ============================================================

/// The little burgundy all-caps section label.
class AdminLabel extends StatelessWidget {
  const AdminLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: IvoryColors.plum,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
        ),
      );
}

/// A gold-when-selected chip with an icon.
class AdminSelectChip extends StatelessWidget {
  const AdminSelectChip({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected
              ? IvoryColors.goldGradient
              : const LinearGradient(
                  colors: <Color>[Color(0xFFFFFCF2), Color(0xFFFDF4E2)],
                ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? IvoryColors.gold : IvoryColors.hairline,
            width: selected ? 1.4 : 1,
          ),
          boxShadow: selected ? IvoryTheme.softShadow(blur: 10, y: 4) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 17, color: IvoryColors.burgundy),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: IvoryColors.burgundy,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The card that appears once a file has been chosen off the phone.
class AdminPickedFileCard extends StatelessWidget {
  const AdminPickedFileCard({
    super.key,
    required this.media,
    required this.uploaded,
    required this.icon,
    required this.onRemove,
  });

  final PickedMedia media;
  final bool uploaded;
  final IconData icon;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: IvoryColors.goldGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: IvoryColors.burgundy, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                media.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: IvoryColors.burgundy,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
              Text(
                uploaded
                    ? '${media.sizeLabel} \u00b7 uploaded'
                    : '${media.sizeLabel} \u00b7 uploads when you send',
                style:
                    TextStyle(fontSize: 11.5, color: IvoryColors.textFaint),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onRemove,
          icon: const Icon(Icons.close, color: IvoryColors.plum),
        ),
      ],
    );
  }
}

/// A plain outlined admin button.
class AdminButton extends StatelessWidget {
  const AdminButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.strong = true,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 17),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: IvoryColors.burgundy,
        side: BorderSide(
          color: strong ? IvoryColors.burgundy : IvoryColors.hairlineStrong,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}

/// "------ or point at a link ------"
class AdminOrLine extends StatelessWidget {
  const AdminOrLine(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Row(
        children: <Widget>[
          Expanded(child: Divider(color: IvoryColors.hairline)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              text,
              style: TextStyle(fontSize: 11.5, color: IvoryColors.textFaint),
            ),
          ),
          Expanded(child: Divider(color: IvoryColors.hairline)),
        ],
      );
}

// END OF FILE - lib/widgets/admin_bits.dart
