// The densest translated screens, laid out in German at phone width.
//
// German runs about a third longer than English, and these screens were
// sized against the English: segmented buttons with three labels, two picker
// fields side by side, list rows with a switch beside two lines of text.
// Nothing here checks wording — l10n_test.dart does that — only that the
// longer words still fit their boxes, at the default text size and at 130%.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/app/theme/app_theme.dart';
import 'package:gymfy/app/theme/accent_color.dart';
import 'package:gymfy/features/help/screens/help_screen.dart';
import 'package:gymfy/features/more/screens/more_screen.dart';
import 'package:gymfy/features/onboarding/screens/onboarding_screen.dart';
import 'package:gymfy/features/settings/screens/settings_screen.dart';
import 'package:gymfy/l10n/l10n.dart';
import 'package:gymfy/shared/database/app_database.dart';

void main() {
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

  /// Pumps [screen] in German on a 360-wide phone, [height] tall so a whole
  /// list is built at once, and returns whatever the layout complained about.
  Future<Object?> pumpGerman(
    WidgetTester tester,
    Widget screen, {
    required double scale,
    double height = 780,
    AppTheme theme = AppTheme.darkDefault,
  }) async {
    tester.view.physicalSize = Size(360, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildAppTheme(theme, AccentPalette.blue),
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: screen,
        ),
      ),
    );
    await tester.runAsync(() => pumpEventQueue());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    return tester.takeException();
  }

  for (final scale in [1.0, 1.3]) {
    group('at text scale $scale', () {
      testWidgets('Settings fits every section', (tester) async {
        // Tall enough that the list builds every section, Health Connect's
        // aside (it is Android-only and absent here).
        expect(
          await pumpGerman(
            tester,
            const SettingsScreen(),
            scale: scale,
            height: 4200,
          ),
          isNull,
        );
        expect(find.text('Einstellungen'), findsOneWidget);
        expect(find.text('Pausentimer-Benachrichtigungen'), findsOneWidget);
      });

      testWidgets('More fits its rows', (tester) async {
        expect(
          await pumpGerman(tester, const MoreScreen(), scale: scale),
          isNull,
        );
        expect(find.text('Übungsbibliothek'), findsOneWidget);
      });

      testWidgets('Help fits its rows', (tester) async {
        expect(
          await pumpGerman(tester, const HelpScreen(), scale: scale),
          isNull,
        );
      });

      testWidgets('onboarding fits three German answers on one row', (
        tester,
      ) async {
        // "Männlich", "Weiblich", "Keine Angabe" — the widest segmented
        // button in the app, on the first screen anyone sees.
        expect(
          await pumpGerman(tester, const OnboardingScreen(), scale: scale),
          isNull,
        );
        expect(find.text('Keine Angabe'), findsOneWidget);
      });

      testWidgets('onboarding fits height and age side by side', (
        tester,
      ) async {
        expect(
          await pumpGerman(tester, const OnboardingScreen(), scale: scale),
          isNull,
        );
        await tester.tap(find.text('Weiter'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        expect(tester.takeException(), isNull);
        expect(find.text('Wie viel wiegst du?'), findsOneWidget);
        expect(find.text('Größe'), findsOneWidget);
      });
    });
  }
}
