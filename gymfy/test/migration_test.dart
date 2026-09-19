// The migrations: an existing database gains new tables and columns without
// losing what was already in it.
//
// Worth its own test because a migration is the one change that can destroy a
// user's data, and it only ever runs on devices that already have some.
//
// Each test opens a database at the current schema, winds it back to an older
// one, then reopens it so `onUpgrade` really runs. [rewindTo] does the winding
// back: every schema version has an entry undoing exactly what its `if (from <
// N)` branch does. Adding a migration means adding one entry there, and every
// older test keeps working — before this existed, each new version silently
// broke every rewind test written before it.

import 'dart:io';

// `show Value` only: drift's full export includes matchers-shaped names that
// would collide with the test package.
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/shared/database/app_database.dart';

/// Undoes what version N's migration branch added. Keyed by N, applied in
/// descending order by [rewindTo].
const _undoVersion = <int, List<String>>{
  25: ['ALTER TABLE exercises DROP COLUMN equipment'],
  24: [
    'ALTER TABLE exercises DROP COLUMN is_timed',
    'ALTER TABLE logged_sets DROP COLUMN seconds',
  ],
  23: ['ALTER TABLE exercises DROP COLUMN notes'],
  22: ['ALTER TABLE exercises DROP COLUMN bar_weight_kg'],
  21: [
    'ALTER TABLE logged_sets DROP COLUMN is_warmup',
    'ALTER TABLE workout_exercises DROP COLUMN warmup_sets',
  ],
  20: [
    'ALTER TABLE workout_exercises ADD COLUMN overload_increment REAL',
    'ALTER TABLE workout_exercises ADD COLUMN overload_percent REAL',
    'ALTER TABLE workout_exercises ADD COLUMN deload_after_weeks INTEGER',
  ],
  19: [
    'ALTER TABLE workout_exercises '
        'ADD COLUMN overload_enabled INTEGER NOT NULL DEFAULT 0',
  ],
  // v17 dropped the habit tables. Winding back recreates them — shaped as they
  // were, since nothing in Dart describes them any more.
  17: [
    'CREATE TABLE habits (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
        'name TEXT NOT NULL, position INTEGER NOT NULL DEFAULT 0, '
        "created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')))",
    'CREATE TABLE habit_entries (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
        'habit_id INTEGER NOT NULL REFERENCES habits (id) ON DELETE CASCADE, '
        'date INTEGER NOT NULL, UNIQUE (habit_id, date))',
  ],
  // v20 removed this column from the Dart schema, but v18 is the version that
  // created it — so winding back past v18 drops it again, after v20's undo has
  // put it back. Each entry undoes exactly its own version, no more.
  18: ['ALTER TABLE workout_exercises DROP COLUMN overload_percent'],
  16: [
    // Same story one version down: v19 removed this one, v16 created it.
    'ALTER TABLE workout_exercises DROP COLUMN overload_enabled',
    'ALTER TABLE workout_exercises DROP COLUMN overload_increment',
    'ALTER TABLE workout_exercises DROP COLUMN deload_after_weeks',
  ],
  15: ['ALTER TABLE exercises DROP COLUMN is_plate_loaded'],
  14: ['ALTER TABLE workout_exercises DROP COLUMN default_reps_max'],
  13: [
    'DROP TABLE workout_day_schedules',
    'ALTER TABLE splits DROP COLUMN is_active',
  ],
  12: [
    // v12 *dropped* a column, so winding back means putting it back.
    "ALTER TABLE exercises ADD COLUMN category TEXT NOT NULL DEFAULT 'push'",
  ],
  11: [
    'ALTER TABLE exercises DROP COLUMN is_custom',
    'ALTER TABLE exercises DROP COLUMN is_archived',
  ],
  10: ['DROP TABLE rest_timers'],
};

/// Turns an open database back into what it looked like at [version].
Future<void> rewindTo(AppDatabase db, int version) async {
  // Newest first: v12's undo re-adds a column that v11's undo doesn't know
  // about, and doing them out of order would leave the schema inconsistent.
  final versions = _undoVersion.keys.where((v) => v > version).toList()
    ..sort((a, b) => b.compareTo(a));
  for (final v in versions) {
    for (final statement in _undoVersion[v]!) {
      await db.customStatement(statement);
    }
  }
  await db.customStatement('PRAGMA user_version = $version');
}

