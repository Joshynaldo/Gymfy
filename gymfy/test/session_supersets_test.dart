// Supersets made during a workout (schema v28): a session's running order
// carries its own superset groups, copied from the plan at the start and
// edited without touching the plan — unless the user saves the change to it.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/workout/data/session_repository.dart';
import 'package:gymfy/features/workout/data/workout_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';

const _bench = 'barbell_bench_press';
const _row = 'barbell_row';
const _curl = 'dumbbell_curl';
const _pushdown = 'triceps_pushdown';

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
      (_bench, 'Barbell Bench Press'),
      (_row, 'Barbell Row'),
      (_curl, 'Dumbbell Curl'),
      (_pushdown, 'Triceps Pushdown'),
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
    final splitId = await plans.createSplit('Upper');
    dayId = await plans.createDay(splitId, 'Upper');
  });

  tearDown(() => db.close());

  Future<List<SessionExerciseEntry>> entriesOf(int sessionId) =>
      sessions.watchSessionExercises(sessionId).first;

  /// The session's blocks as exercise ids: a superset is one inner list.
  Future<List<List<String>>> blocksOf(int sessionId) async {
    final entries = await entriesOf(sessionId);
    final blocks = <List<String>>[];
    int? open;
    for (final e in entries) {
      final group = e.supersetGroup;
      if (group != null && group == open) {
        blocks.last.add(e.exercise.id);
      } else {
        blocks.add([e.exercise.id]);
      }
      open = group;
    }
    return blocks;
  }

  Future<int> entryId(int sessionId, String exerciseId) async =>
      (await entriesOf(
        sessionId,
      )).firstWhere((e) => e.exercise.id == exerciseId).row.id;

  Future<List<int?>> planGroups() async => [
    for (final p in await plans.watchDayExercises(dayId).first)
      p.entry.supersetGroup,
  ];

  /// A free workout with [ids] added in order.
  Future<int> freeWorkout(List<String> ids) async {
    final id = await sessions.startFreeSession(name: 'Free workout');
    await sessions.addExercises(id, ids);
    return id;
  }

  group('starting a day', () {
    test('copies the plan\'s supersets into the session', () async {
      for (final id in [_bench, _row, _curl]) {
        await plans.addExerciseToDay(dayId, id);
      }
      final bench = (await plans.watchDayExercises(dayId).first).first;
      await plans.supersetWithNext(bench.entry.id);

      final sessionId = await sessions.startSession(dayId: dayId, name: 'U');

      expect(await blocksOf(sessionId), [
        [_bench, _row],
        [_curl],
      ]);
    });

    test('later plan edits leave a running workout alone', () async {
      for (final id in [_bench, _row]) {
        await plans.addExerciseToDay(dayId, id);
      }
      final sessionId = await sessions.startSession(dayId: dayId, name: 'U');

      final bench = (await plans.watchDayExercises(dayId).first).first;
      await plans.supersetWithNext(bench.entry.id);

      expect(await blocksOf(sessionId), [
        [_bench],
        [_row],
      ]);
    });
  });

  group('during a workout', () {
    test('a free workout can superset neighbours', () async {
      final sessionId = await freeWorkout([_bench, _row, _curl]);

      await sessions.supersetWithNext(await entryId(sessionId, _bench));

      expect(await blocksOf(sessionId), [
        [_bench, _row],
        [_curl],
      ]);
    });

    test('with the one before works the same way', () async {
      final sessionId = await freeWorkout([_bench, _row, _curl]);

      await sessions.supersetWithPrevious(await entryId(sessionId, _curl));

      expect(await blocksOf(sessionId), [
        [_bench],
        [_row, _curl],
      ]);
    });

    test('an exercise added mid-workout can join a planned one', () async {
      await plans.addExerciseToDay(dayId, _bench);
      final sessionId = await sessions.startSession(dayId: dayId, name: 'U');
      await sessions.addExercises(sessionId, [_pushdown]);

      await sessions.supersetWithPrevious(await entryId(sessionId, _pushdown));

      expect(await blocksOf(sessionId), [
        [_bench, _pushdown],
      ]);
    });

    test('joining onto a pair makes a tri-set', () async {
      final sessionId = await freeWorkout([_bench, _row, _curl]);
      await sessions.supersetWithNext(await entryId(sessionId, _bench));

      await sessions.supersetWithNext(await entryId(sessionId, _row));

      expect(await blocksOf(sessionId), [
        [_bench, _row, _curl],
      ]);
    });

    test('the first or last entry has no neighbour to join', () async {
      final sessionId = await freeWorkout([_bench, _row]);

      await sessions.supersetWithPrevious(await entryId(sessionId, _bench));
      await sessions.supersetWithNext(await entryId(sessionId, _row));

      expect(await blocksOf(sessionId), [
        [_bench],
        [_row],
      ]);
    });

    test('leaving a pair leaves both standing alone', () async {
      final sessionId = await freeWorkout([_bench, _row]);
      await sessions.supersetWithNext(await entryId(sessionId, _bench));

      await sessions.leaveSuperset(await entryId(sessionId, _row));

      final entries = await entriesOf(sessionId);
      expect(entries.map((e) => e.supersetGroup), [null, null]);
    });

    test('taking the middle out of a tri-set parts the other two', () async {
      final sessionId = await freeWorkout([_bench, _row, _curl]);
      await sessions.supersetWithNext(await entryId(sessionId, _bench));
      await sessions.supersetWithNext(await entryId(sessionId, _row));

      await sessions.leaveSuperset(await entryId(sessionId, _row));

      final entries = await entriesOf(sessionId);
      expect(entries.map((e) => e.supersetGroup), [null, null, null]);
    });

    test('reordering a partner away ends the superset', () async {
      final sessionId = await freeWorkout([_bench, _row, _curl]);
      await sessions.supersetWithNext(await entryId(sessionId, _bench));

      // Curl between them: bench and row no longer touch.
      await sessions.reorderExercises(sessionId, [
        await entryId(sessionId, _bench),
        await entryId(sessionId, _curl),
        await entryId(sessionId, _row),
      ]);

      final entries = await entriesOf(sessionId);
      expect(entries.map((e) => e.supersetGroup), [null, null, null]);
    });

    test('removing a partner leaves the other standing alone', () async {
      final sessionId = await freeWorkout([_bench, _row]);
      await sessions.supersetWithNext(await entryId(sessionId, _bench));

      expect(
        await sessions.removeExercise(await entryId(sessionId, _row)),
        true,
      );

      final entries = await entriesOf(sessionId);
      expect(entries.single.supersetGroup, isNull);
    });

    test('swapping keeps the replacement in the superset', () async {
      final sessionId = await freeWorkout([_bench, _row]);
      await sessions.supersetWithNext(await entryId(sessionId, _bench));

      await sessions.swapExercise(
        sessionExerciseId: await entryId(sessionId, _row),
        exerciseId: _curl,
      );

      expect(await blocksOf(sessionId), [
        [_bench, _curl],
      ]);
    });

    test(
      'a swapped-out exercise with sets stays out of the superset',
      () async {
        final sessionId = await freeWorkout([_bench, _row]);
        await sessions.supersetWithNext(await entryId(sessionId, _bench));
        await sessions.logSet(
          sessionId: sessionId,
          exerciseId: _row,
          setNumber: 1,
          weight: 60,
          reps: 8,
        );

        await sessions.swapExercise(
          sessionExerciseId: await entryId(sessionId, _row),
          exerciseId: _curl,
        );

        // The row's sets keep it in the list, just before the curl, on its
        // own — so bench and curl no longer touch either.
        expect(await blocksOf(sessionId), [
          [_bench],
          [_row],
          [_curl],
        ]);
      },
    );

    test('none of it touches the plan', () async {
      for (final id in [_bench, _row]) {
        await plans.addExerciseToDay(dayId, id);
      }
      final sessionId = await sessions.startSession(dayId: dayId, name: 'U');

      await sessions.supersetWithNext(await entryId(sessionId, _bench));

      expect(await planGroups(), [null, null]);
    });
  });

  group('saving to the plan', () {
    test('joins two neighbours in the plan', () async {
      for (final id in [_bench, _row, _curl]) {
        await plans.addExerciseToDay(dayId, id);
      }
      final slots = await plans.watchDayExercises(dayId).first;

      final saved = await plans.supersetPlannedPair(
        slots[1].entry.id,
        slots[0].entry.id,
      );

      expect(saved, isTrue);
      expect(await planGroups(), [1, 1, null]);
    });

    test('refuses two the plan keeps apart', () async {
      // Neighbours in a reordered workout, but not in the plan: joining them
      // would superset the row standing between them.
      for (final id in [_bench, _row, _curl]) {
        await plans.addExerciseToDay(dayId, id);
      }
      final slots = await plans.watchDayExercises(dayId).first;

      final saved = await plans.supersetPlannedPair(
        slots[0].entry.id,
        slots[2].entry.id,
      );

      expect(saved, isFalse);
      expect(await planGroups(), [null, null, null]);
    });

    test('refuses slots from two different days', () async {
      final splitId = await plans.createSplit('Lower');
      final otherDay = await plans.createDay(splitId, 'Lower');
      await plans.addExerciseToDay(dayId, _bench);
      await plans.addExerciseToDay(otherDay, _row);
      final mine = (await plans.watchDayExercises(dayId).first).single;
      final theirs = (await plans.watchDayExercises(otherDay).first).single;

      expect(
        await plans.supersetPlannedPair(mine.entry.id, theirs.entry.id),
        isFalse,
      );
    });
  });
}
