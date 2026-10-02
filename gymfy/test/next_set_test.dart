// "Which exercise am I on, and what do I log next?"
//
// The screen used to answer this for itself. The ongoing notification and
// the watch now ask the same question with the screen nowhere in sight, and
// a set logged from either is only right if the answer matches the card.

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/overload/data/overload_math.dart';
import 'package:gymfy/features/overload/data/overload_repository.dart';
import 'package:gymfy/features/workout/data/next_set.dart';
import 'package:gymfy/features/workout/data/session_repository.dart';
import 'package:gymfy/features/workout/data/workout_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';
import 'package:gymfy/shared/utils/units.dart';

Exercise _exercise(
  String id, {
  bool timed = false,
  String equipment = 'barbell',
}) => Exercise(
  id: id,
  name: id[0].toUpperCase() + id.substring(1),
  muscleIds: const ['chest'],
  isPlateLoaded: false,
  isCustom: false,
  isArchived: false,
  isTimed: timed,
  equipment: equipment,
);

SessionExerciseEntry _entry(
  Exercise exercise,
  int position, {
  int sets = 3,
  int reps = 8,
  bool planned = true,
}) => SessionExerciseEntry(
  row: SessionExercise(
    id: position + 1,
    sessionId: 1,
    exerciseId: exercise.id,
    position: position,
    workoutExerciseId: planned ? position + 100 : null,
  ),
  exercise: exercise,
  planned: planned
      ? WorkoutExercise(
          id: position + 100,
          dayId: 1,
          exerciseId: exercise.id,
          position: position,
          defaultSets: sets,
          defaultReps: reps,
          warmupSets: 0,
        )
      : null,
);

var _ids = 0;

LoggedSet _set(
  String exerciseId, {
  double weight = 80,
  int reps = 8,
  SetType type = SetType.normal,
  int? seconds,
}) => LoggedSet(
  id: ++_ids,
  sessionId: 1,
  exerciseId: exerciseId,
  setNumber: 1,
  weight: weight,
  reps: reps,
  seconds: seconds,
  setType: type.name,
);

