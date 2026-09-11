// Progressive overload against real logged history: which sessions count, how a
// run of increases is counted, and how a suggestion is rounded to a weight you
// can actually load.

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/overload/data/overload_math.dart';
import 'package:gymfy/features/overload/data/overload_preference.dart';
import 'package:gymfy/features/overload/data/overload_repository.dart';
import 'package:gymfy/features/plates/data/plate_math.dart';
import 'package:gymfy/features/workout/data/session_repository.dart';
import 'package:gymfy/features/workout/data/workout_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';
import 'package:gymfy/shared/utils/units.dart';

void main() {
  const bench = 'barbell_bench_press';

  late AppDatabase db;
  late OverloadRepository overload;
  late WorkoutRepository workouts;
  late SessionRepository sessions;
  late int entryId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    overload = OverloadRepository(db);
    workouts = WorkoutRepository(db);
    sessions = SessionRepository(db);

    await db
        .into(db.exercises)
        .insert(
          ExercisesCompanion.insert(
            id: bench,
            name: 'Barbell Bench Press',
            muscleIds: const ['chest'],
            isPlateLoaded: const Value(true),
          ),
        );
    final splitId = await workouts.createSplit('PPL');
    final dayId = await workouts.createDay(splitId, 'Push');
    await workouts.addExercisesToDay(dayId, [bench]);
    entryId = (await db.select(db.workoutExercises).get()).single.id;
    // 3 × 8–12, so 12 is the rep target that earns an increase.
    await workouts.updatePlannedExercise(
      entryId,
      sets: 3,
      reps: 8,
      repsMax: 12,
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<WorkoutExercise> entry() async {
    return (await db.select(db.workoutExercises).get()).single;
  }

  Future<Exercise> exercise() async {
    // By id, not `.single` — some tests add a second exercise to prove it
    // doesn't interfere.
    return (db.select(
      db.exercises,
    )..where((t) => t.id.equals(bench))).getSingle();
  }

  /// Logs and finishes a session of [sets] sets at [weight] for [reps] reps.
  Future<int> loggedSession({
    required double weight,
    required int reps,
    int sets = 3,
    bool complete = true,
  }) async {
    final id = await db
        .into(db.workoutSessions)
        .insert(WorkoutSessionsCompanion.insert(name: 'Push'));
    for (var i = 1; i <= sets; i++) {
      await sessions.logSet(
        sessionId: id,
        exerciseId: bench,
        setNumber: i,
        weight: weight,
        reps: reps,
      );
    }
    if (complete) await sessions.completeSession(id);
    return id;
  }

  /// The app-wide configuration under test. Overload is one setting now, so
  /// each test states the whole configuration rather than mutating one field of
  /// an exercise.
  OverloadConfig config = defaultOverloadConfig;

  void enableOverload({double? increment, double? percent, int? deload}) {
    config = OverloadConfig(
      enabled: true,
      mode: percent != null
          ? OverloadMode.percent
          : increment != null
          ? OverloadMode.fixed
          : OverloadMode.auto,
      fixedKg: increment ?? defaultOverloadConfig.fixedKg,
      percent: percent ?? defaultOverloadConfig.percent,
      deloadWeeks: deload,
    );
  }

  Future<OverloadSuggestion?> suggest() async {
    return overload.suggestionFor(await entry(), await exercise(), config);
  }

  group('when there is nothing to suggest', () {
    test('a core exercise gets none even when enabled', () async {
      await (db.update(db.exercises)..where((t) => t.id.equals(bench))).write(
        const ExercisesCompanion(muscleIds: Value(['abs'])),
      );
      enableOverload();

      // Suggesting +2.5 kg on a plank is meaningless, so nothing is offered
      // rather than a number nobody should follow.
      expect(await suggest(), isNull);
    });

    test('no history yet reads as first time', () async {
      enableOverload();

      expect((await suggest())!.reason, OverloadReason.firstTime);
    });
  });

  group('which sessions count', () {
    test('an unfinished session is ignored', () async {
      await loggedSession(weight: 60, reps: 12);
      await loggedSession(weight: 100, reps: 12, complete: false);
      enableOverload(increment: 2.5);

      // The session in progress is the one being suggested *for*; letting it
      // advise itself would move the target mid-workout.
      expect((await suggest())!.weight, 62.5);
    });

    test('the newest completed session is the base', () async {
      await loggedSession(weight: 60, reps: 12);
      await loggedSession(weight: 70, reps: 12);
      enableOverload(increment: 2.5);

      expect((await suggest())!.weight, 72.5);
    });

    test('sets from other exercises do not interfere', () async {
      await db
          .into(db.exercises)
          .insert(
            ExercisesCompanion.insert(
              id: 'squat',
              name: 'Squat',
              muscleIds: const ['quads'],
            ),
          );
      final id = await loggedSession(weight: 60, reps: 12);
      await sessions.logSet(
        sessionId: id,
        exerciseId: 'squat',
        setNumber: 1,
        weight: 200,
        reps: 12,
      );
      enableOverload(increment: 2.5);

      // 62.5, not 202.5.
      expect((await suggest())!.weight, 62.5);
    });
  });

  group('increases in a row', () {
    test('counts a straight climb', () async {
      await loggedSession(weight: 60, reps: 12);
      await loggedSession(weight: 62.5, reps: 12);
      await loggedSession(weight: 65, reps: 12);

      expect(overload.increasesInARow(await overload.recentSessions(bench)), 2);
    });

    test('a repeated weight ends the run', () async {
      await loggedSession(weight: 60, reps: 12);
      await loggedSession(weight: 62.5, reps: 12);
      await loggedSession(weight: 62.5, reps: 10);

      expect(overload.increasesInARow(await overload.recentSessions(bench)), 0);
    });

    test('a manual deload resets the run on its own', () async {
      await loggedSession(weight: 60, reps: 12);
      await loggedSession(weight: 65, reps: 12);
      await loggedSession(weight: 50, reps: 12);

      // Derived from history rather than stored, so there is no counter left
      // over to disagree with what actually happened.
      expect(overload.increasesInARow(await overload.recentSessions(bench)), 0);
    });

    test('a long enough run triggers a deload suggestion', () async {
      await loggedSession(weight: 60, reps: 12);
      await loggedSession(weight: 62.5, reps: 12);
      await loggedSession(weight: 65, reps: 12);
      await loggedSession(weight: 67.5, reps: 12);
      await loggedSession(weight: 70, reps: 12);
      enableOverload(increment: 2.5, deload: 4);

      final result = await suggest();
      expect(result!.reason, OverloadReason.deload);
      expect(result.weight, closeTo(63, 0.001)); // 10% off 70
    });
  });

  group('earning the increase', () {
    test('hitting the top of the range goes up', () async {
      await loggedSession(weight: 60, reps: 12);
      enableOverload(increment: 2.5);

      final result = await suggest();
      expect(result!.reason, OverloadReason.earned);
      expect(result.weight, 62.5);
    });

    test('stopping mid-range stays put', () async {
      await loggedSession(weight: 60, reps: 10);
      enableOverload(increment: 2.5);

      final result = await suggest();
      expect(result!.reason, OverloadReason.repeat);
      expect(result.weight, 60);
    });

    test('missing a set stays put even at the top of the range', () async {
      await loggedSession(weight: 60, reps: 12, sets: 2);
      enableOverload(increment: 2.5);

      expect((await suggest())!.reason, OverloadReason.repeat);
    });

    test('the muscle default is used when no increment is set', () async {
      await loggedSession(weight: 60, reps: 12);
      enableOverload();

      // Chest defaults to 2.5 kg.
      expect((await suggest())!.weight, 62.5);
    });

    test('a percentage is taken from the current weight', () async {
      await loggedSession(weight: 100, reps: 12);
      enableOverload(percent: 2.5);

      expect((await suggest())!.weight, 102.5);
    });

    test('the same percentage gives a smaller jump on a lighter lift', () async {
      // The whole point: 2.5% scales itself, where a fixed step is generous on
      // small lifts and timid on big ones.
      await loggedSession(weight: 40, reps: 12);
      enableOverload(percent: 2.5);

      expect((await suggest())!.weight, 41);
    });

    test('percent mode ignores the fixed step', () async {
      await loggedSession(weight: 100, reps: 12);
      enableOverload(increment: 10, percent: 2.5);

      expect((await suggest())!.weight, 102.5);
    });

    test('switching back to a fixed step drops the percentage', () async {
      await loggedSession(weight: 100, reps: 12);
      enableOverload(percent: 5);
      enableOverload(increment: 2.5);

      // Written explicitly as null, or the old percentage would sit there
      // invisibly and take over again.
      expect((await suggest())!.weight, 102.5);
    });
  });

  group('loadableSuggestion', () {
    OverloadSuggestion raw(double weight, OverloadReason reason) =>
        OverloadSuggestion(weight: weight, reason: reason);

    double round(
      OverloadSuggestion suggestion, {
      bool plateLoaded = true,
      List<double> plates = defaultPlatesKg,
      double bar = 20,
    }) {
      return loadableSuggestion(
        suggestion: suggestion,
        plateLoaded: plateLoaded,
        unit: WeightUnit.kg,
        plates: plates,
        bar: bar,
      );
    }

    test('an already loadable weight is left alone', () {
      expect(round(raw(62.5, OverloadReason.earned)), 62.5);
    });

    test('an unloadable increase rounds up, not down', () {
      // +1.25 kg on a barbell is half a plate per side, which nobody owns.
      // Rounding down would turn a suggested increase into no increase, and the
      // app would look like it had forgotten.
      final result = round(raw(61.25, OverloadReason.earned));

      expect(result, greaterThan(60));
      expect(result, 62.5);
    });

    test('a deload rounds down, since the point is to go lighter', () {
      // 63 isn't loadable with these plates; 62.5 is, and 65 would be heavier
      // than the deload asked for.
      expect(round(raw(63, OverloadReason.deload)), 62.5);
    });

    test('a limited plate set still finds the next real step', () {
      final result = round(
        raw(62.5, OverloadReason.earned),
        plates: const [20, 10, 5],
      );

      // Nothing smaller than a 5 means the next step from 60 is 70.
      expect(result, 70);
    });

    test('a non-plate exercise rounds to the unit increment instead', () {
      // Dumbbells and machines move in their own steps; the plate inventory
      // says nothing about them.
      expect(round(raw(22.7, OverloadReason.earned), plateLoaded: false), 22.5);
    });

    test('first time gives zero rather than a made-up number', () {
      expect(round(raw(0, OverloadReason.firstTime)), 0);
    });
  });
}
