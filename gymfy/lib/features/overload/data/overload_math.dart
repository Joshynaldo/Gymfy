// Progressive overload: deciding what to suggest for the next set.
//
// The method is double progression. You work up through a rep range at one
// weight, and only when every planned set reaches the top of the range does the
// weight go up — at which point the reps drop back to the bottom of the range
// and the climb starts again.
//
// Two consequences worth stating, because they're what make it trustworthy:
//
// - A suggestion is built from the weight you ACTUALLY LIFTED last time, read
//   out of your logged sets, not from a target stored in the plan. If you
//   deloaded by hand, took three weeks off, or moved the exercise to another
//   day, the next suggestion follows reality instead of a plan that drifted.
//
// - A bad session simply doesn't trigger an increase. Nothing accumulates, no
//   debt is carried, and the number never runs away from what you can lift —
//   which is the failure mode of a calendar-driven increase.
//
// One more rule rides on top, and only when sets were rated for effort (RPE or
// RIR, see `effort_rating_mode`):
//
// - **A maxed-out top set holds the weight.** If every planned set hit the top
//   of the range but a set at the session's top weight was rated RPE 9.5 or
//   higher — or RIR 0, which is the same claim made the other way round — the
//   reps were earned with nothing left in the tank. Adding weight to a set you
//   only just finished is how a lift stalls the week after, so the suggestion
//   repeats the weight instead ([OverloadReason.atLimit]). The rating is read
//   through `effectiveRir`, so RPE 9.5 and 10 both land on RIR 0 and the two
//   scales cannot disagree about where the line is. An unrated set never
//   triggers it: a rating only ever holds an increase back, it never invents
//   one. Ratings are read whenever they are stored, even if rating has since
//   been switched off — the setting decides what the sheet asks, not what the
//   history means.
//
// Everything here is kilograms, like the rest of the stored data.

import '../../../shared/database/app_database.dart';
import '../../../shared/models/set_type.dart';
import '../../workout/data/session_repository.dart' show LoggedSetType;

/// Per-muscle weekly increments, in kilograms added to the bar.
///
/// Smaller muscles get smaller jumps: adding 5 kg to a lateral raise is a
/// different proposition from adding it to a squat. These are starting points —
/// every planned exercise can override its own.
const _incrementByMuscle = <String, double>{
  // Legs take the biggest jumps and recover fastest from them.
  'quads': 5,
  'glutes': 5,
  'hamstrings': 5,
  'calves': 5,
  // Back.
  'lats': 2.5,
  'trapezius': 2.5,
  'lower_back': 2.5,
  // Chest.
  'chest': 2.5,
  // Shoulders — small muscles, small steps.
  'front_deltoid': 1.25,
  'side_deltoid': 1.25,
  'rear_deltoid': 1.25,
  // Arms.
  'biceps': 1.25,
  'triceps': 1.25,
  'forearms': 1.25,
  'adductors': 2.5,
};

/// The fallback when an exercise trains nothing we have a rate for.
const fallbackIncrementKg = 2.5;

/// Muscles that get no automatic weight increase.
///
/// Core work progresses by reps and time under tension; suggesting +2.5 kg on a
/// plank is meaningless, and on a crunch it's how people hurt their necks.
const noOverloadMuscles = {'abs', 'obliques', 'neck'};

/// The default weekly increment for an exercise, from the muscles it trains.
///
/// The *smallest* rate among them, not the average: an exercise that hits both
/// quads and biceps is limited by the biceps, and overshooting the weakest link
/// is what stalls a lift. Returns null when the exercise shouldn't be
/// auto-progressed at all.
double? defaultIncrementKg(List<String> muscleIds) {
  final trainable = muscleIds.where((m) => !noOverloadMuscles.contains(m));
  if (trainable.isEmpty) return null;

  double? smallest;
  for (final muscleId in trainable) {
    final rate = _incrementByMuscle[muscleId] ?? fallbackIncrementKg;
    if (smallest == null || rate < smallest) smallest = rate;
  }
  return smallest;
}

/// Why a suggested weight is what it is.
enum OverloadReason {
  /// Every planned set hit the top of the rep range — time to add weight.
  earned,

  /// The last session fell short, so the weight stays put.
  repeat,

  /// Enough increases in a row that a lighter week is due.
  deload,

  /// The reps were all there, but the top set was rated a limit effort
  /// (RPE 9.5+ / RIR 0), so the weight holds — see [topSetAtLimit].
  atLimit,

  /// No history for this exercise yet, so there is nothing to base a step on.
  firstTime,

  /// The plan names a percentage of the 1RM, and the weight is that share of
  /// the tested or estimated max. See [OverloadSuggestion.targetPercent].
  percentOfMax,

  /// The split's training block is in its deload week, so the weight is the
  /// block's deload percentage of the working weight (or of the %1RM weight).
  /// See [OverloadSuggestion.deloadPercent].
  blockDeload,
}

/// What to put in front of the user for their next set.
class OverloadSuggestion {
  const OverloadSuggestion({
    required this.weight,
    required this.reason,
    this.targetPercent,
    this.deloadPercent,
  });

