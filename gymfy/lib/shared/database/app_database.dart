import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/app_setting.dart';
import '../models/body_measurement.dart';
import '../models/calorie_entry.dart';
import '../models/exercise.dart';
import '../models/progress_photo.dart';
import '../models/rest_timer.dart';
import '../models/tested_one_rm.dart';
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
    WorkoutDaySchedules,
    WorkoutExercises,
    WorkoutSessions,
    LoggedSets,
    CalorieEntries,
    BodyMeasurements,
    ProgressPhotos,
    TestedOneRms,
    AppSettings,
    RestTimers,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Builds a database on a caller-provided executor. Used by tests to run
  /// against an in-memory SQLite instance (no device / file needed).
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 23;

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
      // v5 added the calorie and habit tables. The habit ones are no longer
      // created at all: v17 removed the feature, so a device coming from v4
      // would only be building two tables to drop them again twelve steps
      // later.
      if (from < 5) {
        await m.createTable(calorieEntries);
      }
      // v6 adds the body-measurements table.
      if (from < 6) {
        await m.createTable(bodyMeasurements);
      }
      // v7 adds the progress-photos table.
      if (from < 7) {
        await m.createTable(progressPhotos);
      }
      // v8 adds the manually tested one-rep maxes.
      if (from < 8) {
        await m.createTable(testedOneRms);
      }
      // v9 adds the key-value settings table.
      if (from < 9) {
        await m.createTable(appSettings);
      }
      // v10 adds per-exercise rest timer lengths.
      if (from < 10) {
        await m.createTable(restTimers);
      }
      // v11 adds user-created exercises. Both columns are additive with a
      // default of false, so every existing row keeps working untouched: the
      // whole seeded library reads as built-in and nothing is archived.
      if (from < 11) {
        await m.addColumn(exercises, exercises.isCustom);
        await m.addColumn(exercises, exercises.isArchived);
      }
      // v12 drops the push/pull/legs/core column. Exercises are described by
      // the muscles they train; a second, coarser grouping only invited
      // arguments about which bucket a lift belongs in.
      //
      // Raw SQL rather than drift's `alterTable`, deliberately: `alterTable`
      // rebuilds the table from the *current* Dart definition, so it copies
      // columns that later versions added and this one knows nothing about. A
      // device upgrading from v11 straight to v15 would rebuild the table
      // asking for `is_plate_loaded` before v15 had created it, and crash on
      // first launch. `DROP COLUMN` touches exactly the one column named here,
      // which is what a migration step should do.
      if (from < 12) {
        await customStatement('ALTER TABLE exercises DROP COLUMN category');
      }
      // v13 puts split days on weekdays. Nothing is scheduled to begin with, so
      // an upgrading device reads as "every day is a rest day" until the user
      // assigns some — the honest answer, since we can't guess their week.
      if (from < 13) {
        await m.createTable(workoutDaySchedules);
        await m.addColumn(splits, splits.isActive);
      }
      // v14 allows a rep *range* per planned exercise. The new column is
      // nullable and starts null, so every existing entry keeps its fixed
      // target and reads exactly as it did before.
      if (from < 14) {
        await m.addColumn(workoutExercises, workoutExercises.defaultRepsMax);
      }
      // v15 marks the barbell exercises so the log dialog can offer plate
      // stacking. The column defaults to false; the built-in library gets its
      // real values from the seed upsert on the very next launch, which runs
      // before any screen reads an exercise.
      if (from < 15) {
        await m.addColumn(exercises, exercises.isPlateLoaded);
      }
      // v16 adds progressive overload settings per planned exercise. All three
      // are off or unset to begin with, so nothing starts suggesting weights at
      // anyone without being switched on first.
      // v16 added the per-exercise overload settings. All raw SQL now, because
      // v19 and v20 removed these columns from the Dart schema — a device
      // coming from v15 still has to pass through the v16 that had them, and
      // `addColumn` can only add columns that still exist. They are dropped
      // again a few steps below.
      if (from < 16) {
        await customStatement(
          'ALTER TABLE workout_exercises '
          'ADD COLUMN overload_enabled INTEGER NOT NULL DEFAULT 0',
        );
        await customStatement(
          'ALTER TABLE workout_exercises ADD COLUMN overload_increment REAL',
        );
        await customStatement(
          'ALTER TABLE workout_exercises ADD COLUMN deload_after_weeks INTEGER',
        );
      }
      // v17 removes the habit tracker. The streak it existed for is now counted
      // from logged workouts instead, which is the thing this app is actually
      // about.
      //
      // This DELETES any habit history on the device — there is nowhere for it
      // to go, since nothing else in the app reads it. Entries go before habits
      // so the foreign key is never dangling, even mid-migration.
      if (from < 17) {
        await customStatement('DROP TABLE IF EXISTS habit_entries');
        await customStatement('DROP TABLE IF EXISTS habits');
      }
      // v18 allows a percentage increment instead of a fixed one. Nullable and
      // starting null, so every exercise keeps whatever it already had.
      if (from < 18) {
        await customStatement(
          'ALTER TABLE workout_exercises ADD COLUMN overload_percent REAL',
        );
      }
      // v19 moves "is overload on" from a per-exercise column to a single
      // app-wide setting. Nobody loses a preference: the column defaulted to
      // false and the setting defaults to on, so this switches suggestions on
      // rather than off — which is what the setting is for.
      if (from < 19) {
        await customStatement(
          'ALTER TABLE workout_exercises DROP COLUMN overload_enabled',
        );
      }
      // v20 finishes the move: the step size and the deload schedule are app
      // settings now too, so the last three per-exercise columns go. Nothing is
      // migrated across — the per-exercise values were only reachable through a
      // dialog that no longer exists, and the app-wide defaults are better
      // starting points than whatever one exercise happened to hold.
      if (from < 20) {
        for (final column in [
          'overload_increment',
          'overload_percent',
          'deload_after_weeks',
        ]) {
          await customStatement(
            'ALTER TABLE workout_exercises DROP COLUMN $column',
          );
        }
      }
      // v21 adds warm-up sets. Both columns are additive and default to
      // "nothing is a warm-up": every set already on the device stays a working
      // set, and no planned exercise suddenly grows ramp-up rows. That is the
      // safe direction — mistaking a working set for a warm-up would quietly
      // erase it from your progress charts.
      if (from < 21) {
        await m.addColumn(loggedSets, loggedSets.isWarmup);
        await m.addColumn(workoutExercises, workoutExercises.warmupSets);
      }
      // Per-exercise bar weight. Nullable and unset, so every existing row
      // keeps falling back to the gym-wide default for its unit — the
      // behaviour before this column existed.
      if (from < 22) {
        await m.addColumn(exercises, exercises.barWeightKg);
      }
      // v23 adds the user's own note per exercise. Nullable and unset, so
      // every existing row reads as "no note" — which is what it was.
      if (from < 23) {
        await m.addColumn(exercises, exercises.notes);
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
