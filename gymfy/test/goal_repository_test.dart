// Goals in the database, and the provider that measures them against the log.
//
// The pure rules are in goal_progress_test.dart. These check the wiring: that
// each kind reads the history it should, through the same providers the
// progress screens use — and that a free workout, which has no planned day
// behind it, counts towards a weekly goal like any other.

import 'package:clock/clock.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/goals/data/goal_progress.dart';
import 'package:gymfy/features/goals/data/goal_repository.dart';
import 'package:gymfy/features/progress/data/measurements_repository.dart';
import 'package:gymfy/features/workout/data/session_repository.dart';
import 'package:gymfy/shared/data/current_day.dart';
import 'package:gymfy/shared/data/week_start.dart';
import 'package:gymfy/shared/database/app_database.dart';
import 'package:gymfy/shared/models/body_measurement.dart';
import 'package:gymfy/shared/models/goal.dart';

void main() {
  late AppDatabase db;
  late GoalRepository goals;
  late SessionRepository sessions;
  late ProviderContainer container;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.customStatement('PRAGMA foreign_keys = ON');
    goals = GoalRepository(db);
    sessions = SessionRepository(db);
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        firstWeekdayProvider.overrideWithValue(DateTime.monday),
      ],
    );
    await db
        .into(db.exercises)
        .insert(
          ExercisesCompanion.insert(
            id: 'barbell_bench_press',
            name: 'Barbell Bench Press',
            muscleIds: const ['chest'],
          ),
        );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  /// Where every goal stands, once the streams behind them have answered.
  Future<List<GoalStatus>> statuses() async {
    final sub = container.listen(goalStatusesProvider, (_, _) {});
    addTearDown(sub.close);
    for (var i = 0; i < 50; i++) {
      await pumpEventQueue();
      if (sub.read() != null) {
        // One more round, so the per-goal history streams have landed too.
        await pumpEventQueue();
        return sub.read()!;
      }
    }
    fail('the goals never loaded');
  }

  /// A finished workout with [sets] sets of [weight] × 5 on the bench.
  Future<int> workout({
    bool free = false,
    int sets = 1,
    double weight = 100,
    SetType type = SetType.normal,
  }) async {
    final id = free
        ? await sessions.startFreeSession(name: 'Free workout')
        : await db
              .into(db.workoutSessions)
              .insert(WorkoutSessionsCompanion.insert(name: 'Push'));
    for (var i = 1; i <= sets; i++) {
      await sessions.logSet(
        sessionId: id,
        exerciseId: 'barbell_bench_press',
        setNumber: i,
        weight: weight,
        reps: 5,
        setType: type,
      );
    }
    await sessions.completeSession(id);
    return id;
  }

  group('the repository', () {
    test('saves what was asked for, deadlines as days', () async {
      final id = await goals.add(
        GoalDraft(
          kind: GoalKind.lift,
          exerciseId: 'barbell_bench_press',
          target: 110,
          startValue: 100,
          deadline: DateTime(2026, 12, 31, 15, 30),
        ),
      );

      final goal = (await db.select(db.goals).get()).single;
      expect(goal.id, id);
      expect(goal.kind, 'lift');
      expect(goal.target, 110);
      expect(goal.startValue, 100);
      expect(goal.deadline, DateTime(2026, 12, 31));
      expect(goal.archivedAt, isNull);
      expect(goal.celebratedAt, isNull);
    });

    test('an edit keeps the start and clears the celebration', () async {
      final id = await goals.add(
        const GoalDraft(
          kind: GoalKind.lift,
          exerciseId: 'barbell_bench_press',
          target: 100,
          startValue: 90,
        ),
      );
      await goals.markCelebrated(id);
      expect((await db.select(db.goals).getSingle()).celebratedAt, isNotNull);

      await goals.update(
        id,
        const GoalDraft(
          kind: GoalKind.lift,
          exerciseId: 'barbell_bench_press',
          target: 110,
          // Ignored: progress is still measured from where it started.
          startValue: 105,
        ),
      );

      final goal = await db.select(db.goals).getSingle();
      expect(goal.target, 110);
      expect(goal.startValue, 90);
      // Moved past what was reached: the next one deserves its own moment.
      expect(goal.celebratedAt, isNull);
    });

    test('archive, restore and delete', () async {
      final id = await goals.add(
        const GoalDraft(kind: GoalKind.frequency, target: 3),
      );

      await goals.archive(id);
      expect((await db.select(db.goals).getSingle()).archivedAt, isNotNull);

      await goals.unarchive(id);
      expect((await db.select(db.goals).getSingle()).archivedAt, isNull);

      await goals.delete(id);
      expect(await db.select(db.goals).get(), isEmpty);
    });
  });

  group('the statuses', () {
    test('a lift goal reads the exercise history, working sets only', () async {
      await goals.add(
        const GoalDraft(
          kind: GoalKind.lift,
          exerciseId: 'barbell_bench_press',
          target: 100,
          startValue: 90,
        ),
      );
      // A heavy warm-up-tagged single is not lifting 100 kg for the record.
      await workout(weight: 102.5, type: SetType.warmup);
      await workout(weight: 95);

      final status = (await statuses()).single;
      expect(status.kind, GoalKind.lift);
      expect(status.current, 95);
      expect(status.reached, isFalse);

      await workout(weight: 100);
      final after = (await statuses()).single;
      expect(after.reached, isTrue);
      expect(after.celebrate, isTrue);
    });

    test(
      'a weekly goal counts free workouts, and only finished ones',
      () async {
        await goals.add(const GoalDraft(kind: GoalKind.frequency, target: 3));
        await workout(free: true);
        await workout();
        // Started and walked out of: not a workout.
        await sessions.startFreeSession(name: 'Free workout');
        // Finished with nothing logged: not a workout either, by the recap's
        // rule.
        final empty = await sessions.startFreeSession(name: 'Free workout');
        await sessions.completeSession(empty);

        final status = (await statuses()).single;
        expect(status.current, 2);
        expect(status.reached, isFalse);

        await workout(free: true);
        expect((await statuses()).single.reached, isTrue);
      },
    );

    test('a bodyweight goal reads the weigh-ins', () async {
      final measurements = MeasurementsRepository(db);
      await measurements.setField(
        day: DateTime.now().subtract(const Duration(days: 20)),
        field: MeasurementField.weight,
        value: 84,
      );
      await db
          .into(db.goals)
          .insert(
            GoalsCompanion.insert(
              kind: 'bodyweight',
              target: 80,
              startValue: const Value(84),
              createdAt: Value(
                DateTime.now().subtract(const Duration(days: 20)),
              ),
            ),
          );
      await measurements.setField(
        day: DateTime.now(),
        field: MeasurementField.weight,
        value: 82,
      );

      final status = (await statuses()).single;
      expect(status.current, 82);
      expect(status.fraction, closeTo(0.5, 1e-9));
    });

    test('a new week starts on Monday without restarting the app', () {
      // Sunday evening, the weekly goal met. The app stays alive overnight,
      // and on Monday morning nothing has been logged or edited — so nothing
      // the provider watches has changed. Only the calendar has.
      return withClock(Clock.fixed(DateTime(2026, 9, 27, 20)), () async {
        await goals.add(const GoalDraft(kind: GoalKind.frequency, target: 1));
        // Dated by hand: completeSession stamps the wall clock, not this one.
        final id = await db
            .into(db.workoutSessions)
            .insert(
              WorkoutSessionsCompanion.insert(
                name: 'Push',
                startedAt: Value(DateTime(2026, 9, 27, 19)),
                completedAt: Value(DateTime(2026, 9, 27, 20)),
              ),
            );
        await sessions.logSet(
          sessionId: id,
          exerciseId: 'barbell_bench_press',
          setNumber: 1,
          weight: 100,
          reps: 5,
        );
        expect((await statuses()).single.reached, isTrue);

        withClock(Clock.fixed(DateTime(2026, 9, 28, 9)), () {
          // Monday, before the app has come back: last week's answer, which
          // is what the Home card used to go on saying until a set was
          // logged.
          expect(container.read(goalStatusesProvider)!.single.reached, isTrue);

          // The resume that brings Gymfy back checks the date.
          container.read(currentDayProvider.notifier).check();
          final monday = container.read(goalStatusesProvider)!.single;
          expect(monday.reached, isFalse);
          expect(monday.current, 0);
        });
      });
    });

    test('a deadline passing turns a goal overdue the next day', () {
      return withClock(Clock.fixed(DateTime(2026, 9, 27, 20)), () async {
        await goals.add(
          GoalDraft(
            kind: GoalKind.lift,
            exerciseId: 'barbell_bench_press',
            target: 120,
            startValue: 100,
            deadline: DateTime(2026, 9, 28),
          ),
        );
        final sunday = (await statuses()).single;
        expect(sunday.daysLeft, 1);
        expect(sunday.overdue, isFalse);

        withClock(Clock.fixed(DateTime(2026, 9, 29, 7)), () {
          container.read(currentDayProvider.notifier).check();
          final tuesday = container.read(goalStatusesProvider)!.single;
          expect(tuesday.daysLeft, -1);
          expect(tuesday.overdue, isTrue);
        });
      });
    });

    test('a resume on the same day rebuilds nothing', () async {
      await goals.add(const GoalDraft(kind: GoalKind.frequency, target: 3));
      final before = await statuses();

      container.read(currentDayProvider.notifier).check();

      expect(identical(container.read(goalStatusesProvider), before), isTrue);
    });

    test('a goal of a kind this build does not know is left out', () async {
      await db
          .into(db.goals)
          .insert(GoalsCompanion.insert(kind: 'sleep', target: 8));
      await goals.add(const GoalDraft(kind: GoalKind.frequency, target: 2));

      final all = await statuses();
      expect(all.map((s) => s.kind), [GoalKind.frequency]);
    });
  });
}
