// Coarse body regions, for browsing the library.
//
// The app's canonical unit is the individual muscle (see `MuscleId`), which is
// right for the heatmap and for filtering but wrong as a table of contents:
// eighteen headings over seventy-eight exercises gives sections of two or three
// and buries the thing you're scrolling for. Six regions is how people actually
// ask the question — "show me back exercises", not "show me latissimus dorsi
// exercises".
//
// Lives in the exercises feature rather than in `shared` because only the
// library browses this way. Worth promoting if a second screen ever needs it.

import '../../../shared/models/muscle_ids.dart';

/// A region of the body, used as a section heading in the exercise library.
enum MuscleGroup {
  chest('Chest'),
  back('Back'),
  shoulders('Shoulders'),
  arms('Arms'),
  legs('Legs'),
  core('Core'),
  neck('Neck');

  const MuscleGroup(this.label);

  /// Shown as the section header.
  final String label;
}

/// Which region each muscle belongs to.
///
/// Every id in [MuscleId.all] appears exactly once — there's a test for that, so
/// adding a muscle without placing it here fails loudly rather than quietly
/// dropping its exercises out of the list.
const _groupOfMuscle = <String, MuscleGroup>{
  MuscleId.chest: MuscleGroup.chest,
  MuscleId.lats: MuscleGroup.back,
  MuscleId.trapezius: MuscleGroup.back,
  MuscleId.lowerBack: MuscleGroup.back,
  MuscleId.frontDeltoid: MuscleGroup.shoulders,
  MuscleId.sideDeltoid: MuscleGroup.shoulders,
  MuscleId.rearDeltoid: MuscleGroup.shoulders,
  MuscleId.biceps: MuscleGroup.arms,
  MuscleId.triceps: MuscleGroup.arms,
  MuscleId.forearms: MuscleGroup.arms,
  MuscleId.quads: MuscleGroup.legs,
  MuscleId.hamstrings: MuscleGroup.legs,
  MuscleId.glutes: MuscleGroup.legs,
  MuscleId.calves: MuscleGroup.legs,
  MuscleId.adductors: MuscleGroup.legs,
  MuscleId.abs: MuscleGroup.core,
  MuscleId.obliques: MuscleGroup.core,
  MuscleId.neck: MuscleGroup.neck,
};

/// Whether [muscleId] has been placed in a region.
///
/// Exists for the exhaustiveness test. From the outside an unmapped muscle and
/// a genuinely-core one both come back as [MuscleGroup.core], so without this
/// there is no way to tell "filed under Core" from "forgotten about" — and the
/// forgotten one dumps its exercises where nobody will look for them.
bool isMuscleMapped(String muscleId) => _groupOfMuscle.containsKey(muscleId);

/// The region an exercise is filed under.
///
/// Decided by its *first* muscle, which the seed data lists as the primary one:
/// a bench press trains chest, front deltoid and triceps, and belongs under
/// Chest rather than appearing three times. A custom exercise with no muscles at
/// all falls back to [MuscleGroup.core] — it has to go somewhere, and an
/// exercise that vanished from the list because it was tagged badly would look
/// like data loss.
MuscleGroup groupOfExercise(List<String> muscleIds) {
  if (muscleIds.isEmpty) return MuscleGroup.core;
  return _groupOfMuscle[muscleIds.first] ?? MuscleGroup.core;
}

/// Groups [exercises] by region, in [MuscleGroup] order, skipping empty regions.
///
/// Order comes from the enum rather than from the data, so the sections don't
/// reshuffle as the library is filtered — a heading that moves while you're
/// reading is worse than one that's occasionally absent.
Map<MuscleGroup, List<T>> groupExercises<T>(
  Iterable<T> exercises,
  List<String> Function(T) musclesOf,
) {
  final byGroup = <MuscleGroup, List<T>>{};
  for (final exercise in exercises) {
    byGroup
        .putIfAbsent(groupOfExercise(musclesOf(exercise)), () => [])
        .add(exercise);
  }

  return {
    for (final group in MuscleGroup.values)
      if (byGroup[group] != null) group: byGroup[group]!,
  };
}
