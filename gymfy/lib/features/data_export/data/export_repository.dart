import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/database/app_database.dart';
import 'export_format.dart';

part 'export_repository.g.dart';

/// Reads everything you have logged, for the data export.
class ExportRepository {
  ExportRepository(this._db);

  final AppDatabase _db;

  /// Loads the whole log, oldest first.
  Future<ExportData> load() async {
    return ExportData(
      sets: await _sets(),
      measurements: await _measurements(),
      meals: await _meals(),
    );
  }

  /// Every logged set from a completed session, joined to its exercise.
  ///
  /// Only completed sessions, matching the streak and the recap: a workout you
  /// started and walked out of isn't training, and exporting it would put a
  /// half-finished row in a spreadsheet you're using to judge your progress.
  ///
  /// Warm-ups are included and flagged. This is your data, not an analysis —
  /// dropping rows would be the export deciding what you're allowed to see.
  Future<List<ExportSet>> _sets() async {
    final query = _db.select(_db.loggedSets).join([
      innerJoin(
        _db.workoutSessions,
        _db.workoutSessions.id.equalsExp(_db.loggedSets.sessionId) &
            _db.workoutSessions.completedAt.isNotNull(),
      ),
      innerJoin(
        _db.exercises,
        _db.exercises.id.equalsExp(_db.loggedSets.exerciseId),
      ),
    ]);
    query.orderBy([
      OrderingTerm(expression: _db.workoutSessions.completedAt),
      OrderingTerm(expression: _db.loggedSets.id),
    ]);

    return [
      for (final row in await query.get())
        () {
          final set = row.readTable(_db.loggedSets);
          final session = row.readTable(_db.workoutSessions);
          final exercise = row.readTable(_db.exercises);
          return (
            performedAt: session.completedAt ?? session.startedAt,
            sessionName: session.name,
            exerciseName: exercise.name,
            muscleIds: exercise.muscleIds,
            setNumber: set.setNumber,
            isWarmup: set.isWarmup,
            weightKg: set.weight,
            reps: set.reps,
          );
        }(),
    ];
  }

  Future<List<ExportMeasurement>> _measurements() async {
    final query = _db.select(_db.bodyMeasurements)
      ..orderBy([(t) => OrderingTerm(expression: t.date)]);

    return [
      for (final row in await query.get())
        (
          date: row.date,
          weightKg: row.weightKg,
          chestCm: row.chestCm,
          waistCm: row.waistCm,
          hipsCm: row.hipsCm,
          armsCm: row.armsCm,
          legsCm: row.legsCm,
        ),
    ];
  }

  Future<List<ExportMeal>> _meals() async {
    final query = _db.select(_db.calorieEntries)
      ..orderBy([(t) => OrderingTerm(expression: t.date)]);

    return [
      for (final row in await query.get())
        (
          date: row.date,
          name: row.name,
          calories: row.calories,
          protein: row.protein,
          carbs: row.carbs,
          fat: row.fat,
        ),
    ];
  }
}

/// App-wide access to the [ExportRepository].
@Riverpod(keepAlive: true)
ExportRepository exportRepository(Ref ref) {
  return ExportRepository(ref.watch(appDatabaseProvider));
}
