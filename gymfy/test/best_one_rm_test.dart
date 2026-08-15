// Picking the set that implies the biggest one-rep max — which is not always
// the heaviest set on the bar.

import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/progress/data/progress_repository.dart';

void main() {
  ExerciseHistoryPoint point(int day, double weight, int reps) {
    return ExerciseHistoryPoint(
      date: DateTime(2026, 7, day),
      topWeight: weight,
      repsAtTop: reps,
      totalVolume: weight * reps,
    );
  }

  test('no history means no estimate', () {
    expect(bestEstimatedOneRm([]), isNull);
  });

  test('a rep-heavy set can beat a heavier single', () {
    final best = bestEstimatedOneRm([
      point(1, 100, 1), // 100
      point(8, 90, 5), // ~103
    ])!;

    expect(best.weight, 90);
    expect(best.reps, 5);
    expect(best.date, DateTime(2026, 7, 8));
    expect(best.oneRm, greaterThan(100));
  });

  test('picks the strongest day, not the most recent', () {
    final best = bestEstimatedOneRm([
      point(1, 120, 3),
      point(20, 100, 3), // a lighter, later session
    ])!;

    expect(best.weight, 120);
    expect(best.date, DateTime(2026, 7, 1));
  });

  test('bodyweight sets are skipped, not treated as zero kilos', () {
    // Weight 0 gives every formula nothing to work with.
    expect(bestEstimatedOneRm([point(1, 0, 12)]), isNull);

    final best = bestEstimatedOneRm([point(1, 0, 12), point(2, 60, 5)])!;
    expect(best.weight, 60);
  });

  test('the estimate matches the calculator for the same set', () {
    final best = bestEstimatedOneRm([point(1, 100, 5)])!;

    // Same average of the three formulas the calculator screen shows.
    expect(best.oneRm, closeTo(114.292, 0.001));
  });
}
