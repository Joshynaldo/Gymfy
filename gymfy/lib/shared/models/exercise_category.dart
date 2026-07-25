/// How an exercise is grouped for filtering — movement-pattern based.
///
/// Stored in the database by its enum name (see the `category` column in
/// exercise.dart), so DON'T rename these values without a migration.
enum ExerciseCategory {
  push,
  pull,
  legs,
  core;

  /// Human-friendly label for the UI (filter chips, detail screen, …).
  String get label => switch (this) {
    ExerciseCategory.push => 'Push',
    ExerciseCategory.pull => 'Pull',
    ExerciseCategory.legs => 'Legs',
    ExerciseCategory.core => 'Core',
  };
}
