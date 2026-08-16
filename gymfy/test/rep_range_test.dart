// Rep ranges: how they read, and the rule that keeps a "range" from being a
// fixed number in disguise.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/workout/data/workout_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';
import 'package:gymfy/shared/utils/format.dart';

void main() {
  group('formatRepTarget', () {
    test('a fixed target is just the number', () {
      expect(formatRepTarget(10, null), '10');
    });

    test('a range uses an en dash', () {
      // Not a hyphen: at small text sizes a hyphen reads as a minus sign.
      expect(formatRepTarget(8, 12), '8–12');
    });

    test('a max equal to the minimum is not a range', () {
      // "8–8" is a fixed 8 wearing a costume.
      expect(formatRepTarget(8, 8), '8');
    });

    test('a max below the minimum is not a range either', () {
      expect(formatRepTarget(8, 5), '8');
    });
  });

  group('formatSetTarget', () {
    test('reads as sets × reps', () {
      expect(formatSetTarget(3, 10, null), '3 × 10');
      expect(formatSetTarget(3, 8, 12), '3 × 8–12');
    });
  });

  group('storing a rep range', () {
    late AppDatabase db;
    late WorkoutRepository repo;
    late int entryId;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = WorkoutRepository(db);
      final splitId = await repo.createSplit('PPL');
      final dayId = await repo.createDay(splitId, 'Push');
      await db.into(db.exercises).insert(
        ExercisesCompanion.insert(
          id: 'barbell_bench_press',
          name: 'Barbell Bench Press',
          muscleIds: const ['chest'],
        ),
      );
      await repo.addExercisesToDay(dayId, ['barbell_bench_press']);
      entryId = (await repo.watchDayExercises(dayId).first).single.entry.id;
    });

    tearDown(() async {
      await db.close();
    });

    Future<WorkoutExercise> entry() async {
      return (await db.select(db.workoutExercises).get()).single;
    }

    test('a newly added exercise has no range', () async {
      final row = await entry();
      expect(row.defaultReps, 10);
      expect(row.defaultRepsMax, isNull);
    });

    test('a range is stored as both ends', () async {
      await repo.updatePlannedExercise(entryId, sets: 4, reps: 8, repsMax: 12);

      final row = await entry();
      expect(row.defaultSets, 4);
      expect(row.defaultReps, 8);
      expect(row.defaultRepsMax, 12);
    });

    test('a max equal to the minimum is stored as no range', () async {
      await repo.updatePlannedExercise(entryId, sets: 3, reps: 8, repsMax: 8);

      // Normalised on the way in, so no display anywhere has to handle "8–8".
      expect((await entry()).defaultRepsMax, isNull);
    });

    test('a backwards range is stored as no range', () async {
      await repo.updatePlannedExercise(entryId, sets: 3, reps: 10, repsMax: 6);

      expect((await entry()).defaultRepsMax, isNull);
    });

    test('a range can be turned back into a fixed target', () async {
      await repo.updatePlannedExercise(entryId, sets: 3, reps: 8, repsMax: 12);

      await repo.updatePlannedExercise(entryId, sets: 3, reps: 10);

      // The old max has to be cleared, not left behind — otherwise switching
      // the range off would leave a stale top end in the database.
      final row = await entry();
      expect(row.defaultReps, 10);
      expect(row.defaultRepsMax, isNull);
    });
  });
}
