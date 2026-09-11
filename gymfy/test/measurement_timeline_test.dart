// Covers the timeline chart's data prep: pulling one body part's series out of
// the history, and the y-axis window.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/progress/data/measurements_repository.dart';
import 'package:gymfy/features/progress/widgets/measurement_timeline_chart.dart';
import 'package:gymfy/shared/database/app_database.dart';
import 'package:gymfy/shared/models/body_measurement.dart';

void main() {
  group('seriesFor', () {
    late AppDatabase db;
    late MeasurementsRepository repo;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = MeasurementsRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    Future<void> log(int day, MeasurementField field, double value) {
      return repo.setField(
        day: DateTime(2026, 7, day),
        field: field,
        value: value,
      );
    }

    test(
      'returns one body part oldest first, skipping unmeasured days',
      () async {
        await log(10, MeasurementField.weight, 84);
        await log(17, MeasurementField.waist, 86); // no weight this day
        await log(24, MeasurementField.weight, 82.5);

        final rows = await repo.watchAll().first;
        final series = seriesFor(rows, MeasurementField.weight);

        expect(series.map((p) => p.value), [84, 82.5]);
        expect(series.map((p) => p.day), [
          DateTime(2026, 7, 10),
          DateTime(2026, 7, 24),
        ]);
      },
    );

    test('a body part that was never measured has an empty series', () async {
      await log(10, MeasurementField.weight, 84);

      final rows = await repo.watchAll().first;
      expect(seriesFor(rows, MeasurementField.hips), isEmpty);
    });
  });

  group('axisRange', () {
    test('hugs the data instead of anchoring at zero', () {
      // A 2 kg swing must not be squashed by an axis starting at 0.
      final range = axisRange([82.0, 83.0, 84.0]);
      expect(range.min, greaterThan(80));
      expect(range.min, lessThan(82));
      expect(range.max, greaterThan(84));
    });

    test('a flat series still gets a visible band', () {
      final range = axisRange([82.0, 82.0]);
      expect(range.max - range.min, greaterThan(0));
      expect(range.min, lessThan(82));
      expect(range.max, greaterThan(82));
    });

    test('never dips below zero', () {
      final range = axisRange([0.4, 0.5]);
      expect(range.min, 0);
    });
  });
}
