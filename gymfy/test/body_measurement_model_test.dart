// Verifies the Phase 8 body-measurements table creates, persists partial rows,
// and enforces one row per day. In-memory database, no device.

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/shared/database/app_database.dart';
import 'package:gymfy/shared/models/body_measurement.dart';

void main() {
  late AppDatabase db;
  final day = DateTime(2026, 7, 25);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('a partial measurement persists, unmeasured parts stay null', () async {
    await db
        .into(db.bodyMeasurements)
        .insert(
          BodyMeasurementsCompanion.insert(
            date: day,
            weightKg: const Value(82.4),
            waistCm: const Value(84),
          ),
        );

    final row = (await db.select(db.bodyMeasurements).get()).single;
    expect(row.weightKg, 82.4);
    expect(row.waistCm, 84);
    // Not measured is null — never 0, which would plot as a crash to zero.
    expect(row.chestCm, isNull);
    expect(row.hipsCm, isNull);
    expect(row.armsCm, isNull);
    expect(row.legsCm, isNull);
  });

  test('only one row per day is allowed', () async {
    await db
        .into(db.bodyMeasurements)
        .insert(
          BodyMeasurementsCompanion.insert(
            date: day,
            weightKg: const Value(82),
          ),
        );

    expect(
      () => db
          .into(db.bodyMeasurements)
          .insert(
            BodyMeasurementsCompanion.insert(
              date: day,
              chestCm: const Value(102),
            ),
          ),
      throwsA(isA<Exception>()),
    );
  });

  test('updatedAt is stamped automatically', () async {
    final before = DateTime.now().subtract(const Duration(seconds: 2));
    await db
        .into(db.bodyMeasurements)
        .insert(BodyMeasurementsCompanion.insert(date: day));

    final row = (await db.select(db.bodyMeasurements).get()).single;
    expect(row.updatedAt.isAfter(before), isTrue);
  });

  test('every measurable body part has a label and a unit', () {
    expect(MeasurementField.values, hasLength(6));
    for (final field in MeasurementField.values) {
      expect(field.label, isNotEmpty);
      expect(field.unit, anyOf('kg', 'cm'));
    }
  });
}
