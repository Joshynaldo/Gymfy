// Filtering the exercise library by free text and by muscle.
//
// Lives in `shared` because two screens need exactly the same rules: the
// Exercises tab and the multi-select picker that adds exercises to a workout
// day. Duplicating the logic would let the two drift apart, and "the library
// found it but the picker didn't" is a confusing bug to be on the wrong end of.

import '../database/app_database.dart';
import '../models/equipment.dart';
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
  Set<Equipment> equipmentFilters = const {},
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

  // Equipment ORs within itself for the same reason muscles do: picking
  // Dumbbell and Bodyweight asks "what can I do in a hotel room", which is a
  // real question. It ANDs against the others — "dumbbell chest work" is a
  // search within a filtered set.
  final matchesEquipment =
      equipmentFilters.isEmpty ||
      equipmentFilters.contains(Equipment.parse(exercise.equipment));

  return matchesQuery && matchesMuscle && matchesEquipment;
}

/// Every kind of equipment that appears in [exercises], in enum order.
///
/// Enum order rather than alphabetical: these six are a fixed, small set, and
/// a bar whose chips move around as the library is filtered is a bar you have
/// to re-read every time.
List<Equipment> equipmentIn(Iterable<Exercise> exercises) {
  final present = {for (final e in exercises) Equipment.parse(e.equipment)};
  return Equipment.values.where(present.contains).toList();
}

/// The options each filter bar should offer, given what the other filters
/// have already narrowed things to.
///
/// This is the part worth being careful about. Each facet's options are
/// computed from everything *except its own* selection — so picking "Chest"
/// narrows the equipment chips to what chest work actually needs, while the
/// muscle chips keep offering the other muscles. Computing both from the
/// fully filtered set instead would be the obvious implementation and would
/// be useless: muscle filters OR together, so after picking Chest the only
/// muscle left in the results is Chest, and every other chip would vanish the
/// instant you touched one. You could never pick a second.
///
/// What it buys is the promise in the feature's name: every chip on screen
/// has results behind it. Tap Cable and the machine-only muscles go; there is
/// no combination you can reach that shows an empty list.
({List<String> muscles, List<Equipment> equipment}) filterOptionsFor(
  Iterable<Exercise> exercises, {
  required String query,
  required Set<String> muscleFilters,
  required Set<Equipment> equipmentFilters,
}) {
  final forMuscles = exercises.where(
    (e) => matchesExerciseSearch(
      e,
      query: query,
      muscleFilters: const {},
      equipmentFilters: equipmentFilters,
    ),
  );
  final forEquipment = exercises.where(
    (e) => matchesExerciseSearch(
      e,
      query: query,
      muscleFilters: muscleFilters,
      equipmentFilters: const {},
    ),
  );

  return (
    // A selected option always stays on its bar, even when the *other* facet
    // has narrowed it out of the results. Otherwise the chip you just tapped
    // could disappear under your finger, leaving a filter that is still
    // applied and no longer visible anywhere — the worst state a filter bar
    // can be in, because there is nothing left to tap to undo it.
    muscles: {...musclesIn(forMuscles), ...muscleFilters}.toList()..sort(),
    equipment: {...equipmentIn(forEquipment), ...equipmentFilters}.toList()
      ..sort((a, b) => a.index.compareTo(b.index)),
  );
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
