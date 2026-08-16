// The states of the Home tab's "today" card: no active split, a rest day, a
// workout to start, and a workout already running.

// Material exports an animation curve also named `Split`; hide it so `Split`
// here unambiguously means the Drift row class.
import 'package:drift/native.dart';
import 'package:flutter/material.dart' hide Split;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/home/widgets/today_card.dart';
import 'package:gymfy/features/workout/data/session_repository.dart';
import 'package:gymfy/features/workout/data/workout_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';

import 'support/default_accent.dart';

void main() {
  // A fixed Monday, so the card is tested against a weekday we chose rather
  // than whichever one the suite happens to run on.
  final monday = DateTime(2026, 8, 17);
  final tuesday = DateTime(2026, 8, 18);

  late AppDatabase db;
  late WorkoutRepository repo;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = WorkoutRepository(db);
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db), defaultAccentOverride],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> pump(WidgetTester tester, {required DateTime today}) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: Scaffold(body: TodayCard(today: today))),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('says so when no split is active', (tester) async {
    await pump(tester, today: monday);

    expect(find.text('No active split'), findsOneWidget);
    // Pointing at the fix, not just naming the problem.
    expect(find.textContaining('Set active'), findsOneWidget);
  });

  testWidgets('an unscheduled weekday is a rest day', (tester) async {
    final splitId = await repo.createSplit('PPL');
    final push = await repo.createDay(splitId, 'Push');
    await repo.assignWeekday(dayId: push, weekday: 1);

    await pump(tester, today: tuesday);

    expect(find.text('Rest day'), findsOneWidget);
    // Named, so it's clear which programme decided that.
    expect(find.textContaining('PPL'), findsOneWidget);
  });

  testWidgets('shows the day scheduled for today', (tester) async {
    final splitId = await repo.createSplit('PPL');
    final push = await repo.createDay(splitId, 'Push');
    await repo.assignWeekday(dayId: push, weekday: 1);
    await db.into(db.exercises).insert(
      ExercisesCompanion.insert(
        id: 'barbell_bench_press',
        name: 'Barbell Bench Press',
        muscleIds: const ['chest'],
      ),
    );
    await repo.addExercisesToDay(push, ['barbell_bench_press']);

    await pump(tester, today: monday);

    expect(find.text('MONDAY'), findsOneWidget);
    expect(find.text('Push'), findsOneWidget);
    expect(find.text('Barbell Bench Press'), findsOneWidget);
    // The plan is on the card, so you can see the session before starting it.
    expect(find.text('3 × 10'), findsOneWidget);
    expect(find.text('Start workout'), findsOneWidget);
    expect(find.text('Rest day'), findsNothing);
  });

  testWidgets('rep ranges are shown as ranges', (tester) async {
    final splitId = await repo.createSplit('PPL');
    final push = await repo.createDay(splitId, 'Push');
    await repo.assignWeekday(dayId: push, weekday: 1);
    await db.into(db.exercises).insert(
      ExercisesCompanion.insert(
        id: 'barbell_bench_press',
        name: 'Barbell Bench Press',
        muscleIds: const ['chest'],
      ),
    );
    await repo.addExercisesToDay(push, ['barbell_bench_press']);
    // A plain query, not `watchDayExercises(...).first`: awaiting a Drift
    // *stream* inside `testWidgets` deadlocks, because the faked clock never
    // runs the timers the stream depends on.
    final entry = (await db.select(db.workoutExercises).get()).single;
    await repo.updatePlannedExercise(entry.id, sets: 4, reps: 8, repsMax: 12);

    await pump(tester, today: monday);

    expect(find.text('4 × 8–12'), findsOneWidget);
  });

  testWidgets('offers to resume a workout that is still running', (
    tester,
  ) async {
    final splitId = await repo.createSplit('PPL');
    final push = await repo.createDay(splitId, 'Push');
    await repo.assignWeekday(dayId: push, weekday: 1);
    await db.into(db.exercises).insert(
      ExercisesCompanion.insert(
        id: 'barbell_bench_press',
        name: 'Barbell Bench Press',
        muscleIds: const ['chest'],
      ),
    );
    await repo.addExercisesToDay(push, ['barbell_bench_press']);
    await SessionRepository(db).startSession(dayId: push, name: 'Push');

    await pump(tester, today: monday);

    // Starting a second session would split one workout's sets across both.
    expect(find.text('Resume Push'), findsOneWidget);
    expect(find.text('Start workout'), findsNothing);
  });

  testWidgets('a finished workout does not block starting a new one', (
    tester,
  ) async {
    final splitId = await repo.createSplit('PPL');
    final push = await repo.createDay(splitId, 'Push');
    await repo.assignWeekday(dayId: push, weekday: 1);
    await db.into(db.exercises).insert(
      ExercisesCompanion.insert(
        id: 'barbell_bench_press',
        name: 'Barbell Bench Press',
        muscleIds: const ['chest'],
      ),
    );
    await repo.addExercisesToDay(push, ['barbell_bench_press']);
    final sessions = SessionRepository(db);
    final id = await sessions.startSession(dayId: push, name: 'Push');
    await sessions.completeSession(id);

    await pump(tester, today: monday);

    expect(find.text('Start workout'), findsOneWidget);
    expect(find.textContaining('Resume'), findsNothing);
  });

  testWidgets('a scheduled day with no exercises invites filling it', (
    tester,
  ) async {
    final splitId = await repo.createSplit('PPL');
    final push = await repo.createDay(splitId, 'Push');
    await repo.assignWeekday(dayId: push, weekday: 1);

    await pump(tester, today: monday);

    // Not a rest day — it's scheduled, just empty, and those need different
    // wording or the user goes looking for a bug.
    expect(find.text('Push'), findsOneWidget);
    expect(find.textContaining('No exercises yet'), findsOneWidget);
  });

  testWidgets('only the active split decides the day', (tester) async {
    final ppl = await repo.createSplit('PPL');
    final push = await repo.createDay(ppl, 'Push');
    await repo.assignWeekday(dayId: push, weekday: 1);

    final other = await repo.createSplit('Upper/Lower');
    final upper = await repo.createDay(other, 'Upper');
    await repo.assignWeekday(dayId: upper, weekday: 1);
    await repo.setActiveSplit(other);

    await pump(tester, today: monday);

    expect(find.text('Upper'), findsOneWidget);
    expect(find.text('Push'), findsNothing);
  });
}
