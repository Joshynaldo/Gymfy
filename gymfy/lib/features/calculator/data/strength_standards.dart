// Strength standards: how much a lift is worth relative to your bodyweight.
//
// Pure data plus lookups — no Flutter, no database. The ranking maths and the
// UI come in the next tasks of this phase.

// `LifterSex` moved to shared/ once onboarding and the muscle map needed it as
// well. Re-exported so callers that reason about standards still get it from
// the standards file.
import '../../../shared/data/lifter_sex.dart';

export '../../../shared/data/lifter_sex.dart' show LifterSex;

/// Rank tiers, weakest first.
///
/// Everyone starts at [beginner], so it has no entry ratio — the other four
/// are promotions you earn. `index` order is meaningful: a later tier is
/// always stronger, which is what the progress bar and comparisons rely on.
enum StrengthTier {
  beginner('Beginner'),
  novice('Novice'),
  intermediate('Intermediate'),
  advanced('Advanced'),
  elite('Elite');

  const StrengthTier(this.label);

  final String label;

  /// The tier above this one, or null if you're already at the top.
  StrengthTier? get next =>
      this == StrengthTier.elite ? null : StrengthTier.values[index + 1];
}

/// The bodyweight ratios needed to enter each tier for one exercise.
///
/// A "ratio" is one-rep max ÷ bodyweight, so 1.5 on the squat means squatting
/// one and a half times what you weigh.
class StrengthStandard {
  const StrengthStandard({
    required this.novice,
    required this.intermediate,
    required this.advanced,
    required this.elite,
  });

  final double novice;
  final double intermediate;
  final double advanced;
  final double elite;

  /// The entry ratio for [tier], or null for [StrengthTier.beginner] — there's
  /// no bar to clear for the tier you start in.
  double? ratioFor(StrengthTier tier) {
    return switch (tier) {
      StrengthTier.beginner => null,
      StrengthTier.novice => novice,
      StrengthTier.intermediate => intermediate,
      StrengthTier.advanced => advanced,
      StrengthTier.elite => elite,
    };
  }
}

/// Ratios per sex for one exercise.
typedef ExerciseStandards = ({
  StrengthStandard male,
  StrengthStandard female,
});

