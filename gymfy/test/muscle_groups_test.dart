// The exercise library's categories: which body region each exercise is filed
// under, and in what order the sections come out.

import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/exercises/data/muscle_groups.dart';
import 'package:gymfy/shared/models/muscle_ids.dart';

void main() {
  group('groupOfExercise', () {
    test('files an exercise under its primary muscle', () {
      // The bench press trains chest, front deltoid and triceps. It belongs
      // under Chest once, not under three headings.
      expect(
        groupOfExercise([
          MuscleId.chest,
          MuscleId.frontDeltoid,
          MuscleId.triceps,
        ]),
        MuscleGroup.chest,
      );
    });

    test('the order of the muscle list decides the region', () {
      expect(
        groupOfExercise([MuscleId.triceps, MuscleId.chest]),
        MuscleGroup.arms,
      );
      expect(
        groupOfExercise([MuscleId.chest, MuscleId.triceps]),
        MuscleGroup.chest,
      );
    });

    test('every known muscle has been placed in a region', () {
      // Adding a muscle without placing it in the map would quietly dump its
      // exercises into Core, where nobody would look for them. Asked through
      // `isMuscleMapped` rather than by checking the result isn't Core, because
      // abs and obliques genuinely are Core and a result check couldn't tell
      // them apart from a muscle nobody remembered to file.
      for (final muscle in MuscleId.all) {
        expect(isMuscleMapped(muscle), isTrue, reason: '$muscle has no region');
      }
    });

    test('an exercise with no muscles still lands somewhere', () {
      // Possible for a hastily-made custom exercise. Vanishing from the list
      // would look like data loss.
      expect(groupOfExercise(const []), MuscleGroup.core);
    });
  });

  group('groupExercises', () {
    List<String> musclesOf(List<String> e) => e;

    test('sections come out in body order, not data order', () {
      final grouped = groupExercises([
        [MuscleId.abs],
        [MuscleId.chest],
        [MuscleId.quads],
      ], musclesOf);

      // Fixed order, so a heading doesn't jump around while you're reading as
      // the library is filtered.
      expect(grouped.keys.toList(), [
        MuscleGroup.chest,
        MuscleGroup.legs,
        MuscleGroup.core,
      ]);
    });

    test('empty regions are left out entirely', () {
      final grouped = groupExercises([
        [MuscleId.chest],
      ], musclesOf);

      expect(grouped.keys, [MuscleGroup.chest]);
    });

    test('keeps the order exercises arrived in within a section', () {
      final first = [MuscleId.chest, 'a'];
      final second = [MuscleId.chest, 'b'];

      final grouped = groupExercises([first, second], musclesOf);

      expect(grouped[MuscleGroup.chest], [first, second]);
    });

    test('nothing at all groups to nothing', () {
      expect(groupExercises(const <List<String>>[], musclesOf), isEmpty);
    });
  });
}
