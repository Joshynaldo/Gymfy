// The v10 migration: an existing database gains the rest-timer table without
// losing what was already in it.
//
// Worth its own test because a migration is the one change that can destroy a
// user's data, and it only ever runs on devices that already have some.

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/shared/database/app_database.dart';
import 'package:gymfy/shared/models/exercise_category.dart';

void main() {
  test('the schema version matches the migration ladder', () {
    // A new table with no matching `if (from < N)` branch means upgrading
    // devices crash on first query while fresh installs work — the failure mode
    // that never shows up in development.
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    expect(db.schemaVersion, 10);
  });

  test('a fresh database has the rest-timer table', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    expect(await db.select(db.restTimers).get(), isEmpty);
  });

  test('upgrading from v9 keeps existing data and adds the table', () async {
    // A real file, because an in-memory database can't be closed and reopened —
    // and reopening is the whole point of a migration test.
    final dir = Directory.systemTemp.createTempSync('gymfy_migration');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/gymfy.sqlite');

    // Open once so drift creates the current schema, then wind it back to what
    // v9 looked like: no restTimers table, and user_version saying 9.
    final old = AppDatabase.forTesting(NativeDatabase(file));
    await old.select(old.exercises).get();

    // Something to lose, so the assertion below means something.
    await old.into(old.exercises).insert(
      ExercisesCompanion.insert(
        id: 'barbell_bench_press',
        name: 'Barbell Bench Press',
        category: ExerciseCategory.push,
        muscleIds: const ['chest'],
      ),
    );
    await old.customStatement(
      'DROP TABLE ${old.restTimers.actualTableName}',
    );
    await old.customStatement('PRAGMA user_version = 9');
    await old.close();

    // Reopening runs onUpgrade for 9 -> 10.
    final upgraded = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(upgraded.close);

    // The new table exists and is queryable...
    expect(await upgraded.select(upgraded.restTimers).get(), isEmpty);
    // ...and the row that was already there survived.
    final exercises = await upgraded.select(upgraded.exercises).get();
    expect(exercises.map((e) => e.id), contains('barbell_bench_press'));
  });

  test('a rest override is removed with the exercise it belongs to', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    // Cascades only fire with foreign keys switched on, which the real
    // connection does in beforeOpen.
    await db.customStatement('PRAGMA foreign_keys = ON');

    await db.into(db.exercises).insert(
      ExercisesCompanion.insert(
        id: 'barbell_bench_press',
        name: 'Barbell Bench Press',
        category: ExerciseCategory.push,
        muscleIds: const ['chest'],
      ),
    );
    await db.into(db.restTimers).insert(
      RestTimersCompanion.insert(exerciseId: 'barbell_bench_press', seconds: 90),
    );

    await db.delete(db.exercises).go();

    expect(await db.select(db.restTimers).get(), isEmpty);
  });
}