/// Standards keyed by the seed-data exercise id.
///
/// Every lift here loads a barbell or a cable stack: a weight that means the
/// same thing in every gym, is recorded the same way by every lifter, and has
/// a published table behind it. The ratios follow the widely published tables
/// (ExRx, Strength Level) rounded to something readable. They're population
/// averages, not physics: limb lengths and bodyweight both skew them, and a
/// heavier lifter clears a lower ratio for the same tier. Treat a rank as a
/// rough bracket.
///
/// Exercises missing from this map get no rank at all, which is the honest
/// outcome rather than a gap to be filled. Three kinds are left out on
/// purpose, and none of them for lack of effort:
///
///   * **Bodyweight lifts** — pull-up, chin-up, dip, push-up. Their real load
///     is your body plus whatever you hang off it, but the app logs the added
///     weight. A strict bodyweight pull-up is logged as 0 kg, so a ratio would
///     read 0.0 and rank Beginner forever no matter how many you did. Ranking
///     these properly needs the load model to change first.
///   * **Dumbbell lifts** — published dumbbell tables are per dumbbell, and
///     the app doesn't record whether you entered one or the pair. Guessing
///     wrong is a factor-of-two error, which is the difference between Novice
///     and Elite. A rank that can be that wrong is worse than no rank.
///   * **Plate-loaded and selectorised machines** — leg press, hack squat, pec
///     deck. The sled carries an unknown weight of its own and the leverage
///     differs per machine, so the number on the plates isn't comparable
///     between two gyms. This is the same reason [isPlateLoaded] skips them.
///
/// Isolation work on a bar or a stack *is* included where a table exists
/// (curls, skull crushers, pulldowns): the objection to ranking a cable fly was
/// never that it's small, it's that nobody has published what a good one is.
const strengthStandards = <String, ExerciseStandards>{
  'barbell_bench_press': (
    male: StrengthStandard(
      novice: 0.75,
      intermediate: 1.0,
      advanced: 1.5,
      elite: 2.0,
    ),
    female: StrengthStandard(
      novice: 0.4,
      intermediate: 0.6,
      advanced: 0.9,
      elite: 1.2,
    ),
  ),
  'barbell_back_squat': (
    male: StrengthStandard(
      novice: 1.0,
      intermediate: 1.5,
      advanced: 2.0,
      elite: 2.5,
    ),
    female: StrengthStandard(
      novice: 0.6,
      intermediate: 1.0,
      advanced: 1.4,
      elite: 1.8,
    ),
  ),
  'deadlift': (
    male: StrengthStandard(
      novice: 1.25,
      intermediate: 1.75,
      advanced: 2.25,
      elite: 2.75,
    ),
    female: StrengthStandard(
      novice: 0.75,
      intermediate: 1.25,
      advanced: 1.6,
      elite: 2.1,
    ),
  ),
  'overhead_barbell_press': (
    male: StrengthStandard(
      novice: 0.5,
      intermediate: 0.7,
      advanced: 1.0,
      elite: 1.3,
    ),
    female: StrengthStandard(
      novice: 0.3,
      intermediate: 0.45,
      advanced: 0.65,
      elite: 0.85,
    ),
  ),
  'barbell_row': (
    male: StrengthStandard(
      novice: 0.75,
      intermediate: 1.0,
      advanced: 1.35,
      elite: 1.7,
    ),
    female: StrengthStandard(
      novice: 0.4,
      intermediate: 0.6,
      advanced: 0.85,
      elite: 1.1,
    ),
  ),
  'romanian_deadlift': (
    male: StrengthStandard(
      novice: 1.0,
      intermediate: 1.4,
      advanced: 1.8,
      elite: 2.25,
    ),
    female: StrengthStandard(
      novice: 0.6,
      intermediate: 0.95,
      advanced: 1.3,
      elite: 1.7,
    ),
  ),

  // ---- Pressing variations ----
  'incline_barbell_press': (
    male: StrengthStandard(
      novice: 0.6,
      intermediate: 0.85,
      advanced: 1.25,
      elite: 1.65,
    ),
    female: StrengthStandard(
      novice: 0.35,
      intermediate: 0.5,
      advanced: 0.75,
      elite: 1.0,
    ),
  ),
  'decline_barbell_press': (
    male: StrengthStandard(
      novice: 0.8,
      intermediate: 1.05,
      advanced: 1.55,
      elite: 2.05,
    ),
    female: StrengthStandard(
      novice: 0.45,
      intermediate: 0.6,
      advanced: 0.9,
      elite: 1.2,
    ),
  ),
  'close_grip_bench_press': (
    male: StrengthStandard(
      novice: 0.65,
      intermediate: 0.9,
      advanced: 1.35,
      elite: 1.8,
    ),
    female: StrengthStandard(
      novice: 0.35,
      intermediate: 0.55,
      advanced: 0.8,
      elite: 1.05,
    ),
  ),
  'push_press': (
    male: StrengthStandard(
      novice: 0.6,
      intermediate: 0.85,
      advanced: 1.2,
      elite: 1.55,
    ),
    female: StrengthStandard(
      novice: 0.35,
      intermediate: 0.5,
      advanced: 0.7,
      elite: 0.95,
    ),
  ),

  // ---- Squat and hinge variations ----
  'front_squat': (
    male: StrengthStandard(
      novice: 0.8,
      intermediate: 1.2,
      advanced: 1.6,
      elite: 2.0,
    ),
    female: StrengthStandard(
      novice: 0.5,
      intermediate: 0.8,
      advanced: 1.1,
      elite: 1.4,
    ),
  ),
  'sumo_deadlift': (
    // Level with the conventional pull: the published tables treat the two as
    // the same lift, and which one is stronger is a matter of build.
    male: StrengthStandard(
      novice: 1.25,
      intermediate: 1.75,
      advanced: 2.25,
      elite: 2.75,
    ),
    female: StrengthStandard(
      novice: 0.75,
      intermediate: 1.25,
      advanced: 1.6,
      elite: 2.1,
    ),
  ),
  'good_morning': (
    male: StrengthStandard(
      novice: 0.5,
      intermediate: 0.8,
      advanced: 1.2,
      elite: 1.6,
    ),
    female: StrengthStandard(
      novice: 0.35,
      intermediate: 0.55,
      advanced: 0.8,
      elite: 1.05,
    ),
  ),
  'barbell_hip_thrust': (
    // The one lift where the female ratios sit closest to the male ones.
    male: StrengthStandard(
      novice: 1.25,
      intermediate: 1.75,
      advanced: 2.5,
      elite: 3.25,
    ),
    female: StrengthStandard(
      novice: 1.0,
      intermediate: 1.5,
      advanced: 2.15,
      elite: 2.8,
    ),
  ),
  'power_clean': (
    male: StrengthStandard(
      novice: 0.75,
      intermediate: 1.0,
      advanced: 1.3,
      elite: 1.6,
    ),
    female: StrengthStandard(
      novice: 0.5,
      intermediate: 0.65,
      advanced: 0.85,
      elite: 1.1,
    ),
  ),

  // ---- Pulling ----
  'lat_pulldown': (
    male: StrengthStandard(
      novice: 0.7,
      intermediate: 0.95,
      advanced: 1.25,
      elite: 1.6,
    ),
    female: StrengthStandard(
      novice: 0.4,
      intermediate: 0.55,
      advanced: 0.75,
      elite: 0.95,
    ),
  ),
  'seated_cable_row': (
    male: StrengthStandard(
      novice: 0.65,
      intermediate: 0.9,
      advanced: 1.2,
      elite: 1.5,
    ),
    female: StrengthStandard(
      novice: 0.4,
      intermediate: 0.55,
      advanced: 0.72,
      elite: 0.9,
    ),
  ),
  'barbell_shrug': (
    male: StrengthStandard(
      novice: 1.0,
      intermediate: 1.5,
      advanced: 2.1,
      elite: 2.75,
    ),
    female: StrengthStandard(
      novice: 0.6,
      intermediate: 0.9,
      advanced: 1.25,
      elite: 1.65,
    ),
  ),
  'upright_row': (
    male: StrengthStandard(
      novice: 0.4,
      intermediate: 0.6,
      advanced: 0.85,
      elite: 1.1,
    ),
    female: StrengthStandard(
      novice: 0.22,
      intermediate: 0.33,
      advanced: 0.47,
      elite: 0.6,
    ),
  ),

  // ---- Arms on a bar ----
  'barbell_biceps_curl': (
    male: StrengthStandard(
      novice: 0.35,
      intermediate: 0.5,
      advanced: 0.75,
      elite: 1.0,
    ),
    female: StrengthStandard(
      novice: 0.2,
      intermediate: 0.28,
      advanced: 0.4,
      elite: 0.55,
    ),
  ),
  'preacher_curl': (
    male: StrengthStandard(
      novice: 0.3,
      intermediate: 0.45,
      advanced: 0.65,
      elite: 0.85,
    ),
    female: StrengthStandard(
      novice: 0.17,
      intermediate: 0.25,
      advanced: 0.36,
      elite: 0.48,
    ),
  ),
  'skull_crusher': (
    male: StrengthStandard(
      novice: 0.3,
      intermediate: 0.45,
      advanced: 0.65,
      elite: 0.9,
    ),
    female: StrengthStandard(
      novice: 0.17,
      intermediate: 0.25,
      advanced: 0.36,
      elite: 0.5,
    ),
  ),
};

/// The standard for one exercise and lifter, or null if this exercise isn't
/// ranked. Callers must handle null — that's most of the exercise library.
StrengthStandard? standardsFor(String exerciseId, LifterSex sex) {
  final standards = strengthStandards[exerciseId];
  if (standards == null) return null;
  return switch (sex) {
    LifterSex.male => standards.male,
    LifterSex.female => standards.female,
  };
}

/// Whether this exercise has strength standards at all — for hiding rank UI
/// without having to know the lifter's sex or bodyweight first.
bool hasStrengthStandard(String exerciseId) =>
    strengthStandards.containsKey(exerciseId);