  /// In kilograms. Still needs rounding to something loadable — see
  /// `loadableSuggestion` in overload_repository.dart, which knows the user's
  /// plates.
  final double weight;

  final OverloadReason reason;

  /// The plan's percentage of 1RM this weight was worked out from, 0–100.
  /// Set for [OverloadReason.percentOfMax], and for a block deload of a
  /// percentage target; null otherwise.
  final double? targetPercent;

  /// The training block's deload load, 0–100 of the working weight. Set only
  /// for [OverloadReason.blockDeload].
  final double? deloadPercent;

  bool get isIncrease => reason == OverloadReason.earned;
}

/// The rep count that has to be reached on every set for the weight to go up.
///
/// The top of the range when there is one — that's the whole point of double
/// progression. A fixed target is its own ceiling.
int targetRepsFor(WorkoutExercise entry) =>
    entry.defaultRepsMax ?? entry.defaultReps;

/// Whether a session's sets earned an increase.
///
/// Requires the planned number of sets AND the target reps on every one of
/// them. Doing four of five sets at the top of the range is a good session, but
/// it isn't the session that was planned, and treating it as one is how the
/// weight starts climbing past what you can hold.
bool earnedIncrease({
  required List<LoggedSet> sets,
  required int plannedSets,
  required int targetReps,
}) {
  if (sets.length < plannedSets) return false;
  return sets.take(plannedSets).every((set) => set.reps >= targetReps);
}

/// The highest reps-in-reserve that still counts as a limit effort. RPE 9.5
/// derives to this (10 − 9.5, rounded down), as do RPE 10 and a logged RIR 0.
const limitEffortRir = 0;

/// Whether a set at the top weight of [sets] was a limit effort — rated
/// RPE 9.5 or higher or RIR 0, or tagged as a set taken to failure.
///
/// Any set at the top weight, not just the last one: on a straight-sets day
/// the grinder may be the second of three, and it is still the evidence that
/// the weight is at its ceiling. A failure set is RIR 0 by definition, so the
/// two ways of recording the same effort hold the weight alike, rating mode on
/// or off. Unrated, untagged sets say nothing either way.
bool topSetAtLimit(List<LoggedSet> sets) {
  final top = topWeight(sets);
  if (top == null) return false;
  return sets.any((set) {
    if ((set.weight - top).abs() > 0.001) return false;
    if (set.type == SetType.failure) return true;
    final rir = set.effectiveRir;
    return rir != null && rir <= limitEffortRir;
  });
}

/// The heaviest weight in a set list, or null if there are none.
double? topWeight(List<LoggedSet> sets) {
  if (sets.isEmpty) return null;
  return sets.map((s) => s.weight).reduce((a, b) => a > b ? a : b);
}

/// The step to add this time, in kilograms.
///
/// A percentage is resolved against the weight you're currently lifting, which
/// is the point of offering one: 2.5% adds 2.5 kg to a 100 kg bench and 1 kg to
/// a 40 kg curl, so one setting scales across every lift instead of being
/// generous on the small ones and timid on the big ones.
///
/// A percentage of a bodyweight exercise (logged at zero) is zero, so it falls
/// back to the fixed step — otherwise progression would silently never happen.
double resolveIncrementKg({
  required double currentWeightKg,
  required double fixedKg,
  double? percent,
}) {
  if (percent == null || percent <= 0) return fixedKg;
  final step = currentWeightKg * percent / 100;
  return step > 0 ? step : fixedKg;
}

/// Works out the next weight to suggest.
///
/// [lastSets] are the sets from the most recent session containing this
/// exercise. [incrementKg] is the fixed step; [percent], when given, replaces it
/// with that share of the current weight. [increasesInARow] counts how many
/// sessions in a row already went up, used only when [deloadAfterWeeks] is set.
OverloadSuggestion suggestNextWeight({
  required List<LoggedSet> lastSets,
  required int plannedSets,
  required int targetReps,
  required double incrementKg,
  double? percent,
  int increasesInARow = 0,
  int? deloadAfterWeeks,
}) {
  final last = topWeight(lastSets);
  if (last == null) {
    // Nothing logged yet. Zero rather than a guess — we have no idea what this
    // person lifts, and an invented number is worse than an empty field.
    return const OverloadSuggestion(
      weight: 0,
      reason: OverloadReason.firstTime,
    );
  }

  if (deloadAfterWeeks != null && increasesInARow >= deloadAfterWeeks) {
    // 10% off, the conventional deload. Offered, never applied on its own.
    return OverloadSuggestion(
      weight: last * 0.9,
      reason: OverloadReason.deload,
    );
  }

  final earned = earnedIncrease(
    sets: lastSets,
    plannedSets: plannedSets,
    targetReps: targetReps,
  );

  // Earned on reps, but the top set was a grind: hold rather than add.
  if (earned && topSetAtLimit(lastSets)) {
    return OverloadSuggestion(weight: last, reason: OverloadReason.atLimit);
  }

  final step = resolveIncrementKg(
    currentWeightKg: last,
    fixedKg: incrementKg,
    percent: percent,
  );

  return OverloadSuggestion(
    weight: earned ? last + step : last,
    reason: earned ? OverloadReason.earned : OverloadReason.repeat,
  );
}
