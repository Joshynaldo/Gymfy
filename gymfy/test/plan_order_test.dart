// The day builder's order and supersets, at the repository.
//
// Order is `position, id` since v26; supersets are a shared group number on
// neighbours. The repository keeps the stored groups tidy after every edit, so
// a group number never lingers on an exercise that no longer has a partner.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/workout/data/session_repository.dart';
import 'package:gymfy/features/workout/data/supersets.dart';
import 'package:gymfy/features/workout/data/workout_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';

void main() {
  late AppDatabase db;
  late WorkoutRepository plans;
  late int dayId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.customStatement('PRAGMA foreign_keys = ON');
    plans = WorkoutRepository(db);
    for (final id in ['a', 'b', 'c', 'd']) {
      await db
          .into(db.exercises)
          .insert(
            ExercisesCompanion.insert(
              id: id,
              name: id.toUpperCase(),
              muscleIds: const ['chest'],
            ),
          );
    }
    final splitId = await plans.createSplit('PPL');
    dayId = await plans.createDay(splitId, 'Push');
    await plans.addExercisesToDay(dayId, ['a', 'b', 'c', 'd']);
  });

  tearDown(() => db.close());

  Future<List<PlannedExercise>> day() => plans.watchDayExercises(dayId).first;

  Future<List<String>> names() async => [
    for (final p in await day()) p.exercise.id,
  ];

  /// The day as blocks, e.g. `[[a, b], [c], [d]]`.
  Future<List<List<String>>> blocks() async => [
    for (final block in supersetBlocks(
      await day(),
      (p) => p.entry.supersetGroup,
    ))
      [for (final p in block) p.exercise.id],
  ];

  Future<int> idOf(String exerciseId) async =>
      (await day()).firstWhere((p) => p.exercise.id == exerciseId).entry.id;

  group('order', () {
    test('a reorder writes the order given', () async {
      final ids = [for (final p in await day()) p.entry.id];

      await plans.reorderDayExercises(dayId, [ids[3], ids[0], ids[1], ids[2]]);

      expect(await names(), ['d', 'a', 'b', 'c']);
    });

    test(
      'a new exercise goes to the end, not above a reordered list',
      () async {
        // New rows used to land at position 0; once a reorder has numbered the
        // list 0..3, that would put them second.
        final ids = [for (final p in await day()) p.entry.id];
        await plans.reorderDayExercises(dayId, ids.reversed.toList());
        await db
            .into(db.exercises)
            .insert(
              ExercisesCompanion.insert(
                id: 'e',
                name: 'E',
                muscleIds: const ['chest'],
              ),
            );

        await plans.addExerciseToDay(dayId, 'e');

        expect(await names(), ['d', 'c', 'b', 'a', 'e']);
      },
    );

    test('a session started after a reorder follows it', () async {
      final ids = [for (final p in await day()) p.entry.id];
      await plans.reorderDayExercises(dayId, ids.reversed.toList());

      final sessions = SessionRepository(db);
      final id = await sessions.startSession(dayId: dayId, name: 'Push');

      final entries = await sessions.watchSessionExercises(id).first;
      expect(entries.map((e) => e.exercise.id), ['d', 'c', 'b', 'a']);
    });
  });

  group('supersets', () {
    test('two neighbours can be paired', () async {
      await plans.supersetWithNext(await idOf('a'));

      expect(await blocks(), [
        ['a', 'b'],
        ['c'],
        ['d'],
      ]);
    });

    test('pairing with the one above works the same', () async {
      await plans.supersetWithPrevious(await idOf('d'));

      expect(await blocks(), [
        ['a'],
        ['b'],
        ['c', 'd'],
      ]);
    });

    test('linking onto a pair makes a tri-set', () async {
      await plans.supersetWithNext(await idOf('a'));
      await plans.supersetWithPrevious(await idOf('c'));

      expect(await blocks(), [
        ['a', 'b', 'c'],
        ['d'],
      ]);
    });

    test('two separate supersets keep separate numbers', () async {
      await plans.supersetWithNext(await idOf('a'));
      await plans.supersetWithNext(await idOf('c'));

      final groups = [for (final p in await day()) p.entry.supersetGroup];
      expect(groups[0], groups[1]);
      expect(groups[2], groups[3]);
      expect(groups[0], isNot(groups[2]));
    });

    test('the last exercise has no next to pair with', () async {
      await plans.supersetWithNext(await idOf('d'));

      expect(await blocks(), [
        ['a'],
        ['b'],
        ['c'],
        ['d'],
      ]);
    });

    test('leaving a pair leaves the partner standalone', () async {
      await plans.supersetWithNext(await idOf('a'));

      await plans.leaveSuperset(await idOf('b'));

      final groups = [for (final p in await day()) p.entry.supersetGroup];
      expect(groups, [null, null, null, null]);
    });

    test('removing a partner leaves the survivor standalone', () async {
      await plans.supersetWithNext(await idOf('a'));

      await plans.removePlannedExercise(await idOf('a'));

      expect((await day()).first.entry.supersetGroup, isNull);
    });

    test('dragging a member away breaks the pair cleanly', () async {
      // Without the tidy-up, a stays numbered and would quietly rejoin b the
      // next time they were dragged back together.
      await plans.supersetWithNext(await idOf('a'));
      final ids = [for (final p in await day()) p.entry.id];

      await plans.reorderDayExercises(dayId, [ids[1], ids[2], ids[0], ids[3]]);

      expect(await names(), ['b', 'c', 'a', 'd']);
      final groups = [for (final p in await day()) p.entry.supersetGroup];
      expect(groups, [null, null, null, null]);
    });

    test('a running session reads the grouping from its plan slots', () async {
      await plans.supersetWithNext(await idOf('a'));
      final sessions = SessionRepository(db);
      final id = await sessions.startSession(dayId: dayId, name: 'Push');
      final entries = await sessions.watchSessionExercises(id).first;

      expect(restsAfter(entries, entries[0], (e) => e.supersetGroup), isFalse);
      expect(restsAfter(entries, entries[1], (e) => e.supersetGroup), isTrue);
      expect(restsAfter(entries, entries[2], (e) => e.supersetGroup), isTrue);
    });
  });
}
