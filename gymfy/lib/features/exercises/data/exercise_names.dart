import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'exercise_repository.dart';

/// Every exercise's name by id, archived ones included — a goal or a review
/// naming a lift since retired still has a name to show.
///
/// Empty until the library has loaded; callers fall back to something
/// readable rather than waiting.
final exerciseNamesProvider = Provider<Map<String, String>>((ref) {
  final exercises = ref.watch(allExercisesProvider).value ?? const [];
  return {for (final exercise in exercises) exercise.id: exercise.name};
});
