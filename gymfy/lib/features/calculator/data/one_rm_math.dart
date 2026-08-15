// One-rep-max estimation. Pure maths, no Flutter and no database — so it can be
// unit tested directly and reused by charts later in this phase.

/// Estimates a one-rep max with the Epley formula:
/// `1RM = weight × (1 + reps / 30)`.
///
/// A single rep is already a max, so [reps] of 1 returns [weight] untouched —
/// running it through the formula would inflate a true max by 3.3%.
///
/// Returns null for nonsense input (non-positive weight or reps) so callers can
/// simply show nothing rather than a bogus number.
double? epleyOneRm({required double weight, required int reps}) {
  if (weight <= 0 || reps < 1) return null;
  if (reps == 1) return weight;
  return weight * (1 + reps / 30);
}

/// Estimates a one-rep max with the Brzycki formula:
/// `1RM = weight × 36 / (37 − reps)`.
///
/// Reads lower than Epley as reps climb, and blows up entirely at 37 reps
/// (division by zero), which is why that's guarded.
double? brzyckiOneRm({required double weight, required int reps}) {
  if (weight <= 0 || reps < 1 || reps >= 37) return null;
  if (reps == 1) return weight;
  return weight * 36 / (37 - reps);
}

/// Estimates a one-rep max with the Lander formula:
/// `1RM = 100 × weight / (101.3 − 2.67123 × reps)`.
///
/// Sits close to Epley in the low-rep range. Its denominator reaches zero just
/// short of 38 reps, so the guard is the same idea as Brzycki's.
double? landerOneRm({required double weight, required int reps}) {
  if (weight <= 0 || reps < 1) return null;
  if (reps == 1) return weight;
  final denominator = 101.3 - 2.67123 * reps;
  if (denominator <= 0) return null;
  return 100 * weight / denominator;
}

/// The three formulas the calculator compares.
///
/// They're all curve fits to the same underlying reality, so they agree closely
/// on heavy sets and drift apart as reps climb. Showing the spread is more
/// honest than picking one and calling it the answer.
enum OneRmFormula {
  epley('Epley', 'The common default'),
  brzycki('Brzycki', 'Conservative on high reps'),
  lander('Lander', 'Close to Epley when heavy');

  const OneRmFormula(this.label, this.note);

  final String label;
  final String note;

  /// This formula's estimate, or null if the input is out of its usable range.
  double? estimate({required double weight, required int reps}) {
    return switch (this) {
      OneRmFormula.epley => epleyOneRm(weight: weight, reps: reps),
      OneRmFormula.brzycki => brzyckiOneRm(weight: weight, reps: reps),
      OneRmFormula.lander => landerOneRm(weight: weight, reps: reps),
    };
  }
}

/// Every formula's answer for one set, plus what they agree on.
typedef OneRmEstimates = ({
  Map<OneRmFormula, double> byFormula,
  double average,
  double lowest,
  double highest,
});

/// Runs every formula over the same set.
///
/// Formulas that can't handle the rep count are left out rather than faked, and
/// the average covers only the ones that answered. Returns null when nothing
/// could be estimated at all.
OneRmEstimates? estimateOneRm({required double weight, required int reps}) {
  final byFormula = <OneRmFormula, double>{};
  for (final formula in OneRmFormula.values) {
    final value = formula.estimate(weight: weight, reps: reps);
    if (value != null) byFormula[formula] = value;
  }
  if (byFormula.isEmpty) return null;

  final values = byFormula.values.toList();
  return (
    byFormula: byFormula,
    average: values.reduce((a, b) => a + b) / values.length,
    lowest: values.reduce((a, b) => a < b ? a : b),
    highest: values.reduce((a, b) => a > b ? a : b),
  );
}

/// The reverse of [epleyOneRm]: the weight you'd expect to manage for [reps]
/// given a known or estimated one-rep max.
///
/// Used for the training-percentage table — "if my max is 100, what's my 5?"
double? weightForReps({required double oneRm, required int reps}) {
  if (oneRm <= 0 || reps < 1) return null;
  if (reps == 1) return oneRm;
  return oneRm / (1 + reps / 30);
}

/// Above this many reps, rep-max formulas drift badly — they were derived from
/// low-rep sets, and endurance starts mattering more than strength. The screen
/// keeps calculating but says so.
const oneRmReliableReps = 12;

/// Hard ceiling on the reps input. Past this the estimate is fiction.
const oneRmMaxReps = 20;

/// Rounds to the nearest 0.5 — the smallest increment you can actually load
/// with a standard plate set, so the number is something you can act on.
///
/// Kilograms only. Anything shown to the user should go through
/// `roundToLoadable` in `shared/utils/units.dart` instead, which rounds in
/// whichever unit is on screen.
double roundToPlate(double weight) => (weight * 2).round() / 2;
