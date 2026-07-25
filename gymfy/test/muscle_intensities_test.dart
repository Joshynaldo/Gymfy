// Unit tests for the volume -> intensity aggregation that drives the muscle
// map. Pure logic, no database.

import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/muscle_map/data/muscle_volume_repository.dart';

void main() {
  test('empty input yields an empty map', () {
    expect(muscleIntensities(const []), isEmpty);
  });

  test('normalizes so the hardest-worked muscle is 1.0', () {
    final result = muscleIntensities(const [
      // chest+triceps: 100 * 5 = 500 volume each
      (weight: 100, reps: 5, muscleIds: ['chest', 'triceps']),
      // biceps: 20 * 10 = 200 volume
      (weight: 20, reps: 10, muscleIds: ['biceps']),
    ]);

    expect(result['chest'], 1.0);
    expect(result['triceps'], 1.0);
    expect(result['biceps'], closeTo(0.4, 1e-9)); // 200 / 500
  });

  test('accumulates volume across sets for the same muscle', () {
    final result = muscleIntensities(const [
      (weight: 50, reps: 10, muscleIds: ['chest']), // 500
      (weight: 50, reps: 10, muscleIds: ['chest']), // +500 = 1000
      (weight: 100, reps: 5, muscleIds: ['triceps']), // 500
    ]);

    expect(result['chest'], 1.0); // 1000 is the max
    expect(result['triceps'], closeTo(0.5, 1e-9)); // 500 / 1000
  });

  test('bodyweight sets (weight 0) count reps as effort', () {
    final result = muscleIntensities(const [
      (weight: 0, reps: 20, muscleIds: ['abs']), // effort 20
      (weight: 0, reps: 10, muscleIds: ['lats']), // effort 10
    ]);

    expect(result['abs'], 1.0);
    expect(result['lats'], closeTo(0.5, 1e-9));
  });
}
