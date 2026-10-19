import 'package:flutter/material.dart';

/// ============================================================
/// IVORY - THE TEN RIBBON COLOURS (none blue, none black)
///
/// Each colour is a base, a mid tone, a light tone, a pale trim and a
/// deep shade for shadows. The fluorescent ones (Blaze Orange, Neon
/// Sun, Electric Lime) and Antique Gold Silk carry a firm outline on
/// the letters so the white stays easy to read.
/// ============================================================
class TickerPalette {
  const TickerPalette(
    this.name,
    this.base,
    this.mid,
    this.light,
    this.trim,
    this.deep, {
    this.outline = false,
  });

  final String name;
  final Color base;
  final Color mid;
  final Color light;
  final Color trim;
  final Color deep;

  /// The fluorescent colours get a firm outline on the letters so the
  /// white stays easy to read on the bright ground.
  final bool outline;
}

const List<TickerPalette> kTickerPalettes = <TickerPalette>[
  TickerPalette('Royal Burgundy', Color(0xFF5C0F22), Color(0xFF8E1B3A),
      Color(0xFFC0395F), Color(0xFFF3D9A6), Color(0xFF4A0E17)),
  TickerPalette('Imperial Emerald', Color(0xFF07402C), Color(0xFF0E5C41),
      Color(0xFF218A5F), Color(0xFFE6F1EA), Color(0xFF063524)),
  TickerPalette('Blaze Orange', Color(0xFFB83200), Color(0xFFFF5A0A),
      Color(0xFFFF8A1F), Color(0xFFFFE6C7), Color(0xFF8A2500),
      outline: true),
  TickerPalette('Neon Sun', Color(0xFFA87A00), Color(0xFFF0B800),
      Color(0xFFFFD60A), Color(0xFFFFF6C2), Color(0xFF7A5400),
      outline: true),
  TickerPalette('Rose Magenta', Color(0xFF7A1043), Color(0xFFC2185B),
      Color(0xFFF2578F), Color(0xFFFFDCE8), Color(0xFF5E0B33)),
  TickerPalette('Coral Sunset', Color(0xFFA63A1E), Color(0xFFE8603C),
      Color(0xFFFF9A6B), Color(0xFFFFE3D2), Color(0xFF7A2A14)),
  TickerPalette('Ruby Flame', Color(0xFF7A0A14), Color(0xFFC41E2F),
      Color(0xFFF0503E), Color(0xFFFFD9CF), Color(0xFF5A0810)),
  TickerPalette('Antique Gold Silk', Color(0xFF7A5A12), Color(0xFFB8892B),
      Color(0xFFE6C36A), Color(0xFFFFF1CF), Color(0xFF5A3F0A),
      outline: true),
  TickerPalette('Electric Lime', Color(0xFF3D6B00), Color(0xFF7FD100),
      Color(0xFFC6F31A), Color(0xFFF3FFC9), Color(0xFF2C5000),
      outline: true),
  TickerPalette('Mulberry Wine', Color(0xFF4D0A24), Color(0xFF8A1648),
      Color(0xFFC42F68), Color(0xFFF7D2DE), Color(0xFF4D0A24)),
];

const Color kTickerCream = Color(0xFFFFF8EC);

IconData tickerGlyph(String kind) {
  switch (kind) {
    case 'mark':
      return Icons.workspace_premium;
    case 'treasure':
    case 'treasure_gift':
      return Icons.diamond;
    case 'rung':
      return Icons.military_tech;
    case 'fullday':
    case 'peal':
      return Icons.notifications_active;
    case 'bellset':
    case 'pledge':
      return Icons.notifications;
    case 'glow':
      return Icons.favorite;
    case 'knockoff10':
      return Icons.emoji_events;
    case 'gift':
    case 'gift_live':
      return Icons.card_giftcard;
    case 'welcome':
      return Icons.celebration;
    case 'post':
      return Icons.auto_stories;
    case 'live':
      return Icons.sensors;
    case 'private':
      return Icons.lock;
    case 'note':
      return Icons.campaign;
    default:
      return Icons.star;
  }
}


// END OF FILE - lib/widgets/ticker_palettes.dart
