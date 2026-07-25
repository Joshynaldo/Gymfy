import 'package:flutter/material.dart';

/// Central definition of Gymfy's look-and-feel.
///
/// Design rules (see CLAUDE.md):
/// - Dark mode first.
/// - A single user-chosen [accent] colour drives CTAs, highlights and
///   active states.
/// - Flat surfaces, subtle contrast, no heavy gradients.
///
/// NOTE: Raw hex colours are allowed *here* — this file IS the theme
/// definition. Widgets must never hardcode hex; they read colours from the
/// theme (or from the accent provider).
class AppColors {
  const AppColors._();

  /// Near-black app background — flat and easy on the eyes.
  static const Color background = Color(0xFF0E0F12);

  /// Slightly lifted surface for cards / sheets.
  static const Color surface = Color(0xFF17181C);

  /// A touch lighter again, for elements sitting on a surface.
  static const Color surfaceHigh = Color(0xFF202228);

  /// Primary text.
  static const Color textPrimary = Color(0xFFF4F5F7);

  /// Muted / secondary text.
  static const Color textMuted = Color(0xFF9A9DA6);
}

/// Builds the dark [ThemeData] for the whole app, tinted by [accent].
///
/// Called from `main.dart` whenever the accent colour changes.
ThemeData buildDarkTheme(Color accent) {
  // Seed a Material 3 dark scheme from the accent, then pin the key roles so
  // the accent stays crisp on buttons and active states.
  final scheme = ColorScheme.fromSeed(
    seedColor: accent,
    brightness: Brightness.dark,
  ).copyWith(
    primary: accent,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    canvasColor: AppColors.background,

    // Flat app bar, no shadow line.
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: false,
    ),

    // Flat cards with a subtle surface, no elevation tint.
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
    ),

    // Bottom navigation: the accent drives the active state.
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: accent.withValues(alpha: 0.20),
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: selected ? accent : AppColors.textMuted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(color: selected ? accent : AppColors.textMuted);
      }),
    ),

    // Filled buttons = primary CTAs, tinted by the accent.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: _onAccent(accent),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}

/// Picks black or white for content sitting *on top of* the accent, based on
/// how bright the accent is — keeps CTAs readable for any accent choice.
Color _onAccent(Color accent) {
  return accent.computeLuminance() > 0.5 ? Colors.black : Colors.white;
}
