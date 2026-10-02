import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../l10n/l10n.dart';
import '../../../shared/database/app_database.dart';
import '../../../shared/models/equipment.dart';
import '../../../shared/utils/units.dart';
import '../../overload/data/overload_math.dart';
import '../../overload/data/overload_repository.dart';
import 'session_repository.dart';

part 'next_set.g.dart';

// "Where am I, and what do I do next?" for a running workout.
//
// The active workout screen answered this for itself, from state it kept in
// its own widget. The ongoing notification and the watch need the same answer
// with the screen nowhere in sight — the phone is in a pocket, which is the
// whole point of both — so it lives here, and all three read it. One answer
// in three places beats three answers that disagree about which exercise you
// are on.

/// The exercise you picked by hand on the active workout, if you picked one.
///
/// Held by id rather than by index: the running order can be added to,
/// swapped and reordered mid-session, and an index would then point at a
/// different movement. (A lift appears once per session, so the id is
/// enough.)
///
/// A provider rather than widget state so a set logged from the notification
/// or the wrist can move it too — mid-superset that is exactly what has to
/// happen — and so the notification shows the exercise the card shows.
/// Disposed with its last listener, like the screen state it replaced.
@riverpod
class PickedExercise extends _$PickedExercise {
  @override
  String? build(int sessionId) => null;

  /// Puts the card on [exerciseId]; null hands the choice back to the plan.
  void pick(String? exerciseId) => state = exerciseId;
}

/// The exercise the active workout is on.
///
/// [picked] if it is still in the running order, otherwise the first exercise
/// still short of its planned working sets — which is where you are on any day
/// you work through the plan in order — and the last one once everything is
/// done. Null only for an empty workout.
SessionExerciseEntry? currentSessionEntry(
  List<SessionExerciseEntry> entries,
  List<LoggedSet> sets, {
  String? picked,
}) {
  if (entries.isEmpty) return null;
  if (picked != null) {
    for (final entry in entries) {
      if (entry.exercise.id == picked) return entry;
    }
  }
  for (final entry in entries) {
    if (workingPhaseSets(sets, entry.exercise.id) < entry.targets.defaultSets) {
      return entry;
    }
  }
  return entries.last;
}

/// How many sets of [exerciseId] are in the working phase — everything but
/// warm-ups, drop and failure sets included.
///
/// The count sets are numbered by ("so working sets read 1, 2, 3 however long
/// the ramp-up was") and the one "Set 3 of 4" is about.
int workingPhaseSets(List<LoggedSet> sets, String exerciseId) =>
    sets.where((s) => s.exerciseId == exerciseId && !s.isWarmup).length;

/// The hold offered for a timed exercise with nothing to go on yet.
///
/// Only ever a starting point for the watch's controls, where you see it and
/// change it before anything is logged — it is never logged on one tap.
const placeholderHoldSeconds = 30;

/// The set the app would put in front of you next.
typedef NextSet = ({
  String exerciseId,
  String exerciseName,

  /// Its number among the working-phase sets of the exercise, this one
  /// included.
  int setNumber,

  /// Working sets planned for the exercise.
  int plannedSets,

  /// In kilograms, as stored.
  double weightKg,

  /// Reps for a counted set; zero for a hold.
  int reps,

  /// The hold for a timed exercise; null for a counted set. A set is one or
  /// the other, never both — the same rule the log sheet follows.
  int? seconds,

  /// Whether the numbers come from something real: a set you did today, the
  /// overload suggestion, or a bodyweight movement's own zero.
  ///
  /// Only a confident set is offered as one-tap logging. A guess — no history,
  /// no suggestion, a barbell lift — still prefills the watch's controls,
  /// where you see it and change it first, but a notification button that
  /// logged "0 kg × 10" would write a set nobody did.
  bool confident,
});

