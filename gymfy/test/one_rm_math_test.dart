// The maths behind the 1RM calculator: correct Epley output, a true single rep
// left alone, junk input rejected, and the inverse being a real inverse.

import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/calculator/data/one_rm_math.dart';

void main() {
  group('epleyOneRm', () {
    test('applies the Epley formula', () {
      // 100 × (1 + 5/30) = 116.666…
      expect(epleyOneRm(weight: 100, reps: 5), closeTo(116.667, 0.001));
      // 80 × (1 + 10/30) = 106.666…
      expect(epleyOneRm(weight: 80, reps: 10), closeTo(106.667, 0.001));
    });

    test('a single rep is returned untouched', () {
      // Not 103.3 — the lift itself was already a max.
      expect(epleyOneRm(weight: 100, reps: 1), 100);
    });

    test('rejects nonsense input', () {
      expect(epleyOneRm(weight: 0, reps: 5), isNull);
      expect(epleyOneRm(weight: -60, reps: 5), isNull);
      expect(epleyOneRm(weight: 100, reps: 0), isNull);
    });

    test('more reps at the same weight means a bigger max', () {
      final three = epleyOneRm(weight: 100, reps: 3)!;
      final eight = epleyOneRm(weight: 100, reps: 8)!;
      expect(eight, greaterThan(three));
    });
  });

  group('brzyckiOneRm', () {
    test('applies the Brzycki formula', () {
      // 100 × 36 / (37 − 5) = 112.5
      expect(brzyckiOneRm(weight: 100, reps: 5), closeTo(112.5, 0.001));
    });

    test('a single rep is returned untouched', () {
      expect(brzyckiOneRm(weight: 100, reps: 1), 100);
    });

    test('refuses the rep count that divides by zero', () {
      expect(brzyckiOneRm(weight: 100, reps: 37), isNull);
      expect(brzyckiOneRm(weight: 100, reps: 40), isNull);
    });
  });

  group('landerOneRm', () {
    test('applies the Lander formula', () {
      // 100 × 100 / (101.3 − 2.67123 × 5) = 113.708…
      expect(landerOneRm(weight: 100, reps: 5), closeTo(113.709, 0.001));
    });

    test('a single rep is returned untouched', () {
      expect(landerOneRm(weight: 100, reps: 1), 100);
    });

    test('refuses rep counts past its denominator', () {
      expect(landerOneRm(weight: 100, reps: 40), isNull);
    });
  });

  group('estimateOneRm', () {
    test('collects every formula plus their average and spread', () {
      final result = estimateOneRm(weight: 100, reps: 5)!;

      expect(result.byFormula.length, 3);
      expect(result.byFormula[OneRmFormula.epley], closeTo(116.667, 0.001));
      expect(result.byFormula[OneRmFormula.brzycki], closeTo(112.5, 0.001));
      expect(result.byFormula[OneRmFormula.lander], closeTo(113.709, 0.001));
      // Brzycki is the low read at 5 reps, Epley the high one.
      expect(result.lowest, closeTo(112.5, 0.001));
      expect(result.highest, closeTo(116.667, 0.001));
      expect(result.average, closeTo(114.292, 0.001));
    });

    test('the formulas agree exactly on a true single', () {
      final result = estimateOneRm(weight: 140, reps: 1)!;

      expect(result.lowest, 140);
      expect(result.highest, 140);
      expect(result.average, 140);
    });

    test('they drift apart as the reps climb', () {
      final five = estimateOneRm(weight: 100, reps: 5)!;
      final fifteen = estimateOneRm(weight: 100, reps: 15)!;
      double spread(OneRmEstimates e) => e.highest - e.lowest;

      expect(spread(fifteen), greaterThan(spread(five)));
    });

    test('leaves out formulas that cannot answer, rather than faking one', () {
      // Brzycki divides by zero at 37 reps; the other two still answer.
      final result = estimateOneRm(weight: 100, reps: 37)!;

      expect(result.byFormula.containsKey(OneRmFormula.brzycki), isFalse);
      expect(result.byFormula.length, 2);
    });

    test('returns nothing for nonsense input', () {
      expect(estimateOneRm(weight: 0, reps: 5), isNull);
      expect(estimateOneRm(weight: 100, reps: 0), isNull);
    });
  });

  group('weightForReps', () {
    test('is the inverse of Epley', () {
      final oneRm = epleyOneRm(weight: 100, reps: 5)!;
      expect(weightForReps(oneRm: oneRm, reps: 5), closeTo(100, 0.001));
    });

    test('a single rep is the max itself', () {
      expect(weightForReps(oneRm: 120, reps: 1), 120);
    });

    test('rejects nonsense input', () {
      expect(weightForReps(oneRm: 0, reps: 5), isNull);
      expect(weightForReps(oneRm: 120, reps: 0), isNull);
    });
  });

  group('roundToPlate', () {
    test('rounds to the nearest half kilo', () {
      expect(roundToPlate(116.667), 116.5);
      expect(roundToPlate(116.8), 117.0);
      expect(roundToPlate(100), 100.0);
    });
  });

  // `parseWeight` moved to shared/utils/format.dart when units arrived; its
  // tests live in units_test.dart, next to the unit-aware version.
}
