import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/data/week_start.dart';
import '../../../shared/database/app_database.dart';
import '../../../shared/models/body_measurement.dart';
import '../../../shared/models/goal.dart';
import '../../../shared/utils/dates.dart';
import '../../calculator/data/tested_one_rm_repository.dart';
import '../../home/data/recap_repository.dart';
import '../../progress/data/measurements_repository.dart';
import '../../progress/data/progress_repository.dart';
import 'goal_progress.dart';

part 'goal_repository.g.dart';

/// Reads and writes goals. How far along each one is lives in
/// goal_progress.dart; this only stores what was asked for.
class GoalRepository {
  GoalRepository(this._db);

  final AppDatabase _db;

  /// Every goal, archived ones included, oldest first.
  Stream<List<Goal>> watchGoals() {
    final query = _db.select(_db.goals)
      ..orderBy([
        (t) => OrderingTerm(expression: t.createdAt),
        (t) => OrderingTerm(expression: t.id),
      ]);
    return query.watch();
  }

  /// Saves a new goal and returns its id.
  Future<int> add(GoalDraft draft) {
    return _db
        .into(_db.goals)
        .insert(
          GoalsCompanion.insert(
            kind: draft.kind.name,
            exerciseId: Value(draft.exerciseId),
            target: draft.target,
            startValue: Value(draft.startValue),
            deadline: Value(_day(draft.deadline)),
            createdAt: Value(clock.now()),
          ),
        );
  }

  /// Changes what goal [id] asks for. The kind and the starting point stay as
  /// they were — progress is still measured from where the user stood when
  /// they first set it.
  ///
  /// Clears the celebration: a target moved past what was reached is a goal
  /// not reached yet, and reaching the new one deserves its own moment.
  Future<void> update(int id, GoalDraft draft) {
    return (_db.update(_db.goals)..where((t) => t.id.equals(id))).write(
      GoalsCompanion(
        exerciseId: Value(draft.exerciseId),
        target: Value(draft.target),
        deadline: Value(_day(draft.deadline)),
        celebratedAt: const Value(null),
      ),
    );
  }

  /// Puts a goal away: off Home and out of the active list, history kept.
  Future<void> archive(int id) =>
      _write(id, GoalsCompanion(archivedAt: Value(clock.now())));

  /// Brings an archived goal back.
  Future<void> unarchive(int id) =>
      _write(id, const GoalsCompanion(archivedAt: Value(null)));

  /// Records that the user has seen goal [id] celebrated.
  Future<void> markCelebrated(int id) =>
      _write(id, GoalsCompanion(celebratedAt: Value(clock.now())));

  Future<void> delete(int id) =>
      (_db.delete(_db.goals)..where((t) => t.id.equals(id))).go();

  Future<void> _write(int id, GoalsCompanion patch) =>
      (_db.update(_db.goals)..where((t) => t.id.equals(id))).write(patch);

  /// Deadlines are days, stored at midnight like every other date-only column.
  static DateTime? _day(DateTime? value) =>
      value == null ? null : dateOnly(value);
}

/// App-wide access to the [GoalRepository].
@Riverpod(keepAlive: true)
GoalRepository goalRepository(Ref ref) {
  return GoalRepository(ref.watch(appDatabaseProvider));
}

// Hand-written (not code-generated) because their types are Drift's generated
// classes, which the Riverpod generator can't emit.

/// Every goal, archived ones included.
final goalsProvider = StreamProvider<List<Goal>>((ref) {
  return ref.watch(goalRepositoryProvider).watchGoals();
});

/// When each completed workout finished — what a workouts-per-week goal
/// counts.
///
/// Taken from the recap's sets rather than a query of its own: that stream is
/// already open for Home and Progress, and it already applies the rule that a
/// workout is a completed session with something logged in it. A session
/// started and walked out of is not a workout here either.
final workoutFinishTimesProvider = Provider<List<DateTime>?>((ref) {
  final sets = ref.watch(recapSetsProvider).value;
  if (sets == null) return null;
  final bySession = <int, DateTime>{};
  for (final set in sets) {
    bySession[set.sessionId] = set.date;
  }
  return bySession.values.toList();
});

/// Where every goal stands, in the order they were set. Null until the goals
/// themselves have loaded.
///
/// Each goal reads only the history it is measured against — a lift goal
/// watches its own exercise, not the whole log — through the same providers
/// the progress screens use, so a goal and the chart beside it can never
/// disagree about your best.
final goalStatusesProvider = Provider<List<GoalStatus>?>((ref) {
  final goals = ref.watch(goalsProvider).value;
  if (goals == null) return null;
  final today = clock.now();

  final statuses = <GoalStatus>[];
  for (final goal in goals) {
    switch (GoalKind.parse(goal.kind)) {
      case GoalKind.lift:
        final exerciseId = goal.exerciseId;
        if (exerciseId == null) continue;
        statuses.add(
          liftGoalStatus(
            goal,
            history:
                ref.watch(exerciseHistoryProvider(exerciseId)).value ??
                const [],
            tested: ref.watch(testedOneRmProvider(exerciseId)).value,
            today: today,
          ),
        );
      case GoalKind.bodyweight:
        statuses.add(
          bodyweightGoalStatus(
            goal,
            weights: seriesFor(
              ref.watch(measurementHistoryProvider).value ?? const [],
              MeasurementField.weight,
            ),
            today: today,
          ),
        );
      case GoalKind.frequency:
        statuses.add(
          frequencyGoalStatus(
            goal,
            finishedAt: ref.watch(workoutFinishTimesProvider) ?? const [],
            today: today,
            firstWeekday: ref.watch(firstWeekdayProvider),
          ),
        );
      case null:
        // Written by a newer build. Left alone rather than measured against
        // the wrong numbers.
        continue;
    }
  }
  return statuses;
});
