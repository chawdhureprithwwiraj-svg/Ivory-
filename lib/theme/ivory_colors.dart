import 'package:flutter/material.dart';

/// ============================================================
/// IVORY - THE PALETTE, AND ONLY THE PALETTE.
///
/// Lifted out of `ivory_theme.dart`, which had reached the paste
/// ceiling. Nothing else moved and NO CALL SITE CHANGED:
/// `ivory_theme.dart` re-exports this file, so every
/// `import '../theme/ivory_theme.dart';` in the app still finds
/// `IvoryColors` exactly where it always did.
///
/// Colours live here. How things are STYLED - cards, shadows,
/// buttons, text themes - stays in `ivory_theme.dart`. That is
/// the whole split.
///
/// STRICT RULE, UNCHANGED: there is no black, dark grey or
/// charcoal anywhere in Ivory. The darkest tone permitted is
/// Deep Burgundy #4A0E17, and even shadows are burgundy-tinted.
/// ============================================================
class IvoryColors {
  IvoryColors._();

  // ---- Backgrounds -------------------------------------------------
  static const Color ivory = Color(0xFFFAF5E9);
  static const Color cream = Color(0xFFFFFDD0);

  /// Card face. A warm near-white that sits above the page.
  static const Color surface = Color(0xFFFFFCF2);

  /// Softly tinted surface for secondary panels and chips.
  static const Color surfaceWarm = Color(0xFFFDF1DC);

  // ---- Deep tones (accents only, never large areas) ----------------
  static const Color burgundy = Color(0xFF4A0E17);
  static const Color plum = Color(0xFF5C1222);

  // ---- Highlights ---------------------------------------------------
  static const Color gold = Color(0xFFD4AF37);
  static const Color amber = Color(0xFFE3A857);
  static const Color peach = Color(0xFFFFB366);

  // ---- Status --------------------------------------------------------
  // IMPERIAL EMERALD - the only cool colour in Ivory, and it
  // means one thing: THIS ALREADY HAPPENED.
  //
  // **GOLD IS ON AIR NOW. EMERALD IS THE RECORD.** Warm for
  // happening, cool for finished and kept. Never put emerald on
  // a live broadcast, never put gold on the history - the
  // temperature explains it before the words are read.
  //
  // This replaced a peacock teal on 10 Oct, before any screen
  // had used it. The rule above did not change; only the hexes
  // did. Emerald is the stone gold has always been set in, and
  // `emerald` is deep enough that gold type sings on it while
  // staying a clearly readable GREEN - it is not black, grey or
  // charcoal, and it sits at the same lightness as burgundy.
  // Full reasoning: handover part 13, CC.54.
  static const Color emerald = Color(0xFF07402C);
  static const Color emeraldMid = Color(0xFF0E5C41);
  static const Color emeraldLight = Color(0xFF218A5F);
  static const Color emeraldWash = Color(0xFFE6F1EA);

  static const Color success = Color(0xFF6B8E4E);
  static const Color warning = Color(0xFFE3A857);
  static const Color danger = Color(0xFFA8323E);

  // ---- Text ----------------------------------------------------------
  static const Color text = burgundy;
  static Color get textSoft => burgundy.withValues(alpha: 0.72);
  static Color get textFaint => burgundy.withValues(alpha: 0.52);

  // ---- Lines ----------------------------------------------------------
  static Color get hairline => gold.withValues(alpha: 0.42);
  static Color get hairlineStrong => gold.withValues(alpha: 0.85);

  // ---- Gradients -------------------------------------------------------
  /// The page itself: warm cream falling to ivory.
  static const LinearGradient pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[Color(0xFFFFFDF6), Color(0xFFFDF3DF)],
  );

  /// Light card face with the faintest warm tint.
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFFFFFDF7), Color(0xFFFDF4E2)],
  );

  /// Buttons, badges, the lock medallion.
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: <Color>[gold, amber],
  );

  /// Warmer call-to-action gradient, closer to the reference's glow.
  static const LinearGradient warmGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: <Color>[amber, peach],
  );

  /// Reserved for the few deep panels: the hero, premium banners.
  static const LinearGradient deepGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[burgundy, plum],
  );
}

// END OF FILE - lib/theme/ivory_colors.dart
