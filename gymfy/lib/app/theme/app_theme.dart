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

/// Hyper's material, in the four surfaces the design draws.
///
/// Every number here is a measured value from the design rather than a guess
/// that looked about right, which is why they are odd: 11.5% white at the top
/// of a card, 5.2% through the middle, 7.5% at the foot. A flat tint anywhere
/// in the middle of that range reads as plastic — the dip and the recovery are
/// what the eye takes as thickness.
///
/// Cool white throughout rather than the accent: tinting the glass itself with
/// the accent made every pane the same hue as the thing it contained, and the
/// accent stopped meaning "this matters".
const _hyperGlass = GlassStyle(
  enabled: true,

  // Cards and panels. No blur: nothing sits behind a card but the backdrop's
  // own colour field, and blurring a smooth field returns the same field.
  raised: GlassPane(
    fill: [Color(0x2BFFFFFF), Color(0x17FFFFFF), Color(0x1FFFFFFF)],
    stops: [0, 0.46, 1],
    edge: Color(0x1FFFFFFF),
    topEdge: Color(0x59FFFFFF),
    // Tight and almost black. Not a drop shadow in the Material sense — a card
    // this translucent has no business casting one — but a darkening directly
    // under the pane, which is what stops it looking painted onto the field.
    shadow: [
      BoxShadow(
        color: Color(0xE6000000),
        blurRadius: 30,
        spreadRadius: -16,
        offset: Offset(0, 2),
      ),
    ],
  ),

  // Rows. Two thirds of a card's fill and no shadow, so a list of them recedes
  // and the one card on the screen is still the thing you look at first.
  quiet: GlassPane(
    fill: [Color(0x1FFFFFFF), Color(0x10FFFFFF), Color(0x17FFFFFF)],
    stops: [0, 0.52, 1],
    edge: Color(0x1AFFFFFF),
    topEdge: Color(0x42FFFFFF),
  ),

  // The navigation pill and the app bar's scrim. The opaque floor is what makes
  // this readable with a list running underneath: blur alone averages the text
  // below into a grey haze that is still, faintly, text.
  bar: GlassPane(
    fill: [Color(0x1DFFFFFF), Color(0x0AFFFFFF), Color(0x13FFFFFF)],
    stops: [0, 0.48, 1],
    base: Color(0xAD0B0B15),
    edge: Color(0x1AFFFFFF),
    topEdge: Color(0x52FFFFFF),
    blur: 30,
    shadow: [
      BoxShadow(
        color: Color(0xF2000000),
        blurRadius: 40,
        spreadRadius: -20,
        offset: Offset(0, 20),
      ),
    ],
  ),

  // Sheets and dialogs. The one surface with a colour of its own — a cool
  // violet-grey rather than white over the field — because it covers the whole
  // screen and would otherwise read as the screen having simply got brighter.
  sheet: GlassPane(
    fill: [Color(0xCC26243E), Color(0xCC121220), Color(0xD60F0F1B)],
    stops: [0, 0.38, 1],
    edge: Color(0x1FFFFFFF),
    topEdge: Color(0x52FFFFFF),
    blur: 36,
    shadow: [
      BoxShadow(
        color: Color(0xF2000000),
        blurRadius: 70,
        spreadRadius: -26,
        offset: Offset(0, -28),
      ),
    ],
  ),

  scrim: Color(0xFF07070F),

  // See GlassStyle.saturation. Blur pulls colour towards grey; this puts back
  // what the average took out, and is the difference between the orbs reading
  // through a pane and the pane looking like frosted plastic.
  saturation: 1.85,
  brightness: 1.08,
);

