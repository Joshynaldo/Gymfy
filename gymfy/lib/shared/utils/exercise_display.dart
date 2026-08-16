import 'package:flutter/material.dart';

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

/// The icon shown next to any exercise.
///
/// One icon for everything, on purpose: exercises are grouped by the muscles
/// they train, and a per-exercise icon would have to invent some other
/// classification to vary on. The muscle names sit right there in the subtitle
/// and say more than a glyph could.
const IconData exerciseIcon = Icons.fitness_center;
