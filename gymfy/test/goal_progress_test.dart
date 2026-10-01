// Where a goal stands, worked out from the log — and the words it is shown
// with.
//
// Pure functions, so every rule in goal_progress.dart's header gets a test of
// its own: lifts on the heaviest working set (not the estimate), bodyweight in
// either direction and staying reached, weekly goals that start on the
// phone's first day of the week, and a celebration that shows once.

import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/goals/data/goal_labels.dart';
import 'package:gymfy/features/goals/data/goal_progress.dart';
import 'package:gymfy/features/progress/data/measurements_repository.dart'
    show MeasurementPoint;
import 'package:gymfy/features/progress/data/progress_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';
import 'package:gymfy/shared/models/goal.dart';
import 'package:gymfy/shared/utils/dates.dart';
import 'package:gymfy/shared/utils/units.dart';
import 'package:gymfy/shared/utils/weekday.dart';

// A Thursday.
final _today = DateTime(2026, 10, 1, 9);

Goal _goal({
  GoalKind kind = GoalKind.lift,
  double target = 100,
  double? start,
  DateTime? deadline,
  DateTime? createdAt,
  DateTime? celebratedAt,
  DateTime? archivedAt,
}) => Goal(
  id: 1,
  kind: kind.name,
  exerciseId: kind == GoalKind.lift ? 'barbell_bench_press' : null,
  target: target,
  startValue: start,
  deadline: deadline,
  createdAt: createdAt ?? DateTime(2026, 9, 1),
  celebratedAt: celebratedAt,
  archivedAt: archivedAt,
);

ExerciseHistoryPoint _session(DateTime date, double top, {int reps = 5}) =>
    ExerciseHistoryPoint(
      date: date,
      topWeight: top,
      repsAtTop: reps,
      totalVolume: top * reps,
    );

