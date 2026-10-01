// Percent-of-1RM targets: turning "5 × 5 @ 75 %" into a weight on the bar.
//
// The plan stores only the percentage (`workout_exercises.target_percent`).
// The weight is worked out when it is needed, from the best 1RM we know of, so
// it follows the lifter: test a new max, or log a heavier set, and every
// percentage day moves with it without anyone editing the plan.

import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n.dart';
import '../../../shared/database/app_database.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/utils/units.dart';
import '../../calculator/data/tested_one_rm_repository.dart';
import '../../plates/data/plate_math.dart';
import '../../progress/data/progress_repository.dart';

/// The 1RM a percentage target is taken of, in kilograms.
///
/// A tested max beats the estimate, the same precedence the strength rank and
/// the progress screen use — a number you actually lifted is a better anchor
/// than one a formula guessed from a set of eight. Null when there is neither,
/// or the only thing to go on is zero (a bodyweight lift logged at 0 kg).
double? workingOneRmKg({TestedOneRm? tested, BestOneRm? estimate}) {
  final value = tested?.weightKg ?? estimate?.oneRm;
  return value != null && value > 0 ? value : null;
}

/// The 1RM a percentage target is taken of, for one exercise. Null when there
/// is no tested max and no working set logged to estimate one from.
final workingOneRmProvider = FutureProvider.family<double?, String>((
  ref,
  exerciseId,
) async {
  final tested = await ref.watch(testedOneRmProvider(exerciseId).future);
  final history = await ref.watch(exerciseHistoryProvider(exerciseId).future);
  return workingOneRmKg(tested: tested, estimate: bestEstimatedOneRm(history));
});

/// The same answer as [workingOneRmProvider], read once rather than watched.
///
/// For code that awaits a result with nothing listening — the overload
/// suggestion, which the log sheet awaits through `ref.read(...).future`. A
/// watched stream with no listener never emits, so a watch there could leave
/// the sheet waiting on a value that is never coming.
Future<double?> readWorkingOneRm(Ref ref, String exerciseId) async {
  final tested = await ref
      .read(testedOneRmRepositoryProvider)
      .watchForExercise(exerciseId)
      .first;
  final history = await ref
      .read(progressRepositoryProvider)
      .watchExerciseHistory(exerciseId)
      .first;
  return workingOneRmKg(tested: tested, estimate: bestEstimatedOneRm(history));
}

/// How a 0–100 percentage reads on screen: "75%", "72.5%".
///
/// Pass [l10n] for the language's way of writing it — German puts a space
/// before the sign and a comma in the number: "72,5 %". Without it, English.
String formatPercent(double percent, {AppLocalizations? l10n}) =>
    (l10n ?? englishLocalizations).overloadPercentValue(
      formatWeight(percent, l10n: l10n),
    );

/// [percent] of [oneRmKg], both on the 0–100 scale the app uses everywhere.
///
/// [deloadPercent], when given, scales the result again: a deload week of a
/// percentage programme is the planned percentage, lightened.
double percentOfMaxKg({
  required double oneRmKg,
  required double percent,
  double? deloadPercent,
}) {
  return oneRmKg * percent / 100 * (deloadPercent ?? 100) / 100;
}

/// Rounds [kilograms] to the *nearest* weight the user can actually load.
///
/// Nearest rather than up or down: a percentage is already an approximation of
/// what a day should feel like, and neither direction is the "safe" one the
/// way it is for an overload increase. A tie goes to the lighter weight.
///
/// Plate-loaded lifts round to what the user's own plates and bar can make;
/// everything else to the unit's step, the way the overload suggestion does.
double nearestLoadable({
  required double kilograms,
  required bool plateLoaded,
  required WeightUnit unit,
  required List<double> plates,
  required double bar,
}) {
  if (!plateLoaded || plates.isEmpty) return roundToLoadable(kilograms, unit);

  // Plates are labelled in the display unit, so the search happens there and
  // converts back once at the end.
  final wanted = weightIn(kilograms, unit);
  final below = calculatePlates(target: wanted, bar: bar, plates: plates);
  if (below.isExact || below.belowBar) {
    return weightToKilograms(below.achieved, unit);
  }

  // `calculatePlates` never overshoots, so the next loadable weight up is one
  // pair of the smallest plate heavier.
  final step = plates.reduce(math.min) * 2;
  final above = calculatePlates(
    target: below.achieved + step,
    bar: bar,
    plates: plates,
  );
  final pick = (above.achieved - wanted) < (wanted - below.achieved)
      ? above
      : below;
  return weightToKilograms(pick.achieved, unit);
}
