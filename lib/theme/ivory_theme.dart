import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ============================================================
/// IVORY DESIGN SYSTEM - v2, "Golden Edition"
///
/// Light, warm and editorial: cream pages, near-white cards with
/// hairline gold borders, serif headlines, gold-to-amber gradients.
///
/// STRICT RULE: there is no black, dark grey or charcoal anywhere in
/// this file. The darkest tone permitted is Deep Burgundy #4A0E17, and
/// even shadows are burgundy-tinted.
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

class IvoryTheme {
  IvoryTheme._();

  /// Serif display family. 'serif' resolves to the device's built-in
  /// serif (Noto Serif on Android), so the editorial look costs nothing
  /// in download size and needs no font files in the repo.
  static const String displayFont = 'serif';

  /// Soft warm shadow. Burgundy at low opacity instead of black, so the
  /// strict no-black policy is respected even in elevation.
  static List<BoxShadow> softShadow({double blur = 18, double y = 8}) {
    return <BoxShadow>[
      BoxShadow(
        color: IvoryColors.burgundy.withValues(alpha: 0.10),
        blurRadius: blur,
        offset: Offset(0, y),
      ),
    ];
  }

  /// Standard card decoration used across every screen.
  static BoxDecoration card({
    bool highlighted = false,
    double radius = 20,
  }) {
    return BoxDecoration(
      gradient: IvoryColors.cardGradient,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: highlighted ? IvoryColors.gold : IvoryColors.hairline,
        width: highlighted ? 1.6 : 1,
      ),
      boxShadow: softShadow(blur: highlighted ? 20 : 12, y: highlighted ? 8 : 5),
    );
  }

  static ThemeData light() {
    final ColorScheme scheme = const ColorScheme.light().copyWith(
      primary: IvoryColors.burgundy,
      onPrimary: IvoryColors.ivory,
      secondary: IvoryColors.amber,
      onSecondary: IvoryColors.burgundy,
      surface: IvoryColors.surface,
      onSurface: IvoryColors.burgundy,
      error: IvoryColors.danger,
      onError: IvoryColors.ivory,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: IvoryColors.ivory,
      canvasColor: IvoryColors.ivory,
      shadowColor: IvoryColors.burgundy.withValues(alpha: 0.12),
      splashColor: IvoryColors.peach.withValues(alpha: 0.16),
      highlightColor: IvoryColors.amber.withValues(alpha: 0.10),
      dividerTheme: DividerThemeData(
        color: IvoryColors.hairline,
        thickness: 1,
        space: 24,
      ),

      // A light, papery header with a burgundy wordmark.
      appBarTheme: AppBarTheme(
        backgroundColor: IvoryColors.surface,
        foregroundColor: IvoryColors.burgundy,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontFamily: displayFont,
          color: IvoryColors.burgundy,
          fontSize: 21,
          fontWeight: FontWeight.w700,
          letterSpacing: 4.5,
        ),
        iconTheme: const IconThemeData(color: IvoryColors.burgundy),
        actionsIconTheme: const IconThemeData(color: IvoryColors.burgundy),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: IvoryColors.surface,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        shape: Border(
          bottom: BorderSide(color: IvoryColors.hairline, width: 1),
        ),
      ),

      cardTheme: CardThemeData(
        color: IvoryColors.surface,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: IvoryColors.hairline),
        ),
      ),

      textTheme: TextTheme(
        displayLarge: const TextStyle(
          fontFamily: displayFont,
          color: IvoryColors.burgundy,
          fontSize: 38,
          fontWeight: FontWeight.w700,
          letterSpacing: 7,
        ),
        headlineLarge: const TextStyle(
          fontFamily: displayFont,
          color: IvoryColors.burgundy,
          fontSize: 29,
          height: 1.22,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: const TextStyle(
          fontFamily: displayFont,
          color: IvoryColors.burgundy,
          fontSize: 23,
          height: 1.25,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: const TextStyle(
          fontFamily: displayFont,
          color: IvoryColors.burgundy,
          fontSize: 19,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: const TextStyle(
          color: IvoryColors.burgundy,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: IvoryColors.textSoft,
          fontSize: 15.5,
          height: 1.58,
        ),
        bodyMedium: TextStyle(
          color: IvoryColors.textSoft,
          fontSize: 14,
          height: 1.55,
        ),
        labelLarge: const TextStyle(
          color: IvoryColors.burgundy,
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: IvoryColors.amber,
          foregroundColor: IvoryColors.burgundy,
          disabledBackgroundColor: IvoryColors.surfaceWarm,
          disabledForegroundColor: IvoryColors.textFaint,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.7,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: IvoryColors.burgundy,
          backgroundColor: IvoryColors.surface,
          side: BorderSide(color: IvoryColors.hairlineStrong, width: 1.3),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: IvoryColors.plum,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: IvoryColors.surface,
        selectedColor: IvoryColors.amber,
        side: BorderSide(color: IvoryColors.hairlineStrong),
        labelStyle: const TextStyle(
          color: IvoryColors.burgundy,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: IvoryColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        hintStyle: TextStyle(color: IvoryColors.textFaint, fontSize: 14),
        labelStyle: TextStyle(color: IvoryColors.textSoft),
        prefixIconColor: IvoryColors.plum,
        suffixIconColor: IvoryColors.plum,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: IvoryColors.hairlineStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: IvoryColors.gold, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: IvoryColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: IvoryColors.danger, width: 1.6),
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: IvoryColors.surface,
        selectedItemColor: IvoryColors.burgundy,
        unselectedItemColor: IvoryColors.burgundy.withValues(alpha: 0.42),
        selectedLabelStyle:
            const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        elevation: 0,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: IvoryColors.burgundy,
        contentTextStyle: const TextStyle(color: IvoryColors.cream),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),

      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: IvoryColors.amber),
    );
  }
}