/// What to log next for [entry], given the session's [sets] so far.
///
/// The same numbers the log sheet would open with, with one deliberate
/// difference: the repeat source is the last *working* set ([isWorkingSet]),
/// never a warm-up or a stripped-down drop set — "the same again" from a
/// pocket means the set you are building towards.
///
/// [suggestion] is the overload suggestion, and only consulted before the
/// first working-phase set of the exercise: after that, what you actually
/// lifted today is the better guess, exactly as on the card.
NextSet nextSetFor(
  SessionExerciseEntry entry,
  List<LoggedSet> sets, {
  OverloadSuggestion? suggestion,
}) {
  final exercise = entry.exercise;
  final targets = entry.targets;
  final done = workingPhaseSets(sets, exercise.id);
  final mine = sets.where(
    (s) => s.exerciseId == exercise.id && isWorkingSet(s),
  );
  final last = mine.isEmpty ? null : mine.last;
  final suggested = done == 0 ? suggestion : null;

  NextSet result({
    required double weightKg,
    int reps = 0,
    int? seconds,
    required bool confident,
  }) => (
    exerciseId: exercise.id,
    exerciseName: exercise.name,
    setNumber: done + 1,
    plannedSets: targets.defaultSets,
    weightKg: weightKg,
    reps: reps,
    seconds: seconds,
    confident: confident,
  );

  if (exercise.isTimed) {
    final held = last?.seconds;
    return result(
      weightKg: last?.weight ?? suggested?.weight ?? 0,
      seconds: held ?? placeholderHoldSeconds,
      confident: held != null && held > 0,
    );
  }

  if (last != null && last.seconds == null && last.reps > 0) {
    return result(weightKg: last.weight, reps: last.reps, confident: true);
  }
  if (suggested != null) {
    return result(
      weightKg: suggested.weight,
      reps: targets.defaultReps,
      confident: true,
    );
  }
  return result(
    weightKg: 0,
    reps: targets.defaultReps,
    // Zero is a real answer for a pull-up and a placeholder for a squat.
    confident: Equipment.parse(exercise.equipment) == Equipment.bodyweight,
  );
}

/// "Set 3 of 4" — or "Set 5" once the plan's sets are behind you, because
/// "Set 5 of 4" reads like a bug.
///
/// In [l10n]'s language when given ("Satz 3 von 4"), else English — the
/// notification and the watch have no context to read one from.
String describeSetPosition(NextSet next, {AppLocalizations? l10n}) {
  final strings = l10n ?? englishLocalizations;
  return next.setNumber <= next.plannedSets
      ? strings.workoutSetPositionOf(next.setNumber, next.plannedSets)
      : strings.workoutSetPosition(next.setNumber);
}

/// The numbers of [next], as one line: `80 kg × 8 reps`, `12 reps` with
/// nothing on the bar, `1:30` for a hold.
String describeNextNumbers(
  NextSet next,
  WeightUnit unit, {
  AppLocalizations? l10n,
}) {
  final seconds = next.seconds;
  if (seconds == null && next.weightKg <= 0) {
    return (l10n ?? englishLocalizations).workoutReps(next.reps);
  }
  return formatLoggedSet(
    weightKg: next.weightKg,
    reps: next.reps,
    seconds: seconds,
    unit: unit,
    l10n: l10n,
  );
}

/// The next set of a running session, for anything that is not the screen.
///
/// Null for an empty workout. Recomputed when a set is logged, the order
/// changes or a different exercise is picked; while it recomputes, readers
/// keep the previous answer rather than flashing an empty one.
final nextSetProvider = FutureProvider.autoDispose.family<NextSet?, int>((
  ref,
  sessionId,
) async {
  final picked = ref.watch(pickedExerciseProvider(sessionId));
  final entries = await ref.watch(sessionExercisesProvider(sessionId).future);
  final sets = await ref.watch(sessionSetsProvider(sessionId).future);

  final current = currentSessionEntry(entries, sets, picked: picked);
  if (current == null) return null;

  // Awaited only when it can matter, for the same reason as on the card: it
  // is a database read, and after the first working set it is not used.
  final suggestion = workingPhaseSets(sets, current.exercise.id) == 0
      ? await ref.watch(
          overloadSuggestionProvider((
            entry: current.targets,
            exercise: current.exercise,
          )).future,
        )
      : null;
  return nextSetFor(current, sets, suggestion: suggestion);
});
