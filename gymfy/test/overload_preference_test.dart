// The app-wide "suggest heavier weights" switch.
//
// One setting rather than one per exercise, asked during onboarding and
// changeable in Settings. What it has to guarantee is simple: off means no
// suggestion reaches the log dialog, whatever any individual exercise says.

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/overload/data/overload_math.dart';
import 'package:gymfy/features/overload/data/overload_preference.dart';
import 'package:gymfy/features/overload/data/overload_repository.dart';
import 'package:gymfy/features/workout/data/session_repository.dart';
import 'package:gymfy/features/workout/data/workout_repository.dart';
import 'package:gymfy/shared/data/settings_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';

void main() {
  group('parseOverloadEnabled', () {
    test('reads back what it writes', () {
      expect(parseOverloadEnabled('true'), isTrue);
      expect(parseOverloadEnabled('false'), isFalse);
    });

    test('an unset preference means on', () {
      // Onboarding offers it already on, so a user who taps straight through
      // gets suggestions — and an install that never saw that page behaves the
      // same as a new one.
      expect(parseOverloadEnabled(null), isTrue);
    });

    test('only the exact string false switches it off', () {
      // Anything else is a value we didn't write, and silently disabling a
      // feature because of junk in a settings row would be hard to diagnose.
      for (final raw in ['', 'FALSE', '0', 'no', 'nope']) {
        expect(parseOverloadEnabled(raw), isTrue, reason: raw);
      }
    });
  });

  group('OverloadConfig compares by value', () {
    // Not housekeeping. `overloadConfigProvider` builds a fresh config every
    // time one of its five settings streams emits, and all five emit on
    // startup. On identity equality each of those is a new config, so every
    // overload suggestion on screen throws away its result and re-runs its
    // database join — several times, before the first screen has settled.
    test('two configs with the same values are the same config', () {
      expect(
        defaultOverloadConfig,
        equals(
          const OverloadConfig(
            enabled: true,
            mode: OverloadMode.auto,
            fixedKg: 2.5,
            percent: 2.5,
            deloadWeeks: null,
          ),
        ),
      );
    });

    test('a changed field makes it a different config', () {
      // The other half: equality that is too generous would stop a real
      // settings change from ever reaching the suggestions, which is a worse
      // bug than the churn it was meant to fix. One case per field.
      expect(
        defaultOverloadConfig,
        isNot(defaultOverloadConfig.copyWith(enabled: false)),
      );
      expect(
        defaultOverloadConfig,
        isNot(defaultOverloadConfig.copyWith(mode: OverloadMode.percent)),
      );
      expect(
        defaultOverloadConfig,
        isNot(defaultOverloadConfig.copyWith(fixedKg: 5)),
      );
      expect(
        defaultOverloadConfig,
        isNot(defaultOverloadConfig.copyWith(percent: 5)),
      );
      expect(
        defaultOverloadConfig,
        isNot(defaultOverloadConfig.copyWith(deloadWeeks: 4)),
      );
    });

    test('equal configs hash alike', () {
      expect(
        defaultOverloadConfig.hashCode,
        defaultOverloadConfig.copyWith().hashCode,
      );
    });
  });

  group('the switch gates real suggestions', () {
    const bench = 'barbell_bench_press';

    late AppDatabase db;
    late ProviderContainer container;
    late WorkoutRepository workouts;
    late SessionRepository sessions;
    late WorkoutExercise entry;
    late Exercise exercise;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      workouts = WorkoutRepository(db);
      sessions = SessionRepository(db);

      await db
          .into(db.exercises)
          .insert(
            ExercisesCompanion.insert(
              id: bench,
              name: 'Barbell Bench Press',
              muscleIds: const ['chest'],
            ),
          );
      final splitId = await workouts.createSplit('PPL');
      final dayId = await workouts.createDay(splitId, 'Push');
      await workouts.addExercisesToDay(dayId, [bench]);
      final entryId = (await db.select(db.workoutExercises).get()).single.id;
      await workouts.updatePlannedExercise(
        entryId,
        sets: 3,
        reps: 8,
        repsMax: 12,
      );

      // A session that earns an increase, so a null answer below can only be
      // the switch and nothing else.
      final sessionId = await db
          .into(db.workoutSessions)
          .insert(WorkoutSessionsCompanion.insert(name: 'Push'));
      for (var i = 1; i <= 3; i++) {
        await sessions.logSet(
          sessionId: sessionId,
          exerciseId: bench,
          setNumber: i,
          weight: 60,
          reps: 12,
        );
      }
      await sessions.completeSession(sessionId);

      entry = (await db.select(db.workoutExercises).get()).single;
      exercise = (await db.select(db.exercises).get()).single;
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    Future<OverloadSuggestion?> suggestion() async {
      // Every key the config reads has to have emitted, or the provider would
      // be answering from defaults while a stored value was still in flight.
      for (final key in [
        overloadEnabledSetting,
        overloadModeSetting,
        overloadFixedSetting,
        overloadPercentSetting,
        overloadDeloadSetting,
      ]) {
        container.listen(rawSettingProvider(key), (_, _) {});
        await container.read(rawSettingProvider(key).future);
      }
      return container.read(
        overloadSuggestionProvider((entry: entry, exercise: exercise)).future,
      );
    }

    Future<void> setEnabled(bool enabled) async {
      await container
          .read(settingsRepositoryProvider)
          .write(overloadEnabledSetting, enabled.toString());
    }

    Future<void> setPercent(double percent) async {
      final settings = container.read(settingsRepositoryProvider);
      await settings.write(overloadModeSetting, OverloadMode.percent.name);
      await settings.write(overloadPercentSetting, percent.toString());
    }

    test('on by default, so an earned increase is suggested', () async {
      final result = await suggestion();

      expect(result, isNotNull);
      expect(result!.weight, 62.5);
    });

    test('switching it off suppresses the suggestion entirely', () async {
      await setEnabled(false);

      // Not "shows the same weight" — nothing at all, so the log dialog opens
      // exactly as it did before the feature existed.
      expect(await suggestion(), isNull);
    });

    test('switching it back on brings suggestions back', () async {
      await setEnabled(false);
      await setEnabled(true);

      expect(await suggestion(), isNotNull);
    });

    test('the step survives being switched off and on', () async {
      // The panel still edits *how much* while suggestions are off; that
      // setting has to still be there when they come back.
      await setPercent(5);
      await setEnabled(false);
      await setEnabled(true);

      // 5% of 60 kg is 3 kg, rounded up to the next loadable weight.
      expect((await suggestion())!.weight, 63);
    });
  });
}
