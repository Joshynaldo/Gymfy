// The language setting: stored in app_settings, applied live, and following
// the phone until someone picks otherwise.

import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart' hide Split;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/onboarding/data/onboarding_repository.dart';
import 'package:gymfy/features/settings/screens/settings_screen.dart';
import 'package:gymfy/features/workout/data/workout_repository.dart';
import 'package:gymfy/l10n/app_language.dart';
import 'package:gymfy/l10n/l10n.dart';
import 'package:gymfy/main.dart';
import 'package:gymfy/shared/data/settings_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';

import 'support/default_accent.dart';

/// The bottom bar's labels, read off the destinations.
List<String> _tabLabels(WidgetTester tester) => tester
    .widget<NavigationBar>(find.byType(NavigationBar))
    .destinations
    .cast<NavigationDestination>()
    .map((d) => d.label)
    .toList();

void main() {
  group('AppLanguage', () {
    test('round-trips its stored values', () {
      for (final language in AppLanguage.values) {
        expect(AppLanguage.parse(language.storedValue), language);
      }
      expect(AppLanguage.german.storedValue, 'de');
      expect(AppLanguage.english.storedValue, 'en');
    });

    test('anything unknown follows the phone', () {
      for (final raw in [null, '', 'fr', 'DE', 'german']) {
        expect(AppLanguage.parse(raw), AppLanguage.system, reason: raw);
      }
    });

    test('names each language in that language', () {
      expect(AppLanguage.endonymFor(const Locale('de')), 'Deutsch');
      expect(AppLanguage.endonymFor(const Locale('en')), 'English');
    });
  });

  group('resolveSystemLocale', () {
    test('a German phone, in any region, gets German', () {
      expect(
        resolveSystemLocale(const [Locale('de', 'DE')]).languageCode,
        'de',
      );
      expect(
        resolveSystemLocale(const [Locale('de', 'CH')]).languageCode,
        'de',
      );
    });

    test('a language the app does not have falls back to English', () {
      expect(
        resolveSystemLocale(const [Locale('fr', 'FR')]).languageCode,
        'en',
      );
      expect(resolveSystemLocale(const []).languageCode, 'en');
    });

    test('the first supported language in the phone list wins', () {
      expect(
        resolveSystemLocale(const [Locale('fr'), Locale('de')]).languageCode,
        'de',
      );
    });
  });

  group('storage', () {
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

    test('nothing stored means the phone decides', () async {
      container.listen(appLocaleProvider, (_, _) {});
      await container.read(storedAppLanguageProvider.future);
      expect(container.read(appLanguageProvider), AppLanguage.system);
      expect(container.read(appLocaleProvider), isNull);
    });

    test(
      'a picked language is stored as its code and forces the locale',
      () async {
        container.listen(appLocaleProvider, (_, _) {});
        await container
            .read(settingsRepositoryProvider)
            .write(appLanguageSetting, AppLanguage.german.storedValue);
        await pumpEventQueue();

        expect(
          await container
              .read(settingsRepositoryProvider)
              .readRaw(appLanguageSetting),
          'de',
        );
        expect(container.read(appLocaleProvider), const Locale('de'));
        expect(container.read(appLocalizationsProvider).localeName, 'de');
      },
    );

    test('the phone changing language moves the strings with it', () async {
      container.listen(appLocalizationsProvider, (_, _) {});
      await container.read(storedAppLanguageProvider.future);
      final phone = container.read(systemLocalesProvider.notifier);

      phone.changed(const [Locale('de', 'AT')]);
      expect(container.read(appLocalizationsProvider).localeName, 'de');
      phone.changed(const [Locale('fr'), Locale('en', 'GB')]);
      expect(container.read(appLocalizationsProvider).localeName, 'en');
    });

    test('but not past a language picked in Settings', () async {
      container.listen(appLocalizationsProvider, (_, _) {});
      await container
          .read(settingsRepositoryProvider)
          .write(appLanguageSetting, AppLanguage.german.storedValue);
      await pumpEventQueue();

      container.read(systemLocalesProvider.notifier).changed(const [
        Locale('en', 'US'),
      ]);
      expect(container.read(appLocalizationsProvider).localeName, 'de');
    });
  });

  group('the app', () {
    /// Boots the real app root with the stored language fed from [stored].
    Future<void> boot(WidgetTester tester, Stream<AppLanguage?> stored) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            defaultAccentOverride,
            onboardingCompleteProvider.overrideWith(
              (ref) => Stream.value(true),
            ),
            splitListProvider.overrideWith((ref) => Stream.value(<Split>[])),
            storedAppLanguageProvider.overrideWith((ref) => stored),
          ],
          child: const GymfyApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('follows a German phone without being told', (tester) async {
      tester.platformDispatcher.localesTestValue = const [Locale('de', 'DE')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);

      await boot(tester, Stream.value(null));

      expect(_tabLabels(tester), ['Start', 'Training', 'Fortschritt', 'Mehr']);
    });

    testWidgets('stays English on an English phone', (tester) async {
      tester.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);

      await boot(tester, Stream.value(null));

      expect(_tabLabels(tester), ['Home', 'Workout', 'Progress', 'More']);
    });

    testWidgets(
      'on the system default, the words outside the app follow the phone too',
      (tester) async {
        // The notification and the watch are worded from
        // appLocalizationsProvider, not from a widget. Android does not
        // restart Gymfy for a language change, so that provider has to hear
        // about it — the screens already do, through MaterialApp.
        await boot(tester, Stream.value(null));
        final container = ProviderScope.containerOf(
          tester.element(find.byType(NavigationBar)),
        );
        container.listen(appLocalizationsProvider, (_, _) {});
        addTearDown(tester.platformDispatcher.clearLocalesTestValue);

        tester.platformDispatcher.localesTestValue = const [Locale('de', 'DE')];
        await tester.pumpAndSettle();
        expect(_tabLabels(tester), [
          'Start',
          'Training',
          'Fortschritt',
          'Mehr',
        ]);
        expect(container.read(appLocalizationsProvider).localeName, 'de');

        tester.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
        await tester.pumpAndSettle();
        expect(_tabLabels(tester), ['Home', 'Workout', 'Progress', 'More']);
        expect(container.read(appLocalizationsProvider).localeName, 'en');
      },
    );

    testWidgets('a picked language beats the phone, and applies live', (
      tester,
    ) async {
      tester.platformDispatcher.localesTestValue = const [Locale('de', 'DE')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      final stored = StreamController<AppLanguage?>();
      addTearDown(stored.close);

      await boot(tester, stored.stream);
      stored.add(AppLanguage.english);
      await tester.pumpAndSettle();
      expect(_tabLabels(tester), ['Home', 'Workout', 'Progress', 'More']);

      // No restart: the root rebuilds with the new locale as soon as the
      // setting changes.
      stored.add(AppLanguage.german);
      await tester.pumpAndSettle();
      expect(_tabLabels(tester), ['Start', 'Training', 'Fortschritt', 'Mehr']);

      stored.add(AppLanguage.system);
      await tester.pumpAndSettle();
      expect(_tabLabels(tester), ['Start', 'Training', 'Fortschritt', 'Mehr']);
    });
  });

  group('the settings row', () {
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

    /// The settings screen inside an app that is localised the way the real
    /// one is, so picking a language visibly changes the screen.
    Future<void> pump(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 2600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.localesTestValue = const [Locale('en', 'GB')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: Consumer(
            builder: (context, ref, _) => MaterialApp(
              locale: ref.watch(appLocaleProvider),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const SettingsScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> settle(WidgetTester tester) async {
      await tester.runAsync(() => pumpEventQueue());
      await tester.pumpAndSettle();
    }

    testWidgets('starts on the system default and says what that is', (
      tester,
    ) async {
      await pump(tester);

      expect(find.text('Language'), findsOneWidget);
      expect(find.text('System default'), findsOneWidget);

      await tester.tap(find.text('App language'));
      await tester.pumpAndSettle();

      expect(find.text('Follows your phone: English'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Deutsch'), findsOneWidget);
    });

    testWidgets('picking Deutsch stores it and switches the screen', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(find.text('App language'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Deutsch'));
      await settle(tester);

      expect(
        await container
            .read(settingsRepositoryProvider)
            .readRaw(appLanguageSetting),
        'de',
      );
      expect(find.text('Einstellungen'), findsOneWidget);
      expect(find.text('App-Sprache'), findsOneWidget);
      // The one thing deliberately left in English gets said once.
      expect(find.text('Übungsnamen bleiben auf Englisch.'), findsOneWidget);
    });

    testWidgets('going back to the system default clears the choice', (
      tester,
    ) async {
      await container
          .read(settingsRepositoryProvider)
          .write(appLanguageSetting, AppLanguage.german.storedValue);
      await pump(tester);
      expect(find.text('Einstellungen'), findsOneWidget);

      await tester.tap(find.text('App-Sprache'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Systemsprache'));
      await settle(tester);

      expect(container.read(appLanguageProvider), AppLanguage.system);
      // The phone in this test is English, so that is where it lands.
      expect(find.text('Settings'), findsOneWidget);
    });
  });
}
