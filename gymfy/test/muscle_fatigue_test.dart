// The fatigue map's decay model.
//
// Pure-function tests against `muscleFatigue`, plus a couple through the
// repository to prove the warm-up filter and the time window are really wired
// to the query rather than only to the maths.

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/muscle_map/data/muscle_fatigue_repository.dart';
import 'package:gymfy/features/workout/data/session_repository.dart';
import 'package:gymfy/features/workout/data/workout_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';

final _now = DateTime(2026, 8, 24, 18);

/// [count] sets on [muscles], performed [ago] before [_now].
List<FatigueSample> sets({
  required int count,
  required List<String> muscles,
  Duration ago = Duration.zero,
}) {
  return [
    for (var i = 0; i < count; i++)
      (performedAt: _now.subtract(ago), muscleIds: muscles),
  ];
}

void main() {
  group('decay', () {
    test('nothing logged means no fatigue at all', () {
      expect(muscleFatigue(const [], now: _now), isEmpty);
    });

    test('a saturating session reads as fully fatigued', () {
      final fatigue = muscleFatigue(
        sets(count: 12, muscles: ['chest']),
        now: _now,
      );

      expect(fatigue['chest'], closeTo(1.0, 0.001));
    });

    test('half the saturating volume reads as half fatigued', () {
      final fatigue = muscleFatigue(
        sets(count: 6, muscles: ['chest']),
        now: _now,
      );

      expect(fatigue['chest'], closeTo(0.5, 0.001));
    });

    test('one half-life later it has halved', () {
      final fatigue = muscleFatigue(
        sets(count: 12, muscles: ['chest'], ago: fatigueHalfLife),
        now: _now,
      );

      expect(fatigue['chest'], closeTo(0.5, 0.001));
    });

    test('two half-lives later it has quartered', () {
      final fatigue = muscleFatigue(
        sets(count: 12, muscles: ['chest'], ago: fatigueHalfLife * 2),
        now: _now,
      );

      expect(fatigue['chest'], closeTo(0.25, 0.001));
    });

    test('a week off leaves almost nothing behind', () {
      final fatigue = muscleFatigue(
        sets(count: 12, muscles: ['chest'], ago: const Duration(days: 7)),
        now: _now,
      );

      expect(fatigue['chest']!, lessThan(0.1));
    });

    test('beyond saturation it clamps rather than overflowing', () {
      final fatigue = muscleFatigue(
        sets(count: 40, muscles: ['chest']),
        now: _now,
      );

      // There is no "more than fully fatigued" worth drawing, and a value above
      // 1.0 would push the SVG opacity out of range.
      expect(fatigue['chest'], 1.0);
    });

    test('sessions stack instead of replacing each other', () {
      final fatigue = muscleFatigue(
        [
          ...sets(count: 6, muscles: ['chest']),
          ...sets(count: 6, muscles: ['chest'], ago: fatigueHalfLife),
        ],
        now: _now,
      );

      // 6 fresh + 6 half-decayed = 9 effective sets of 12.
      expect(fatigue['chest'], closeTo(0.75, 0.001));
    });

    test('every muscle an exercise trains takes the hit', () {
      final fatigue = muscleFatigue(
        sets(count: 12, muscles: ['chest', 'triceps']),
        now: _now,
      );

      expect(fatigue['chest'], closeTo(1.0, 0.001));
      expect(fatigue['triceps'], closeTo(1.0, 0.001));
    });

    test('untrained muscles are absent, not zero', () {
      final fatigue = muscleFatigue(
        sets(count: 3, muscles: ['chest']),
        now: _now,
      );

      // The map treats a missing muscle as untouched; an explicit 0.0 would
      // mean the same thing but make the legend list muscles you never worked.
      expect(fatigue.containsKey('lats'), isFalse);
    });

    test('a set stamped in the future does not decay upward', () {
      final fatigue = muscleFatigue(
        [(performedAt: _now.add(const Duration(days: 2)), muscleIds: ['chest'])],
        now: _now,
      );

      // A clock change or edited data shouldn't be able to produce more than a
      // fresh set's worth of fatigue.
      expect(fatigue['chest'], closeTo(1 / fatigueSaturationSets, 0.001));
    });
  });

  group('fatigue is absolute, not relative', () {
    test('a light week stays dark instead of rescaling to itself', () {
      final fatigue = muscleFatigue(
        sets(count: 1, muscles: ['chest'], ago: const Duration(days: 3)),
        now: _now,
      );

      // The volume heatmap would show this as 1.0 — it scales so the busiest
      // muscle is always full. For fatigue that would be a lie: one set three
      // days ago is a recovered chest, not a fried one.
      expect(fatigue['chest']!, lessThan(0.05));
    });

    test('the hardest-worked muscle is not automatically maxed', () {
      final fatigue = muscleFatigue(
        [
          ...sets(count: 2, muscles: ['chest']),
          ...sets(count: 1, muscles: ['lats']),
        ],
        now: _now,
      );

      expect(fatigue['chest'], closeTo(2 / 12, 0.001));
      expect(fatigue['lats'], closeTo(1 / 12, 0.001));
    });
  });

  group('through the database', () {
    late AppDatabase db;
    late MuscleFatigueRepository fatigue;
    late SessionRepository sessions;
    late WorkoutRepository workout;
    late int dayId;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      fatigue = MuscleFatigueRepository(db);
      sessions = SessionRepository(db);
      workout = WorkoutRepository(db);

      await db.into(db.exercises).insert(
        ExercisesCompanion.insert(
          id: 'barbell_bench_press',
          name: 'Barbell Bench Press',
          muscleIds: const ['chest', 'triceps'],
        ),
      );
      final splitId = await workout.createSplit('PPL');
      dayId = await workout.createDay(splitId, 'Push');
    });

    tearDown(() => db.close());

    /// Logs [working] working sets and [warmup] warm-ups in a session started
    /// [ago] before [_now].
    Future<void> session({
      int working = 0,
      int warmup = 0,
      Duration ago = Duration.zero,
    }) async {
      final id = await db.into(db.workoutSessions).insert(
        WorkoutSessionsCompanion.insert(
          dayId: Value(dayId),
          name: 'Push',
          startedAt: Value(_now.subtract(ago)),
        ),
      );
      for (var i = 0; i < warmup; i++) {
        await sessions.logSet(
          sessionId: id,
          exerciseId: 'barbell_bench_press',
          setNumber: i + 1,
          weight: 40,
          reps: 5,
          isWarmup: true,
        );
      }
      for (var i = 0; i < working; i++) {
        await sessions.logSet(
          sessionId: id,
          exerciseId: 'barbell_bench_press',
          setNumber: i + 1,
          weight: 100,
          reps: 5,
        );
      }
    }

    test('warm-ups do not fatigue you', () async {
      await session(working: 6, warmup: 6);

      final result = await fatigue.watchFatigue(_now).first;

      // Six working sets, not twelve — ramping up to your working weight is the
      // opposite of accumulating work.
      expect(result['chest'], closeTo(0.5, 0.001));
    });

    test('a session of only warm-ups leaves you recovered', () async {
      await session(warmup: 8);

      expect(await fatigue.watchFatigue(_now).first, isEmpty);
    });

    test('sets older than the window are not read', () async {
      await session(working: 12, ago: fatigueWindow + const Duration(days: 1));

      // Decay would have made them negligible anyway; the point is the query
      // doesn't drag a year of history off disk to prove it.
      expect(await fatigue.watchFatigue(_now).first, isEmpty);
    });

    test('every muscle of the exercise is fatigued', () async {
      await session(working: 12);

      final result = await fatigue.watchFatigue(_now).first;

      expect(result['chest'], closeTo(1.0, 0.001));
      expect(result['triceps'], closeTo(1.0, 0.001));
    });

    test('an in-progress workout already counts', () async {
      // No completedAt — you are standing in the gym and your chest is already
      // tired. Unlike the overload suggestion, fatigue has no reason to wait
      // for the session to be finished.
      await session(working: 12);

      final result = await fatigue.watchFatigue(_now).first;
      expect(result['chest'], closeTo(1.0, 0.001));
    });
  });
}
