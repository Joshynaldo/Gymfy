import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/calorie_entry.dart';
import '../models/exercise.dart';
import '../models/exercise_category.dart';
import '../models/habit.dart';
import '../models/workout_log.dart';
import '../models/workout_plan.dart';

part 'app_database.g.dart';

/// The app's single local SQLite database (via Drift).
///
/// Tables get added phase by phase. Whenever you add or change a table you
/// MUST bump [schemaVersion] and extend the [migration] below.
@DriftDatabase(
  tables: [
    Exercises,
    Splits,
    WorkoutDays,
    WorkoutExercises,
    WorkoutSessions,
    LoggedSets,
    CalorieEntries,
    Habits,
    HabitEntries,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Builds a database on a caller-provided executor. Used by tests to run
  /// against an in-memory SQLite instance (no device / file needed).
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    // Fresh install: create every table that currently exists.
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // v1 shipped an empty database; v2 adds the exercises table. This keeps
      // any device that already ran Phase 1 working without a reinstall.
      if (from < 2) {
        await m.createTable(exercises);
      }
      // v3 adds the workout-plan tables (splits, days, planned exercises).
      if (from < 3) {
        await m.createTable(splits);
        await m.createTable(workoutDays);
        await m.createTable(workoutExercises);
      }
      // v4 adds the workout-log tables (sessions and their logged sets).
      if (from < 4) {
        await m.createTable(workoutSessions);
        await m.createTable(loggedSets);
      }
      // v5 adds the calorie + habit tracking tables.
      if (from < 5) {
        await m.createTable(calorieEntries);
        await m.createTable(habits);
        await m.createTable(habitEntries);
      }
    },
    // SQLite doesn't enforce foreign keys unless we turn them on per
    // connection. We need them for the cascade deletes on the workout-plan
    // tables (deleting a split removes its days and their exercises).
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

/// Opens (and creates on first run) the on-device database file.
///
/// `drift_flutter` handles the platform details for us — the correct file
/// location and the bundled SQLite engine — so this stays a one-liner.
QueryExecutor _openConnection() {
  return driftDatabase(name: 'gymfy');
}

/// App-wide access to the database. Kept alive for the app's lifetime and
/// closed automatically when the provider is disposed.
///
/// Use it later with: `final db = ref.watch(appDatabaseProvider);`
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}