void main() {
  group('a lift goal', () {
    test('is judged on the heaviest working set, at any rep count', () {
      final status = liftGoalStatus(
        _goal(start: 90),
        history: [
          _session(DateTime(2026, 9, 3, 18), 92.5),
          _session(DateTime(2026, 9, 10, 18), 95, reps: 2),
        ],
        tested: null,
        today: _today,
      );

      expect(status.current, 95);
      expect(status.reached, isFalse);
      // From where it started (90), halfway to 100.
      expect(status.fraction, closeTo(0.5, 1e-9));
    });

    test('is not met by an estimate the bar never saw', () {
      // 90 kg × 8 estimates well over 100 on every formula. The goal said
      // "lift 100 kg", and nobody has.
      final status = liftGoalStatus(
        _goal(start: 85),
        history: [_session(DateTime(2026, 9, 20, 18), 90, reps: 8)],
        tested: null,
        today: _today,
      );

      expect(status.reached, isFalse);
      expect(status.current, 90);
    });

    test('is met on the first session that hit the target', () {
      final status = liftGoalStatus(
        _goal(start: 90),
        history: [
          _session(DateTime(2026, 9, 10, 18), 100, reps: 1),
          _session(DateTime(2026, 9, 24, 18), 102.5),
        ],
        tested: null,
        today: _today,
      );

      expect(status.reached, isTrue);
      expect(status.reachedAt, DateTime(2026, 9, 10, 18));
      expect(status.fraction, 1);
      expect(status.current, 102.5);
    });

    test('a tested max counts — it is a weight that was lifted', () {
      final status = liftGoalStatus(
        _goal(start: 90),
        history: [_session(DateTime(2026, 9, 10, 18), 95)],
        tested: TestedOneRm(
          exerciseId: 'barbell_bench_press',
          weightKg: 101,
          testedOn: DateTime(2026, 9, 28),
          updatedAt: DateTime(2026, 9, 28),
        ),
        today: _today,
      );

      expect(status.reached, isTrue);
      expect(status.reachedAt, DateTime(2026, 9, 28));
    });

    test('a lift never trained has nothing to show yet', () {
      final status = liftGoalStatus(
        _goal(),
        history: const [],
        tested: null,
        today: _today,
      );

      expect(status.current, isNull);
      expect(status.fraction, 0);
      expect(goalCaption(status), 'Not trained yet');
    });

    test('bestLiftKg is the larger of the history and a tested max', () {
      final history = [_session(DateTime(2026, 9, 1), 97.5)];
      expect(bestLiftKg(history, null), 97.5);
      expect(
        bestLiftKg(
          history,
          TestedOneRm(
            exerciseId: 'x',
            weightKg: 100,
            testedOn: DateTime(2026, 9, 2),
            updatedAt: DateTime(2026, 9, 2),
          ),
        ),
        100,
      );
      expect(bestLiftKg(const [], null), isNull);
    });
  });

  group('a bodyweight goal', () {
    MeasurementPoint weighIn(int day, double kg) =>
        (day: DateTime(2026, 9, day), value: kg);

    test('reads a target below the start as a cut', () {
      final status = bodyweightGoalStatus(
        _goal(kind: GoalKind.bodyweight, target: 80, start: 84),
        weights: [weighIn(1, 84), weighIn(15, 82)],
        today: _today,
      );

      expect(status.current, 82);
      expect(status.reached, isFalse);
      expect(status.fraction, closeTo(0.5, 1e-9));
    });

    test('and one above it as a gain', () {
      final status = bodyweightGoalStatus(
        _goal(kind: GoalKind.bodyweight, target: 70, start: 66),
        weights: [weighIn(1, 66), weighIn(20, 67)],
        today: _today,
      );

      expect(status.fraction, closeTo(0.25, 1e-9));
    });

    test('stays reached when the scale bounces back', () {
      // The goal was "get there", not "stay there".
      final status = bodyweightGoalStatus(
        _goal(kind: GoalKind.bodyweight, target: 80, start: 84),
        weights: [weighIn(1, 84), weighIn(20, 79.8), weighIn(28, 81)],
        today: _today,
      );

      expect(status.reached, isTrue);
      expect(status.reachedAt, DateTime(2026, 9, 20));
      expect(status.current, 81);
      expect(status.fraction, 1);
    });

    test('ignores a weigh-in from before the goal was set', () {
      // Being 80 kg last spring is not reaching a goal set this autumn.
      final status = bodyweightGoalStatus(
        _goal(
          kind: GoalKind.bodyweight,
          target: 80,
          start: 84,
          createdAt: DateTime(2026, 9, 10),
        ),
        weights: [weighIn(1, 79), weighIn(12, 84)],
        today: _today,
      );

      expect(status.reached, isFalse);
    });
  });

  group('a workouts-per-week goal', () {
    GoalStatus weekly(List<DateTime> finished, {int first = DateTime.monday}) =>
        frequencyGoalStatus(
          _goal(kind: GoalKind.frequency, target: 3),
          finishedAt: finished,
          today: _today,
          firstWeekday: first,
        );

    test('counts this week from its first day', () {
      // Monday 28 Sep to Thursday 1 Oct: two workouts. Sunday's belongs to the
      // week before.
      final status = weekly([
        DateTime(2026, 9, 27, 10),
        DateTime(2026, 9, 28, 18),
        DateTime(2026, 9, 30, 18),
      ]);

      expect(status.current, 2);
      expect(status.reached, isFalse);
      expect(goalValue(status, unit: WeightUnit.kg), '2 of 3');
      expect(goalCaption(status), '1 to go this week');
    });

    test('a week starting on Sunday counts that Sunday', () {
      final status = weekly([
        DateTime(2026, 9, 27, 10),
        DateTime(2026, 9, 28, 18),
        DateTime(2026, 9, 30, 18),
      ], first: DateTime.sunday);

      expect(status.current, 3);
      expect(status.reached, isTrue);
      // Met when the third one finished.
      expect(status.reachedAt, DateTime(2026, 9, 30, 18));
    });

    test('two workouts on one day are two workouts', () {
      final status = weekly([
        DateTime(2026, 9, 29, 7),
        DateTime(2026, 9, 29, 19),
        DateTime(2026, 9, 30, 19),
      ]);

      expect(status.reached, isTrue);
    });

    test('counts the weeks in a row it was met', () {
      final status = weekly([
        // Two full weeks before this one…
        for (final day in [14, 15, 16, 21, 22, 23]) DateTime(2026, 9, day, 18),
        // …and this week not done yet, which breaks nothing.
        DateTime(2026, 9, 29, 18),
      ]);

      expect(status.weekStreak, 2);
      expect(goalCaption(status), '2 to go this week · 2 weeks in a row');
    });

    test('never finishes, so it stays in progress once met', () {
      final status = weekly([
        for (final day in [28, 29, 30]) DateTime(2026, 9, day, 18),
      ]);

      expect(status.reached, isTrue);
      expect(status.inProgress, isTrue);
      expect(goalCaption(status), 'Done this week');
    });
  });

  group('celebrating', () {
    test('a reached goal celebrates until it has been seen', () {
      final history = [_session(DateTime(2026, 9, 30, 18), 100)];
      GoalStatus status(DateTime? seen) => liftGoalStatus(
        _goal(start: 90, celebratedAt: seen),
        history: history,
        tested: null,
        today: _today,
      );

      expect(status(null).celebrate, isTrue);
      expect(status(DateTime(2026, 9, 30, 20)).celebrate, isFalse);
    });

    test('a goal not reached never celebrates', () {
      final status = liftGoalStatus(
        _goal(start: 90),
        history: [_session(DateTime(2026, 9, 30, 18), 95)],
        tested: null,
        today: _today,
      );
      expect(status.celebrate, isFalse);
    });

    test('an archived goal stays quiet', () {
      final status = liftGoalStatus(
        _goal(start: 90, archivedAt: DateTime(2026, 9, 30, 21)),
        history: [_session(DateTime(2026, 9, 30, 18), 100)],
        tested: null,
        today: _today,
      );
      expect(status.celebrate, isFalse);
      expect(status.inProgress, isFalse);
    });

    test('a weekly goal celebrates each week it is met, once', () {
      final thisWeek = [
        for (final day in [28, 29, 30]) DateTime(2026, 9, day, 18),
      ];
      GoalStatus status(DateTime? seen) => frequencyGoalStatus(
        _goal(kind: GoalKind.frequency, target: 3, celebratedAt: seen),
        finishedAt: thisWeek,
        today: _today,
        firstWeekday: DateTime.monday,
      );

      expect(status(null).celebrate, isTrue);
      // Seen after Wednesday's workout met it: done for this week.
      expect(status(DateTime(2026, 9, 30, 19)).celebrate, isFalse);
      // Last week's celebration, opened on Monday morning, is not this
      // week's.
      expect(status(DateTime(2026, 9, 28, 8)).celebrate, isTrue);
    });
  });

  group('deadlines', () {
    GoalStatus due(DateTime deadline) => liftGoalStatus(
      _goal(start: 90, deadline: deadline),
      history: [_session(DateTime(2026, 9, 20), 95)],
      tested: null,
      today: _today,
    );

    test('count calendar days', () {
      expect(due(DateTime(2026, 10, 11)).daysLeft, 10);
      expect(goalCaption(due(DateTime(2026, 10, 11))), '10 days left');
      expect(goalCaption(due(DateTime(2026, 10, 2))), '1 day left');
      expect(goalCaption(due(DateTime(2026, 10, 1))), 'Due today');
    });

    test('a passed one makes the goal overdue, not gone', () {
      final status = due(DateTime(2026, 9, 25));
      expect(status.overdue, isTrue);
      expect(status.inProgress, isTrue);
      expect(goalCaption(status), 'Was due 25 Sep 2026');
    });

    test('a far one is named, not counted', () {
      expect(goalCaption(due(DateTime(2027, 3, 1))), 'By 1 Mar 2027');
    });

    test('a reached goal says when, not how long was left', () {
      final status = liftGoalStatus(
        _goal(start: 90, deadline: DateTime(2026, 12, 1)),
        history: [_session(DateTime(2026, 9, 20, 18), 100)],
        tested: null,
        today: _today,
      );
      expect(goalCaption(status), 'Reached 20 Sep 2026');
    });
  });

  group('titles', () {
    test('say what the goal is, in the chosen unit', () {
      final lift = liftGoalStatus(
        _goal(target: 100),
        history: const [],
        tested: null,
        today: _today,
      );
      expect(
        goalTitle(lift, exerciseName: 'Bench Press', unit: WeightUnit.kg),
        'Bench Press · 100 kg',
      );
      expect(
        goalTitle(lift, exerciseName: 'Bench Press', unit: WeightUnit.lbs),
        'Bench Press · 220 lbs',
      );
      expect(workoutsPerWeekLabel(1), '1 workout a week');
      expect(workoutsPerWeekLabel(4), '4 workouts a week');
    });
  });

  group('saving a goal', () {
    String? problem(GoalDraft draft, {double? best}) =>
        goalDraftProblem(draft, today: _today, bestLiftKg: best);

    test('a lift needs an exercise and a target above your best', () {
      expect(
        problem(const GoalDraft(kind: GoalKind.lift, target: 100)),
        'Choose the exercise.',
      );
      const draft = GoalDraft(
        kind: GoalKind.lift,
        target: 100,
        exerciseId: 'barbell_bench_press',
      );
      expect(problem(draft, best: 100), contains('already lifted'));
      expect(problem(draft, best: 97.5), isNull);
      expect(problem(draft), isNull);
    });

    test('weekly goals are between one and seven', () {
      expect(
        problem(const GoalDraft(kind: GoalKind.frequency, target: 0)),
        isNotNull,
      );
      expect(
        problem(const GoalDraft(kind: GoalKind.frequency, target: 8)),
        isNotNull,
      );
      expect(
        problem(const GoalDraft(kind: GoalKind.frequency, target: 4)),
        isNull,
      );
    });

    test('a bodyweight goal needs a start, and a target that differs', () {
      expect(
        problem(const GoalDraft(kind: GoalKind.bodyweight, target: 80)),
        'Log your current weight first.',
      );
      expect(
        problem(
          const GoalDraft(
            kind: GoalKind.bodyweight,
            target: 80,
            startValue: 80,
          ),
        ),
        isNotNull,
      );
      expect(
        problem(
          const GoalDraft(
            kind: GoalKind.bodyweight,
            target: 78,
            startValue: 84,
          ),
        ),
        isNull,
      );
    });

    test('a deadline in the past is refused, today is fine', () {
      expect(
        problem(
          GoalDraft(
            kind: GoalKind.lift,
            target: 100,
            exerciseId: 'x',
            deadline: DateTime(2026, 9, 30),
          ),
        ),
        isNotNull,
      );
      expect(
        problem(
          GoalDraft(
            kind: GoalKind.lift,
            target: 100,
            exerciseId: 'x',
            deadline: DateTime(2026, 10, 1),
          ),
        ),
        isNull,
      );
    });
  });

  group('the week', () {
    test('starts on the first day the region uses', () {
      expect(firstWeekdayFor(const Locale('de', 'DE')), DateTime.monday);
      expect(firstWeekdayFor(const Locale('en', 'GB')), DateTime.monday);
      expect(firstWeekdayFor(const Locale('en', 'US')), DateTime.sunday);
      expect(firstWeekdayFor(const Locale('pt', 'BR')), DateTime.sunday);
      expect(firstWeekdayFor(const Locale('ar', 'EG')), DateTime.saturday);
      // No region: the ISO week, like the year grid.
      expect(firstWeekdayFor(const Locale('en')), DateTime.monday);
    });

    test('startOfWeek walks back to it, across a month', () {
      expect(
        startOfWeek(DateTime(2026, 10, 1), DateTime.monday),
        DateTime(2026, 9, 28),
      );
      expect(
        startOfWeek(DateTime(2026, 10, 1), DateTime.sunday),
        DateTime(2026, 9, 27),
      );
      expect(
        startOfWeek(DateTime(2026, 9, 27), DateTime.sunday),
        DateTime(2026, 9, 27),
      );
    });

    test('weekdaysFrom lists the week in order', () {
      expect(weekdaysFrom(DateTime.monday), [1, 2, 3, 4, 5, 6, 7]);
      expect(weekdaysFrom(DateTime.sunday), [7, 1, 2, 3, 4, 5, 6]);
      expect(weekdaysFrom(DateTime.saturday), [6, 7, 1, 2, 3, 4, 5]);
    });

    test('daysBetween counts dates, not hours', () {
      // Across the end of summer time in Europe (25 Oct 2026).
      expect(daysBetween(DateTime(2026, 10, 24), DateTime(2026, 10, 26)), 2);
      expect(daysBetween(DateTime(2026, 10, 26), DateTime(2026, 10, 24)), -2);
    });
  });
}
