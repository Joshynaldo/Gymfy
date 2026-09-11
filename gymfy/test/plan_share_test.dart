// Sharing a plan: what goes in the file, what stays out of it, and what
// happens on the way back in.
//
// The privacy tests matter most. "It never includes your workouts or your
// measurements" is a promise printed on the screen, and the only thing keeping
// it true is that the exporter reads the plan tables and nothing else.

import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/plan_share/data/plan_document.dart';
import 'package:gymfy/features/plan_share/data/plan_pdf.dart';
import 'package:gymfy/features/plan_share/data/plan_share_repository.dart';
import 'package:gymfy/features/workout/data/session_repository.dart';
import 'package:gymfy/features/workout/data/workout_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';

void main() {
  group('the file format', () {
    final sample = PlanDocument(
      splits: [
        SharedSplit(
          name: 'Push / Pull / Legs',
          days: [
            SharedDay(
              name: 'Push',
              weekdays: const [1, 4],
              exercises: const [
                SharedExercise(
                  exerciseId: 'barbell_bench_press',
                  name: 'Barbell Bench Press',
                  muscleIds: ['chest', 'triceps'],
                  sets: 3,
                  reps: 8,
                  repsMax: 12,
                  warmupSets: 2,
                ),
              ],
            ),
          ],
        ),
      ],
      exportedAt: DateTime(2026, 8, 24, 18),
    );

    test('survives a round trip unchanged', () {
      final decoded = PlanDocument.decode(sample.encode());

      final split = decoded.splits.single;
      expect(split.name, 'Push / Pull / Legs');

      final day = split.days.single;
      expect(day.name, 'Push');
      expect(day.weekdays, [1, 4]);

      final exercise = day.exercises.single;
      expect(exercise.exerciseId, 'barbell_bench_press');
      expect(exercise.name, 'Barbell Bench Press');
      expect(exercise.muscleIds, ['chest', 'triceps']);
      expect(exercise.sets, 3);
      expect(exercise.reps, 8);
      expect(exercise.repsMax, 12);
      expect(exercise.warmupSets, 2);
    });

    test('is readable JSON, not an opaque blob', () {
      // A format you can open in a text editor is one you can still recover by
      // hand years after this app stops being installed.
      final json = jsonDecode(sample.encode()) as Map<String, dynamic>;

      expect(json['format'], planFormatTag);
      expect(json['version'], planFormatVersion);
    });

    test('a fixed rep target stays fixed, not a range of one', () {
      final document = PlanDocument(
        splits: [
          SharedSplit(
            name: 'A',
            days: [
              SharedDay(
                name: 'Day',
                weekdays: const [],
                exercises: const [
                  SharedExercise(
                    exerciseId: 'x',
                    name: 'X',
                    muscleIds: ['chest'],
                    sets: 3,
                    reps: 10,
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      final decoded = PlanDocument.decode(document.encode());
      expect(
        decoded.splits.single.days.single.exercises.single.repsMax,
        isNull,
      );
    });

    test('rejects a file that is not JSON at all', () {
      expect(
        () => PlanDocument.decode('not a plan'),
        throwsA(isA<PlanFormatException>()),
      );
    });

    test('rejects JSON that is not a plan', () {
      expect(
        () => PlanDocument.decode('{"hello": "world"}'),
        throwsA(
          isA<PlanFormatException>().having(
            (e) => e.message,
            'message',
            contains('.gymfy'),
          ),
        ),
      );
    });

    test('refuses a plan from a newer version rather than guessing', () {
      final future = jsonEncode({
        'format': planFormatTag,
        'version': planFormatVersion + 1,
        'splits': [
          {'name': 'A', 'days': []},
        ],
      });

      // A newer file may describe things this build has no column for, and a
      // half-imported plan is worse than none.
      expect(
        () => PlanDocument.decode(future),
        throwsA(
          isA<PlanFormatException>().having(
            (e) => e.message,
            'message',
            contains('newer version'),
          ),
        ),
      );
    });

    test('rejects a plan with no splits in it', () {
      final empty = jsonEncode({
        'format': planFormatTag,
        'version': planFormatVersion,
        'splits': <Object>[],
      });

      expect(
        () => PlanDocument.decode(empty),
        throwsA(isA<PlanFormatException>()),
      );
    });

    test('drops a weekday outside Monday–Sunday', () {
      final odd = jsonEncode({
        'format': planFormatTag,
        'version': planFormatVersion,
        'splits': [
          {
            'name': 'A',
            'days': [
              {
                'name': 'Day',
                'weekdays': [1, 9, 0, 7],
                'exercises': [],
              },
            ],
          },
        ],
      });

      // A weekday of 9 would be invisible in the UI but still hold the day's
      // slot, so the day would silently never appear.
      final decoded = PlanDocument.decode(odd);
      expect(decoded.splits.single.days.single.weekdays, [1, 7]);
    });

    test(
      'survives a missing optional field instead of refusing the import',
      () {
        final sparse = jsonEncode({
          'format': planFormatTag,
          'version': planFormatVersion,
          'splits': [
            {
              'name': 'A',
              'days': [
                {
                  'name': 'Day',
                  'exercises': [
                    {'exerciseId': 'x', 'name': 'X'},
                  ],
                },
              ],
            },
          ],
        });

        final exercise = PlanDocument.decode(
          sparse,
        ).splits.single.days.single.exercises.single;
        expect(exercise.sets, 3);
        expect(exercise.reps, 10);
        expect(exercise.warmupSets, 0);
      },
    );

    test('names the file after the plan', () {
      expect(planFileName(sample), 'push-pull-legs.gymfy');
    });

    test('falls back to a generic name for several plans', () {
      final many = PlanDocument(
        splits: [
          const SharedSplit(name: 'A', days: []),
          const SharedSplit(name: 'B', days: []),
        ],
      );

      expect(planFileName(many), 'gymfy-plans.gymfy');
    });
  });

  group('suggestFreeName', () {
    test('leaves a free name alone', () {
      expect(suggestFreeName('Push', {'Pull'}), 'Push');
    });

    test('numbers up past what is taken', () {
      expect(suggestFreeName('Push', {'Push'}), 'Push (2)');
      expect(suggestFreeName('Push', {'Push', 'Push (2)'}), 'Push (3)');
    });
  });

  group('export and import', () {
    late AppDatabase db;
    late PlanShareRepository share;
    late WorkoutRepository workout;
    late SessionRepository sessions;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      share = PlanShareRepository(db);
      workout = WorkoutRepository(db);
      sessions = SessionRepository(db);

      await db
          .into(db.exercises)
          .insert(
            ExercisesCompanion.insert(
              id: 'barbell_bench_press',
              name: 'Barbell Bench Press',
              muscleIds: const ['chest', 'triceps'],
            ),
          );
    });

    tearDown(() => db.close());

    /// A split with one scheduled day and one exercise on it.
    Future<int> seedSplit({String name = 'PPL'}) async {
      final splitId = await workout.createSplit(name);
      final dayId = await workout.createDay(splitId, 'Push');
      await workout.assignWeekday(dayId: dayId, weekday: 1);
      await workout.addExerciseToDay(dayId, 'barbell_bench_press');
      return splitId;
    }

    test('carries the split, its days, schedule and exercises', () async {
      final splitId = await seedSplit();

      final document = await share.export([splitId]);

      final split = document.splits.single;
      expect(split.name, 'PPL');
      final day = split.days.single;
      expect(day.name, 'Push');
      expect(day.weekdays, [1]);
      expect(day.exercises.single.exerciseId, 'barbell_bench_press');
    });

    test('the file mentions nothing about what you lifted', () async {
      final splitId = await seedSplit();
      final dayId = (await workout.watchDays(splitId).first).single.id;
      final sessionId = await sessions.startSession(dayId: dayId, name: 'Push');
      await sessions.logSet(
        sessionId: sessionId,
        exerciseId: 'barbell_bench_press',
        setNumber: 1,
        weight: 137.5,
        reps: 5,
      );
      await sessions.completeSession(sessionId);
      await db
          .into(db.bodyMeasurements)
          .insert(
            BodyMeasurementsCompanion.insert(
              date: DateTime(2026, 8, 24),
              weightKg: const Value(84.2),
            ),
          );

      final encoded = (await share.export([splitId])).encode();

      // Sending your programme to a stranger must not send them your body
      // weight or your best bench.
      expect(encoded, isNot(contains('137.5')));
      expect(encoded, isNot(contains('84.2')));
      expect(encoded.toLowerCase(), isNot(contains('bodyweight')));
    });

    test('exports in the order they were ticked', () async {
      final first = await seedSplit(name: 'Alpha');
      final second = await seedSplit(name: 'Beta');

      final document = await share.export([second, first]);

      expect(document.splits.map((s) => s.name), ['Beta', 'Alpha']);
    });

    test('a plan makes the round trip into a second library', () async {
      final splitId = await seedSplit();
      final document = PlanDocument.decode(
        (await share.export([splitId])).encode(),
      );

      // A second, empty library standing in for the recipient's phone.
      final theirDb = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(theirDb.close);
      final theirShare = PlanShareRepository(theirDb);
      final theirWorkout = WorkoutRepository(theirDb);

      await theirShare.import(document.splits.single, name: 'PPL');

      final splits = await theirWorkout.watchSplits().first;
      expect(splits.single.name, 'PPL');
      final days = await theirWorkout
          .watchScheduledDays(splits.single.id)
          .first;
      expect(days.single.day.name, 'Push');
      expect(days.single.weekdays, [1]);
      final planned = await theirWorkout
          .watchDayExercises(days.single.day.id)
          .first;
      expect(planned.single.exercise.name, 'Barbell Bench Press');
    });

    test('an imported plan is not active, so it cannot hijack today', () async {
      final splitId = await seedSplit();
      final document = await share.export([splitId]);

      final theirDb = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(theirDb.close);
      await PlanShareRepository(
        theirDb,
      ).import(document.splits.single, name: 'Theirs');
      // Their own first split, created afterwards, is the one that goes active.
      await WorkoutRepository(theirDb).createSplit('Mine');

      final splits = await WorkoutRepository(theirDb).watchSplits().first;
      expect(splits.firstWhere((s) => s.name == 'Theirs').isActive, isFalse);
    });

    test('importing never overwrites the plan you already had', () async {
      await seedSplit(name: 'PPL');
      final other = await seedSplit(name: 'Other');
      final document = await share.export([other]);

      // Same name as one already here, imported under a new one.
      await share.import(document.splits.single, name: 'PPL (2)');

      final splits = await workout.watchSplits().first;
      expect(splits.map((s) => s.name), containsAll(['PPL', 'PPL (2)']));
      expect(splits, hasLength(3));
    });

    test('a custom exercise the recipient lacks is recreated', () async {
      await db
          .into(db.exercises)
          .insert(
            ExercisesCompanion.insert(
              id: 'custom_zercher_carry',
              name: 'Zercher Carry',
              muscleIds: const ['core', 'quads'],
              isCustom: const Value(true),
            ),
          );
      final splitId = await workout.createSplit('Odd');
      final dayId = await workout.createDay(splitId, 'Day');
      await workout.addExerciseToDay(dayId, 'custom_zercher_carry');
      final document = await share.export([splitId]);

      final theirDb = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(theirDb.close);
      await PlanShareRepository(
        theirDb,
      ).import(document.splits.single, name: 'Odd');

      // Dropping it would lose exactly the exercises most worth sharing.
      final exercise = (await theirDb.select(theirDb.exercises).get()).single;
      expect(exercise.id, 'custom_zercher_carry');
      expect(exercise.name, 'Zercher Carry');
      expect(exercise.muscleIds, ['core', 'quads']);
      expect(exercise.isCustom, isTrue);
    });

    test('their exercise does not rename yours', () async {
      final splitId = await workout.createSplit('Theirs');
      final dayId = await workout.createDay(splitId, 'Day');
      await workout.addExerciseToDay(dayId, 'barbell_bench_press');
      final document = await share.export([splitId]);

      // The recipient calls the same slug something else.
      final theirDb = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(theirDb.close);
      await theirDb
          .into(theirDb.exercises)
          .insert(
            ExercisesCompanion.insert(
              id: 'barbell_bench_press',
              name: 'Bench (my name for it)',
              muscleIds: const ['chest'],
            ),
          );

      await PlanShareRepository(
        theirDb,
      ).import(document.splits.single, name: 'Theirs');

      final exercise = (await theirDb.select(theirDb.exercises).get()).single;
      expect(exercise.name, 'Bench (my name for it)');
    });

    test('an exercise with no id is skipped, not imported as a blank', () async {
      // The id is the only thing connecting a planned slot to a real lift.
      // Importing one without it used to create a nameless exercise that then
      // showed up in every picker forever.
      const broken = SharedSplit(
        name: 'Broken',
        days: [
          SharedDay(
            name: 'Day',
            weekdays: [1],
            exercises: [
              SharedExercise(
                exerciseId: '',
                name: '',
                muscleIds: [],
                sets: 3,
                reps: 10,
              ),
              SharedExercise(
                exerciseId: 'barbell_bench_press',
                name: 'Barbell Bench Press',
                muscleIds: ['chest'],
                sets: 3,
                reps: 10,
              ),
            ],
          ),
        ],
      );

      await share.import(broken, name: 'Broken');

      // The good half still arrives — one bad row shouldn't cost the whole day.
      final splitId = (await workout.watchSplits().first).single.id;
      final dayId = (await workout.watchDays(splitId).first).single.id;
      final planned = await workout.watchDayExercises(dayId).first;
      expect(planned.map((p) => p.exercise.id), ['barbell_bench_press']);
      expect(
        (await db.select(db.exercises).get()).map((e) => e.id),
        isNot(contains('')),
      );
    });

    test('a blank exercise is dropped when the file is read', () async {
      final source = jsonEncode({
        'format': planFormatTag,
        'version': planFormatVersion,
        'splits': [
          {
            'name': 'A',
            'days': [
              {
                'name': 'Day',
                'weekdays': <int>[],
                'exercises': [
                  {'exerciseId': '', 'name': 'Nameless'},
                  {'exerciseId': 'barbell_bench_press', 'name': 'Bench'},
                ],
              },
            ],
          },
        ],
      });

      final day = PlanDocument.decode(source).splits.single.days.single;
      expect(day.exercises.map((e) => e.exerciseId), ['barbell_bench_press']);
    });
  });

  group('the printable version', () {
    test('produces a real PDF', () async {
      final bytes = await buildPlanPdf(
        PlanDocument(
          splits: [
            SharedSplit(
              name: 'PPL',
              days: [
                SharedDay(
                  name: 'Push',
                  weekdays: const [1],
                  exercises: const [
                    SharedExercise(
                      exerciseId: 'barbell_bench_press',
                      name: 'Barbell Bench Press',
                      muscleIds: ['chest'],
                      sets: 3,
                      reps: 8,
                      repsMax: 12,
                    ),
                  ],
                ),
                // A day with nothing in it still has to render.
                const SharedDay(name: 'Rest?', weekdays: [], exercises: []),
              ],
            ),
          ],
        ),
      );

      // %PDF- is the magic number every reader looks for.
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(bytes.length, greaterThan(1000));
    });

    test('rep ranges use characters the built-in font can actually draw', () {
      // The PDF's Helvetica has no Unicode support, so the en dash in "8–12"
      // draws as nothing and the printed plan reads "8 12". Anything going into
      // the page has to survive that.
      expect(pdfSafeTarget(3, 8, 12), '3 × 8-12');
      expect(pdfSafeTarget(3, 10, null), '3 × 10');
    });
  });
}
