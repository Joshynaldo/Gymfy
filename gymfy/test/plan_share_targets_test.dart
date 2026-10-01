// Supersets and percentage-of-1RM targets in a shared plan file.
//
// Both were added to the format after it shipped, as optional keys. So the two
// directions matter equally: a new file carries them all the way into the
// database, and an old file without them still imports exactly as before.

import 'dart:convert';

import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/plan_share/data/plan_document.dart';
import 'package:gymfy/features/plan_share/data/plan_share_repository.dart';
import 'package:gymfy/features/workout/data/workout_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';

Map<String, dynamic> _exerciseJson(Map<String, dynamic> extra) => {
  'exerciseId': 'barbell_bench_press',
  'name': 'Barbell Bench Press',
  'muscleIds': ['chest'],
  'sets': 5,
  'reps': 5,
  ...extra,
};

String _fileWith(List<Map<String, dynamic>> exercises) => jsonEncode({
  'format': planFormatTag,
  'version': planFormatVersion,
  'splits': [
    {
      'name': 'Strength',
      'days': [
        {
          'name': 'Bench',
          'weekdays': [1],
          'exercises': exercises,
        },
      ],
    },
  ],
});

void main() {
  group('the file format', () {
    test('carries a superset group and a percentage through a round trip', () {
      const exercise = SharedExercise(
        exerciseId: 'barbell_bench_press',
        name: 'Barbell Bench Press',
        muscleIds: ['chest'],
        sets: 5,
        reps: 5,
        supersetGroup: 2,
        targetPercent: 72.5,
      );
      final document = PlanDocument(
        splits: [
          SharedSplit(
            name: 'Strength',
            days: [
              SharedDay(name: 'Bench', weekdays: [1], exercises: [exercise]),
            ],
          ),
        ],
      );

      final back = PlanDocument.decode(
        document.encode(),
      ).splits.single.days.single.exercises.single;
      expect(back.supersetGroup, 2);
      expect(back.targetPercent, 72.5);
    });

    test('leaves the keys out when there is nothing to say', () {
      // An older build reading the file never sees a key it doesn't know.
      const exercise = SharedExercise(
        exerciseId: 'barbell_bench_press',
        name: 'Barbell Bench Press',
        muscleIds: ['chest'],
        sets: 3,
        reps: 8,
      );
      final json = exercise.toJson();
      expect(json.containsKey('supersetGroup'), isFalse);
      expect(json.containsKey('targetPercent'), isFalse);
    });

    test('a file written before the keys existed reads as no targets', () {
      final exercise = PlanDocument.decode(
        _fileWith([_exerciseJson({})]),
      ).splits.single.days.single.exercises.single;
      expect(exercise.supersetGroup, isNull);
      expect(exercise.targetPercent, isNull);
    });

    test('a percentage no load could mean is dropped, not imported', () {
      final exercises = PlanDocument.decode(
        _fileWith([
          _exerciseJson({'targetPercent': 0}),
          _exerciseJson({'targetPercent': -10}),
          _exerciseJson({'targetPercent': 140}),
          _exerciseJson({'targetPercent': 'seventy'}),
          _exerciseJson({'targetPercent': 100}),
        ]),
      ).splits.single.days.single.exercises;
      expect(exercises.map((e) => e.targetPercent), [
        null,
        null,
        null,
        null,
        100,
      ]);
    });
  });

  group('the database', () {
    late AppDatabase db;
    late PlanShareRepository share;
    late WorkoutRepository workouts;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      share = PlanShareRepository(db);
      workouts = WorkoutRepository(db);
      for (final id in [
        'barbell_bench_press',
        'cable_fly',
        'triceps_pushdown',
      ]) {
        await db
            .into(db.exercises)
            .insert(
              ExercisesCompanion.insert(
                id: id,
                name: id,
                muscleIds: const ['chest'],
              ),
            );
      }
    });

    tearDown(() async => db.close());

    Future<List<WorkoutExercise>> plannedOf(int splitId) async {
      final day = await (db.select(
        db.workoutDays,
      )..where((t) => t.splitId.equals(splitId))).getSingle();
      return (db.select(db.workoutExercises)
            ..where((t) => t.dayId.equals(day.id))
            ..orderBy([
              (t) => OrderingTerm(expression: t.position),
              (t) => OrderingTerm(expression: t.id),
            ]))
          .get();
    }

    test('export writes the superset group and percentage', () async {
      final splitId = await workouts.createSplit('Strength');
      final dayId = await workouts.createDay(splitId, 'Bench');
      await workouts.addExercisesToDay(dayId, ['barbell_bench_press']);
      await db
          .update(db.workoutExercises)
          .write(
            const WorkoutExercisesCompanion(
              supersetGroup: Value(1),
              targetPercent: Value(80),
            ),
          );

      final exported = (await share.export([
        splitId,
      ])).splits.single.days.single.exercises.single;
      expect(exported.supersetGroup, 1);
      expect(exported.targetPercent, 80);
    });

    test('import writes them, and the file order as position', () async {
      final split = PlanDocument.decode(
        _fileWith([
          _exerciseJson({'targetPercent': 75}),
          _exerciseJson({'exerciseId': 'cable_fly', 'supersetGroup': 1}),
          _exerciseJson({'exerciseId': 'triceps_pushdown', 'supersetGroup': 1}),
        ]),
      ).splits.single;

      final splitId = await share.import(split, name: 'Strength');
      final planned = await plannedOf(splitId);

      expect(planned.map((p) => p.exerciseId), [
        'barbell_bench_press',
        'cable_fly',
        'triceps_pushdown',
      ]);
      expect(planned.map((p) => p.position), [0, 1, 2]);
      expect(planned.map((p) => p.targetPercent), [75, null, null]);
      expect(planned.map((p) => p.supersetGroup), [null, 1, 1]);
    });

    test('an old file imports with no targets at all', () async {
      final split = PlanDocument.decode(
        _fileWith([_exerciseJson({})]),
      ).splits.single;

      final planned = await plannedOf(
        await share.import(split, name: 'Strength'),
      );
      expect(planned.single.targetPercent, isNull);
      expect(planned.single.supersetGroup, isNull);
    });
  });
}
