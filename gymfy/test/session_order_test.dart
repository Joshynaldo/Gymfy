// Editing a running workout's exercise list: add, swap, reorder and remove.
//
// All four edit the session's own running order (session_exercises) and must
// leave the plan alone — the one exception, saving a swap back to the plan, is
// a separate call on the plan repository and is covered here too.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/workout/data/session_repository.dart';
import 'package:gymfy/features/workout/data/workout_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';

void main() {
  late AppDatabase db;
  late SessionRepository sessions;
  late WorkoutRepository plans;
  late int dayId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.customStatement('PRAGMA foreign_keys = ON');
    sessions = SessionRepository(db);
    plans = WorkoutRepository(db);
    for (final (id, name) in [
      ('bench', 'Bench Press'),
      ('row', 'Barbell Row'),
      ('curl', 'Dumbbell Curl'),
      ('dip', 'Dip'),
    ]) {
      await db
          .into(db.exercises)
          .insert(
            ExercisesCompanion.insert(
              id: id,
              name: name,
              muscleIds: const ['chest'],
            ),
          );
    }
    final splitId = await plans.createSplit('PPL');
    dayId = await plans.createDay(splitId, 'Push');
  });

  tearDown(() => db.close());

  Future<List<String>> order(int sessionId) async => [
    for (final e in await sessions.watchSessionExercises(sessionId).first)
      e.exercise.id,
  ];

  Future<void> logOne(int sessionId, String exerciseId) => sessions.logSet(
    sessionId: sessionId,
    exerciseId: exerciseId,
    setNumber: 1,
    weight: 50,
    reps: 10,
  );

  group('adding', () {
    test('appends to the end of the running order', () async {
      await plans.addExerciseToDay(dayId, 'bench');
      final id = await sessions.startSession(dayId: dayId, name: 'Push');

      final added = await sessions.addExercises(id, ['curl', 'dip']);

      expect(added, 2);
      expect(await order(id), ['bench', 'curl', 'dip']);
    });

    test('skips what is already in the workout', () async {
      // A lift appears once: its sets are keyed by exercise, so a second
      // entry would share — and double-count — the first one's sets.
      final id = await sessions.startFreeSession(name: 'Free');
      await sessions.addExercises(id, ['bench']);

      final added = await sessions.addExercises(id, ['bench', 'row', 'row']);

      expect(added, 1);
      expect(await order(id), ['bench', 'row']);
    });

    test('an added exercise works to the 3 × 10 default', () async {
      final id = await sessions.startFreeSession(name: 'Free');
      await sessions.addExercises(id, ['curl']);

      final entry = (await sessions.watchSessionExercises(id).first).single;

      expect(entry.planned, isNull);
      expect(entry.targets.defaultSets, addedExerciseSets);
      expect(entry.targets.defaultReps, addedExerciseReps);
      expect(entry.targets.warmupSets, 0);
      expect(entry.supersetGroup, isNull);
    });

    test('never touches the plan', () async {
      await plans.addExerciseToDay(dayId, 'bench');
      final id = await sessions.startSession(dayId: dayId, name: 'Push');

      await sessions.addExercises(id, ['curl']);

      final plan = await plans.watchDayExercises(dayId).first;
      expect(plan.map((p) => p.exercise.id), ['bench']);
    });
  });

  group('swapping', () {
    test('keeps the plan slot, so the targets carry over', () async {
      await plans.addExerciseToDay(dayId, 'bench', sets: 5, reps: 5);
      final id = await sessions.startSession(dayId: dayId, name: 'Push');
      final entry = (await sessions.watchSessionExercises(id).first).single;

      final ok = await sessions.swapExercise(
        sessionExerciseId: entry.row.id,
        exerciseId: 'dip',
      );

      final swapped = (await sessions.watchSessionExercises(id).first).single;
      expect(ok, isTrue);
      expect(swapped.exercise.id, 'dip');
      expect(swapped.targets.defaultSets, 5);
      expect(swapped.targets.defaultReps, 5);
      // One-off: the plan still says bench.
      final plan = await plans.watchDayExercises(dayId).first;
      expect(plan.single.exercise.id, 'bench');
    });

    test('saving the swap to the plan changes the slot too', () async {
      await plans.addExerciseToDay(dayId, 'bench', sets: 4);
      final id = await sessions.startSession(dayId: dayId, name: 'Push');
      final entry = (await sessions.watchSessionExercises(id).first).single;

      await sessions.swapExercise(
        sessionExerciseId: entry.row.id,
        exerciseId: 'dip',
      );
      await plans.replacePlannedExercise(entry.planned!.id, 'dip');

      final plan = (await plans.watchDayExercises(dayId).first).single;
      expect(plan.exercise.id, 'dip');
      expect(plan.entry.defaultSets, 4, reason: 'targets are kept');
    });

    test('refuses an exercise already in the workout', () async {
      final id = await sessions.startFreeSession(name: 'Free');
      await sessions.addExercises(id, ['bench', 'row']);
      final bench = (await sessions.watchSessionExercises(id).first).first;

      final ok = await sessions.swapExercise(
        sessionExerciseId: bench.row.id,
        exerciseId: 'row',
      );

      expect(ok, isFalse);
      expect(await order(id), ['bench', 'row']);
    });

    test('keeps a swapped-out exercise that already has sets', () async {
      // You did two sets of bench, then the bench was needed. Those sets are
      // still in the session; the exercise must stay on screen with them.
      await plans.addExerciseToDay(dayId, 'bench');
      await plans.addExerciseToDay(dayId, 'curl');
      final id = await sessions.startSession(dayId: dayId, name: 'Push');
      await logOne(id, 'bench');
      final bench = (await sessions.watchSessionExercises(id).first).first;

      await sessions.swapExercise(
        sessionExerciseId: bench.row.id,
        exerciseId: 'dip',
      );

      final entries = await sessions.watchSessionExercises(id).first;
      expect(entries.map((e) => e.exercise.id), ['bench', 'dip', 'curl']);
      // The plan slot moved to the replacement; the kept bench has none.
      expect(entries[0].planned, isNull);
      expect(entries[1].planned?.id, bench.planned!.id);
    });
  });

  group('reordering', () {
    test('writes the order given', () async {
      final id = await sessions.startFreeSession(name: 'Free');
      await sessions.addExercises(id, ['bench', 'row', 'curl']);
      final entries = await sessions.watchSessionExercises(id).first;

      await sessions.reorderExercises(id, [
        entries[2].row.id,
        entries[0].row.id,
        entries[1].row.id,
      ]);

      expect(await order(id), ['curl', 'bench', 'row']);
    });

    test('keeps anything left out after the ones given', () async {
      final id = await sessions.startFreeSession(name: 'Free');
      await sessions.addExercises(id, ['bench', 'row', 'curl']);
      final entries = await sessions.watchSessionExercises(id).first;

      await sessions.reorderExercises(id, [entries[2].row.id, 999]);

      expect(await order(id), ['curl', 'bench', 'row']);
    });

    test('an exercise added afterwards still goes to the end', () async {
      final id = await sessions.startFreeSession(name: 'Free');
      await sessions.addExercises(id, ['bench', 'row']);
      final entries = await sessions.watchSessionExercises(id).first;
      await sessions.reorderExercises(id, [
        entries[1].row.id,
        entries[0].row.id,
      ]);

      await sessions.addExercises(id, ['curl']);

      expect(await order(id), ['row', 'bench', 'curl']);
    });

    test('does not reorder the plan', () async {
      await plans.addExerciseToDay(dayId, 'bench');
      await plans.addExerciseToDay(dayId, 'row');
      final id = await sessions.startSession(dayId: dayId, name: 'Push');
      final entries = await sessions.watchSessionExercises(id).first;

      await sessions.reorderExercises(id, [
        entries[1].row.id,
        entries[0].row.id,
      ]);

      final plan = await plans.watchDayExercises(dayId).first;
      expect(plan.map((p) => p.exercise.id), ['bench', 'row']);
    });
  });

  group('removing', () {
    test('takes an untouched exercise out of the workout', () async {
      final id = await sessions.startFreeSession(name: 'Free');
      await sessions.addExercises(id, ['bench', 'row']);
      final row = (await sessions.watchSessionExercises(id).first).last;

      expect(await sessions.removeExercise(row.row.id), isTrue);
      expect(await order(id), ['bench']);
    });

    test('refuses once sets are logged for it', () async {
      final id = await sessions.startFreeSession(name: 'Free');
      await sessions.addExercises(id, ['bench']);
      await logOne(id, 'bench');
      final bench = (await sessions.watchSessionExercises(id).first).single;

      expect(await sessions.removeExercise(bench.row.id), isFalse);
      expect(await order(id), ['bench']);
      expect(await sessions.watchSessionSets(id).first, hasLength(1));
    });
  });
}
