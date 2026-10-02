// The monthly review and the Year in Training.
//
// Mostly pure: the review re-adds streams the app already has over a calendar
// window, so the tests feed it those streams' values directly. The two that
// touch the database check the new readers it needed — records per day, and
// training time over the whole log rather than the year grid's window — and
// that the review's record count is exactly what the workout summaries said.

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymfy/features/home/data/activity_repository.dart';
import 'package:gymfy/features/home/data/recap.dart';
import 'package:gymfy/features/reviews/data/review.dart';
import 'package:gymfy/features/workout/data/personal_records.dart';
import 'package:gymfy/features/workout/data/session_repository.dart';
import 'package:gymfy/shared/database/app_database.dart';

RecapSet _set(
  DateTime date,
  int session, {
  String exercise = 'barbell_bench_press',
  double weight = 100,
  int reps = 5,
  List<String> muscles = const ['chest', 'tricep'],
}) => (
  date: date,
  sessionId: session,
  exerciseId: exercise,
  weight: weight,
  reps: reps,
  muscleIds: muscles,
);

DayTraining _timed(int minutes) => (minutes: minutes, untimed: 0);

void main() {
  group('the period', () {
    test('a month runs from the first to the first', () {
      final september = ReviewPeriod.month(2026, 9);
      expect(september.start, DateTime(2026, 9));
      expect(september.end, DateTime(2026, 10));
      expect(september.contains(DateTime(2026, 9, 30, 23, 59)), isTrue);
      expect(september.contains(DateTime(2026, 10, 1)), isFalse);
      expect(september.label, 'September 2026');
      expect(september.previous, ReviewPeriod.month(2026, 8));
      expect(
        ReviewPeriod.month(2026, 1).previous,
        ReviewPeriod.month(2025, 12),
      );
      expect(ReviewPeriod.month(2026, 12).next, ReviewPeriod.month(2027, 1));
    });

    test('a year is a calendar year', () {
      final year = ReviewPeriod.year(2026);
      expect(year.end, DateTime(2027));
      expect(year.label, '2026');
      expect(year.previous.label, '2025');
    });

    test('opens on the current period, or the last one if this is empty', () {
      final sets = [_set(DateTime(2026, 9, 20, 18), 1)];
      // The first of October: nothing yet, so September.
      expect(
        defaultReviewPeriod(ReviewSpan.month, DateTime(2026, 10, 1), sets),
        ReviewPeriod.month(2026, 9),
      );
      expect(
        defaultReviewPeriod(ReviewSpan.month, DateTime(2026, 9, 25), sets),
        ReviewPeriod.month(2026, 9),
      );
      expect(
        defaultReviewPeriod(ReviewSpan.year, DateTime(2026, 10, 1), sets),
        ReviewPeriod.year(2026),
      );
      expect(
        defaultReviewPeriod(ReviewSpan.year, DateTime(2027, 1, 1), sets),
        ReviewPeriod.year(2026),
      );
    });
  });

  group('the numbers', () {
    // September: three workouts (one a free workout — nothing marks it here,
    // and nothing needs to), August: one.
    final sets = [
      _set(DateTime(2026, 8, 30, 18), 1),
      _set(DateTime(2026, 9, 1, 18), 2),
      _set(DateTime(2026, 9, 1, 18), 2, weight: 60, reps: 10),
      _set(
        DateTime(2026, 9, 2, 19),
        3,
        exercise: 'pull_up',
        weight: 0,
        reps: 8,
        muscles: const ['lats'],
      ),
      _set(
        DateTime(2026, 9, 2, 19),
        3,
        exercise: 'pull_up',
        weight: 0,
        reps: 6,
        muscles: const ['lats'],
      ),
      _set(
        DateTime(2026, 9, 2, 19),
        3,
        exercise: 'pull_up',
        weight: 0,
        reps: 6,
        muscles: const ['lats'],
      ),
      _set(DateTime(2026, 9, 9, 18), 4),
      // October does not leak in.
      _set(DateTime(2026, 10, 1, 8), 5),
    ];
    final days = {
      DateTime(2026, 8, 30): _timed(50),
      DateTime(2026, 9, 1): _timed(60),
      // An imported session whose length was never recorded.
      DateTime(2026, 9, 2): (minutes: 0, untimed: 1),
      DateTime(2026, 9, 9): _timed(45),
      DateTime(2026, 10, 1): _timed(30),
    };
    final records = {DateTime(2026, 9, 9): 2, DateTime(2026, 8, 30): 1};

    final review = buildReview(
      period: ReviewPeriod.month(2026, 9),
      allSets: sets,
      trainingDays: days,
      recordsByDay: records,
    );
    final now = review.current;

    test('workouts, sets and volume — every set type, bodyweight as reps', () {
      expect(now.workouts, 3);
      expect(now.sets, 6);
      // 500 + 600 + 500 kg, and the pull-ups by the recap's rule: 8 + 6 + 6.
      expect(now.volumeKg, 1620);
    });

    test('time is known minutes only, with the untimed counted apart', () {
      expect(now.minutes, 105);
      expect(now.untimedWorkouts, 1);
    });

    test('records come from the per-day counts', () {
      expect(now.records, 2);
      expect(review.previous.records, 1);
    });

    test('top exercises by sets, then by volume', () {
      expect(now.topExercises.map((e) => (e.exerciseId, e.sets, e.workouts)), [
        ('barbell_bench_press', 3, 2),
        ('pull_up', 3, 1),
      ]);
    });

    test('muscles by sets, each set once per muscle', () {
      expect(now.muscleSets.first, isA<MapEntry<String, int>>());
      expect(
        {for (final e in now.muscleSets) e.key: e.value},
        {'chest': 3, 'tricep': 3, 'lats': 3},
      );
    });

    test('days trained and the longest run of them', () {
      expect(now.activeDays, 3);
      // 1 and 2 September back to back.
      expect(now.longestStreak, 2);
    });

    test('the period before is summed the same way, for comparison', () {
      expect(review.previous.workouts, 1);
      expect(review.previous.minutes, 50);
      expect(review.period.previous.shortLabel, 'August');
    });

    test('an empty period is empty, not an error', () {
      final empty = buildReview(
        period: ReviewPeriod.month(2026, 3),
        allSets: sets,
        trainingDays: days,
        recordsByDay: records,
      );
      expect(empty.current.isEmpty, isTrue);
      expect(empty.current.topExercises, isEmpty);
      expect(empty.current.longestStreak, 0);
    });

    test('a year adds its months up', () {
      final year = buildReview(
        period: ReviewPeriod.year(2026),
        allSets: sets,
        trainingDays: days,
        recordsByDay: records,
      );
      expect(year.current.workouts, 5);
      expect(year.current.minutes, 185);
      expect(year.previous.isEmpty, isTrue);
    });
  });

  group('signedDelta', () {
    test('says how a number moved, with a real minus', () {
      expect(signedDelta(5, 3), '+2');
      expect(signedDelta(3, 5), '−2');
      expect(signedDelta(4, 4), isNull);
      expect(signedDelta(90, 30, format: (v) => '$v min'), '+60 min');
    });
  });

  group('records across the log', () {
    late AppDatabase db;
    late SessionRepository sessions;
    late PersonalRecordsRepository records;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      sessions = SessionRepository(db);
      records = PersonalRecordsRepository(db);
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

    /// A finished workout on [day] with the given sets of bench.
    Future<int> workout(
      DateTime day,
      List<(double, int, SetType)> sets, {
      bool free = false,
    }) async {
      final id = await db
          .into(db.workoutSessions)
          .insert(
            WorkoutSessionsCompanion.insert(
              name: free ? 'Free workout' : 'Push',
              startedAt: Value(day),
              completedAt: Value(day.add(const Duration(hours: 1))),
            ),
          );
      for (final (i, (weight, reps, type)) in sets.indexed) {
        await sessions.logSet(
          sessionId: id,
          exerciseId: 'barbell_bench_press',
          setNumber: i + 1,
          weight: weight,
          reps: reps,
          setType: type,
        );
      }
      return id;
    }

    test('add up to exactly what the workout summaries say', () async {
      final first = await workout(DateTime(2026, 9, 1, 18), [
        (100, 5, SetType.normal),
      ]);
      // Heavier and a better estimate, in a free workout: two records.
      final second = await workout(DateTime(2026, 9, 3, 18), [
        (60, 5, SetType.warmup),
        (105, 5, SetType.normal),
      ], free: true);
      // A heavier drop set is not a record; same weight is not either.
      final third = await workout(DateTime(2026, 9, 5, 18), [
        (105, 5, SetType.normal),
        (110, 3, SetType.drop),
      ]);

      final byDay = await records.watchRecordsByDay().first;

      var fromSummaries = 0;
      for (final id in [first, second, third]) {
        final summary = await records.recordsForSession(id);
        fromSummaries += summary.fold(0, (n, e) => n + e.records.length);
      }
      final fromReview = byDay.values.fold(0, (n, c) => n + c);

      expect(fromReview, fromSummaries);
      // Weight, estimated 1RM and session volume on the 3rd.
      expect(byDay, {DateTime(2026, 9, 3): 3});
    });

    test('an unfinished workout sets nothing', () async {
      await workout(DateTime(2026, 9, 1, 18), [(100, 5, SetType.normal)]);
      final open = await db
          .into(db.workoutSessions)
          .insert(
            WorkoutSessionsCompanion.insert(
              name: 'Push',
              startedAt: Value(DateTime(2026, 9, 2, 18)),
            ),
          );
      await sessions.logSet(
        sessionId: open,
        exerciseId: 'barbell_bench_press',
        setNumber: 1,
        weight: 120,
        reps: 5,
      );

      expect(await records.watchRecordsByDay().first, isEmpty);
    });

    test('training time reaches back past the year grid', () async {
      // Two years ago: outside the heatmap's 53 weeks, inside the review's
      // "this year against last year".
      final old = DateTime.now().subtract(const Duration(days: 730));
      await workout(old, [(100, 5, SetType.normal)]);

      final all = await ActivityRepository(db).watchAllTrainingByDay().first;
      final grid = await ActivityRepository(
        db,
      ).watchMinutesByDay(DateTime.now()).first;

      expect(all, hasLength(1));
      expect(all.values.single.minutes, 60);
      expect(grid, isEmpty);
    });
  });
}
