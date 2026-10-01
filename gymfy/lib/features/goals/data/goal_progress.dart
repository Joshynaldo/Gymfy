// Where a goal stands, worked out from the log.
//
// Everything here is pure: a goal row plus the history it is measured against
// in, a status out. Nothing is stored about reaching a goal except when its
// celebration was seen (see the `Goals` table), so deleting the set that hit a
// target quietly un-reaches it again — the same "derived, never counted"
// rule the training totals follow.
//
// How each kind is judged, so the Home card, the Goals screen and the tests
// never disagree:
//
// - **Lift:** the heaviest *working* set on the exercise (warm-ups and drop
//   sets never count — the strength filter in session_repository.dart), at
//   any rep count, or a tested one-rep max. Deliberately not the estimated
//   1RM. "Lift 100 kg" is a sentence about the bar: a formula reading
//   90 kg × 6 as "about 105" would declare the goal met on a day nobody had
//   100 kg in their hands. The estimate is still on the progress screen for
//   anyone who wants it.
// - **Bodyweight:** the latest weigh-in, measured from the weight the goal
//   started at. A target below the start is a cut, above it a gain. Reached
//   the first day a weigh-in on or after the goal was set crosses the target —
//   and it stays reached if the scale bounces back, because the goal was "get
//   there", not "stay there".
// - **Workouts per week:** completed workouts in the current week, which
//   starts on the phone's first day of the week. It never finishes; it is met
//   or not, week by week.

import '../../../shared/database/app_database.dart';
import '../../../shared/models/goal.dart';
import '../../../shared/utils/dates.dart';
import '../../progress/data/measurements_repository.dart' show MeasurementPoint;
import '../../progress/data/progress_repository.dart' show ExerciseHistoryPoint;

/// Floating-point dust allowance — 99.99999 kg is 100 kg.
const _epsilon = 0.001;

/// Where one goal stands today.
class GoalStatus {
  const GoalStatus({
    required this.goal,
    required this.kind,
    required this.current,
    required this.fraction,
    required this.reachedAt,
    required this.daysLeft,
    this.weekStreak = 0,
  });

  final Goal goal;
  final GoalKind kind;

  /// Where the user is now, in the goal's unit: kilograms for a lift or a
  /// bodyweight, workouts this week for a frequency goal. Null when there is
  /// nothing to go on yet — a lift never trained, a bodyweight never logged.
  final double? current;

  /// How far from the start to the target, 0–1. Full once reached.
  final double fraction;

  /// When the log first met the target — this week's, for a frequency goal.
  /// Null while it hasn't.
  ///
  /// As precise as the log is: the workout's own time for a lift or a week,
  /// the day for a weigh-in or a tested max, which carry no time.
  final DateTime? reachedAt;

  /// Calendar days until the deadline: 0 on the day itself, negative once it
  /// has passed. Null without a deadline.
  final int? daysLeft;

  /// Weeks in a row the target was met, counting this week only once it has
  /// been. Frequency goals only; zero for the others.
  final int weekStreak;

  bool get reached => reachedAt != null;

  bool get archived => goal.archivedAt != null;

  /// Past its deadline without getting there.
  bool get overdue => !reached && daysLeft != null && daysLeft! < 0;

  /// Reached, and the user has not seen it celebrated yet.
  ///
  /// A frequency goal is celebrated once a week: a celebration seen before
  /// this week's target was met — last week's, say, opened on Monday morning —
  /// does not cover this week.
  bool get celebrate {
    if (!reached || archived) return false;
    final seen = goal.celebratedAt;
    if (seen == null) return true;
    if (kind != GoalKind.frequency) return false;
    return seen.isBefore(reachedAt!);
  }

  /// Whether the goal is still being worked on — live, and (frequency goals
  /// aside, which never finish) not reached yet.
  bool get inProgress => !archived && (kind == GoalKind.frequency || !reached);
}

/// A lift goal, judged on the heaviest working set or a tested max.
///
/// [history] is the exercise's per-session history from the progress
/// repository — working sets only, oldest first — and [tested] its tested
/// one-rep max, if any.
GoalStatus liftGoalStatus(
  Goal goal, {
  required List<ExerciseHistoryPoint> history,
  required TestedOneRm? tested,
  required DateTime today,
}) {
  double? best;
  DateTime? reachedAt;

  void consider(double weight, DateTime on) {
    if (weight <= 0) return;
    if (best == null || weight > best!) best = weight;
    if (weight + _epsilon >= goal.target &&
        (reachedAt == null || on.isBefore(reachedAt!))) {
      reachedAt = on;
    }
  }

  for (final point in history) {
    consider(point.topWeight, point.date);
  }
  if (tested != null) consider(tested.weightKg, tested.testedOn);

  return GoalStatus(
    goal: goal,
    kind: GoalKind.lift,
    current: best,
    fraction: reachedAt != null
        ? 1
        : _fractionUp(
            start: goal.startValue ?? 0,
            now: best ?? 0,
            to: goal.target,
          ),
    reachedAt: reachedAt,
    daysLeft: _daysLeft(goal, today),
  );
}

/// The heaviest weight a lift goal on this exercise would count — the best
/// working set in [history] or the [tested] max — or null if neither exists.
///
/// What a new lift goal starts from, and what its target has to beat.
double? bestLiftKg(List<ExerciseHistoryPoint> history, TestedOneRm? tested) {
  double? best;
  for (final point in history) {
    if (point.topWeight > 0 && (best == null || point.topWeight > best)) {
      best = point.topWeight;
    }
  }
  if (tested != null && (best == null || tested.weightKg > best)) {
    best = tested.weightKg;
  }
  return best;
}

