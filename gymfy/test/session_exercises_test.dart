// A session's running order (schema v26): copied from the plan at start, owned
// by the session afterwards, and empty for a free workout.

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/exercises/data/exercise_repository.dart';
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
    // Cascades and set-null only fire with foreign keys on, which the real
    // connection does in beforeOpen.
    await db.customStatement('PRAGMA foreign_keys = ON');
    sessions = SessionRepository(db);
    plans = WorkoutRepository(db);
    for (final (id, name) in [
      ('barbell_bench_press', 'Barbell Bench Press'),
      ('barbell_row', 'Barbell Row'),
      ('dumbbell_curl', 'Dumbbell Curl'),
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

  test('starting a day copies its plan into the session, in order', () async {
    await plans.addExerciseToDay(dayId, 'barbell_row', sets: 4);
    await plans.addExerciseToDay(dayId, 'barbell_bench_press');
    // Position outranks insertion order: the bench was moved to the top.
    final bench = (await plans.watchDayExercises(dayId).first).last.entry;
    await (db.update(db.workoutExercises)..where((t) => t.id.equals(bench.id)))
        .write(const WorkoutExercisesCompanion(position: Value(-1)));

    final id = await sessions.startSession(dayId: dayId, name: 'Push');
    final entries = await sessions.watchSessionExercises(id).first;

    expect(entries.map((e) => e.exercise.id), [
      'barbell_bench_press',
      'barbell_row',
    ]);
    expect(entries.map((e) => e.row.position), [0, 1]);
    // Each entry carries its plan slot, so the targets come along.
    expect(entries.last.planned?.defaultSets, 4);
  });

  test('the plan list follows position, then insertion order', () async {
    await plans.addExerciseToDay(dayId, 'barbell_row');
    await plans.addExerciseToDay(dayId, 'barbell_bench_press');
    final before = await plans.watchDayExercises(dayId).first;
    expect(before.map((p) => p.exercise.id), [
      'barbell_row',
      'barbell_bench_press',
    ]);

    await (db.update(db.workoutExercises)
          ..where((t) => t.id.equals(before.first.entry.id)))
        .write(const WorkoutExercisesCompanion(position: Value(5)));

    final after = await plans.watchDayExercises(dayId).first;
    expect(after.map((p) => p.exercise.id), [
      'barbell_bench_press',
      'barbell_row',
    ]);
  });

  test('a free workout has no day and an empty running order', () async {
    final id = await sessions.startFreeSession(name: '  Free workout ');

    final session = await sessions.watchSession(id).first;
    expect(session!.dayId, isNull);
    expect(session.name, 'Free workout');
    expect(await sessions.watchSessionExercises(id).first, isEmpty);
  });

  test('an added exercise has no plan slot', () async {
    final id = await sessions.startFreeSession(name: 'Free');
    await db
        .into(db.sessionExercises)
        .insert(
          SessionExercisesCompanion.insert(
            sessionId: id,
            exerciseId: 'dumbbell_curl',
          ),
        );

    final entry = (await sessions.watchSessionExercises(id).first).single;
    expect(entry.exercise.name, 'Dumbbell Curl');
    expect(entry.planned, isNull);
  });

  test('deleting the plan slot keeps the exercise in the session', () async {
    await plans.addExerciseToDay(dayId, 'barbell_row');
    final id = await sessions.startSession(dayId: dayId, name: 'Push');
    final slot = (await plans.watchDayExercises(dayId).first).single.entry;

    await plans.removePlannedExercise(slot.id);

    final entry = (await sessions.watchSessionExercises(id).first).single;
    expect(entry.exercise.id, 'barbell_row');
    expect(entry.row.workoutExerciseId, isNull);
    expect(entry.planned, isNull);
  });

  test('deleting the session takes its running order with it', () async {
    await plans.addExerciseToDay(dayId, 'barbell_row');
    final id = await sessions.startSession(dayId: dayId, name: 'Push');

    await sessions.deleteSession(id);

    expect(await db.select(db.sessionExercises).get(), isEmpty);
  });

  test(
    'a custom exercise in a running order is archived, not deleted',
    () async {
      // The foreign key would reject the delete; archiving is the existing
      // answer for an exercise something still points at.
      final exercises = ExerciseRepository(db);
      await db
          .into(db.exercises)
          .insert(
            ExercisesCompanion.insert(
              id: 'custom_sled_push',
              name: 'Sled Push',
              muscleIds: const ['quads'],
              isCustom: const Value(true),
            ),
          );
      final id = await sessions.startFreeSession(name: 'Free');
      await db
          .into(db.sessionExercises)
          .insert(
            SessionExercisesCompanion.insert(
              sessionId: id,
              exerciseId: 'custom_sled_push',
            ),
          );

      final sled = await (db.select(
        db.exercises,
      )..where((t) => t.id.equals('custom_sled_push'))).getSingle();
      expect(await exercises.deleteCustom(sled), isTrue);
    },
  );
}
