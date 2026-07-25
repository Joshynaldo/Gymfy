import 'package:flutter/material.dart';

import '../models/exercise_category.dart';

/// Small helpers for turning exercise data into things we can show on screen.
/// Shared by the exercise list and detail screens.

/// Turns a muscle id like `front_deltoid` into a label like `Front Deltoid`.
String muscleLabel(String id) => id
    .split('_')
    .map(
      (word) =>
          word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}',
    )
    .join(' ');

/// A representative icon for each movement-pattern category.
IconData categoryIcon(ExerciseCategory category) => switch (category) {
  ExerciseCategory.push => Icons.arrow_upward,
  ExerciseCategory.pull => Icons.arrow_downward,
  ExerciseCategory.legs => Icons.directions_run,
  ExerciseCategory.core => Icons.self_improvement,
};
