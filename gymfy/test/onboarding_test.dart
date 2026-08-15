// First-launch onboarding: what it gates, what it saves, and what it does with
// answers the user chose to skip.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/app/theme/accent_color.dart';
import 'package:gymfy/features/onboarding/data/onboarding_repository.dart';
import 'package:gymfy/features/onboarding/screens/onboarding_screen.dart';
import 'package:gymfy/features/progress/data/measurements_repository.dart';
import 'package:gymfy/shared/data/settings_repository.dart';
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

  /// Reads a stream provider's first value.
  ///
  /// Listens before awaiting on purpose: a bare `read(provider.future)` has no
  /// listener, so Riverpod can tear the provider down while it is still loading
  /// and the await never completes.
  Future<T> firstValue<T>(StreamProvider<T> provider) {
    container.listen(provider, (_, _) {});
    return container.read(provider.future);
  }

  /// The latest logged bodyweight, once the measurement stream has emitted.
  Future<double?> latestBodyweight() async {
    await firstValue(measurementHistoryProvider);
    return container.read(latestBodyweightProvider)?.value;
  }

  /// Waits for a finish triggered through the UI to actually land.
  ///
  /// [firstValue] is no good here: the taps don't await the writes, so the first
  /// emission of any of these streams can predate them. Since `finish()` writes
  /// the completion flag *last*, once that flips every other write is done and
  /// the rest can be read back directly.
  ///
  /// The database work is genuinely asynchronous, and inside `testWidgets` the
  /// clock is faked — so draining has to happen inside [WidgetTester.runAsync],
  /// which steps outside the fake-async zone. A bare `pumpEventQueue()` here
  /// blocks forever.
  Future<void> waitForFinish(WidgetTester tester) async {
    container.listen(onboardingCompleteProvider, (_, _) {});
    container.listen(measurementHistoryProvider, (_, _) {});
    container.listen(userNameProvider, (_, _) {});
    for (var attempt = 0; attempt < 20; attempt++) {
      await tester.runAsync(() => pumpEventQueue());
      await tester.pump();
      if (container.read(onboardingCompleteProvider).value == true) return;
    }
    fail('onboarding never reported itself finished');
  }

  group('onboardingCompleteProvider', () {
    test('a fresh install has not been onboarded', () async {
      expect(await firstValue(onboardingCompleteProvider), isFalse);
    });

    test('only the exact string true counts as done', () async {
      // A half-written or junk value must read as "not yet". Showing onboarding
      // a second time is recoverable; locking a new user out of it is not.
      for (final raw in ['', 'TRUE', '1', 'yes', 'false']) {
        await container
            .read(settingsRepositoryProvider)
            .write(onboardingCompleteSetting, raw);

        expect(
          await firstValue(onboardingCompleteProvider),
          isFalse,
          reason: '"$raw" should not count as onboarded',
        );
      }
    });

    test('finishing flips the gate', () async {
      await container
          .read(onboardingRepositoryProvider)
          .finish(name: 'Joshua', bodyweightKg: 82);

      expect(await firstValue(onboardingCompleteProvider), isTrue);
    });
  });

  group('finish', () {
    test('saves the name and the bodyweight', () async {
      await container
          .read(onboardingRepositoryProvider)
          .finish(name: 'Joshua', bodyweightKg: 82.5);

      expect(await firstValue(userNameProvider), 'Joshua');

      // The weight lands in the measurements table, which is what the charts
      // and the strength ranks read — not a setting of its own.
      expect(await latestBodyweight(), 82.5);
    });

    test('a skipped name is not stored as an empty string', () async {
      await container
          .read(onboardingRepositoryProvider)
          .finish(name: '', bodyweightKg: null);

      expect(await firstValue(userNameProvider), isNull);
      expect(
        await container.read(settingsRepositoryProvider).readRaw(userNameSetting),
        isNull,
      );
    });

    test('a name is trimmed rather than stored with its spaces', () async {
      await container
          .read(onboardingRepositoryProvider)
          .finish(name: '  Joshua  ', bodyweightKg: null);

      expect(await firstValue(userNameProvider), 'Joshua');
    });

    test('whitespace alone counts as skipped', () async {
      await container
          .read(onboardingRepositoryProvider)
          .finish(name: '   ', bodyweightKg: null);

      expect(await firstValue(userNameProvider), isNull);
    });

    test('a skipped bodyweight leaves no measurement behind', () async {
      await container
          .read(onboardingRepositoryProvider)
          .finish(name: 'Joshua', bodyweightKg: null);

      // Not a 0 kg row: that would read as a real weigh-in everywhere else,
      // and would be skipped as bodyweight-only by the 1RM estimator.
      expect(await latestBodyweight(), isNull);
      expect(await firstValue(measurementHistoryProvider), isEmpty);
    });

    test('a zero bodyweight is refused, not written', () async {
      await container
          .read(onboardingRepositoryProvider)
          .finish(name: null, bodyweightKg: 0);

      expect(await latestBodyweight(), isNull);
    });

    test('finishing twice does not duplicate anything', () async {
      final repo = container.read(onboardingRepositoryProvider);
      await repo.finish(name: 'Joshua', bodyweightKg: 82);
      await repo.finish(name: 'Joshua', bodyweightKg: 83);

      // One row per day, so the second answer overwrites the first.
      expect(await firstValue(measurementHistoryProvider), hasLength(1));
      expect(await latestBodyweight(), 83);
    });
  });

  group('OnboardingScreen', () {
    Future<void> pump(WidgetTester tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: OnboardingScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('opens on the welcome step', (tester) async {
      await pump(tester);

      expect(find.text('Welcome to Gymfy'), findsOneWidget);
      // Nothing to go back to yet.
      expect(find.text('Back'), findsNothing);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('walks forward through all three steps', (tester) async {
      await pump(tester);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('How much do you weigh?'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Pick your colour'), findsOneWidget);
      // The last step offers to finish instead of advancing.
      expect(find.text('Next'), findsNothing);
      expect(find.text('Start lifting'), findsOneWidget);
    });

    testWidgets('and back again', (tester) async {
      await pump(tester);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to Gymfy'), findsOneWidget);
    });

    testWidgets('tapping a colour applies it immediately', (tester) async {
      await pump(tester);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // The picker shows one swatch per palette option, and the current one is
      // ticked. Default accent is first, so tap a different one.
      final target = AccentPalette.options.firstWhere(
        (c) => c != AccentPalette.defaultAccent,
      );
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.selected == false,
        ).first,
      );
      await tester.pumpAndSettle();

      // Applied without a save step, so it can be seen before committing.
      expect(container.read(accentColorProvider), target);
    });

    testWidgets('typed answers are saved on finish', (tester) async {
      await pump(tester);

      await tester.enterText(find.byType(TextField), 'Joshua');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '82,5');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start lifting'));
      await tester.pumpAndSettle();
      await waitForFinish(tester);

      expect(container.read(userNameProvider).value, 'Joshua');
      // A comma decimal is what a German keyboard offers, and it must not be
      // silently dropped.
      expect(container.read(latestBodyweightProvider)?.value, 82.5);
    });

    testWidgets('everything can be skipped', (tester) async {
      await pump(tester);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start lifting'));
      await tester.pumpAndSettle();
      await waitForFinish(tester);

      expect(container.read(userNameProvider).value, isNull);
      expect(container.read(latestBodyweightProvider), isNull);
    });
  });
}
