// Covers the measurement write path: per-field updates onto one row per day,
// the auto-timestamp, clearing, and the "previous value" lookup.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/progress/data/measurements_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';
import 'package:gymfy/shared/models/body_measurement.dart';

void main() {
  late AppDatabase db;
  late MeasurementsRepository repo;
  final today = DateTime(2026, 7, 25);
  final yesterday = DateTime(2026, 7, 24);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = MeasurementsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<List<BodyMeasurement>> allRows() => repo.watchAll().first;

  test('two fields on the same day land on one row', () async {
    await repo.setField(
      day: today,
      field: MeasurementField.weight,
      value: 82.4,
    );
    await repo.setField(day: today, field: MeasurementField.waist, value: 84);

    final rows = await allRows();
    expect(rows, hasLength(1));
    expect(rows.single.weightKg, 82.4);
    expect(rows.single.waistCm, 84);
  });

  test('updating one field leaves the others alone', () async {
    await repo.setField(day: today, field: MeasurementField.chest, value: 102);
    await repo.setField(day: today, field: MeasurementField.weight, value: 82);
    await repo.setField(day: today, field: MeasurementField.weight, value: 81.5);

    final row = (await allRows()).single;
    expect(row.weightKg, 81.5);
    expect(row.chestCm, 102); // untouched by the weight updates
  });

  test('clearing a field nulls just that field', () async {
    await repo.setField(day: today, field: MeasurementField.chest, value: 102);
    await repo.setField(day: today, field: MeasurementField.weight, value: 82);

    await repo.setField(
      day: today,
      field: MeasurementField.chest,
      value: null,
    );

    final row = (await allRows()).single;
    expect(row.chestCm, isNull);
    expect(row.weightKg, 82);
  });

  test('clearing the last field removes the empty row entirely', () async {
    await repo.setField(day: today, field: MeasurementField.weight, value: 82);
    await repo.setField(
      day: today,
      field: MeasurementField.weight,
      value: null,
    );

    expect(await allRows(), isEmpty);
  });

  test('history comes back newest day first', () async {
    await repo.setField(
      day: yesterday,
      field: MeasurementField.weight,
      value: 83,
    );
    await repo.setField(day: today, field: MeasurementField.weight, value: 82);

    final rows = await allRows();
    expect(rows.map((r) => r.weightKg), [82, 83]);
  });

  test('previousValue finds the last measurement before a day', () async {
    await repo.setField(
      day: DateTime(2026, 7, 20),
      field: MeasurementField.waist,
      value: 86,
    );
    await repo.setField(
      day: yesterday,
      field: MeasurementField.weight,
      value: 83,
    );

    final rows = await allRows();

    // Skips yesterday's row, which has no waist value.
    final waist = previousValue(rows, MeasurementField.waist, today);
    expect(waist?.value, 86);
    expect(waist?.day, DateTime(2026, 7, 20));

    // Strictly before the given day — a value on the same day isn't "previous".
    expect(previousValue(rows, MeasurementField.weight, yesterday), isNull);
    expect(previousValue(rows, MeasurementField.hips, today), isNull);
  });

  // `parseDecimal` was removed when units arrived: it did exactly what
  // `parseWeight` does, and the measurement dialog now parses through the
  // unit-aware helper. Its behaviour is covered in units_test.dart.
}