/// A database file that survives being closed and reopened — an in-memory one
/// can't, and reopening is the whole point of a migration test.
File _tempDatabase(String name) {
  final dir = Directory.systemTemp.createTempSync('gymfy_$name');
  addTearDown(() => dir.deleteSync(recursive: true));
  return File('${dir.path}/gymfy.sqlite');
}

void main() {
  test('the schema version matches the migration ladder', () {
    // A new table with no matching `if (from < N)` branch means upgrading
    // devices crash on first query while fresh installs work — the failure mode
    // that never shows up in development.
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    expect(db.schemaVersion, 25);
  });

  test('every version above the oldest test target can be wound back', () {
    // Guards the helper itself: a new migration with no undo entry would make
    // every rewind test below fail with a confusing SQL error instead of this.
    for (var v = 10; v <= 25; v++) {
      expect(_undoVersion.keys, contains(v), reason: 'no undo for v$v');
    }
  });

  test('a fresh database has every current table', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    expect(await db.select(db.restTimers).get(), isEmpty);
    expect(await db.select(db.workoutDaySchedules).get(), isEmpty);
  });

  test('upgrading from v9 adds the rest-timer table and keeps data', () async {
    final file = _tempDatabase('v9');

    final old = AppDatabase.forTesting(NativeDatabase(file));
    // Something to lose, so the assertion below means something.
    await old
        .into(old.exercises)
        .insert(
          ExercisesCompanion.insert(
            id: 'barbell_bench_press',
            name: 'Barbell Bench Press',
            muscleIds: const ['chest'],
          ),
        );
    await rewindTo(old, 9);
    await old.close();

    final upgraded = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(upgraded.close);

    expect(await upgraded.select(upgraded.restTimers).get(), isEmpty);
    final exercises = await upgraded.select(upgraded.exercises).get();
    expect(exercises.map((e) => e.id), contains('barbell_bench_press'));
  });

  test('upgrading from v10 marks existing exercises as built-in', () async {
    final file = _tempDatabase('v10');

    final old = AppDatabase.forTesting(NativeDatabase(file));
    await old
        .into(old.exercises)
        .insert(
          ExercisesCompanion.insert(
            id: 'barbell_bench_press',
            name: 'Barbell Bench Press',
            muscleIds: const ['chest'],
          ),
        );
    await rewindTo(old, 10);
    await old.close();

    final upgraded = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(upgraded.close);

    // The whole existing library must read as built-in and un-archived —
    // anything else would hide a user's exercises or offer to delete rows the
    // seed will just put back.
    final row = (await upgraded.select(upgraded.exercises).get()).single;
    expect(row.id, 'barbell_bench_press');
    expect(row.isCustom, isFalse);
    expect(row.isArchived, isFalse);
  });

  test(
    'upgrading from v11 drops the category column and keeps the rest',
    () async {
      final file = _tempDatabase('v11');

      final old = AppDatabase.forTesting(NativeDatabase(file));
      await old
          .into(old.exercises)
          .insert(
            ExercisesCompanion.insert(
              id: 'custom_cable_fly',
              name: 'Cable Fly',
              muscleIds: const ['chest'],
              isCustom: const Value(true),
            ),
          );
      await rewindTo(old, 11);
      await old.close();

      final upgraded = AppDatabase.forTesting(NativeDatabase(file));
      addTearDown(upgraded.close);

      // Dropping a column in SQLite means rebuilding the table, so this is really
      // asking: did every other value survive the rebuild?
      final row = (await upgraded.select(upgraded.exercises).get()).single;
      expect(row.id, 'custom_cable_fly');
      expect(row.name, 'Cable Fly');
      expect(row.muscleIds, const ['chest']);
      expect(row.isCustom, isTrue);

      // And the column itself is really gone, not just hidden from Dart.
      final columns = await upgraded
          .customSelect('PRAGMA table_info(exercises)')
          .get();
      expect(columns.map((c) => c.data['name']), isNot(contains('category')));
    },
  );

  test('upgrading from v12 keeps splits, unscheduled', () async {
    final file = _tempDatabase('v12');

    final old = AppDatabase.forTesting(NativeDatabase(file));
    final splitId = await old
        .into(old.splits)
        .insert(SplitsCompanion.insert(name: 'PPL'));
    await old
        .into(old.workoutDays)
        .insert(WorkoutDaysCompanion.insert(splitId: splitId, name: 'Push'));
    await rewindTo(old, 12);
    await old.close();

    final upgraded = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(upgraded.close);

    // Every weekday reads as a rest day until the user assigns some. We can't
    // guess anyone's week, and inventing a schedule would be worse than a blank
    // one they notice and fill in.
    expect(await upgraded.select(upgraded.workoutDaySchedules).get(), isEmpty);
    final split = (await upgraded.select(upgraded.splits).get()).single;
    expect(split.name, 'PPL');
    expect(split.isActive, isFalse);
    expect(await upgraded.select(upgraded.workoutDays).get(), hasLength(1));
  });

  test('upgrading from v13 leaves rep targets fixed, not ranges', () async {
    final file = _tempDatabase('v13');

    final old = AppDatabase.forTesting(NativeDatabase(file));
    final splitId = await old
        .into(old.splits)
        .insert(SplitsCompanion.insert(name: 'PPL'));
    final dayId = await old
        .into(old.workoutDays)
        .insert(WorkoutDaysCompanion.insert(splitId: splitId, name: 'Push'));
    await old
        .into(old.exercises)
        .insert(
          ExercisesCompanion.insert(
            id: 'barbell_bench_press',
            name: 'Barbell Bench Press',
            muscleIds: const ['chest'],
          ),
        );
    await old
        .into(old.workoutExercises)
        .insert(
          WorkoutExercisesCompanion.insert(
            dayId: dayId,
            exerciseId: 'barbell_bench_press',
            defaultReps: const Value(8),
          ),
        );
    await rewindTo(old, 13);
    await old.close();

    final upgraded = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(upgraded.close);

    // Null, not 8: an existing "3 × 8" must keep reading as "8" rather than
    // turning into the degenerate range "8–8".
    final entry =
        (await upgraded.select(upgraded.workoutExercises).get()).single;
    expect(entry.defaultReps, 8);
    expect(entry.defaultRepsMax, isNull);
  });

  test('upgrading from v16 removes the habit tables', () async {
    final file = _tempDatabase('v16');

    final old = AppDatabase.forTesting(NativeDatabase(file));
    await rewindTo(old, 16);
    await old.customStatement(
      "INSERT INTO habits (name) VALUES ('Drink water')",
    );
    await old
        .into(old.calorieEntries)
        .insert(
          CalorieEntriesCompanion.insert(
            date: DateTime(2026, 7, 24),
            name: 'Chicken & rice',
            calories: const Value(650),
          ),
        );
    await old.close();

    final upgraded = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(upgraded.close);

    // The tables are gone, and so is any habit data on the device — there was
    // nowhere for it to go, since nothing else reads it.
    final tables = await upgraded
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
        .get();
    final names = tables.map((t) => t.data['name']).toSet();
    expect(names, isNot(contains('habits')));
    expect(names, isNot(contains('habit_entries')));

    // The calorie log, which shared that phase, is untouched.
    expect(await upgraded.select(upgraded.calorieEntries).get(), hasLength(1));
  });

  test('upgrading from v20 keeps every existing set a working set', () async {
    final file = _tempDatabase('v20');

    final old = AppDatabase.forTesting(NativeDatabase(file));
    await old
        .into(old.exercises)
        .insert(
          ExercisesCompanion.insert(
            id: 'barbell_bench_press',
            name: 'Barbell Bench Press',
            muscleIds: const ['chest'],
          ),
        );
    final sessionId = await old
        .into(old.workoutSessions)
        .insert(WorkoutSessionsCompanion.insert(name: 'Push'));
    await old
        .into(old.loggedSets)
        .insert(
          LoggedSetsCompanion.insert(
            sessionId: sessionId,
            exerciseId: 'barbell_bench_press',
            setNumber: 1,
            weight: const Value(100),
            reps: const Value(5),
          ),
        );
    final splitId = await old
        .into(old.splits)
        .insert(SplitsCompanion.insert(name: 'PPL'));
    final dayId = await old
        .into(old.workoutDays)
        .insert(WorkoutDaysCompanion.insert(splitId: splitId, name: 'Push'));
    await old
        .into(old.workoutExercises)
        .insert(
          WorkoutExercisesCompanion.insert(
            dayId: dayId,
            exerciseId: 'barbell_bench_press',
          ),
        );
    await rewindTo(old, 20);
    await old.close();

    final upgraded = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(upgraded.close);

    // The safe direction. Guessing that an old 100 kg × 5 was a warm-up would
    // silently delete it from the user's bench chart and their PR history.
    final set = (await upgraded.select(upgraded.loggedSets).get()).single;
    expect(set.weight, 100);
    expect(set.reps, 5);
    expect(set.isWarmup, isFalse);

    // And no planned exercise suddenly grows ramp-up rows it never had.
    final planned =
        (await upgraded.select(upgraded.workoutExercises).get()).single;
    expect(planned.warmupSets, 0);
  });

  test('upgrading from v22 leaves every exercise without a note', () async {
    // The safe and only honest direction: the app cannot invent a note, and
    // "" would be worse than null — the UI draws its empty state from exactly
    // that distinction, so a blank string would render a note heading over
    // nothing.
    final file = _tempDatabase('v22');

    final old = AppDatabase.forTesting(NativeDatabase(file));
    await old
        .into(old.exercises)
        .insert(
          ExercisesCompanion.insert(
            id: 'leg_press',
            name: 'Leg Press',
            muscleIds: const ['quads'],
          ),
        );
    await rewindTo(old, 22);
    await old.close();

    final upgraded = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(upgraded.close);

    final exercise = (await upgraded.select(upgraded.exercises).get()).single;
    expect(exercise.notes, isNull);
    // And the row it was added to is otherwise untouched.
    expect(exercise.name, 'Leg Press');
    expect(exercise.muscleIds, ['quads']);
  });

  test('upgrading from v23 leaves everything counted in reps', () async {
    // The safe direction. Marking an existing exercise as timed would make
    // the log sheet ask for a duration for a lift the user counts in reps,
    // and a logged set that grew a duration would start rendering as a hold.
    final file = _tempDatabase('v23');

    final old = AppDatabase.forTesting(NativeDatabase(file));
    await old
        .into(old.exercises)
        .insert(
          ExercisesCompanion.insert(
            id: 'plank',
            name: 'Plank',
            muscleIds: const ['abs'],
          ),
        );
    final sessionId = await old
        .into(old.workoutSessions)
        .insert(WorkoutSessionsCompanion.insert(name: 'Core'));
    await old
        .into(old.loggedSets)
        .insert(
          LoggedSetsCompanion.insert(
            sessionId: sessionId,
            exerciseId: 'plank',
            setNumber: 1,
            reps: const Value(12),
          ),
        );
    await rewindTo(old, 23);
    await old.close();

    final upgraded = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(upgraded.close);

    // Even the plank: the seed upsert is what will mark it timed on the next
    // launch, and the migration itself must not guess.
    final exercise = (await upgraded.select(upgraded.exercises).get()).single;
    expect(exercise.isTimed, isFalse);

    final set = (await upgraded.select(upgraded.loggedSets).get()).single;
    expect(set.seconds, isNull);
    expect(set.reps, 12);
  });

  test('a rest override is removed with the exercise it belongs to', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    // Cascades only fire with foreign keys switched on, which the real
    // connection does in beforeOpen.
    await db.customStatement('PRAGMA foreign_keys = ON');

    await db
        .into(db.exercises)
        .insert(
          ExercisesCompanion.insert(
            id: 'barbell_bench_press',
            name: 'Barbell Bench Press',
            muscleIds: const ['chest'],
          ),
        );
    await db
        .into(db.restTimers)
        .insert(
          RestTimersCompanion.insert(
            exerciseId: 'barbell_bench_press',
            seconds: 90,
          ),
        );

    await db.delete(db.exercises).go();

    expect(await db.select(db.restTimers).get(), isEmpty);
  });
}
