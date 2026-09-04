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

    test('bodyweight lifts are not ranked', () {
      // Their real load is your body plus any added weight, but the app logs
      // only the added weight — a strict pull-up is 0 kg, which would rank
      // Beginner forever. Adding a table for these without changing the load
      // model would produce a rank that is confidently wrong.
      for (final id in ['pull_up', 'chin_up', 'chest_dip', 'push_up']) {
        expect(hasStrengthStandard(id), isFalse, reason: '$id is bodyweight');
      }
    });

    test('dumbbell lifts are not ranked', () {
      // Published dumbbell tables are per dumbbell and the app doesn't record
      // whether the user entered one or the pair. Being wrong here is a
      // factor of two — Novice or Elite for the same lift.
      for (final id in [
        'dumbbell_bench_press',
        'dumbbell_shoulder_press',
        'dumbbell_row',
        'goblet_squat',
      ]) {
        expect(hasStrengthStandard(id), isFalse, reason: '$id is a dumbbell');
      }
    });

    test('plate-loaded machines are not ranked', () {
      // The sled has an unknown weight of its own and the leverage differs per
      // machine, so the plates on it aren't comparable between two gyms. The
      // same reason `isPlateLoaded` skips them.
      for (final id in ['leg_press', 'hack_squat', 'pec_deck']) {
        expect(hasStrengthStandard(id), isFalse, reason: '$id is a machine');
      }
    });

    test('a barbell or cable lift is ranked even when it is isolation work', () {
      // The objection to ranking a cable fly was never that it's a small lift
      // — it's that nobody publishes what a good one is. Where a table exists
      // and the load is unambiguous, the lift gets a rank.
      expect(hasStrengthStandard('barbell_biceps_curl'), isTrue);
      expect(hasStrengthStandard('lat_pulldown'), isTrue);
      expect(hasStrengthStandard('skull_crusher'), isTrue);
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
