// Goals on screen: the compact card on Home, the celebration, and the Goals
// screen with its form.

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/app/theme/accent_color.dart';
import 'package:gymfy/app/theme/app_theme.dart';
import 'package:gymfy/features/exercises/data/exercise_names.dart';
import 'package:gymfy/features/goals/data/goal_progress.dart';
import 'package:gymfy/features/goals/data/goal_repository.dart';
import 'package:gymfy/features/goals/screens/goals_screen.dart';
import 'package:gymfy/features/goals/widgets/goal_celebration.dart';
import 'package:gymfy/features/goals/widgets/goals_card.dart';
import 'package:gymfy/features/workout/data/session_repository.dart';
import 'package:gymfy/shared/data/week_start.dart';
import 'package:gymfy/shared/database/app_database.dart';
import 'package:gymfy/shared/models/goal.dart';

import 'support/default_accent.dart';

final _today = DateTime.now();

Goal _goal(int id, GoalKind kind, double target, {DateTime? archivedAt}) =>
    Goal(
      id: id,
      kind: kind.name,
      exerciseId: kind == GoalKind.lift ? 'barbell_bench_press' : null,
      target: target,
      startValue: kind == GoalKind.frequency ? null : target - 10,
      createdAt: DateTime(2026, 9, 1),
      archivedAt: archivedAt,
    );

GoalStatus _status(
  Goal goal, {
  double? current,
  double fraction = 0.5,
  DateTime? reachedAt,
}) => GoalStatus(
  goal: goal,
  kind: GoalKind.parse(goal.kind)!,
  current: current,
  fraction: fraction,
  reachedAt: reachedAt,
  daysLeft: null,
);

