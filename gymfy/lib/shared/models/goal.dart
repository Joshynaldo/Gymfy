import 'package:drift/drift.dart';

import 'exercise.dart';

/// Something the user is working towards: a weight on one lift, a number of
/// workouts a week, or a bodyweight.
///
/// Only the *intent* is stored. Whether a goal has been reached, and how close
/// it is, is worked out from the log every time it is shown (see
/// `features/goals/data/goal_progress.dart`) — the same rule the training
/// totals follow. A stored "reached" flag would be one more thing to keep in
/// step with a deleted set, and it would go stale silently when it failed.
///
/// Added in schema v27.
class Goals extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// What kind of goal this is, as the [GoalKind] slug (`lift`, `frequency`,
  /// `bodyweight`). Read it through [GoalKind.parse] rather than comparing
  /// strings.
  TextColumn get kind => text().withLength(max: 20)();

  /// The exercise a `lift` goal is about. Null for the other kinds.
  ///
  /// Deleting the exercise deletes the goal: a target on a lift that no longer
  /// exists has nothing left to measure. (A custom exercise with any history
  /// is archived rather than deleted, so this only fires for one that was
  /// never trained.)
  TextColumn get exerciseId => text().nullable().references(
    Exercises,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// The number to reach, in the kind's own unit: kilograms for `lift` and
  /// `bodyweight` (stored canonically, like every weight), workouts per week
  /// for `frequency`.
  RealColumn get target => real()();

  /// Where the user stood when the goal was set, in the same unit — the best
  /// working weight on the lift, or the latest bodyweight. Progress is
  /// measured from here, so a 95 → 100 kg goal starts empty rather than at
  /// 95%.
  ///
  /// For a bodyweight goal it also says which way is forward: a target below
  /// it is a cut, above it a gain. Null for `frequency`, which starts from
  /// zero every week, and for a lift never trained before.
  RealColumn get startValue => real().nullable()();

  /// The day to reach it by, or null for "whenever". Never set on `frequency`
  /// goals, which repeat every week rather than ending.
  DateTimeColumn get deadline => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// When the user saw this goal's celebration. Null until then.
  ///
  /// The one piece of reaching a goal that *is* stored, because it is about
  /// the user rather than the log: the celebration shows once, not every time
  /// Home is opened. For a `frequency` goal it is the last week celebrated —
  /// a new week that meets the target earns a new one.
  DateTimeColumn get celebratedAt => dateTime().nullable()();

  /// When the goal was put away. Archived goals leave Home and the active
  /// list but keep their history; null while the goal is live.
  DateTimeColumn get archivedAt => dateTime().nullable()();
}

/// The kinds of goal there are, stored on `goals.kind` as the enum's [name].
enum GoalKind {
  /// Lift a weight on one exercise.
  lift('Lift'),

  /// Train a number of times a week.
  frequency('Workouts'),

  /// Reach a bodyweight.
  bodyweight('Bodyweight');

  const GoalKind(this.label);

  final String label;

  /// Reads a stored slug, or null for one this build does not know.
  ///
  /// Null rather than a fallback: guessing that an unknown goal is, say, a
  /// lift would measure it against the wrong numbers. A goal a newer build
  /// wrote is left alone instead of being shown wrongly.
  static GoalKind? parse(String? raw) {
    for (final kind in GoalKind.values) {
      if (kind.name == raw) return kind;
    }
    return null;
  }
}
