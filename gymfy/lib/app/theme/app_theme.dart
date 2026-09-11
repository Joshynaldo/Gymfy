import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/data/settings_repository.dart';
import 'glass.dart';
import 'motion.dart';

/// Central definition of Gymfy's look-and-feel.
///
/// Design rules (see CLAUDE.md):
/// - Dark mode first.
/// - A single user-chosen accent colour drives CTAs, highlights and active
///   states. The *theme* chooses the greys behind it; the two are independent,
///   so any accent works with any theme.
/// - Flat surfaces, subtle contrast, no heavy gradients.
///
/// NOTE: Raw hex colours are allowed *here* — this file IS the theme
/// definition. Widgets must never hardcode hex; they read colours from the
/// theme (or from the accent provider). The one deliberate exception is
/// competition plate colours, which are physical facts rather than styling.

/// The greys behind the accent, for one theme.
class AppPalette {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.textPrimary,
    required this.textMuted,
    required this.outline,
  });

  final Color background;

  /// Cards and sheets.
  final Color surface;

  /// Elements sitting on a surface.
  final Color surfaceHigh;

  final Color textPrimary;
  final Color textMuted;

  /// Borders and dividers. Carries most of the weight in the high-contrast
  /// theme, where edges do the work that colour differences do elsewhere.
  final Color outline;
}

/// The themes a user can pick from.
///
/// All dark: the app is dark-mode-first, and a light theme is a separate design
/// job rather than an inverted copy of this one. Not shipped rather than shipped
/// badly.
enum AppTheme {
  /// The original. Near-black with lifted grey cards.
  darkDefault(
    'Dark',
    'Near-black with soft grey cards.',
    AppPalette(
      background: Color(0xFF0E0F12),
      surface: Color(0xFF17181C),
      surfaceHigh: Color(0xFF202228),
      textPrimary: Color(0xFFF4F5F7),
      textMuted: Color(0xFF9A9DA6),
      outline: Color(0xFF2C2F36),
    ),
  ),

  /// True black. On an OLED screen a black pixel is an *off* pixel, so this is
  /// the one that actually saves battery — and it's why the surfaces are barely
  /// lifted: lighting them up would defeat the point.
  amoled(
    'AMOLED black',
    'True black. Saves power on OLED screens.',
    AppPalette(
      background: Color(0xFF000000),
      surface: Color(0xFF000000),
      surfaceHigh: Color(0xFF0D0D0D),
      textPrimary: Color(0xFFF4F5F7),
      textMuted: Color(0xFF8E9199),
      // Cards are the same colour as the background here, so their border is
      // the only thing that makes them cards.
      outline: Color(0xFF33363D),
    ),
  ),

  /// Maximum legibility: white text, much brighter secondary text, and visible
  /// borders everywhere. For bright gyms and for anyone who finds the default's
  /// muted grey hard to read.
  highContrast(
    'High contrast',
    'Brighter text and visible borders.',
    AppPalette(
      background: Color(0xFF000000),
      surface: Color(0xFF16181D),
      surfaceHigh: Color(0xFF23262D),
      textPrimary: Color(0xFFFFFFFF),
      textMuted: Color(0xFFD6D9E0),
      outline: Color(0xFF6B6F78),
    ),
  ),

  // The four below are the well-known editor palettes, using each project's own
  // published background/surface/foreground values rather than an approximation
  // — half-remembered Dracula is just purple-ish grey, and people who choose
  // these know what they should look like.
  //
  // Each also carries a `suggestedAccent`: these palettes are designed around a
  // particular set of hues, and the app's default blue fights most of them. The
  // picker offers to switch the accent to match; it doesn't do it silently.

  /// Tokyo Night — the "storm" variant, which is the one most people mean.
  tokyoNight(
    'Tokyo Night',
    'Deep blue-grey with a soft indigo cast.',
    AppPalette(
      background: Color(0xFF1A1B26),
      surface: Color(0xFF24283B),
      surfaceHigh: Color(0xFF2F3549),
      textPrimary: Color(0xFFC0CAF5),
      textMuted: Color(0xFF787C99),
      outline: Color(0xFF3B4261),
    ),
    suggestedAccent: Color(0xFF7AA2F7),
  ),

