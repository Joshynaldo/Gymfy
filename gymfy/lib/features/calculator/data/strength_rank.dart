// Turns a one-rep max plus a bodyweight into a rank.
//
// Pure maths over the tables in strength_standards.dart — no Flutter, no
// database. The screen that shows this arrives in the next task.

import 'strength_standards.dart';

/// Where one lift places you, and how far you are from the next tier.
typedef StrengthRank = ({
  /// The tier earned: the highest one whose entry ratio you've cleared.
  StrengthTier tier,

  /// The tier above, or null at [StrengthTier.elite].
  StrengthTier? next,

  /// One-rep max ÷ bodyweight.
  double ratio,

  /// How far through the current tier you are, 0.0–1.0. Null at elite, where
  /// there's nothing left to progress toward.
  double? progressToNext,

  /// Kilos still needed on the bar to reach [next]. Null at elite.
  double? weightToNext,
});

/// Ranks one lift.
///
/// Returns null when there's nothing honest to say: an exercise with no
/// standards (most of the library), a missing or nonsensical bodyweight, or no
/// one-rep max to go on.
///
/// [oneRm] should be the tested max where the user has entered one and the
/// estimate otherwise — the caller decides, since only it knows which exists.
StrengthRank? rankFor({
  required String exerciseId,
  required LifterSex sex,
  required double oneRm,
  required double bodyweightKg,
}) {
  if (oneRm <= 0 || bodyweightKg <= 0) return null;
  final standard = standardsFor(exerciseId, sex);
  if (standard == null) return null;

  final ratio = oneRm / bodyweightKg;

  // Walk down from the top: the first bar you clear is your tier. Everyone
  // clears beginner, which has no bar at all.
  var tier = StrengthTier.beginner;
  for (final candidate in StrengthTier.values.reversed) {
    final required = standard.ratioFor(candidate);
    if (required != null && ratio >= required) {
      tier = candidate;
      break;
    }
  }

  final next = tier.next;
  if (next == null) {
    return (
      tier: tier,
      next: null,
      ratio: ratio,
      progressToNext: null,
      weightToNext: null,
    );
  }

  // Progress runs from the bar you cleared to the one you're chasing. Beginner
  // has no bar, so it starts from zero.
  final floor = standard.ratioFor(tier) ?? 0;
  final ceiling = standard.ratioFor(next)!;
  final progress = ((ratio - floor) / (ceiling - floor)).clamp(0.0, 1.0);

  return (
    tier: tier,
    next: next,
    ratio: ratio,
    progressToNext: progress,
    // What the bar needs to read, minus what you can already do.
    weightToNext: ceiling * bodyweightKg - oneRm,
  );
}
