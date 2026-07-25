// Unit tests for the personal-records derivation. Pure logic, no database.

import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/progress/data/progress_repository.dart';

ExerciseHistoryPoint _point(
  DateTime date,
  double topWeight,
  int reps,
  double volume,
) {
  return ExerciseHistoryPoint(
    date: date,
    topWeight: topWeight,
    repsAtTop: reps,
    totalVolume: volume,
  );
}

void main() {
  test('null when there is no history', () {
    expect(personalRecordsFrom(const []), isNull);
  });

  test('picks the heaviest weight and the best-volume session', () {
    final records = personalRecordsFrom([
      _point(DateTime(2026, 1, 1), 100, 5, 1500),
      _point(DateTime(2026, 1, 8), 110, 3, 1200), // heaviest weight
      _point(DateTime(2026, 1, 15), 105, 8, 2000), // best volume
    ])!;

    expect(records.heaviestWeight, 110);
    expect(records.repsAtHeaviest, 3);
    expect(records.heaviestDate, DateTime(2026, 1, 8));
    expect(records.bestVolume, 2000);
    expect(records.bestVolumeDate, DateTime(2026, 1, 15));
  });

  test('breaks equal-weight ties by more reps', () {
    final records = personalRecordsFrom([
      _point(DateTime(2026, 1, 1), 100, 5, 500),
      _point(DateTime(2026, 1, 8), 100, 8, 800),
    ])!;

    expect(records.heaviestWeight, 100);
    expect(records.repsAtHeaviest, 8);
  });
}
