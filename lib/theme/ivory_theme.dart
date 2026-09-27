import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// IVORY DESIGN SYSTEM
/// "Every story leaves a mark"
///
/// STRICT COLOR POLICY: absolutely no black, dark gray or charcoal.
/// The darkest tone allowed anywhere in this app is Deep Burgundy (#4A0E17).
class IvoryColors {
  IvoryColors._();

  // Backgrounds - warm soft ivory / cream
  static const Color ivory = Color(0xFFFAF5E9);
  static const Color cream = Color(0xFFFFFDD0);

  // Containers & cards - rich burgundy / deep royal plum
  static const Color burgundy = Color(0xFF4A0E17);
  static const Color plum = Color(0xFF5C1222);

  // Primary highlights - warm metallic gold & butterscotch amber
  static const Color gold = Color(0xFFD4AF37);
  static const Color amber = Color(0xFFE3A857);

  // Secondary accent - peach glow / sunset gold
  static const Color peach = Color(0xFFFFB366);

  // Semantic tones (kept inside the warm palette)
  static const Color success = Color(0xFF6B8E4E);
  static const Color warning = Color(0xFFE3A857);
  static const Color danger = Color(0xFFA8323E);

  /// Signature burgundy card gradient used across the storytelling feed.
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[plum, burgundy],
  );

  /// Warm ivory background wash.
  static const LinearGradient pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[cream, ivory],
  );

  /// Gold shimmer used on headers, borders and lock icons.
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: <Color>[amber, gold, peach],
  );
}

class IvoryTheme {
  IvoryTheme._();

  /// Soft warm shadow. Uses burgundy at low opacity instead of black,
  /// so the strict no-black policy is respected even in elevation.
  static List<BoxShadow> softShadow({double blur = 18, double y = 8}) {
    return <BoxShadow>[
      BoxShadow(
        color: IvoryColors.burgundy.withValues(alpha: 0.18),
        blurRadius: blur,
        offset: Offset(0, y),
      ),
    ];
  }

  static ThemeData light() {
    final ColorScheme scheme = const ColorScheme.light().copyWith(
      primary: IvoryColors.burgundy,
      onPrimary: IvoryColors.ivory,
      secondary: IvoryColors.gold,
      onSecondary: IvoryColors.burgundy,
      surface: IvoryColors.ivory,
      onSurface: IvoryColors.burgundy,
      error: IvoryColors.danger,
      onError: IvoryColors.ivory,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: IvoryColors.ivory,
      canvasColor: IvoryColors.ivory,
      shadowColor: IvoryColors.burgundy.withValues(alpha: 0.2),
      splashColor: IvoryColors.peach.withValues(alpha: 0.18),
      highlightColor: IvoryColors.amber.withValues(alpha: 0.12),
      dividerTheme: DividerThemeData(
        color: IvoryColors.gold.withValues(alpha: 0.35),
        thickness: 1,
        space: 24,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: IvoryColors.burgundy,
        foregroundColor: IvoryColors.gold,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: IvoryColors.gold,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: 3,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: IvoryColors.burgundy,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        color: IvoryColors.plum,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: IvoryColors.gold.withValues(alpha: 0.55),
            width: 1.2,
          ),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: IvoryColors.gold,
          fontSize: 40,
          fontWeight: FontWeight.w700,
          letterSpacing: 8,
        ),
        headlineMedium: TextStyle(
          color: IvoryColors.burgundy,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
        titleMedium: TextStyle(
          color: IvoryColors.burgundy,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: IvoryColors.burgundy,
          fontSize: 16,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: IvoryColors.burgundy,
          fontSize: 14,
          height: 1.5,
        ),
        labelLarge: TextStyle(
          color: IvoryColors.burgundy,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: IvoryColors.amber,
          foregroundColor: IvoryColors.burgundy,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: IvoryColors.gold,
          side: const BorderSide(color: IvoryColors.gold, width: 1.4),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: IvoryColors.cream,
        hintStyle: TextStyle(
          color: IvoryColors.burgundy.withValues(alpha: 0.45),
        ),
        labelStyle: const TextStyle(color: IvoryColors.burgundy),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: IvoryColors.gold.withValues(alpha: 0.6),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: IvoryColors.gold, width: 1.8),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: IvoryColors.burgundy,
        selectedItemColor: IvoryColors.gold,
        unselectedItemColor: IvoryColors.peach,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: IvoryColors.plum,
        contentTextStyle: TextStyle(color: IvoryColors.ivory),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
