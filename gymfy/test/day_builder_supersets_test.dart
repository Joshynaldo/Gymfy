// The day builder's superset and reorder controls.
//
// The grouping rules and the tidy-up after each edit are in
// plan_order_test.dart; this covers what the screen shows and which edit each
// control asks for.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/workout/data/workout_repository.dart';
import 'package:gymfy/features/workout/screens/day_builder_screen.dart';
import 'package:gymfy/shared/database/app_database.dart';

import 'support/default_accent.dart';

const _dayId = 10;

final _day = WorkoutDay(id: _dayId, splitId: 1, name: 'Push', position: 0);

Exercise _exercise(String id, String name) => Exercise(
  id: id,
  name: name,
  muscleIds: const ['chest'],
  isPlateLoaded: false,
  isCustom: false,
  isArchived: false,
  isTimed: false,
  equipment: 'other',
);

PlannedExercise _planned(String id, String name, int position, {int? group}) =>
    PlannedExercise(
      entry: WorkoutExercise(
        id: position + 1,
        dayId: _dayId,
        exerciseId: id,
        position: position,
        defaultSets: 3,
        defaultReps: 10,
        warmupSets: 0,
        supersetGroup: group,
      ),
      exercise: _exercise(id, name),
    );

class _RecordingPlans extends WorkoutRepository {
  _RecordingPlans(super.db);

  final calls = <String>[];
  final orders = <List<int>>[];

  @override
  Future<void> supersetWithNext(int id) async => calls.add('next $id');

  @override
  Future<void> supersetWithPrevious(int id) async => calls.add('previous $id');

  @override
  Future<void> leaveSuperset(int id) async => calls.add('leave $id');

  @override
  Future<void> reorderDayExercises(int dayId, List<int> orderedIds) async =>
      orders.add(orderedIds);
}

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<_RecordingPlans> pump(
    WidgetTester tester,
    List<PlannedExercise> planned,
  ) async {
    tester.view.physicalSize = const Size(420, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final plans = _RecordingPlans(db);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...defaultDisplayOverrides,
          workoutRepositoryProvider.overrideWithValue(plans),
          dayProvider.overrideWith((ref, id) => Stream.value(_day)),
          dayExercisesProvider.overrideWith(
            (ref, dayId) => Stream.value(planned),
          ),
        ],
        child: const MaterialApp(home: DayBuilderScreen(dayId: _dayId)),
      ),
    );
    await tester.pumpAndSettle();
    return plans;
  }

  testWidgets('a superset is labelled once, over its first exercise', (
    tester,
  ) async {
    await pump(tester, [
      _planned('bench', 'Bench press', 0, group: 1),
      _planned('row', 'Cable row', 1, group: 1),
      _planned('fly', 'Cable fly', 2),
    ]);

    expect(find.text('SUPERSET · REST AFTER THE LAST'), findsOneWidget);
  });

  testWidgets('a lone group number is not a superset', (tester) async {
    // Members must be neighbours: one stray number is just an exercise.
    await pump(tester, [
      _planned('bench', 'Bench press', 0, group: 1),
      _planned('fly', 'Cable fly', 1),
    ]);

    expect(find.textContaining('SUPERSET'), findsNothing);
  });

  testWidgets('the first exercise can only pair with the one below', (
    tester,
  ) async {
    final plans = await pump(tester, [
      _planned('bench', 'Bench press', 0),
      _planned('row', 'Cable row', 1),
    ]);

    await tester.tap(find.byTooltip('Superset').first);
    await tester.pumpAndSettle();

    expect(find.text('Superset with the exercise above'), findsNothing);
    await tester.tap(find.text('Superset with the exercise below'));
    await tester.pumpAndSettle();

    expect(plans.calls, ['next 1']);
  });

  testWidgets('the last exercise pairs with the one above', (tester) async {
    final plans = await pump(tester, [
      _planned('bench', 'Bench press', 0),
      _planned('row', 'Cable row', 1),
    ]);

    await tester.tap(find.byTooltip('Superset').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Superset with the exercise above'));
    await tester.pumpAndSettle();

    expect(plans.calls, ['previous 2']);
  });

  testWidgets('a member can leave its superset', (tester) async {
    final plans = await pump(tester, [
      _planned('bench', 'Bench press', 0, group: 1),
      _planned('row', 'Cable row', 1, group: 1),
    ]);

    await tester.tap(find.byTooltip('Superset').first);
    await tester.pumpAndSettle();
    // Already paired with the row, so that is not offered again.
    expect(find.text('Superset with the exercise below'), findsNothing);
    await tester.tap(find.text('Remove from superset'));
    await tester.pumpAndSettle();

    expect(plans.calls, ['leave 1']);
  });

  testWidgets('a one-exercise day has no superset button', (tester) async {
    await pump(tester, [_planned('bench', 'Bench press', 0)]);

    expect(find.byTooltip('Superset'), findsNothing);
  });

  testWidgets('dragging a handle saves the new order', (tester) async {
    final plans = await pump(tester, [
      _planned('bench', 'Bench press', 0),
      _planned('row', 'Cable row', 1),
      _planned('fly', 'Cable fly', 2),
    ]);

    final handle = find.byIcon(Icons.drag_handle).first;
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump();
    for (var i = 0; i < 9; i++) {
      await gesture.moveBy(const Offset(0, 10));
      await tester.pump();
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(plans.orders, [
      [2, 1, 3],
    ]);
  });
}
