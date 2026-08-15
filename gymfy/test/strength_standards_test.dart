// The strength standard tables: internally consistent, sex-specific, and
// scoped to the lifts where standards actually mean something.

import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/calculator/data/strength_standards.dart';
import 'package:gymfy/features/exercises/data/exercise_seed_data.dart';

void main() {
  group('StrengthTier', () {
    test('runs weakest to strongest', () {
      expect(StrengthTier.values.map((t) => t.label), [
        'Beginner',
        'Novice',
        'Intermediate',
        'Advanced',
        'Elite',
      ]);
      expect(
        StrengthTier.beginner.index,
        lessThan(StrengthTier.elite.index),
      );
    });

    test('every tier has a next one except elite', () {
      expect(StrengthTier.beginner.next, StrengthTier.novice);
      expect(StrengthTier.advanced.next, StrengthTier.elite);
      expect(StrengthTier.elite.next, isNull);
    });
  });

  group('the tables themselves', () {
    test('thresholds only ever go up', () {
      for (final entry in strengthStandards.entries) {
        for (final standard in [entry.value.male, entry.value.female]) {
          expect(
            standard.novice,
            lessThan(standard.intermediate),
            reason: '${entry.key} novice must be below intermediate',
          );
          expect(
            standard.intermediate,
            lessThan(standard.advanced),
            reason: '${entry.key} intermediate must be below advanced',
          );
          expect(
            standard.advanced,
            lessThan(standard.elite),
            reason: '${entry.key} advanced must be below elite',
          );
        }
      }
    });

    test('every standard names a real exercise from the seed data', () {
      final seedIds = exerciseSeedData.map((e) => e.id.value).toSet();
      for (final id in strengthStandards.keys) {
        expect(seedIds, contains(id), reason: '$id is not a seeded exercise');
      }
    });

    test('the women\'s ratios are lower than the men\'s, tier for tier', () {
      // Not a stylistic choice — it's what the published tables say, and using
      // one shared table would misrank half the users.
      for (final entry in strengthStandards.entries) {
        for (final tier in StrengthTier.values) {
          final male = entry.value.male.ratioFor(tier);
          final female = entry.value.female.ratioFor(tier);
          if (male == null || female == null) continue;
          expect(
            female,
            lessThan(male),
            reason: '${entry.key} ${tier.label}',
          );
        }
      }
    });

    test('the squat is ranked harder than the bench', () {
      // A sanity check that the numbers weren't transcribed into the wrong
      // exercise: everyone squats more than they bench.
      final squat = standardsFor('barbell_back_squat', LifterSex.male)!;
      final bench = standardsFor('barbell_bench_press', LifterSex.male)!;
      expect(squat.elite, greaterThan(bench.elite));
    });
  });

  group('lookups', () {
    test('returns the right table per sex', () {
      final male = standardsFor('barbell_bench_press', LifterSex.male)!;
      final female = standardsFor('barbell_bench_press', LifterSex.female)!;
      expect(male.intermediate, 1.0);
      expect(female.intermediate, 0.6);
    });

    test('unranked exercises get nothing rather than a guess', () {
      expect(standardsFor('dumbbell_lateral_raise', LifterSex.male), isNull);
      expect(standardsFor('plank', LifterSex.female), isNull);
      expect(hasStrengthStandard('cable_crunch'), isFalse);
      expect(hasStrengthStandard('deadlift'), isTrue);
    });

    test('beginner has no bar to clear', () {
      final squat = standardsFor('barbell_back_squat', LifterSex.male)!;
      expect(squat.ratioFor(StrengthTier.beginner), isNull);
      expect(squat.ratioFor(StrengthTier.elite), 2.5);
    });
  });
}
