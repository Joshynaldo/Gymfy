// User-created exercises: how they get an id, why the seed can't overwrite
// them, and the difference between deleting one that has history and one that
// doesn't.

// `show Value` only: drift's full export includes an `isNotNull` that would
// shadow the matcher of the same name.
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/exercises/data/exercise_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';
import 'package:gymfy/shared/models/muscle_ids.dart';

void main() {
  group('slugifyExerciseName', () {
    test('lowercases and joins words with underscores', () {
      expect(slugifyExerciseName('Cable Fly'), 'custom_cable_fly');
    });

    test('collapses punctuation rather than carrying it into the id', () {
      expect(slugifyExerciseName('Cable Fly (Low)'), 'custom_cable_fly_low');
    });

    test('apostrophes vanish instead of becoming a separator', () {
      // `farmer_s_walk` would be the naive result, and it reads as a typo.
      expect(slugifyExerciseName("Farmer's Walk"), 'custom_farmers_walk');
      // Phone keyboards insert the curly apostrophe, so it has to count too.
      expect(slugifyExerciseName('Farmer’s Walk'), 'custom_farmers_walk');
    });

    test('never leaves a leading or trailing underscore', () {
      expect(slugifyExerciseName('  Dips!  '), 'custom_dips');
    });

    test('a name with no usable characters still yields a valid id', () {
      // Otherwise the id would be a bare "custom_", and a second such exercise
      // would collide with the first.
      expect(slugifyExerciseName('!!!'), 'custom_exercise');
    });

    test('the prefix keeps custom ids out of the seed namespace', () {
      // This is what stops the startup upsert from overwriting a user's
      // exercise: no seed row can ever have this id.
      expect(
        slugifyExerciseName('Barbell Bench Press'),
        isNot('barbell_bench_press'),
      );
      expect(slugifyExerciseName('anything'), startsWith('custom_'));
    });
  });

  group('ExerciseRepository', () {
    late AppDatabase db;
    late ExerciseRepository repo;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = ExerciseRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    Future<String> createFly({String name = 'Cable Fly'}) {
      return repo.createCustom(
        name: name,
        isPlateLoaded: false,
        muscleIds: const [MuscleId.chest, MuscleId.frontDeltoid],
      );
    }

    /// Logs one set of [exerciseId], which is what makes it undeletable.
    Future<void> logASet(String exerciseId) async {
      final sessionId = await db
          .into(db.workoutSessions)
          .insert(WorkoutSessionsCompanion.insert(name: 'Push'));
      await db
          .into(db.loggedSets)
          .insert(
            LoggedSetsCompanion.insert(
              sessionId: sessionId,
              exerciseId: exerciseId,
              setNumber: 1,
              weight: const Value(60),
              reps: const Value(10),
            ),
          );
    }

    test('a created exercise is marked custom and is pickable', () async {
      final id = await createFly();

      final active = await repo.watchActiveExercises().first;
      expect(active.single.id, id);
      expect(active.single.name, 'Cable Fly');
      expect(active.single.isCustom, isTrue);
      expect(active.single.isArchived, isFalse);
      expect(active.single.muscleIds, [MuscleId.chest, MuscleId.frontDeltoid]);
    });

    test('the same name twice gets two distinct exercises', () async {
      // Two cable-fly machines in one gym is a real thing; refusing the second
      // would be worse than a suffixed id.
      final first = await createFly();
      final second = await createFly();

      expect(first, 'custom_cable_fly');
      expect(second, 'custom_cable_fly_2');
      expect(await repo.watchActiveExercises().first, hasLength(2));
    });

    test('seeding leaves custom exercises alone', () async {
      final id = await createFly();
      await repo.seed();

      final mine = await repo.watchExercise(id).first;
      expect(mine, isNotNull);
      expect(mine!.name, 'Cable Fly');
      expect(mine.isCustom, isTrue);
    });

    test('seeded exercises are not marked custom', () async {
      await repo.seed();

      final active = await repo.watchActiveExercises().first;
      expect(active, isNotEmpty);
      expect(active.every((e) => !e.isCustom), isTrue);
    });

    test('editing changes the name but keeps the id', () async {
      final id = await createFly();

      await repo.updateCustom(
        id: id,
        name: 'Low Cable Fly',
        isPlateLoaded: false,
        muscleIds: const [MuscleId.chest],
        imagePath: null,
      );

      // The id is referenced by every logged set, so a rename must not move it.
      final updated = await repo.watchExercise(id).first;
      expect(updated!.id, id);
      expect(updated.name, 'Low Cable Fly');
      expect(updated.muscleIds, [MuscleId.chest]);
    });

    test('deleting an unused exercise removes it outright', () async {
      final id = await createFly();

      final archived = await repo.deleteCustom(
        (await repo.watchExercise(id).first)!,
      );

      expect(archived, isFalse);
      expect(await repo.watchEveryExercise().first, isEmpty);
    });

    test('deleting a logged exercise archives it and keeps the set', () async {
      final id = await createFly();
      await logASet(id);

      final archived = await repo.deleteCustom(
        (await repo.watchExercise(id).first)!,
      );

      expect(archived, isTrue);
      // Gone from anywhere the user picks an exercise...
      expect(await repo.watchActiveExercises().first, isEmpty);
      // ...but the row survives, so history can still resolve its name.
      final every = await repo.watchEveryExercise().first;
      expect(every.single.name, 'Cable Fly');
      expect(every.single.isArchived, isTrue);
      // And the set it was part of is untouched.
      expect(await db.select(db.loggedSets).get(), hasLength(1));
    });

    test('an exercise planned into a split also archives', () async {
      final id = await createFly();
      final splitId = await db
          .into(db.splits)
          .insert(SplitsCompanion.insert(name: 'PPL'));
      final dayId = await db
          .into(db.workoutDays)
          .insert(
            WorkoutDaysCompanion.insert(
              splitId: splitId,
              name: 'Push',
              position: const Value(0),
            ),
          );
      await db
          .into(db.workoutExercises)
          .insert(
            WorkoutExercisesCompanion.insert(
              dayId: dayId,
              exerciseId: id,
              position: const Value(0),
            ),
          );

      // Planned-but-never-performed counts as history too: hard-deleting would
      // leave a split day pointing at a row that no longer exists.
      expect(await repo.hasHistory(id), isTrue);
      expect(
        await repo.deleteCustom((await repo.watchExercise(id).first)!),
        isTrue,
      );
    });
  });
}
