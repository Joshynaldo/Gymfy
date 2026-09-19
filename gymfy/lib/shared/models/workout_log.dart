import 'package:drift/drift.dart';

import 'exercise.dart';
import 'workout_plan.dart';

/// The two tables that record *performed* training (as opposed to the planned
/// programme in workout_plan.dart).
///
/// Shape:
///   WorkoutSession  ──has many──▶  LoggedSet
///
/// A [WorkoutSessions] row is one training session — usually started from a
/// planned [WorkoutDays], but it keeps its own copy of the day's name so the
/// history stays readable even if that plan is later edited or deleted.
/// Each [LoggedSets] row is a single set performed during a session (the
/// weight lifted and reps done for one exercise).

/// One training session — a workout the user starts, logs sets into, and then
/// finishes.
class WorkoutSessions extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// The planned day this session was started from, if any. Nullable and set
  /// to null (not cascaded) if that day is deleted, so past sessions survive.
  IntColumn get dayId => integer().nullable().references(
    WorkoutDays,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// A readable label for the session, snapshotted from the day name at start
  /// time (e.g. "Push"). Kept on the row so history doesn't depend on the plan.
  TextColumn get name => text().withLength(min: 1, max: 60)();

  /// When the session was started.
  DateTimeColumn get startedAt => dateTime().withDefault(currentDateAndTime)();

  /// When the session was finished. Null while it's still in progress.
  DateTimeColumn get completedAt => dateTime().nullable()();
}

/// A single set performed in a session: the weight and reps for one exercise.
class LoggedSets extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Owning session. If the session is deleted, its sets go with it.
  IntColumn get sessionId =>
      integer().references(WorkoutSessions, #id, onDelete: KeyAction.cascade)();

  /// Which library exercise this set is for (text FK — exercise ids are slugs).
  TextColumn get exerciseId => text().references(Exercises, #id)();

  /// 1-based position of this set within its exercise for this session
  /// (set 1, set 2, …).
  IntColumn get setNumber => integer()();

  /// Weight lifted. A real number so half-kilo / half-pound plates work.
  RealColumn get weight => real().withDefault(const Constant(0))();

  /// Reps completed for this set. Zero on a set logged by time.
  IntColumn get reps => integer().withDefault(const Constant(0))();

  /// How long the set was held, in seconds — planks, hangs, wall sits, loaded
  /// carries. Null on an ordinary set counted in reps.
  ///
  /// Null rather than zero, because the two say different things: zero would
  /// be a set that lasted no time, and every screen deciding how to render a
  /// set reads exactly this distinction. A set has one or the other, never
  /// both — a plank has no rep count and a bench press has no useful duration.
  ///
  /// [weight] still applies: a loaded carry and a weighted plank both have
  /// one, and a set of 45 seconds with 20 kg is a different set from 45
  /// seconds with nothing.
  IntColumn get seconds => integer().nullable()();

  /// Whether this was a ramp-up set rather than a working set.
  ///
  /// Warm-ups are real work you did and are stored like any other set — they
  /// still count toward session volume, the muscle map and the recap charts,
  /// because they happened. What they must not do is pretend to be evidence of
  /// strength: a 60 kg single on the way to 100 is not a data point on your
  /// bench chart, is not a PR, and must never talk the overload suggestion
  /// down. See `isWorkingSet` in `session_repository.dart` for the one place
  /// that filter is defined.
  BoolColumn get isWarmup => boolean().withDefault(const Constant(false))();
}
