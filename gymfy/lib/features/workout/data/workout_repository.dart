import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/database/app_database.dart';

part 'workout_repository.g.dart';

/// A planned exercise joined with its library exercise, so the UI has both the
/// plan data (sets/reps) and the display data (name/category) in one object.
class PlannedExercise {
  const PlannedExercise({required this.entry, required this.exercise});

  /// The row from the workout_exercises table (dayId, sets, reps, …).
  final WorkoutExercise entry;

  /// The library exercise it points at (name, category, muscles, …).
  final Exercise exercise;
}

/// All database access for workout *plans* (splits, days, planned exercises)
/// lives here.
class WorkoutRepository {
  WorkoutRepository(this._db);

  final AppDatabase _db;

  // --- Splits -------------------------------------------------------------

  /// Streams every split, newest first. Re-emits automatically whenever the
  /// splits table changes, so the list UI updates with no manual refresh.
  Stream<List<Split>> watchSplits() {
    final query = _db.select(_db.splits)
      ..orderBy([
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
      ]);
    return query.watch();
  }

  /// Streams a single split by id (null if it doesn't exist).
  Stream<Split?> watchSplit(int id) {
    final query = _db.select(_db.splits)..where((t) => t.id.equals(id));
    return query.watchSingleOrNull();
  }

  /// Creates a new split with the given name and returns its generated id.
  Future<int> createSplit(String name) {
    return _db
        .into(_db.splits)
        .insert(SplitsCompanion.insert(name: name.trim()));
  }

  /// Deletes a split. Its days and their planned exercises are removed too,
  /// via the foreign-key cascade (see app_database.dart).
  Future<void> deleteSplit(int id) {
    return (_db.delete(_db.splits)..where((t) => t.id.equals(id))).go();
  }

  // --- Days ---------------------------------------------------------------

  /// Streams the days of a split, in the order they were added.
  Stream<List<WorkoutDay>> watchDays(int splitId) {
    final query = _db.select(_db.workoutDays)
      ..where((t) => t.splitId.equals(splitId))
      ..orderBy([(t) => OrderingTerm(expression: t.id)]);
    return query.watch();
  }

  /// Streams a single day by id (null if it doesn't exist).
  Stream<WorkoutDay?> watchDay(int id) {
    final query = _db.select(_db.workoutDays)..where((t) => t.id.equals(id));
    return query.watchSingleOrNull();
  }

  /// Adds a day to a split and returns its generated id.
  Future<int> createDay(int splitId, String name) {
    return _db.into(_db.workoutDays).insert(
      WorkoutDaysCompanion.insert(splitId: splitId, name: name.trim()),
    );
  }

  /// Deletes a day (and its planned exercises, via cascade).
  Future<void> deleteDay(int id) {
    return (_db.delete(_db.workoutDays)..where((t) => t.id.equals(id))).go();
  }

  // --- Planned exercises --------------------------------------------------

  /// Streams the exercises planned for a day, each joined with its library
  /// entry, in the order they were added.
  Stream<List<PlannedExercise>> watchDayExercises(int dayId) {
    final query = _db.select(_db.workoutExercises).join([
      innerJoin(
        _db.exercises,
        _db.exercises.id.equalsExp(_db.workoutExercises.exerciseId),
      ),
    ])..where(_db.workoutExercises.dayId.equals(dayId));
    query.orderBy([OrderingTerm(expression: _db.workoutExercises.id)]);

    return query.watch().map(
      (rows) => rows
          .map(
            (row) => PlannedExercise(
              entry: row.readTable(_db.workoutExercises),
              exercise: row.readTable(_db.exercises),
            ),
          )
          .toList(),
    );
  }

  /// Adds a library exercise to a day with default set/rep targets.
  Future<void> addExerciseToDay(
    int dayId,
    String exerciseId, {
    int sets = 3,
    int reps = 10,
  }) {
    return _db.into(_db.workoutExercises).insert(
      WorkoutExercisesCompanion.insert(
        dayId: dayId,
        exerciseId: exerciseId,
        defaultSets: Value(sets),
        defaultReps: Value(reps),
      ),
    );
  }

  /// Updates the default set/rep targets of a planned exercise.
  Future<void> updatePlannedExercise(
    int id, {
    required int sets,
    required int reps,
  }) {
    return (_db.update(_db.workoutExercises)..where((t) => t.id.equals(id)))
        .write(
          WorkoutExercisesCompanion(
            defaultSets: Value(sets),
            defaultReps: Value(reps),
          ),
        );
  }

  /// Removes a planned exercise from its day.
  Future<void> removePlannedExercise(int id) {
    return (_db.delete(_db.workoutExercises)..where((t) => t.id.equals(id)))
        .go();
  }
}

/// App-wide access to the [WorkoutRepository].
@Riverpod(keepAlive: true)
WorkoutRepository workoutRepository(Ref ref) {
  return WorkoutRepository(ref.watch(appDatabaseProvider));
}

// The providers below are hand-written (not code-generated) because their
// types are Drift's generated classes (Split / WorkoutDay) or a class built
// from them, which the Riverpod generator can't emit.

/// The live list of all splits.
final splitListProvider = StreamProvider<List<Split>>((ref) {
  return ref.watch(workoutRepositoryProvider).watchSplits();
});

/// A single split by id (data may be null if it was deleted).
final splitProvider = StreamProvider.family<Split?, int>((ref, id) {
  return ref.watch(workoutRepositoryProvider).watchSplit(id);
});

/// The live list of days in a split.
final dayListProvider = StreamProvider.family<List<WorkoutDay>, int>((
  ref,
  splitId,
) {
  return ref.watch(workoutRepositoryProvider).watchDays(splitId);
});

/// A single day by id (data may be null if it was deleted).
final dayProvider = StreamProvider.family<WorkoutDay?, int>((ref, id) {
  return ref.watch(workoutRepositoryProvider).watchDay(id);
});

/// The live list of planned exercises in a day.
final dayExercisesProvider =
    StreamProvider.family<List<PlannedExercise>, int>((ref, dayId) {
      return ref.watch(workoutRepositoryProvider).watchDayExercises(dayId);
    });
