// The theme system: what each variant promises, and that the accent and the
// theme stay independent of each other.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/app/theme/accent_color.dart';
import 'package:gymfy/app/theme/app_theme.dart';
import 'package:gymfy/shared/data/settings_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';

void main() {
  group('AppTheme.parse', () {
    test('reads back what it writes', () {
      for (final theme in AppTheme.values) {
        expect(AppTheme.parse(theme.name), theme);
      }
    });

    test('an unset or unreadable value falls back to the default', () {
      // The worst case is the user picking again — never a screen that can't
      // build a theme.
      expect(AppTheme.parse(null), AppTheme.darkDefault);
      expect(AppTheme.parse('neon'), AppTheme.darkDefault);
      expect(AppTheme.parse(''), AppTheme.darkDefault);
    });
  });

  group('palettes', () {
    test('every theme is dark', () {
      // Dark-mode-first is a design rule, not a default — a light theme would
      // be a separate design job rather than an inverted copy.
      for (final theme in AppTheme.values) {
        expect(
          theme.palette.background.computeLuminance(),
          lessThan(0.2),
          reason: theme.name,
        );
      }
    });

    test('text is always readable against its surface', () {
      // Not a full WCAG check — just a guard against a palette edit that makes
      // primary text disappear into the cards it sits on.
      for (final theme in AppTheme.values) {
        final text = theme.palette.textPrimary.computeLuminance();
        final surface = theme.palette.surface.computeLuminance();
        expect((text - surface).abs(), greaterThan(0.5), reason: theme.name);
      }
    });

    test('AMOLED is genuinely black, not just dark', () {
      // The whole point: on OLED a black pixel is an off pixel. A near-black
      // would light every one of them and save nothing.
      expect(AppTheme.amoled.palette.background, const Color(0xFF000000));
      expect(AppTheme.amoled.palette.surface, const Color(0xFF000000));
    });

    test('the editor themes use their own published colours', () {
      // Spot-checked against each project's palette. Half-remembered Dracula is
      // just purple-ish grey, and people who pick these know what they should
      // look like.
      expect(AppTheme.tokyoNight.palette.background, const Color(0xFF1A1B26));
      expect(AppTheme.dracula.palette.background, const Color(0xFF282A36));
      expect(
        AppTheme.catppuccinMocha.palette.background,
        const Color(0xFF1E1E2E),
      );
      expect(AppTheme.gruvbox.palette.background, const Color(0xFF282828));
    });

    test('only the editor themes suggest an accent', () {
      // The three house themes are accent-agnostic by design; the borrowed
      // palettes were each built around a particular hue.
      for (final theme in [
        AppTheme.darkDefault,
        AppTheme.amoled,
        AppTheme.highContrast,
      ]) {
        expect(theme.suggestedAccent, isNull, reason: theme.name);
      }
      for (final theme in [
        AppTheme.tokyoNight,
        AppTheme.dracula,
        AppTheme.catppuccinMocha,
        AppTheme.gruvbox,
      ]) {
        expect(theme.suggestedAccent, isNotNull, reason: theme.name);
      }
    });

    test('every suggested accent survives a round-trip', () {
      // They aren't in AccentPalette.options, so without widening the parser a
      // theme's own accent would be stored and then silently read back as the
      // default blue.
      for (final theme in AppTheme.values) {
        final accent = theme.suggestedAccent;
        if (accent == null) continue;
        expect(
          parseAccentColor(accent.toARGB32().toString()),
          accent,
          reason: theme.name,
        );
      }
    });

    test('a suggested accent is readable on its own theme', () {
      for (final theme in AppTheme.values) {
        final accent = theme.suggestedAccent;
        if (accent == null) continue;
        final gap =
            (accent.computeLuminance() -
                    theme.palette.surface.computeLuminance())
                .abs();
        expect(gap, greaterThan(0.15), reason: theme.name);
      }
    });

    test('high contrast really is higher contrast', () {
      final normal = AppTheme.darkDefault.palette;
      final high = AppTheme.highContrast.palette;

      // Muted text is where the default is hardest to read, so that's the
      // number that has to move.
      expect(
        high.textMuted.computeLuminance(),
        greaterThan(normal.textMuted.computeLuminance()),
      );
      expect(
        high.outline.computeLuminance(),
        greaterThan(normal.outline.computeLuminance()),
      );
    });
  });

  group('buildAppTheme', () {
    test('uses the palette rather than the seeded scheme greys', () {
      for (final theme in AppTheme.values) {
        final data = buildAppTheme(theme, AccentPalette.blue);

        expect(data.scaffoldBackgroundColor, theme.palette.background);
        expect(data.colorScheme.surface, theme.palette.surface);
        expect(data.colorScheme.onSurface, theme.palette.textPrimary);
        expect(data.colorScheme.onSurfaceVariant, theme.palette.textMuted);
      }
    });

    test('the accent survives every theme', () {
      // Theme and accent are independent: any accent has to work with any set
      // of greys, or the two pickers would have to know about each other.
      for (final theme in AppTheme.values) {
        for (final accent in AccentPalette.options) {
          final data = buildAppTheme(theme, accent);
          expect(data.colorScheme.primary, accent, reason: theme.name);
        }
      }
    });

    test('AMOLED and high contrast give cards a border', () {
      // AMOLED needs one because its cards match the background exactly;
      // without it a card would be invisible.
      for (final theme in [AppTheme.amoled, AppTheme.highContrast]) {
        final shape = buildAppTheme(theme, AccentPalette.blue).cardTheme.shape;
        expect(
          (shape! as RoundedRectangleBorder).side.style,
          BorderStyle.solid,
          reason: theme.name,
        );
      }
    });

    test('a card is never invisible against its own background', () {
      // The border is derived from the palette rather than listed per theme, so
      // this holds for any future one too: either the surface stands out on its
      // own, or it gets an outline.
      for (final theme in AppTheme.values) {
        final data = buildAppTheme(theme, AccentPalette.blue);
        final shape = data.cardTheme.shape! as RoundedRectangleBorder;
        final standsOut =
            (theme.palette.surface.computeLuminance() -
                    theme.palette.background.computeLuminance())
                .abs() >
            0.01;
        expect(
          standsOut || shape.side.style == BorderStyle.solid,
          isTrue,
          reason: theme.name,
        );
      }
    });

    test('every theme is marked dark for Flutter too', () {
      for (final theme in AppTheme.values) {
        final data = buildAppTheme(theme, AccentPalette.blue);
        expect(data.brightness, Brightness.dark);
        expect(data.colorScheme.brightness, Brightness.dark);
      }
    });
  });

  group('onAccent', () {
    test('picks a readable foreground for any accent', () {
      // A CTA label has to stay legible whichever accent is chosen.
      for (final accent in AccentPalette.options) {
        final foreground = onAccent(accent);
        expect(
          (foreground.computeLuminance() - accent.computeLuminance()).abs(),
          greaterThan(0.3),
        );
      }
    });
  });

  group('the stored preference', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    Future<void> settle() async {
      container.listen(appThemeProvider, (_, _) {});
      await container.read(storedAppThemeProvider.future);
    }

    test('starts on the default', () async {
      await settle();

      expect(container.read(appThemeProvider), AppTheme.darkDefault);
    });

    test('a stored theme is used', () async {
      await container
          .read(settingsRepositoryProvider)
          .write(appThemeSetting, AppTheme.amoled.name);
      await settle();

      expect(container.read(appThemeProvider), AppTheme.amoled);
    });

    test('junk in the setting degrades to the default', () async {
      await container
          .read(settingsRepositoryProvider)
          .write(appThemeSetting, 'neon');
      await settle();

      expect(container.read(appThemeProvider), AppTheme.darkDefault);
    });
  });
}