/// A bodyweight goal, judged on the weigh-ins in [weights] (oldest first, as
/// `seriesFor` returns them).
GoalStatus bodyweightGoalStatus(
  Goal goal, {
  required List<MeasurementPoint> weights,
  required DateTime today,
}) {
  final latest = weights.isEmpty ? null : weights.last.value;
  final start =
      goal.startValue ?? (weights.isEmpty ? null : weights.first.value);
  // Which way is forward. A goal with no start to compare against (which the
  // form does not allow) is read as a cut — the more common of the two.
  final losing = start == null || goal.target <= start;
  final since = dateOnly(goal.createdAt);

  DateTime? reachedAt;
  for (final point in weights) {
    if (point.day.isBefore(since)) continue;
    final crossed = losing
        ? point.value <= goal.target + _epsilon
        : point.value + _epsilon >= goal.target;
    if (crossed) {
      reachedAt = dateOnly(point.day);
      break;
    }
  }

  final double fraction;
  if (reachedAt != null) {
    fraction = 1;
  } else if (start == null || latest == null) {
    fraction = 0;
  } else if (losing) {
    fraction = _fractionUp(start: -start, now: -latest, to: -goal.target);
  } else {
    fraction = _fractionUp(start: start, now: latest, to: goal.target);
  }

  return GoalStatus(
    goal: goal,
    kind: GoalKind.bodyweight,
    current: latest,
    fraction: fraction,
    reachedAt: reachedAt,
    daysLeft: _daysLeft(goal, today),
  );
}

/// A workouts-per-week goal, judged on [finishedAt] — one entry per completed
/// workout, when it finished (two workouts on one day are two entries), the
/// same moment the streak and the recap date a workout by.
GoalStatus frequencyGoalStatus(
  Goal goal, {
  required Iterable<DateTime> finishedAt,
  required DateTime today,
  required int firstWeekday,
}) {
  final target = goal.target.round() < 1 ? 1 : goal.target.round();

  // Workouts per week, keyed by the week's first day.
  final perWeek = <DateTime, List<DateTime>>{};
  for (final moment in finishedAt) {
    perWeek
        .putIfAbsent(startOfWeek(dateOnly(moment), firstWeekday), () => [])
        .add(moment);
  }

  final thisWeek = startOfWeek(dateOnly(today), firstWeekday);
  final done = [...?perWeek[thisWeek]]..sort();
  final reachedAt = done.length >= target ? done[target - 1] : null;

  // Back from this week if it is already met, otherwise from last week: a
  // Monday morning with nothing done yet hasn't broken anything.
  var streak = 0;
  var week = reachedAt != null
      ? thisWeek
      : DateTime(thisWeek.year, thisWeek.month, thisWeek.day - 7);
  while ((perWeek[week]?.length ?? 0) >= target) {
    streak++;
    week = DateTime(week.year, week.month, week.day - 7);
  }

  return GoalStatus(
    goal: goal,
    kind: GoalKind.frequency,
    current: done.length.toDouble(),
    fraction: (done.length / target).clamp(0.0, 1.0),
    reachedAt: reachedAt,
    daysLeft: null,
    weekStreak: streak,
  );
}

/// Progress from [start] towards a higher [to], given where things are
/// [now], as 0–1. A target at or below the start reads as empty until it is
/// reached rather than dividing by zero.
double _fractionUp({
  required double start,
  required double now,
  required double to,
}) {
  final span = to - start;
  if (span <= 0) return 0;
  return ((now - start) / span).clamp(0.0, 1.0);
}

int? _daysLeft(Goal goal, DateTime today) {
  final deadline = goal.deadline;
  if (deadline == null) return null;
  return daysBetween(today, deadline);
}

/// What the user is about to save, before it is a row.
class GoalDraft {
  const GoalDraft({
    required this.kind,
    required this.target,
    this.exerciseId,
    this.startValue,
    this.deadline,
  });

  final GoalKind kind;

  /// Kilograms for a lift or bodyweight, workouts per week for frequency.
  final double target;
  final String? exerciseId;
  final double? startValue;
  final DateTime? deadline;
}

/// The most workouts a week a goal may ask for.
const maxWorkoutsPerWeek = 7;

/// Why [draft] can't be saved, worded for the person filling in the form, or
/// null when it can.
///
/// [bestLiftKg] is the heaviest working set already logged on the chosen
/// exercise; [today] is used to refuse a deadline in the past.
String? goalDraftProblem(
  GoalDraft draft, {
  required DateTime today,
  double? bestLiftKg,
}) {
  final deadline = draft.deadline;
  if (deadline != null && dateOnly(deadline).isBefore(dateOnly(today))) {
    return 'Pick a date that has not passed yet.';
  }
  switch (draft.kind) {
    case GoalKind.lift:
      if (draft.exerciseId == null) return 'Choose the exercise.';
      if (draft.target <= 0) return 'Set the weight to reach.';
      // Already done is not a goal — and saving it would celebrate on the
      // spot, for something that happened before it was asked for.
      if (bestLiftKg != null && draft.target <= bestLiftKg + _epsilon) {
        return 'You have already lifted that — aim higher.';
      }
    case GoalKind.frequency:
      if (draft.target < 1 || draft.target > maxWorkoutsPerWeek) {
        return 'Pick between 1 and $maxWorkoutsPerWeek workouts a week.';
      }
    case GoalKind.bodyweight:
      if (draft.target <= 0) return 'Set the weight to reach.';
      final start = draft.startValue;
      if (start == null) return 'Log your current weight first.';
      if ((draft.target - start).abs() < _epsilon) {
        return 'That is the weight you are now — pick a different one.';
      }
  }
  return null;
}
