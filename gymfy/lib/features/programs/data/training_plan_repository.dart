import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/database/app_database.dart';
import '../../../shared/utils/dates.dart';

part 'training_plan_repository.g.dart';

/// Lowest and highest deload load the block settings accept, as a percentage
/// of the working weight. Below half is a week off with extra steps; at 100
/// there is no deload at all.
const minDeloadPercent = 40.0;
const maxDeloadPercent = 95.0;

/// Longest training block offered, in weeks before the deload.
const maxBlockWeeks = 12;

/// Writes the plan-level targets programmes are built from: a planned
/// exercise's percentage of 1RM, and a split's training block.
///
/// Kept apart from `WorkoutRepository` so these few columns have one owner,
/// and every write validates the same way whichever screen made it.
class TrainingPlanRepository {
  TrainingPlanRepository(this._db);

  final AppDatabase _db;

  /// Sets (or with null, clears) the percentage-of-1RM target of one planned
  /// exercise.
  ///
  /// Anything outside (0, 100] is stored as null rather than clamped: a
  /// percentage no load could mean is a mistake, and quietly turning 140 into
  /// 100 would put a max attempt on the plan for every working set.
  Future<void> setTargetPercent(int workoutExerciseId, double? percent) {
    final valid = percent != null && percent > 0 && percent <= 100;
    return (_db.update(
      _db.workoutExercises,
    )..where((t) => t.id.equals(workoutExerciseId))).write(
      WorkoutExercisesCompanion(targetPercent: Value(valid ? percent : null)),
    );
  }

  /// Sets up a training block on [splitId]: [blockWeeks] training weeks, then
  /// one deload week at [deloadPercent] of the working weights, starting on
  /// [startedAt]'s calendar day.
  ///
  /// The week count and percentage are clamped into the ranges the settings
  /// offer, so a value from a stale screen can't store a zero-week block.
  Future<void> setTrainingBlock(
    int splitId, {
    required int blockWeeks,
    required double deloadPercent,
    required DateTime startedAt,
  }) {
    return (_db.update(_db.splits)..where((t) => t.id.equals(splitId))).write(
      SplitsCompanion(
        blockWeeks: Value(blockWeeks.clamp(1, maxBlockWeeks)),
        deloadPercent: Value(
          deloadPercent.clamp(minDeloadPercent, maxDeloadPercent),
        ),
        // Midnight of the day, so "week 1 began on Monday" doesn't depend on
        // what time on Monday the settings were saved.
        blockStartedAt: Value(dateOnly(startedAt)),
      ),
    );
  }

  /// Turns the training block off: the split goes back to running week after
  /// week with no planned deload.
  Future<void> clearTrainingBlock(int splitId) {
    return (_db.update(_db.splits)..where((t) => t.id.equals(splitId))).write(
      const SplitsCompanion(
        blockWeeks: Value(null),
        deloadPercent: Value(null),
        blockStartedAt: Value(null),
      ),
    );
  }
}

/// App-wide access to the [TrainingPlanRepository].
@Riverpod(keepAlive: true)
TrainingPlanRepository trainingPlanRepository(Ref ref) {
  return TrainingPlanRepository(ref.watch(appDatabaseProvider));
}