  /// Dracula — the canonical background/current-line/foreground.
  dracula(
    'Dracula',
    'Dark violet with high-saturation accents.',
    AppPalette(
      background: Color(0xFF282A36),
      surface: Color(0xFF343746),
      surfaceHigh: Color(0xFF44475A),
      textPrimary: Color(0xFFF8F8F2),
      textMuted: Color(0xFF9CA0B0),
      outline: Color(0xFF4D5066),
    ),
    suggestedAccent: Color(0xFFBD93F9),
  ),

  /// Catppuccin Mocha — the darkest of the four Catppuccin flavours.
  catppuccinMocha(
    'Catppuccin Mocha',
    'Warm, muted pastels on deep charcoal.',
    AppPalette(
      background: Color(0xFF1E1E2E),
      surface: Color(0xFF262637),
      surfaceHigh: Color(0xFF313244),
      textPrimary: Color(0xFFCDD6F4),
      textMuted: Color(0xFF9399B2),
      outline: Color(0xFF45475A),
    ),
    suggestedAccent: Color(0xFFCBA6F7),
  ),

  /// Gruvbox Dark — the warm, low-contrast one.
  gruvbox(
    'Gruvbox',
    'Warm retro browns and greens.',
    AppPalette(
      background: Color(0xFF282828),
      surface: Color(0xFF32302F),
      surfaceHigh: Color(0xFF3C3836),
      textPrimary: Color(0xFFEBDBB2),
      textMuted: Color(0xFFA89984),
      outline: Color(0xFF504945),
    ),
    suggestedAccent: Color(0xFFFABD2F),
  ),

  /// Hyper — the glass one, and the only theme that is a *construction* rather
  /// than a palette.
  ///
  /// Everything else here recolours flat opaque cards. This one makes every
  /// surface translucent and blurs what is behind it, which only works because
  /// there is something behind it to blur: the app paints a slow atmospheric
  /// field under the whole screen (see `HyperBackdrop`). Glass over a flat
  /// black background is just a slightly different grey — the backdrop is not
  /// decoration, it is the half of the effect that makes the other half read.
  ///
  /// The palette is deep indigo rather than neutral so the blur has colour to
  /// pick up, and the surfaces are near-transparent because the tint is doing
  /// the work the fill used to do.
  hyper(
    'Hyper',
    'Translucent glass over a living backdrop.',
    AppPalette(
      background: Color(0xFF07070F),
      // Barely there: on this theme the real surface is the tint in
      // [GlassStyle], and an opaque fill here would paint over the blur.
      surface: Color(0xFF12121E),
      surfaceHigh: Color(0xFF1B1B2C),
      textPrimary: Color(0xFFF2F3FA),
      textMuted: Color(0xFF9EA0BC),
      outline: Color(0xFF2B2C45),
    ),
    suggestedAccent: Color(0xFF7C6BFF),
  );

  const AppTheme(
    this.label,
    this.description,
    this.palette, {
    this.suggestedAccent,
  });

  /// Shown in the settings picker.
  final String label;
  final String description;
  final AppPalette palette;

  /// The accent this palette was designed around, for themes that have one.
  ///
  /// Offered, never applied on its own: someone who picked orange picked it on
  /// purpose, and a theme quietly changing it would be the app overruling them.
  /// Null for the three house themes, which are accent-agnostic by design.
  final Color? suggestedAccent;

  /// Parses a stored value, falling back to the default.
  ///
  /// An unreadable setting means showing the default theme, never failing to
  /// build one — the worst case is the user picking again.
  static AppTheme parse(String? raw) {
    return AppTheme.values.firstWhere(
      (theme) => theme.name == raw,
      orElse: () => AppTheme.darkDefault,
    );
  }
}

/// Setting key for the chosen theme.
const appThemeSetting = 'app_theme';

/// The theme as stored on disk; null while the first read is in flight.
final storedAppThemeProvider = StreamProvider<AppTheme?>((ref) {
  return ref
      .watch(settingsRepositoryProvider)
      .watchRaw(appThemeSetting)
      .map((raw) => raw == null ? null : AppTheme.parse(raw));
});

/// The theme in use. Backed by the settings table, so it survives a restart.
///
/// Like the accent, there is no in-memory copy: [setAppTheme] only writes, and
/// the new value arrives back through [storedAppThemeProvider]. The stored and
/// displayed values cannot drift apart, and the picker needs no state.
final appThemeProvider = Provider<AppTheme>((ref) {
  return ref.watch(storedAppThemeProvider).value ?? AppTheme.darkDefault;
});