/// The signature Ivory button: a gold-to-amber gradient pill with
/// burgundy lettering. Flutter's ElevatedButton cannot take a gradient,
/// so this small widget does it properly.
class IvoryGradientButton extends StatelessWidget {
  const IvoryGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
    this.busy = false,
    this.gradient,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;
  final bool busy;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null && !busy;
    final Widget content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (busy)
          const SizedBox(
            width: 17,
            height: 17,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: IvoryColors.burgundy,
            ),
          )
        else if (icon != null)
          Icon(icon, size: 19, color: IvoryColors.burgundy),
        if (busy || icon != null) const SizedBox(width: 9),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: IvoryColors.burgundy,
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
        ),
      ],
    );

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: enabled ? onPressed : null,
          child: Ink(
            decoration: BoxDecoration(
              gradient: gradient ?? IvoryColors.goldGradient,
              borderRadius: BorderRadius.circular(30),
              boxShadow: IvoryTheme.softShadow(blur: 12, y: 5),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

/// Small uppercase eyebrow label used above every section.
class IvoryEyebrow extends StatelessWidget {
  const IvoryEyebrow(this.text, {super.key, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        if (icon != null) ...<Widget>[
          Icon(icon, size: 15, color: IvoryColors.amber),
          const SizedBox(width: 7),
        ],
        Text(
          text.toUpperCase(),
          style: const TextStyle(
            color: IvoryColors.plum,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.4,
          ),
        ),
      ],
    );
  }
}

/// Section heading with an optional trailing action, like the
/// "Editor's Golden Reserve · Featured Drop" rows.
class IvorySectionHeader extends StatelessWidget {
  const IvorySectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    if (icon != null) ...<Widget>[
                      Icon(icon, size: 19, color: IvoryColors.amber),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                  ],
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
                      color: IvoryColors.textSoft,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    actionLabel!,
                    style: const TextStyle(
                      color: IvoryColors.plum,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(Icons.arrow_forward, size: 15),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
