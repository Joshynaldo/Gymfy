// The words a goal is shown with. Pulled out of the widgets so the Home card,
// the Goals screen and the celebration say the same thing, and so the wording
// can be tested without pumping a screen.
//
// Each takes an optional `l10n` like the helpers in shared/utils/format.dart:
// without it they print the English the app has always shown.

import '../../../l10n/l10n.dart';
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
  AppLocalizations? l10n,
}) {
  final strings = l10n ?? englishLocalizations;
  final target = status.goal.target;
  final weight = formatWeightUnit(target, unit, l10n: l10n);
  return switch (status.kind) {
    GoalKind.lift => '${exerciseName ?? strings.goalsExercise} · $weight',
    GoalKind.frequency => workoutsPerWeekLabel(target.round(), l10n: l10n),
    GoalKind.bodyweight => strings.goalsTitleBodyweight(weight),
  };
}

/// "1 workout a week", "3 workouts a week".
String workoutsPerWeekLabel(int count, {AppLocalizations? l10n}) =>
    (l10n ?? englishLocalizations).goalsWorkoutsPerWeek(count);

/// Where the user is now, for the right-hand side of a row: "92.5 kg",
/// "2 of 3", or a dash when there is nothing to show yet.
String goalValue(
  GoalStatus status, {
  required WeightUnit unit,
  AppLocalizations? l10n,
}) {
  final current = status.current;
  return switch (status.kind) {
    GoalKind.frequency => (l10n ?? englishLocalizations).goalsValueOf(
      (current ?? 0).round(),
      status.goal.target.round(),
    ),
    GoalKind.lift || GoalKind.bodyweight =>
      current == null ? '—' : formatWeightUnit(current, unit, l10n: l10n),
  };
}

/// The line under the bar: how long is left, or what has been done.
String goalCaption(GoalStatus status, {AppLocalizations? l10n}) {
  final strings = l10n ?? englishLocalizations;
  if (status.kind == GoalKind.frequency) {
    final target = status.goal.target.round();
    final done = (status.current ?? 0).round();
    final week = status.reached
        ? strings.goalsCaptionWeekDone
        : strings.goalsCaptionWeekToGo(target - done);
    final streak = status.weekStreak;
    if (streak < 2) return week;
    return '$week · ${strings.goalsCaptionWeeksInARow(streak)}';
  }

  final reachedAt = status.reachedAt;
  if (reachedAt != null) {
    return strings.goalsCaptionReached(formatDate(reachedAt, l10n: l10n));
  }

  final deadline = status.goal.deadline;
  final daysLeft = status.daysLeft;
  if (deadline != null && daysLeft != null) {
    final date = formatDate(deadline, l10n: l10n);
    if (daysLeft < 0) return strings.goalsCaptionWasDue(date);
    if (daysLeft == 0) return strings.goalsCaptionDueToday;
    if (daysLeft <= 60) return strings.goalsCaptionDaysLeft(daysLeft);
    return strings.goalsCaptionBy(date);
  }

  if (status.current == null) {
    return status.kind == GoalKind.lift
        ? strings.goalsCaptionNotTrained
        : strings.goalsCaptionNoWeighIn;
  }
  return status.kind == GoalKind.lift
      ? strings.goalsCaptionHeaviest
      : strings.goalsCaptionLatestWeighIn;
}