void main() {
  group('the Home card', () {
    Future<void> pump(WidgetTester tester, List<GoalStatus> statuses) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...defaultDisplayOverrides,
            goalStatusesProvider.overrideWithValue(statuses),
            exerciseNamesProvider.overrideWithValue({
              'barbell_bench_press': 'Bench Press',
            }),
          ],
          child: MaterialApp(
            theme: buildAppTheme(AppTheme.hyper, AccentPalette.blue),
            home: const Scaffold(body: GoalsCard()),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('says nothing without an active goal', (tester) async {
      await pump(tester, [
        _status(_goal(1, GoalKind.lift, 100, archivedAt: DateTime(2026, 9, 2))),
      ]);
      expect(find.text('Goals'), findsNothing);
    });

    testWidgets('lists active goals with their progress', (tester) async {
      await pump(tester, [
        _status(_goal(1, GoalKind.lift, 100), current: 95),
        _status(_goal(2, GoalKind.frequency, 3), current: 2),
      ]);

      expect(find.text('Goals'), findsOneWidget);
      expect(find.text('2 active'), findsOneWidget);
      expect(find.text('Bench Press · 100 kg'), findsOneWidget);
      expect(find.text('95 kg'), findsOneWidget);
      expect(find.text('3 workouts a week'), findsOneWidget);
      expect(find.text('2 of 3'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
    });

    testWidgets('stays compact: three rows, then a count', (tester) async {
      await pump(tester, [
        for (var i = 1; i <= 5; i++)
          _status(_goal(i, GoalKind.frequency, i.toDouble()), current: 0),
      ]);

      expect(find.byType(LinearProgressIndicator), findsNWidgets(3));
      expect(find.text('+2 more'), findsOneWidget);
    });

    testWidgets(
      'keeps the accent off its bars, which belong to Start workout',
      (tester) async {
        await pump(tester, [
          _status(_goal(1, GoalKind.lift, 100), current: 95),
        ]);

        final bar = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        expect(bar.color, isNot(AccentPalette.blue));
      },
    );

    testWidgets('a reached goal celebrates above the card', (tester) async {
      await pump(tester, [
        _status(
          _goal(1, GoalKind.lift, 100),
          current: 100,
          fraction: 1,
          reachedAt: DateTime(2026, 9, 30, 18),
        ),
      ]);

      expect(find.byType(GoalCelebration), findsOneWidget);
      expect(find.text('Goal reached'), findsOneWidget);
      expect(find.text('Nice'), findsOneWidget);
    });
  });

  group('the celebration', () {
    Future<double> opacityAfterOneFrame(
      WidgetTester tester, {
      required bool reduceMotion,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...defaultDisplayOverrides,
            exerciseNamesProvider.overrideWithValue(const {}),
          ],
          child: MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: reduceMotion),
              child: Scaffold(
                body: GoalCelebration(
                  status: _status(
                    _goal(1, GoalKind.frequency, 3),
                    current: 3,
                    fraction: 1,
                    reachedAt: _today,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));
      return tester
          .widget<Opacity>(
            find
                .ancestor(
                  of: find.text('Week done'),
                  matching: find.byType(Opacity),
                )
                .first,
          )
          .opacity;
    }

    testWidgets('springs in', (tester) async {
      expect(
        await opacityAfterOneFrame(tester, reduceMotion: false),
        lessThan(0.5),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('simply appears under reduced motion', (tester) async {
      expect(await opacityAfterOneFrame(tester, reduceMotion: true), 1);
    });
  });

  group('with the database', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          ...defaultDisplayOverrides,
          firstWeekdayProvider.overrideWithValue(DateTime.monday),
        ],
      );
      await db
          .into(db.exercises)
          .insert(
            ExercisesCompanion.insert(
              id: 'barbell_bench_press',
              name: 'Bench Press',
              muscleIds: const ['chest'],
            ),
          );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    Future<void> pump(WidgetTester tester, Widget child) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildAppTheme(AppTheme.hyper, AccentPalette.blue),
            home: child,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('seeing a celebration puts it away for good', (tester) async {
      await tester.runAsync(() async {
        await db
            .into(db.goals)
            .insert(
              GoalsCompanion.insert(
                kind: 'lift',
                exerciseId: const Value('barbell_bench_press'),
                target: 100,
                startValue: const Value(90),
              ),
            );
        final sessions = SessionRepository(db);
        final id = await sessions.startFreeSession(name: 'Free workout');
        await sessions.logSet(
          sessionId: id,
          exerciseId: 'barbell_bench_press',
          setNumber: 1,
          weight: 100,
          reps: 1,
        );
        await sessions.completeSession(id);
      });

      await pump(tester, const Scaffold(body: GoalsCard()));
      expect(find.text('Goal reached'), findsOneWidget);
      expect(find.text('Bench Press · 100 kg'), findsOneWidget);

      await tester.tap(find.text('Nice'));
      await tester.pumpAndSettle();

      expect(find.text('Goal reached'), findsNothing);
      final goal = await tester.runAsync(() => db.select(db.goals).getSingle());
      expect(goal!.celebratedAt, isNotNull);
    });

    testWidgets('the Goals screen sets a weekly goal from empty', (
      tester,
    ) async {
      await pump(tester, const GoalsScreen());
      expect(find.text('No goals yet'), findsOneWidget);

      await tester.tap(find.text('Set a goal'));
      await tester.pumpAndSettle();
      expect(find.text('New goal'), findsOneWidget);

      await tester.tap(find.text('Workouts'));
      await tester.pumpAndSettle();
      expect(find.text('3 workouts a week'), findsOneWidget);

      await tester.tap(find.text('Save goal'));
      await tester.pumpAndSettle();

      expect(find.text('New goal'), findsNothing);
      expect(find.text('Working on'), findsOneWidget);
      expect(find.text('3 workouts a week'), findsOneWidget);
      expect(find.text('0 of 3'), findsOneWidget);
    });

    testWidgets('a lift goal starts from your best and opens above it', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final sessions = SessionRepository(db);
        final id = await sessions.startFreeSession(name: 'Free workout');
        await sessions.logSet(
          sessionId: id,
          exerciseId: 'barbell_bench_press',
          setNumber: 1,
          weight: 100,
          reps: 5,
        );
        await sessions.completeSession(id);
      });
      await pump(tester, const GoalsScreen());

      await tester.tap(find.text('Set a goal'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose an exercise'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bench Press'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Your best so far: 100 kg'), findsOneWidget);

      await tester.ensureVisible(find.text('Save goal'));
      await tester.tap(find.text('Save goal'));
      await tester.pumpAndSettle();

      final goal = (await tester.runAsync(
        () => db.select(db.goals).get(),
      ))!.single;
      expect(goal.kind, 'lift');
      expect(goal.exerciseId, 'barbell_bench_press');
      // Measured from where you stood, aimed one loadable step above it.
      expect(goal.startValue, 100);
      expect(goal.target, 105);
      expect(find.text('Bench Press · 105 kg'), findsOneWidget);
    });

    testWidgets('a lift goal needs its exercise before it saves', (
      tester,
    ) async {
      await pump(tester, const GoalsScreen());
      await tester.tap(find.text('Set a goal'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Save goal'));
      await tester.tap(find.text('Save goal'));
      await tester.pumpAndSettle();

      expect(find.text('Choose the exercise.'), findsOneWidget);
      final goals = await tester.runAsync(() => db.select(db.goals).get());
      expect(goals, isEmpty);
    });

    testWidgets('archiving moves a goal down, restoring brings it back', (
      tester,
    ) async {
      await tester.runAsync(
        () => GoalRepository(
          db,
        ).add(const GoalDraft(kind: GoalKind.frequency, target: 4)),
      );
      await pump(tester, const GoalsScreen());
      expect(find.text('Working on'), findsOneWidget);

      await tester.tap(find.byTooltip('More'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();

      expect(find.text('Working on'), findsNothing);
      expect(find.text('Archived'), findsOneWidget);

      await tester.tap(find.byTooltip('More'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Restore'));
      await tester.pumpAndSettle();
      expect(find.text('Working on'), findsOneWidget);
    });

    testWidgets('deleting asks first', (tester) async {
      await tester.runAsync(
        () => GoalRepository(
          db,
        ).add(const GoalDraft(kind: GoalKind.frequency, target: 4)),
      );
      await pump(tester, const GoalsScreen());

      await tester.tap(find.byTooltip('More'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Delete this goal?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('4 workouts a week'), findsOneWidget);

      await tester.tap(find.byTooltip('More'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();
      expect(find.text('No goals yet'), findsOneWidget);
    });
  });
}
