// Strength standards: how much a lift is worth relative to your bodyweight.
//
// Pure data plus lookups — no Flutter, no database. The ranking maths and the
// UI come in the next tasks of this phase.

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

/// Which set of ratios to use.
///
/// Real-world standards differ substantially by sex — a 1.0× bodyweight bench
/// is intermediate for men and advanced for women — so one shared table would
/// be wrong for roughly half of users. Where the app doesn't know, it should
/// ask rather than assume; the bodyweight prompt in a later task of this phase
/// is where that happens.
enum LifterSex {
  male('Male'),
  female('Female');

  const LifterSex(this.label);

  final String label;
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
/// Deliberately only the barbell compounds. Standards exist because these lifts
/// are trained and tested the same way everywhere, so the numbers mean
/// something; ranking a cable fly or a lateral raise would be inventing
/// authority the data doesn't have. Exercises missing from this map simply get
/// no rank — see [standardsFor].
///
/// The ratios follow the widely published tables (ExRx, Strength Level) rounded
/// to something readable. They're population averages, not physics: limb
/// lengths and bodyweight both skew them, and a heavier lifter clears a lower
/// ratio for the same tier. Treat a rank as a rough bracket.
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
