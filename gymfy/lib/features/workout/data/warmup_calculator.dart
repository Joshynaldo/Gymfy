// Ramping up to a working weight.
//
// Given the weight you are about to work at, suggest the warm-up sets that get
// you there: an empty bar, then a few steps at fixed percentages of the
// working weight, each with fewer reps than the last. The point of a ramp is
// to rehearse the movement and wake the muscles up without spending the energy
// the working sets need — so the reps fall as the weight climbs.
//
// Plate-loaded exercises are rounded with the user's actual plate inventory
// (`calculatePlates`), always *down*: a warm-up a little lighter than planned
// costs nothing, one heavier than planned is fatigue taken out of the working
// sets. Everything else rounds to the unit's step, the way overload does.
//
// Like the plate calculator, the bar and plates are handled in the display
// unit, because they are physical objects stamped in it. The answer is handed
// back in kilograms, like every other stored weight.

import '../../../shared/utils/units.dart';
import '../../plates/data/plate_math.dart';

/// Reps on the empty bar. Plenty, because it costs nothing and grooves the
/// movement.
const emptyBarReps = 10;

/// One suggested warm-up set.
class WarmupStep {
  const WarmupStep({
    required this.weightKg,
    required this.reps,
    required this.percent,
    this.perSide = const [],
  });

  /// In kilograms, as stored.
  final double weightKg;

  final int reps;

  /// The ramp step this came from, or null for the empty bar.
  final int? percent;

  /// Plates for one side, heaviest first, in the display unit. Empty for the
  /// bare bar and for anything not plate-loaded.
  final List<double> perSide;

  bool get isEmptyBar => percent == null;

  @override
  bool operator ==(Object other) =>
      other is WarmupStep &&
      other.weightKg == weightKg &&
      other.reps == reps &&
      other.percent == percent;

  @override
  int get hashCode => Object.hash(weightKg, reps, percent);

  @override
  String toString() => 'WarmupStep($weightKg kg × $reps @ $percent%)';
}

/// The reps for a ramp step at [percent] of the working weight.
///
/// Fewer as it gets heavier: five at the light end, a single near the top.
/// These are the numbers most ramp tables print, and they keep the whole ramp
/// to a couple of dozen easy reps.
int warmupRepsFor(int percent) {
  if (percent <= 50) return 5;
  if (percent <= 70) return 3;
  if (percent <= 85) return 2;
  return 1;
}

/// The warm-up sets leading to [workingKg].
///
/// [percents] is the ramp (see `parseWarmupRamp`); [bar] and [plates] are in
/// [unit] and only matter when [plateLoaded].
///
/// Steps that would round to the same weight as the one before, or to the
/// working weight itself, are dropped rather than repeated: two identical
/// warm-ups are one warm-up done twice, and a warm-up at the working weight is
/// a working set. Returns an empty list when there is nothing to ramp to.
List<WarmupStep> planWarmups({
  required double workingKg,
  required List<int> percents,
  required WeightUnit unit,
  required bool plateLoaded,
  required List<double> plates,
  required double bar,
}) {
  if (workingKg <= 0) return const [];

  final working = weightIn(workingKg, unit);
  final steps = <WarmupStep>[];
  // In the display unit, the same as `working`.
  var previous = 0.0;

  // The empty bar first, when there is a bar and it is lighter than the work.
  // A machine with no bar starts straight at the first percentage.
  if (plateLoaded && bar > 0 && bar < working - 0.001) {
    steps.add(
      WarmupStep(
        weightKg: weightToKilograms(bar, unit),
        reps: emptyBarReps,
        percent: null,
      ),
    );
    previous = bar;
  }

  for (final percent in [...percents]..sort()) {
    final target = working * percent / 100;

    double shown;
    var perSide = const <double>[];
    if (plateLoaded) {
      // Lighter than the bar means the bar *is* the step, and it is already
      // on the list (or there is no bar and nothing to load).
      if (target < bar - 0.001) continue;
      final load = calculatePlates(target: target, bar: bar, plates: plates);
      shown = load.achieved;
      perSide = load.perSide;
    } else {
      shown = weightIn(
        roundToLoadable(weightToKilograms(target, unit), unit),
        unit,
      );
    }

    if (shown <= 0) continue;
    if (shown <= previous + 0.001) continue;
    if (shown >= working - 0.001) continue;

    steps.add(
      WarmupStep(
        weightKg: weightToKilograms(shown, unit),
        reps: warmupRepsFor(percent),
        percent: percent,
        perSide: perSide,
      ),
    );
    previous = shown;
  }

  return steps;
}
