// The training calendar beside the year grid: the month's shape, which days
// are marked, and what tapping one does.

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gymfy/app/theme/accent_color.dart';
import 'package:gymfy/features/calendar/data/calendar_month.dart';
import 'package:gymfy/features/calendar/data/calendar_repository.dart';
import 'package:gymfy/features/calendar/widgets/training_calendar.dart';
import 'package:gymfy/features/exercises/data/exercise_repository.dart';
import 'package:gymfy/features/workout/data/personal_records.dart';
import 'package:gymfy/features/workout/data/session_repository.dart';
import 'package:gymfy/features/workout/screens/workout_summary_screen.dart';
import 'package:gymfy/shared/data/week_start.dart';
import 'package:gymfy/shared/database/app_database.dart';

import 'support/default_accent.dart';
import 'package:gymfy/shared/widgets/lucide_icons.dart';

// A Thursday.
final _today = DateTime(2026, 10, 1, 12);

void main() {
  testWidgets('a past workout opens with a way back to the calendar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final session = WorkoutSession(
      id: 3,
      name: 'Free workout',
      startedAt: DateTime(2026, 9, 14, 7),
      completedAt: DateTime(2026, 9, 14, 8),
    );
    final router = GoRouter(
      initialLocation: '/progress',
      routes: [
        GoRoute(
          path: '/progress',
          builder: (context, state) => const Text('the calendar'),
          routes: [
            GoRoute(
              path: 'session/:sessionId',
              builder: (context, state) => WorkoutSummaryScreen(
                sessionId: int.parse(state.pathParameters['sessionId']!),
                fromHistory: true,
              ),
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...defaultDisplayOverrides,
          sessionProvider.overrideWith((ref, id) => Stream.value(session)),
          sessionSetsProvider.overrideWith(
            (ref, id) => Stream.value(const <LoggedSet>[]),
          ),
          allExercisesProvider.overrideWith((ref) => Stream.value(const [])),
          sessionRecordsProvider.overrideWith((ref, id) async => const []),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    router.go('/progress/session/3');
    await tester.pumpAndSettle();

    // Looked up, not just finished: no "complete", and a back arrow.
    expect(find.text('Workout'), findsOneWidget);
    expect(find.text('Workout complete'), findsNothing);
    expect(find.byType(BackButton), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('the calendar'), findsOneWidget);
  });

  group('monthGrid', () {
    test('pads to whole weeks, starting on the first day of the week', () {
      // 1 September 2026 is a Tuesday.
      final cells = monthGrid(DateTime(2026, 9), DateTime.monday);
      expect(cells.length % 7, 0);
      expect(cells.take(2), [null, DateTime(2026, 9, 1)]);
      expect(cells.whereType<DateTime>(), hasLength(30));
      expect(cells.last, isNull);
    });

    test('a Sunday-first week shifts every day one column right', () {
      final cells = monthGrid(DateTime(2026, 9), DateTime.sunday);
      expect(cells.take(3), [null, null, DateTime(2026, 9, 1)]);
    });

    test('a month starting on the first weekday has no blanks before it', () {
      // 1 February 2027 is a Monday, and February has exactly four weeks.
      final cells = monthGrid(DateTime(2027, 2), DateTime.monday);
      expect(cells.first, DateTime(2027, 2, 1));
      expect(cells, hasLength(28));
    });

    test('a long month can need six rows', () {
      // 1 August 2026 is a Saturday: 5 blanks, 31 days → 36 → six rows.
      expect(monthGrid(DateTime(2026, 8), DateTime.monday), hasLength(42));
    });
  });

  group('the calendar', () {
    late AppDatabase db;
    late ProviderContainer container;
    late GoRouter router;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          defaultAccentOverride,
          firstWeekdayProvider.overrideWithValue(DateTime.monday),
        ],
      );
      router = GoRouter(
        initialLocation: '/progress',
        routes: [
          GoRoute(
            path: '/progress',
            builder: (context, state) => Scaffold(
              body: ListView(children: [TrainingCalendar(today: _today)]),
            ),
            routes: [
              GoRoute(
                path: 'session/:id',
                builder: (context, state) =>
                    Text('summary ${state.pathParameters['id']}'),
              ),
            ],
          ),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    Future<void> pump(WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
    }

    /// A finished workout ending at [at], with [sets] sets logged.
    Future<int> workout(
      DateTime at, {
      String name = 'Push',
      bool free = false,
      int sets = 2,
    }) async {
      final id = await _insertSession(db, at, name: name, free: free);
      final repo = SessionRepository(db);
      for (var i = 1; i <= sets; i++) {
        await repo.logSet(
          sessionId: id,
          exerciseId: 'barbell_bench_press',
          setNumber: i,
          weight: 100,
          reps: 5,
        );
      }
      return id;
    }

    Future<void> seedExercise() => db
        .into(db.exercises)
        .insert(
          ExercisesCompanion.insert(
            id: 'barbell_bench_press',
            name: 'Barbell Bench Press',
            muscleIds: const ['chest'],
          ),
        );

    testWidgets('is hidden before the first finished workout', (tester) async {
      await pump(tester);
      expect(find.text('Calendar'), findsNothing);
    });

    testWidgets('marks trained days in the accent, and only those', (
      tester,
    ) async {
      await seedExercise();
      await workout(DateTime(2026, 10, 1, 9));

      await pump(tester);

      expect(find.text('Calendar'), findsOneWidget);
      expect(find.text('October 2026'), findsOneWidget);

      Color? fillOf(String day) {
        final box = tester.widget<Container>(
          find
              .ancestor(of: find.text(day), matching: find.byType(Container))
              .first,
        );
        return (box.decoration as BoxDecoration?)?.color;
      }

      expect(fillOf('1'), AccentPalette.defaultAccent);
      expect(fillOf('2'), Colors.transparent);
    });

    testWidgets('tapping a day lists its workouts, free ones included', (
      tester,
    ) async {
      await seedExercise();
      await workout(DateTime(2026, 9, 14, 8), name: 'Free workout', free: true);
      final push = await workout(DateTime(2026, 9, 14, 19), sets: 3);

      await pump(tester);
      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();
      expect(find.text('September 2026'), findsOneWidget);

      await tester.tap(find.text('14'));
      await tester.pumpAndSettle();

      expect(find.text('Free workout'), findsOneWidget);
      expect(find.text('Push'), findsOneWidget);
      expect(find.textContaining('3 sets'), findsOneWidget);

      await tester.tap(find.text('Push'));
      await tester.pumpAndSettle();
      expect(find.text('summary $push'), findsOneWidget);
    });

    testWidgets('a day with nothing on it says so', (tester) async {
      await seedExercise();
      await workout(DateTime(2026, 10, 1, 9));

      await pump(tester);
      // Tuesday 29 September: back a month, nothing logged that day.
      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('29'));
      await tester.pumpAndSettle();

      expect(find.textContaining('rest day'), findsOneWidget);
    });

    testWidgets('cannot step into the future', (tester) async {
      await seedExercise();
      await workout(DateTime(2026, 10, 1, 9));

      await pump(tester);

      final next = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(LucideIcons.chevronRight),
          matching: find.byType(IconButton),
        ),
      );
      expect(next.onPressed, isNull);
    });

    testWidgets('the week starts where the phone says it does', (tester) async {
      await seedExercise();
      await workout(DateTime(2026, 10, 1, 9));
      container.dispose();
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          defaultAccentOverride,
          firstWeekdayProvider.overrideWithValue(DateTime.sunday),
        ],
      );

      await pump(tester);

      final su = tester.getTopLeft(find.text('Su'));
      final mo = tester.getTopLeft(find.text('Mo'));
      expect(su.dx, lessThan(mo.dx));
    });

    test('the repository dates a workout by when it finished', () async {
      await seedExercise();
      // Started on the 30th, finished after midnight: it is October's.
      final id = await db
          .into(db.workoutSessions)
          .insert(
            WorkoutSessionsCompanion.insert(
              name: 'Late one',
              startedAt: Value(DateTime(2026, 9, 30, 23, 30)),
              completedAt: Value(DateTime(2026, 10, 1, 0, 40)),
            ),
          );
      final repo = CalendarRepository(db);

      final september = await repo.watchMonth(DateTime(2026, 9)).first;
      final october = await repo.watchMonth(DateTime(2026, 10)).first;

      expect(september, isEmpty);
      expect(october.single.id, id);
      expect(october.single.day, DateTime(2026, 10, 1));
      expect(october.single.length, const Duration(minutes: 70));
      expect(october.single.sets, 0);
      expect(october.single.free, isTrue);
    });
  });
}

/// Inserts a finished session ending at [at], an hour long.
Future<int> _insertSession(
  AppDatabase db,
  DateTime at, {
  required String name,
  required bool free,
}) async {
  int? dayId;
  if (!free) {
    final splitId = await db
        .into(db.splits)
        .insert(SplitsCompanion.insert(name: 'Split $at'));
    dayId = await db
        .into(db.workoutDays)
        .insert(WorkoutDaysCompanion.insert(splitId: splitId, name: name));
  }
  return db
      .into(db.workoutSessions)
      .insert(
        WorkoutSessionsCompanion.insert(
          name: name,
          dayId: Value(dayId),
          startedAt: Value(at.subtract(const Duration(hours: 1))),
          completedAt: Value(at),
        ),
      );
}
