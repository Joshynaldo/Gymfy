// Rules every seeded exercise has to satisfy.
//
// None of these are caught by the compiler: a muscle id is just a string, so a
// typo produces an exercise that loads fine, lists fine, and then quietly fails
// to light up anything on the muscle map. This file is where that fails loudly
// instead.

import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/exercises/data/exercise_repository.dart';
import 'package:gymfy/features/exercises/data/exercise_seed_data.dart';
import 'package:gymfy/shared/models/muscle_ids.dart';

void main() {
  test('the library is large enough to plan real training with', () {
    // Not an arbitrary number: below roughly this many, most people hit a lift
    // they do regularly and have to add it by hand before they can log anything.
    expect(exerciseSeedData.length, greaterThanOrEqualTo(60));
  });

  test('every id is unique', () {
    // The id is the primary key, and `seed()` upserts on it — a duplicate would
    // silently collapse two exercises into one, taking the second one's name.
    final ids = exerciseSeedData.map((e) => e.id.value).toList();
    expect(ids.toSet(), hasLength(ids.length));
  });

  test('every name is unique', () {
    // Two identically named rows are indistinguishable in every picker.
    final names = exerciseSeedData.map((e) => e.name.value).toList();
    expect(names.toSet(), hasLength(names.length));
  });

  test('no seeded id looks like a custom one', () {
    // A seed row in the `custom_` namespace would collide with a user's own
    // exercise and get overwritten by the upsert on the next launch.
    for (final exercise in exerciseSeedData) {
      expect(
        exercise.id.value,
        isNot(startsWith('custom_')),
        reason: exercise.id.value,
      );
    }
  });

  test('every muscle id is a real one', () {
    for (final exercise in exerciseSeedData) {
      for (final muscleId in exercise.muscleIds.value) {
        expect(
          MuscleId.all,
          contains(muscleId),
          reason: '${exercise.id.value} lists unknown muscle "$muscleId"',
        );
      }
    }
  });

  test('no exercise trains nothing, or the same muscle twice', () {
    for (final exercise in exerciseSeedData) {
      final muscleIds = exercise.muscleIds.value;
      // An empty list means the exercise contributes to no volume total and is
      // invisible to the map — indistinguishable from a bug.
      expect(muscleIds, isNotEmpty, reason: exercise.id.value);
      expect(
        muscleIds.toSet(),
        hasLength(muscleIds.length),
        reason: '${exercise.id.value} repeats a muscle',
      );
    }
  });

  test('every gif path follows the assets/exercises/<id>.gif convention', () {
    // The files are added over time, so a missing GIF is fine — a path that
    // doesn't match its id is not, because it would silently show the wrong
    // animation once both files exist.
    for (final exercise in exerciseSeedData) {
      expect(
        exercise.gifPath.value,
        'assets/exercises/${exercise.id.value}.gif',
        reason: exercise.id.value,
      );
    }
  });

  test('every name would slugify back to its own id', () {
    // Keeps ids predictable: whatever a name is, the id is the same string in
    // snake_case. Drift-apart names and ids make the library hard to search
    // through as a developer.
    for (final exercise in exerciseSeedData) {
      expect(
        slugifyExerciseName(exercise.name.value),
        'custom_${exercise.id.value}',
        reason: '${exercise.name.value} -> ${exercise.id.value}',
      );
    }
  });

  test('only barbell lifts are marked plate-loaded', () {
    // Plate-loaded machines (leg press, hack squat) are deliberately excluded:
    // their sleds have an unlisted starting weight, so "bar + 2 × plates" would
    // report a confidently wrong number.
    final plateLoaded = exerciseSeedData
        .where((e) => e.isPlateLoaded.present && e.isPlateLoaded.value)
        .map((e) => e.id.value)
        .toSet();

    expect(plateLoaded, contains('barbell_bench_press'));
    expect(plateLoaded, contains('deadlift'));
    expect(plateLoaded, contains('barbell_back_squat'));
    expect(plateLoaded, isNot(contains('leg_press')));
    expect(plateLoaded, isNot(contains('hack_squat')));
    expect(plateLoaded, isNot(contains('dumbbell_bench_press')));
    expect(plateLoaded, isNot(contains('cable_fly')));
    expect(plateLoaded, isNot(contains('pull_up')));
  });

  test('most of the library is not plate-loaded', () {
    // A sanity bound rather than an exact count: if a careless edit ever flipped
    // the flag on everything, the log dialog would offer plate stacking for
    // push-ups.
    final count = exerciseSeedData
        .where((e) => e.isPlateLoaded.present && e.isPlateLoaded.value)
        .length;

    expect(count, greaterThan(15));
    expect(count, lessThan(exerciseSeedData.length ~/ 2));
  });

  test('every muscle on the map is trained by something', () {
    // A muscle no exercise touches is a permanently dark patch on the heatmap.
    // Neck is excluded: there's no neck training in the library on purpose.
    final trained = {
      for (final exercise in exerciseSeedData) ...exercise.muscleIds.value,
    };
    for (final muscleId in MuscleId.all) {
      if (muscleId == MuscleId.neck) continue;
      expect(trained, contains(muscleId), reason: '$muscleId has no exercise');
    }
  });
}