/// Stores a theme choice, from a widget. Mirrors `setWeightUnit` in units.dart.
Future<void> setAppTheme(WidgetRef ref, AppTheme theme) {
  return ref
      .read(settingsRepositoryProvider)
      .write(appThemeSetting, theme.name);
}

/// Builds the [ThemeData] for [theme], tinted by [accent].
///
/// Called from `main.dart` whenever either changes.
ThemeData buildAppTheme(AppTheme theme, Color accent) {
  final palette = theme.palette;
  // Seed a Material 3 dark scheme from the accent, then pin the key roles so
  // the accent stays crisp and the palette's greys aren't overridden by the
  // scheme's generated ones.
  final scheme =
      ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.dark,
      ).copyWith(
        primary: accent,
        surface: palette.surface,
        onSurface: palette.textPrimary,
        onSurfaceVariant: palette.textMuted,
        surfaceContainerHighest: palette.surfaceHigh,
        outline: palette.outline,
        outlineVariant: palette.outline,
      );

  // Derived rather than listed per theme, so a new palette can't accidentally
  // ship invisible cards. A card needs an outline when it doesn't stand out
  // from the background on its own — AMOLED's surface IS the background — and
  // high contrast wants a heavier one, since there edges do the work that
  // colour differences do elsewhere.
  final surfaceIsFlat =
      (palette.surface.computeLuminance() -
              palette.background.computeLuminance())
          .abs() <
      0.01;
  final cardBorder = switch (theme) {
    AppTheme.highContrast => BorderSide(color: palette.outline, width: 1.5),
    _ when surfaceIsFlat => BorderSide(color: palette.outline),
    _ => BorderSide.none,
  };

  // Hyper is the only theme whose surfaces are a material rather than a fill.
  // Carried on the ThemeData so widgets ask "how does a surface look here"
  // instead of testing which theme is on.
  final glass = theme == AppTheme.hyper
      ? GlassStyle(
          enabled: true,
          // Enough that what shows through is colour and movement, never
          // legible content. A surface you can read the screen through is a
          // window, not a material.
          blur: 24,
          // Cool white at low alpha rather than the accent: tinting the glass
          // itself with the accent made every pane the same hue as the thing
          // it contained, and the accent stopped meaning "this matters".
          tint: const Color(0x14FFFFFF),
          highlight: const Color(0x2EFFFFFF),
          edge: const Color(0x24FFFFFF),
        )
      : const GlassStyle.off();

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    extensions: [glass],
    // Transparent on a glass theme so the backdrop painted underneath shows
    // through every scaffold; opaque everywhere else, as before.
    scaffoldBackgroundColor: glass.enabled
        ? Colors.transparent
        : palette.background,
    canvasColor: palette.background,

    // Every pushed screen in the app, in one line. go_router builds Material
    // pages, Material pages ask the theme how to transition, so this reaches
    // routes that no longer have to know anything about it.
    //
    // iOS and macOS are left on Cupertino's own transition on purpose: that
    // builder is also what installs the swipe-from-the-left-edge back gesture,
    // and replacing it would trade a nicer animation for a navigation gesture
    // every iPhone user has in their hands.
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: GymfyPageTransitionsBuilder(),
        TargetPlatform.linux: GymfyPageTransitionsBuilder(),
        TargetPlatform.windows: GymfyPageTransitionsBuilder(),
        TargetPlatform.fuchsia: GymfyPageTransitionsBuilder(),
      },
    ),

    // Flat app bar, no shadow line.
    appBarTheme: AppBarTheme(
      backgroundColor: palette.background,
      foregroundColor: palette.textPrimary,
      elevation: 0,
      centerTitle: false,
    ),

    dividerTheme: DividerThemeData(
      color: palette.outline,
      thickness: theme == AppTheme.highContrast ? 1.5 : 1,
    ),

    cardTheme: CardThemeData(
      color: palette.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: cardBorder,
      ),
      margin: EdgeInsets.zero,
    ),

    // Bottom navigation: the accent drives the active state.
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: palette.surface,
      indicatorColor: accent.withValues(alpha: 0.20),
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: selected ? accent : palette.textMuted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(color: selected ? accent : palette.textMuted);
      }),
    ),

    // Filled buttons = primary CTAs, tinted by the accent.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: onAccent(accent),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}

/// Picks black or white for content sitting *on top of* the accent, based on
/// how bright the accent is — keeps CTAs readable for any accent choice.
Color onAccent(Color accent) {
  return accent.computeLuminance() > 0.5 ? Colors.black : Colors.white;
}
