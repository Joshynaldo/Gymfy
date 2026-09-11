// Warm-up sets: what they stay out of, what they still count toward, and how
// the two phases are numbered.
//
// The whole feature is a filter, so the tests that matter are the ones that
// prove the filter is applied in some places and *not* in others. A warm-up
// leaking into your PR history is a silent lie about how strong you are; a
// warm-up vanishing from your session volume is a silent lie about how much
// work you did.

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/overload/data/overload_math.dart';
import 'package:gymfy/features/overload/data/overload_repository.dart';
import 'package:gymfy/features/progress/data/progress_repository.dart';
import 'package:gymfy/features/workout/data/session_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';

void main() {
  late AppDatabase db;
  late SessionRepository sessions;
  late ProgressRepository progress;
  late OverloadRepository overload;

  /// A real day to hang sessions off — sessions carry a foreign key to one.
  late int dayId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    sessions = SessionRepository(db);
    progress = ProgressRepository(db);
    overload = OverloadRepository(db);
    await db
        .into(db.exercises)
        .insert(
          ExercisesCompanion.insert(
            id: 'barbell_bench_press',
            name: 'Barbell Bench Press',
            muscleIds: const ['chest'],
          ),
        );
    final splitId = await db
        .into(db.splits)
        .insert(SplitsCompanion.insert(name: 'PPL'));
    dayId = await db
        .into(db.workoutDays)
        .insert(WorkoutDaysCompanion.insert(splitId: splitId, name: 'Push'));
  });

  tearDown(() async {
    await db.close();
  });

  /// Starts a session and logs a ramp-up to [top], then working sets at it.
  Future<int> benchSession({
    required List<double> warmups,
    required List<double> working,
    int reps = 5,
    bool complete = true,
  }) async {
    final id = await sessions.startSession(dayId: dayId, name: 'Push');
    var n = 0;
    for (final weight in warmups) {
      await sessions.logSet(
        sessionId: id,
        exerciseId: 'barbell_bench_press',
        setNumber: ++n,
        weight: weight,
        reps: reps,
        isWarmup: true,
      );
    }
    n = 0;
    for (final weight in working) {
      await sessions.logSet(
        sessionId: id,
        exerciseId: 'barbell_bench_press',
        setNumber: ++n,
        weight: weight,
        reps: reps,
      );
    }
    if (complete) await sessions.completeSession(id);
    return id;
  }

  group('what warm-ups stay out of', () {
    test('the progress chart plots working sets only', () async {
      await benchSession(warmups: [40, 60, 80], working: [100, 100, 100]);

      final points = await progress
          .watchExerciseHistory('barbell_bench_press')
          .first;

      final point = points.single;
      expect(point.topWeight, 100);
      // 3 × 100 × 5, not 6 sets — the ramp-up is not part of the working
      // volume the chart compares day to day.
      expect(point.totalVolume, 1500);
    });

    test('a warm-up can never become a personal record', () async {
      // A deliberately silly ramp-up: heavier than anything worked with. If the
      // filter were missing, this would show as the best bench of all time.
      await benchSession(warmups: [200], working: [100]);

      final points = await progress
          .watchExerciseHistory('barbell_bench_press')
          .first;
      final records = personalRecordsFrom(points);

      expect(records, isNotNull);
      expect(records!.heaviestWeight, 100);
    });

    test('the estimated 1RM ignores the ramp-up', () async {
      await benchSession(warmups: [200], working: [100]);

      final points = await progress
          .watchExerciseHistory('barbell_bench_press')
          .first;
      final best = bestEstimatedOneRm(points);

      expect(best, isNotNull);
      expect(best!.weight, 100);
    });

    test('overload sees only the working sets of each session', () async {
      await benchSession(warmups: [40, 60], working: [100, 100, 100]);

      final recent = await overload.recentSessions('barbell_bench_press');

      expect(recent.single, hasLength(3));
      expect(recent.single.every((s) => s.weight == 100), isTrue);
    });

    test('a light ramp-up cannot drag the suggested weight down', () async {
      // The failure this guards: `topWeight` over all six sets is still 100, but
      // a session whose *first* set is 40 kg would break the "did every planned
      // set hit the range?" walk and could suggest a decrease.
      await benchSession(warmups: [40, 60, 80], working: [100, 100, 100]);

      final recent = await overload.recentSessions('barbell_bench_press');

      expect(topWeight(recent.single), 100);
    });

    test('an exercise with only warm-ups is not offered a chart', () async {
      await benchSession(warmups: [40, 60], working: const []);

      final charted = await progress.watchExercisesWithHistory().first;

      // An empty chart is a worse answer than no chart.
      expect(charted, isEmpty);
    });
  });

  group('what warm-ups still count toward', () {
    test('they are stored and read back with the session', () async {
      final id = await benchSession(warmups: [40, 60], working: [100]);

      final all = await sessions.watchSessionSets(id).first;

      // Session volume, the muscle map and the recap charts all read this
      // list unfiltered: a warm-up is work you actually did.
      expect(all, hasLength(3));
      expect(all.where((s) => s.isWarmup), hasLength(2));
    });

    test('isWorkingSet is the one place the divide is defined', () async {
      final id = await benchSession(warmups: [40], working: [100]);

      final all = await sessions.watchSessionSets(id).first;

      expect(all.where(isWorkingSet).map((s) => s.weight), [100]);
    });
  });

  group('numbering', () {
    test('the two phases are numbered independently', () async {
      final id = await benchSession(
        warmups: [40, 60],
        working: [100, 100, 100],
        complete: false,
      );

      final all = await sessions.watchSessionSets(id).first;

      // Working sets read 1, 2, 3 no matter how long the ramp-up was —
      // "set 5 of 3" would be a strange thing to see on the card.
      expect(all.where((s) => s.isWarmup).map((s) => s.setNumber), [1, 2]);
      expect(all.where((s) => !s.isWarmup).map((s) => s.setNumber), [1, 2, 3]);
    });

    test('re-tagging a warm-up renumbers both phases', () async {
      final id = await benchSession(
        warmups: [40, 60, 80],
        working: [100],
        complete: false,
      );
      final all = await sessions.watchSessionSets(id).first;
      final lastWarmup = all.where((s) => s.isWarmup).last;

      // The bar felt light, so the 80 was really the first working set.
      await sessions.setWarmup(id: lastWarmup.id, isWarmup: false);

      final after = await sessions.watchSessionSets(id).first;
      expect(after.where((s) => s.isWarmup).map((s) => s.setNumber), [1, 2]);
      expect(
        after.where((s) => !s.isWarmup).map((s) => (s.weight, s.setNumber)),
        [(80.0, 1), (100.0, 2)],
      );
    });

    test('deleting a set closes the gap it left', () async {
      final id = await benchSession(
        warmups: const [],
        working: [100, 105, 110],
        complete: false,
      );
      final all = await sessions.watchSessionSets(id).first;

      await sessions.deleteSet(all.first.id);

      final after = await sessions.watchSessionSets(id).first;
      expect(after.map((s) => (s.weight, s.setNumber)), [
        (105.0, 1),
        (110.0, 2),
      ]);
    });

    test('re-tagging a set that is already gone does nothing', () async {
      final id = await benchSession(
        warmups: const [],
        working: [100],
        complete: false,
      );
      final all = await sessions.watchSessionSets(id).first;
      await sessions.deleteSet(all.single.id);

      // Two taps racing on the same row shouldn't throw.
      await sessions.setWarmup(id: all.single.id, isWarmup: true);

      expect(await sessions.watchSessionSets(id).first, isEmpty);
    });
  });

  group('planned warm-ups', () {
    test('a planned exercise starts with none', () async {
      final splitId = await db
          .into(db.splits)
          .insert(SplitsCompanion.insert(name: 'PPL'));
      final dayId = await db
          .into(db.workoutDays)
          .insert(WorkoutDaysCompanion.insert(splitId: splitId, name: 'Push'));
      await db
          .into(db.workoutExercises)
          .insert(
            WorkoutExercisesCompanion.insert(
              dayId: dayId,
              exerciseId: 'barbell_bench_press',
            ),
          );

      final planned = (await db.select(db.workoutExercises).get()).single;

      // You don't warm up for a cable curl, so zero is the honest default.
      expect(planned.warmupSets, 0);
    });

    test('a planned count is stored and read back', () async {
      final splitId = await db
          .into(db.splits)
          .insert(SplitsCompanion.insert(name: 'PPL'));
      final dayId = await db
          .into(db.workoutDays)
          .insert(WorkoutDaysCompanion.insert(splitId: splitId, name: 'Push'));
      await db
          .into(db.workoutExercises)
          .insert(
            WorkoutExercisesCompanion.insert(
              dayId: dayId,
              exerciseId: 'barbell_bench_press',
              warmupSets: const Value(3),
            ),
          );

      final planned = (await db.select(db.workoutExercises).get()).single;
      expect(planned.warmupSets, 3);
    });
  });
}
