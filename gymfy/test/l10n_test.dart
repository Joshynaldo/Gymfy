// The localisation plumbing: the English fallback every widget test relies
// on, and the two ARB files staying in step with each other.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/l10n/l10n.dart';

/// The messages in an ARB file, without its `@` metadata.
Map<String, String> _messages(String path) {
  final json =
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  return {
    for (final entry in json.entries)
      if (!entry.key.startsWith('@')) entry.key: entry.value as String,
  };
}

/// The placeholder names a message uses: `{name}`, and the `{count, plural …`
/// that opens a plural or select. Literal text inside a plural branch, like
/// the `{1 set}` in `=1{1 set}`, starts with a digit and is not counted.
Set<String> _placeholders(String message) => {
  for (final match in RegExp(r'\{([A-Za-z_]\w*)\s*[,}]').allMatches(message))
    match.group(1)!,
};

/// German messages that are meant to read exactly like the English ones.
///
/// Everything else in app_de.arb has to differ from the template: a German
/// value that is a copy of the English is almost always a string someone
/// forgot to translate. Add a key here only when German really says the same
/// thing — a name, a borrowed word, a unit.
const _sameInGerman = {
  'settingsSectionHealthConnect',
  'settingsNameTitle',
  'helpVersionTitle',
  'onboardingNameHint',
  'homeGreeting',
};

void main() {
  group('context.l10n', () {
    testWidgets('falls back to English without the delegates', (tester) async {
      // How most widget tests in this suite pump a widget: a bare
      // MaterialApp, no localisation delegates. AppLocalizations.of returns
      // null there, and the extension has to hand back English rather than
      // crash.
      late AppLocalizations strings;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              strings = context.l10n;
              return Text(context.l10n.settingsTitle);
            },
          ),
        ),
      );

      expect(find.text('Settings'), findsOneWidget);
      expect(strings.localeName, 'en');
    });

    testWidgets('falls back to English with no Localizations at all', (
      tester,
    ) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(builder: (context) => Text(context.l10n.commonDone)),
        ),
      );

      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('speaks German once the delegates are installed', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(builder: (context) => Text(context.l10n.settingsTitle)),
        ),
      );

      expect(find.text('Einstellungen'), findsOneWidget);
    });

    testWidgets('a regional German phone gets German', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('de', 'AT'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(builder: (context) => Text(context.l10n.shellNavMore)),
        ),
      );

      expect(find.text('Mehr'), findsOneWidget);
    });
  });

  test('English is listed first, so an unsupported language gets English', () {
    // Flutter falls back to the first supported locale. The generator sorts
    // alphabetically unless told otherwise, which would put German first and
    // hand a French phone a German app.
    expect(AppLocalizations.supportedLocales.first, const Locale('en'));
  });

  group('the ARB files', () {
    final english = _messages('lib/l10n/app_en.arb');
    final german = _messages('lib/l10n/app_de.arb');

    test('German has every English key, and nothing else', () {
      expect(
        english.keys.toSet().difference(german.keys.toSet()),
        isEmpty,
        reason: 'missing from app_de.arb',
      );
      expect(
        german.keys.toSet().difference(english.keys.toSet()),
        isEmpty,
        reason: 'in app_de.arb but not in the template',
      );
    });

    test('every translation uses the same placeholders', () {
      for (final key in english.keys) {
        expect(
          _placeholders(german[key]!),
          _placeholders(english[key]!),
          reason: key,
        );
      }
    });

    test('nothing is left as a copy of the English', () {
      final copies = {
        for (final key in english.keys)
          if (german[key] == english[key]) key,
      };
      expect(copies.difference(_sameInGerman), isEmpty);
      // And the list stays honest: an entry whose German has since been
      // reworded is no longer an exception and comes off it.
      expect(_sameInGerman.difference(copies), isEmpty);
    });

    test('keys follow the naming convention', () {
      // lowerCamelCase, ASCII, starting with the area (see FEATURE_PLAN.md).
      for (final key in english.keys) {
        expect(key, matches(RegExp(r'^[a-z][a-zA-Z0-9]*$')), reason: key);
      }
    });
  });

  group('plurals', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final de = lookupAppLocalizations(const Locale('de'));

    test('count the same thing in both languages', () {
      expect(en.homeWeekWorkouts(1), '1 workout');
      expect(en.homeWeekWorkouts(3), '3 workouts');
      expect(de.homeWeekWorkouts(1), '1 Training');
      expect(de.homeWeekWorkouts(3), '3 Trainings');

      expect(en.homeLastWorkoutSets(1, '80 kg'), '1 set • 80 kg');
      expect(de.homeLastWorkoutSets(1, '80 kg'), '1 Satz • 80 kg');
      expect(de.homeLastWorkoutSets(12, '4.200 kg'), '12 Sätze • 4.200 kg');
    });

    test('the body diagram sentence declines with the sex', () {
      expect(
        en.settingsBodyDiagramSubtitle('female'),
        'Female diagram and strength standards',
      );
      expect(
        de.settingsBodyDiagramSubtitle('female'),
        'Weibliches Diagramm und Kraftstandards',
      );
      expect(
        de.settingsBodyDiagramSubtitle('male'),
        'Männliches Diagramm und Kraftstandards',
      );
    });
  });
}
