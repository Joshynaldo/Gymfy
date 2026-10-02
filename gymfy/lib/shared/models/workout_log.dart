import 'package:drift/drift.dart';

import 'exercise.dart';
import 'workout_plan.dart';

/// The tables that record *performed* training (as opposed to the planned
/// programme in workout_plan.dart).
///
/// Shape:
///   WorkoutSession  ──has many──▶  LoggedSet
///                   ──has many──▶  SessionExercise
///
/// A [WorkoutSessions] row is one training session — usually started from a
/// planned [WorkoutDays], but it keeps its own copy of the day's name so the
/// history stays readable even if that plan is later edited or deleted.
/// Each [LoggedSets] row is a single set performed during a session (the
/// weight lifted and reps done for one exercise). [SessionExercises] is the
/// session's own running order — what you meant to do today, which can be
/// added to, swapped and reordered mid-workout without touching the plan.

/// One training session — a workout the user starts, logs sets into, and then
/// finishes.
class WorkoutSessions extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// The planned day this session was started from, if any. Nullable and set
  /// to null (not cascaded) if that day is deleted, so past sessions survive.
  /// Null from the start for a free workout, which follows no plan at all.
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

  /// What kind of set this was — `warmup`, `normal`, `drop` or `failure` —
  /// stored as the `SetType` slug (see set_type.dart). Read it through the
  /// `type` getter on `LoggedSet` (session_repository.dart) rather than
  /// comparing strings.
  ///
  /// Replaced the `is_warmup` boolean in v26: old warm-ups became `warmup` and
  /// everything else `normal`.
  ///
  /// Every type is real work you did and is stored like any other set — all of
  /// them count toward session volume, the muscle map and the recap charts,
  /// because they happened. What warm-ups and drop sets must not do is pretend
  /// to be evidence of strength: a 60 kg single on the way to 100 is not a data
  /// point on your bench chart, is not a PR, and must never talk the overload
  /// suggestion down. See `isWorkingSet` in `session_repository.dart` for the
  /// one place that filter is defined.
  ///
  /// Defaults to `normal` rather than being nullable, like the exercise
  /// equipment column: "untyped" and "working" would render identically, and a
  /// state nobody can see is a state nobody can fix.
  TextColumn get setType =>
      text().withDefault(const Constant('normal')).withLength(max: 20)();

  /// Rate of perceived exertion, 1–10 in half steps (8.5 = "maybe two more").
  /// Null when the set wasn't rated — most sets, since rating is optional and
  /// switched on in Settings.
  RealColumn get rpe => real().nullable()();

  /// Reps in reserve — how many more reps were left in the tank. The other way
  /// of saying [rpe] (RIR ≈ 10 − RPE); a set normally carries whichever one the
  /// user chose to log, never a guess at the other. Null when unrated.
  IntColumn get rir => integer().nullable()();
}

/// One exercise in a session's running order.
///
/// Copied from the planned day when a session starts, then owned by the
/// session: adding, swapping or reordering exercises mid-workout edits these
/// rows and leaves the plan alone (unless the user explicitly saves a swap back
/// to it). A free workout — a session with no day — starts with none and grows
/// them as exercises are added.
///
/// Sessions finished before v26 have no rows here; their history is read from
/// [LoggedSets] as it always was.
class SessionExercises extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Owning session. If the session is deleted, its running order goes too.
  IntColumn get sessionId =>
      integer().references(WorkoutSessions, #id, onDelete: KeyAction.cascade)();

  /// The exercise to do. A swap rewrites this and keeps [workoutExerciseId], so
  /// the plan slot's targets carry over to the replacement.
  TextColumn get exerciseId => text().references(Exercises, #id)();

  /// Sort order within the session (lower = earlier), ties broken by id.
  IntColumn get position => integer().withDefault(const Constant(0))();

  /// The plan slot this came from, which supplies the targets (sets, reps,
  /// warm-ups, percent of 1RM). Null for an exercise added during the
  /// session, and set to null if the slot is later deleted — the session
  /// keeps the exercise either way.
  IntColumn get workoutExerciseId => integer().nullable().references(
    WorkoutExercises,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// The superset this entry is done in, like `WorkoutExercises.supersetGroup`
  /// but for this session's own running order. Null when it stands alone.
  ///
  /// The session's, not the plan's (v28). Copied from the plan slot when the
  /// session starts, then edited here: a free workout or an exercise added
  /// mid-workout has no plan slot to carry a group, and pairing two exercises
  /// for one workout is no reason to rewrite the plan.
  IntColumn get supersetGroup => integer().nullable()();
}
