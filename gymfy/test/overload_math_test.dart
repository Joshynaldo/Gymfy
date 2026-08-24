// Progressive overload: when the weight goes up, when it stays, and what the
// suggestion is built from.

import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/overload/data/overload_math.dart';
import 'package:gymfy/shared/database/app_database.dart';

void main() {
  /// A set list at one weight — `reps` per set, [count] sets.
  List<LoggedSet> sets(double weight, int reps, {int count = 3}) {
    return [
      for (var i = 1; i <= count; i++)
        LoggedSet(
          id: i,
          sessionId: 1,
          exerciseId: 'barbell_bench_press',
          setNumber: i,
          weight: weight,
          reps: reps,
          isWarmup: false,
        ),
    ];
  }

  group('defaultIncrementKg', () {
    test('legs get the biggest jump', () {
      expect(defaultIncrementKg(['quads', 'glutes']), 5);
    });

    test('shoulders and arms get the smallest', () {
      expect(defaultIncrementKg(['side_deltoid']), 1.25);
      expect(defaultIncrementKg(['biceps']), 1.25);
    });

    test('a mixed exercise is limited by its smallest muscle', () {
      // A squat that also lists biceps would otherwise get the leg rate, and
      // overshooting the weakest link is what stalls a lift.
      expect(defaultIncrementKg(['quads', 'biceps']), 1.25);
    });

    test('an unknown muscle falls back rather than returning nothing', () {
      expect(defaultIncrementKg(['wingspan']), fallbackIncrementKg);
    });

    test('core work gets no automatic increase at all', () {
      // Suggesting +2.5 kg on a plank is meaningless.
      expect(defaultIncrementKg(['abs']), isNull);
      expect(defaultIncrementKg(['abs', 'obliques']), isNull);
    });

    test('a core exercise that also trains something else still progresses', () {
      // An ab wheel rollout works the lats too, and that part can be loaded.
      expect(defaultIncrementKg(['abs', 'lats']), 2.5);
    });
  });

  group('earnedIncrease', () {
    test('every set at the target earns it', () {
      expect(
        earnedIncrease(sets: sets(60, 12), plannedSets: 3, targetReps: 12),
        isTrue,
      );
    });

    test('beating the target counts too', () {
      expect(
        earnedIncrease(sets: sets(60, 14), plannedSets: 3, targetReps: 12),
        isTrue,
      );
    });

    test('one short set is enough to withhold it', () {
      final mixed = [...sets(60, 12, count: 2), ...sets(60, 10, count: 1)];

      expect(
        earnedIncrease(sets: mixed, plannedSets: 3, targetReps: 12),
        isFalse,
      );
    });

    test('missing a whole set withholds it', () {
      // Two of three sets at the top of the range is a good session, but it
      // isn't the session that was planned.
      expect(
        earnedIncrease(sets: sets(60, 12, count: 2), plannedSets: 3, targetReps: 12),
        isFalse,
      );
    });

    test('extra sets beyond the plan do not spoil it', () {
      expect(
        earnedIncrease(sets: sets(60, 12, count: 5), plannedSets: 3, targetReps: 12),
        isTrue,
      );
    });

    test('no sets at all is not an achievement', () {
      expect(
        earnedIncrease(sets: const [], plannedSets: 3, targetReps: 12),
        isFalse,
      );
    });
  });

  group('targetRepsFor', () {
    WorkoutExercise entry({required int reps, int? repsMax}) {
      return WorkoutExercise(
        id: 1,
        dayId: 1,
        exerciseId: 'barbell_bench_press',
        position: 0,
        defaultSets: 3,
        defaultReps: reps,
        defaultRepsMax: repsMax,
        warmupSets: 0,
      );
    }

    test('a range asks for its top', () {
      // The whole point of double progression: climb the range, then add weight.
      expect(targetRepsFor(entry(reps: 8, repsMax: 12)), 12);
    });

    test('a fixed target is its own ceiling', () {
      expect(targetRepsFor(entry(reps: 10)), 10);
    });
  });

  group('resolveIncrementKg', () {
    test('no percentage means the fixed step', () {
      expect(resolveIncrementKg(currentWeightKg: 100, fixedKg: 2.5), 2.5);
    });

    test('a percentage is taken from the current weight', () {
      expect(
        resolveIncrementKg(currentWeightKg: 100, fixedKg: 2.5, percent: 2.5),
        2.5,
      );
      expect(
        resolveIncrementKg(currentWeightKg: 40, fixedKg: 2.5, percent: 2.5),
        1,
      );
    });

    test('the same percentage scales with the lift', () {
      // A fixed step is generous on a curl and timid on a squat; this is the
      // setting that fixes that with one number.
      final curl = resolveIncrementKg(
        currentWeightKg: 20,
        fixedKg: 2.5,
        percent: 5,
      );
      final squat = resolveIncrementKg(
        currentWeightKg: 140,
        fixedKg: 2.5,
        percent: 5,
      );

      expect(curl, 1);
      expect(squat, 7);
    });

    test('a percentage of a bodyweight exercise falls back to the step', () {
      // Bodyweight sets are logged at zero, and 5% of nothing is nothing —
      // progression would silently never happen.
      expect(
        resolveIncrementKg(currentWeightKg: 0, fixedKg: 2.5, percent: 5),
        2.5,
      );
    });

    test('a zero or negative percentage is ignored', () {
      expect(
        resolveIncrementKg(currentWeightKg: 100, fixedKg: 2.5, percent: 0),
        2.5,
      );
    });
  });

  group('suggestNextWeight', () {
    OverloadSuggestion suggest(
      List<LoggedSet> lastSets, {
      double increment = 2.5,
      int increasesInARow = 0,
      int? deloadAfterWeeks,
    }) {
      return suggestNextWeight(
        lastSets: lastSets,
        plannedSets: 3,
        targetReps: 12,
        incrementKg: increment,
        increasesInARow: increasesInARow,
        deloadAfterWeeks: deloadAfterWeeks,
      );
    }

    test('hitting the target adds the increment', () {
      final result = suggest(sets(60, 12));

      expect(result.weight, 62.5);
      expect(result.reason, OverloadReason.earned);
      expect(result.isIncrease, isTrue);
    });

    test('falling short repeats the same weight', () {
      final result = suggest(sets(60, 9));

      // Nothing accumulates and no debt is carried — a bad week just means the
      // same weight again, which is what keeps the number honest.
      expect(result.weight, 60);
      expect(result.reason, OverloadReason.repeat);
      expect(result.isIncrease, isFalse);
    });

    test('the base is the heaviest set, not the last one', () {
      final descending = [
        ...sets(80, 12, count: 1),
        ...sets(70, 12, count: 1),
        ...sets(60, 12, count: 1),
      ];

      // Back-off sets after a top set must not drag the suggestion down.
      expect(suggest(descending).weight, 82.5);
    });

    test('no history gives no number', () {
      final result = suggest(const []);

      // Zero rather than a guess: we have no idea what this person lifts, and
      // an invented number is worse than an empty field.
      expect(result.weight, 0);
      expect(result.reason, OverloadReason.firstTime);
    });

    test('a custom increment is used instead of the default', () {
      expect(suggest(sets(60, 12), increment: 5).weight, 65);
    });

    test('enough increases in a row suggests a deload', () {
      final result = suggest(
        sets(100, 12),
        increasesInARow: 4,
        deloadAfterWeeks: 4,
      );

      expect(result.weight, 90); // 10% off
      expect(result.reason, OverloadReason.deload);
      expect(result.isIncrease, isFalse);
    });

    test('a deload outranks an earned increase', () {
      // Both conditions are met here. The deload wins, because the point of it
      // is to interrupt a run of increases.
      final result = suggest(
        sets(100, 12),
        increasesInARow: 6,
        deloadAfterWeeks: 4,
      );

      expect(result.reason, OverloadReason.deload);
    });

    test('without a deload setting a long run just keeps climbing', () {
      final result = suggest(sets(100, 12), increasesInARow: 20);

      expect(result.reason, OverloadReason.earned);
      expect(result.weight, 102.5);
    });

    test('a run shorter than the setting does not deload', () {
      final result = suggest(
        sets(100, 12),
        increasesInARow: 3,
        deloadAfterWeeks: 4,
      );

      expect(result.reason, OverloadReason.earned);
    });
  });
}
