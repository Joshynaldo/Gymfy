// Filtering the exercise library by free text and by muscle.
//
// Lives in `shared` because two screens need exactly the same rules: the
// Exercises tab and the multi-select picker that adds exercises to a workout
// day. Duplicating the logic would let the two drift apart, and "the library
// found it but the picker didn't" is a confusing bug to be on the wrong end of.

import '../database/app_database.dart';
import 'exercise_display.dart';

/// Whether [exercise] survives a free-text [query] and a set of [muscleFilters].
///
/// The two combine with AND (a search *within* a filtered set), but several
/// muscle filters combine with OR: picking Chest and Triceps asks for "anything
/// that trains either", which is how you build a push day. Requiring both would
/// answer a question almost nobody has, and would usually return nothing.
///
/// An empty [query] and an empty [muscleFilters] both mean "no restriction".
bool matchesExerciseSearch(
  Exercise exercise, {
  required String query,
  required Set<String> muscleFilters,
}) {
  final needle = query.trim().toLowerCase();
  final matchesQuery =
      needle.isEmpty ||
      exercise.name.toLowerCase().contains(needle) ||
      // Searching by muscle: "delt" finds the lateral raise even though the
      // word never appears in its name.
      exercise.muscleIds.any(
        (muscleId) => muscleLabel(muscleId).toLowerCase().contains(needle),
      );

  final matchesMuscle =
      muscleFilters.isEmpty || exercise.muscleIds.any(muscleFilters.contains);

  return matchesQuery && matchesMuscle;
}

/// Every muscle that actually appears in [exercises], sorted, for building the
/// filter chips.
///
/// Derived from the data rather than from a fixed list, so a chip is never
/// offered that would return nothing — and a muscle used only by a custom
/// exercise still gets one.
List<String> musclesIn(Iterable<Exercise> exercises) {
  return <String>{for (final e in exercises) ...e.muscleIds}.toList()..sort();
}
