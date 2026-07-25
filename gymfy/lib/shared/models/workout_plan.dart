import 'package:drift/drift.dart';

import 'exercise.dart';

/// The three tables that describe a *planned* training programme (as opposed
/// to a logged workout, which comes in Phase 4).
///
/// Shape:
///   Split  ──has many──▶  WorkoutDay  ──has many──▶  WorkoutExercise
///
/// e.g. a "Push / Pull / Legs" [Split] contains a "Push" [WorkoutDay], which
/// contains a "Barbell Bench Press" [WorkoutExercise] with default sets/reps.
///
/// Deleting a split cascades to its days, and deleting a day cascades to its
/// planned exercises (enforced by SQLite foreign keys — see the `beforeOpen`
/// pragma in app_database.dart).

/// A named training programme the user builds, e.g. "PPL" or "Upper/Lower".
class Splits extends Table {
  /// App-generated integer id (these are created at runtime by the user, so
  /// unlike exercises they use an autoincrementing key rather than a slug).
  IntColumn get id => integer().autoIncrement()();

  /// Display name, e.g. "Push / Pull / Legs".
  TextColumn get name => text().withLength(min: 1, max: 60)();

  /// Sort order of this split in the split list (lower = higher up).
  IntColumn get position => integer().withDefault(const Constant(0))();

  /// When it was created — handy for a default "newest first" ordering.
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

/// A single day within a [Split], e.g. "Push" or "Leg Day A".
class WorkoutDays extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Owning split. If the split is deleted, its days go with it.
  IntColumn get splitId =>
      integer().references(Splits, #id, onDelete: KeyAction.cascade)();

  /// Display name, e.g. "Push".
  TextColumn get name => text().withLength(min: 1, max: 60)();

  /// Sort order of this day within its split (lower = earlier in the week).
  IntColumn get position => integer().withDefault(const Constant(0))();
}

/// One planned exercise slot inside a [WorkoutDay], pointing at a library
/// [Exercises] entry and carrying the default set/rep targets for it.
class WorkoutExercises extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Owning day. If the day is deleted, its planned exercises go with it.
  IntColumn get dayId =>
      integer().references(WorkoutDays, #id, onDelete: KeyAction.cascade)();

  /// Which library exercise this slot is. Text FK because exercise ids are
  /// slugs (see exercise.dart).
  TextColumn get exerciseId => text().references(Exercises, #id)();

  /// Sort order of this exercise within its day.
  IntColumn get position => integer().withDefault(const Constant(0))();

  /// Default number of working sets planned for this exercise.
  IntColumn get defaultSets => integer().withDefault(const Constant(3))();

  /// Default target reps per set.
  IntColumn get defaultReps => integer().withDefault(const Constant(10))();
}
