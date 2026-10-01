// Training blocks and percentage targets, as the suggestion on the workout
// screen sees them.
//
// The block used throughout: three training weeks from Monday 7 September
// 2026, then a deload week (28 Sep – 4 Oct), then the next block from 5 Oct.

import 'package:clock/clock.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/calculator/data/tested_one_rm_repository.dart';
import 'package:gymfy/features/overload/data/overload_math.dart';
import 'package:gymfy/features/overload/data/overload_preference.dart';
import 'package:gymfy/features/overload/data/overload_repository.dart';
import 'package:gymfy/features/programs/data/training_plan_repository.dart';
import 'package:gymfy/features/workout/data/session_repository.dart';
import 'package:gymfy/features/workout/data/workout_repository.dart';
import 'package:gymfy/shared/data/settings_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';

const _bench = 'barbell_bench_press';
const _crunch = 'crunch';

final _blockStart = DateTime(2026, 9, 7);

void main() {
  late AppDatabase db;
  late WorkoutRepository workouts;
  late SessionRepository sessions;
  late OverloadRepository overload;
  late TrainingPlanRepository plans;
  late int splitId;
  late int dayId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    workouts = WorkoutRepository(db);
    sessions = SessionRepository(db);
    overload = OverloadRepository(db);
    plans = TrainingPlanRepository(db);

    await db
        .into(db.exercises)
        .insert(
          ExercisesCompanion.insert(
            id: _bench,
            name: 'Barbell Bench Press',
            muscleIds: const ['chest'],
          ),
        );
    await db
        .into(db.exercises)
        .insert(
          ExercisesCompanion.insert(
            id: _crunch,
            name: 'Crunch',
            muscleIds: const ['abs'],
          ),
        );

    splitId = await workouts.createSplit('Strength');
    dayId = await workouts.createDay(splitId, 'Bench');
    await workouts.addExercisesToDay(dayId, [_bench, _crunch]);
    for (final row in await db.select(db.workoutExercises).get()) {
      await workouts.updatePlannedExercise(
        row.id,
        sets: 3,
        reps: 8,
        repsMax: 12,
      );
    }
  });

  tearDown(() async => db.close());

  Future<void> startBlock({double deloadPercent = 60}) =>
      plans.setTrainingBlock(
        splitId,
        blockWeeks: 3,
        deloadPercent: deloadPercent,
        startedAt: _blockStart,
      );

  Future<Split> split() =>
      (db.select(db.splits)..where((t) => t.id.equals(splitId))).getSingle();

  Future<WorkoutExercise> entry([String exerciseId = _bench]) => (db.select(
    db.workoutExercises,
  )..where((t) => t.exerciseId.equals(exerciseId))).getSingle();

  Future<Exercise> exercise([String id = _bench]) =>
      (db.select(db.exercises)..where((t) => t.id.equals(id))).getSingle();

  /// A finished session on [day]: three sets of twelve at [weight], which
  /// earns an increase under double progression.
  Future<void> trained(DateTime day, double weight) async {
    final sessionId = await db
        .into(db.workoutSessions)
        .insert(
          WorkoutSessionsCompanion.insert(
            name: 'Bench',
            dayId: Value(dayId),
            startedAt: Value(day),
            completedAt: Value(day.add(const Duration(hours: 1))),
          ),
        );
    for (var i = 1; i <= 3; i++) {
      await sessions.logSet(
        sessionId: sessionId,
        exerciseId: _bench,
        setNumber: i,
        weight: weight,
        reps: 12,
      );
    }
  }

  group('TrainingPlanRepository', () {
    test('sets a block from midnight of its start day', () async {
      await plans.setTrainingBlock(
        splitId,
        blockWeeks: 4,
        deloadPercent: 70,
        startedAt: DateTime(2026, 9, 7, 18, 45),
      );
      final s = await split();
      expect(s.blockWeeks, 4);
      expect(s.deloadPercent, 70);
      expect(s.blockStartedAt, DateTime(2026, 9, 7));
    });

    test('clamps values no settings screen offers', () async {
      await plans.setTrainingBlock(
        splitId,
        blockWeeks: 0,
        deloadPercent: 5,
        startedAt: _blockStart,
      );
      var s = await split();
      expect(s.blockWeeks, 1);
      expect(s.deloadPercent, minDeloadPercent);

      await plans.setTrainingBlock(
        splitId,
        blockWeeks: 40,
        deloadPercent: 100,
        startedAt: _blockStart,
      );
      s = await split();
      expect(s.blockWeeks, maxBlockWeeks);
      expect(s.deloadPercent, maxDeloadPercent);
    });

    test('turning the block off clears all three columns', () async {
      await startBlock();
      await plans.clearTrainingBlock(splitId);
      final s = await split();
      expect(s.blockWeeks, isNull);
      expect(s.deloadPercent, isNull);
      expect(s.blockStartedAt, isNull);
    });

    test('a percentage outside (0, 100] is stored as none', () async {
      final id = (await entry()).id;

      await plans.setTargetPercent(id, 75);
      expect((await entry()).targetPercent, 75);

      await plans.setTargetPercent(id, 140);
      expect((await entry()).targetPercent, isNull);

      await plans.setTargetPercent(id, 80);
      await plans.setTargetPercent(id, 0);
      expect((await entry()).targetPercent, isNull);

      await plans.setTargetPercent(id, 80);
      await plans.setTargetPercent(id, null);
      expect((await entry()).targetPercent, isNull);
    });
  });

  group('OverloadRepository', () {
    test('finds the split a day belongs to', () async {
      expect((await overload.splitOfDay(dayId))?.id, splitId);
      expect(await overload.splitOfDay(9999), isNull);
    });

    test('progresses from the last training week, not the deload', () async {
      await startBlock();
      await trained(DateTime(2026, 9, 22), 100); // week 3
      await trained(DateTime(2026, 9, 29), 60); // the deload week

      const config = OverloadConfig(
        enabled: true,
        mode: OverloadMode.fixed,
        fixedKg: 2.5,
        percent: 2.5,
        deloadWeeks: null,
      );

      // With the block, the deliberately light week is not the baseline.
      final withBlock = await overload.suggestionFor(
        await entry(),
        await exercise(),
        config,
        split: await split(),
      );
      expect(withBlock!.weight, 102.5);

      // Without it, the 60 kg week would be — which is the bug a block avoids.
      final without = await overload.suggestionFor(
        await entry(),
        await exercise(),
        config,
      );
      expect(without!.weight, 62.5);
    });

    test('a deload takes its percentage of the last training week', () async {
      await startBlock();
      await trained(DateTime(2026, 9, 22), 100);
      // A second session inside the deload week must not compound: 60 % of
      // 100, not 60 % of the first deload session's 60.
      await trained(DateTime(2026, 9, 29), 60);

      final result = await overload.blockDeloadFor(
        await exercise(),
        await split(),
        deloadPercent: 60,
      );
      expect(result!.reason, OverloadReason.blockDeload);
      expect(result.weight, 60);
      expect(result.deloadPercent, 60);
    });

    test('a deload with no history has nothing to take a share of', () async {
      await startBlock();
      final result = await overload.blockDeloadFor(
        await exercise(),
        await split(),
        deloadPercent: 60,
      );
      expect(result!.reason, OverloadReason.firstTime);
    });

    test('core work gets no deload number either', () async {
      await startBlock();
      expect(
        await overload.blockDeloadFor(
          await exercise(_crunch),
          await split(),
          deloadPercent: 60,
        ),
        isNull,
      );
    });
  });

  group('the suggestion provider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
    });

    tearDown(() => container.dispose());

    Future<void> settingsLoaded() async {
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
    }

    Future<OverloadSuggestion?> suggestionOn(DateTime day) async {
      await settingsLoaded();
      final key = (entry: await entry(), exercise: await exercise());
      return withClock(
        Clock.fixed(day),
        () => container.read(overloadSuggestionProvider(key).future),
      );
    }

    Future<void> overloadOff() async {
      await container
          .read(settingsRepositoryProvider)
          .write(overloadEnabledSetting, 'false');
    }

    test('in the deload week, suggests the deload load', () async {
      await startBlock();
      await trained(DateTime(2026, 9, 22), 100);

      final result = await suggestionOn(DateTime(2026, 9, 30, 12));
      expect(result!.reason, OverloadReason.blockDeload);
      expect(result.weight, 60);
    });

    test('the block deload shows even with overload switched off', () async {
      // The block is something the user set up on the split; the overload
      // switch is about automatic increases.
      await startBlock();
      await trained(DateTime(2026, 9, 22), 100);
      await overloadOff();

      final result = await suggestionOn(DateTime(2026, 9, 30, 12));
      expect(result!.reason, OverloadReason.blockDeload);
    });

    test('outside the deload week it is ordinary overload', () async {
      await startBlock();
      await trained(DateTime(2026, 9, 15), 100);

      final result = await suggestionOn(DateTime(2026, 9, 22, 12));
      expect(result!.reason, OverloadReason.earned);
      expect(result.weight, 102.5);
    });

    group('with a percentage target', () {
      setUp(() async {
        await plans.setTargetPercent((await entry()).id, 80);
        await TestedOneRmRepository(db).setForExercise(
          exerciseId: _bench,
          weightKg: 120,
          testedOn: DateTime(2026, 9, 1),
        );
      });

      test('suggests that share of the tested max', () async {
        final result = await suggestionOn(DateTime(2026, 9, 16, 12));
        expect(result!.reason, OverloadReason.percentOfMax);
        expect(result.weight, 96);
        expect(result.targetPercent, 80);
      });

      test('shows even with overload switched off', () async {
        await overloadOff();
        final result = await suggestionOn(DateTime(2026, 9, 16, 12));
        expect(result!.reason, OverloadReason.percentOfMax);
      });

      test('in a deload week, lightens the percentage', () async {
        await startBlock();
        final result = await suggestionOn(DateTime(2026, 9, 30, 12));
        expect(result!.reason, OverloadReason.blockDeload);
        // 60 % of 96 is 57.6; dumbbells-and-machines rounding gives 57.5.
        expect(result.weight, 57.5);
        expect(result.targetPercent, 80);
        expect(result.deloadPercent, 60);
      });
    });

    test('a percentage with no max to go on falls back to overload', () async {
      await plans.setTargetPercent((await entry()).id, 80);
      // No tested max, and no working set yet — so no estimate either.
      expect(await suggestionOn(DateTime(2026, 9, 16, 12)), isNull);
    });
  });
}
