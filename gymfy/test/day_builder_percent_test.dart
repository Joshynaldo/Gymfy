// The percentage-of-1RM field in the day builder's sets & reps dialog.

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/workout/data/workout_repository.dart';
import 'package:gymfy/features/workout/screens/day_builder_screen.dart';
import 'package:gymfy/shared/database/app_database.dart';

import 'support/default_accent.dart';

void main() {
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
    final splitId = await repo.createSplit('Strength');
    dayId = await repo.createDay(splitId, 'Squat');

    await db
        .into(db.exercises)
        .insert(
          ExercisesCompanion.insert(
            id: 'barbell_back_squat',
            name: 'Back Squat',
            muscleIds: const ['quads'],
          ),
        );
    await db
        .into(db.exercises)
        .insert(
          ExercisesCompanion.insert(
            id: 'plank',
            name: 'Plank',
            muscleIds: const ['abs'],
            isTimed: const Value(true),
          ),
        );
    await repo.addExercisesToDay(dayId, ['barbell_back_squat', 'plank']);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(() => pumpEventQueue());
    await tester.pump();
  }

  Future<void> openDialog(WidgetTester tester, String on) async {
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: DayBuilderScreen(dayId: dayId)),
      ),
    );
    await settle(tester);

    await tester.tap(find.text(on));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<double?> storedPercent(WidgetTester tester, String exerciseId) async {
    final rows = (await tester.runAsync(
      () => repo.watchDayExercises(dayId).first,
    ))!;
    return rows
        .firstWhere((p) => p.exercise.id == exerciseId)
        .entry
        .targetPercent;
  }

  testWidgets('picking a percentage saves it on that exercise', (tester) async {
    await openDialog(tester, 'Back Squat');

    expect(find.text('% of 1RM'), findsOneWidget);
    await tester.ensureVisible(find.text('75%'));
    await tester.tap(find.text('75%'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await settle(tester);

    expect(await storedPercent(tester, 'barbell_back_squat'), 75);
    // Say-what-it-does on the row, once the list has caught up.
    await settle(tester);
    expect(find.textContaining('@ 75% 1RM'), findsOneWidget);
  });

  testWidgets('"Save to all" leaves the other exercises\' percentage alone', (
    tester,
  ) async {
    await openDialog(tester, 'Back Squat');

    await tester.ensureVisible(find.text('80%'));
    await tester.tap(find.text('80%'));
    await tester.pump();
    await tester.tap(find.text('Save to all 2'));
    await settle(tester);

    expect(await storedPercent(tester, 'barbell_back_squat'), 80);
    expect(await storedPercent(tester, 'plank'), isNull);
  });

  testWidgets('Off clears a stored percentage', (tester) async {
    // Inside runAsync: the database is genuinely asynchronous, and a bare
    // await on it under the widget test's fake clock never returns.
    await tester.runAsync(() async {
      final id = (await repo.watchDayExercises(dayId).first)
          .firstWhere((p) => p.exercise.id == 'barbell_back_squat')
          .entry
          .id;
      await (db.update(db.workoutExercises)..where((t) => t.id.equals(id)))
          .write(const WorkoutExercisesCompanion(targetPercent: Value(72.5)));
    });

    await openDialog(tester, 'Back Squat');
    // A value with no chip of its own still shows as chosen.
    expect(find.text('72.5%'), findsOneWidget);

    await tester.ensureVisible(find.text('Off'));
    await tester.tap(find.text('Off'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await settle(tester);

    expect(await storedPercent(tester, 'barbell_back_squat'), isNull);
  });

  testWidgets('a timed exercise is not offered a percentage', (tester) async {
    await openDialog(tester, 'Plank');
    expect(find.text('% of 1RM'), findsNothing);
  });
}
