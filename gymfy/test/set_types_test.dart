// Set types and ratings (schema v26): what each type stays out of, what it
// still counts toward, and how RPE / RIR are stored.
//
// Like the warm-up tests this is mostly a filter, so the tests that matter
// prove it is applied where strength is judged and nowhere else. Drop sets are
// the new case: kept out of e1RM, PRs, charts and overload exactly like
// warm-ups, but numbered with the working sets.

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/overload/data/overload_repository.dart';
import 'package:gymfy/features/progress/data/progress_repository.dart';
import 'package:gymfy/features/workout/data/session_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';

void main() {
  group('SetType', () {
    test('only warm-ups and drop sets are kept out of strength', () {
      expect(SetType.warmup.countsTowardStrength, isFalse);
      expect(SetType.drop.countsTowardStrength, isFalse);
      expect(SetType.normal.countsTowardStrength, isTrue);
      expect(SetType.failure.countsTowardStrength, isTrue);
    });

    test('only warm-ups are numbered in the ramp-up phase', () {
      expect(SetType.values.where((t) => t.isWarmupPhase), [SetType.warmup]);
    });

    test('parse reads every slug and falls back to a working set', () {
      for (final type in SetType.values) {
        expect(SetType.parse(type.name), type);
      }
      // A slug from a newer build counts as a working set — and the SQL
      // exclusion list agrees, because it only names what it excludes.
      expect(SetType.parse('cluster'), SetType.normal);
      expect(strengthExcludedSetTypes, isNot(contains('cluster')));
      expect(SetType.parse(null), SetType.normal);
    });

    test('the SQL exclusion list matches the enum', () {
      expect(strengthExcludedSetTypes.toSet(), {
        for (final t in SetType.values)
          if (!t.countsTowardStrength) t.name,
      });
    });
  });

  group('with a database', () {
    late AppDatabase db;
    late SessionRepository sessions;
    late ProgressRepository progress;
    late OverloadRepository overload;
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

    tearDown(() => db.close());

    /// A finished session of (weight, type) bench sets, 5 reps each.
    Future<int> session(List<(double, SetType)> sets) async {
      final id = await sessions.startSession(dayId: dayId, name: 'Push');
      var n = 0;
      for (final (weight, type) in sets) {
        await sessions.logSet(
          sessionId: id,
          exerciseId: 'barbell_bench_press',
          setNumber: ++n,
          weight: weight,
          reps: 5,
          setType: type,
        );
      }
      await sessions.completeSession(id);
      return id;
    }

    test('a new set is a working set unless told otherwise', () async {
      final id = await sessions.startSession(dayId: dayId, name: 'Push');
      await sessions.logSet(
        sessionId: id,
        exerciseId: 'barbell_bench_press',
        setNumber: 1,
        weight: 100,
        reps: 5,
      );

      final set = (await sessions.watchSessionSets(id).first).single;
      expect(set.type, SetType.normal);
      expect(set.rpe, isNull);
      expect(set.rir, isNull);
    });

    test('drop sets stay out of the chart, PRs and e1RM', () async {
      // A drop set heavier than the working set is impossible in practice, but
      // it makes a missing filter impossible to miss.
      await session([(100, SetType.normal), (140, SetType.drop)]);

      final points = await progress
          .watchExerciseHistory('barbell_bench_press')
          .first;
      expect(points.single.topWeight, 100);
      expect(personalRecordsFrom(points)!.heaviestWeight, 100);
      expect(bestEstimatedOneRm(points)!.weight, 100);
    });

    test('failure sets count as working sets', () async {
      await session([(100, SetType.normal), (105, SetType.failure)]);

      final points = await progress
          .watchExerciseHistory('barbell_bench_press')
          .first;
      expect(points.single.topWeight, 105);
    });

    test('overload never sees a drop set', () async {
      await session([
        (100, SetType.normal),
        (100, SetType.normal),
        (70, SetType.drop),
      ]);

      final recent = await overload.recentSessions('barbell_bench_press');
      expect(recent.single.map((s) => s.weight), [100, 100]);
    });

    test('an exercise with only drop sets is not offered a chart', () async {
      await session([(70, SetType.drop)]);

      expect(await progress.watchExercisesWithHistory().first, isEmpty);
    });

    test('every type is still read back with the session', () async {
      final id = await session([
        (40, SetType.warmup),
        (100, SetType.normal),
        (70, SetType.drop),
        (100, SetType.failure),
      ]);

      // Volume, the muscle map and the recap read this list unfiltered.
      final all = await sessions.watchSessionSets(id).first;
      expect(all.map((s) => s.type), [
        SetType.warmup,
        SetType.normal,
        SetType.drop,
        SetType.failure,
      ]);
      expect(all.where(isWorkingSet).map((s) => s.weight), [100, 100]);
    });

    test('setSetType re-tags a set and renumbers its phase', () async {
      final id = await session([
        (40, SetType.warmup),
        (100, SetType.normal),
        (100, SetType.normal),
      ]);
      final all = await sessions.watchSessionSets(id).first;

      // The first working set was really a drop set: still a working-phase
      // number, so nothing renumbers.
      await sessions.setSetType(id: all[2].id, type: SetType.drop);
      // And the warm-up was really a working set.
      await sessions.setSetType(id: all[0].id, type: SetType.normal);

      final after = await sessions.watchSessionSets(id).first;
      expect(after.map((s) => (s.type, s.setNumber)), [
        (SetType.normal, 1),
        (SetType.normal, 2),
        (SetType.drop, 3),
      ]);
    });

    test('RPE and RIR are stored as given', () async {
      final id = await sessions.startSession(dayId: dayId, name: 'Push');
      await sessions.logSet(
        sessionId: id,
        exerciseId: 'barbell_bench_press',
        setNumber: 1,
        weight: 100,
        reps: 5,
        rpe: 8.5,
      );
      await sessions.logSet(
        sessionId: id,
        exerciseId: 'barbell_bench_press',
        setNumber: 2,
        weight: 100,
        reps: 5,
        rir: 1,
      );

      final sets = await sessions.watchSessionSets(id).first;
      expect((sets[0].rpe, sets[0].rir), (8.5, null));
      expect((sets[1].rpe, sets[1].rir), (null, 1));
    });
  });

  group('effectiveRir', () {
    LoggedSet rated({double? rpe, int? rir}) => LoggedSet(
      id: 1,
      sessionId: 1,
      exerciseId: 'barbell_bench_press',
      setNumber: 1,
      weight: 100,
      reps: 5,
      setType: SetType.normal.name,
      rpe: rpe,
      rir: rir,
    );

    test('prefers a stored RIR', () {
      expect(rated(rpe: 6, rir: 2).effectiveRir, 2);
    });

    test('derives one from RPE, rounding down, never below zero', () {
      expect(rated(rpe: 8).effectiveRir, 2);
      // "Maybe two more" is not two more.
      expect(rated(rpe: 8.5).effectiveRir, 1);
      expect(rated(rpe: 10).effectiveRir, 0);
      expect(rated(rpe: 10.5).effectiveRir, 0);
    });

    test('is null on an unrated set', () {
      expect(rated().effectiveRir, isNull);
    });
  });

  test('an unused companion default is a working set', () async {
    // The column default, not the repository, is what a raw insert gets — the
    // importer and any future restore write companions directly.
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db
        .into(db.exercises)
        .insert(
          ExercisesCompanion.insert(
            id: 'squat',
            name: 'Squat',
            muscleIds: const ['quads'],
          ),
        );
    final sessionId = await db
        .into(db.workoutSessions)
        .insert(WorkoutSessionsCompanion.insert(name: 'Legs'));
    await db
        .into(db.loggedSets)
        .insert(
          LoggedSetsCompanion.insert(
            sessionId: sessionId,
            exerciseId: 'squat',
            setNumber: 1,
            weight: const Value(140),
          ),
        );

    final set = (await db.select(db.loggedSets).get()).single;
    expect(set.setType, 'normal');
    expect(isWorkingSet(set), isTrue);
  });
}
