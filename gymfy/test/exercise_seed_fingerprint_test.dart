// The launch-time seed skips itself when the built-in library is unchanged.
//
// With ~1,270 built-in exercises the upsert costs real time before the first
// frame, so it only runs when the seed list differs from the one written last
// time — in practice, the first launch after an update.

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/exercises/data/exercise_repository.dart';
import 'package:gymfy/features/exercises/data/exercise_seed_data.dart';
import 'package:gymfy/shared/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() async => db.close());

  Future<String> benchName() async => (await (db.select(
    db.exercises,
  )..where((t) => t.id.equals('barbell_bench_press'))).getSingle()).name;

  Future<void> renameBench() =>
      (db.update(db.exercises)
            ..where((t) => t.id.equals('barbell_bench_press')))
          .write(const ExercisesCompanion(name: Value('Tampered')));

  test('the first launch writes the whole library and a fingerprint', () async {
    await ExerciseRepository(db).seed();

    expect(
      await db.select(db.exercises).get(),
      hasLength(exerciseSeedData.length),
    );
    final settings = await db.select(db.appSettings).get();
    expect(settings.map((s) => s.name), contains('exercise_seed_fingerprint'));
  });

  test('an unchanged library is not written again', () async {
    await ExerciseRepository(db).seed();
    await renameBench();

    await ExerciseRepository(db).seed();

    // Still tampered: the second seed saw the same fingerprint and skipped.
    expect(await benchName(), 'Tampered');
  });

  test('a different fingerprint writes the library again', () async {
    await ExerciseRepository(db).seed();
    await renameBench();
    // What an app update looks like from the database's side.
    await (db.update(db.appSettings)
          ..where((s) => s.name.equals('exercise_seed_fingerprint')))
        .write(const AppSettingsCompanion(value: Value('from-an-older-build')));

    await ExerciseRepository(db).seed();

    expect(await benchName(), 'Barbell Bench Press');
  });
}
