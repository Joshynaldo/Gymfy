// Percent-of-1RM targets: which max a percentage is taken of, how the result
// is rounded to something loadable, and when no number is offered at all.

import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/overload/data/overload_math.dart';
import 'package:gymfy/features/overload/data/overload_repository.dart';
import 'package:gymfy/features/overload/data/percent_target.dart';
import 'package:gymfy/shared/database/app_database.dart';
import 'package:gymfy/shared/utils/units.dart';

const _kgPlates = [25.0, 20.0, 15.0, 10.0, 5.0, 2.5, 1.25];

Exercise _exercise({
  bool plateLoaded = true,
  bool timed = false,
  double? barKg,
}) => Exercise(
  id: 'barbell_back_squat',
  name: 'Barbell Back Squat',
  muscleIds: const ['quads'],
  isPlateLoaded: plateLoaded,
  isCustom: false,
  isArchived: false,
  isTimed: timed,
  equipment: 'barbell',
  barWeightKg: barKg,
);

WorkoutExercise _entry({double? percent}) => WorkoutExercise(
  id: 1,
  dayId: 1,
  exerciseId: 'barbell_back_squat',
  position: 0,
  defaultSets: 5,
  defaultReps: 5,
  warmupSets: 0,
  targetPercent: percent,
);

void main() {
  group('workingOneRmKg', () {
    final tested = TestedOneRm(
      exerciseId: 'barbell_back_squat',
      weightKg: 140,
      testedOn: DateTime(2026, 9, 1),
      updatedAt: DateTime(2026, 9, 1),
    );
    final estimate = (
      oneRm: 150.0,
      weight: 130.0,
      reps: 4,
      date: DateTime(2026, 9, 10),
    );

    test('a tested max beats the estimate, even a higher one', () {
      expect(workingOneRmKg(tested: tested, estimate: estimate), 140);
    });

    test('falls back to the estimate, then to nothing', () {
      expect(workingOneRmKg(estimate: estimate), 150);
      expect(workingOneRmKg(), isNull);
    });

    test('a zero max is no max', () {
      final zero = (oneRm: 0.0, weight: 0.0, reps: 10, date: DateTime(2026));
      expect(workingOneRmKg(estimate: zero), isNull);
    });
  });

  group('percentOfMaxKg', () {
    test('takes the percentage, then the deload on top', () {
      expect(percentOfMaxKg(oneRmKg: 200, percent: 75), 150);
      expect(
        percentOfMaxKg(oneRmKg: 200, percent: 75, deloadPercent: 60),
        closeTo(90, 0.0001),
      );
    });
  });

  group('nearestLoadable', () {
    double round(double kg, {bool plateLoaded = true, double bar = 20}) =>
        nearestLoadable(
          kilograms: kg,
          plateLoaded: plateLoaded,
          unit: WeightUnit.kg,
          plates: _kgPlates,
          bar: bar,
        );

    test('an exactly loadable weight is left alone', () {
      expect(round(102.5), 102.5);
    });

    test('rounds to the nearer of the two loadable neighbours', () {
      // 2.5 kg steps on a 20 kg bar with 1.25s: 101 is nearer 100 than 102.5,
      // 102 is nearer 102.5.
      expect(round(101), 100);
      expect(round(102), 102.5);
    });

    test('a tie goes to the lighter weight', () {
      expect(round(101.25), 100);
    });

    test('below the bar is just the bar', () {
      expect(round(12), 20);
    });

    test('the exercise\'s own bar counts', () {
      // 61 on a 15 kg bar: 60 (15 + 2×22.5) is loadable and nearer than 62.5.
      expect(round(61, bar: 15), 60);
    });

    test('dumbbells and machines round to the unit step', () {
      expect(round(31.3, plateLoaded: false), 31.5);
    });
  });

  group('percentOfMaxSuggestion', () {
    OverloadSuggestion? suggest({
      double? percent = 75,
      double? oneRm = 140,
      Exercise? exercise,
      double? deload,
    }) => percentOfMaxSuggestion(
      entry: _entry(percent: percent),
      exercise: exercise ?? _exercise(),
      oneRmKg: oneRm,
      unit: WeightUnit.kg,
      plates: _kgPlates,
      gymBar: 20,
      deloadPercent: deload,
    );

    test('turns the plan\'s percentage into a loadable weight', () {
      final result = suggest()!;
      // 75 % of 140 is 105, which is loadable.
      expect(result.weight, 105);
      expect(result.reason, OverloadReason.percentOfMax);
      expect(result.targetPercent, 75);
      expect(result.deloadPercent, isNull);
    });

    test('a deload week lightens it and says so', () {
      final result = suggest(deload: 60)!;
      // 60 % of 105 is 63 — nearest loadable on a 20 kg bar is 62.5.
      expect(result.weight, 62.5);
      expect(result.reason, OverloadReason.blockDeload);
      expect(result.targetPercent, 75);
      expect(result.deloadPercent, 60);
    });

    test('nothing without a percentage, a max, or for a timed lift', () {
      expect(suggest(percent: null), isNull);
      expect(suggest(oneRm: null), isNull);
      expect(suggest(exercise: _exercise(timed: true)), isNull);
    });
  });

  test('formatPercent drops a pointless decimal', () {
    expect(formatPercent(75), '75%');
    expect(formatPercent(72.5), '72.5%');
  });
}
