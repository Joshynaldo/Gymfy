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

  /// Whether this is the programme currently being followed.
  ///
  /// At most one split is active at a time (enforced in the repository, not by
  /// the schema — SQLite has no "only one row may be true" constraint). Only the
  /// active split's [WorkoutDaySchedules] decide what today is, so an old split
  /// kept around for reference can't fight the current one over Mondays.
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();

  /// When it was created — handy for a default "newest first" ordering.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
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

/// Which weekdays a [WorkoutDays] is trained on.
///
/// A separate table rather than a column, because one day routinely lands on
/// several weekdays: a six-day PPL puts Push on Monday *and* Thursday. Storing
/// a single weekday would force two identical "Push" days, splitting their
/// logged history across two ids.
///
/// A weekday with no row here is a rest day. That's an absence rather than a
/// stored fact on purpose — there's no way for "rest" and "no workout assigned"
/// to disagree if only one of them exists.
class WorkoutDaySchedules extends Table {
  /// The day being scheduled. Removed with it.
  IntColumn get dayId =>
      integer().references(WorkoutDays, #id, onDelete: KeyAction.cascade)();

  /// ISO-8601 weekday: 1 = Monday … 7 = Sunday, matching `DateTime.weekday`
  /// so "is this day today?" needs no conversion.
  IntColumn get weekday => integer()();

  /// One row per (day, weekday): assigning the same day to Monday twice is
  /// meaningless, so the key makes it impossible.
  @override
  Set<Column> get primaryKey => {dayId, weekday};
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

  /// How many ramp-up sets to plan before the working sets.
  ///
  /// Zero for most exercises — you don't warm up for a cable curl.
  ///
  /// A target, not pre-created rows. The session shows "Warm-up 1 of 3" and
  /// keeps offering the button until you've logged that many; it never inserts
  /// placeholder sets, because a 0 kg row you didn't perform would still count
  /// toward your session volume and your muscle map.
  IntColumn get warmupSets => integer().withDefault(const Constant(0))();

  /// Default target reps per set — the bottom of the range when there is one.
  IntColumn get defaultReps => integer().withDefault(const Constant(10))();

  // Progressive overload is configured once for the whole app rather than per
  // exercise — whether to progress, by how much, and whether to deload all live
  // in overload/data/overload_preference.dart. Nothing about it is stored here.

  /// Top of the rep range, e.g. 12 in "3 × 8–12". Null means a fixed target
  /// rather than a range.
  ///
  /// Nullable rather than defaulting to the same value as [defaultReps]: a
  /// fixed 10 should read as "10", not "10–10", and storing them identically
  /// would leave no way to tell "no range" from "a range of one number".
  IntColumn get defaultRepsMax => integer().nullable()();
}
