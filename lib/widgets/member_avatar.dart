import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';

class MemberAvatar extends StatelessWidget {
  const MemberAvatar({
    super.key,
    required this.displayName,
    required this.size,
    this.imageUrl,
    this.premiumFrame = false,
  });

  final String displayName;
  final double size;
  final String? imageUrl;
  final bool premiumFrame;

  Widget _initial() {
    final String name = displayName.trim();
    final String initial = name.isEmpty ? 'I' : name.substring(0, 1).toUpperCase();
    return Container(
      color: IvoryColors.gold.withValues(alpha: 0.2),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontFamily: IvoryTheme.displayFont,
          fontSize: size * 0.39,
          fontWeight: FontWeight.w800,
          color: IvoryColors.burgundy,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? url = imageUrl;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(premiumFrame ? 2.8 : 1.2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: premiumFrame ? IvoryColors.goldGradient : null,
        color: premiumFrame ? null : IvoryColors.hairline,
        boxShadow: premiumFrame ? IvoryTheme.softShadow(blur: 8, y: 2) : null,
      ),
      child: ClipOval(
        child: url == null || url.isEmpty
            ? _initial()
            : Image.network(
                url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                loadingBuilder: (BuildContext context, Widget child,
                    ImageChunkEvent? progress) =>
                    progress == null ? child : _initial(),
                errorBuilder: (_, __, ___) => _initial(),
              ),
      ),
    );
  }
}

// END OF FILE - lib/widgets/member_avatar.dart
