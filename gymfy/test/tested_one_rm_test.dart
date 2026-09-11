// Manually tested one-rep maxes: one row per exercise, a retest overwrites it,
// clearing falls back to the estimate, and deleting the exercise cleans up.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/calculator/data/tested_one_rm_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';

void main() {
  late AppDatabase db;
  late TestedOneRmRepository repository;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = TestedOneRmRepository(db);
    // The table references exercises, so a real row has to exist.
    await db
        .into(db.exercises)
        .insert(
          ExercisesCompanion.insert(
            id: 'barbell_bench_press',
            name: 'Barbell Bench Press',
            muscleIds: const ['chest'],
          ),
        );
  });

  tearDown(() => db.close());

  test('an untested exercise has no max', () async {
    expect(
      await repository.watchForExercise('barbell_bench_press').first,
      isNull,
    );
  });

  test(
    'a tested max is stored with its date, normalized to midnight',
    () async {
      await repository.setForExercise(
        exerciseId: 'barbell_bench_press',
        weightKg: 122.5,
        testedOn: DateTime(2026, 7, 20, 18, 42),
      );

      final row = await repository
          .watchForExercise('barbell_bench_press')
          .first;
      expect(row!.weightKg, 122.5);
      expect(row.testedOn, DateTime(2026, 7, 20));
    },
  );

  test('a retest overwrites rather than adding a second row', () async {
    await repository.setForExercise(
      exerciseId: 'barbell_bench_press',
      weightKg: 120,
      testedOn: DateTime(2026, 5, 1),
    );
    await repository.setForExercise(
      exerciseId: 'barbell_bench_press',
      weightKg: 127.5,
      testedOn: DateTime(2026, 7, 20),
    );

    final rows = await db.select(db.testedOneRms).get();
    expect(rows.length, 1);
    expect(rows.single.weightKg, 127.5);
    expect(rows.single.testedOn, DateTime(2026, 7, 20));
  });

  test('clearing removes it so the estimate takes over again', () async {
    await repository.setForExercise(
      exerciseId: 'barbell_bench_press',
      weightKg: 120,
      testedOn: DateTime(2026, 7, 20),
    );
    await repository.clearForExercise('barbell_bench_press');

    expect(
      await repository.watchForExercise('barbell_bench_press').first,
      isNull,
    );
  });

  test('deleting the exercise cascades to its tested max', () async {
    await repository.setForExercise(
      exerciseId: 'barbell_bench_press',
      weightKg: 120,
      testedOn: DateTime(2026, 7, 20),
    );

    await (db.delete(
      db.exercises,
    )..where((t) => t.id.equals('barbell_bench_press'))).go();

    expect(await db.select(db.testedOneRms).get(), isEmpty);
  });

  test('maxes are kept per exercise, not app-wide', () async {
    await db
        .into(db.exercises)
        .insert(
          ExercisesCompanion.insert(
            id: 'barbell_squat',
            name: 'Barbell Squat',
            muscleIds: const ['quads'],
          ),
        );
    await repository.setForExercise(
      exerciseId: 'barbell_bench_press',
      weightKg: 120,
      testedOn: DateTime(2026, 7, 20),
    );
    await repository.setForExercise(
      exerciseId: 'barbell_squat',
      weightKg: 180,
      testedOn: DateTime(2026, 7, 21),
    );

    final bench = await repository
        .watchForExercise('barbell_bench_press')
        .first;
    final squat = await repository.watchForExercise('barbell_squat').first;
    expect(bench!.weightKg, 120);
    expect(squat!.weightKg, 180);
  });
}