/// Hyper's type scale.
///
/// Eleven sizes, and the gaps between them are the point: 11, 12.5, 13, 15, 17,
/// 19, 26, 34. Material's own scale is built for a page of prose and steps
/// gently; this one steps hard, because every screen here is a number you read
/// at a glance with something in your other hand, and a hierarchy you have to
/// squint at is not a hierarchy.
///
/// Two rules run through it:
///
/// Large text is tracked **in**. At 26px and up, default spacing reads as gappy
/// and the number stops being one object — so it tightens as it grows, up to
/// -0.6 at 34.
///
/// Small caps are tracked **out**, hard: 11px at +1.1 is the label style the
/// whole design leans on for "WEDNESDAY", "UP NEXT", "STEP 1 — WEIGHT". At that
/// size, letterspacing is what separates a label from just another small line.
///
/// Only Hyper gets this. The six flat themes keep Material's defaults, which is
/// what they have always drawn.
TextTheme _hyperText(AppPalette palette) {
  TextStyle style(
    double size,
    FontWeight weight, {
    double? tracking,
    double height = 1.25,
    Color? colour,
  }) => TextStyle(
    fontSize: size,
    fontWeight: weight,
    letterSpacing: tracking,
    height: height,
    color: colour ?? palette.textPrimary,
  );

  return TextTheme(
    // The numbers a screen is built around: a volume total, a countdown.
    displayLarge: style(66, FontWeight.w600, tracking: -2.5, height: 1),
    displayMedium: style(38, FontWeight.w600, tracking: -1, height: 1.05),
    displaySmall: style(34, FontWeight.w600, tracking: -0.8, height: 1.05),

    headlineLarge: style(34, FontWeight.w600, tracking: -0.6, height: 1.1),
    // The day name on Home — the largest thing that is a word rather than a
    // figure.
    headlineMedium: style(32, FontWeight.w600, tracking: -0.5, height: 1.1),
    headlineSmall: style(28, FontWeight.w600, tracking: -0.4, height: 1.15),

    // A screen's own name: the exercise on its detail page.
    titleLarge: style(26, FontWeight.w600, tracking: -0.4, height: 1.15),
    // A card's heading, and the app bar's title.
    titleMedium: style(19, FontWeight.w600, tracking: -0.2),
    // A section heading over a run of cards.
    titleSmall: style(17, FontWeight.w600),

    // Rows: the name of a thing in a list.
    bodyLarge: style(16, FontWeight.w400, height: 1.35),
    bodyMedium: style(15, FontWeight.w400, height: 1.35),
    // Everything secondary — the line under a title, a date, a target.
    bodySmall: style(
      13,
      FontWeight.w400,
      height: 1.4,
      colour: palette.textMuted,
    ),

    // Buttons.
    labelLarge: style(14.5, FontWeight.w600),
    labelMedium: style(
      12.5,
      FontWeight.w400,
      height: 1.35,
      colour: palette.textMuted,
    ),
    // The tracked caps label. See above — this one carries a lot of the design.
    labelSmall: style(
      11,
      FontWeight.w600,
      tracking: 1.1,
      colour: palette.textMuted,
    ),
  );
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
  final glass = theme == AppTheme.hyper ? _hyperGlass : const GlassStyle.off();

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    extensions: [glass],

    // Hyper's typeface, and Hyper's alone. A grotesque with tight apertures and
    // a near-square figure set — it holds up at 11px tracked caps and at a
    // 38px timer, which is the range this app actually asks of a face.
    //
    // Null everywhere else, which means Roboto: the six flat themes are meant
    // to come out of the redesign unchanged, and a typeface is not a detail
    // that can be changed quietly.
    fontFamily: glass.enabled ? 'Schibsted Grotesk' : null,
    textTheme: glass.enabled ? _hyperText(palette) : null,
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
      // Material 3 gives the bar `titleLarge`, which in this scale is the 26px
      // a screen's own subject gets. A title is a label for where you are, not
      // the thing you came to read — the design sets it at 19.
      titleTextStyle: glass.enabled
          ? _hyperText(
              palette,
            ).titleMedium?.copyWith(fontFamily: 'Schibsted Grotesk')
          : null,
    ),
    dividerTheme: DividerThemeData(
      color: palette.outline,
      thickness: theme == AppTheme.highContrast ? 1.5 : 1,
    ),

    cardTheme: CardThemeData(
      color: palette.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        // Hyper's panes are rounder than a flat card. A translucent surface is
        // read by its edge rather than by its fill, and at 16 that edge reads
        // as a box with softened corners rather than as something moulded.
        borderRadius: BorderRadius.circular(glass.enabled ? 24 : 16),
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
