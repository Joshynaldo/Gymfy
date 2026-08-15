import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/database/app_database.dart';
import '../../../shared/models/body_measurement.dart';
import '../../../shared/utils/dates.dart';

part 'measurements_repository.g.dart';

/// Reads one measurement off a row. Paired with [companionFor] so the UI can
/// work with a [MeasurementField] instead of naming columns.
double? valueOf(BodyMeasurement row, MeasurementField field) {
  return switch (field) {
    MeasurementField.weight => row.weightKg,
    MeasurementField.chest => row.chestCm,
    MeasurementField.waist => row.waistCm,
    MeasurementField.hips => row.hipsCm,
    MeasurementField.arms => row.armsCm,
    MeasurementField.legs => row.legsCm,
  };
}

/// Builds a companion that writes just [field], leaving every other column
/// alone. `Value(null)` is an explicit "clear this", not "skip this".
BodyMeasurementsCompanion companionFor(MeasurementField field, double? value) {
  final v = Value(value);
  return switch (field) {
    MeasurementField.weight => BodyMeasurementsCompanion(weightKg: v),
    MeasurementField.chest => BodyMeasurementsCompanion(chestCm: v),
    MeasurementField.waist => BodyMeasurementsCompanion(waistCm: v),
    MeasurementField.hips => BodyMeasurementsCompanion(hipsCm: v),
    MeasurementField.arms => BodyMeasurementsCompanion(armsCm: v),
    MeasurementField.legs => BodyMeasurementsCompanion(legsCm: v),
  };
}

/// True when a row carries no measurements at all any more.
bool isEmptyRow(BodyMeasurement row) {
  return MeasurementField.values.every((f) => valueOf(row, f) == null);
}

/// The most recent value for [field] strictly before [day], with the day it was
/// measured — shown as a reference while entering today's numbers.
///
/// [rows] must be newest-first, as [MeasurementsRepository.watchAll] returns.
({double value, DateTime day})? previousValue(
  List<BodyMeasurement> rows,
  MeasurementField field,
  DateTime day,
) {
  final target = dateOnly(day);
  for (final row in rows) {
    if (!dateOnly(row.date).isBefore(target)) continue;
    final value = valueOf(row, field);
    if (value != null) return (value: value, day: row.date);
  }
  return null;
}

/// One plotted measurement.
typedef MeasurementPoint = ({DateTime day, double value});

/// Pulls the timeline for a single [field] out of the history, oldest first.
///
/// Days where that part wasn't measured are skipped entirely rather than
/// interpolated or zeroed — the chart connects the days you actually measured,
/// and the gaps between them stay visible on the date axis.
///
/// [rows] is newest-first, as [MeasurementsRepository.watchAll] returns.
List<MeasurementPoint> seriesFor(
  List<BodyMeasurement> rows,
  MeasurementField field,
) {
  final points = <MeasurementPoint>[];
  for (final row in rows.reversed) {
    final value = valueOf(row, field);
    if (value != null) points.add((day: dateOnly(row.date), value: value));
  }
  return points;
}

/// Database access for body measurements.
class MeasurementsRepository {
  MeasurementsRepository(this._db);

  final AppDatabase _db;

  /// Streams every measurement row, newest day first. The whole history is a
  /// row per day at most — small enough to hold in memory, and the progress
  /// charts need all of it anyway.
  Stream<List<BodyMeasurement>> watchAll() {
    final query = _db.select(_db.bodyMeasurements)
      ..orderBy([
        (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
      ]);
    return query.watch();
  }

  /// Writes a single [field] on [day], creating that day's row if needed and
  /// leaving the other measurements untouched. Pass a null [value] to clear it.
  ///
  /// Every write re-stamps `updatedAt`, which is the auto-timestamp the screen
  /// shows.
  Future<void> setField({
    required DateTime day,
    required MeasurementField field,
    required double? value,
  }) async {
    final d = dateOnly(day);
    final patch = companionFor(field, value).copyWith(
      updatedAt: Value(DateTime.now()),
    );

    // The unique key is `date`, not the primary key, so the conflict target has
    // to say so explicitly — otherwise this would try to upsert on `id`.
    await _db.into(_db.bodyMeasurements).insert(
      patch.copyWith(date: Value(d)),
      onConflict: DoUpdate(
        (_) => patch,
        target: [_db.bodyMeasurements.date],
      ),
    );

    // Clearing the last value on a day leaves an all-null row behind, which
    // would show up as a phantom entry in the history. Drop it.
    final row = await (_db.select(_db.bodyMeasurements)
          ..where((t) => t.date.equals(d)))
        .getSingleOrNull();
    if (row != null && isEmptyRow(row)) {
      await (_db.delete(_db.bodyMeasurements)..where((t) => t.date.equals(d)))
          .go();
    }
  }
}

/// App-wide access to the [MeasurementsRepository].
@Riverpod(keepAlive: true)
MeasurementsRepository measurementsRepository(Ref ref) {
  return MeasurementsRepository(ref.watch(appDatabaseProvider));
}

/// The live measurement history, newest day first.
final measurementHistoryProvider = StreamProvider<List<BodyMeasurement>>((ref) {
  return ref.watch(measurementsRepositoryProvider).watchAll();
});

/// The most recent logged bodyweight and the day it was measured, or null if
/// the user has never recorded one.
///
/// Derived from [measurementHistoryProvider] rather than its own query — the
/// measurement rows are already in memory, and one source keeps the weight
/// shown on the measurements screen and the weight used for strength ranks
/// from ever disagreeing.
final latestBodyweightProvider = Provider<MeasurementPoint?>((ref) {
  final history = ref.watch(measurementHistoryProvider).value;
  if (history == null) return null;
  // Newest first, and weight is nullable — the first row that has one wins.
  for (final row in history) {
    final weight = valueOf(row, MeasurementField.weight);
    if (weight != null) return (day: row.date, value: weight);
  }
  return null;
});
