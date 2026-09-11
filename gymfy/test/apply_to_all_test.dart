// "Apply to every exercise" in the day builder's sets & reps dialog.
//
// The shortcut for the case the per-exercise dialog serves worst: a whole day
// built on 3×8, edited one row at a time. It is also the only edit on that
// screen that changes rows you are not looking at, so what it touches — and
// what it leaves alone — is worth pinning down.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/workout/data/workout_repository.dart';
import 'package:gymfy/features/workout/screens/day_builder_screen.dart';
import 'package:gymfy/shared/database/app_database.dart';

import 'support/default_accent.dart';

/// Seeds [count] exercises into the library and plans them all into [dayId].
Future<void> _plan(
  AppDatabase db,
  WorkoutRepository repo,
  int dayId,
  int count,
) async {
  final ids = <String>[];
  for (var i = 0; i < count; i++) {
    final id = 'exercise_$i';
    ids.add(id);
    await db
        .into(db.exercises)
        .insert(
          ExercisesCompanion.insert(
            id: id,
            name: 'Exercise $i',
            muscleIds: const ['chest'],
          ),
        );
  }
  await repo.addExercisesToDay(dayId, ids);
}

void main() {
  group('updateAllPlannedExercises', () {
    late AppDatabase db;
    late WorkoutRepository repo;
    late int dayId;
    late int otherDayId;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = WorkoutRepository(db);
      final splitId = await repo.createSplit('PPL');
      dayId = await repo.createDay(splitId, 'Push');
      otherDayId = await repo.createDay(splitId, 'Pull');

      await _plan(db, repo, dayId, 3);
      // One exercise on a different day, to prove the update is scoped.
      await repo.addExercisesToDay(otherDayId, ['exercise_0']);
      final other = (await repo.watchDayExercises(otherDayId).first).single;
      await repo.updatePlannedExercise(other.entry.id, sets: 9, reps: 9);
    });

    tearDown(() async => db.close());

    Future<List<WorkoutExercise>> entriesOf(int day) {
      return (db.select(
        db.workoutExercises,
      )..where((t) => t.dayId.equals(day))).get();
    }

    test('writes the same targets to every exercise in the day', () async {
      final changed = await repo.updateAllPlannedExercises(
        dayId,
        sets: 4,
        reps: 8,
        repsMax: 12,
        warmupSets: 2,
      );

      expect(changed, 3);
      for (final entry in await entriesOf(dayId)) {
        expect(entry.defaultSets, 4);
        expect(entry.defaultReps, 8);
        expect(entry.defaultRepsMax, 12);
        expect(entry.warmupSets, 2);
      }
    });

    test('leaves other days alone', () async {
      // The dialog is opened from one day. Rewriting a whole split from it
      // would be a genuinely destructive surprise.
      await repo.updateAllPlannedExercises(dayId, sets: 4, reps: 8);

      final other = (await entriesOf(otherDayId)).single;
      expect(other.defaultSets, 9);
      expect(other.defaultReps, 9);
    });

    test(
      'a max at or below the minimum is dropped, not stored backwards',
      () async {
        // Same rule as the single-row update, restated because this is a
        // separate SQL statement and could drift from it.
        await repo.updateAllPlannedExercises(
          dayId,
          sets: 3,
          reps: 10,
          repsMax: 10,
        );

        for (final entry in await entriesOf(dayId)) {
          expect(entry.defaultRepsMax, isNull);
        }
      },
    );

    test('clears a range that was there before', () async {
      await repo.updateAllPlannedExercises(
        dayId,
        sets: 3,
        reps: 8,
        repsMax: 12,
      );
      await repo.updateAllPlannedExercises(dayId, sets: 3, reps: 8);

      for (final entry in await entriesOf(dayId)) {
        expect(entry.defaultRepsMax, isNull);
      }
    });

    test('a negative warm-up count is floored at zero', () async {
      // "Warm-up 1 of -1" would be nonsense on the session card.
      await repo.updateAllPlannedExercises(
        dayId,
        sets: 3,
        reps: 8,
        warmupSets: -2,
      );

      for (final entry in await entriesOf(dayId)) {
        expect(entry.warmupSets, 0);
      }
    });

    test('an empty day changes nothing and does not throw', () async {
      final splitId = await repo.createSplit('Other');
      final empty = await repo.createDay(splitId, 'Legs');

      expect(await repo.updateAllPlannedExercises(empty, sets: 3, reps: 8), 0);
    });
  });

  group('the dialog', () {
    late AppDatabase db;
    late WorkoutRepository repo;
    late ProviderContainer container;
    late int dayId;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = WorkoutRepository(db);
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          ...defaultDisplayOverrides,
        ],
      );
      final splitId = await repo.createSplit('PPL');
      dayId = await repo.createDay(splitId, 'Push');
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    Future<void> openDialog(
      WidgetTester tester, {
      String on = 'Exercise 0',
    }) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: DayBuilderScreen(dayId: dayId)),
        ),
      );
      // A real database, so the list arrives asynchronously — but drift's
      // cleanup timer means pumpAndSettle would never return.
      await tester.runAsync(() => pumpEventQueue());
      await tester.pump();

      await tester.tap(find.text(on));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    /// The stored targets, in the order the day lists them.
    ///
    /// Read inside [WidgetTester.runAsync]: the database work is genuinely
    /// asynchronous and `testWidgets` fakes the clock, so a bare await on a
    /// drift stream inside a widget test simply never returns.
    Future<List<({int sets, int reps})>> targets(WidgetTester tester) async {
      final rows = await tester.runAsync(
        () => repo.watchDayExercises(dayId).first,
      );
      return [
        for (final row in rows!)
          (sets: row.entry.defaultSets, reps: row.entry.defaultReps),
      ];
    }

    /// Settles the writes a dialog button kicked off.
    Future<void> settle(WidgetTester tester) async {
      await tester.runAsync(() => pumpEventQueue());
      await tester.pump();
    }

    testWidgets('offers a second button naming how many it covers', (
      tester,
    ) async {
      await _plan(db, repo, dayId, 3);
      await openDialog(tester);

      // The count is on the button because this is the one action here that
      // changes rows you cannot see.
      expect(find.widgetWithText(TextButton, 'Save to all 3'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Save'), findsOneWidget);
    });

    testWidgets('a one-exercise day gets no second button', (tester) async {
      // It would do exactly what Save does, and only raise a moment's doubt
      // about the difference.
      await _plan(db, repo, dayId, 1);
      await openDialog(tester);

      expect(find.textContaining('Save to all'), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Save'), findsOneWidget);
    });

    testWidgets('Save to all writes the targets to every exercise', (
      tester,
    ) async {
      await _plan(db, repo, dayId, 3);
      // Give one row targets of its own, so "they all changed" cannot pass by
      // them having been identical to begin with.
      final rows = (await tester.runAsync(
        () => repo.watchDayExercises(dayId).first,
      ))!;
      await tester.runAsync(
        () => repo.updatePlannedExercise(rows[1].entry.id, sets: 7, reps: 15),
      );

      await openDialog(tester);
      await tester.tap(find.text('Save to all 3'));
      await settle(tester);

      final after = await targets(tester);
      expect(after, hasLength(3));
      // Whatever the wheels opened on, all three now agree.
      expect(after.toSet(), hasLength(1));
    });

    testWidgets('plain Save leaves the other exercises alone', (tester) async {
      await _plan(db, repo, dayId, 3);
      final rows = (await tester.runAsync(
        () => repo.watchDayExercises(dayId).first,
      ))!;
      await tester.runAsync(
        () => repo.updatePlannedExercise(rows[1].entry.id, sets: 7, reps: 15),
      );

      await openDialog(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await settle(tester);

      // The row that was different is still different — the whole point of
      // having two buttons rather than one.
      final after = await targets(tester);
      expect(after[1], (sets: 7, reps: 15));
    });

    testWidgets('Cancel writes nothing at all', (tester) async {
      await _plan(db, repo, dayId, 3);
      final before = await targets(tester);

      await openDialog(tester);
      await tester.tap(find.text('Cancel'));
      await settle(tester);

      expect(await targets(tester), before);
    });
  });
}
