// Adding several exercises to a workout day at once: the target list the picker
// shows, and what happens when some of the selection is already planned.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/workout/data/workout_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';

void main() {
  late AppDatabase db;
  late WorkoutRepository repo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = WorkoutRepository(db);
    await db.into(db.exercises).insert(
      ExercisesCompanion.insert(
        id: 'barbell_bench_press',
        name: 'Barbell Bench Press',
        muscleIds: const ['chest'],
      ),
    );
    await db.into(db.exercises).insert(
      ExercisesCompanion.insert(
        id: 'push_up',
        name: 'Push-Up',
        muscleIds: const ['chest'],
      ),
    );
    await db.into(db.exercises).insert(
      ExercisesCompanion.insert(
        id: 'pull_up',
        name: 'Pull-Up',
        muscleIds: const ['lats'],
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('watchAllDays', () {
    test('is empty when no splits exist yet', () async {
      // The picker leans on this to show its "create a split first" state.
      expect(await repo.watchAllDays().first, isEmpty);
    });

    test('carries the split along with each day', () async {
      final splitId = await repo.createSplit('PPL');
      await repo.createDay(splitId, 'Push');
      await repo.createDay(splitId, 'Pull');

      final days = await repo.watchAllDays().first;
      expect(days.map((d) => d.day.name), ['Push', 'Pull']);
      // Day names repeat across splits, so the split name has to travel with
      // them or the picker can't tell two "Push" days apart.
      expect(days.every((d) => d.split.name == 'PPL'), isTrue);
    });

    test('groups days by split, newest split first', () async {
      final older = await repo.createSplit('Full Body');
      await repo.createDay(older, 'A');
      final newer = await repo.createSplit('PPL');
      await repo.createDay(newer, 'Push');
      await repo.createDay(newer, 'Pull');

      final days = await repo.watchAllDays().first;
      expect(days.map((d) => d.split.name), ['PPL', 'PPL', 'Full Body']);
      expect(days.map((d) => d.day.name), ['Push', 'Pull', 'A']);
    });
  });

  group('addExercisesToDay', () {
    late int dayId;

    setUp(() async {
      final splitId = await repo.createSplit('PPL');
      dayId = await repo.createDay(splitId, 'Push');
    });

    Future<List<String>> plannedIds() async {
      final planned = await repo.watchDayExercises(dayId).first;
      return planned.map((p) => p.entry.exerciseId).toList();
    }

    test('adds every exercise in one go', () async {
      final added = await repo.addExercisesToDay(dayId, [
        'barbell_bench_press',
        'push_up',
      ]);

      expect(added, 2);
      expect(await plannedIds(), ['barbell_bench_press', 'push_up']);
    });

    test('skips exercises already in the day', () async {
      await repo.addExercisesToDay(dayId, ['barbell_bench_press']);

      final added = await repo.addExercisesToDay(dayId, [
        'barbell_bench_press',
        'push_up',
      ]);

      // Selecting three when one is already planned should leave one of each,
      // not a stray duplicate to notice and remove later.
      expect(added, 1);
      expect(await plannedIds(), ['barbell_bench_press', 'push_up']);
    });

    test('adding only duplicates changes nothing and reports zero', () async {
      await repo.addExercisesToDay(dayId, ['barbell_bench_press']);

      expect(await repo.addExercisesToDay(dayId, ['barbell_bench_press']), 0);
      expect(await plannedIds(), ['barbell_bench_press']);
    });

    test('the same exercise can be in two different days', () async {
      final otherDay = await repo.createDay(
        (await repo.watchSplits().first).single.id,
        'Pull',
      );

      await repo.addExercisesToDay(dayId, ['barbell_bench_press']);
      final added = await repo.addExercisesToDay(otherDay, [
        'barbell_bench_press',
      ]);

      // Skipping is per-day: a bench press in Push must not block one in Pull.
      expect(added, 1);
    });

    test('new entries get the usual default sets and reps', () async {
      await repo.addExercisesToDay(dayId, ['barbell_bench_press']);

      final planned = (await repo.watchDayExercises(dayId).first).single;
      expect(planned.entry.defaultSets, 3);
      expect(planned.entry.defaultReps, 10);
    });
  });
}