void main() {
  final bench = _exercise('bench');
  final row = _exercise('row');
  final plank = _exercise('plank', timed: true, equipment: 'bodyweight');
  final pullup = _exercise('pullup', equipment: 'bodyweight');

  group('the exercise you are on', () {
    final entries = [_entry(bench, 0), _entry(row, 1)];

    test('is the first one short of its planned working sets', () {
      final sets = [for (var i = 0; i < 3; i++) _set('bench')];

      expect(currentSessionEntry(entries, sets)?.exercise.id, 'row');
    });

    test('ignores warm-ups when counting what is done', () {
      // Three warm-ups are not three sets of bench.
      final sets = [
        for (var i = 0; i < 3; i++) _set('bench', type: SetType.warmup),
      ];

      expect(currentSessionEntry(entries, sets)?.exercise.id, 'bench');
    });

    test('is your pick, when you made one', () {
      expect(
        currentSessionEntry(entries, const [], picked: 'row')?.exercise.id,
        'row',
      );
    });

    test('falls back to the plan when the pick has left the workout', () {
      expect(
        currentSessionEntry(entries, const [], picked: 'gone')?.exercise.id,
        'bench',
      );
    });

    test('stays on the last one once everything is done', () {
      final sets = [
        for (var i = 0; i < 3; i++) ...[_set('bench'), _set('row')],
      ];

      expect(currentSessionEntry(entries, sets)?.exercise.id, 'row');
    });

    test('is nothing in an empty workout', () {
      expect(currentSessionEntry(const [], const []), isNull);
    });
  });

  group('the next set', () {
    test('repeats the last working set of the exercise', () {
      final next = nextSetFor(_entry(bench, 0, sets: 4), [
        _set('bench', weight: 70, reps: 10),
        _set('bench', weight: 80, reps: 8),
      ]);

      expect(next.weightKg, 80);
      expect(next.reps, 8);
      expect(next.seconds, isNull);
      expect(next.setNumber, 3);
      expect(next.plannedSets, 4);
      expect(next.confident, isTrue);
    });

    test('never repeats a warm-up or a drop set', () {
      // From a pocket "the same again" means the set you are building
      // towards — not the empty bar, and not the stripped-down drop.
      final next = nextSetFor(_entry(bench, 0), [
        _set('bench', weight: 80),
        _set('bench', weight: 40, type: SetType.drop),
        _set('bench', weight: 20, type: SetType.warmup),
      ]);

      expect(next.weightKg, 80);
    });

    test('numbers drop and failure sets with the working ones', () {
      // The phase the screen numbers by: everything but warm-ups.
      final next = nextSetFor(_entry(bench, 0), [
        _set('bench', type: SetType.warmup),
        _set('bench'),
        _set('bench', type: SetType.failure),
        _set('bench', type: SetType.drop),
      ]);

      expect(next.setNumber, 4);
    });

    test('ignores other exercises', () {
      final next = nextSetFor(_entry(row, 1), [_set('bench', weight: 100)]);

      expect(next.setNumber, 1);
      expect(next.weightKg, isNot(100));
    });

    test('takes the overload suggestion before the first working set', () {
      final next = nextSetFor(
        _entry(bench, 0, reps: 6),
        [_set('bench', weight: 40, type: SetType.warmup)],
        suggestion: const OverloadSuggestion(
          weight: 82.5,
          reason: OverloadReason.earned,
        ),
      );

      expect(next.weightKg, 82.5);
      expect(next.reps, 6, reason: 'the plan\'s reps go with it');
      expect(next.confident, isTrue);
    });

    test('but what you lifted today beats it after that', () {
      final next = nextSetFor(
        _entry(bench, 0),
        [_set('bench', weight: 77.5)],
        suggestion: const OverloadSuggestion(
          weight: 82.5,
          reason: OverloadReason.earned,
        ),
      );

      expect(next.weightKg, 77.5);
    });

    test('is a guess, not a set to log blind, with nothing to go on', () {
      // "0 kg × 8" for a squat you have never done is a placeholder.
      final next = nextSetFor(_entry(bench, 0), const []);

      expect(next.weightKg, 0);
      expect(next.reps, 8);
      expect(next.confident, isFalse);
    });

    test('but zero is a real answer for a bodyweight movement', () {
      final next = nextSetFor(_entry(pullup, 0, reps: 10), const []);

      expect(next.weightKg, 0);
      expect(next.reps, 10);
      expect(next.confident, isTrue);
    });

    test('is the same hold again for a timed exercise', () {
      final next = nextSetFor(_entry(plank, 0), [
        _set('plank', weight: 0, reps: 0, seconds: 45),
      ]);

      expect(next.seconds, 45);
      expect(next.reps, 0, reason: 'a hold has no reps — one or the other');
      expect(next.confident, isTrue);
    });

    test('offers a placeholder hold only as a starting point', () {
      final next = nextSetFor(_entry(plank, 0), const []);

      expect(next.seconds, placeholderHoldSeconds);
      expect(next.confident, isFalse);
    });

    test('works to 3 × 10 for an exercise added mid-workout', () {
      final next = nextSetFor(_entry(pullup, 0, planned: false), const []);

      expect(next.plannedSets, addedExerciseSets);
      expect(next.reps, addedExerciseReps);
    });
  });

  group('in words', () {
    NextSet next({int number = 3, int planned = 4}) => (
      exerciseId: 'bench',
      exerciseName: 'Bench',
      setNumber: number,
      plannedSets: planned,
      weightKg: 80,
      reps: 8,
      seconds: null,
      confident: true,
    );

    test('says which set of how many', () {
      expect(describeSetPosition(next()), 'Set 3 of 4');
    });

    test('drops the "of" once you are past the plan', () {
      // "Set 5 of 4" reads like a bug.
      expect(describeSetPosition(next(number: 5)), 'Set 5');
    });

    test('spells out the numbers in the display unit', () {
      expect(describeNextNumbers(next(), WeightUnit.kg), '80 kg × 8 reps');
      expect(describeNextNumbers(next(), WeightUnit.lbs), contains('lbs'));
    });

    test('leaves the bar out when there is nothing on it', () {
      final bodyweight = (
        exerciseId: 'pullup',
        exerciseName: 'Pullup',
        setNumber: 1,
        plannedSets: 3,
        weightKg: 0.0,
        reps: 10,
        seconds: null,
        confident: true,
      );

      expect(describeNextNumbers(bodyweight, WeightUnit.kg), '10 reps');
    });

    test('reads a hold as a clock', () {
      final hold = (
        exerciseId: 'plank',
        exerciseName: 'Plank',
        setNumber: 1,
        plannedSets: 3,
        weightKg: 0.0,
        reps: 0,
        seconds: 90,
        confident: true,
      );

      expect(describeNextNumbers(hold, WeightUnit.kg), '1:30');
    });
  });

  group('the provider', () {
    late AppDatabase db;
    late ProviderContainer container;
    late int sessionId;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      for (final id in ['bench', 'row']) {
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
      final plans = WorkoutRepository(db);
      final dayId = await plans.createDay(await plans.createSplit('PPL'), 'A');
      await plans.addExercisesToDay(dayId, ['bench', 'row']);
      sessionId = await SessionRepository(
        db,
      ).startSession(dayId: dayId, name: 'A');

      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          overloadSuggestionProvider.overrideWith((ref, key) async => null),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    Future<NextSet?> read() async {
      final sub = container.listen(nextSetProvider(sessionId), (_, _) {});
      addTearDown(sub.close);
      return container.read(nextSetProvider(sessionId).future);
    }

    test('follows the plan', () async {
      expect((await read())?.exerciseId, 'bench');
    });

    test(
      'follows a pick made anywhere — the screen, the shade, the wrist',
      () async {
        final sub = container.listen(nextSetProvider(sessionId), (_, _) {});
        addTearDown(sub.close);
        await container.read(nextSetProvider(sessionId).future);

        container.read(pickedExerciseProvider(sessionId).notifier).pick('row');

        expect(
          (await container.read(nextSetProvider(sessionId).future))?.exerciseId,
          'row',
        );
      },
    );

    test('moves on as sets are logged', () async {
      final sub = container.listen(nextSetProvider(sessionId), (_, _) {});
      addTearDown(sub.close);
      await container.read(nextSetProvider(sessionId).future);

      await SessionRepository(db).logSet(
        sessionId: sessionId,
        exerciseId: 'bench',
        setNumber: 1,
        weight: 60,
        reps: 8,
      );
      // Let the stream deliver the new set.
      NextSet? next;
      for (var i = 0; i < 50; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        next = await container.read(nextSetProvider(sessionId).future);
        if (next?.setNumber == 2) break;
      }

      expect(next?.setNumber, 2);
      expect(next?.weightKg, 60);
    });
  });
}
