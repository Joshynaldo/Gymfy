// The settings screen: what it changes, what it stores, and what it refuses to
// guess when a stored value makes no sense.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/app/theme/accent_color.dart';
import 'package:gymfy/app/theme/app_theme.dart';
import 'package:gymfy/features/onboarding/data/onboarding_repository.dart';
import 'package:gymfy/features/overload/data/overload_preference.dart';
import 'package:gymfy/features/settings/data/notification_preferences.dart';
import 'package:gymfy/features/settings/screens/settings_screen.dart';
import 'package:gymfy/shared/data/settings_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';
import 'package:gymfy/shared/widgets/accent_swatch.dart';
import 'package:gymfy/shared/utils/units.dart';

void main() {
  group('parseFlag', () {
    test('reads the two values it writes', () {
      expect(parseFlag('true', orElse: false), isTrue);
      expect(parseFlag('false', orElse: true), isFalse);
    });

    test('an unset preference takes the default', () {
      expect(parseFlag(null, orElse: true), isTrue);
      expect(parseFlag(null, orElse: false), isFalse);
    });

    test('junk takes the default rather than being guessed at', () {
      // Notably '1' and 'yes' are NOT true: only what we write counts, so a
      // value from some other build can't flip a preference unexpectedly.
      for (final raw in ['', '1', '0', 'yes', 'TRUE']) {
        expect(parseFlag(raw, orElse: true), isTrue, reason: raw);
        expect(parseFlag(raw, orElse: false), isFalse, reason: raw);
      }
    });
  });

  group('SettingsScreen', () {
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

    Future<void> pump(WidgetTester tester) async {
      // A taller-than-default viewport so the whole screen fits without
      // scrolling. The default 800×600 cuts off the rest-timer switches, and
      // scrolling to each control would break again every time a section is
      // added — which is exactly what happened when Units arrived.
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    /// Drains the real async database work that a tap kicks off.
    ///
    /// Inside `testWidgets` the clock is faked, so this has to step outside that
    /// zone via [WidgetTester.runAsync] — a bare `pumpEventQueue()` would block.
    Future<void> settle(WidgetTester tester) async {
      await tester.runAsync(() => pumpEventQueue());
      await tester.pumpAndSettle();
    }

    testWidgets('shows every section', (tester) async {
      await pump(tester);

      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('Accent'), findsOneWidget);
      expect(find.text('Units'), findsOneWidget);
      expect(find.text('Plates'), findsOneWidget);
      expect(find.text('Progressive overload'), findsOneWidget);
      expect(find.text('You'), findsOneWidget);
      expect(find.text('Rest timer'), findsOneWidget);
      expect(find.text('Data'), findsOneWidget);
    });

    testWidgets('the data export is reachable from here', (tester) async {
      await pump(tester);

      // Lives in Settings rather than on the More tab: exporting is a
      // once-before-a-phone-swap job, not a tool you reach for mid-session.
      expect(find.text('Export data'), findsOneWidget);
    });

    testWidgets('progressive overload is configured here, not per exercise', (
      tester,
    ) async {
      await pump(tester);

      // The whole panel, not just an on/off — whether, how much and deload all
      // moved out of the day builder.
      expect(find.text('Suggest heavier weights'), findsOneWidget);
      expect(find.text('How much to add'), findsOneWidget);
      expect(find.text('Deload'), findsOneWidget);
      for (final mode in OverloadMode.values) {
        expect(find.text(mode.label), findsOneWidget, reason: mode.name);
      }
    });

    testWidgets('turning it off hides the options it would configure', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(find.text('Suggest heavier weights'));
      await settle(tester);

      // A greyed-out wall of controls under a switch that's off is worse than
      // no controls at all.
      expect(container.read(overloadConfigProvider).enabled, isFalse);
      expect(find.text('How much to add'), findsNothing);
      expect(find.text('Deload'), findsNothing);
    });

    testWidgets('picking a percentage is applied and stored', (tester) async {
      await pump(tester);

      await tester.tap(find.text(OverloadMode.percent.label));
      await settle(tester);
      await tester.tap(find.text('5%'));
      await settle(tester);

      final config = container.read(overloadConfigProvider);
      expect(config.mode, OverloadMode.percent);
      expect(config.percent, 5);
      expect(config.percentOrNull, 5);
      // Auto and Fixed must not leak through in percent mode.
      expect(config.fixedOrNull, isNull);
    });

    testWidgets('a deload schedule can be set and cleared', (tester) async {
      await pump(tester);

      await tester.tap(find.text('6 in a row'));
      await settle(tester);
      expect(container.read(overloadConfigProvider).deloadWeeks, 6);

      await tester.tap(find.text('Never'));
      await settle(tester);
      // Cleared, not left behind — the config writes every key every time.
      expect(container.read(overloadConfigProvider).deloadWeeks, isNull);
    });

    /// Opens the theme dropdown and picks [theme] from the menu.
    ///
    /// Two taps now the picker is collapsed. `.last` on the menu entry because
    /// the closed field still shows the current theme's name behind the open
    /// menu, so its label matches twice.
    Future<void> pickTheme(WidgetTester tester, AppTheme theme) async {
      await tester.tap(find.byType(DropdownButtonFormField<AppTheme>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(theme.label).last);
      await settle(tester);
    }

    testWidgets('shows the current theme without opening', (tester) async {
      await pump(tester);

      // Collapsed, so only the active one is on screen — that's the point of
      // the dropdown over seven stacked rows.
      expect(find.text(AppTheme.darkDefault.label), findsOneWidget);
      expect(find.text(AppTheme.amoled.label), findsNothing);
      expect(container.read(appThemeProvider), AppTheme.darkDefault);
    });

    testWidgets('offers every theme once opened', (tester) async {
      await pump(tester);

      await tester.tap(find.byType(DropdownButtonFormField<AppTheme>));
      await tester.pumpAndSettle();

      for (final theme in AppTheme.values) {
        expect(find.text(theme.label), findsWidgets, reason: theme.name);
      }
    });

    testWidgets('picking a theme applies and stores it', (tester) async {
      await pump(tester);

      await pickTheme(tester, AppTheme.amoled);

      // Applied app-wide immediately — this screen re-themes under your finger,
      // which is what makes the picker its own preview.
      expect(container.read(appThemeProvider), AppTheme.amoled);
      expect(
        await container.read(settingsRepositoryProvider).readRaw(
          appThemeSetting,
        ),
        AppTheme.amoled.name,
      );
    });

    testWidgets('switching back to the default works too', (tester) async {
      await pump(tester);

      await pickTheme(tester, AppTheme.highContrast);
      await pickTheme(tester, AppTheme.darkDefault);

      expect(container.read(appThemeProvider), AppTheme.darkDefault);
    });

    testWidgets('weights start in kilograms', (tester) async {
      await pump(tester);

      expect(container.read(weightUnitProvider), WeightUnit.kg);
    });

    testWidgets('picking pounds is applied and stored', (tester) async {
      await pump(tester);

      await tester.tap(find.text('lbs'));
      await settle(tester);

      expect(container.read(weightUnitProvider), WeightUnit.lbs);
      expect(
        await container.read(settingsRepositoryProvider).readRaw(
          weightUnitSetting,
        ),
        'lbs',
      );
    });

    testWidgets('switching back to kilograms works too', (tester) async {
      await pump(tester);

      await tester.tap(find.text('lbs'));
      await settle(tester);
      await tester.tap(find.text('kg'));
      await settle(tester);

      expect(container.read(weightUnitProvider), WeightUnit.kg);
    });

    testWidgets('offers one swatch per palette colour', (tester) async {
      await pump(tester);

      expect(
        find.byWidgetPredicate((w) => w is Semantics && w.properties.button == true),
        findsAtLeastNWidgets(AccentPalette.options.length),
      );
    });

    testWidgets('picking a colour applies and stores it', (tester) async {
      await pump(tester);

      final target = AccentPalette.options.firstWhere(
        (c) => c != AccentPalette.defaultAccent,
      );
      // Scoped to AccentSwatch on purpose: the theme rows are selectable too,
      // so a bare "first unselected Semantics" would tap the wrong picker.
      await tester.tap(
        find
            .descendant(
              of: find.byType(AccentSwatch),
              matching: find.byWidgetPredicate(
                (w) => w is Semantics && w.properties.selected == false,
              ),
            )
            .first,
      );
      await settle(tester);

      expect(container.read(accentColorProvider), target);
      expect(
        parseAccentColor(
          await container.read(settingsRepositoryProvider).readRaw(
            accentColorSetting,
          ),
        ),
        target,
      );
    });

    testWidgets('a name that was never set reads as not set', (tester) async {
      await pump(tester);

      // Scoped to the Name row: height and age say "Not set" too, so a bare
      // text finder would pass or fail depending on how many other unanswered
      // profile fields happen to be on the screen.
      expect(
        find.descendant(
          of: find.widgetWithText(ListTile, 'Name'),
          matching: find.text('Not set'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a stored name is shown', (tester) async {
      await container
          .read(settingsRepositoryProvider)
          .write(userNameSetting, 'Joshua');
      await pump(tester);

      expect(find.text('Joshua'), findsOneWidget);
    });

    testWidgets('the name can be changed', (tester) async {
      await pump(tester);

      await tester.tap(find.text('Name'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '  Joshua  ');
      await tester.tap(find.text('Save'));
      await settle(tester);

      // Trimmed on the way in, like onboarding does.
      expect(container.read(userNameProvider).value, 'Joshua');
    });

    testWidgets('saving an empty name removes it', (tester) async {
      await container
          .read(settingsRepositoryProvider)
          .write(userNameSetting, 'Joshua');
      await pump(tester);

      await tester.tap(find.text('Joshua'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '');
      await tester.tap(find.text('Save'));
      await settle(tester);

      expect(container.read(userNameProvider).value, isNull);
    });

    testWidgets('cancelling leaves the name alone', (tester) async {
      await container
          .read(settingsRepositoryProvider)
          .write(userNameSetting, 'Joshua');
      await pump(tester);

      await tester.tap(find.text('Joshua'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Someone else');
      await tester.tap(find.text('Cancel'));
      await settle(tester);

      // Cancelling is not the same as clearing, even with the field edited.
      expect(container.read(userNameProvider).value, 'Joshua');
    });

    testWidgets('rest timer alerts start on', (tester) async {
      await pump(tester);

      expect(container.read(restTimerAlertsProvider).value, isTrue);
      expect(container.read(restTimerVibrateProvider).value, isTrue);
    });

    testWidgets('turning alerts off is stored', (tester) async {
      await pump(tester);

      await tester.tap(find.text('Rest timer notifications'));
      await settle(tester);

      expect(container.read(restTimerAlertsProvider).value, isFalse);
    });

    testWidgets('vibration is disabled while alerts are off', (tester) async {
      await pump(tester);

      await tester.tap(find.text('Rest timer notifications'));
      await settle(tester);

      // Nested under alerts on purpose: with nothing alerting there is nothing
      // to vibrate for, so the switch goes dead rather than silently doing
      // nothing.
      final vibrate = tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, 'Vibrate'),
      );
      expect(vibrate.onChanged, isNull);
    });

    testWidgets('vibration can be turned off on its own', (tester) async {
      await pump(tester);

      await tester.tap(find.text('Vibrate'));
      await settle(tester);

      expect(container.read(restTimerVibrateProvider).value, isFalse);
      // Turning off the buzz must not turn off the alert itself.
      expect(container.read(restTimerAlertsProvider).value, isTrue);
    });
  });
}
