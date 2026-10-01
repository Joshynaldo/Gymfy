// The words a goal is shown with. Pulled out of the widgets so the Home card,
// the Goals screen and the celebration say the same thing, and so the wording
// can be tested without pumping a screen.

import '../../../shared/models/goal.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/utils/units.dart';
import 'goal_progress.dart';

/// What the goal is: "Bench Press · 100 kg", "3 workouts a week",
/// "Bodyweight · 80 kg".
String goalTitle(
  GoalStatus status, {
  required String? exerciseName,
  required WeightUnit unit,
}) {
  final target = status.goal.target;
  return switch (status.kind) {
    GoalKind.lift =>
      '${exerciseName ?? 'Exercise'} · ${formatWeightUnit(target, unit)}',
    GoalKind.frequency => workoutsPerWeekLabel(target.round()),
    GoalKind.bodyweight => 'Bodyweight · ${formatWeightUnit(target, unit)}',
  };
}

/// "1 workout a week", "3 workouts a week".
String workoutsPerWeekLabel(int count) =>
    '$count ${count == 1 ? 'workout' : 'workouts'} a week';

/// Where the user is now, for the right-hand side of a row: "92.5 kg",
/// "2 of 3", or a dash when there is nothing to show yet.
String goalValue(GoalStatus status, {required WeightUnit unit}) {
  final current = status.current;
  return switch (status.kind) {
    GoalKind.frequency =>
      '${(current ?? 0).round()} of ${status.goal.target.round()}',
    GoalKind.lift || GoalKind.bodyweight =>
      current == null ? '—' : formatWeightUnit(current, unit),
  };
}

/// The line under the bar: how long is left, or what has been done.
String goalCaption(GoalStatus status) {
  if (status.kind == GoalKind.frequency) {
    final target = status.goal.target.round();
    final done = (status.current ?? 0).round();
    final week = status.reached
        ? 'Done this week'
        : '${target - done} to go this week';
    final streak = status.weekStreak;
    if (streak < 2) return week;
    return '$week · $streak weeks in a row';
  }

  final reachedAt = status.reachedAt;
  if (reachedAt != null) return 'Reached ${formatDate(reachedAt)}';

  final deadline = status.goal.deadline;
  final daysLeft = status.daysLeft;
  if (deadline != null && daysLeft != null) {
    if (daysLeft < 0) return 'Was due ${formatDate(deadline)}';
    if (daysLeft == 0) return 'Due today';
    if (daysLeft == 1) return '1 day left';
    if (daysLeft <= 60) return '$daysLeft days left';
    return 'By ${formatDate(deadline)}';
  }

  if (status.current == null) {
    return status.kind == GoalKind.lift ? 'Not trained yet' : 'No weigh-in yet';
  }
  return status.kind == GoalKind.lift
      ? 'Heaviest working set'
      : 'Latest weigh-in';
}
